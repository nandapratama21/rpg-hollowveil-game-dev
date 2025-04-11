extends Control

@onready var text_label = $RichTextLabel
@onready var timer = $Timer
@onready var type_sound = $TypeSound

var dialogue_text = ""
var current_char_index = 0
var is_typing = false
var dialogue_finished_signal = false

# Connect to this signal to know when dialogue is complete
signal dialogue_finished

# Speed at which text appears (seconds per character)
@export var typing_speed: float = 0.04


func _ready():
	# Initialize the RichTextLabel
	text_label.text = ""
	timer.wait_time = typing_speed
	timer.one_shot = false
	timer.connect("timeout", _on_timer_timeout)

	# Configure the typing sound to loop
	if type_sound:
		type_sound.stream = load(
			"res://assets/SoundEffect_elevenlabs/typing_dialog_sound_effect.mp3"
		)
		# Make sure the stream is set to loop
		var stream = type_sound.stream
		if stream is AudioStreamMP3:
			stream.loop = true
		type_sound.volume_db = -10  # Adjust volume to not be too loud


# Start displaying new dialogue
func start_dialogue(text: String):
	dialogue_text = text
	current_char_index = 0
	text_label.text = ""
	is_typing = true
	timer.start()

	# Start the typing sound when dialogue begins
	if type_sound and !type_sound.playing:
		type_sound.play()

	show()  # Make sure the dialogue box is visible


# Skip to end of current text if typing, or close dialogue if finished
func advance_dialogue():
	if is_typing:
		# If still typing, display all text immediately
		text_label.text = dialogue_text
		is_typing = false
		timer.stop()

		# Stop typing sound
		if type_sound and type_sound.playing:
			type_sound.stop()
	else:
		# If finished typing, close dialogue
		hide()  # Hide the dialogue box
		dialogue_finished.emit()


func _on_timer_timeout():
	if current_char_index < dialogue_text.length():
		# Add next character
		text_label.text += dialogue_text[current_char_index]
		current_char_index += 1

		# Make sure typing sound is playing
		if type_sound and !type_sound.playing:
			type_sound.play()
	else:
		# Finished typing
		is_typing = false
		timer.stop()

		# Stop typing sound when done typing
		if type_sound and type_sound.playing:
			type_sound.stop()
