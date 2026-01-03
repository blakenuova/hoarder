extends Resource
class_name ItemData

# This is the information every item will share
@export var name: String = "Item"
@export_multiline var description: String = "Description"
@export var stackable: bool = false
@export var icon: Texture2D # The image we will show in the inventory grid
@export_file("*.tscn") var pickup_scene_path: String
