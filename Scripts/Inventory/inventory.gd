extends Node
class_name Inventory

# This array will hold all the ItemData resources we pick up
@export var items: Array[ItemData] = []

func add_item(item: ItemData):
	# Add the item to the list
	items.append(item)
	print("Inventory: Added " + item.name + ". Total items: " + str(items.size()))
	
	# TODO: Later, we will tell the UI to update here
