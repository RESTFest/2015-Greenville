/* A simple CLI for moving a single piece on a chess board */
/* Based on a FEN string and a move, applies the move to the board, producing
   a new board, and a list of legal moves.
   If the game is over, there are no legal moves. */
var fen = process.argv[2];
var move = process.argv[3];
var chess = require("chess.js")
var board = new chess.Chess(fen);
board.move(move);
console.error(board.ascii())
console.log(board.fen());
if (! board.game_over()) {
  var moves = board.moves();
  for (m in moves) {
    console.log(moves[m]);
  }
}
