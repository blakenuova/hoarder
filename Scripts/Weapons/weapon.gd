extends Node3D
class_name Weapon

signal ammo_changed(new_amount) # Tell UI to update

@export_group("Stats")
@export var damage: int = 10
@export var max_ammo: int = 30
@export var fire_rate: float = 0.5

@onready var ray_cast = $RayCast

var current_ammo: int
var can_shoot = true

func _ready():
	current_ammo = max_ammo

func shoot():
	# 1. Check constraints
	if not can_shoot:
		return
	if current_ammo <= 0:
		print("Click... (Empty)")
		# Optional: Play empty sound
		return
	
	# 2. Fire Logic
	current_ammo -= 1
	ammo_changed.emit(current_ammo) # Shout to UI
	print("Bang! Ammo: " + str(current_ammo))
	
	can_shoot = false
	
	# Hit Detection
	if ray_cast.is_colliding():
		var target = ray_cast.get_collider()
		if target.has_method("take_damage"):
			target.take_damage(damage)
			
	# 3. Cooldown
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

func reload():
	print("Reloading...")
	can_shoot = false
	await get_tree().create_timer(1.5).timeout # 1.5 second reload time
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo)
	can_shoot = true
	print("Reload Complete!") 
