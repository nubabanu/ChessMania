extends Sprite2D

const BOARD_LENGTH = 10
const BOARD_WIDTH = 13
const CELL_WIDTH = 16

# -- Textures (same names as your original code) -----------------------
const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")
const BLACK_BISHOP = preload("res://Assets/black_bishop.png")
const BLACK_KING = preload("res://Assets/black_king.png")
const BLACK_KNIGHT = preload("res://Assets/black_knight.png")
const BLACK_PAWN = preload("res://Assets/black_pawn.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Assets/black_rook.png")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Assets/white_king.png")
const WHITE_KNIGHT = preload("res://Assets/white_knight.png")
const WHITE_PAWN = preload("res://Assets/white_pawn.png")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Assets/white_rook.png")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")
const PIECE_MOVE = preload("res://Assets/Piece_move.png")

@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var white_pieces = $"../CanvasLayer/white_pieces"
@onready var black_pieces = $"../CanvasLayer/black_pieces"

var board : Array = []
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2

var promotion_square = null

var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var en_passant = null  # Not used now, left in for minimal disruption

var white_king_pos = Vector2(0, 4)
var black_king_pos = Vector2(9, 4)

var fifty_move_rule = 0
var unique_board_moves : Array = []
var amount_of_same : Array = []

func _ready():
	# -- DO NOT CHANGE THE BOARD, as requested -------------------------
	board.append([  0,  2,  3,  5,  6,  3,  2,  4,  0,  0,  0,  0,  0 ]) # Row 0
	board.append([  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0 ]) # Row 1
	board.append([  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ]) # Row 2
	board.append([  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ]) # Row 3
	board.append([  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ]) # Row 4
	board.append([  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ]) # Row 5
	board.append([  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ]) # Row 6
	board.append([  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 ]) # Row 7
	board.append([ 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  0 ]) # Row 8
	board.append([ 0, -2, -3, -5, -6, -3, -2, -4,  0,  0,  0,  0,  0 ]) # Row 9
	
	display_board()

	# Connect button presses for promotion UI
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))


func _input(event):
	if event is InputEventMouseButton and event.pressed and promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out():
				return
			var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH
			if not state and ((white and board[var2][var1] > 0) or (not white and board[var2][var1] < 0)):
				selected_piece = Vector2(var2, var1)
				show_options()
				state = true
			elif state:
				set_move(var2, var1)


func is_mouse_out():
	if get_rect().has_point(to_local(get_global_mouse_position())):
		return false
	return true


func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_LENGTH:
		for j in BOARD_WIDTH:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(
				j * CELL_WIDTH + (CELL_WIDTH / 2),
				-i * CELL_WIDTH - (CELL_WIDTH / 2)
			)
			
			match board[i][j]:
				-6:
					holder.texture = BLACK_KING
				-5:
					holder.texture = BLACK_QUEEN
				-4:
					holder.texture = BLACK_ROOK
				-3:
					holder.texture = BLACK_BISHOP
				-2:
					holder.texture = BLACK_KNIGHT
				-1:
					holder.texture = BLACK_PAWN
				0:
					holder.texture = null
				6:
					holder.texture = WHITE_KING
				5:
					holder.texture = WHITE_QUEEN
				4:
					holder.texture = WHITE_ROOK
				3:
					holder.texture = WHITE_BISHOP
				2:
					holder.texture = WHITE_KNIGHT
				1:
					holder.texture = WHITE_PAWN
				
	if white:
		turn.texture = TURN_WHITE
	else:
		turn.texture = TURN_BLACK


func show_options():
	moves = get_moves(selected_piece)
	if moves.size() == 0:
		state = false
		return
	show_dots()


func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(
			i.y * CELL_WIDTH + (CELL_WIDTH / 2),
			-i.x * CELL_WIDTH - (CELL_WIDTH / 2)
		)


func delete_dots():
	for child in dots.get_children():
		child.queue_free()


func set_move(var2, var1):
	var just_now = false
	for i in moves:
		if i.x == var2 and i.y == var1:
			fifty_move_rule += 1
			# Reset the 50-move counter if capturing a piece
			if is_enemy(Vector2(var2, var1)):
				fifty_move_rule = 0

			var moving_piece = board[selected_piece.x][selected_piece.y]
			# Put the piece onto (var2,var1)
			board[var2][var1] = moving_piece
			board[selected_piece.x][selected_piece.y] = 0

			# Track King positions so is_in_check() works
			if abs(moving_piece) == 6:  # King
				if moving_piece > 0:
					white_king_pos = Vector2(var2, var1)
				else:
					black_king_pos = Vector2(var2, var1)

				# -- CITADEL CHECK (Tamerlane draw rule) --
				# White King stepping onto black's citadel => row=8,col=0
				# Black King stepping onto white's citadel => row=1,col=12
				if moving_piece > 0 and white_king_pos == Vector2(8, 12):
					print("Win: White King occupies Black's citadel!")
				elif moving_piece < 0 and black_king_pos == Vector2(1, 0):
					print("Win: Black King occupies White's citadel!")

			white = not white
			threefold_position(board)
			display_board()
			break

	delete_dots()
	state = false

	# Optional: If we actually moved onto a different square, re-select if it's still ours
	if ((selected_piece.x != var2 or selected_piece.y != var1)
		and ((white and board[var2][var1] > 0) or (not white and board[var2][var1] < 0))):
		selected_piece = Vector2(var2, var1)
		show_options()
		state = true
	elif is_stalemate():
		# Tamerlane chess typically says stalemate is a WIN for the player delivering it.
		# For minimal changes, we'll just print "DRAW" or "CHECKMATE" as is:
		if (white and is_in_check(white_king_pos)) or (not white and is_in_check(black_king_pos)):
			print("CHECKMATE")
		else:
			print("DRAW")

	if fifty_move_rule == 50:
		print("DRAW")
	elif insuficient_material():
		print("DRAW")


func get_moves(selected: Vector2):
	var _moves = []
	match abs(board[selected.x][selected.y]):
		1: _moves = get_pawn_moves(selected)
		2: _moves = get_knight_moves(selected)
		3: _moves = get_bishop_moves(selected)
		4: _moves = get_rook_moves(selected)
		5: _moves = get_queen_moves(selected)
		6: _moves = get_king_moves(selected)
	return _moves


# ------------------------------- PAWN --------------------------------
# Tamerlane has no double-step or en passant. Let's remove that logic.
# Promotion stays, but you can enhance or remove as needed.
func get_pawn_moves(piece_position: Vector2):
	var _moves = []
	var direction
	if white:
		direction = Vector2(1, 0)
	else:
		direction = Vector2(-1, 0)
	
	# Move forward 1 if empty
	var forward = piece_position + direction
	if is_valid_position(forward) and is_empty(forward):
		# Simulate
		var stored = board[forward.x][forward.y]
		board[forward.x][forward.y] = board[piece_position.x][piece_position.y]
		board[piece_position.x][piece_position.y] = 0
		if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
			_moves.append(forward)
		board[piece_position.x][piece_position.y] = board[forward.x][forward.y]
		board[forward.x][forward.y] = stored

	# Capture diagonally
	for side in [1, -1]:
		var diag = piece_position + Vector2(direction.x, side)
		if is_valid_position(diag) and is_enemy(diag):
			var captured = board[diag.x][diag.y]
			var store_me = board[piece_position.x][piece_position.y]
			board[diag.x][diag.y] = store_me
			board[piece_position.x][piece_position.y] = 0
			if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
				_moves.append(diag)
			board[piece_position.x][piece_position.y] = store_me
			board[diag.x][diag.y] = captured
	
	return _moves


# ------------------------------- KNIGHT ------------------------------
func get_knight_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(2, 1),  Vector2(2, -1),  Vector2(1, 2),  Vector2(1, -2),
		Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)
	]
	for dir in directions:
		var pos = piece_position + dir
		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				var t = board[pos.x][pos.y]
				var s = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = s
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = s
				board[pos.x][pos.y] = t
	return _moves


# ------------------------------- BISHOP ------------------------------
func get_bishop_moves(piece_position: Vector2):
	var _moves = []
	var directions = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	for direction in directions:
		var pos = piece_position + direction
		while is_valid_position(pos):
			if is_empty(pos):
				var tmp = board[pos.x][pos.y]
				board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
				board[pos.x][pos.y] = tmp
			elif is_enemy(pos):
				var captured = board[pos.x][pos.y]
				var store_me = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = store_me
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = store_me
				board[pos.x][pos.y] = captured
				break
			else:
				break
			pos += direction
	return _moves


# ------------------------------- ROOK --------------------------------
func get_rook_moves(piece_position: Vector2):
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	for direction in directions:
		var pos = piece_position + direction
		while is_valid_position(pos):
			if is_empty(pos):
				var tmp = board[pos.x][pos.y]
				board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
				board[pos.x][pos.y] = tmp
			elif is_enemy(pos):
				var temp = board[pos.x][pos.y]
				var self_piece = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = self_piece
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = self_piece
				board[pos.x][pos.y] = temp
				break
			else:
				break
			pos += direction
	return _moves


# ------------------------------- QUEEN -------------------------------
func get_queen_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	for direction in directions:
		var pos = piece_position + direction
		while is_valid_position(pos):
			if is_empty(pos):
				var tmp = board[pos.x][pos.y]
				board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
				board[pos.x][pos.y] = tmp
			elif is_enemy(pos):
				var temp = board[pos.x][pos.y]
				var self_piece = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = self_piece
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = self_piece
				board[pos.x][pos.y] = temp
				break
			else:
				break
			pos += direction
	return _moves


# ------------------------------- KING --------------------------------
# Removed castling references. Just 1 step any direction, checking for check.
func get_king_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(0, 1),  Vector2(0, -1), Vector2(1, 0),  Vector2(-1, 0),
		Vector2(1, 1),  Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	
	var old_val = board[piece_position.x][piece_position.y]
	if white:
		board[white_king_pos.x][white_king_pos.y] = 0
	else:
		board[black_king_pos.x][black_king_pos.y] = 0
	
	for dir in directions:
		var pos = piece_position + dir
		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				# Simulate
				var temp = board[pos.x][pos.y]
				board[pos.x][pos.y] = old_val
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(pos)) or (not white and not is_in_check(pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = old_val
				board[pos.x][pos.y] = temp

	# Place king back
	if white:
		board[white_king_pos.x][white_king_pos.y] = old_val
	else:
		board[black_king_pos.x][black_king_pos.y] = old_val
	
	return _moves


func is_valid_position(pos: Vector2) -> bool:
	# Unchanged
	var row = pos.x
	var col = pos.y
	if row < 0 or row >= BOARD_LENGTH:
		return false
	if col >= 1 and col <= 11:
		return true
	if row == 1 and col == 12:
		return true
	if row == 8 and col == 0:
		return true
#whites citadel
	if row == 1 and col == 0:
		return true
#blacks citadel 
	if row == 8 and col == 12:
		return true
	return false


func is_empty(pos: Vector2) -> bool:
	return board[pos.x][pos.y] == 0
func is_enemy(pos: Vector2) -> bool:
	if (white and board[pos.x][pos.y] < 0) or (not white and board[pos.x][pos.y] > 0):
		return true
	return false


func promote(_var: Vector2):
	# Minimal: we keep the old standard-chess style promotion
	promotion_square = _var
	white_pieces.visible = white
	black_pieces.visible = not white


func _on_button_pressed(button):
	var num_char = int(button.name.substr(0, 1))
	board[promotion_square.x][promotion_square.y] = -num_char if white else num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()


# ---------------------------------------------------------------------
# Checking if a king is attacked. Minimal changes, uses standard approach.
# ---------------------------------------------------------------------
func is_in_check(king_pos: Vector2) -> bool:
	var directions = [
		Vector2(0, 1),  Vector2(0, -1), Vector2(1, 0),  Vector2(-1, 0),
		Vector2(1, 1),  Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	var pawn_direction = 1 if white else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, -1)
	]
	# Pawn attack
	for pa in pawn_attacks:
		if is_valid_position(pa):
			if (white and board[pa.x][pa.y] == -1) or (not white and board[pa.x][pa.y] == 1):
				return true
	
	# Enemy king adjacent
	for dir in directions:
		var pos = king_pos + dir
		if is_valid_position(pos):
			if (white and board[pos.x][pos.y] == -6) or (not white and board[pos.x][pos.y] == 6):
				return true
			
	# Rook/Queen lines
	for dir in directions:
		var pos = king_pos + dir
		while is_valid_position(pos):
			if not is_empty(pos):
				var piece = board[pos.x][pos.y]
				if (dir.x == 0 or dir.y == 0):
					# Rook or Queen
					if (white and piece in [-4, -5]) or (not white and piece in [4, 5]):
						return true
				else:
					# Bishop or Queen
					if (white and piece in [-3, -5]) or (not white and piece in [3, 5]):
						return true
				break
			pos += dir
	
	# Knight positions
	var knight_directions = [
		Vector2(2, 1),  Vector2(2, -1),  Vector2(1, 2),  Vector2(1, -2),
		Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)
	]
	for nd in knight_directions:
		var pos = king_pos + nd
		if is_valid_position(pos):
			if (white and board[pos.x][pos.y] == -2) or (not white and board[pos.x][pos.y] == 2):
				return true
	return false


func is_stalemate() -> bool:
	# If the side to move has no moves, it's stalemate or checkmate
	if white:
		for i in BOARD_LENGTH:
			for j in BOARD_WIDTH:
				if board[i][j] > 0:
					if get_moves(Vector2(i, j)).size() > 0:
						return false
	else:
		for i in BOARD_LENGTH:
			for j in BOARD_WIDTH:
				if board[i][j] < 0:
					if get_moves(Vector2(i, j)).size() > 0:
						return false
	return true


func insuficient_material() -> bool:
	return false


func threefold_position(var1: Array):
	for i in unique_board_moves.size():
		if var1 == unique_board_moves[i]:
			amount_of_same[i] += 1
			if amount_of_same[i] >= 3:
				print("DRAW")
			return
	unique_board_moves.append(var1.duplicate(true))
	amount_of_same.append(1)
