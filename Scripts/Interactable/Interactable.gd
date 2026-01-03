extends CollisionObject3D
class_name Interactable

# The text to show on UI when looking at this (e.g. "Open Door", "Pick up Ammo")
@export var prompt_message = "Interact"

# This function is called by the Player. 
# We can overwrite this function in other scripts for specific items.
func interact(player):
	print("Interacted with " + name)
