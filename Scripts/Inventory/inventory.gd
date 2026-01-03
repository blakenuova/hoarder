extends Node
class_name Inventory

# Define the signal
signal inventory_updated

# This array will hold all the ItemData resources we pick up
@export var items: Array[ItemData] = []

func add_item(item: ItemData):
	# Add the item to the list
	items.append(item)
	print("Inventory: Added " + item.name + ". Total items: " + str(items.size()))
	
	# Shout! Tell the UI to update. Shout: "Hey! The list changed! Here is the new list!"
	inventory_updated.emit(items)
