extends Control

@onready var prompt_label = $Label

func update_prompt(text_message):
	prompt_label.text = text_message
	prompt_label.visible = true

func clear_prompt():
	prompt_label.visible = false
