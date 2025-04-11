extends Resource

class_name InventorySlot

@export var item: InventoryItem
@export var amount: int


func set_equipped(is_equipped: bool):
	if is_equipped:
		# Add a visual indicator (like a border or overlay)
		self.modulate = Color(1.2, 1.2, 0.8)  # Gold tint
	else:
		# Remove the visual indicator
		self.modulate = Color(1, 1, 1)  # Normal color
