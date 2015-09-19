var chess=require("chess.js")

var fen=process.argv[2];
var longmove=process.argv[3];

var board = new chess.Chess(fen)
var moves = board.moves({"verbose":true});
for (move in moves) {
  if (longmove.substring(0,4) == moves[move].from + moves[move].to) {
    console.log(moves[move].san)
    break;
  }
}

