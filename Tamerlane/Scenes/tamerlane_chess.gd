extends Sprite2D

const BOARD_LENGTH = 10
const BOARD_WIDTH = 13
const CELL_WIDTH = 90

# -- Standard Chess Textures-------------------
const TEXTURE_HOLDER = preload("res://Tamerlane/Scenes/texture_holder.tscn")
const BLACK_BISHOP = preload("res://Tamerlane/LanePieces/Chess_bdl45.svg")
const BLACK_KING = preload("res://Tamerlane/LanePieces/Chess_kdl44.png")
const BLACK_KNIGHT = preload("res://Tamerlane/LanePieces/Chess_ndl45.svg")
const BLACK_PAWN = preload("res://Tamerlane/LanePieces/Chess_pdl44.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Tamerlane/LanePieces/Chess_rdl45.svg")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Tamerlane/LanePieces/Chess_kll45.svg")
const WHITE_KNIGHT = preload("res://Tamerlane/LanePieces/Chess_nll45.svg")
const WHITE_PAWN = preload("res://Tamerlane/LanePieces/Chess_pll45.svg")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Tamerlane/LanePieces/Chess_rll45.svg")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")
const PIECE_MOVE = preload("res://Assets/Piece_move.png")

# -- Tamerlane Piece Textures --
const WHITE_ELEPHANT = preload("res://Tamerlane/LanePieces/Elephant_white_45x45.png")
const WHITE_CAMEL = preload("res://Tamerlane/LanePieces/Chess_sll44.png")
const WHITE_WAR_ENGINE = preload("res://Tamerlane/LanePieces/Chess_mll44.png")
const WHITE_PICKET = preload("res://Tamerlane/LanePieces/Chess_bll44.png")
const WHITE_GIRAFFE = preload("res://Tamerlane/LanePieces/Chess_Gll45.svg")
const WHITE_GENERAL = preload("res://Tamerlane/LanePieces/Chess_qll45.svg")
const WHITE_VIZIER = preload("res://Tamerlane/LanePieces/Chess_gll44.png")

const BLACK_ELEPHANT = preload("res://Tamerlane/LanePieces/Chess_edl45.svg")
const BLACK_CAMEL = preload("res://Tamerlane/LanePieces/Chess_sdl44.png")
const BLACK_WAR_ENGINE = preload("res://Tamerlane/LanePieces/Chess_mdl44.png")
const BLACK_PICKET = preload("res://Tamerlane/LanePieces/Chess_bdl45.svg")
const BLACK_GIRAFFE = preload("res://Tamerlane/LanePieces/Chess_Gdl45.svg")
const BLACK_GENERAL = preload("res://Tamerlane/LanePieces/Chess_qdl44.png")
const BLACK_VIZIER = preload("res://Tamerlane/LanePieces/Chess_gdl44.png")

@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn
@onready var white_pieces = $"../Tamerlane_CanvasLayer/Tamerlane_white_pieces"
@onready var black_pieces = $"../Tamerlane_CanvasLayer/Tamerlane_black_pieces"

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

var white_king_pos = Vector2(1, 6)
var black_king_pos = Vector2(8, 6)

# Track if each side has used the "king switch places once" special move
var white_king_switch_used = false
var black_king_switch_used = false

var fifty_move_rule = 0
var unique_board_moves : Array = []
var amount_of_same : Array = []


func _ready():
	
	print("pieces is:", pieces) 
	board.clear()

	# Tamerlane layout (10 rows, 13 columns), with citadels at columns 0 & 12:
	board.append([0,  7,  0,  8,  0,  9,  0,  9,  0,  8,  0,  7,  0]) # row 0
	board.append([0,  4,  2, 10, 11, 12,  6, 13, 11, 10,  2,  4,  0]) # row 1
	board.append([0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0]) # row 2
	for _i in range(4):
		board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])         # rows 3..6
	board.append([0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0]) # row 7
	board.append([0, -4, -2, -10, -11, -12, -6, -13, -11, -10, -2, -4, 0]) # row 8
	board.append([0, -7,  0, -8,  0, -9,  0, -9,  0, -8,  0, -7,  0]) # row 9

	display_board()

	# Connect promotion‐button signals
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

			# Selecting or moving
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
	# Clear existing child sprites
	for child in pieces.get_children():
		child.queue_free() 

	# Loop through board
	for i in BOARD_LENGTH:
		for j in BOARD_WIDTH:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(
				j * CELL_WIDTH + (CELL_WIDTH / 2),
				-i * CELL_WIDTH - (CELL_WIDTH / 2)
			)
			match board[i][j]:
				# Standard
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN

				6:  holder.texture = WHITE_KING
				5:  holder.texture = WHITE_QUEEN
				4:  holder.texture = WHITE_ROOK
				3:  holder.texture = WHITE_BISHOP
				2:  holder.texture = WHITE_KNIGHT
				1:  holder.texture = WHITE_PAWN

				# Tamerlane codes:
				-7:  holder.texture = BLACK_ELEPHANT
				-8:  holder.texture = BLACK_CAMEL
				-9:  holder.texture = BLACK_WAR_ENGINE
				-10: holder.texture = BLACK_PICKET
				-11: holder.texture = BLACK_GIRAFFE
				-12: holder.texture = BLACK_GENERAL
				-13: holder.texture = BLACK_VIZIER

				7:   holder.texture = WHITE_ELEPHANT
				8:   holder.texture = WHITE_CAMEL
				9:   holder.texture = WHITE_WAR_ENGINE
				10:  holder.texture = WHITE_PICKET
				11:  holder.texture = WHITE_GIRAFFE
				12:  holder.texture = WHITE_GENERAL
				13:  holder.texture = WHITE_VIZIER

				0:
					holder.texture = null

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
	for i in moves:
		if i.x == var2 and i.y == var1:
			fifty_move_rule += 1
			# Reset if capturing
			if is_enemy(Vector2(var2, var1)):
				fifty_move_rule = 0

			var moving_piece = board[selected_piece.x][selected_piece.y]
			# Place piece
			board[var2][var1] = moving_piece
			board[selected_piece.x][selected_piece.y] = 0

			# If it's the king, update king pos
			if abs(moving_piece) == 6:
				if moving_piece > 0:
					white_king_pos = Vector2(var2, var1)
				else:
					black_king_pos = Vector2(var2, var1)

				# If occupying opponent's citadel => "win"
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

	# Re-select if we just moved onto a square that still belongs to the same color
	if ((selected_piece.x != var2 or selected_piece.y != var1)
		and ((white and board[var2][var1] > 0) or (not white and board[var2][var1] < 0))):
		selected_piece = Vector2(var2, var1)
		show_options()
		state = true
	else:
		if is_stalemate():
			if (white and is_in_check(white_king_pos)) or (not white and is_in_check(black_king_pos)):
				print("CHECKMATE")
			else:
				print("Win")

		if fifty_move_rule == 50:
			print("DRAW")
		elif insuficient_material():
			print("DRAW")


func get_moves(selected: Vector2):
	var _moves = []
	var piece = board[selected.x][selected.y]
	match abs(piece):
		1:  _moves = get_pawn_moves(selected)
		2:  _moves = get_knight_moves(selected)
		3:  _moves = get_bishop_moves(selected)
		4:  _moves = get_rook_moves(selected)
		5:  _moves = get_queen_moves(selected)
		6:  _moves = get_king_moves(selected)
		7:  _moves = get_elephant_moves(selected)
		8:  _moves = get_camel_moves(selected)
		9:  _moves = get_war_engine_moves(selected)
		10: _moves = get_picket_moves(selected)
		11: _moves = get_giraffe_moves(selected)
		12: _moves = get_general_moves(selected)
		13: _moves = get_vizier_moves(selected)
	return _moves


# ------------------------------- PAWN --------------------------------
func get_pawn_moves(piece_position: Vector2):
	var _moves = []
	var direction = Vector2(1, 0) if white else Vector2(-1, 0)
		

	# Forward 1
	var forward = piece_position + direction
	if is_valid_position(forward) and is_empty(forward):
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
				# simulate
				var temp = board[pos.x][pos.y]
				var s = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = s
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = s
				board[pos.x][pos.y] = temp
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
	var directions = [Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0)]
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
		Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
		Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
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
func get_king_moves(piece_position: Vector2):
	var _moves = []
	var directions = [
		Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
		Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
	]

	var old_val = board[piece_position.x][piece_position.y]
	if white:
		board[white_king_pos.x][white_king_pos.y] = 0
	else:
		board[black_king_pos.x][black_king_pos.y] = 0

	# Normal 1-step moves:
	for dir in directions:
		var pos = piece_position + dir
		if is_valid_position(pos):
			if is_empty(pos) or is_enemy(pos):
				# simulate
				var temp = board[pos.x][pos.y]
				board[pos.x][pos.y] = old_val
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(pos)) or (not white and not is_in_check(pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = old_val
				board[pos.x][pos.y] = temp

	# "King switch places once" rule:
	if white and not white_king_switch_used:
		_moves += get_king_swap_moves(piece_position, true)
	elif not white and not black_king_switch_used:
		_moves += get_king_swap_moves(piece_position, false)

	# Restore the king
	if white:
		board[white_king_pos.x][white_king_pos.y] = old_val
	else:
		board[black_king_pos.x][black_king_pos.y] = old_val

	return _moves

func get_king_swap_moves(king_pos: Vector2, is_white: bool) -> Array:
	var swap_moves = []
	var king_val = board[king_pos.x][king_pos.y]
	for row in range(BOARD_LENGTH):
		for col in range(BOARD_WIDTH):
			var p = board[row][col]
			if is_white and p > 0 and abs(p) != 6:
				# Friendly piece, not a king
				var old_here = board[row][col]
				var old_king_sq = board[king_pos.x][king_pos.y]

				# swap them
				board[row][col] = king_val
				board[king_pos.x][king_pos.y] = old_here

				# see if the king is safe at (row,col)
				if not is_in_check(Vector2(row, col)):
					swap_moves.append(Vector2(row, col))

				# revert
				board[king_pos.x][king_pos.y] = old_king_sq
				board[row][col] = old_here

			elif not is_white and p < 0 and abs(p) != 6:
				# Friendly piece, not a king
				var old_here_b = board[row][col]
				var old_king_sq_b = board[king_pos.x][king_pos.y]

				board[row][col] = king_val
				board[king_pos.x][king_pos.y] = old_here_b

				if not is_in_check(Vector2(row, col)):
					swap_moves.append(Vector2(row, col))

				board[king_pos.x][king_pos.y] = old_king_sq_b
				board[row][col] = old_here_b

	return swap_moves


# ------------------------------- ELEPHANT (7) -------------------------
# Moves two squares diagonally, leaps over the intermediate square (Alfil move).
func get_elephant_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var offsets = [
		Vector2(2,2),  Vector2(2,-2),
		Vector2(-2,2), Vector2(-2,-2)
	]
	var s = board[piece_position.x][piece_position.y]
	for off in offsets:
		var newpos = piece_position + off
		if is_valid_position(newpos):
			var mid = piece_position + (off / 2)
			if not is_empty(mid):
				continue
		
			if is_empty(newpos) or is_enemy(newpos):
				var store = board[newpos.x][newpos.y]
				board[newpos.x][newpos.y] = s
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(newpos)
				board[piece_position.x][piece_position.y] = s
				board[newpos.x][newpos.y] = store
	return _moves


# ------------------------------- CAMEL (8) ----------------------------
func get_camel_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var offsets = [
		Vector2(3,1),  Vector2(3,-1),  Vector2(-3,1),  Vector2(-3,-1),
		Vector2(1,3),  Vector2(1,-3),  Vector2(-1,3),  Vector2(-1,-3),
	]
	var s = board[piece_position.x][piece_position.y]
	for off in offsets:
		var newpos = piece_position + off
		if is_valid_position(newpos):
			if is_empty(newpos) or is_enemy(newpos):
				
				var store = board[newpos.x][newpos.y]
				board[newpos.x][newpos.y] = s
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(newpos)
				board[piece_position.x][piece_position.y] = s
				board[newpos.x][newpos.y] = store
	return _moves


# ------------------------------- WAR ENGINE (9) -----------------------
func get_war_engine_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var offsets = [
		Vector2(2,0), Vector2(-2,0),
		Vector2(0,2), Vector2(0,-2)
	]
	var s = board[piece_position.x][piece_position.y]
	for off in offsets:
		var newpos = piece_position + off
		if is_valid_position(newpos):
			var mid = piece_position + (off / 2)
			if not is_empty(mid):
				continue
			if is_empty(newpos) or is_enemy(newpos):
			
				var store = board[newpos.x][newpos.y]
				board[newpos.x][newpos.y] = s
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(newpos)
				board[piece_position.x][piece_position.y] = s
				board[newpos.x][newpos.y] = store
	return _moves


# ------------------------------- PICKET (10) --------------------------
func get_picket_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var directions = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	var s = board[piece_position.x][piece_position.y]
	for dir in directions:
		var pos = piece_position + dir
		var steps = 1
		while is_valid_position(pos):
			# The Picket must move >= 2 squares, so ignore the very first square:
			if steps == 1:
				# just check if blocked, but do NOT allow a move here
				if not is_empty(pos):
					# if blocked by any piece (even an enemy), break
					break
			else:
				# steps >= 2
				if is_empty(pos) or is_enemy(pos):
					# simulate
					var store = board[pos.x][pos.y]
					board[pos.x][pos.y] = s
					board[piece_position.x][piece_position.y] = 0
					if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
						_moves.append(pos)
					board[piece_position.x][piece_position.y] = s
					board[pos.x][pos.y] = store
					# if enemy piece was here, we can't go further
					if is_enemy(pos):
						break
				else:
					break
			steps += 1
			pos += dir
	return _moves


# ------------------------------- GIRAFFE (11) -------------------------
# "Restricted gryphon": 1 diagonal step, then a minimum of 3 squares
# horizontally or vertically, unobstructed.
func get_giraffe_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var s = board[piece_position.x][piece_position.y]

	var diag_dirs = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	var orth_dirs = [Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0)]

	for d in diag_dirs:
		var mid = piece_position + d
		if not is_valid_position(mid):
			continue
		# Giraffe leaps the first diagonal step (check if blocked? - it is typically a leap)
		# But Tamerlane says "unobstructed by pieces in between"? 
		# Usually the diagonal step can leap. If there's an allied piece exactly on 'mid', we can't stand on top of them.
		# So let's say if there's a piece of either color in 'mid', we skip.
		if not is_empty(mid):
			continue

		# Now from 'mid', it can move at least 3 squares in one orth direction
		for od in orth_dirs:
			var pos = mid + od
			var distance = 1
			while is_valid_position(pos):
				if not is_empty(pos):
					# If blocked, we cannot go further
					break
				distance += 1
				if distance >= 3:
					# from 3 squares onward, we can step or capture
					# Try capturing if there's an enemy piece *on* that square
					# but we just found it's empty in this check, so keep going
					# We do actually add the empty position as a valid move
					# simulate
					var store = board[pos.x][pos.y]
					board[pos.x][pos.y] = s
					board[piece_position.x][piece_position.y] = 0
					if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
						_moves.append(pos)
					board[piece_position.x][piece_position.y] = s
					board[pos.x][pos.y] = store

				pos += od

			# Also consider capturing an enemy piece exactly on that path 
			# once we get to distance >= 3.
			# Actually, to handle capturing, we can do a second pass: if we encounter an enemy piece,
			# that might be a valid landing square. But in the code above we skip as soon as we "not is_empty(pos)".
			# So let's do an extra check: if we first empty-run until we find a piece:
			var pos2 = mid + od
			var dist2 = 1
			while is_valid_position(pos2):
				if not is_empty(pos2):
					# if enemy, can we capture? only if dist2 >= 3
					if dist2 >= 3 and is_enemy(pos2):
						var store2 = board[pos2.x][pos2.y]
						board[pos2.x][pos2.y] = s
						board[piece_position.x][piece_position.y] = 0
						if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
							_moves.append(pos2)
						board[piece_position.x][piece_position.y] = s
						board[pos2.x][pos2.y] = store2
					break
				dist2 += 1
				pos2 += od

	return _moves


# ------------------------------- GENERAL (12) -------------------------
# (Ferz): moves exactly 1 square diagonally
func get_general_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var directions = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	var s = board[piece_position.x][piece_position.y]
	for dir in directions:
		var newpos = piece_position + dir
		if is_valid_position(newpos):
			if is_empty(newpos) or is_enemy(newpos):
				# simulate
				var store = board[newpos.x][newpos.y]
				board[newpos.x][newpos.y] = s
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(newpos)
				board[piece_position.x][piece_position.y] = s
				board[newpos.x][newpos.y] = store
	return _moves


# ------------------------------- VIZIER (13) --------------------------
# (Wazir): moves exactly 1 square horizontally or vertically
func get_vizier_moves(piece_position: Vector2) -> Array:
	var _moves = []
	var directions = [Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0)]
	var s = board[piece_position.x][piece_position.y]
	for dir in directions:
		var newpos = piece_position + dir
		if is_valid_position(newpos):
			if is_empty(newpos) or is_enemy(newpos):
				# simulate
				var store = board[newpos.x][newpos.y]
				board[newpos.x][newpos.y] = s
				board[piece_position.x][piece_position.y] = 0
				if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
					_moves.append(newpos)
				board[piece_position.x][piece_position.y] = s
				board[newpos.x][newpos.y] = store
	return _moves


# ---------------------------------------------------------------------
# Checking if a king is attacked
# ---------------------------------------------------------------------
func is_in_check(king_pos: Vector2) -> bool:
	# This logic is still mostly standard, so you may want to expand it
	# to handle Tamerlane pieces threatening the king. 
	# For now it checks only standard rook/bishop/knight/queen/pawn/king lines.
	var directions = [
		Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
		Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
	]
	var pawn_direction = 1 if white else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction,1),
		king_pos + Vector2(pawn_direction,-1)
	]
	# Pawn
	for pa in pawn_attacks:
		if is_valid_position(pa):
			if (white and board[pa.x][pa.y] == -1) or (not white and board[pa.x][pa.y] == 1):
				return true

	# King adjacent
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
		Vector2(2,1),  Vector2(2,-1),  Vector2(1,2),  Vector2(1,-2),
		Vector2(-2,1), Vector2(-2,-1), Vector2(-1,2), Vector2(-1,-2)
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
	# Extend this if you wish to handle typical Tamerlane "insufficient material"
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


func is_valid_position(pos: Vector2) -> bool:
	var row = pos.x
	var col = pos.y
	if row < 0 or row >= BOARD_LENGTH:
		return false
	# Tamerlane board widths: columns 1..11 are normal squares
	# columns 0 and 12 are "citadels" only valid at certain row combos:
	if col >= 1 and col <= 11:
		return true
	# White's citadel (row=1,col=0), (row=1,col=12)
	if row == 1 and col == 0 :
		return true
	# Black's citadel (row=8,col=0), (row=8,col=12)
	if row == 8 and  col == 12:
		return true
	return false


func is_empty(pos: Vector2) -> bool:
	return board[pos.x][pos.y] == 0


func is_enemy(pos: Vector2) -> bool:
	if (white and board[pos.x][pos.y] < 0) or (not white and board[pos.x][pos.y] > 0):
		return true
	return false


func promote(_var: Vector2):
	# Basic example, if you choose to keep promotion:
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
