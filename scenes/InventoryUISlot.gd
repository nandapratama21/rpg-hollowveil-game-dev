extends Panel

@onready var item_visual: Sprite2D = $CenterContainer/Panel/Item_Display
@onready var amount_text: Label = $CenterContainer/Panel/Label
@onready var equipped_indicator = $EquippedIndicator if has_node("EquippedIndicator") else null

func _ready():
	# Create equipped indicator if it doesn't exist
	if not equipped_indicator:
		equipped_indicator = ColorRect.new()
		equipped_indicator.name = "EquippedIndicator"
		equipped_indicator.color = Color(0, 1, 0, 0.3) # Green with transparency
		equipped_indicator.visible = false
		equipped_indicator.size = self.size
		equipped_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(equipped_indicator)

func update(slot: InventorySlot):
	if slot.item:
		item_visual.visible = true
		item_visual.texture = slot.item.item_texture
		if slot.amount > 1:
			amount_text.visible = true
		amount_text.text = str(slot.amount)
	else:
		item_visual.visible = false
		amount_text.visible = false

func set_equipped(is_equipped: bool):
	if equipped_indicator:
		equipped_indicator.visible = is_equipped
