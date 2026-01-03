extends CharacterBody3D
class_name Player

# --- CONFIGURATION ---
@export_group("Speeds")
@export var walk_speed = 5.0
@export var run_speed = 8.0
@export var crouch_speed = 2.5
@export var prone_speed = 1.0

@export_group("Movement")
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.003
@export var lerp_speed = 10.0 # How fast the camera moves between stances

# Head Heights (Adjust these Y values to match where the camera should be)
const HEAD_Y_STAND = 0.5
const HEAD_Y_CROUCH = 0.0
const HEAD_Y_PRONE = -0.5

# State Management
enum State { STAND, CROUCH, PRONE }
var current_state = State.STAND
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- NODES ---
@onready var head = $Head
@onready var standing_shape = $StandingCollisionShape
@onready var crouching_shape = $CrouchingCollisionShape
@onready var prone_shape = $ProneCollisionShape
@onready var stand_ray: RayCast3D = $StandRay
@onready var crouch_ray: RayCast3D = $CrouchRay


# Flashlight
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight



#-------------------------------------------------------------------------------

func _ready():
	# Lock mouse for FPS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Initialize shapes: Ensure only standing is active at start
	update_collision_shapes(State.STAND)

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
	
	
	# 1. Handle Stance (Crouch/Prone)
	handle_stance()

	# 2. Add Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 3. Jump (Only allow jumping if Standing)
	if Input.is_action_just_pressed("jump") and is_on_floor() and current_state == State.STAND:
		velocity.y = jump_velocity

	# 4. Movement Calculation
	var current_speed = get_current_speed()
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
	# 5. Smooth Camera Height Adjustment
	var target_height = HEAD_Y_STAND
	if current_state == State.CROUCH:
		target_height = HEAD_Y_CROUCH
	elif current_state == State.PRONE:
		target_height = HEAD_Y_PRONE
	
	# Lerp (Linear Interpolate) head position for smooth transition
	head.position.y = lerp(head.position.y, target_height, delta * lerp_speed)


#-------------------------------------------------------------------------------
#                        CUSTOM FUNCTIONS 
#-------------------------------------------------------------------------------

func _flashlight():
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible

func handle_stance():
	var target_state = State.STAND
	
	# Priority: Prone > Crouch > Stand
	if Input.is_action_pressed("prone"):
		target_state = State.PRONE
	elif Input.is_action_pressed("crouch"):
		target_state = State.CROUCH
	
# 2. APPLY CEILING CONSTRAINTS (What the world *allows*)
	# We check from tallest to shortest.
	
	# If we WANT to STAND (or higher), but the ceiling is too low for standing:
	if target_state == State.STAND and stand_ray.is_colliding():
		target_state = State.CROUCH # Force downgrade to Crouch
		
	# If we WANT to CROUCH (or were forced to), but the ceiling is too low for crouching:
	if target_state == State.CROUCH and crouch_ray.is_colliding():
		target_state = State.PRONE # Force downgrade to Prone

	# Apply State Change
	if current_state != target_state:
		current_state = target_state
		update_collision_shapes(current_state)

func update_collision_shapes(state: State):
	# Disable all shapes first
	standing_shape.disabled = true
	crouching_shape.disabled = true
	prone_shape.disabled = true
	
	# Enable only the active one
	match state:
		State.STAND:
			standing_shape.disabled = false
		State.CROUCH:
			crouching_shape.disabled = false
		State.PRONE:
			prone_shape.disabled = false

func get_current_speed() -> float:
	match current_state:
		State.PRONE: return prone_speed
		State.CROUCH: return crouch_speed
		State.STAND:
			if Input.is_action_pressed("run"): return run_speed
			return walk_speed
	return walk_speed
