extends StaticBody2D

@export var required_item_type = "weapon"

func _ready():
	add_to_group("bushes")
	collision_layer = 4  # Set to layer 3 (bit 2)

func destroy():
	# Get player
	var player = get_tree().get_nodes_in_group("player")[0]
	
	# Make sure player has a weapon equipped
	if !player.equipped_item or player.equipped_item.item_type != required_item_type:
		print("Player doesn't have the right tool to destroy this bush!")
		return
	
	# Play destroy effect
	modulate = Color(1, 0.5, 0.5, 1)
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Fade out and destroy
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5, 0), 0.5)
	await tween.finished
	
	# Notify the level
	var level = get_tree().get_nodes_in_group("level")[0]
	if level.has_method("_on_bush_cleared"):
		level.call("_on_bush_cleared", global_position)
	
	# Remove bush
	queue_free()
