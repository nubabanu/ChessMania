extends Node

var control: Node = null
var max_depth: int = 2

var piece_values = {
	"pawn":   100,
	"knight": 280,
	"bishop": 320,
	"rook":   479,
	"queen":  929,
	"king":   60000
}

var piece_offsets = {
	"pawn": [
		[100, 100, 100, 100, 105, 100, 100, 100],
		[78, 83, 86, 73, 102, 82, 85, 90],
		[7, 29, 21, 44, 40, 31, 44, 7],
		[-17, 16, -2, 15, 14, 0, 15, -13],
		[-26, 3, 10, 9, 6, 1, 0, -23],
		[-22, 9, 5, -11, -10, -2, 3, -19],
		[-31, 8, -7, -37, -36, -14, 3, -31],
		[0, 0, 0, 0, 0, 0, 0, 0]
	],
	"knight": [
		[-66, -53, -75, -75, -10, -55, -58, -70],
		[-3, -6, 100, -36, 4, 62, -4, -14],
		[10, 67, 1, 74, 73, 27, 62, -2],
		[24, 24, 45, 37, 33, 41, 25, 17],
		[-1, 5, 31, 21, 22, 35, 2, 0],
		[-18, 10, 13, 22, 18, 15, 11, -14],
		[-23, -15, 2, 0, 2, 0, -23, -20],
		[-74, -23, -26, -24, -19, -35, -22, -69]
	],
	"bishop": [
		[-59, -78, -82, -76, -23, -107, -37, -50],
		[-11, 20, 35, -42, -39, 31, 2, -22],
		[-9, 39, -32, 41, 52, -10, 28, -14],
		[25, 17, 20, 34, 26, 25, 15, 10],
		[13, 10, 17, 23, 17, 16, 0, 7],
		[14, 25, 24, 15, 8, 25, 20, 15],
		[19, 20, 11, 6, 7, 6, 20, 16],
		[-7, 2, -15, -12, -14, -15, -10, -10]
	],
	"rook": [
		[35, 29, 33, 4, 37, 33, 56, 50],
		[55, 29, 56, 67, 55, 62, 34, 60],
		[19, 35, 28, 33, 45, 27, 25, 15],
		[0, 5, 16, 13, 18, -4, -9, -6],
		[-28, -35, -16, -21, -13, -29, -46, -30],
		[-42, -28, -42, -25, -25, -35, -26, -46],
		[-53, -38, -31, -26, -29, -43, -44, -53],
		[-30, -24, -18, 5, -2, -18, -31, -32]
	],
	"queen": [
		[6, 1, -8, -104, 69, 24, 88, 26],
		[14, 32, 60, -10, 20, 76, 57, 24],
		[-2, 43, 32, 60, 72, 63, 43, 2],
		[1, -16, 22, 17, 25, 20, -13, -6],
		[-14, -15, -2, -5, -1, -10, -20, -22],
		[-30, -6, -13, -11, -16, -11, -16, -27],
		[-36, -18, 0, -19, -15, -15, -21, -38],
		[-39, -30, -31, -13, -31, -36, -34, -42]
	],
	"king": [
		[4, 54, 47, -99, -99, 60, 83, -62],
		[-32, 10, 55, 56, 56, 55, 10, 3],
		[-62, 12, -57, 44, -67, 28, 37, -31],
		[-55, 50, 11, -4, -19, 13, 0, -49],
		[-55, -43, -52, -28, -51, -47, -8, -50],
		[-47, -42, -43, -79, -64, -32, -29, -32],
		[-4, 3, -14, -50, -57, -18, 13, 4],
		[17, 30, -3, -14, 6, -1, 40, 18]
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
