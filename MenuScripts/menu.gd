extends Control


func _on_standard_pressed() -> void:
	GameSettings.PlayRegularGame = true
	GameSettings.PlayFischerRandomGame = false
	get_tree().change_scene_to_file("res://Standard/Standard_Scenes/standard_main.tscn")

func _on_tamerlane_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func _on_total_war_pressed() -> void:
	pass # Replace with function body.


func _on_fisher_pressed() -> void:
	GameSettings.PlayFischerRandomGame = true
	GameSettings.PlayRegularGame = false
	get_tree().change_scene_to_file("res://board.tscn")
