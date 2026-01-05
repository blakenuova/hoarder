extends Node3D
class_name Weapon

@export var damage: int = 10
@export var fire_rate: float = 0.5 # Seconds between shots

@onready var ray_cast: RayCast3D = $RayCast3D


var can_shoot = true

func shoot():
	if not can_shoot:
		return
	
	print("Bang!")
	
	# Cooldown Logic
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
	
	# Hit Detection
	if ray_cast.is_colliding():
		var target = ray_cast.get_collider()
		print("Hit: " + target.name)
		
		# TODO: Later we will call target.take_damage(damage)
		if target.has_method("take_damage"):
			target.take_damage(damage)
