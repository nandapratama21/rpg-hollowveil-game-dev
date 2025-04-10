extends CharacterBody2D

@export var max_health = 50
@export var health = 50
@export var attack_damage = 10
@export var detect_radius = 120
@export var chase_speed = 25
@export var patrol_speed = 15
@export var knockback_force = 150
@export var attack_range = 30 

@onready var animated_sprite = $AnimatedSprite2D

enum State {PATROL, CHASE, ATTACK, HURT, DIE}
var current_state = State.PATROL
var patrol_direction = Vector2.RIGHT
var player = null
var patrol_timer = 0
var patrol_point_duration = 3.0 # Longer patrol duration
var can_attack = true
var attack_cooldown = 2.0 # Longer attack cooldown

func _ready():
	add_to_group("enemies")
	
	# Initialize animations
	if animated_sprite:
		animated_sprite.play("Idle Down")
	
	# Find player reference
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if health <= 0 or current_state == State.DIE:
		return
		
	match current_state:
		State.PATROL:
			_handle_patrol(delta)
		State.CHASE:
			_handle_chase()
		State.ATTACK:
			_handle_attack()
		State.HURT:
			# Do nothing while hurt animation plays
			pass
	
	# Apply movement
	if current_state != State.ATTACK and current_state != State.HURT:
		move_and_slide()

func _handle_patrol(delta):
	# Check if player is within detection radius
	if player and global_position.distance_to(player.global_position) < detect_radius:
		current_state = State.CHASE
		return
		
	# Simple patrol behavior: move in current direction for a while, then switch
	patrol_timer += delta
	if patrol_timer > patrol_point_duration:
		patrol_timer = 0
		patrol_direction = -patrol_direction # Reverse direction
	
	velocity = patrol_direction * patrol_speed
	
	# Set animation based on direction
	if patrol_direction.x > 0:
		animated_sprite.play("Walk Right")
	else:
		animated_sprite.play("Walk Left")

func _handle_chase():
	# If player is too far away, go back to patrol
	if !player or global_position.distance_to(player.global_position) > detect_radius * 1.5:
		current_state = State.PATROL
		return
	
	# Move toward player - reptiles are slower but more determined
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	
	# Set animation based on direction
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement is dominant
		if direction.x > 0:
			animated_sprite.play("Walk Right")
		else:
			animated_sprite.play("Walk Left")
	else:
		# Vertical movement is dominant
		if direction.y > 0:
			animated_sprite.play("Walk Down")
		else:
			animated_sprite.play("Walk Up")
	
	# Check if close enough to attack
	if global_position.distance_to(player.global_position) < attack_range and can_attack:
		current_state = State.ATTACK

func _handle_attack():
	# Play attack animation if available, otherwise use idle animation
	var current_anim = animated_sprite.animation
	if current_anim.begins_with("Walk"):
		var direction = current_anim.split(" ")[1]
		if animated_sprite.sprite_frames.has_animation("Attack " + direction):
			animated_sprite.play("Attack " + direction)
		else:
			animated_sprite.play("Idle " + direction)
	
	# Stop movement
	velocity = Vector2.ZERO
	
	# Apply damage to player if in range
	if player and global_position.distance_to(player.global_position) < attack_range:
		if player.has_method("take_damage"):
			# Calculate chance for critical hit (20% chance)
			var is_critical = randf() < 0.20
			var final_damage = attack_damage
			
			if is_critical:
				final_damage = int(attack_damage * 1.5)
				print("Reptile lands a CRITICAL hit!")
			
			player.take_damage(final_damage)
			
			# Apply knockback to player
			var knockback_dir = (player.global_position - global_position).normalized()
			player.apply_knockback(knockback_dir * knockback_force)
	
	# Attack cooldown
	can_attack = false
	
	# Wait for attack animation to complete
	await get_tree().create_timer(0.7).timeout # Reptiles have a slower attack
	
	# Return to chase state
	current_state = State.CHASE
	
	# Reset cooldown after delay
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount):
	if current_state == State.DIE:
		return
	
	# Reptiles have a chance to reduce damage (tough hide)
	var damage_reduction = 0
	if randf() < 0.3: # 30% chance to reduce damage
		damage_reduction = int(amount * 0.3)
		print("Reptile's tough hide reduced damage by ", damage_reduction)
	
	var final_damage = amount - damage_reduction
	health -= final_damage
	print("Reptile took ", final_damage, " damage! Health: ", health)
	
	# Enter hurt state
	current_state = State.HURT
	
	# Flash red
	modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.4) # Slower recovery flash
	
	# Check if dead
	if health <= 0:
		die()
		return
	
	# Apply short knockback effect when hurt
	velocity = -velocity.normalized() * knockback_force * 0.5
	move_and_slide()
	velocity = Vector2.ZERO
	
	# Longer recovery time for reptiles
	await get_tree().create_timer(0.5).timeout
	current_state = State.CHASE

func die():
	# Enter die state
	current_state = State.DIE
	
	# Play death animation if available
	if animated_sprite.sprite_frames.has_animation("Die"):
		animated_sprite.play("Die")
	else:
		# Just stop current animation
		animated_sprite.stop()
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Add death effect
	modulate = Color(1, 0.5, 0.5, 1)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 0), 1.5) # Slower fade out
	
	# Chance to drop an item (could be implemented later)
	# if randf() < 0.4:  # 40% chance to drop something
	#     _drop_item()
	
	# Remove after a delay
	await get_tree().create_timer(1.5).timeout
	queue_free()

# Optional: Add a special attack that reptiles could use occasionally
func _special_poison_attack():
	# This could be called randomly during chase or attack
	if player and randf() < 0.1 and global_position.distance_to(player.global_position) < attack_range * 1.5:
		# Visual effect
		modulate = Color(0.3, 1, 0.3) # Green glow
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.5)
		
		# Apply poison damage over time (this would need a poison system in the player)
		if player.has_method("apply_poison"):
			player.apply_poison(2, 5) # 2 damage for 5 seconds
