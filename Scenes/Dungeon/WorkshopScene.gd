extends Control

@onready var next_button: Button = $NextButton

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)

func _on_next_button_pressed() -> void:
	DungeonManager.on_room_cleared()
