extends CharacterBody3D

# --- STATS ---
@export var speed = 4.0
@export var max_health: int = 30
@export var damage_to_player: int = 50
@export var attack_range: float = 2.0
@export var attack_rate: float = 1.0 # Time between attacks

var current_health: int
var can_attack = true # Cooldown flag
var attack_cooldown: float = 0.0 # Variable to track time
var player = null

@onready var nav_agent = $NavigationAgent3D
@onready var mesh = $body # Make sure your mesh is named this!

func _ready():
	current_health = max_health
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("CRITICAL ERROR: No node in 'Player' group found!")

func _physics_process(delta):
	if not player:
		return
		
	
	# --- 1. HANDLE COOLDOWN ---
	# Count down the timer every frame
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# --- 3. MOVEMENT ---
	nav_agent.target_position = player.global_position
	
	if not nav_agent.is_navigation_finished():
		var next_path_position = nav_agent.get_next_path_position()
		var current_agent_position = global_position
		
		var offset = next_path_position - current_agent_position
		offset.y = 0
		var direction = offset.normalized()
		
		velocity.x = lerp(velocity.x, direction.x * speed, 0.1)
		velocity.z = lerp(velocity.z, direction.z * speed, 0.1)
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	# Look at player
	var target_look = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(target_look)
	
	# --- 3. ATTACK LOGIC ---
	var dist = global_position.distance_to(player.global_position)
	
	# Only attack if close enough AND cooldown is finished ( <= 0 )
	if dist <= attack_range and attack_cooldown <= 0.0:
		attack_player()

# --- CUSTOM FUNCTIONS ---

func attack_player():
	print("Enemy Attacked Player!")
	if player.has_method("take_damage"):
		player.take_damage(damage_to_player)
	
	# RESET COOLDOWN
	# Set the timer to 1.0 (or whatever attack_rate is). 
	# It will count down in _physics_process.
	attack_cooldown = attack_rate

func take_damage(amount: int):
	current_health -= amount
	
	# Visual Flash
	if mesh:
		mesh.transparency = 0.5
		# It's okay to use create_timer here because if we die during this, 
		# the visual doesn't matter as much as game logic.
		# But to be 100% crash-proof, checking inside_tree is good:
		if is_inside_tree():
			await get_tree().create_timer(0.1).timeout
			if mesh: mesh.transparency = 0.0
	
	if current_health <= 0:
		die()

func die():
	print("Enemy Died!")
	queue_free()
