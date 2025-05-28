extends Control

@onready var stamina_bar = $StaminaBar
@onready var stamina_label = $Label if has_node("Label") else null

func _ready():
	# Add to stamina_ui group for easier reference
	add_to_group("stamina_ui")
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		# Connect to player signals
		player.connect("stamina_changed", self._on_player_stamina_changed)
		# Initial update
		_on_player_stamina_changed(player.stamina, player.max_stamina)

func _on_player_stamina_changed(new_stamina, max_stamina):
	# Update stamina bar progress
	stamina_bar.max_value = max_stamina
	stamina_bar.value = new_stamina
	
	# Update label if present
	if stamina_label:
		stamina_label.text = "Stamina: " + str(int(new_stamina)) + " / " + str(int(max_stamina))
