#!/bin/bash

# ./best-move "$board"

fen="$1"
time="$2"

bestmove=$(
(
echo "position fen $fen"
echo "go movetime $time"
sleep 2
) | stockfish | tail -n 1 | cut -f 2 -d ' '
)

nodejs convertlongtoshort.js "$fen" "$bestmove"

