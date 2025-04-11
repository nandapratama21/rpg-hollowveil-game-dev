extends Area2D

@export var max_health_bonus = 100  # How much to increase max health
@export var heal_amount = 200  # Set to full health (200)
@export var show_pickup_effect = true


func _ready():
	# Connect the area entered signal
	connect("body_entered", _on_body_entered)

	# Add a slight hovering animation
	var tween = create_tween()
	tween.set_loops()  # Make it repeat forever
	tween.tween_property($Sprite2D, "position:y", -2.0, 1.0)
	tween.tween_property($Sprite2D, "position:y", 2.0, 1.0)


func _on_body_entered(body):
	if body.is_in_group("player"):
		# Increase max health and heal player
		if body.has_method("increase_max_health"):
			body.increase_max_health(max_health_bonus)
		else:
			# Fallback if no dedicated method exists
			body.max_health = 200

		# Restore health to full
		if body.has_method("heal"):
			body.heal(heal_amount)  # This will cap at max_health
		else:
			body.health = body.max_health

			# Emit health changed signal if it exists
			if body.has_signal("health_changed"):
				body.emit_signal("health_changed", body.health)

		# Show pickup effect
		if show_pickup_effect:
			var effect_tween = create_tween()
			effect_tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
			effect_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)

			# Optional: Play a sound
			# if $AudioStreamPlayer:
			#     $AudioStreamPlayer.play()

			# Wait for effect to finish then remove
			await effect_tween.finished

		# Remove the power-up
		queue_free()
