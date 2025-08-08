extends Node



func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")
	

func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_2.tscn")

func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_3.tscn")




func _on_button_4_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_4.tscn")


func _on_button_5_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_5.tscn")


func _on_button_6_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_6.tscn")


func _on_level_7_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_7.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
