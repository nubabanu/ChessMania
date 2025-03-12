extends Control

@onready var board = $ChessBoard                       # Chessboard node (target for reparenting pieces)
@onready var piece_container = $PieceContainer           # Container for pieces (shop area)
@onready var tile_container = $ChessBoard/TileContainer    # Container holding the grid tiles
@onready var chessboard_texture = $ChessBoard/Background  # Chessboard background
@onready var black_piece_container = $BlackPieceContainer
@onready var turn_label = $TurnLabel

var white_available_pieces = {}
var black_available_pieces = {}
var tiles = []                     # Array of tile nodes
var tile_size = Vector2(60, 60)    # Each tile is 60x60 pixels
var tile_spacing = Vector2(5, 5)   # Gap between tiles (adjust as needed)
var board_offset = Vector2()       # Computed offset to center the grid

var white_pieces_placed = 0
var black_pieces_placed = 0
var total_white_pieces = 1     # King
var total_black_pieces = 1     # King

enum GamePhase { PLACEMENT, PLAY }
var game_phase = GamePhase.PLACEMENT  # Start in the placement phase

# Mapping of piece names to texture file paths.
var piece_textures = {
	"WPawn": "res://TotalWar/Assets/ChessTextures/WPawn.svg",
	"WBishop": "res://TotalWar/Assets/ChessTextures/WBishop.svg",
	"WKnight": "res://TotalWar/Assets/ChessTextures/WKnight.svg",
	"WRook": "res://TotalWar/Assets/ChessTextures/WRook.svg",
	"WQueen": "res://TotalWar/Assets/ChessTextures/WQueen.svg",
	"WKing": "res://TotalWar/Assets/ChessTextures/WKing.svg",
	"BPawn": "res://TotalWar/Assets/ChessTextures/BPawn.svg",
	"BBishop": "res://TotalWar/Assets/ChessTextures/BBishop.svg",
	"BKnight": "res://TotalWar/Assets/ChessTextures/BKnight.svg",
	"BRook": "res://TotalWar/Assets/ChessTextures/BRook.svg",
	"BQueen": "res://TotalWar/Assets/ChessTextures/BQueen.svg",
	"BKing": "res://TotalWar/Assets/ChessTextures/BKing.svg",
}

func _ready():
	align_chessboard_background()   # Center the chessboard and grid.
	generate_tiles()                # Create the 8x8 grid with spacing.
	create_piece("WKing", Global.Player.WHITE)
	create_piece("BKing", Global.Player.BLACK)
	load_purchased_pieces()         # Spawn pieces from the shop.
	update_turn_label()
	
	# Hide the black piece container initially
	black_piece_container.visible = false

func hide_white_pieces():
	if Global.turn == Global.Player.BLACK:
		for piece in board.get_children():
			if(piece.get_meta("player") == Global.Player.WHITE):
				piece.visible = false

# Centers the chessboard and calculates the board_offset to center the tile grid.
func align_chessboard_background():
	var window_size = get_viewport_rect().size
	var board_size = Vector2(648, 648)  # Chessboard texture size; adjust if necessary.
	var centered_position = (window_size - board_size) / 2
	chessboard_texture.position = centered_position
	
	# Calculate grid size: there are 8 tiles and 7 gaps between them.
	var grid_size = tile_size * 8 + tile_spacing * (8 - 1)
	board_offset = (board_size - grid_size) / 2
	
	# Position tile_container at the same place as the chessboard.
	tile_container.position = chessboard_texture.position

# Creates the 8x8 grid of tiles using the defined tile_size and tile_spacing.
func generate_tiles():
	# Clear any existing children.
	for child in tile_container.get_children():
		tile_container.remove_child(child)
	tiles.clear()
	
	for row in range(8):
		for col in range(8):
			var tile = ColorRect.new()
			tile.z_index = 1
			tile.size = tile_size
			# Use a transparent base color.
			tile.color = Color(0.8, 0.8, 0.8, 0.0)
			
			# Create a border using StyleBoxFlat.
			var tile_style = StyleBoxFlat.new()
			tile_style.bg_color = tile.color
			tile_style.border_color = Color(0, 0, 0, 1)
			tile_style.border_width_top = 2
			tile_style.border_width_bottom = 2
			tile_style.border_width_left = 2
			tile_style.border_width_right = 2
			tile.add_theme_stylebox_override("panel", tile_style)
			
			# Add a highlight overlay.
			var highlight = ColorRect.new()
			highlight.name = "HighlightOverlay"
			highlight.size = tile_size - Vector2(4, 4)
			highlight.position = Vector2(2, 2)
			highlight.color = Color(0, 1, 0, 0.5)
			highlight.visible = false
			tile.add_child(highlight)
			
			# Initialize tile occupancy.
			tile.set_meta("occupied", false)
			
			# Position the tile using spacing; board_offset centers the grid.
			tile.position = Vector2(col * (tile_size.x + tile_spacing.x), row * (tile_size.y + tile_spacing.y)) + board_offset
			tile_container.add_child(tile)
			tiles.append(tile)

# Highlights all unoccupied tiles.
func highlight_tiles(exclude_piece = null):
	reset_tile_highlights()  # Clear previous highlights
	
	if not exclude_piece:
		return

	var occupied_tile = exclude_piece.get_meta("occupied_tile")  # Tile currently occupied by the dragged piece
	var player = exclude_piece.get_meta("player")

	for tile in tiles:
		# Skip highlighting the tile where the dragged piece is currently placed
		if tile == occupied_tile:
			continue

		# Placement Phase: Only highlight allowed placement areas
		var tile_index = tiles.find(tile)
		var tile_row = tile_index / 8

		if game_phase == GamePhase.PLACEMENT:
			if player == Global.Player.WHITE and tile_row >= 8 - Global.playable_lines:
				if not tile.get_meta("occupied"):  # Avoid highlighting occupied tiles
					tile.get_node("HighlightOverlay").visible = true
			elif player == Global.Player.BLACK and tile_row < Global.playable_lines:
				if not tile.get_meta("occupied"):
					tile.get_node("HighlightOverlay").visible = true

		# Play Phase: Highlight all available movement tiles, excluding occupied ones
		elif game_phase == GamePhase.PLAY and not tile.get_meta("occupied"):
			tile.get_node("HighlightOverlay").visible = true

func reset_tile_highlights():
	for tile in tiles:
		var hl = tile.get_node("HighlightOverlay")
		if hl:
			hl.visible = false

func load_purchased_pieces():
	white_available_pieces = Global.white_purchased_pieces  # Retrieve saved pieces.
	black_available_pieces = Global.black_purchased_pieces
	
	if white_available_pieces.is_empty():
		print("No purchased white pieces found!")
		return
	if black_available_pieces.is_empty():
		print("No purchased black pieces found!")
		return
		
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

func create_piece(piece_name, player_color):
	var piece = TextureRect.new()
	var texture_path = piece_textures.get(piece_name, null)
	if texture_path and FileAccess.file_exists(texture_path):
		piece.texture = load(texture_path)
	else:
		print("Warning: Texture not found for", piece_name, "Expected:", texture_path)
		return
	piece.mouse_filter = Control.MOUSE_FILTER_STOP
	# Spawn pieces at a designated shop position.
	piece.position = Vector2(50, 850)
	piece.z_index = 2
	# Set piece size to 60x60.
	piece.custom_minimum_size = Vector2(60, 60)
	piece.pivot_offset = piece.custom_minimum_size / 2
	# Initialize occupied_tile meta.
	piece.set_meta("occupied_tile", null)
	piece.set_script(load("res://TotalWar/TotalWarScripts/DraggablePiece.gd"))
	if(player_color == Global.Player.WHITE):
		piece_container.add_child(piece)
		piece.set_meta("player", player_color)  # Store which player owns it
	else:
		black_piece_container.add_child(piece)
		piece.set_meta("player", player_color)  # Store which player owns it
	print("Created piece:", piece_name, "at", piece.position)

# Returns the tile node at a given global position.
func get_tile_at_position(world_pos: Vector2) -> ColorRect:
	for tile in tiles:
		if tile.get_global_rect().has_point(world_pos):
			return tile
	return null

# Drop event handling (when a piece is dropped onto this control).
# Drop event handling (when a piece is dropped onto this control).
func _drop_data(position, data):
	if not data is TextureRect:
		return

	var piece = data
	var local_pos = tile_container.to_local(position)
	var target_tile = null

	for tile in tiles:
		var rect = Rect2(tile.position, tile.size)
		if rect.has_point(local_pos):
			target_tile = tile
			break

	# Prevent dropping on occupied tiles except for the original one
	var previous_tile = piece.get_meta("occupied_tile")
	if target_tile == null or (target_tile.get_meta("occupied") and target_tile != previous_tile):
		print("❌ Cannot move here!")
		reset_tile_highlights()
		return

	var player = piece.get_meta("player")
	var tile_index = tiles.find(target_tile)
	var tile_row = tile_index / 8

	if game_phase == GamePhase.PLACEMENT:
		# Restrict placement based on player side
		if player == Global.Player.WHITE and tile_row < 8 - Global.playable_lines:
			print("❌ White pieces must be placed in rows 5, 6, or 7!")
			reset_tile_highlights()
			return
		elif player == Global.Player.BLACK and tile_row > Global.playable_lines - 1:
			print("❌ Black pieces must be placed in rows 0, 1, or 2!")
			reset_tile_highlights()
			return

		# Mark the tile as occupied and place the piece
		target_tile.set_meta("occupied", true)
		piece.set_meta("occupied_tile", target_tile)

		# Compute the center of the tile
		var tile_center = tile_container.position + target_tile.position + tile_size / 2

		# Reparent the piece to the board for proper positioning
		piece.get_parent().remove_child(piece)
		board.add_child(piece)
		piece.position = tile_center - piece.pivot_offset

		# Reset highlights
		reset_tile_highlights()

		# Update piece placement tracking
		if player == Global.Player.WHITE:
			white_pieces_placed += 1
			check_white_placement_done()
		elif player == Global.Player.BLACK:
			black_pieces_placed += 1
			check_black_placement_done()

	elif game_phase == GamePhase.PLAY:
		# Allow moving pieces only in play phase
		var current_player = Global.turn
		var piece_owner = piece.get_meta("player")

		# Only allow the current player to move their pieces
		if piece_owner != current_player:
			print("❌ Not your turn!")
			return

		if target_tile == null or target_tile.get_meta("occupied"):
			print("❌ Cannot move here!")
			reset_tile_highlights()
			return

		# Move the piece
		if previous_tile and previous_tile != target_tile:
			previous_tile.set_meta("occupied", false)  # Free up the old tile

		target_tile.set_meta("occupied", true)
		piece.set_meta("occupied_tile", target_tile)

		# Compute the center of the tile
		var tile_center = tile_container.position + target_tile.position + tile_size / 2
		piece.position = tile_center - piece.pivot_offset

		# Reset highlights
		reset_tile_highlights()

		# Switch turn after a move
		switch_turn()

func _can_drop_data(_position, data):
	return data is TextureRect

func check_white_placement_done():
	if white_pieces_placed >= total_white_pieces:
		print("✅ All white pieces placed! Black can now place pieces.")
		black_piece_container.visible = true
		switch_turn()
		hide_white_pieces()
		
func check_black_placement_done():
	if black_pieces_placed >= total_black_pieces:
		print("✅ All pieces placed. Starting play phase.")
		game_phase = GamePhase.PLAY  # 🔥 Start play phase
		show_all_pieces()
		switch_turn()
		update_turn_label()

func switch_turn():
	if game_phase == GamePhase.PLACEMENT:
		Global.switch_turn()
		hide_white_pieces()
	else:
		# Normal turn switching in play mode
		Global.switch_turn()

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
