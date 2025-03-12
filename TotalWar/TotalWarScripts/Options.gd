extends Node

@onready var confirm_button = $ButtonsContainer/ConfirmButton
@onready var back_button = $ButtonsContainer/BackButton
@onready var line_option = $OptionButtons/LineOption
@onready var balance_option = $OptionButtons/BalanceOption

func _ready():
	# Connect buttons
	confirm_button.pressed.connect(on_confirm_pressed)
	back_button.pressed.connect(on_back_pressed)

# Handles Confirm button press
func on_confirm_pressed():
	# Convert entered balance to an integer safely
	var entered_balance = int(balance_option.text.strip_edges())
	if(entered_balance is int and entered_balance > 0):
		Global.TOTAL_BALANCE = entered_balance
	else:
		print("Invalid balance input! Keeping default:", Global.TOTAL_BALANCE)

	# Get selected option for playable lines
	if(line_option.get_selected_id() != -1):
		Global.playable_lines = line_option.get_selected_id() + 1  # Ensures it matches the chosen option

	print("Selected Lines:", Global.playable_lines)
	print("Total Balance:", Global.TOTAL_BALANCE)

	get_tree().change_scene_to_file(Global.SHOP)

# Handles Back button press
func on_back_pressed():
	get_tree().change_scene_to_file(Global.MAIN_MENU)  # Switch scene
