extends "res://scenes/Racoon.gd"


signal king_racoon_died

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
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 0), 1.5)
	
	# Emit signal for level to show credits
	emit_signal("king_racoon_died")
	
	# Remove after a longer delay for boss (more dramatic)
	await get_tree().create_timer(2.0).timeout
	queue_free()


func _on_king_racoon_died():
	pass # Replace with function body.
