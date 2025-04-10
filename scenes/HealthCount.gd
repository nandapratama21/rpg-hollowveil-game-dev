extends Label

func _ready():
	# Find player and connect health signal
	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:
		if not player[0].is_connected("health_changed", update_health):
			player[0].connect("health_changed", update_health)
		
		# Initialize with current health if available
		if player[0].has_method("get_health"):
			update_health(player[0].get_health())
		elif "health" in player[0]:
			update_health(player[0].health)

func update_health(new_health):
	text = "Health: " + str(new_health)
