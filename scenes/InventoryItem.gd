extends Resource

class_name InventoryItem

@export var item_name: String
@export var item_texture: Texture2D
@export var item_type: String = "general"  # weapon, consumable, etc.
@export var usable: bool = false
@export var damage: int = 0
