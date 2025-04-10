extends Control

var scroll_speed = 50  # Adjust this to control scroll speed
var can_skip = false
var credits_finished = false

func _ready():
	# Start the scrolling animation after a short delay
	await get_tree().create_timer(1.0).timeout
	can_skip = true
	
	# Start the automatic scrolling
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# Calculate how far to scroll (total height of content)
	var scroll_container = $ScrollContainer
	var content_height = $ScrollContainer/VBoxContainer.get_combined_minimum_size().y
	var scroll_amount = content_height - scroll_container.size.y
	
	# Scroll over time (speed depends on content length)
	var scroll_time = content_height / scroll_speed
	tween.tween_property(scroll_container, "scroll_vertical", scroll_amount, scroll_time)
	
	# When scrolling finishes
	await tween.finished
	credits_finished = true

func _input(event):
	# Allow skipping with any key after a short delay
	if can_skip and (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_on_main_menu_button_pressed()

func _on_main_menu_button_pressed():
	# Transition back to main menu
	var transition = ColorRect.new()
	transition.color = Color(0, 0, 0, 0)
	transition.anchors_preset = Control.PRESET_FULL_RECT
	add_child(transition)
	
	var tween = create_tween()
	tween.tween_property(transition, "color", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	
	# Return to the main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
