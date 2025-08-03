extends CharacterBody2D

class_name Player

# Movement settings
@export var movement_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Jump settings
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var max_fall_speed: float = 500.0

# Attack settings
@export var attack_damage: int = 25
@export var attack_range: float = 80.0
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.5
@export var knockback_force: float = 200.0

# Node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/AttackCollision
@onready var attack_timer: Timer = $AttackTimer
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# State variables
var is_attacking: bool = false
var can_attack: bool = true
var facing_direction: int = 1  # 1 = right, -1 = left
var last_direction: Vector2 = Vector2.ZERO

# Attack tracking
var enemies_in_range: Array[Node2D] = []

# Signals
signal attack_performed(damage: int, targets: Array)
signal movement_changed(velocity: Vector2)
signal direction_changed(new_direction: int)

func _ready():
	"""
	Initialize the character controller
	"""
	print("=== PLAYER INITIALIZATION START ===")
	print("[INIT] Player character starting initialization...")
	
	# Setup timers
	if attack_timer:
		attack_timer.wait_time = attack_duration
		attack_timer.one_shot = true
		attack_timer.connect("timeout", _on_attack_timer_timeout)
		print("[INIT] Attack timer configured: %.2f seconds" % attack_duration)
	
	if cooldown_timer:
		cooldown_timer.wait_time = attack_cooldown
		cooldown_timer.one_shot = true
		cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
		print("[INIT] Cooldown timer configured: %.2f seconds" % attack_cooldown)
	
	# Setup attack area
	if attack_area:
		attack_area.connect("body_entered", _on_attack_area_body_entered)
		attack_area.connect("body_exited", _on_attack_area_body_exited)
		# Initially disable attack collision
		if attack_collision:
			attack_collision.disabled = true
		print("[INIT] Attack area configured")
	
	print("[INIT] Starting position: %s" % str(global_position))
	print("[INIT] Movement speed: %.1f, Jump velocity: %.1f" % [movement_speed, jump_velocity])
	print("[INIT] Attack damage: %d, Range: %.1f" % [attack_damage, attack_range])
	print("=== PLAYER INITIALIZATION COMPLETE ===\n")

func _physics_process(delta):
	"""
	Handle movement and physics every frame
	"""
	# Handle gravity
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():  # Space key
		perform_jump()
	
	# Handle horizontal movement
	handle_movement(delta)
	
	# Handle attack input with debug
	if Input.is_action_just_pressed("meleeatack"):
		print("🔍 [INPUT DEBUG] Attack button pressed!")
		if can_attack:
			print("🔍 [INPUT DEBUG] Can attack - calling perform_attack()")
			perform_attack()
		else:
			print("🔍 [INPUT DEBUG] Cannot attack - on cooldown or already attacking")
	
	# Apply movement
	var old_velocity = velocity
	move_and_slide()
	
	# Emit movement signal if velocity changed significantly
	if old_velocity.distance_to(velocity) > 10:
		movement_changed.emit(velocity)

func handle_movement(delta):
	"""
	Handle horizontal movement with acceleration and friction
	"""
	var input_direction = Input.get_axis("moveleft", "moveright")
	
	if input_direction != 0:
		# Accelerate in input direction
		velocity.x = move_toward(velocity.x, input_direction * movement_speed, acceleration * delta)
		
		# Update facing direction
		var new_facing = 1 if input_direction > 0 else -1
		if new_facing != facing_direction:
			facing_direction = new_facing
			update_sprite_direction()
			direction_changed.emit(facing_direction)
			print("[MOVEMENT] Changed direction: %s" % ("Right" if facing_direction == 1 else "Left"))
		
		last_direction = Vector2(input_direction, 0)
		
	else:
		# Apply friction when no input
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func perform_jump():
	"""
	Handle jump with logging
	"""
	print("\n[JUMP] Player jumping!")
	print("[JUMP] Jump velocity: %.1f" % jump_velocity)
	print("[JUMP] Ground position: %s" % str(global_position))
	
	velocity.y = jump_velocity
	
	# Play jump animation if available
	if animation_player and animation_player.has_animation("jump"):
		animation_player.play("jump")
		print("[JUMP] Jump animation started")

func perform_attack():
	"""
	Perform melee attack with detailed logging
	"""
	print("\n⚔️ === ATTACK SEQUENCE START ===")
	print("[ATTACK] Player initiating melee attack...")
	print("[ATTACK] Facing direction: %s" % ("Right" if facing_direction == 1 else "Left"))
	print("[ATTACK] Attack damage: %d" % attack_damage)
	print("[ATTACK] Attack range: %.1f" % attack_range)
	
	if is_attacking:
		print("[ATTACK] ❌ Already attacking, ignoring input")
		return
	
	if not can_attack:
		print("[ATTACK] ❌ Attack on cooldown, ignoring input")
		return
	
	# Start attack state
	is_attacking = true
	can_attack = false
	
	print("[ATTACK] ✅ Attack initiated successfully")
	
	# Enable attack collision
	if attack_collision:
		attack_collision.disabled = false
		print("[ATTACK] Attack collision enabled")
	else:
		print("[ATTACK] ⚠️ WARNING: No attack collision found!")
	
	# Position attack area based on facing direction
	position_attack_area()
	
	# DEBUG: Show current detection state
	debug_enemy_detection()
	
	# Play attack animation
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
		print("[ATTACK] Attack animation started")
	
	# Start attack timer
	if attack_timer:
		attack_timer.start()
		print("[ATTACK] Attack timer started (%.2f seconds)" % attack_duration)
	
	# Deal damage to enemies in range
	deal_damage_to_enemies()
	
	print("⚔️ === ATTACK SEQUENCE INITIATED ===\n")

func position_attack_area():
	"""
	Position the attack area based on facing direction
	"""
	if not attack_area:
		print("[ATTACK] ⚠️ No attack area found")
		return
	
	var offset_x = attack_range * 0.5 * facing_direction
	attack_area.position.x = offset_x
	
	print("[ATTACK] Attack area positioned at offset: %.1f" % offset_x)

func deal_damage_to_enemies():
	"""
	Deal damage to all enemies currently in attack range
	"""
	print("[ATTACK] Checking for enemies in attack range...")
	print("[ATTACK] Enemies detected: %d" % enemies_in_range.size())
	
	var damaged_enemies: Array = []
	
	for enemy in enemies_in_range:
		if enemy and is_instance_valid(enemy):
			print("[ATTACK] Attempting to damage enemy: %s" % enemy.name)
			
			# Check if enemy has take_damage method
			if enemy.has_method("take_damage"):
				enemy.take_damage(attack_damage, "Player Melee Attack")
				damaged_enemies.append(enemy)
				print("[ATTACK] ✅ Damaged %s for %d damage" % [enemy.name, attack_damage])
				
				# Apply knockback if enemy has the method
				if enemy.has_method("apply_knockback"):
					var knockback_direction = (enemy.global_position - global_position).normalized()
					enemy.apply_knockback(knockback_direction * knockback_force)
					print("[ATTACK] Applied knockback to %s" % enemy.name)
			else:
				print("[ATTACK] ⚠️ Enemy %s cannot take damage (no take_damage method)" % enemy.name)
		else:
			print("[ATTACK] ⚠️ Invalid enemy reference, skipping")
	
	# Emit attack signal
	attack_performed.emit(attack_damage, damaged_enemies)
	print("[ATTACK] Attack signal emitted with %d targets" % damaged_enemies.size())

func update_sprite_direction():
	"""
	Update sprite facing direction
	"""
	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * facing_direction
		print("[VISUAL] Sprite direction updated: %s" % ("Right" if facing_direction == 1 else "Left"))

func _on_attack_timer_timeout():
	"""
	Called when attack duration ends
	"""
	print("\n[ATTACK] Attack duration completed")
	print("[ATTACK] Ending attack state...")
	
	is_attacking = false
	
	# Disable attack collision
	if attack_collision:
		attack_collision.disabled = true
		print("[ATTACK] Attack collision disabled")
	
	# Start cooldown
	if cooldown_timer:
		cooldown_timer.start()
		print("[ATTACK] Cooldown started (%.2f seconds)" % attack_cooldown)
	
	# Return to idle animation
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
		print("[ATTACK] Returned to idle animation")
	
	print("[ATTACK] Attack sequence completed\n")

func _on_cooldown_timer_timeout():
	"""
	Called when attack cooldown ends
	"""
	print("[ATTACK] Cooldown completed - can attack again")
	can_attack = true

func _on_attack_area_body_entered(body):
	"""
	Called when a potential target enters attack range
	"""
	print("\n[DETECTION] Body entered attack range: %s" % body.name)
	
	# Check if it's an enemy (has enemy class or group)
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		if body not in enemies_in_range:
			enemies_in_range.append(body)
			print("[DETECTION] ✅ Enemy added to attack range: %s" % body.name)
			print("[DETECTION] Total enemies in range: %d" % enemies_in_range.size())
		else:
			print("[DETECTION] Enemy already in range: %s" % body.name)
	else:
		print("[DETECTION] Non-enemy body ignored: %s" % body.name)

func _on_attack_area_body_exited(body):
	"""
	Called when a target leaves attack range
	"""
	print("\n[DETECTION] Body left attack range: %s" % body.name)
	
	if body in enemies_in_range:
		enemies_in_range.erase(body)
		print("[DETECTION] ✅ Enemy removed from attack range: %s" % body.name)
		print("[DETECTION] Total enemies in range: %d" % enemies_in_range.size())

# Utility functions
func debug_enemy_detection():
	"""
	Debug function to check enemy detection status
	"""
	print("\n🔍 === ENEMY DETECTION DEBUG ===")
	print("🔍 Player Position: %s" % str(global_position))
	if attack_area:
		print("🔍 Attack Area Position: %s" % str(attack_area.global_position))
		print("🔍 Attack Area Local Position: %s" % str(attack_area.position))
	else:
		print("🔍 Attack Area Position: NO ATTACK AREA")
		print("🔍 Attack Area Local Position: NO ATTACK AREA")
	
	print("🔍 Facing Direction: %s" % ("Right" if facing_direction == 1 else "Left"))
	
	if attack_collision:
		print("🔍 Attack Collision Disabled: %s" % str(attack_collision.disabled))
	else:
		print("🔍 Attack Collision Disabled: NO COLLISION")
	
	print("🔍 Enemies in Range: %d" % enemies_in_range.size())
	
	if attack_area:
		var bodies = attack_area.get_overlapping_bodies()
		print("🔍 All Bodies in Attack Area: %d" % bodies.size())
		for body in bodies:
			print("🔍   - Body: %s (Groups: %s)" % [body.name, str(body.get_groups())])
	
	for i in range(enemies_in_range.size()):
		var enemy = enemies_in_range[i]
		if enemy and is_instance_valid(enemy):
			print("🔍 Enemy %d: %s at %s" % [i, enemy.name, str(enemy.global_position)])
			print("🔍   - Has take_damage method: %s" % str(enemy.has_method("take_damage")))
			print("🔍   - Is in enemies group: %s" % str(enemy.is_in_group("enemies")))
			print("🔍   - Distance from player: %.1f" % global_position.distance_to(enemy.global_position))
		else:
			print("🔍 Enemy %d: NULL/INVALID" % i)
	print("🔍 === END ENEMY DEBUG ===\n")

func is_grounded() -> bool:
	"""
	Check if player is on the ground
	"""
	return is_on_floor()

func get_movement_state() -> String:
	"""
	Get current movement state as string
	"""
	if not is_on_floor():
		return "airborne"
	elif abs(velocity.x) > 10:
		return "running"
	elif is_attacking:
		return "attacking"
	else:
		return "idle"

func print_status():
	"""
	Print complete player status for debugging
	"""
	print("\n🎮 === PLAYER STATUS REPORT ===")
	print("🎮 Position: %s" % str(global_position))
	print("🎮 Velocity: %s" % str(velocity))
	print("🎮 Facing: %s" % ("Right" if facing_direction == 1 else "Left"))
	print("🎮 State: %s" % get_movement_state())
	print("🎮 Grounded: %s" % str(is_grounded()))
	print("🎮 Attacking: %s" % str(is_attacking))
	print("🎮 Can Attack: %s" % str(can_attack))
	print("🎮 Enemies in Range: %d" % enemies_in_range.size())
	print("🎮 === END STATUS REPORT ===\n")

# Input method for external damage (e.g., from enemies)
func take_damage(damage: int, source: String = "Unknown"):
	"""
	Player takes damage - implement your own health system here
	"""
	print("\n[PLAYER DAMAGE] Player taking %d damage from %s" % [damage, source])
	# Add your player health system here

func apply_knockback(knockback_velocity: Vector2):
	"""
	Apply knockback force to player
	"""
	print("[KNOCKBACK] Player receiving knockback: %s" % str(knockback_velocity))
	velocity += knockback_velocity
