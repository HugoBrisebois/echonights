extends Control

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://level_1.tscn")




func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://tutorial.tscn")



func _on_options_pressed() -> void:
	print("OPTIONS PRESS")


func _on_quit_pressed() -> void:
	get_tree().quit()
