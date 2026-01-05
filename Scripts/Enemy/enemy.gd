extends CharacterBody3D

@export var max_health: int = 30 # Dies in 3 shots (if gun does 10 dmg)
@export var speed: float = 3.0
@export var damage_to_player: int = 10
var current_health: int

@onready var body: MeshInstance3D = $body
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# We need to find the player. We'll do this in _ready.
var player = null

func _ready():
	current_health = max_health
	
	# Simple way to find the player: 
	# (Make sure your Player node is in the main scene tree!)
	# Ideally, put your Player in a Group called "Player" to make this safer.
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("Enemy Warning: No Player found!")

func _physics_process(delta):
	if player:
		# 1. Tell the agent where we want to go (Player's position)
		nav_agent.target_position = player.global_position
		
		# 2. Get the next point on the path
		var next_path_position = nav_agent.get_next_path_position()
		
		# 3. Calculate direction towards that point
		var current_agent_position = global_position
		var new_velocity = (next_path_position - current_agent_position).normalized() * speed
		
		# 4. Move
		velocity = new_velocity
		move_and_slide()
		
		# 5. Rotate to face player (Optional)
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))



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
