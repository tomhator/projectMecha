extends Control

@onready var result_label: Label = $ResultLabel
@onready var restart_button: Button = $RestartButton

func _ready() -> void:
	if GameState.is_run_active:
		result_label.text = "런 클리어!"
		GameState.end_run()
	else:
		result_label.text = "런 종료"
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/CoreSelect/CoreSelectScene.tscn")
