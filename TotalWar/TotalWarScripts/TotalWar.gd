extends Control

@onready var board = $ChessBoard                       # Chessboard node (target for reparenting pieces)
@onready var piece_container = $PieceContainer           # Container for pieces (shop area)
@onready var tile_container = $ChessBoard/TileContainer    # Container holding the grid tiles
@onready var chessboard_texture = $ChessBoard/Background  # Chessboard background

var available_pieces = {}
var tiles = []                     # Array of tile nodes
var tile_size = Vector2(60, 60)    # Each tile is 60x60 pixels
var tile_spacing = Vector2(5, 5)   # Gap between tiles (adjust as needed)
var board_offset = Vector2()       # Computed offset to center the grid

# Mapping of piece names to texture file paths.
var piece_textures = {
	"pieceshopitem": "res://TotalWar/Assets/ChessTextures/WPawn.svg",
	"pieceshopitem2": "res://TotalWar/Assets/ChessTextures/WBishop.svg",
	"pieceshopitem3": "res://TotalWar/Assets/ChessTextures/WKnight.svg",
	"pieceshopitem4": "res://TotalWar/Assets/ChessTextures/WRook.svg",
	"pieceshopitem5": "res://TotalWar/Assets/ChessTextures/WQueen.svg"
	#"pieceshopitem6": "res://ChessTextures/WKing.svg"
}

func _ready():
	align_chessboard_background()   # Center the chessboard and grid.
	generate_tiles()                # Create the 8x8 grid with spacing.
	load_purchased_pieces()         # Spawn pieces from the shop.

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
# If a dragged piece is provided, skip highlighting the tile under that piece.
func highlight_tiles(exclude_piece = null):
	for tile in tiles:
		if not tile.get_meta("occupied"):
			# If an exclude_piece is provided, do not highlight the tile that contains its center.
			if exclude_piece:
				var piece_center = exclude_piece.get_global_position() + exclude_piece.pivot_offset
				if tile.get_global_rect().has_point(piece_center):
					continue
			var hl = tile.get_node("HighlightOverlay")
			if hl:
				hl.visible = true

func reset_tile_highlights():
	for tile in tiles:
		var hl = tile.get_node("HighlightOverlay")
		if hl:
			hl.visible = false

func load_purchased_pieces():
	available_pieces = Global.purchased_pieces  # Retrieve saved pieces.
	if available_pieces.is_empty():
		print("No purchased pieces found!")
		return
	for piece_name in available_pieces.keys():
		var count = available_pieces[piece_name]
		if typeof(count) != TYPE_INT:
			print("Warning: Piece count for", piece_name, "is not an integer:", count)
			continue
		for i in range(count):
			create_piece(piece_name)

func create_piece(piece_name):
	var piece = TextureRect.new()
	var texture_path = piece_textures.get(piece_name.to_lower(), null)
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
	piece_container.add_child(piece)
	print("Created piece:", piece_name, "at", piece.position)

# Returns the tile node at a given global position.
func get_tile_at_position(world_pos: Vector2) -> ColorRect:
	for tile in tiles:
		if tile.get_global_rect().has_point(world_pos):
			return tile
	return null

# Drop event handling (when a piece is dropped onto this control).
func _drop_data(position, data):
	# 'position' is in TotalWar.gd's coordinate space.
	if data is TextureRect:
		# Convert drop position to tile_container's local coordinates.
		var local_pos = tile_container.to_local(position)
		# Find the tile whose rectangle contains local_pos.
		var target_tile = null
		for tile in tiles:
			var rect = Rect2(tile.position, tile.size)
			if rect.has_point(local_pos):
				target_tile = tile
				break
		if target_tile == null:
			reset_tile_highlights()
			return
		if target_tile.get_meta("occupied"):
			print("Tile is already occupied!")
			reset_tile_highlights()
			return

		# Mark the target tile as occupied.
		target_tile.set_meta("occupied", true)
		data.set_meta("occupied_tile", target_tile)
		# Compute the center of the tile.
		var tile_center = tile_container.position + target_tile.position + tile_size / 2
		# Reparent the piece to the board for proper positioning.
		data.get_parent().remove_child(data)
		board.add_child(data)
		# Set the piece's position so its center aligns with the tile center.
		data.position = tile_center - data.pivot_offset
		reset_tile_highlights()

func _can_drop_data(_position, data):
	return data is TextureRect
