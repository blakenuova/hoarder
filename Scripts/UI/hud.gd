extends Control

@onready var prompt_label = $Label
@onready var crosshair: ColorRect = $Crosshair


func update_prompt(text_message):
	prompt_label.text = text_message
	prompt_label.visible = true

func clear_prompt():
	prompt_label.visible = false

func set_crosshair_color(color: Color):
	crosshair.color = color
