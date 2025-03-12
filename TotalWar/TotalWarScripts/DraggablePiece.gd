extends TextureRect

var dragging = false
var drag_offset = Vector2.ZERO
var total_war

func _ready():
	# Locate your TotalWar or Board node – adapt the find call as needed.
	# If your board node is named something else or in a different place,
	# adjust accordingly.
	total_war = get_tree().get_root().find_child("Control", true, false)

func _gui_input(event):
	if event is InputEventMouseButton:
		# Left mouse button
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 1) On mouse press: start dragging if it's our turn
				if total_war and self.get_meta("player") != Global.turn:
					print("❌ Not your turn!")
					return

				dragging = true
				drag_offset = event.position

				# Highlight possible tiles right when we begin dragging
				if total_war:
					total_war.highlight_tiles(self)

				accept_event()  # Stop event from propagating
			else:
				# 2) On mouse release: "drop" on the board
				if dragging:
					dragging = false

					# Clear highlights, and call board._drop_data for final placement
					if total_war:
						total_war.reset_tile_highlights()
						# Pass global mouse position to the board
						total_war._drop_data(get_global_mouse_position(), self)

					accept_event()

	elif event is InputEventMouseMotion and dragging:
		# 3) While dragging, update the piece's position to follow the mouse
		var new_global_pos = event.global_position - drag_offset
		global_position = new_global_pos
		accept_event()
