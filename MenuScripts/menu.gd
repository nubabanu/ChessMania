extends Control

const StandardBoard = preload("res://Standard/Standard_Scenes/standard_board.tscn")
const TamerlaneBoard = preload("res://Tamerlane/Scenes/tamerlane_board.tscn")

var board

func _on_standard_pressed() -> void:
	GameSettings.PlayRegularGame = true
	board = StandardBoard.instantiate()
	add_child(board)
	get_tree().change_scene_to_file("res://Standard/Standard_Scenes/standard_main.tscn")

func _on_tamerlane_pressed() -> void:
	GameSettings.PlayTamerlaneGame = true
	board = TamerlaneBoard.instantiate()
	add_child(board)
	get_tree().change_scene_to_file("res://Tamerlane/Scenes/tamerlane_main.tscn")


func _on_total_war_pressed() -> void:
	get_tree().change_scene_to_file("res://TotalWar/Scenes/Options.tscn")


func _on_fisher_pressed() -> void:
	GameSettings.PlayFischerRandomGame = true
	get_tree().change_scene_to_file("res://Standard/Standard_Scenes/standard_main.tscn")



func _on_toggled(toggled_on: bool) -> void:
	GameSettings.is_single_player = not GameSettings.is_single_player


func _on_back_button_pressed() -> void:
	GameSettings.PlayFischerRandomGame = false
	GameSettings.PlayRegularGame = false
	GameSettings.PlayTamerlaneGame = false
	get_tree().change_scene_to_file("res://scenesMenu/menu.tscn")

func _on_pressed() -> void:
	GameSettings.PlayFischerRandomGame = false
	GameSettings.PlayRegularGame = false
	GameSettings.PlayTamerlaneGame = false
	get_tree().change_scene_to_file("res://scenesMenu/menu.tscn")
