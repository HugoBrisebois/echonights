# Player.gd - 2D Platformer Version
extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -400.0
@export var attack_damage = 25
@export var attack_range = 60.0
@export var attack_cooldown = 0.5

@onready var attack_area = $Attack
@onready var attack_collision = $Area2D/attackarea
@onready var attack_timer = $attacktimer
@onready var sprite = $Sprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_attack = true
var is_attacking = false
var facing_direction = 1  # 1 for right, -1 for left

func _ready():
	# Setup attack timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	# Initially disable attack area
	attack_area.set_deferred("monitoring", false)

func _physics_process(delta):
	handle_gravity(delta)
	handle_jump()
	handle_movement()
	handle_attack()
	move_and_slide()

func handle_gravity(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump():
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func handle_movement():
	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("moveleft", "moveright")
	
	if direction != 0:
		velocity.x = direction * speed
		# Update facing direction
		facing_direction = sign(direction)
		# Flip sprite based on direction
		sprite.scale.x = abs(sprite.scale.x) * facing_direction
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func handle_attack():
	if Input.is_action_just_pressed("meleeatack") and can_attack and not is_attacking:
		perform_attack()

func perform_attack():
	is_attacking = true
	can_attack = false
	
	# Visual feedback - flash sprite
	sprite.modulate = Color.RED
	
	# Enable attack area
	attack_area.monitoring = true
	
	# Position attack area based on facing direction
	var attack_offset = Vector2(attack_range * facing_direction, 0)
	attack_area.position = attack_offset
	
	# Optional: Play attack animation
	
	# Start cooldown timer
	attack_timer.start()
	
	# Disable attack area after short delay
	await get_tree().create_timer(0.15).timeout
	attack_area.monitoring = false
	is_attacking = false
	sprite.modulate = Color.WHITE

func _on_attack_timer_timeout():
	can_attack = true

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage") and body != self:
		body.take_damage(attack_damage)
		
		# Optional: Add knockback to hit enemy
		if body.has_method("apply_knockback"):
			var knockback_direction = Vector2(facing_direction, -0.3).normalized()
			body.apply_knockback(knockback_direction, 200)
