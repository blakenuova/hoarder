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
@onready var standing_shape = $StandingCollisionShape
@onready var crouching_shape = $CrouchingCollisionShape
@onready var prone_shape = $ProneCollisionShape
@onready var stand_ray: RayCast3D = $StandRay
@onready var crouch_ray: RayCast3D = $CrouchRay
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var hud: Control = $CanvasLayer/HUD
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var inventory: Inventory = $Inventory
@onready var inventory_ui: Control = $CanvasLayer/InventoryUI
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var aim_ray: RayCast3D = $Head/Camera3D/AimRay


# --------------- audio node ---------------
@export_group("Audio")
@onready var footstep_audio: AudioStreamPlayer3D = $Footstep_audio

# --- Head Bobbing ---
@export_group("Head Bob")
@export var bob_freq = 2.4
@export var bob_amp = 0.08
var t_bob = 0.0


# Flashlight
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var flashlight_audio: AudioStreamPlayer3D = $Head/Camera3D/Flashlight/Flashlight_audio

# Player Stats
@export var health: int = 100

#-------------------------------------------------------------------------------

func _ready():
	# Lock mouse for FPS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Initialize shapes: Ensure only standing is active at start
	update_collision_shapes(State.STAND)
	
	# --- CONNECT SIGNALS ---
	# When inventory changes, tell UI to update
	inventory.inventory_updated.connect(inventory_ui.update_grid)
	
	# Listen for Drop Request
	inventory_ui.drop_item.connect(_on_drop_item)
	inventory_ui.use_item.connect(_on_use_item)
	
	# --- WEAPON CONNECTIONS ---
	for child in weapon_holder.get_children():
		if child is Weapon:
			# 1. Give the weapon the Camera's Raycast
			child.ray_cast = aim_ray 
			
			# 2. Connect signals
			child.ammo_changed.connect(_on_ammo_changed)
			hud.update_ammo(child.current_ammo, child.max_ammo)

func _input(event):
	# Toggle Inventory (Always allow this so we can close it!)
	if event.is_action_pressed("inventory"):
		inventory_ui.visible = !inventory_ui.visible
		if inventory_ui.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	# --- BLOCKER ---
	# If inventory is open, ignore camera look
	if inventory_ui.visible:
		return
		
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
	# --- BLOCKER ---
	if inventory_ui.visible:
		return # Stop all movement calculations
	
	_flashlight()
	_interaction_logic()
	_handle_combat()
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
	
	_headbob(delta)


#-------------------------------------------------------------------------------
#                        CUSTOM FUNCTIONS 
#-------------------------------------------------------------------------------

func _flashlight():
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = !flashlight.visible
		flashlight_audio.play()

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

func _interaction_logic():
	# 1. Check if Raycast is hitting anything
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		
		# 2. Is it Interactable?
		if collider is Interactable:
			# SHOW PROMPT on UI
			hud.update_prompt(collider.prompt_message)
			
			# Interact on key press
			if Input.is_action_just_pressed("interact"):
				collider.interact(self)
		else:
			# Hitting something, but it's not interactive (like a wall)
			hud.clear_prompt()
	else:
		# Not looking at anything
		hud.clear_prompt()

func _headbob(delta):
	if is_on_floor():
		# Only bob if moving
		if velocity.length() > 0.1: 
			# Increment time based on speed (faster run = faster bob)
			t_bob += delta * velocity.length() * float(is_on_floor())
			
			# Calculate the Sine Wave
			# sin(t_bob * bob_freq) creates the up/down wave
			var pos = Vector3.ZERO
			pos.y = sin(t_bob * bob_freq) * bob_amp
			pos.x = cos(t_bob * bob_freq / 2) * bob_amp # Slower side-to-side sway
			
			# Apply to Camera (local position)
			camera.transform.origin = pos
			
			# --- FOOTSTEP AUDIO LOGIC ---
			# If the sine wave is at the "bottom" (the step), play sound.
			# We check a small window near -1.0 on the sine wave.
			var low_pos = sin(t_bob * bob_freq)
			
			# If the cycle just hit the bottom ( > -0.95 is purely for timing tolerance)
			# We use a timer check or simple math to ensure it doesn't spam every frame
			# A simple way: check if we just crossed a threshold
			if low_pos < -0.90 and !footstep_audio.playing:
				# Randomize pitch slightly for variety
				footstep_audio.pitch_scale = randf_range(0.8, 1.1)
				footstep_audio.play()
				
		else:
			# Reset camera smoothly when stopped
			t_bob = 0.0
			camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 5.0)

func collect_item(item_data: ItemData):
	inventory.add_item(item_data)

func _on_drop_item(index: int):
	var item_to_drop = inventory.items[index]
	
	# CHECK IF PATH IS NOT EMPTY
	if item_to_drop.pickup_scene_path != "":
		
		# 1. LOAD THE SCENE MANUALLY
		var scene_resource = load(item_to_drop.pickup_scene_path)
		
		# 2. INSTANTIATE IT
		var pickup_instance = scene_resource.instantiate()
		get_parent().add_child(pickup_instance)
		
		# Position it
		var drop_position = head.global_position - (head.global_transform.basis.z * 1.5)
		pickup_instance.global_position = drop_position
		
		# IMPORTANT: If the spawned pickup needs to know what it is, re-assign the data!
		# (This is safe because it happens at runtime, not save-time)
		if pickup_instance is Pickup: # Assuming your class_name is Pickup
			pickup_instance.item_data = item_to_drop

	# 3. Remove from Inventory
	inventory.remove_item_at_index(index)

func _on_use_item(index: int):
	# 1. Get the item
	var item_to_use = inventory.items[index]
	
	# 2. Try to use it. Pass 'self' (the player) to the item.
	var was_used = item_to_use.use(self)
	
	# 3. If the item says it was consumed (returns true), remove it.
	if was_used:
		inventory.remove_item_at_index(index)

func _handle_combat():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# FIRE
		if Input.is_action_pressed("fire"):
			for child in weapon_holder.get_children():
				if child.has_method("shoot"):
					child.shoot()
		
		# RELOAD
		if Input.is_action_just_pressed("reload"): # Make sure "reload" is in Input Map (key R)
			for child in weapon_holder.get_children():
				if child.has_method("reload"):
					child.reload()
					

func _on_ammo_changed(new_amount):
	# We assume max ammo is 30 for now, or you can get it from the weapon
	# For a quick fix, just update the current number
	hud.update_ammo(new_amount, 30)
