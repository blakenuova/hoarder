extends Interactable

# Settings
@export var open_angle = 90.0  # How far to rotate (in degrees)
@export var open_time = 0.5    # How fast it opens

var is_open = false
var closed_rotation = 0.0

func _ready():
	# Remember where we started so we can close it exactly
	closed_rotation = rotation_degrees.y

# We override the 'interact' function from the parent script
func interact(player):
	# Toggle state
	is_open = !is_open
	
	# Calculate target rotation
	var target_y = closed_rotation
	if is_open:
		target_y = closed_rotation + open_angle
		
	# Create a Tween to animate the rotation smoothly
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:y", target_y, open_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
