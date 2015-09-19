#!/bin/bash

endpoint=$1

[ -z "$endpoint" ] && {
  echo "Please give me a valid restchess endpoint..."
  exit 2
}

# Take the last game in the list of games...
game=$(curl "$endpoint" | jq --raw-output '._links.games[].href' | tail -n 1)
if [ "$game" != "null" ] ; then
  if [[ $game == /* ]] ; then
    game="${game%/}${endpoint}"
  fi
  echo "Running game $game..."
  ./supervisor.sh "$game"
fi
