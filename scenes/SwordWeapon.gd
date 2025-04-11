extends StaticBody2D

@export var item: InventoryItem
var player = null


func _ready():
	# Make sure the sword item is loaded
	if not item:
		# Try to load the item resource if not assigned in the editor
		item = load("res://assets/Sword.tres")

	# Ensure item_type is set to "weapon" for proper handling
	if item and item.item_type != "weapon":
		item.item_type = "weapon"
		push_warning("Fixed Sword item_type to 'weapon'")

	# Add a slight hovering animation
	var tween = create_tween()
	tween.set_loops()  # Make it repeat forever
	tween.tween_property($Sprite2D, "position:y", -2.0, 1.0)
	tween.tween_property($Sprite2D, "position:y", 2.0, 1.0)


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player = body

		# Call sword collection method on level if it exists
		var level = get_tree().get_nodes_in_group("level")[0]
		if level and level.has_method("_on_sword_collected"):
			level._on_sword_collected()

		# Give the sword to the player
		player.collect(item)

		# Optional: Show a pickup effect
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)

		# Remove the sword object after a short delay
		await get_tree().create_timer(0.2).timeout
		queue_free()
