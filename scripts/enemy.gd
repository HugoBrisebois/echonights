# Enemy.gd - 2D Platformer Version
extends CharacterBody2D

@export var max_health = 100
@export var speed = 100.0
@export var patrol_distance = 200.0

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

var current_health
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var start_position
var facing_direction = 1
var knockback_velocity = Vector2.ZERO

func _ready():
	current_health = max_health
	start_position = global_position
	update_health_bar()

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Apply knockback
	if knockback_velocity != Vector2.ZERO:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
	else:
		# Simple patrol AI
		patrol_movement()
	
	move_and_slide()

func patrol_movement():
	# Simple back and forth patrol
	var distance_from_start = global_position.x - start_position.x
	
	# Change direction if too far from start or hit a wall
	if abs(distance_from_start) > patrol_distance or is_on_wall():
		facing_direction *= -1
		sprite.scale.x = abs(sprite.scale.x) * facing_direction
	
	# Move in facing direction
	velocity.x = facing_direction * speed

func apply_knockback(direction: Vector2, force: float):
	knockback_velocity = direction * force

func take_damage(amount):
	current_health -= amount
	
	# Visual feedback
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	update_health_bar()
	
	if current_health <= 0:
		die()

func update_health_bar():
	if health_bar:
		health_bar.value = (float(current_health) / float(max_health)) * 100

func die():
	print("Enemy died!")
	queue_free()
