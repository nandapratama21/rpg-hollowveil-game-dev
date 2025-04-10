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
	
	# Schedule wake up sequence
	await get_tree().create_timer(intro_delay).timeout
	_wake_up_sequence()

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
		
	]
	
	# Show first dialogue
	show_next_dialogue()
	intro_sequence_complete = true

func _input(event):
	# Only process input after intro sequence is complete
	if !intro_sequence_complete:
		return
	
	# If dialogue is active, ONLY accept dialogue advancement input and block everything else
	if dialogue_instance and dialogue_instance.visible:
		if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
			# For keyboard input, only allow specific keys to advance dialogue
			if event is InputEventKey:
				# Only allow space, enter, and escape to advance dialogue
				if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
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
