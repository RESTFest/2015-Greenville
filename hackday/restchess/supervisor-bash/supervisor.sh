#!/bin/bash

queue=$1

function main() {
  while true; do
    echo "checking"
    make_decision
    echo "Waiting.."
    sleep 6;
  done
}

function grab_endpoint() {
  if [[ "$queue" == "http"* ]] ; then
    curl -s $queue
  else
    cat $queue
  fi
}

function post_response() {
  curl -H "content-type:application/json" --data-binary "$2" "$1" 
}

function make_decision() {
  local work=$(grab_endpoint)
  if ! [ "$(jq <<< "$work" ".[\"current-state\"]")" == \""tag:chess.mogsie.com,2001:game-in-progress"\" ] ; then
    # Not an in-progress game.
    return 1
  fi
  length=$(jq <<< "$work" '.data["recent-events"]|length')
  if ! [[ "$length" =~ ^[0-9]+$ ]] ; then
    echo "Invalid number of events found..."
    return 1
  fi

  board=$(jq --raw-output <<< "$work" '.data.board')
  echo "$board  ----  $(cut -f 6 -d ' ' <<< "$board")"
  if [ $length == 0 ] && [ "$(cut -f 6 -d ' ' <<< "$board")" != "1" ] ; then 
    echo "No move"
    return 0
  fi

  move=$(jq --raw-output <<< "$work" '.data["recent-events"][0].data.move')
  board=$(jq --raw-output <<< "$work" '.data.board')

  result="$(nodejs make-move.js "$board" "$move")"

  new_board=$(head -n 1 <<< "$result")
  legal_moves="$(tail -n +2 <<< "$result" | sed -e 's/^/,"/' -e 's/$/"/' | xargs -d '\n' | sed 's/,//')"

  echo "new board: $new_board"
  player="$(echo $new_board | cut -f 2 -d ' ')"
  echo "legal_moves: $legal_moves"

  if [ -z "$legal_moves" ] ; then
    echo "Game over"
    sleep 10
    exit 0
  fi

  complete_uri=$(jq --raw-output <<< "$work" '._links["workflow:make-decisions"].href')
  # TODO: absolutize the URI
  result=$(cat <<EOF
{
    "current-state" : "tag:chess.mogsie.com,2001:game-in-progress",
    "data" : {
        "board" : "$new_board"
    },
    "decisions": [
        {
            "type": "schedule-work",
            "name": "make-a-move",
            "queue": "bot-$player",
            "work": {
                "type": "http://mogsie.com/static/workflow/make-chess-move",
                "input": {
                    "board" : "$new_board",
                    "legal-moves" : [ $legal_moves ]
                }
            }
        }
    ]
}
EOF
)
  cat > last-board.json <<< "$new_board"
  complete_uri=$(nodejs absolutize.js "$queue" "$complete_uri")
  post_response "$complete_uri" "$result"
}



main;
