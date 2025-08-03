extends CharacterBody2D

class_name Enemy

# Enemy stats
@export var max_health: int = 100
@export var current_health: int
@export var damage_flash_duration: float = 0.2
@export var enemy_name: String = "Enemy"  # For better debug identification

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar  # Optional health bar

# Damage flash effect
var original_modulate: Color
var is_flashing: bool = false
var is_dead: bool = false

# Signals
signal enemy_died(enemy: Enemy)
signal health_changed(current_health: int, max_health: int)

func _ready():
	"""
	Initialize the enemy when it enters the scene
	"""
	print("=== ENEMY INITIALIZATION START ===")
	print("[INIT] Enemy '%s' starting initialization..." % enemy_name)
	
	# Initialize health
	current_health = max_health
	original_modulate = sprite.modulate
	is_dead = false
	
	print("[INIT] Health initialized: %d/%d" % [current_health, max_health])
	print("[INIT] Original sprite color: %s" % str(original_modulate))
	
	# Connect health bar if it exists
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		print("[INIT] Health bar connected and configured")
	else:
		print("[INIT] No health bar found - continuing without visual health display")
	
	print("[INIT] Enemy '%s' successfully initialized!" % enemy_name)
	print("=== ENEMY INITIALIZATION COMPLETE ===\n")

func take_damage(damage_amount: int, damage_source: String = "Unknown"):
	"""
	Apply damage to the enemy with detailed logging
	"""
	print("\n--- DAMAGE EVENT START ---")
	print("[DAMAGE] Enemy '%s' receiving damage..." % enemy_name)
	print("[DAMAGE] Damage amount: %d" % damage_amount)
	print("[DAMAGE] Damage source: %s" % damage_source)
	print("[DAMAGE] Current status - Alive: %s, Health: %d/%d" % [str(not is_dead), current_health, max_health])
	
	# Check if enemy is already dead
	if is_dead or current_health <= 0:
		print("[DAMAGE] ❌ DAMAGE REJECTED - Enemy is already dead!")
		print("--- DAMAGE EVENT END ---\n")
		return
	
	# Validate damage amount
	if damage_amount < 0:
		print("[DAMAGE] ⚠️ WARNING - Negative damage amount, converting to heal")
		heal(abs(damage_amount))
		return
	
	if damage_amount == 0:
		print("[DAMAGE] ⚠️ WARNING - Zero damage dealt, no effect")
		print("--- DAMAGE EVENT END ---\n")
		return
	
	# Apply damage
	var old_health = current_health
	current_health = max(0, current_health - damage_amount)
	var actual_damage = old_health - current_health
	
	print("[DAMAGE] ✅ Damage applied successfully!")
	print("[DAMAGE] Expected damage: %d, Actual damage: %d" % [damage_amount, actual_damage])
	print("[DAMAGE] Health change: %d → %d (-%d)" % [old_health, current_health, actual_damage])
	print("[DAMAGE] Health percentage: %.1f%%" % (get_health_percentage() * 100))
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		print("[DAMAGE] Health bar updated to %d" % current_health)
	
	# Emit health changed signal
	health_changed.emit(current_health, max_health)
	print("[DAMAGE] Health changed signal emitted")
	
	# Visual feedback
	print("[DAMAGE] Starting damage flash effect...")
	flash_damage()
	
	# Check for death
	if current_health <= 0:
		print("[DAMAGE] 💀 FATAL DAMAGE - Initiating death sequence")
		die()
	else:
		print("[DAMAGE] Enemy survived with %d health remaining" % current_health)
	
	print("--- DAMAGE EVENT END ---\n")

func heal(heal_amount: int):
	"""
	Heal the enemy with detailed logging
	"""
	print("\n+++ HEAL EVENT START +++")
	print("[HEAL] Enemy '%s' receiving healing..." % enemy_name)
	print("[HEAL] Heal amount: %d" % heal_amount)
	
	if is_dead or current_health <= 0:
		print("[HEAL] ❌ HEAL REJECTED - Cannot heal dead enemy")
		print("+++ HEAL EVENT END +++\n")
		return
	
	if heal_amount <= 0:
		print("[HEAL] ⚠️ WARNING - Invalid heal amount: %d" % heal_amount)
		print("+++ HEAL EVENT END +++\n")
		return
	
	var old_health = current_health
	current_health = min(max_health, current_health + heal_amount)
	var actual_heal = current_health - old_health
	
	print("[HEAL] ✅ Healing applied successfully!")
	print("[HEAL] Expected heal: %d, Actual heal: %d" % [heal_amount, actual_heal])
	print("[HEAL] Health change: %d → %d (+%d)" % [old_health, current_health, actual_heal])
	
	if current_health >= max_health:
		print("[HEAL] 💚 Enemy fully healed!")
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		print("[HEAL] Health bar updated to %d" % current_health)
	
	# Emit health changed signal
	health_changed.emit(current_health, max_health)
	print("[HEAL] Health changed signal emitted")
	print("+++ HEAL EVENT END +++\n")

func die():
	"""
	Handle enemy death with comprehensive logging
	"""
	print("\n💀💀💀 DEATH SEQUENCE START 💀💀💀")
	print("[DEATH] Enemy '%s' beginning death sequence..." % enemy_name)
	print("[DEATH] Final health: %d/%d" % [current_health, max_health])
	
	# Mark as dead immediately to prevent further damage
	is_dead = true
	current_health = 0
	print("[DEATH] Enemy marked as dead, health set to 0")
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		print("[DEATH] Collision disabled")
	else:
		print("[DEATH] ⚠️ No collision shape found to disable")
	
	# Stop movement
	velocity = Vector2.ZERO
	print("[DEATH] Movement stopped")
	
	# Emit death signal BEFORE starting animations
	enemy_died.emit(self)
	print("[DEATH] Death signal emitted to listeners")
	
	# Start death animation
	print("[DEATH] Starting fade-out animation...")
	var tween = create_tween()
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		print("[DEATH] Fade animation configured (0.5 seconds)")
	else:
		print("[DEATH] ⚠️ No sprite found for fade animation")
	
	# Wait for animation and cleanup
	if sprite and tween:
		await tween.finished
		print("[DEATH] Fade animation completed")
	
	print("[DEATH] Removing enemy from scene...")
	queue_free()
	print("[DEATH] Enemy '%s' queued for removal" % enemy_name)
	print("💀💀💀 DEATH SEQUENCE COMPLETE 💀💀💀\n")

func flash_damage():
	"""
	Visual feedback when taking damage with logging
	"""
	print("[FLASH] Starting damage flash effect...")
	
	if is_flashing:
		print("[FLASH] ⚠️ Already flashing, skipping new flash")
		return
	
	if not sprite:
		print("[FLASH] ❌ No sprite found, cannot flash")
		return
	
	is_flashing = true
	print("[FLASH] Sprite color: %s → RED" % str(sprite.modulate))
	
	# Flash red
	sprite.modulate = Color.RED
	
	# Return to original color after duration
	await get_tree().create_timer(damage_flash_duration).timeout
	
	if sprite and not is_dead:  # Only restore color if still alive and sprite exists
		sprite.modulate = original_modulate
		print("[FLASH] Sprite color restored: RED → %s" % str(original_modulate))
	
	is_flashing = false
	print("[FLASH] Flash effect completed")

func is_alive() -> bool:
	"""
	Check if enemy is still alive with logging
	"""
	var alive = not is_dead and current_health > 0
	print("[STATUS] Enemy '%s' alive status: %s (Health: %d, Dead flag: %s)" % 
		[enemy_name, str(alive), current_health, str(is_dead)])
	return alive

func get_health_percentage() -> float:
	"""
	Get health as a percentage with logging
	"""
	if max_health == 0:
		print("[STATUS] ⚠️ Max health is 0, returning 0% health")
		return 0.0
	
	var percentage = float(current_health) / float(max_health)
	print("[STATUS] Health percentage: %.1f%% (%d/%d)" % [percentage * 100, current_health, max_health])
	return percentage

# Debug functions for testing
func _input(event):
	"""
	Debug input handling with detailed logging
	"""
	if Engine.is_editor_hint():
		return
		
	print("\n[INPUT] Debug input detected...")
	
	if event.is_action_pressed("L"):  # Space key
		print("[INPUT] Space pressed - Dealing 25 debug damage")
		take_damage(25, "Debug Test (Space Key)")
		
	elif event.is_action_pressed("ui_select"):  # Enter key
		print("[INPUT] Enter pressed - Healing 20 health")
		heal(20)
		
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		print("[INPUT] Escape pressed - Instant kill debug")
		take_damage(current_health + 100, "Debug Instant Kill (Escape Key)")

func _on_area_2d_body_entered(body):
	"""
	Example collision detection with logging
	"""
	print("\n[COLLISION] Body entered enemy area!")
	print("[COLLISION] Colliding body: %s (Type: %s)" % [body.name, body.get_class()])
	
	if body.has_method("deal_damage"):
		var damage = body.deal_damage()
		print("[COLLISION] Body can deal damage: %d" % damage)
		take_damage(damage, "Collision with " + body.name)
	else:
		print("[COLLISION] Body cannot deal damage (no deal_damage method)")

# Function to receive damage from other scripts
func _on_damage_received(damage: int, source: String = "External Script"):
	"""
	External damage interface with logging
	"""
	print("\n[EXTERNAL] External damage received via signal/call")
	print("[EXTERNAL] Damage: %d, Source: %s" % [damage, source])
	take_damage(damage, source)

# Debug status function
func print_status():
	"""
	Print complete enemy status - useful for debugging
	"""
	print("\n📊 === ENEMY STATUS REPORT ===")
	print("📊 Name: %s" % enemy_name)
	print("📊 Health: %d/%d (%.1f%%)" % [current_health, max_health, get_health_percentage() * 100])
	print("📊 Alive: %s" % str(is_alive()))
	print("📊 Flashing: %s" % str(is_flashing))
	print("📊 Position: %s" % str(global_position))
	print("📊 Velocity: %s" % str(velocity))
	print("📊 === END STATUS REPORT ===\n")
