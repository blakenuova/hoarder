extends Interactable

# We export a NodePath so you can pick ANY light in the scene to control
@export var light_node: Light3D
@export var switch_mesh: Node3D # Optional: If you want the physical switch to flip
@onready var switch_audio: AudioStreamPlayer3D = $SwitchAudio

var is_on = true

func _ready():
	# Sync the switch state with the light's actual state at start
	if light_node:
		is_on = light_node.visible

func interact(player):
	if light_node:
		# 1. Toggle the logic
		is_on = !is_on
		light_node.visible = is_on
		
		# 2. (Optional) Play a sound
		# $AudioStreamPlayer3D.play()
		
		# 3. (Optional) Animate the switch flipping
		if switch_mesh:
			var target_rot = -15 if is_on else 15 # degrees up or down
			var tween = create_tween()
			tween.tween_property(switch_mesh, "rotation_degrees:x", target_rot, 0.1)
			switch_audio.play()
