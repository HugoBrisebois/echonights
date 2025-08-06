extends Area2D

@onready var gamemanager: Node = %gamemanager


func _on_body_entered(body):
	if (body.name == "player"):
		queue_free()
		gamemanager.add_points()
