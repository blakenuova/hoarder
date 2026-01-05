extends Node3D

# Signal to tell the world we won
signal player_extracted

@onready var area = $Area3D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("PLAYER REACHED EXTRACTION!")
		
		# Access the player's UI directly
		if body.has_node("CanvasLayer/GameOverScreen"):
			var screen = body.get_node("CanvasLayer/GameOverScreen")
			screen.set_title("MISSION COMPLETE", Color.GREEN)
