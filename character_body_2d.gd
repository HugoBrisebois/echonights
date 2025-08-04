extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -400.0
@export var acceleration = 1500.0
@export var friction = 1200.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Cache enemy detection area
@onready var enemy_detector = $EnemyDetector

func _physics_process(delta):
	handle_gravity(delta)
	handle_input(delta)
	handle_movement()
	check_enemy_collisions()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_input(delta):
	# Jump
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = jump_velocity

	# Movement
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_movement():
	move_and_slide()

func check_enemy_collisions():
	# Use Area2D for more efficient enemy detection
	var enemies_in_range = enemy_detector.get_overlapping_bodies()
	
	for enemy in enemies_in_range:
		if enemy.is_in_group("enemies") and enemy.is_alive:
			# Check if player is above enemy (stomping)
			if velocity.y > 0 and global_position.y < enemy.global_position.y - 10:
				# Stomp enemy
				enemy.die()
				velocity.y = jump_velocity * 0.6  # Bounce
			else:
				# Player dies or takes damage
				print("Player hit enemy!")
				global_position = Vector2(100, 100)
				velocity = Vector2.ZERO
