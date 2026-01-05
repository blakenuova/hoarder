extends CharacterBody3D

@export var max_health: int = 30 # Dies in 3 shots (if gun does 10 dmg)
var current_health: int
@onready var body: MeshInstance3D = $body

func _ready():
	current_health = max_health

# This is the function your Gun calls!
func take_damage(amount: int):
	current_health -= amount
	
	print("Enemy hit! Health: " + str(current_health))
	
	# Flash Red (Optional visual feedback)
	body.transparency = 0.5
	await get_tree().create_timer(0.1).timeout
	body.transparency = 0.0
	
	if current_health <= 0:
		die()

func die():
	print("Enemy Died!")
	# Optional: Play sound or particle effect here
	queue_free() # Delete the object
