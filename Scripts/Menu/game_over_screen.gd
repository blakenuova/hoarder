extends Control

@onready var title_label = $"Game Over"

func _ready():
	
	# Start hidden
	visible = false

func set_title(text: String, color: Color):
	title_label.text = text
	title_label.add_theme_color_override("font_color", color)
	
	# Show mouse and pause game
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
