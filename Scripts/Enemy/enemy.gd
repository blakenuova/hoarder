extends CharacterBody3D

@export var speed = 4.0

@onready var nav_agent = $NavigationAgent3D

func _ready():
	# 1. Wait for map to sync
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# 2. Find Player Group
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# Set target immediately to test path
		nav_agent.target_position = player.global_position
	else:
		print("CRITICAL ERROR: No node in 'Player' group found!")

func _physics_process(delta):
	# Continuously update target to player position
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		nav_agent.target_position = player.global_position

	if nav_agent.is_navigation_finished():
		return 

	var next_path_position = nav_agent.get_next_path_position()
	var current_agent_position = global_position
	
	# --- THE FIX STARTS HERE ---
	# 1. Calculate the raw difference
	var offset = next_path_position - current_agent_position
	
	# 2. FLATTEN IT: Force Y to 0 so we don't try to walk into the floor
	offset.y = 0 
	
	# 3. Normalize to get direction
	var new_velocity = offset.normalized() * speed
	# --- THE FIX ENDS HERE ---
	
	velocity = new_velocity
	
	# Gravity logic
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
		
	move_and_slide()
	
	# Look at player
	if player:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
