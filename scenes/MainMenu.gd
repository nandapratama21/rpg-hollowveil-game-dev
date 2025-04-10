extends Control

func _ready():	
	# Hide the how to play panel initially
	$HowToPlayPanel.visible = false


func _on_new_game_button_pressed():
	# Create transition effect
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.anchors_preset = Control.PRESET_FULL_RECT
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	
	# Start the game
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")

func _on_how_to_play_button_pressed():
	# Show the How To Play panel
	$HowToPlayPanel.visible = true
	
	# Add a quick fade-in effect
	$HowToPlayPanel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property($HowToPlayPanel, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_close_button_pressed():
	# Hide the How To Play panel with a fade-out effect
	var tween = create_tween()
	tween.tween_property($HowToPlayPanel, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	$HowToPlayPanel.visible = false

func _on_quit_button_pressed():
	# Fade out before quitting
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.anchors_preset = Control.PRESET_FULL_RECT
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	
	# Quit the game
	get_tree().quit()

# Optional: Handle ESC key to close How To Play panel
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if $HowToPlayPanel.visible:
			_on_close_button_pressed()