extends Control

@onready var prompt_label = $Label
@onready var crosshair: ColorRect = $Crosshair
@onready var ammo_label: Label = $AmmoLabel


func update_prompt(text_message):
	prompt_label.text = text_message
	prompt_label.visible = true

func clear_prompt():
	prompt_label.visible = false

func set_crosshair_color(color: Color):
	crosshair.color = color

func update_ammo(current, max_ammo):
	# Format the text like "25 / 30"
	ammo_label.text = str(current) + " / " + str(max_ammo)
