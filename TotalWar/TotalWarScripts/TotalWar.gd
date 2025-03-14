extends Control

@onready var board = $ChessBoard
@onready var piece_container = $PieceContainer
@onready var tile_container = $ChessBoard/TileContainer
@onready var chessboard_texture = $ChessBoard/Background
@onready var black_piece_container = $BlackPieceContainer
@onready var turn_label = $TurnLabel
@onready var back_button = $BackButton

var ending_popup_scene = preload("res://scenesMenu/EndingPopup.tscn")
var ending_popup_instance

var white_available_pieces = {}
var black_available_pieces = {}
var tiles = []
var tile_size = Vector2(60, 60)
var tile_spacing = Vector2(5, 5)
var board_offset = Vector2()

var white_pieces_placed = 0
var black_pieces_placed = 0
var total_white_pieces = 1  # King
var total_black_pieces = 1  # King

enum GamePhase { PLACEMENT, PLAY }
var game_phase = GamePhase.PLACEMENT

# Chess piece textures
var piece_textures = {

	"WPawn": preload("res://TotalWar/Assets/ChessTextures/WPawn.png"),
	"WBishop": preload("res://TotalWar/Assets/ChessTextures/WBishop.png"),
	"WKnight": preload("res://TotalWar/Assets/ChessTextures/WKnight.png"),
	"WRook": preload("res://TotalWar/Assets/ChessTextures/WRook.png"),
	"WQueen": preload("res://TotalWar/Assets/ChessTextures/WQueen.png"),
	"WKing": preload("res://TotalWar/Assets/ChessTextures/WKing.png"),
	"BPawn": preload("res://TotalWar/Assets/ChessTextures/BPawn.png"),
	"BBishop": preload("res://TotalWar/Assets/ChessTextures/BBishop.png"),
	"BKnight": preload("res://TotalWar/Assets/ChessTextures/BKnight.png"),
	"BRook": preload("res://TotalWar/Assets/ChessTextures/BRook.png"),
	"BQueen": preload("res://TotalWar/Assets/ChessTextures/BQueen.png"),
	"BKing": preload("res://TotalWar/Assets/ChessTextures/BKing.png"),
}

# ---------------------------------------------------------------
# board_state[row][col] = occupant = {
#   "node": <TextureRect>,
#   "type": <"Pawn", "Rook", ...>,
#   "color": Global.Player.WHITE or BLACK,
#   "moved": false,  # track if piece has moved (for castling, etc.)
# }
var board_state = []

# Track last pawn move for en passant
var last_move = {
	"from": null,
	"to": null,
	"piece": null,
	"two_step": false
}

func _ready():
	align_chessboard_background()
	generate_tiles()
	initialize_board_state()
	# Instance the pop-up once at the start
	ending_popup_instance = ending_popup_scene.instantiate()
	add_child(ending_popup_instance)
	back_button.pressed.connect(Global.on_back_pressed)

	create_piece("WKing", Global.Player.WHITE)
	create_piece("BKing", Global.Player.BLACK)
	load_purchased_pieces()
	update_turn_label()

	black_piece_container.visible = false

# ------------------------------------------------
# --- BOARD SETUP & UTILITIES --------------------
func initialize_board_state():
	board_state.clear()
	for i in range(8):
		board_state.append([])
		for j in range(8):
			board_state[i].append(null)

func hide_white_pieces():
	if Global.turn == Global.Player.BLACK:
		for piece in board.get_children():
			if piece.get_meta("player") == Global.Player.WHITE:
				piece.visible = false

func align_chessboard_background():
	var window_size = get_viewport_rect().size
	var board_size = Vector2(648, 648)
	var centered_position = (window_size - board_size) / 2
	chessboard_texture.position = centered_position

	var grid_size = tile_size * 8 + tile_spacing * (8 - 1)
	board_offset = (board_size - grid_size) / 2

	tile_container.position = chessboard_texture.position

func generate_tiles():
	for child in tile_container.get_children():
		tile_container.remove_child(child)
	tiles.clear()

	for row in range(8):
		for col in range(8):
			var tile = ColorRect.new()
			tile.z_index = 1
			tile.size = tile_size
			tile.color = Color(0.8, 0.8, 0.8, 0.0)

			var tile_style = StyleBoxFlat.new()
			tile_style.bg_color = tile.color
			tile_style.border_color = Color(0, 0, 0, 1)
			tile_style.border_width_top = 2
			tile_style.border_width_bottom = 2
			tile_style.border_width_left = 2
			tile_style.border_width_right = 2
			tile.add_theme_stylebox_override("panel", tile_style)

			var highlight = ColorRect.new()
			highlight.name = "HighlightOverlay"
			highlight.size = tile_size - Vector2(4, 4)
			highlight.position = Vector2(2, 2)
			highlight.color = Color(0, 1, 0, 0.5)
			highlight.visible = false
			tile.add_child(highlight)

			tile.set_meta("row", row)
			tile.set_meta("col", col)

			tile.position = Vector2(col * (tile_size.x + tile_spacing.x), row * (tile_size.y + tile_spacing.y)) + board_offset
			tile_container.add_child(tile)
			tiles.append(tile)

func load_purchased_pieces():
	white_available_pieces = Global.white_purchased_pieces
	black_available_pieces = Global.black_purchased_pieces

	if white_available_pieces.is_empty():
		print("No purchased white pieces found!")
	if black_available_pieces.is_empty():
		print("No purchased black pieces found!")

	for piece_name in white_available_pieces.keys():
		var count = white_available_pieces[piece_name]
		if typeof(count) != TYPE_INT:
			print("Warning: Piece count for", piece_name, "is not an integer:", count)
			continue
		for i in range(count):
			create_piece(piece_name, Global.Player.WHITE)
			total_white_pieces += 1

	for piece_name in black_available_pieces.keys():
		var count = black_available_pieces[piece_name]
		if typeof(count) != TYPE_INT:
			print("Warning: Piece count for", piece_name, "is not an integer:", count)
			continue
		for i in range(count):
			create_piece(piece_name, Global.Player.BLACK)
			total_black_pieces += 1

func create_piece(piece_name: String, player_color: int):
	if not piece_textures.has(piece_name):
		print("⚠️ Error: Missing preloaded texture for", piece_name)
		return

	var piece = TextureRect.new()
	piece.texture = piece_textures[piece_name]  # Directly assign preloaded texture
	piece.mouse_filter = Control.MOUSE_FILTER_STOP
	piece.position = Vector2(50, 850)
	piece.z_index = 2
	piece.custom_minimum_size = Vector2(60, 60)
	piece.pivot_offset = piece.custom_minimum_size / 2

	piece.set_meta("occupied_tile", null)
	piece.set_script(load("res://TotalWar/TotalWarScripts/DraggablePiece.gd"))
	piece.set_meta("player", player_color)

	# Extract the piece type (e.g., "WKing" → "King")
	var piece_type = piece_name.substr(1, piece_name.length() - 1)
	piece.set_meta("piece_type", piece_type)

	if player_color == Global.Player.WHITE:
		piece_container.add_child(piece)
	else:
		black_piece_container.add_child(piece)

	print("✅ Created piece:", piece_name, "at", piece.position)


# ------------------------------------------------
# --- HIGHLIGHTING & VALIDATION ------------------
func highlight_tiles(exclude_piece = null):
	reset_tile_highlights()
	if exclude_piece == null:
		return

	if game_phase == GamePhase.PLACEMENT:
		highlight_placement_tiles(exclude_piece)
	else:
		highlight_play_tiles(exclude_piece)

func highlight_placement_tiles(piece):
	var occupied_tile = piece.get_meta("occupied_tile")
	var player = piece.get_meta("player")
	for tile in tiles:
		if tile == occupied_tile:
			continue
		var tile_row = tile.get_meta("row")
		if player == Global.Player.WHITE and tile_row >= (8 - Global.playable_lines):
			if not is_tile_occupied(tile):
				tile.get_node("HighlightOverlay").visible = true
		elif player == Global.Player.BLACK and tile_row < Global.playable_lines:
			if not is_tile_occupied(tile):
				tile.get_node("HighlightOverlay").visible = true

func highlight_play_tiles(piece):
	var valid_moves = get_legal_moves(piece)
	for move in valid_moves:
		var tile_index = move[0] * 8 + move[1]
		if tile_index >= 0 and tile_index < tiles.size():
			var tile = tiles[tile_index]
			tile.get_node("HighlightOverlay").visible = true

func reset_tile_highlights():
	for tile in tiles:
		var hl = tile.get_node("HighlightOverlay")
		if hl:
			hl.visible = false

func is_tile_occupied(tile: ColorRect) -> bool:
	var r = tile.get_meta("row")
	var c = tile.get_meta("col")
	return board_state[r][c] != null

func occupant_color_at(row: int, col: int) -> int:
	if board_state[row][col] == null:
		return -1
	return board_state[row][col].color

# -------------------------
# ALLOW occupant TO BE NULL
func set_occupant(row: int, col: int, occupant):
	board_state[row][col] = occupant


func clear_occupant(row: int, col: int):
	board_state[row][col] = null

func get_occupant(row: int, col: int):
	return board_state[row][col]


# ---------------------------------------------------------------
# --- CHESS MOVE GENERATION (PSEUDO-LEGAL) ----------------------

func get_valid_moves(piece: TextureRect) -> Array:
	var from_tile = piece.get_meta("occupied_tile")
	if not from_tile:
		return []
	var row = from_tile.get_meta("row")
	var col = from_tile.get_meta("col")

	var piece_type = piece.get_meta("piece_type")
	var color = piece.get_meta("player")

	match piece_type:
		"Pawn":
			return get_pawn_moves(row, col, color)
		"Rook":
			return get_rook_moves(row, col, color)
		"Knight":
			return get_knight_moves(row, col, color)
		"Bishop":
			return get_bishop_moves(row, col, color)
		"Queen":
			var rook_like = get_rook_moves(row, col, color)
			var bishop_like = get_bishop_moves(row, col, color)
			return rook_like + bishop_like
		"King":
			return get_king_moves(row, col, color)
		_:
			return []


# --- Check-Legal Moves: Filter out moves that leave your king in check
func get_legal_moves(piece: TextureRect) -> Array:
	var pseudo_moves = get_valid_moves(piece)
	var color = piece.get_meta("player")

	var legal_moves = []
	var from_tile = piece.get_meta("occupied_tile")
	if not from_tile:
		return legal_moves

	var orig_row = from_tile.get_meta("row")
	var orig_col = from_tile.get_meta("col")
	var occupant = get_occupant(orig_row, orig_col)
	if occupant == null:
		return legal_moves

	for new_pos in pseudo_moves:
		var to_row = new_pos[0]
		var to_col = new_pos[1]

		var captured = get_occupant(to_row, to_col)

		# Simulate
		set_occupant(to_row, to_col, occupant)  # occupant is Dictionary
		clear_occupant(orig_row, orig_col)

		if not occupant.has("moved"):
			occupant["moved"] = false

		# Check if king is in check
		if not is_king_in_check(color):
			legal_moves.append(new_pos)

		# Revert
		set_occupant(orig_row, orig_col, occupant)
		set_occupant(to_row, to_col, captured)

	return legal_moves

func get_pawn_moves(r: int, c: int, color) -> Array:
	var moves = []

	var direction = 0
	if color == Global.Player.WHITE:
		direction = -1
	else:
		direction = 1

	var start_row = 0
	if color == Global.Player.WHITE:
		start_row = 6
	else:
		start_row = 1

	var fr = r + direction
	if fr >= 0 and fr < 8:
		if board_state[fr][c] == null:
			moves.append([fr, c])
			if r == start_row:
				var fr2 = r + 2 * direction
				if board_state[fr2][c] == null:
					moves.append([fr2, c])

		for dc in [-1, 1]:
			var cc = c + dc
			if cc >= 0 and cc < 8:
				var occupant_capture = board_state[fr][cc]
				if occupant_capture != null and occupant_capture["color"] != color:
					moves.append([fr, cc])

	if last_move["two_step"] == true and last_move["piece"] != null and last_move["piece"]["type"] == "Pawn":
		var last_to = last_move["to"]
		var lr = last_to[0]
		var lc = last_to[1]
		if r == lr and abs(c - lc) == 1:
			var en_passant_row = lr + direction
			var en_passant_col = lc
			moves.append([en_passant_row, en_passant_col])

	return moves

func get_rook_moves(r: int, c: int, color) -> Array:
	var moves = []
	var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	for dir in directions:
		moves += slide_in_direction(r, c, int(dir.x), int(dir.y), color)
	return moves

func get_bishop_moves(r: int, c: int, color) -> Array:
	var moves = []
	var directions = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	for dir in directions:
		moves += slide_in_direction(r, c, int(dir.x), int(dir.y), color)
	return moves

func get_knight_moves(r: int, c: int, color) -> Array:
	var moves = []
	var offsets = [
		[2, 1], [2, -1], [-2, 1], [-2, -1],
		[1, 2], [1, -2], [-1, 2], [-1, -2],
	]
	for offset in offsets:
		var nr = r + offset[0]
		var nc = c + offset[1]
		if nr >= 0 and nr < 8 and nc >= 0 and nc < 8:
			var occupant_spot = board_state[nr][nc]
			if occupant_spot == null or occupant_spot["color"] != color:
				moves.append([nr, nc])
	return moves

func get_king_moves(r: int, c: int, color) -> Array:
	var moves = []
	for row_off in range(-1, 2):
		for col_off in range(-1, 2):
			if row_off == 0 and col_off == 0:
				continue
			var nr = r + row_off
			var nc = c + col_off
			if nr >= 0 and nr < 8 and nc >= 0 and nc < 8:
				var occupant_spot = board_state[nr][nc]
				if occupant_spot == null or occupant_spot["color"] != color:
					moves.append([nr, nc])

	var occupant_here = board_state[r][c]
	if occupant_here and occupant_here["type"] == "King":
		if not occupant_here.has("moved"):
			occupant_here["moved"] = false
		if occupant_here["moved"] == false:
			if can_castle_kingside(color):
				if color == Global.Player.WHITE:
					moves.append([7, 6])
				else:
					moves.append([0, 6])
			if can_castle_queenside(color):
				if color == Global.Player.WHITE:
					moves.append([7, 2])
				else:
					moves.append([0, 2])

	return moves

func slide_in_direction(r, c, dr, dc, color) -> Array:
	var moves = []
	var nr = r + dr
	var nc = c + dc
	while nr >= 0 and nr < 8 and nc >= 0 and nc < 8:
		var occupant_spot = board_state[nr][nc]
		if occupant_spot == null:
			moves.append([nr, nc])
		else:
			if occupant_spot["color"] != color:
				moves.append([nr, nc])
			break
		nr += dr
		nc += dc
	return moves

func can_castle_kingside(color) -> bool:
	var rank = 0
	if color == Global.Player.WHITE:
		rank = 7
	else:
		rank = 0

	var king_occ = board_state[rank][4]
	var rook_occ = board_state[rank][7]
	if king_occ == null or rook_occ == null:
		return false
	if king_occ["type"] != "King" or rook_occ["type"] != "Rook":
		return false
	if not king_occ.has("moved"):
		king_occ["moved"] = false
	if not rook_occ.has("moved"):
		rook_occ["moved"] = false
	if king_occ["moved"] or rook_occ["moved"]:
		return false

	if board_state[rank][5] != null: return false
	if board_state[rank][6] != null: return false

	if is_square_attacked(rank, 4, color): return false
	if is_square_attacked(rank, 5, color): return false
	if is_square_attacked(rank, 6, color): return false

	return true

func can_castle_queenside(color) -> bool:
	var rank = 0
	if color == Global.Player.WHITE:
		rank = 7
	else:
		rank = 0

	var king_occ = board_state[rank][4]
	var rook_occ = board_state[rank][0]
	if king_occ == null or rook_occ == null:
		return false
	if king_occ["type"] != "King" or rook_occ["type"] != "Rook":
		return false
	if not king_occ.has("moved"):
		king_occ["moved"] = false
	if not rook_occ.has("moved"):
		rook_occ["moved"] = false
	if king_occ["moved"] or rook_occ["moved"]:
		return false

	for cc in [1, 2, 3]:
		if board_state[rank][cc] != null:
			return false

	if is_square_attacked(rank, 4, color): return false
	if is_square_attacked(rank, 3, color): return false
	if is_square_attacked(rank, 2, color): return false

	return true


# --------------------------------------------------------------
# --- CHECK / CHECKMATE / ATTACK LOGIC --------------------------
func is_king_in_check(color) -> bool:
	var king_row = -1
	var king_col = -1
	for row in range(8):
		for col in range(8):
			var occ = board_state[row][col]
			if occ and occ["type"] == "King" and occ["color"] == color:
				king_row = row
				king_col = col
				break
		if king_row != -1:
			break
	if king_row == -1:
		# no king found => consider "in check" or game over
		return true
	return is_square_attacked(king_row, king_col, color)

func is_square_attacked(row:int, col:int, color) -> bool:
	var opp_color = 0
	if color == Global.Player.WHITE:
		opp_color = Global.Player.BLACK
	else:
		opp_color = Global.Player.WHITE

	for r in range(8):
		for c in range(8):
			var occ = board_state[r][c]
			if occ and occ["color"] == opp_color:
				var piece_moves = get_valid_moves_node_check(r, c, occ)
				for pm in piece_moves:
					if pm[0] == row and pm[1] == col:
						return true
	return false

func get_valid_moves_node_check(r:int, c:int, occupant:Dictionary) -> Array:
	if occupant["type"] == "Pawn":
		return get_pawn_moves_nocheck(r, c, occupant["color"])
	elif occupant["type"] == "Rook":
		return get_rook_moves(r, c, occupant["color"])
	elif occupant["type"] == "Knight":
		return get_knight_moves(r, c, occupant["color"])
	elif occupant["type"] == "Bishop":
		return get_bishop_moves(r, c, occupant["color"])
	elif occupant["type"] == "Queen":
		var rook_moves = get_rook_moves(r, c, occupant["color"])
		var bishop_moves = get_bishop_moves(r, c, occupant["color"])
		return rook_moves + bishop_moves
	elif occupant["type"] == "King":
		return get_king_moves_nocheck(r, c, occupant["color"])
	return []

# Pawn ignoring en passant in "attack check" logic
func get_pawn_moves_nocheck(r: int, c: int, color) -> Array:
	var moves = []

	var direction = 0
	if color == Global.Player.WHITE:
		direction = -1
	else:
		direction = 1

	var start_row = 0
	if color == Global.Player.WHITE:
		start_row = 6
	else:
		start_row = 1

	var fr = r + direction
	if fr >= 0 and fr < 8:
		if board_state[fr][c] == null:
			moves.append([fr, c])
			if r == start_row:
				var fr2 = r + 2 * direction
				if board_state[fr2][c] == null:
					moves.append([fr2, c])
		for dc in [-1, 1]:
			var cc = c + dc
			if cc >= 0 and cc < 8:
				var occupant_capture = board_state[fr][cc]
				if occupant_capture != null and occupant_capture["color"] != color:
					moves.append([fr, cc])

	return moves

func get_king_moves_nocheck(r: int, c: int, color) -> Array:
	var moves = []
	for ro in range(-1, 2):
		for co in range(-1, 2):
			if ro == 0 and co == 0:
				continue
			var nr = r + ro
			var nc = c + co
			if nr >= 0 and nr < 8 and nc >= 0 and nc < 8:
				var occupant_spot = board_state[nr][nc]
				if occupant_spot == null or occupant_spot["color"] != color:
					moves.append([nr, nc])
	return moves

func check_for_checkmate_stalemate(current_player):
	if not is_king_in_check(current_player):
		if not any_legal_move_exists(current_player):
			show_game_end_popup(current_player, true)
	else:
		if not any_legal_move_exists(current_player):
			if(current_player == Global.Player.WHITE):
				show_game_end_popup(current_player, false)
			else:
				show_game_end_popup(current_player, false)
		else:
			print("‼️ Check!")

func any_legal_move_exists(color) -> bool:
	for row in range(8):
		for col in range(8):
			var occ = board_state[row][col]
			if occ and occ["color"] == color:
				var piece_node = occ["node"]
				if piece_node:
					var moves = get_legal_moves(piece_node)
					if moves.size() > 0:
						return true
	return false


# --------------------------------------------------------------
# --- DRAG & DROP EVENTS ---------------------------------------
func _drop_data(position, data):
	if not data is TextureRect:
		return

	var piece = data
	var local_pos = tile_container.to_local(position)
	var target_tile: ColorRect = null

	for tile in tiles:
		var rect = Rect2(tile.position, tile.size)
		if rect.has_point(local_pos):
			target_tile = tile
			break

	var previous_tile = piece.get_meta("occupied_tile")
	if target_tile == null:
		print("❌ Cannot move here!")
		reset_tile_highlights()
		return

	var player = piece.get_meta("player")
	var tile_row = target_tile.get_meta("row")
	var tile_col = target_tile.get_meta("col")

	if game_phase == GamePhase.PLACEMENT:
		if not valid_placement(piece, tile_row, tile_col):
			reset_tile_highlights()
			return
		place_piece(piece, target_tile)
		if player == Global.Player.WHITE:
			white_pieces_placed += 1
			check_white_placement_done()
		else:
			black_pieces_placed += 1
			check_black_placement_done()
	else:
		var current_player = Global.turn
		if player != current_player:
			print("❌ Not your turn!")
			reset_tile_highlights()
			return

		var valid_moves = get_legal_moves(piece)
		var to_coords = [tile_row, tile_col]
		if to_coords not in valid_moves:
			print("❌ Illegal move for this piece!")
			reset_tile_highlights()
			return

		var occupant = get_occupant(tile_row, tile_col)
		if occupant and occupant["color"] != player:
			var enemy_node = occupant["node"]
			if enemy_node:
				enemy_node.queue_free()
			clear_occupant(tile_row, tile_col)

		var piece_type = piece.get_meta("piece_type")
		var old_tile_row = -1
		var old_tile_col = -1
		if previous_tile:
			old_tile_row = previous_tile.get_meta("row")
			old_tile_col = previous_tile.get_meta("col")

		# Castling
		if piece_type == "King":
			if old_tile_col == 4 and tile_col == 6:
				# kingside
				var rook_occ = get_occupant(tile_row, 7)
				if rook_occ:
					clear_occupant(tile_row, 7)
					set_occupant(tile_row, 5, rook_occ)
					var rook_node = rook_occ["node"]
					if rook_node:
						var tile_center = tile_container.position
						tile_center += Vector2(5 * (tile_size.x + tile_spacing.x), tile_row * (tile_size.y + tile_spacing.y))
						tile_center += tile_size / 2
						rook_node.position = tile_center - rook_node.pivot_offset
					rook_occ["moved"] = true
			if old_tile_col == 4 and tile_col == 2:
				# queenside
				var rook_occ2 = get_occupant(tile_row, 0)
				if rook_occ2:
					clear_occupant(tile_row, 0)
					set_occupant(tile_row, 3, rook_occ2)
					var rook_node2 = rook_occ2["node"]
					if rook_node2:
						var t_center = tile_container.position
						t_center += Vector2(3 * (tile_size.x + tile_spacing.x), tile_row * (tile_size.y + tile_spacing.y))
						t_center += tile_size / 2
						rook_node2.position = t_center - rook_node2.pivot_offset
					rook_occ2["moved"] = true

		# En passant
		if piece_type == "Pawn":
			if occupant == null and old_tile_col != tile_col:
				var en_passant_r = 0
				if player == Global.Player.WHITE:
					en_passant_r = tile_row + 1
				else:
					en_passant_r = tile_row - 1
				clear_occupant(en_passant_r, tile_col)

			# Promotion
			if (player == Global.Player.WHITE and tile_row == 0) or (player == Global.Player.BLACK and tile_row == 7):
				piece.set_meta("piece_type", "Queen")

		move_piece_on_board(piece, target_tile)

		var occupant_dict = get_occupant(tile_row, tile_col)
		if occupant_dict and occupant_dict.has("moved") == false:
			occupant_dict["moved"] = false
		if occupant_dict:
			occupant_dict["moved"] = true

		last_move["from"] = [old_tile_row, old_tile_col]
		last_move["to"] = [tile_row, tile_col]
		last_move["piece"] = occupant_dict
		last_move["two_step"] = false
		if piece_type == "Pawn":
			if abs(tile_row - old_tile_row) == 2:
				last_move["two_step"] = true

		switch_turn()

	reset_tile_highlights()

func _can_drop_data(_position, data):
	return data is TextureRect

func valid_placement(piece, row, col) -> bool:
	var color = piece.get_meta("player")
	if color == Global.Player.WHITE:
		if row < 8 - Global.playable_lines:
			print("❌ White must place in last rows!")
			return false
	else:
		if row > Global.playable_lines - 1:
			print("❌ Black must place in first rows!")
			return false
	if board_state[row][col] != null:
		print("❌ Tile occupied!")
		return false
	return true

func place_piece(piece: TextureRect, tile: ColorRect):
	var row = tile.get_meta("row")
	var col = tile.get_meta("col")

	set_occupant(row, col, {
		"node": piece,
		"type": piece.get_meta("piece_type"),
		"color": piece.get_meta("player"),
		"moved": false
	})

	piece.set_meta("occupied_tile", tile)
	tile.set_meta("occupied", true)

	var tile_center = tile_container.position + tile.position + tile_size / 2
	piece.get_parent().remove_child(piece)
	board.add_child(piece)
	piece.position = tile_center - piece.pivot_offset

func move_piece_on_board(piece: TextureRect, tile: ColorRect):
	var old_tile = piece.get_meta("occupied_tile")
	if old_tile:
		var old_r = old_tile.get_meta("row")
		var old_c = old_tile.get_meta("col")
		clear_occupant(old_r, old_c)
		old_tile.set_meta("occupied", false)

	var r = tile.get_meta("row")
	var c = tile.get_meta("col")

	var occupant_dict = {
		"node": piece,
		"type": piece.get_meta("piece_type"),
		"color": piece.get_meta("player"),
		"moved": false,
	}
	set_occupant(r, c, occupant_dict)

	tile.set_meta("occupied", true)
	piece.set_meta("occupied_tile", tile)

	var tile_center = tile_container.position + tile.position + tile_size / 2
	piece.position = tile_center - piece.pivot_offset


# ---------------------------------------------------------
# --- PHASE LOGIC, TURNS, ETC. ----------------------------
func check_white_placement_done():
	if white_pieces_placed >= total_white_pieces:
		print("✅ All white pieces placed! Black can now place pieces.")
		black_piece_container.visible = true
		switch_turn()
		hide_white_pieces()

func check_black_placement_done():
	if black_pieces_placed >= total_black_pieces:
		print("✅ All pieces placed. Starting play phase.")
		game_phase = GamePhase.PLAY
		show_all_pieces()
		switch_turn()
		update_turn_label()

func switch_turn():
	if game_phase == GamePhase.PLACEMENT:
		Global.switch_turn()
		hide_white_pieces()
	else:
		# 1) Switch turn
		Global.switch_turn()
		# 2) Now check the NEW current player
		check_for_checkmate_stalemate(Global.turn)

	update_turn_label()

func update_turn_label():
	if game_phase == GamePhase.PLACEMENT:
		if Global.turn == Global.Player.BLACK:
			turn_label.text = "BLACK'S TURN (Placement)"
		else:
			turn_label.text = "WHITE'S TURN (Placement)"
	else:
		if Global.turn == Global.Player.BLACK:
			turn_label.text = "BLACK'S TURN (Play Phase)"
		else:
			turn_label.text = "WHITE'S TURN (Play Phase)"

	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func show_all_pieces():
	for piece in board.get_children():
		piece.visible = true

func show_game_end_popup(loser, isdraw: bool):
	ending_popup_instance.show_popup(loser, isdraw)  # Call function from EndingPopup
