extends Node

# Signals
signal item_equipped(item)
signal item_unequipped(item)

# Currently equipped item
var equipped_item: InventoryItem = null

# The player's inventory resource
var player_inventory: Inventory

func _ready():
	# Get reference to player inventory
	player_inventory = preload("res://assets/player_inventory.tres")
	
	# Connect to inventory signals
	if player_inventory:
		player_inventory.update.connect(_on_inventory_updated)

func equip_item(item: InventoryItem):
	if item == null:
		if equipped_item:
			var old_item = equipped_item
			equipped_item = null
			item_unequipped.emit(old_item)
		return
		
	# Set as equipped item
	var previous_item = equipped_item
	equipped_item = item
	
	# Emit signals
	if previous_item:
		item_unequipped.emit(previous_item)
	item_equipped.emit(item)
	
	print("Equipped: ", item.item_name)
	return previous_item

func get_equipped_item():
	return equipped_item
	
func _on_inventory_updated():
	# If the equipped item has been removed from inventory, unequip it
	var found = false
	for slot in player_inventory.slots:
		if slot.item == equipped_item:
			found = true
			break
	
	if !found and equipped_item:
		equip_item(null)