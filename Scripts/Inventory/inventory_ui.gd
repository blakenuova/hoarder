extends Control

# Load the slot template so we can copy it
var slot_scene = preload("res://Scenes/UI/InventorySlot.tscn")

@onready var grid = $Panel/Grid

func update_grid(items: Array[ItemData]):
	# 1. Clear existing slots (start fresh)
	for child in grid.get_children():
		child.queue_free()
	
	# 2. Loop through the items and create a slot for each
	for item in items:
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.set_item(item)
