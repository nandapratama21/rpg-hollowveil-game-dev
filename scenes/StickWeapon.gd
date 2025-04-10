extends StaticBody2D

@export var item: InventoryItem
var player = null

func _ready():
	# Add a slight hovering animation
	var tween = create_tween()
	tween.set_loops()  # Make it repeat forever
	tween.tween_property($Sprite2D, "position:y", -2.0, 1.0)
	tween.tween_property($Sprite2D, "position:y", 2.0, 1.0)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player = body
		
		# Call stick collection method on level
		var level = get_tree().get_nodes_in_group("level")[0]
		if level and level.has_method("_on_stick_collected"):
			level._on_stick_collected()
		
		# Give the stick to the player
		player.collect(item)
		await get_tree().create_timer(0.1).timeout
		self.queue_free()
