extends CharacterBody2D

@export var max_health = 30
@export var health = 30
@export var attack_damage = 5
@export var detect_radius = 100
@export var chase_speed = 50
@export var patrol_speed = 20
@export var knockback_force = 120
@export var prob_heal = 0.65
@export var heal_amountfixed = 0

@onready var animated_sprite = $AnimatedSprite2D

enum State { PATROL, CHASE, ATTACK, HURT, DIE }
var current_state = State.PATROL
var patrol_direction = Vector2.RIGHT
var player = null
var patrol_timer = 0
var patrol_point_duration = 2.0
var can_attack = true
var attack_cooldown = 1.5


func _ready():
	add_to_group("enemies")

	# Initialize animations
	if animated_sprite:
		animated_sprite.play("Walk Down")

	# Find player reference
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _physics_process(delta):
	if health <= 0:
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
	if current_state != State.ATTACK and current_state != State.HURT and current_state != State.DIE:
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
		patrol_direction = -patrol_direction  # Reverse direction

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

	# Move toward player
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
	if global_position.distance_to(player.global_position) < 25 and can_attack:
		current_state = State.ATTACK


func _handle_attack():
	# Play attack animation if available, otherwise use walk animation
	var current_anim = animated_sprite.animation
	if current_anim.begins_with("Walk"):
		var direction = current_anim.split(" ")[1]
		if animated_sprite.sprite_frames.has_animation("Attack " + direction):
			animated_sprite.play("Attack " + direction)

	# Stop movement
	velocity = Vector2.ZERO

	# Apply damage to player if in range
	if player and global_position.distance_to(player.global_position) < 25:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)

			# Apply knockback to player
			var knockback_dir = (player.global_position - global_position).normalized()
			player.apply_knockback(knockback_dir * knockback_force)

	# Attack cooldown
	can_attack = false

	# Wait for attack animation to complete
	await get_tree().create_timer(0.5).timeout

	# Return to chase state
	current_state = State.CHASE

	# Reset cooldown after delay
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func take_damage(amount):
	if current_state == State.DIE:
		return

	health -= amount
	print("Racoon took ", amount, " damage! Health: ", health)

	# Enter hurt state
	current_state = State.HURT

	# Flash red
	modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	# Check if dead
	if health <= 0:
		die()
		return

	# Apply short knockback effect when hurt
	velocity = -velocity.normalized() * knockback_force
	move_and_slide()
	velocity = Vector2.ZERO

	# Recover after short delay
	await get_tree().create_timer(0.3).timeout
	current_state = State.CHASE


func die():
	# Enter die state
	current_state = State.DIE

	# Play death animation if available
	if animated_sprite.sprite_frames.has_animation("Die"):
		animated_sprite.play("Die")

	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)

	# Add death effect
	modulate = Color(1, 0.5, 0.5, 1)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 0), 1.0)

	# Chance to heal the player
	if randf() <= prob_heal and player and player.has_method("heal"):
		# Heal the player
		var heal_amount = 0
		if heal_amountfixed > 0:
			heal_amount = heal_amountfixed
		else:
			# Random heal amount between 10 and 20
			heal_amount = randi_range(10, 20)
		player.heal(heal_amount)
		print("Racoon death healed player for: ", heal_amount)

	# Signal that the enemy died (useful for enemy spawner)
	if has_signal("enemy_died"):
		emit_signal("enemy_died")

	# Remove after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()
