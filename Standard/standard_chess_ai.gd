extends Node

var control: Node = null
var max_depth: int = 2

var piece_values = {
	"pawn":   10,
	"knight": 30,
	"bishop": 30,
	"rook":   50,
	"queen":  90,
	"king":   900
}

var piece_offsets = {
	"pawn":  [
		[ 0,   0,   0,   0,   0,   0,   0,   0 ],
		[ 5,   5,   5,   5,   5,   5,   5,   5 ],
		[ 1,   1,   2,   3,   3,   2,   1,   1 ],
		[ 0.5, 0.5, 1,   2.5, 2.5, 1,   0.5, 0.5 ],
		[ 0,   0,   0,   2,   2,   0,   0,   0 ],
		[ 0.5,-0.5,-1,   0,   0,  -1,  -0.5, 0.5 ],
		[ 0.5, 1,   1,  -2,  -2,   1,   1,   0.5 ],
		[ 0,   0,   0,   0,   0,   0,   0,   0 ]
	],
	"knight": [
		[-50, -40, -30, -30, -30, -30, -40, -50],
		[-40, -20,   0,   0,   0,   0, -20, -40],
		[-30,   0,  10,  15,  15,  10,   0, -30],
		[-30,   5,  15,  20,  20,  15,   5, -30],
		[-30,   0,  15,  20,  20,  15,   0, -30],
		[-30,   5,  10,  15,  15,  10,   5, -30],
		[-40, -20,   0,   5,   5,   0, -20, -40],
		[-50, -40, -30, -30, -30, -30, -40, -50]
	],
	"bishop": [
		[-20, -10, -10, -10, -10, -10, -10, -20],
		[-10,   0,   0,   0,   0,   0,   0, -10],
		[-10,   0,   5,  10,  10,   5,   0, -10],
		[-10,   5,   5,  10,  10,   5,   5, -10],
		[-10,   0,  10,  10,  10,  10,   0, -10],
		[-10,  10,  10,  10,  10,  10,  10, -10],
		[-10,   5,   0,   0,   0,   0,   5, -10],
		[-20, -10, -10, -10, -10, -10, -10, -20]
	],
	"rook": [
		[ 0,   0,   0,   0,   0,   0,   0,   0 ],
		[ 5,  10,  10,  10,  10,  10,  10,   5 ],
		[-5,   0,   0,   0,   0,   0,   0,  -5],
		[-5,   0,   0,   0,   0,   0,   0,  -5],
		[-5,   0,   0,   0,   0,   0,   0,  -5],
		[-5,   0,   0,   0,   0,   0,   0,  -5],
		[-5,   0,   0,   0,   0,   0,   0,  -5],
		[ 0,   0,   0,   5,   5,   0,   0,   0 ]
	],
	"queen": [
		[-20, -10, -10,  -5,  -5, -10, -10, -20],
		[-10,   0,   0,   0,   0,   0,   0, -10],
		[-10,   0,   5,   5,   5,   5,   0, -10],
		[ -5,   0,   5,   5,   5,   5,   0,  -5],
		[  0,   0,   5,   5,   5,   5,   0,  -5],
		[-10,   5,   5,   5,   5,   5,   0, -10],
		[-10,   0,   5,   0,   0,   0,   0, -10],
		[-20, -10, -10,  -5,  -5, -10, -10, -20]
	],
	"king": [
		[-30, -40, -40, -50, -50, -40, -40, -30],
		[-30, -40, -40, -50, -50, -40, -40, -30],
		[-30, -40, -40, -50, -50, -40, -40, -30],
		[-30, -40, -40, -50, -50, -40, -40, -30],
		[-20, -30, -30, -40, -40, -30, -30, -20],
		[-10, -20, -20, -20, -20, -20, -20, -10],
		[ 20,  20,   0,   0,   0,   0,  20,  20],
		[ 20,  30,  10,   0,   0,  10,  30,  20]
	]
}

const INF     = 999999
const NEG_INF = -999999

func set_control(ctrl: Node) -> void:
	control = ctrl

func apply_move(board: Array, move: Dictionary):
	var origin = move.origin
	var dest = move.destination
	var captured = board[dest.x][dest.y]
	board[dest.x][dest.y] = board[origin.x][origin.y]
	board[origin.x][origin.y] = 0
	return captured

func revert_move(board: Array, move: Dictionary, captured):
	var origin = move.origin
	var dest = move.destination
	board[origin.x][origin.y] = board[dest.x][dest.y]
	board[dest.x][dest.y] = captured

func get_best_move(board: Array, is_white: bool) -> Variant:
	var best_move: Variant = null
	var best_score: float
	if is_white:
		best_score = NEG_INF
	else:
		best_score = INF

	var possible_moves = get_all_legal_moves(board, is_white)
	if possible_moves.size() == 0:
		print("Stalemate")
		return null

	for move in possible_moves:
		var captured = apply_move(board, move)
		var score = minimax(board, max_depth - 1, NEG_INF, INF, not is_white)
		revert_move(board, move, captured)

		if is_white:
			if score > best_score:
				best_score = score
				best_move = move
		else:
			if score < best_score:
				best_score = score
				best_move = move

	return best_move

func minimax(board: Array, depth: int, alpha: float, beta: float, maximizing_is_white: bool) -> float:
	if depth == 0 or control.is_game_over(board):
		return evaluate_board(board)

	var possible_moves = get_all_legal_moves(board, maximizing_is_white)
	if possible_moves.size() == 0:
		return evaluate_board(board)

	if maximizing_is_white:
		var max_eval = NEG_INF
		for move in possible_moves:
			var captured = apply_move(board, move)
			var score = minimax(board, depth - 1, alpha, beta, false)
			revert_move(board, move, captured)

			if score > max_eval:
				max_eval = score
			if max_eval > alpha:
				alpha = max_eval
			if beta <= alpha:
				break
		return max_eval
	else:
		var min_eval = INF
		for move in possible_moves:
			var captured = apply_move(board, move)
			var score = minimax(board, depth - 1, alpha, beta, true)
			revert_move(board, move, captured)

			if score < min_eval:
				min_eval = score
			if min_eval < beta:
				beta = min_eval
			if beta <= alpha:
				break
		return min_eval

func evaluate_board(board: Array) -> float:
	var score: float = 0.0
	var all_pieces = control.get_all_pieces(board)
	for piece_data in all_pieces:
		var piece_type = piece_data.type
		var base_value = 0
		if piece_values.has(piece_type):
			base_value = piece_values[piece_type]
		var pos = piece_data.position
		var x = pos[0]
		var y = pos[1]
		var bonus = 0.0
		if is_white_piece(piece_data):
			bonus = piece_offsets[piece_type][y][x]
			score += base_value + bonus
		else:
			y = 7 - y
			bonus = piece_offsets[piece_type][y][x]
			score -= (base_value + bonus)
	return score

func get_all_legal_moves(board: Array, is_white: bool) -> Array:
	return control.get_moveable_areas_for_all_pieces(is_white)

func is_white_piece(piece_data: Dictionary) -> bool:
	if piece_data.has("is_white"):
		return piece_data["is_white"]
	return false
