extends Resource
class_name ItemData

# This is the information every item will share
@export var name: String = "Item"
@export_multiline var description: String = "Description"
@export var stackable: bool = false
@export var icon: Texture2D # The image we will show in the inventory grid
@export_file("*.tscn") var pickup_scene_path: String


# Base usage function. By default, items don't do anything.
# We pass the 'player' node so the item can modify health, etc.
func use(player: Node) -> bool:
	print("Used generic item: " + name)
	return false # Return false means "Don't consume this item" (it stays in inventory)
