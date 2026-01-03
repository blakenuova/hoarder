extends CharacterBody3D

# Settings
@export var walk_speed = 5.0
@export var run_speed = 8.0
@export var crouch_speed = 2.5
@export var prone_speed = 1.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.003

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Node references
@onready var head = $Head
@onready var camera = $Head/Camera3D


# Flashlight
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight



#-------------------------------------------------------------------------------

func _ready():
	# Lock mouse for FPS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Camera Look Logic
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	# Menu/Unlock Mouse
	if event.is_action_pressed("menu"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	_flashlight()
	
	
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Determine Current Speed (State Management)
	var current_speed = walk_speed
	if Input.is_action_pressed("run") and not Input.is_action_pressed("aim"):
		current_speed = run_speed
	elif Input.is_action_pressed("crouch"):
		current_speed = crouch_speed
		# Add logic here to shrink CollisionShape height
	elif Input.is_action_pressed("prone"):
		current_speed = prone_speed
		# Add logic here to shrink CollisionShape height further

	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()


#-------------------------------------------------------------------------------
#                        CUSTOM FUNCTIONS 
#-------------------------------------------------------------------------------

func _flashlight():
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible
