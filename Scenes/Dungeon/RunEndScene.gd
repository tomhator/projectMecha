extends Control

const HUB_SCENE: String = "res://Scenes/Base/HubScene.tscn"

@onready var result_label: Label = $Center/VBox/ResultLabel
@onready var summary_label: Label = $Center/VBox/SummaryLabel
@onready var return_button: Button = $Center/VBox/ReturnButton


func _ready() -> void:
	if GameState.is_run_active:
		GameState.end_run(GameState.current_floor > 10)
	var success: bool = bool(GameState.last_run_summary.get("success", GameState.current_floor > 10))
	result_label.text = "런 클리어!" if success else "코어 침묵... 패배"
	summary_label.text = _summary_text()
	return_button.pressed.connect(_on_return_pressed)


func _on_return_pressed() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)


func _summary_text() -> String:
	var summary: Dictionary = GameState.last_run_summary
	if summary.is_empty():
		return "정산 기록 없음"
	var recovered_names: Array = summary.get("recovered_part_names", [])
	var lost_names: Array = summary.get("lost_part_names", [])
	var lines: Array[String] = [
		"도달 층: %d" % int(summary.get("reached_floor", 0)),
		"크레딧: 런 %d / 회수 %d" % [
			int(summary.get("run_credits", 0)),
			int(summary.get("recovered_credits", 0)),
		],
		"고철: 런 %d / 회수 %d" % [
			int(summary.get("run_scrap", 0)),
			int(summary.get("recovered_scrap", 0)),
		],
		"회수 파츠: %d개 / 손실 파츠: %d개" % [
			int(summary.get("recovered_part_count", 0)),
			int(summary.get("lost_part_count", 0)),
		],
	]
	if not recovered_names.is_empty():
		lines.append("회수: %s" % _join_name_preview(recovered_names))
	if not lost_names.is_empty():
		lines.append("손실: %s" % _join_name_preview(lost_names))
	return "\n".join(lines)


func _join_name_preview(names: Array) -> String:
	var out: Array[String] = []
	for i: int in mini(names.size(), 4):
		out.append(str(names[i]))
	if names.size() > 4:
		out.append("외 %d개" % (names.size() - 4))
	return ", ".join(out)
