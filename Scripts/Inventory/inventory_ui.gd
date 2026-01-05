extends Control


#Signals
signal drop_item(index) # Signal to tell Player to drop something
signal use_item(index)


var slot_scene = preload("res://Scenes/UI/InventorySlot.tscn")
@onready var grid = $Panel/Grid




func update_grid(items: Array[ItemData]):
	# Clear existing
	for child in grid.get_children():
		child.queue_free()
	
	# Create slots
	for i in items.size():
		var item = items[i]
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.set_item(item)
		
		# CONNECT THE SIGNAL
		# When slot is clicked -> call 'on_slot_clicked' inside THIS script
		slot.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(index: int, button: int):
	if button == MOUSE_BUTTON_RIGHT:
		# Trigger the drop
		drop_item.emit(index)
	elif button == MOUSE_BUTTON_LEFT:
		use_item.emit(index)
