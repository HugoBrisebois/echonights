extends CharacterBody2D

@export var speed = 50.0
@export var direction = -1  # -1 for left, 1 for right

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_alive = true

# Optimization: Cache raycasting variables
var wall_check_distance = 20.0
var ground_check_distance = 50.0
var last_raycast_time = 0.0
var raycast_interval = 0.1  # Check every 0.1 seconds instead of every frame

func _ready():
	add_to_group("enemies")
	# Add some randomization to prevent all enemies from raycasting at the same time
	raycast_interval += randf() * 0.05

func _physics_process(delta):
	if not is_alive:
		return
		
	handle_gravity(delta)
	handle_movement()
	
	# Optimize raycasting - don't do it every frame
	last_raycast_time += delta
	if last_raycast_time >= raycast_interval:
		check_walls_and_edges()
		last_raycast_time = 0.0

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement():
	velocity.x = direction * speed
	move_and_slide()

func check_walls_and_edges():
	# Check for walls using built-in collision detection first
	if is_on_wall():
		direction *= -1
		return
	
	# Only do expensive raycasting if no wall collision detected
	var space_state = get_world_2d().direct_space_state
	
	# Create raycast query once and reuse
	var edge_check_start = global_position + Vector2(direction * wall_check_distance, 0)
	var edge_check_end = edge_check_start + Vector2(0, ground_check_distance)
	
	var query = PhysicsRayQueryParameters2D.create(edge_check_start, edge_check_end)
	query.collision_mask = 1  # Only check ground layer
	query.exclude = [self]    # Don't collide with self
	
	var result = space_state.intersect_ray(query)
	
	# If no ground ahead, turn around
	if not result:
		direction *= -1

func die():
	is_alive = false
	# Disable collision immediately to prevent multiple hits
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Simple fade out and remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
