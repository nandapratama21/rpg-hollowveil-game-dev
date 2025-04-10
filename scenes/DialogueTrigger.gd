extends Area2D

@export var dialogue_lines: Array[String] = []
@export var trigger_once: bool = true
@export var check_condition: String = "" # Name of a method to call on the level to check condition

var has_triggered: bool = false

signal dialogue_triggered(trigger, lines)

func _ready():
	# Connect the body_entered signal
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	# Check if the body is the player and we haven't triggered yet (or can trigger multiple times)
	if body.is_in_group("player") and (!has_triggered or !trigger_once):
		has_triggered = true
		print(name + " triggered")
		
		# Find the level
		var level_nodes = get_tree().get_nodes_in_group("level")
		if level_nodes.size() > 0:
			var level = level_nodes[0]
			
			# Check if there's a condition method to call
			var lines_to_use = dialogue_lines
			if check_condition != "":
				print("Checking condition: " + check_condition)
				if level.has_method(check_condition):
					var condition_met = level.call(check_condition)
					print("Condition result: ", condition_met)
					if condition_met and level.has_method("get_alternative_dialogue"):
						var alt_lines = level.get_alternative_dialogue(name)
						print("Alt lines: ", alt_lines)
						if alt_lines != null and alt_lines.size() > 0:
							lines_to_use = alt_lines
							print("Using alternative dialogue")
			
			# Emit signal for the level to handle
			dialogue_triggered.emit(self, lines_to_use)
			
			# The level should connect to this signal and handle the dialogue
			# But as a fallback, try to directly call methods on the level if they exist
			if level.has_method("on_dialogue_trigger_activated"):
				level.on_dialogue_trigger_activated(self, lines_to_use)
			elif level.has_method("queue_dialogue") and level.has_method("show_next_dialogue"):
				# Queue all dialogue lines
				for line in lines_to_use:
					level.queue_dialogue(line)
				
				# Start the dialogue
				level.show_next_dialogue()
