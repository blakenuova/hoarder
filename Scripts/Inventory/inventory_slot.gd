extends PanelContainer

signal slot_clicked(index: int, button: int) # New Signal

@onready var icon_texture = $Icon

func set_item(item: ItemData):
	# (Your existing code here)
	if item and item.icon:
		icon_texture.texture = item.icon
		tooltip_text = item.name
	else:
		icon_texture.texture = null
		tooltip_text = ""

# Built-in Godot function to detect clicks on UI Controls
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# MOUSE_BUTTON_LEFT = 1, MOUSE_BUTTON_RIGHT = 2
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			# Tell the parent (InventoryUI) which slot was clicked
			slot_clicked.emit(get_index(), event.button_index)
