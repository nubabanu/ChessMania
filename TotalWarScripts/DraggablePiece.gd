extends TextureRect

var is_dragging = false
var total_war  # Reference to TotalWar.gd

func _ready():
	# Locate the TotalWar node in the scene (adjust name if necessary).
	total_war = get_tree().get_root().find_child("Control", true, false)

func _get_drag_data(_position):
	is_dragging = true
	print("Dragging piece:", self.name)
	# Free the currently occupied tile, if any.
	var cur_tile = self.get_meta("occupied_tile")
	if cur_tile:
		cur_tile.set_meta("occupied", false)
		self.set_meta("occupied_tile", null)
	# Pass 'self' as the piece to exclude so that the tile under it is not highlighted.
	if total_war:
		total_war.highlight_tiles(self)
	# Create a semi-transparent drag preview.
	var drag_texture = TextureRect.new()
	drag_texture.texture = texture
	drag_texture.custom_minimum_size = Vector2(60, 60)
	drag_texture.modulate = Color(1, 1, 1, 0.5)
	drag_texture.z_index = 5
	set_drag_preview(drag_texture)
	return self

func _can_drop_data(_position, data):
	return data is TextureRect
