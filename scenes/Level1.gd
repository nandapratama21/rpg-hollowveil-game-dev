extends Node2D

@onready var player = $CharacterBody2D
@onready var player_sprite = $CharacterBody2D/AnimatedSprite2D
@export var intro_delay = 2.0

var dialogue_scene = preload("res://scenes/Dialogue.tscn")
var dialogue_instance
var player_can_move = false
var canvas_layer
var waiting_for_input = false
var dialogue_queue = []
var intro_sequence_complete = false
var has_stick = false # Variable to track if player has stick
var game_paused = false # Track if game is paused
var pause_menu # Reference to the pause menu

func _ready():
	# Add this level to the "level" group so triggers can find it
	add_to_group("level")
	
	# Disable player movement initially
	player.set_physics_process(false)
	
	# Create a CanvasLayer for UI elements
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10  # Make sure it's above other elements
	add_child(canvas_layer)
	
	# Add player to "player" group for area triggers
	player.add_to_group("player")
	
	# Start with sleep animation
	player_sprite.play("Sleep_Die")

	# Create pause menu
	_create_pause_menu()
	
	# Schedule wake up sequence
	await get_tree().create_timer(intro_delay).timeout
	_wake_up_sequence()

func _create_pause_menu():
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.anchors_preset = Control.PRESET_FULL_RECT
	pause_menu.visible = false
	canvas_layer.add_child(pause_menu)

	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Semi-transparent background
	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0, 0, 0, 0.5)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	pause_menu.add_child(bg)
	
	# Pause Menu Container
	var container = CenterContainer.new()
	container.anchors_preset = Control.PRESET_FULL_RECT
	pause_menu.add_child(container)
	
	# Pause Menu Panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 300)
	
	# Create panel style to match MainMenu
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.196, 0.196, 0.275, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.91, 0.867, 0.718, 0.35)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.shadow_color = Color(0, 0, 0, 0.31)
	panel_style.shadow_size = 5
	panel.add_theme_stylebox_override("panel", panel_style)
	
	container.add_child(panel)
	
	# Create VBox for title and buttons
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# Add some margins
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	
	# Title
	var title = Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.91, 0.867, 0.718))
	vbox.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Buttons container
	var buttons_container = VBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons_container)
	
	# Button style
	var button_normal_style = StyleBoxFlat.new()
	button_normal_style.bg_color = Color(0.196, 0.196, 0.275, 0.7)
	button_normal_style.border_width_left = 2
	button_normal_style.border_width_top = 2
	button_normal_style.border_width_right = 2
	button_normal_style.border_width_bottom = 2
	button_normal_style.border_color = Color(0.91, 0.867, 0.718, 0.35)
	button_normal_style.corner_radius_top_left = 5
	button_normal_style.corner_radius_top_right = 5
	button_normal_style.corner_radius_bottom_right = 5
	button_normal_style.corner_radius_bottom_left = 5
	
	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = Color(0.196, 0.196, 0.275, 0.9)
	button_hover_style.border_width_left = 2
	button_hover_style.border_width_top = 2
	button_hover_style.border_width_right = 2
	button_hover_style.border_width_bottom = 2
	button_hover_style.border_color = Color(0.91, 0.867, 0.718, 0.35)
	button_hover_style.corner_radius_top_left = 8
	button_hover_style.corner_radius_top_right = 8
	button_hover_style.corner_radius_bottom_right = 8
	button_hover_style.corner_radius_bottom_left = 8
	
	# Resume button
	var resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.add_theme_font_size_override("font_size", 24)
	resume_button.add_theme_color_override("font_color", Color(0.91, 0.867, 0.718))
	resume_button.add_theme_color_override("font_hover_color", Color(1, 0.957, 0.843))
	resume_button.add_theme_stylebox_override("normal", button_normal_style)
	resume_button.add_theme_stylebox_override("hover", button_hover_style)
	resume_button.add_theme_stylebox_override("focus", button_hover_style)
	resume_button.pressed.connect(_on_resume_button_pressed)
	buttons_container.add_child(resume_button)
	
	# Main Menu button
	var menu_button = Button.new()
	menu_button.text = "Main Menu"
	menu_button.add_theme_font_size_override("font_size", 24)
	menu_button.add_theme_color_override("font_color", Color(0.91, 0.867, 0.718))
	menu_button.add_theme_color_override("font_hover_color", Color(1, 0.957, 0.843))
	menu_button.add_theme_stylebox_override("normal", button_normal_style)
	menu_button.add_theme_stylebox_override("hover", button_hover_style)
	menu_button.add_theme_stylebox_override("focus", button_hover_style)
	menu_button.pressed.connect(_on_main_menu_button_pressed)
	buttons_container.add_child(menu_button)
	
	# Quit button
	var quit_button = Button.new()
	quit_button.text = "Quit Game"
	quit_button.add_theme_font_size_override("font_size", 24)
	quit_button.add_theme_color_override("font_color", Color(0.91, 0.867, 0.718))
	quit_button.add_theme_color_override("font_hover_color", Color(1, 0.957, 0.843))
	quit_button.add_theme_stylebox_override("normal", button_normal_style)
	quit_button.add_theme_stylebox_override("hover", button_hover_style)
	quit_button.add_theme_stylebox_override("focus", button_hover_style)
	quit_button.pressed.connect(_on_quit_button_pressed)
	buttons_container.add_child(quit_button)

	# Make sure all the buttons have process_mode set to PROCESS_MODE_WHEN_PAUSED
	resume_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	menu_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED 
	quit_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func toggle_pause():
	# Toggle the paused state
	game_paused = !game_paused
	
	if game_paused:
		# Show the menu first
		pause_menu.visible = true
		pause_menu.modulate = Color(1, 1, 1, 0)
		
		# Create a nice fade-in effect
		var tween = create_tween()
		# Make sure the tween works during pause
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(pause_menu, "modulate", Color(1, 1, 1, 1), 0.3)
		
		# Pause the game AFTER showing the menu
		await get_tree().create_timer(0.1).timeout
		get_tree().paused = true
	else:
		# Unpause the game
		get_tree().paused = false
		
		# Create a fade-out effect and then hide
		var tween = create_tween()
		tween.tween_property(pause_menu, "modulate", Color(1, 1, 1, 0), 0.3)
		await tween.finished
		pause_menu.visible = false

func _on_resume_button_pressed():
	toggle_pause()

func _on_main_menu_button_pressed():
	# Fade out before going to main menu

	get_tree().paused = false

	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.anchors_preset = Control.PRESET_FULL_RECT
	canvas_layer.add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	
	# Unpause and go to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_quit_button_pressed():
	# Fade out before quitting
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.anchors_preset = Control.PRESET_FULL_RECT
	canvas_layer.add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	
	# Quit the game
	get_tree().quit()

# Called when the player picks up the stick
func _on_stick_collected():
	has_stick = true
	print("Stick collected!")
	

func _wake_up_sequence():
	# Play wake up animation
	player_sprite.play("Wake Up")
	
	# Wait for animation to finish
	await player_sprite.animation_finished
	
	# Queue all dialogues 
	dialogue_queue = [
		"Aren: Where... am I? This forest... I don't recognize it at all. How did I end up here?",
		"Aren: Last thing I remember... there was a storm. A shipwreck?",
		"Aren: The waves must've dragged me ashore. But where *is* this place?",
		"Aren: It's quiet... too quiet.",
		"Aren: No signs of anyone. No roads, no buildings... just trees and the sound of the ocean.",
		"Aren: I need to find a way out of here. Maybe I can find someone who can help me.",
		"Aren: I should start by exploring the area. Maybe there's a path or something.",
		"Aren: Maybe someone nearby can tell me where I am… or at least how to get back."
	]
	
	# Show first dialogue
	show_next_dialogue()
	intro_sequence_complete = true

func _input(event):
	# Only process input after intro sequence is complete
	if !intro_sequence_complete:
		return

	# Check for ESC key to toggle pause menu
	if event.is_action_pressed("ui_cancel"):  # ESC key
		# Only allow pausing if not in dialogue
		if !dialogue_instance or !dialogue_instance.visible:
			toggle_pause()
			get_viewport().set_input_as_handled()
			return
	
	# If dialogue is active, ONLY accept dialogue advancement input and block everything else
	if dialogue_instance and dialogue_instance.visible:
		if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
			# For keyboard input, only allow specific keys to advance dialogue
			if event is InputEventKey:
				# Only allow space, enter, and escape to advance dialogue
				if event.keycode in [KEY_SPACE, KEY_ENTER]:
					_handle_dialogue_advancement()
			else:
				# Mouse buttons can advance dialogue
				_handle_dialogue_advancement()
		
		# Block ALL other inputs while dialogue is active
		get_viewport().set_input_as_handled()
		return
	
	# Handle other inputs only if no dialogue is active
	if waiting_for_input:
		return

# Add a method to queue dialogue from external sources like triggers
func queue_dialogue(text: String):
	dialogue_queue.append(text)

func show_next_dialogue():
	if dialogue_queue.size() > 0:
		var next_text = dialogue_queue.pop_front()
		show_dialogue(next_text)
		waiting_for_input = true
		
		# Pause player movement during dialogue
		player.set_physics_process(false)
		player_can_move = false
		
		# Set player to idle animation based on current direction
		var current_anim = player_sprite.animation
		var facing_direction = "Down"
		
		if current_anim.begins_with("Walk") or current_anim.begins_with("Idle"):
			facing_direction = current_anim.split(" ")[1]
		
		player_sprite.play("Idle " + facing_direction)

func show_dialogue(text):
	# Create dialogue instance if needed
	if !dialogue_instance:
		dialogue_instance = dialogue_scene.instantiate()
		# Add to canvas layer instead of directly to the node
		canvas_layer.add_child(dialogue_instance)
		# Connect to the dialogue_finished signal
		dialogue_instance.dialogue_finished.connect(_on_dialogue_finished)
	
	# Start the dialogue
	dialogue_instance.start_dialogue(text)

func _on_dialogue_finished():
	# This function gets called when a dialogue is finished
	if dialogue_queue.size() > 0:
		show_next_dialogue()
	else:
		# All dialogues completed, enable player movement
		player.set_physics_process(true)
		player_can_move = true
		waiting_for_input = false


# Helper function to handle dialogue advancement
func _handle_dialogue_advancement():
	if dialogue_instance.is_typing:
		dialogue_instance.advance_dialogue()
	else:
		# If dialogue is done typing, close it and show next
		dialogue_instance.hide()
		# Process next dialogue or enable player movement
		if dialogue_queue.size() > 0:
			show_next_dialogue()
		else:
			# All dialogues completed, enable player movement
			player.set_physics_process(true)
			player_can_move = true
			waiting_for_input = false


# Called when a dialogue trigger is activated
func on_dialogue_trigger_activated(trigger, lines):
	# Disable player movement during dialogue
	player_can_move = false
	player.set_physics_process(false)
	
	# Set player to idle animation based on current direction
	var current_anim = player_sprite.animation
	var facing_direction = "Down"
	
	if current_anim.begins_with("Walk") or current_anim.begins_with("Idle"):
		facing_direction = current_anim.split(" ")[1]
	
	player_sprite.play("Idle " + facing_direction)
	
	# Queue all dialogue lines
	for line in lines:
		queue_dialogue(line)
	
	# Start the dialogue
	show_next_dialogue()

# Check if player has stick
func has_stick_check():
	return has_stick

# Get alternative dialogue for a trigger
func get_alternative_dialogue(trigger_name):
	print("Getting alternative dialogue for: ", trigger_name)
	if trigger_name == "DialogueTriggerBushBlocked" and has_stick:
		print("Using alternative bush dialogue")
		var alt_dialogue = []
		alt_dialogue.append("Now that I have a stick, I can clear the way ahead. Let me push these bushes aside.")
		return alt_dialogue
	print("No alternative dialogue found")
	return null

func _on_bush_cleared(position):
	print("Bush cleared at: ", position)
	
	# If this is a specific path-blocking bush, open the path
	if position.distance_to(Vector2(248, 24)) < 20:
		print("Path is now clear!")
		
		# You could add a dialogue here
		dialogue_queue = ["I've cleared the path! Now I can continue."]
		show_next_dialogue()

func _on_player_died():
	# Disable player movement
	player_can_move = false
	
	# Show game over message
	dialogue_queue = ["Game Over. You have died."]
	show_next_dialogue()
	
	# Add ability to restart 
	await get_tree().create_timer(2.0).timeout
	
	get_tree().reload_current_scene()

func _on_king_racoon_died():
	# Disable player movement
	player_can_move = false
	player.set_physics_process(false)
	
	# Show victory dialogue
	dialogue_queue = [
		"Aren: I did it! I defeated the King Racoon!"
	]
	show_next_dialogue()
	
	# Wait for dialogue to finish (using a signal connection)
	await get_tree().create_timer(2.0).timeout
	
	# Transition to credits
	_show_credits()

func _show_credits():
	# Create a fade transition
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.anchors_preset = Control.PRESET_FULL_RECT
	canvas_layer.add_child(transition)
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(transition, "color", Color(0, 0, 0, 1), 2.0)
	await tween.finished
	
	# Change to credits scene
	get_tree().change_scene_to_file("res://scenes/Credits.tscn")
