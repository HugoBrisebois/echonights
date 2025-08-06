extends Control

func resume():
	get_tree().paused = false
	
func pause():
	get_tree().paused = true
	
func testpause():
	if Input.is_action_just_pressed("accessmenu") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("accessmenu") and get_tree().paused == true:
		resume()

func _on_resume_pressed() -> void:
	resume()


func _on_quit_pressed() -> void:
	get_tree().quit()
