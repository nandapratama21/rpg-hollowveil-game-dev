extends Area2D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 5
@export var spawn_interval: float = 3.0
@export var spawn_radius: float = 100.0
@export var max_spawn_attempts: int = 30  # Maximum attempts to find valid spawn position
@export var obstacle_layer_mask: int = 4  # Set this to the collision layer of your obstacles

var current_enemies = 0
var can_spawn = true

func _ready():
	# Start the spawning timer
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()

func _on_spawn_timer_timeout():
	if current_enemies < max_enemies and can_spawn:
		spawn_enemy()

func spawn_enemy():
	var space_state = get_world_2d().direct_space_state
	var valid_position = false
	var spawn_position = Vector2.ZERO
	var attempts = 0
	
	# Try multiple positions until finding a valid one
	while !valid_position and attempts < max_spawn_attempts:
		attempts += 1
		
		# Generate a random position within the spawn radius
		var random_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
		spawn_position = global_position + (random_direction * randf_range(0, spawn_radius))
		
		# Check if position is valid (not inside obstacles)
		valid_position = is_valid_spawn_position(spawn_position, space_state)
	
	if !valid_position:
		print("Failed to find valid spawn position after ", attempts, " attempts")
		return
	
	# Instance the enemy at the valid position
	var enemy = enemy_scene.instantiate()
	
	# Important: Get the same parent that the manual enemies use
	var target_parent = get_parent()
	
	# Set position before adding to scene
	enemy.position = spawn_position - target_parent.global_position
	
	# Copy Z index and other rendering properties from a manually placed enemy if available
	var manual_enemies = get_tree().get_nodes_in_group("enemies")
	if manual_enemies.size() > 0:
		for manual_enemy in manual_enemies:
			# Skip if this is a dynamically spawned enemy
			if manual_enemy.get_meta("spawned", false) == true:
				continue
				
			# Found a manually placed enemy, copy its properties
			enemy.z_index = manual_enemy.z_index
			enemy.z_as_relative = manual_enemy.z_as_relative
			enemy.y_sort_enabled = manual_enemy.y_sort_enabled
			break
	
	# Mark this as a spawned enemy
	enemy.set_meta("spawned", true)
	
	# Connect death signal if enemy has one
	if enemy.has_signal("enemy_died"):
		enemy.connect("enemy_died", _on_enemy_died)
	
	# Check for TileMapLayerPlayerBehind node
	var tile_map_player_behind = null
	var insert_index = -1 # Default to adding at the end
	
	# Find the TileMapLayerPlayerBehind node and its index
	for i in range(target_parent.get_child_count()):
		var child = target_parent.get_child(i)
		if child.name == "TileMapLayerPlayerBehind":
			tile_map_player_behind = child
			insert_index = i
			break
	
	# Add enemy to the scene at the correct position in hierarchy
	if insert_index >= 0:
		# Add before the TileMapLayerPlayerBehind node
		target_parent.add_child(enemy)
		target_parent.move_child(enemy, insert_index)
		print("Added enemy before TileMapLayerPlayerBehind")
	else:
		# Fallback: just add it to the parent
		target_parent.add_child(enemy)
		print("Added enemy to parent (no TileMapLayerPlayerBehind found)")
	
	# If there's a Y-sort node, try to use that instead
	var y_sort = null
	for node in target_parent.get_children():
		if node.is_class("Node2D") and node.is_y_sort_enabled():
			y_sort = node
			break
	
	if y_sort:
		# Remove from current parent
		target_parent.remove_child(enemy)
		# Add to Y-sort node
		y_sort.add_child(enemy)
		# Restore position
		enemy.position = spawn_position - y_sort.global_position
		print("Moved enemy to Y-sort node")
	
	current_enemies += 1
	print("Spawned enemy at: ", spawn_position)

func is_valid_spawn_position(pos: Vector2, space_state) -> bool:
	# Check for obstacles at the spawn position
	
	# Method 1: Using raycast from spawner to spawn position
	var params = PhysicsRayQueryParameters2D.create(global_position, pos, obstacle_layer_mask)
	var result = space_state.intersect_ray(params)
	if result:
		# Hit an obstacle on the way to spawn position
		return false
	
	# Method 2: Check for collisions at the exact spawn point using a small shape
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0  # Size of collision check (adjust based on enemy size)
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = obstacle_layer_mask
	
	var collisions = space_state.intersect_shape(query)
	if collisions.size() > 0:
		# Found obstacle(s) at spawn position
		return false
	
	return true

func _on_enemy_died():
	current_enemies -= 1

func _on_body_entered(body):
	# Optionally pause spawning when player enters area
	if body.is_in_group("player"):
		can_spawn = false

func _on_body_exited(body):
	# Resume spawning when player exits
	if body.is_in_group("player"):
		can_spawn = true
