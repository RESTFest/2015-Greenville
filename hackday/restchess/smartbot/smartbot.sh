#!/bin/bash

queue=$1
time=$2

[ -z "$time" ] && {
  echo "I need a queue URI and a time (in milliseconds) for stockfish to run, e.g. 500"
  exit 1
}

function main() {
  while true; do
    make_move
    sleep 0.2;
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
  curl --data-urlencode move=$2 "$1" 
}

function make_move() {
  local work=$(grab_endpoint)
  if ! [ "$(jq <<< "$work" .type)" == \""http://mogsie.com/static/workflow/make-chess-move"\" ] ; then
    # Not a "make a chess move" ...
    return 1
  fi

  length=$(jq <<< "$work" '.input["legal-moves"]|length')
  if ! [[ "$length" =~ ^[0-9]+$ ]] ; then
    echo "Can't determine the number of legal moves... DOH!"
    return 1
  fi
  board=$(jq --raw-output <<< "$work" '.input.board')
  move=$(./best-move.sh "$board" "$time")
  if ! [ -z "$move" ] ; then
    echo "Making smart move: $move"
  else
    choice=$((RANDOM % length))
    echo "making move $choice"
    move=$(jq --raw-output <<< "$work" '.input["legal-moves"]['$choice']')
    echo "making move $choice: $move"
  fi
  
  complete_uri=$(jq --raw-output <<< "$work" '.complete')
  cat > last-work.json <<< "$work"
  complete_uri=$(nodejs ../supervisor-bash/absolutize.js "$queue" "$complete_uri")
  post_response "$complete_uri" "$move"
}



main;
