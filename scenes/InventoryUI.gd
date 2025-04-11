extends Control

@onready var inventory: Inventory = preload("res://assets/player_inventory.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()

var is_open = false
var equipped_slot_index = -1  # Track which slot has equipped item
var current_weapon_index = -1


func _ready():
	inventory.update.connect(update_slots)

	# Connect slot input events
	for i in range(slots.size()):
		slots[i].gui_input.connect(_on_slot_gui_input.bind(i))

	update_slots()
	close()


func update_slots():
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].update(inventory.slots[i])

		# Update visual indication of equipped item
		if equipped_slot_index == i:
			slots[i].set_equipped(true)
		else:
			slots[i].set_equipped(false)


func _physics_process(delta):
	if Input.is_action_just_pressed("ui_inventory"):
		if is_open:
			close()
		else:
			open()


func open():
	visible = true
	is_open = true


func close():
	visible = false
	is_open = false


# Handle clicks on inventory slots
func _on_slot_gui_input(event, slot_index):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var slot = inventory.slots[slot_index]

		if slot.item and slot.item.item_type == "weapon":
			# Find the player
			var player = (
				get_tree().get_nodes_in_group("player")[0]
				if get_tree().get_nodes_in_group("player").size() > 0
				else null
			)
			if !player:
				return

			# Toggle equipped state
			if equipped_slot_index == slot_index:
				# Unequip
				equipped_slot_index = -1

				# Notify player
				if player.has_method("unequip_item"):
					player.unequip_item()
			else:
				# Unequip previous item if any
				if equipped_slot_index != -1:
					# Reset visual state of previous equipped slot
					slots[equipped_slot_index].set_equipped(false)

				# Set new equipped slot
				equipped_slot_index = slot_index

				# Notify player
				if player.has_method("equip_item"):
					print("Equipping from UI: ", slot.item.item_name)  # Debug output
					player.equip_item(slot.item)

			# Update UI to show equipped status
			update_slots()
