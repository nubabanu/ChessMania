extends Control

@onready var message_label = $Panel/VBoxContainer/Label
@onready var back_button = $Panel/VBoxContainer/BackButton

func _ready():
	visible = false  # Hide the pop-up by default
	back_button.pressed.connect(Global.on_back_pressed)

func show_popup(loser, isDraw: bool):
	if isDraw:
		message_label.text = "Stalemate! It's a draw."
	elif loser == Global.Player.WHITE:
		message_label.text = "Checkmate! Player BLACK wins!"
	else:
		message_label.text = "Checkmate! Player WHITE wins!"
	
	visible = true  # Make sure it's visible before adjusting position
	center_popup()  # Ensure it's centered relative to the camera

func center_popup():
	var camera = get_viewport().get_camera_2d()

	if camera:
		# Get the camera's screen center position
		var screen_center = camera.get_screen_center_position()
		# Adjust position so the pop-up is centered correctly
		position = screen_center - (size / 2)
	else:
		# Default positioning if no camera exists
		var screen_size = get_viewport_rect().size
		position = (screen_size - size) / 2  # Center in viewport
