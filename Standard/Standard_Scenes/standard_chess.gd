extends Sprite2D

# Board / UI constants
const BOARD_SIZE   = 8
const CELL_WIDTH   = 18

# Preloaded textures for pieces
const TEXTURE_HOLDER = preload("res://Standard/Standard_Scenes/standard_texture_holder.tscn")

const BLACK_BISHOP  = preload("res://Standard/Standard_Assets/black_bishop.png")
const BLACK_KING    = preload("res://Standard/Standard_Assets/black_king.png")
const BLACK_KNIGHT  = preload("res://Standard/Standard_Assets/black_knight.png")
const BLACK_PAWN    = preload("res://Standard/Standard_Assets/black_pawn.png")
const BLACK_QUEEN   = preload("res://Standard/Standard_Assets/black_queen.png")
const BLACK_ROOK    = preload("res://Standard/Standard_Assets/black_rook.png")
const WHITE_BISHOP  = preload("res://Standard/Standard_Assets/white_bishop.png")
const WHITE_KING    = preload("res://Standard/Standard_Assets/white_king.png")
const WHITE_KNIGHT  = preload("res://Standard/Standard_Assets/white_knight.png")
const WHITE_PAWN    = preload("res://Standard/Standard_Assets/white_pawn.png")
const WHITE_QUEEN   = preload("res://Standard/Standard_Assets/white_queen.png")
const WHITE_ROOK    = preload("res://Standard/Standard_Assets/white_rook.png")

const TURN_WHITE = preload("res://Standard/Standard_Assets/turn-white.png")
const TURN_BLACK = preload("res://Standard/Standard_Assets/turn-black.png")

const PIECE_MOVE = preload("res://Standard/Standard_Assets/Piece_move.png")

@onready var pieces        = $Pieces
@onready var dots          = $Dots
@onready var turn          = $Turn
@onready var white_pieces  = $"../CanvasLayer/white_pieces"
@onready var black_pieces  = $"../CanvasLayer/black_pieces"

# The AI script
@onready var chess_ai = preload("res://Standard/standard_chess_ai.gd").new()

# Board piece definitions:
#   -6 = black king
#   -5 = black queen
#   -4 = black rook
#   -3 = black bishop
#   -2 = black knight
#   -1 = black pawn
#    0 = empty
#    6 = white king
#    5 = white queen
#    4 = white rook
#    3 = white bishop
#    2 = white knight
#    1 = white pawn

var board : Array = []
var white : bool  = true  # used for "whose turn it is" in the UI

var state            : bool    = false
var moves            : Array   = []
var selected_piece   : Vector2 = Vector2()

var promotion_square = null

# Castling flags (true means that side’s king/rook has moved)
var white_king       = false
var black_king       = false
var white_rook_left  = false
var white_rook_right = false
var black_rook_left  = false
var black_rook_right = false

var en_passant = null
var promotion_side : bool = true 

var white_king_pos = Vector2(0, 4)
var black_king_pos = Vector2(7, 4)

var fifty_move_rule : int = 0

# Threefold repetition data
var unique_board_moves : Array = []
var amount_of_same     : Array = []

func _ready():
	print("okey")
	chess_ai.set_control(self)

	# Standard initial layout
	board.append([  4,  2,  3,  5,  6,  3,  2,  4 ])
	board.append([  1,  1,  1,  1,  1,  1,  1,  1 ])
	board.append([  0,  0,  0,  0,  0,  0,  0,  0 ])
	board.append([  0,  0,  0,  0,  0,  0,  0,  0 ])
	board.append([  0,  0,  0,  0,  0,  0,  0,  0 ])
	board.append([  0,  0,  0,  0,  0,  0,  0,  0 ])
	board.append([ -1, -1, -1, -1, -1, -1, -1, -1 ])
	board.append([ -4, -2, -3, -5, -6, -3, -2, -4 ])

	display_board()

	# Connect promotion buttons (UI)
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")

	for button in white_buttons:
		button.pressed.connect(_on_button_pressed.bind(button))

	for button in black_buttons:
		button.pressed.connect(_on_button_pressed.bind(button))


func _input(event):
	if event is InputEventMouseButton and event.pressed and promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out():
				return
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
		

			# If we're not mid‐move, and the clicked piece belongs to current side
			if not state and ((white and board[var2][var1] > 0) or (not white and board[var2][var1] < 0)):
				selected_piece = Vector2(var2, var1)
				show_options()
				state = true
			elif state:
				set_move(var2, var1)


func is_mouse_out() -> bool:
	return not get_rect().has_point(to_local(get_global_mouse_position()))


func display_board():
	# Clear old placeholders
	for child in pieces.get_children():
		child.queue_free()

	# Generate new placeholders
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(
				j * CELL_WIDTH + (CELL_WIDTH / 2),
				-i * CELL_WIDTH - (CELL_WIDTH / 2)
			)

			match board[i][j]:
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				6: holder.texture = WHITE_KING
				5: holder.texture = WHITE_QUEEN
				4: holder.texture = WHITE_ROOK
				3: holder.texture = WHITE_BISHOP
				2: holder.texture = WHITE_KNIGHT
				1: holder.texture = WHITE_PAWN

	# Show whose turn it is
	if white:
		turn.texture = TURN_WHITE
	else:
		turn.texture = TURN_BLACK


func show_options():
	# Generate moves for the piece at selected_piece, based on `white` (UI side).
	moves = get_moves(selected_piece, white)
	if moves.size() == 0:
		state = false
		return
	show_dots()


func show_dots():
	for mv in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(
			mv.y * CELL_WIDTH + (CELL_WIDTH / 2),
			-mv.x * CELL_WIDTH - (CELL_WIDTH / 2)
		)


func delete_dots():
	for child in dots.get_children():
		child.queue_free()




func set_move(var2: int, var1: int) -> void:
	var game_over = false
	var move_found = false
	var just_now = false  # flag for moves like en passant that postpone resetting en_passant
	var did_promote = false  # NEW: indicates whether a promotion occurred

	# Loop over possible moves to see if the clicked square is valid
	for mv in moves:
		if mv.x == var2 and mv.y == var1:
			move_found = true
			# Update fifty move rule: reset if capturing an enemy
			fifty_move_rule += 1
			if is_enemy(Vector2(var2, var1), white):
				fifty_move_rule = 0

			var piece_val = board[selected_piece.x][selected_piece.y]

			# Process special moves
			match piece_val:
				1:  # White pawn
					fifty_move_rule = 0
					if var2 == 7:
						# Promotion
						did_promote = true
						promotion_side = white
						promote(Vector2(var2, var1))  # do NOT toggle white yet
					if var2 == 3 and selected_piece.x == 1:
						en_passant = Vector2(var2, var1)
						just_now = true
					elif en_passant != null:
						if en_passant.y == var1 and selected_piece.y != var1 and en_passant.x == selected_piece.x:
							board[en_passant.x][en_passant.y] = 0

				-1:  # Black pawn
					fifty_move_rule = 0
					if var2 == 0:
						# Promotion
						did_promote = true
						promotion_side = white  # (white == false if black was moving)
						promote(Vector2(var2, var1))
					if var2 == 4 and selected_piece.x == 6:
						en_passant = Vector2(var2, var1)
						just_now = true
					elif en_passant != null:
						if en_passant.y == var1 and selected_piece.y != var1 and en_passant.x == selected_piece.x:
							board[en_passant.x][en_passant.y] = 0

				4:  # White rook
					if selected_piece.x == 0 and selected_piece.y == 0:
						white_rook_left = true
					elif selected_piece.x == 0 and selected_piece.y == 7:
						white_rook_right = true

				-4:  # Black rook
					if selected_piece.x == 7 and selected_piece.y == 0:
						black_rook_left = true
					elif selected_piece.x == 7 and selected_piece.y == 7:
						black_rook_right = true

				6:  # White king
					if selected_piece.x == 0 and selected_piece.y == 4:
						white_king = true
						if var1 == 2:
							white_rook_left = true
							white_rook_right = true
							board[0][0] = 0
							board[0][3] = 4
						elif var1 == 6:
							white_rook_left = true
							white_rook_right = true
							board[0][7] = 0
							board[0][5] = 4
					white_king_pos = Vector2(var2, var1)

				-6:  # Black king
					if selected_piece.x == 7 and selected_piece.y == 4:
						black_king = true
						if var1 == 2:
							black_rook_left = true
							black_rook_right = true
							board[7][0] = 0
							board[7][3] = -4
						elif var1 == 6:
							black_rook_left = true
							black_rook_right = true
							board[7][7] = 0
							board[7][5] = -4
					black_king_pos = Vector2(var2, var1)

			# Reset en passant if not just set this turn
			if not just_now:
				en_passant = null

			# Execute the move on the board
			board[var2][var1] = piece_val
			board[selected_piece.x][selected_piece.y] = 0

			# If no promotion happened, we flip sides now
			if not did_promote:
				white = not white
				threefold_position(board)
				display_board()

				# Check if the move ended the game
				if is_game_over(board):
					game_over = true
				else:
					# In single-player, let AI move if it's now black's turn
					if GameSettings.is_single_player and not white:
						make_ai_move()
						if is_game_over(board):
							game_over = true

			break  # Exit loop after processing the valid move

	# Clean up move options from the UI
	delete_dots()
	state = false

	# If no valid move was found, try reselecting a piece
	if not move_found:
		var new_val = board[var2][var1]
		if (white and new_val > 0) or (not white and new_val < 0):
			selected_piece = Vector2(var2, var1)
			show_options()
			state = true
		elif is_stalemate(true) or is_stalemate(false):
			if (white and is_in_check(white_king_pos, true)) or (not white and is_in_check(black_king_pos, false)):
				print("CHECKMATE")
			else:
				print("DRAW")

	# If the game is over, print a single game-over message
	if game_over:
		if white:
			print("Checkmate! Black wins.")
		else:
			print("Checkmate! White wins.")

	# Finally, check for draw conditions if no promotion
	if not did_promote:
		if fifty_move_rule == 50:
			print("DRAW")
		elif insuficient_material():
			print("DRAW")


# 3) Modified promote():
func promote(_var: Vector2):
	# Just remember the promotion square and show the correct UI.
	promotion_square = _var
	white_pieces.visible = white
	black_pieces.visible = not white


# 4) Modified _on_button_pressed():
func _on_button_pressed(button):
	var num_char = int(button.name.substr(0, 1))

	# Use promotion_side to decide if the new piece is + (White) or - (Black).
	if promotion_side:
		board[promotion_square.x][promotion_square.y] = num_char
	else:
		board[promotion_square.x][promotion_square.y] = -num_char

	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null

	# Now we flip sides because the promotion is complete.
	white = not white

	# Update board display and check for game end.
	threefold_position(board)
	display_board()

	if is_game_over(board):
		if white:
			print("Checkmate! Black wins.")
		else:
			print("Checkmate! White wins.")
	else:
		if GameSettings.is_single_player and not white:
			make_ai_move()
			if is_game_over(board):
				if white:
					print("Checkmate! Black wins.")
				else:
					print("Checkmate! White wins.")


func get_moves(selected: Vector2, for_white: bool) -> Array:
	var piece_type = abs(board[selected.x][selected.y])
	var _moves     = []

	match piece_type:
		1:
			_moves = get_pawn_moves(selected, for_white)
		2:
			_moves = get_knight_moves(selected, for_white)
		3:
			_moves = get_bishop_moves(selected, for_white)
		4:
			_moves = get_rook_moves(selected, for_white)
		5:
			_moves = get_queen_moves(selected, for_white)
		6:
			_moves = get_king_moves(selected, for_white)

	return _moves


func get_rook_moves(piece_position: Vector2, for_white: bool) -> Array:
	var results = []
	var directions = [
		Vector2(0,1), Vector2(0,-1),
		Vector2(1,0), Vector2(-1,0)
	]

	var rook_value = 0
	if for_white:
		rook_value = 4
	else:
		rook_value = -4

	for dir in directions:
		var pos = piece_position + dir
		while is_valid_position(pos):
			if is_empty(pos):
				var old_dest = board[pos.x][pos.y]
				var old_orig = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = rook_value
				board[piece_position.x][piece_position.y] = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				board[pos.x][pos.y] = old_dest
				board[piece_position.x][piece_position.y] = old_orig

			elif is_enemy(pos, for_white):
				var captured = board[pos.x][pos.y]
				var old_orig2 = board[piece_position.x][piece_position.y]

				board[pos.x][pos.y] = rook_value
				board[piece_position.x][piece_position.y] = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				board[pos.x][pos.y] = captured
				board[piece_position.x][piece_position.y] = old_orig2
				break
			else:
				break

			pos += dir

	return results


func get_bishop_moves(piece_position: Vector2, for_white: bool) -> Array:
	var results = []
	var directions = [
		Vector2(1,1), Vector2(1,-1),
		Vector2(-1,1), Vector2(-1,-1)
	]

	var bishop_value = 0
	if for_white:
		bishop_value = 3
	else:
		bishop_value = -3

	for dir in directions:
		var pos = piece_position + dir
		while is_valid_position(pos):
			if is_empty(pos):
				var old_dest = board[pos.x][pos.y]
				var old_orig = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = bishop_value
				board[piece_position.x][piece_position.y] = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				board[pos.x][pos.y] = old_dest
				board[piece_position.x][piece_position.y] = old_orig

			elif is_enemy(pos, for_white):
				var captured = board[pos.x][pos.y]
				var old_orig2 = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = bishop_value
				board[piece_position.x][piece_position.y] = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				board[pos.x][pos.y] = captured
				board[piece_position.x][piece_position.y] = old_orig2
				break
			else:
				break

			pos += dir

	return results


func get_queen_moves(piece_position: Vector2, for_white: bool) -> Array:
	var results = []
	var directions = [
		Vector2(0,1), Vector2(0,-1),
		Vector2(1,0), Vector2(-1,0),
		Vector2(1,1), Vector2(1,-1),
		Vector2(-1,1), Vector2(-1,-1)
	]

	var queen_value = 0
	if for_white:
		queen_value = 5
	else:
		queen_value = -5

	for dir in directions:
		var pos = piece_position + dir
		while is_valid_position(pos):
			if is_empty(pos):
				var old_dest = board[pos.x][pos.y]
				var old_orig = board[piece_position.x][piece_position.y]

				board[pos.x][pos.y] = queen_value
				board[piece_position.x][piece_position.y] = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				board[pos.x][pos.y] = old_dest
				board[piece_position.x][piece_position.y] = old_orig

			elif is_enemy(pos, for_white):
				var captured = board[pos.x][pos.y]
				var old_orig2 = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = queen_value
				board[piece_position.x][piece_position.y] = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				board[pos.x][pos.y] = captured
				board[piece_position.x][piece_position.y] = old_orig2
				break
			else:
				break

			pos += dir

	return results

func get_king_moves(piece_position: Vector2, for_white: bool) -> Array:
	var results = []

	var directions = [
		Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
		Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1),
		Vector2(0, -1), Vector2(1, -1)
	]

	var king_value 
	if(for_white):
		king_value = 6
	else:
		king_value = -6	

	for dir in directions:
		var pos = piece_position + dir
		if is_valid_position(pos):
			var occupant = board[pos.x][pos.y]

			# 1) Skip if occupant is same color as King
			if (for_white and occupant > 0) or (not for_white and occupant < 0):
				continue

			# 2) Temporarily move/capture
			var old_dest = board[pos.x][pos.y]
			board[pos.x][pos.y] = king_value
			board[piece_position.x][piece_position.y] = 0

			# 3) Check for check
			if not is_in_check(pos, for_white):
				results.append(pos)

			# 4) Revert
			board[pos.x][pos.y] = old_dest
			board[piece_position.x][piece_position.y] = king_value

	return results





func get_knight_moves(piece_position: Vector2, for_white: bool) -> Array:
	var results = []
	
	# Knight offsets: 8 possible "L"-shaped moves
	var directions = [
		Vector2(2, 1),   Vector2(2, -1),
		Vector2(-2, 1),  Vector2(-2, -1),
		Vector2(1, 2),   Vector2(1, -2),
		Vector2(-1, 2),  Vector2(-1, -2)
	]


	var knight_value
	if(for_white):
		knight_value = 2
	else:
		knight_value = -2	

	for dir in directions:
		var pos = piece_position + dir
		if is_valid_position(pos):
			# Check if the square is empty
			if is_empty(pos):
				var old_dest = board[pos.x][pos.y]
				var old_orig = board[piece_position.x][piece_position.y]
				
				board[pos.x][pos.y] = knight_value
				board[piece_position.x][piece_position.y] = 0

				# Verify that our king is not in check after making this move
				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				# Revert the board
				board[pos.x][pos.y] = old_dest
				board[piece_position.x][piece_position.y] = old_orig

			# Check if the square has an enemy piece (capture possible)
			elif is_enemy(pos, for_white):
				var captured = board[pos.x][pos.y]
				var old_orig2 = board[piece_position.x][piece_position.y]
				
				board[pos.x][pos.y] = knight_value
				board[piece_position.x][piece_position.y] = 0

				# Verify that our king is not in check after capturing
				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				# Revert the board
				board[pos.x][pos.y] = captured
				board[piece_position.x][piece_position.y] = old_orig2

	# Return all valid knight moves
	return results



func get_pawn_moves(piece_position: Vector2, for_white: bool) -> Array:
	var results = []

	var direction = Vector2()
	if for_white:
		direction = Vector2(1,0)
	else:
		direction = Vector2(-1,0)

	var pawn_value = 0
	if for_white:
		pawn_value = 1
	else:
		pawn_value = -1

	var row = piece_position.x
	var col = piece_position.y

	var is_first_move = false
	if for_white and row == 1:
		is_first_move = true
	elif not for_white and row == 6:
		is_first_move = true

	# En passant
	if en_passant != null:
		if for_white and row == 4:
			if abs(en_passant.y - col) == 1:
				var pos = en_passant + direction
				var old_ep    = board[en_passant.x][en_passant.y]
				var old_orig  = board[row][col]
				var old_dest  = board[pos.x][pos.y]

				board[en_passant.x][en_passant.y] = 0
				board[pos.x][pos.y] = pawn_value
				board[row][col]     = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos)

				# undo
				board[en_passant.x][en_passant.y] = old_ep
				board[pos.x][pos.y]              = old_dest
				board[row][col]                  = old_orig

		elif not for_white and row == 3:
			if abs(en_passant.y - col) == 1:
				var pos2 = en_passant + direction
				var old_ep2   = board[en_passant.x][en_passant.y]
				var old_orig2 = board[row][col]
				var old_dest2 = board[pos2.x][pos2.y]

				board[en_passant.x][en_passant.y] = 0
				board[pos2.x][pos2.y]            = pawn_value
				board[row][col]                  = 0

				if not is_in_check(get_king_position(for_white), for_white):
					results.append(pos2)

				board[en_passant.x][en_passant.y] = old_ep2
				board[pos2.x][pos2.y]            = old_dest2
				board[row][col]                  = old_orig2

	# Move forward 1
	var forward1 = piece_position + direction
	if is_valid_position(forward1) and is_empty(forward1):
		var old_dest3 = board[forward1.x][forward1.y]
		var old_orig3 = board[row][col]
		board[forward1.x][forward1.y] = pawn_value
		board[row][col]               = 0

		if not is_in_check(get_king_position(for_white), for_white):
			results.append(forward1)

		board[forward1.x][forward1.y] = old_dest3
		board[row][col]               = old_orig3

	# Capture diagonally (col +/- 1)
	for diag_col_offset in [-1, 1]:
		var diag_pos = piece_position + direction + Vector2(0, diag_col_offset)
		if is_valid_position(diag_pos) and is_enemy(diag_pos, for_white):
			var old_dest4 = board[diag_pos.x][diag_pos.y]
			var old_orig4 = board[row][col]

			board[diag_pos.x][diag_pos.y] = pawn_value
			board[row][col]              = 0

			if not is_in_check(get_king_position(for_white), for_white):
				results.append(diag_pos)

			board[diag_pos.x][diag_pos.y] = old_dest4
			board[row][col]              = old_orig4

	# Move forward 2 if first move
	if is_first_move:
		var forward2   = piece_position + (direction * 2)
		var forward1_2 = piece_position + direction
		if is_valid_position(forward2) and is_empty(forward2) and is_empty(forward1_2):
			var old_dest5 = board[forward2.x][forward2.y]
			var old_orig5 = board[row][col]

			board[forward2.x][forward2.y] = pawn_value
			board[row][col]               = 0

			if not is_in_check(get_king_position(for_white), for_white):
				results.append(forward2)

			board[forward2.x][forward2.y] = old_dest5
			board[row][col]               = old_orig5

	return results


func is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE


func is_empty(pos: Vector2) -> bool:
	return board[pos.x][pos.y] == 0


func is_enemy(pos: Vector2, for_white: bool) -> bool:
	var val = board[pos.x][pos.y]
	if for_white and val < 0:
		return true
	if not for_white and val > 0:
		return true
	return false


func get_king_position(for_white: bool) -> Vector2:
	if for_white:
		return white_king_pos
	else:
		return black_king_pos



func is_in_check(king_pos: Vector2, for_white: bool) -> bool:
	# 1) Pawn attacks
	var pawn_dir = 0
	if for_white:
		pawn_dir = 1
	else:
		pawn_dir = -1

	var left_pawn_attack  = king_pos + Vector2(pawn_dir, -1)
	var right_pawn_attack = king_pos + Vector2(pawn_dir, 1)

	if is_valid_position(left_pawn_attack):
		if for_white and board[left_pawn_attack.x][left_pawn_attack.y] == -1:
			return true
		if not for_white and board[left_pawn_attack.x][left_pawn_attack.y] == 1:
			return true

	if is_valid_position(right_pawn_attack):
		if for_white and board[right_pawn_attack.x][right_pawn_attack.y] == -1:
			return true
		if not for_white and board[right_pawn_attack.x][right_pawn_attack.y] == 1:
			return true

	# 2) King attacks
	var king_check_dirs = [
		Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
		Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
	]
	for d in king_check_dirs:
		var kpos = king_pos + d
		if is_valid_position(kpos):
			if for_white and board[kpos.x][kpos.y] == -6:
				return true
			if not for_white and board[kpos.x][kpos.y] == 6:
				return true

	# 3) Rook/Queen lines
	var rook_dirs = [
		Vector2(0,1), Vector2(0,-1),
		Vector2(1,0), Vector2(-1,0)
	]
	for rd in rook_dirs:
		var scan = king_pos + rd
		while is_valid_position(scan):
			if not is_empty(scan):
				var piece = board[scan.x][scan.y]
				if for_white and (piece == -4 or piece == -5):
					return true
				if not for_white and (piece == 4 or piece == 5):
					return true
				break
			scan += rd

	# 4) Bishop/Queen diagonals
	var bishop_dirs = [
		Vector2(1,1), Vector2(1,-1),
		Vector2(-1,1), Vector2(-1,-1)
	]
	for bd in bishop_dirs:
		var scan2 = king_pos + bd
		while is_valid_position(scan2):
			if not is_empty(scan2):
				var piece2 = board[scan2.x][scan2.y]
				if for_white and (piece2 == -3 or piece2 == -5):
					return true
				if not for_white and (piece2 == 3 or piece2 == 5):
					return true
				break
			scan2 += bd

	# 5) Knight checks
	var knight_dirs = [
		Vector2(2,1), Vector2(2,-1), Vector2(1,2), Vector2(1,-2),
		Vector2(-2,1), Vector2(-2,-1), Vector2(-1,2), Vector2(-1,-2)
	]
	for nd in knight_dirs:
		var kscan = king_pos + nd
		if is_valid_position(kscan):
			if for_white and board[kscan.x][kscan.y] == -2:
				return true
			if not for_white and board[kscan.x][kscan.y] == 2:
				return true

	return false


func is_stalemate(for_white: bool) -> bool:
	# 1) Are we NOT in check?
	if is_in_check(get_king_position(for_white), for_white):
		return false
	# 2) No legal moves
	var possible_moves = get_moveable_areas_for_all_pieces(for_white)
	return possible_moves.size() == 0



func insuficient_material() -> bool:
	var white_piece = 0
	var black_piece = 0

	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			match board[i][j]:
				2, 3:
					if white_piece == 0:
						white_piece += 1
					else:
						return false
				-2, -3:
					if black_piece == 0:
						black_piece += 1
					else:
						return false
				6, -6, 0:
					pass
				_:
					return false
	return true


func threefold_position(var1: Array):
	for i in range(unique_board_moves.size()):
		if var1 == unique_board_moves[i]:
			amount_of_same[i] += 1
			if amount_of_same[i] >= 3:
				print("DRAW")
			return

	unique_board_moves.append(var1.duplicate(true))
	amount_of_same.append(1)


func get_moveable_areas_for_all_pieces(is_white: bool) -> Array:
	var all_moves = []
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			var val = board[i][j]
			if (is_white and val > 0) or (not is_white and val < 0):
				var origin = Vector2(i, j)
				var possible = get_moves(origin, is_white)
				for dest in possible:
					all_moves.append({
						"origin": origin,
						"destination": dest
					})
	return all_moves


func make_ai_move():
	var best_move = chess_ai.get_best_move(board, false)  # black’s move
	if best_move != null:
		board[best_move.destination.x][best_move.destination.y] = board[best_move.origin.x][best_move.origin.y]
		board[best_move.origin.x][best_move.origin.y] = 0

		white = not white
		state = false
		selected_piece = Vector2()

		display_board()


func is_game_over(board: Array) -> bool:
	return is_checkmate(true) or is_checkmate(false) or is_stalemate(true) or is_stalemate(false)
	
func is_checkmate(for_white: bool) -> bool:
	# 1) Are we in check?
	if not is_in_check(get_king_position(for_white), for_white):
		return false
	# 2) Are there any legal moves to get out of check?
	var possible_moves = get_moveable_areas_for_all_pieces(for_white)
	return possible_moves.size() == 0
	


func get_all_pieces(board: Array) -> Array:
	var pieces_list = []
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			var piece_val = board[i][j]
			if piece_val != 0:
				var piece_data = {
					"position":  Vector2(i, j),
					"is_white":  (piece_val > 0),
					"type":      ""
				}

				match abs(piece_val):
					1:
						piece_data.type = "pawn"
					2:
						piece_data.type = "knight"
					3:
						piece_data.type = "bishop"
					4:
						piece_data.type = "rook"
					5:
						piece_data.type = "queen"
					6:
						piece_data.type = "king"

				pieces_list.append(piece_data)

	return pieces_list
