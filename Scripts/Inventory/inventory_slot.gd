extends PanelContainer

@onready var icon_texture = $Icon

func set_item(item: ItemData):
	if item and item.icon:
		icon_texture.texture = item.icon
		tooltip_text = item.name # Hover text shows item name
	else:
		icon_texture.texture = null
