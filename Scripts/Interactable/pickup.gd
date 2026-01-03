extends Interactable
class_name Pickup

# Drag the "Flashlight.tres" resource here in the Inspector
@export var item_data: ItemData

func _ready():
	# Auto-set the prompt message so it says "Pick up Flashlight"
	if item_data:
		prompt_message = "Pick up " + item_data.name

func interact(player):
	if item_data:
		# Call the new function on the player
		if player.has_method("collect_item"):
			print("Picked up: " + item_data.name)
			player.collect_item(item_data)
			queue_free() # Delete the physical object)
