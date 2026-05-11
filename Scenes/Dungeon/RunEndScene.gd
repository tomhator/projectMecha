extends Control

@onready var result_label: Label = $Center/VBox/ResultLabel
@onready var return_button: Button = $Center/VBox/ReturnButton


func _ready() -> void:
	if GameState.current_floor > 10:
		result_label.text = "런 클리어!"
		GameState.end_run()
	else:
		result_label.text = "코어 침묵… 패배"
	return_button.pressed.connect(_on_return_pressed)


func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/CoreSelect/CoreSelectScene.tscn")
