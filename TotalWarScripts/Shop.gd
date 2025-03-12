extends Control

@onready var pieces_container = $PiecesContainer
@onready var money_label = $MoneyContainer/MoneyAmount
@onready var confirm_button = $ButtonsContainer/ConfirmButton
@onready var reset_button = $ButtonsContainer/ResetButton

var total_money = 50  # Starting money
var selected_pieces = {}  # Dictionary to track selected pieces
const NEXT_SCENE_PATH = "res://TotalWarScenes/TotalWar.tscn"

func _ready():
	# Connect buttons
	confirm_button.pressed.connect(on_confirm_pressed)
	reset_button.pressed.connect(on_reset_pressed)

	# Initialize each PieceShopItem inside PiecesContainer
	for piece_item in pieces_container.get_children():
		var vbox = piece_item.get_node("VBoxContainer")  # Get VBox inside PieceShopItem

		var plus_button = vbox.get_node("QuantityContainer/PlusButton")
		var minus_button = vbox.get_node("QuantityContainer/MinusButton")
		var quantity_label = vbox.get_node("QuantityContainer/QuantityLabel")
		var price_label = vbox.get_node("Price")

		# Convert price from label text to integer
		var price = int(price_label.text)

		# Store piece information
		selected_pieces[piece_item] = {"count": 0, "price": price, "quantity_label": quantity_label}

		# Connect buttons dynamically
		plus_button.pressed.connect(func(): on_plus_pressed(piece_item))
		minus_button.pressed.connect(func(): on_minus_pressed(piece_item))

	update_money_display()

# Handles + button press
func on_plus_pressed(piece_item):
	var piece_data = selected_pieces[piece_item]
	var piece_price = piece_data["price"]

	if total_money >= piece_price:
		piece_data["count"] += 1
		total_money -= piece_price
		piece_data["quantity_label"].text = str(piece_data["count"])
		update_money_display()

# Handles - button press
func on_minus_pressed(piece_item):
	var piece_data = selected_pieces[piece_item]
	var piece_price = piece_data["price"]

	if piece_data["count"] > 0:
		piece_data["count"] -= 1
		total_money += piece_price
		piece_data["quantity_label"].text = str(piece_data["count"])
		update_money_display()

# Handles Reset button press
func on_reset_pressed():
	total_money = 50  # Reset money
	for piece_item in selected_pieces.keys():
		selected_pieces[piece_item]["count"] = 0
		selected_pieces[piece_item]["quantity_label"].text = "0"
	update_money_display()

# Handles Confirm button press
func on_confirm_pressed():
	# Store selected pieces in a dictionary
	for piece_item in selected_pieces.keys():
		var count = selected_pieces[piece_item]["count"]
		if count > 0:
			selected_pieces[piece_item.name] = count
			
	# Save selection to Global script
	Global.purchased_pieces = selected_pieces
	print("Selection Confirmed:", selected_pieces)
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)  # Switch scene

# Updates the money UI
func update_money_display():
	money_label.text = str(total_money)
