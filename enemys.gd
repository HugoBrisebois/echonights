extends Node

# Pool dead enemies for reuse instead of constantly creating/destroying
var enemy_pool = []
var max_pool_size = 10

func spawn_enemy(enemy_scene: PackedScene, position: Vector2):
	var enemy
	
	# Try to reuse from pool first
	if enemy_pool.size() > 0:
		enemy = enemy_pool.pop_back()
		enemy.global_position = position
		enemy.is_alive = true
		enemy.modulate.a = 1.0
		enemy.set_collision_layer_value(1, true)
		enemy.set_collision_mask_value(1, true)
	else:
		# Create new enemy if pool is empty
		enemy = enemy_scene.instantiate()
		enemy.global_position = position
		add_child(enemy)
	
	return enemy

func return_enemy_to_pool(enemy):
	if enemy_pool.size() < max_pool_size:
		enemy.get_parent().remove_child(enemy)
		enemy_pool.push_back(enemy)
	else:
		enemy.queue_free()
