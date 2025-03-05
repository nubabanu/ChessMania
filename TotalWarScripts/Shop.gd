extends Control

@onready var money_label: Label = $MoneyLabel
@onready var shop_panel: Panel = $MarginContainer/Panel

const ITEM_PRICES = {
	"Pawn": 10,
	"Bishop": 20,
	"Knight": 30,
	"Rook": 40,
	"Queen": 50
}

func _ready():
	update_money_display()
	ShopManager.money_changed.connect(update_money_display)

	for button in get_tree().get_nodes_in_group("shop_buttons"):
		if button.name in ITEM_PRICES:
			button.tooltip_text = "Buy %s - %d Gold" % [button.name, ITEM_PRICES[button.name]]
			button.pressed.connect(func(): spend_money(ITEM_PRICES[button.name]))

	shop_panel.modulate = Color(1, 1, 1, 0)
	shop_panel.visible = false

func update_money_display():
	money_label.text = "Money: " + str(ShopManager.money)

func spend_money(amount: int):
	if ShopManager.spend_money(amount):
		print("✅ Purchase successful! Spent:", amount)
	else:
		print("❌ Not enough money!")

func show_shop():
	shop_panel.visible = true
	var tween = create_tween()
	shop_panel.modulate.a = 0  # Start fully transparent
	tween.tween_property(shop_panel, "modulate:a", 1, 0.3)  # Fade in over 0.3 sec

func hide_shop():
	var tween = create_tween()
	tween.tween_property(shop_panel, "modulate:a", 0, 0.3)  # Fade out
	await tween.finished
	shop_panel.visible = false
