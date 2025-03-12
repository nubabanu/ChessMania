extends TextureRect

var is_dragging = false
var total_war  # Reference to TotalWar.gd

func _ready():
	# Locate the TotalWar node in the scene (adjust name if necessary).
	total_war = get_tree().get_root().find_child("Control", true, false)

func _get_drag_data(_position):
	# Prevent dragging if it's not this player's turn
	if total_war and self.get_meta("player") != Global.turn:
		print("❌ Not your turn!")
		return null  # Cancel dragging

	is_dragging = true
	print("Dragging piece:", self.name)

	# Free the currently occupied tile, but store a reference
	var cur_tile = self.get_meta("occupied_tile")
	
	# Pass 'self' to exclude its current tile from highlights
	if total_war:
		total_war.highlight_tiles(self)
	
	if cur_tile:
		cur_tile.set_meta("occupied", false)  # Mark as unoccupied
		self.set_meta("occupied_tile", null)  # Clear reference
		print("Unoccupied tile:", cur_tile)

	# Create a semi-transparent drag preview
	var drag_texture = TextureRect.new()
	drag_texture.texture = texture
	drag_texture.custom_minimum_size = Vector2(60, 60)
	drag_texture.modulate = Color(1, 1, 1, 0.5)
	drag_texture.z_index = 5
	set_drag_preview(drag_texture)

	return self
