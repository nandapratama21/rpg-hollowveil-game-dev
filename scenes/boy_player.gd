extends CharacterBody2D

@export var speed = 300.0
@export var max_health = 100
@export var health = 100

@onready var animated_sprite = $AnimatedSprite2D
@onready var weapon_sprite = $WeaponSprite if has_node("WeaponSprite") else null

var equipped_item = null
var attack_cooldown = false
var is_attacking = false
var facing_direction = "Down"
var invincible = false
var invincibility_time = 1.0
var knockback_resistance = 0.5
var current_weapon_index = -1

signal health_changed(new_health)

func _ready():
	# Add player to player group for easier reference
	add_to_group("player")
	
	# Set initial animation
	animated_sprite.play("Idle Down")
	
	# Make sure weapon sprite is hidden initially
	if weapon_sprite:
		weapon_sprite.visible = false
	
	# Initialize health UI
	emit_signal("health_changed", health)
	
	# Update any existing health UI in the scene
	var health_count = get_tree().get_nodes_in_group("health_ui")
	for ui in health_count:
		if ui.has_method("update_health"):
			ui.update_health(health)

	# Connect to InventoryUI if it exists
	var inventory_ui = get_tree().get_nodes_in_group("inventory_ui")
	if inventory_ui.size() > 0:
		print("Found inventory UI")


func _physics_process(delta):
	# Skip if attacking
	if is_attacking:
		return
		
	# Get input direction
	var direction = Vector2.ZERO
	
	# Check if movement is allowed
	var level = get_parent()
	if level.has_method("_ready") and level.get("player_can_move") != null and !level.player_can_move:
		# No movement during dialogue
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	# Normalize to prevent faster diagonal movement
	if direction.length() > 0:
		direction = direction.normalized()
		
		# Set animation based on movement direction
		if abs(direction.x) > abs(direction.y):
			# Horizontal movement is dominant
			if direction.x > 0:
				animated_sprite.play("Walk Right")
				facing_direction = "Right"
			else:
				animated_sprite.play("Walk Left")
				facing_direction = "Left"
		else:
			# Vertical movement is dominant
			if direction.y > 0:
				animated_sprite.play("Walk Down")
				facing_direction = "Down"
			else:
				animated_sprite.play("Walk Up")
				facing_direction = "Up"
				
		# Update weapon position
		if weapon_sprite and weapon_sprite.visible:
			update_weapon_position()
	else:
		# No movement, play idle animation based on the last movement
		if animated_sprite.animation.begins_with("Walk") or animated_sprite.animation.begins_with("Attack"):
			animated_sprite.play("Idle " + facing_direction)

	# Velocity
	velocity = direction * speed

	# Move the character
	move_and_slide()
	
	# Attack input (spacebar or E key)
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_focus_next"):
		attack()

func equip_item(item):
	# Print debug to see when this is called
	print("Player equipping: ", item.item_name if item else "None")
	
	equipped_item = item
	
	# Show weapon sprite
	if weapon_sprite and item and item.item_texture:
		weapon_sprite.texture = item.item_texture
		weapon_sprite.visible = true
		update_weapon_position()
	elif weapon_sprite:
		# If no valid item/texture, hide the weapon
		weapon_sprite.visible = false
		
	print("Equipped: ", item.item_name if item else "None")

func unequip_item():
	equipped_item = null
	
	# Hide weapon sprite
	if weapon_sprite:
		weapon_sprite.visible = false
	
	print("Unequipped weapon")

func update_weapon_position():
	# Position weapon based on facing direction
	if not weapon_sprite:
		return
		
	match facing_direction:
		"Up":
			weapon_sprite.position = Vector2(-8, 0) # Adjust position for up
			weapon_sprite.rotation_degrees = -45
			weapon_sprite.flip_h = false
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = -1 # Put behind player
			
		"Down":
			weapon_sprite.position = Vector2(-2, 16) # Adjust position for down
			weapon_sprite.rotation_degrees = 45
			weapon_sprite.flip_h = false
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = 1 # Put in front of player
			
		"Left":
			weapon_sprite.position = Vector2(-16, 8) # Adjust position for left
			weapon_sprite.rotation_degrees = 0
			weapon_sprite.flip_h = true # Flip horizontally for left direction
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = 0 # Same as player
			
		"Right":
			weapon_sprite.position = Vector2(0, 8) # Adjust position for right
			weapon_sprite.rotation_degrees = 0
			weapon_sprite.flip_h = false # No flip for right direction
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = 0 # Same as player

func attack():
	# First check if a weapon is equipped
	if equipped_item == null:
		print("No weapon equipped!")
		return
	
	# Also check if the equipped item is a weapon type
	if equipped_item.item_type != "weapon":
		print("Equipped item is not a weapon!")
		return
	
	# Start attack sequence
	is_attacking = true
	attack_cooldown = true
	
	# Play attack animation based on facing direction
	animated_sprite.play("Attack " + facing_direction)
	
	# Hide weapon during attack animation since it's part of the animation
	if weapon_sprite and weapon_sprite.visible:
		update_weapon_attack_position()
	
	# Check for bushes or enemies in attack direction
	var attack_direction = Vector2.ZERO
	match facing_direction:
		"Up": attack_direction = Vector2(0, -1)
		"Down": attack_direction = Vector2(0, 1)
		"Left": attack_direction = Vector2(-1, 0)
		"Right": attack_direction = Vector2(1, 0)
	
	# Use raycast to check for obstacles
	var ray = RayCast2D.new()
	ray.position = Vector2(0, 0)
	ray.target_position = attack_direction * 32  # Attack range
	ray.collision_mask = 6  # Layer where bushes (4) and enemies (2) are
	add_child(ray)
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var object = ray.get_collider()
		print("Hit: ", object.name)
		
		# If it's a bush, destroy it
		if object.is_in_group("bushes"):
			if object.has_method("destroy"):
				object.destroy()
				
		# If it's an enemy, damage it
		if object.is_in_group("enemies"):
			if object.has_method("take_damage"):
				# Get weapon damage or use default
				var damage = 10  # Default damage
				if equipped_item.get("damage"):
					damage = equipped_item.damage
					
				print("Attacking enemy with ", damage, " damage")
				object.take_damage(damage)
	
	ray.queue_free()
	
	# Wait for animation to finish
	await get_tree().create_timer(0.4).timeout
	
	# Return to idle animation and show weapon again
	animated_sprite.play("Idle " + facing_direction)
	if weapon_sprite and equipped_item:
		weapon_sprite.visible = true
		update_weapon_position()
	
	is_attacking = false
	
	# Attack cooldown
	await get_tree().create_timer(0.2).timeout
	attack_cooldown = false

func update_weapon_attack_position():
	if not weapon_sprite:
		return
		
	match facing_direction:
		"Up":
			weapon_sprite.position = Vector2(-6, -4) # Custom position for attack up
			weapon_sprite.rotation_degrees = -90
			weapon_sprite.flip_h = false
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = -1
		"Down":
			weapon_sprite.position = Vector2(0, 12) # Custom position for attack down
			weapon_sprite.rotation_degrees = 90
			weapon_sprite.flip_h = false
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = 1
		"Left":
			weapon_sprite.position = Vector2(-14, 4) # Custom position for attack left
			weapon_sprite.rotation_degrees = 0
			weapon_sprite.flip_h = true # Keep flipped horizontally for left attack
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = 0
		"Right":
			weapon_sprite.position = Vector2(4, 4) # Custom position for attack right
			weapon_sprite.rotation_degrees = 0
			weapon_sprite.flip_h = false # No flip for right attack
			weapon_sprite.flip_v = false
			weapon_sprite.z_index = 0

func collect(item):
	# Add to inventory
	var player_inventory = preload("res://assets/player_inventory.tres")
	if player_inventory:
		player_inventory.insert(item)
		
		# DEBUG: Print item details
		print("Collected item: ", item.item_name, " type: ", item.item_type)
		
		# Auto-equip the item directly
		equip_item(item)

func take_damage(amount):
	# Ignore damage if invincible
	if invincible:
		return
		
	health -= amount
	print("Player took ", amount, " damage! Health: ", health)
	
	# Emit signal for UI update
	emit_signal("health_changed", health)
	
	# Update any existing health UI in the scene
	var health_count = get_tree().get_nodes_in_group("health_ui")
	for ui in health_count:
		if ui.has_method("update_health"):
			ui.update_health(health)
	
	# Flash red
	modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Play hurt animation if available
	# Using idle animation as fallback
	animated_sprite.play("Idle " + facing_direction)
	
	# Check if dead
	if health <= 0:
		die()
		return
	
	# Temporary invincibility
	invincible = true
	await get_tree().create_timer(invincibility_time).timeout
	invincible = false

func die():
	# Disable movement
	set_physics_process(false)
	
	# Play death animation if available
	if animated_sprite.sprite_frames.has_animation("Die"):
		animated_sprite.play("Die")
	else:
		# Fallback to idle animation with red tint
		animated_sprite.play("Idle " + facing_direction)
		modulate = Color(1, 0.3, 0.3, 0.7)
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Notify level
	var level = get_parent()
	if level.has_method("_on_player_died"):
		level._on_player_died()

func apply_knockback(force):
	# Apply knockback with some resistance
	velocity = force * (1 - knockback_resistance)
	move_and_slide()
	
	# Reset velocity after short delay
	await get_tree().create_timer(0.2).timeout
	velocity = Vector2.ZERO

func heal(amount):
	health = min(health + amount, max_health)
	
	# Emit signal for UI update
	emit_signal("health_changed", health)
	
	# Update any existing health UI in the scene
	var health_count = get_tree().get_nodes_in_group("health_ui")
	for ui in health_count:
		if ui.has_method("update_health"):
			ui.update_health(health)
	
	# Healing effect
	modulate = Color(0.3, 1, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func get_health():
	return health


func _input(event):
	# Check for weapon quick switch keys
	if event is InputEventKey and event.pressed:
		var key_num = -1
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			key_num = event.keycode - KEY_1  # 0-8
			switch_weapon(key_num)
		# Cycling through weapons with Q/E
		elif event.keycode == KEY_Q:
			cycle_weapon(-1)  # Previous weapon
		elif event.keycode == KEY_E:
			cycle_weapon(1)   # Next weapon

func switch_weapon(slot_index):
	var player_inventory = preload("res://assets/player_inventory.tres")
	if !player_inventory or slot_index >= player_inventory.slots.size():
		return
		
	var slot = player_inventory.slots[slot_index]
	if slot.item and slot.item.item_type == "weapon":
		print("Switching to weapon: ", slot.item.item_name)
		equip_item(slot.item)
		current_weapon_index = slot_index

func cycle_weapon(direction):
	var player_inventory = preload("res://assets/player_inventory.tres")
	if !player_inventory:
		return
		
	var weapons = []
	var weapon_indices = []
	
	# Find all weapons in inventory
	for i in range(player_inventory.slots.size()):
		var slot = player_inventory.slots[i]
		if slot.item and slot.item.item_type == "weapon":
			weapons.append(slot.item)
			weapon_indices.append(i)
	
	if weapons.size() == 0:
		return  # No weapons to cycle
		
	# Find current weapon index in the weapons list
	var current_index = -1
	for i in range(weapon_indices.size()):
		if weapon_indices[i] == current_weapon_index:
			current_index = i
			break
	
	# Cycle to next/previous weapon
	if current_index == -1:
		# No weapon equipped, select first one
		current_index = 0
	else:
		# Move to next/previous
		current_index = (current_index + direction) % weapons.size()
		if current_index < 0:
			current_index = weapons.size() - 1
	
	# Equip the selected weapon
	equip_item(weapons[current_index])
	current_weapon_index = weapon_indices[current_index]
	print("Cycled to weapon: ", weapons[current_index].item_name)

func increase_max_health(amount):
	# Track old max health for percentage calculation
	var old_max_health = max_health
	
	# Increase max health
	max_health += amount
	
	# Also increase current health proportionally
	var health_percentage = float(health) / old_max_health
	health = int(health_percentage * max_health)
	
	# Emit signal for UI update
	emit_signal("health_changed", health)
	
	# Update any existing health UI in the scene
	var health_count = get_tree().get_nodes_in_group("health_ui")
	for ui in health_count:
		if ui.has_method("update_max_health"):
			ui.update_max_health(max_health)
	
	print("Max health increased to: ", max_health)
