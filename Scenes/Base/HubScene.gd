extends Control

const HANGAR_SCENE: String = "res://Scenes/Base/HangarScene.tscn"
const CORE_SELECT_SCENE: String = "res://Scenes/CoreSelect/CoreSelectScene.tscn"
const BACKGROUND_PATH: String = "res://Asset/UI/hub_outer_hideout.png"
const SLOT_ORDER: Array[CoreData.CoreSlot] = [
	CoreData.CoreSlot.ARM_L,
	CoreData.CoreSlot.ARM_R,
	CoreData.CoreSlot.BACK,
	CoreData.CoreSlot.LEG,
]

var _status_label: Label
var _recommend_label: Label
var _operation_dialog: AcceptDialog
var _system_dialog: AcceptDialog


func _ready() -> void:
	_build_background()
	_build_status_band()
	_build_zone_buttons()
	_build_dialogs()
	_refresh_status()
	if not EventBus.scrap_changed.is_connected(_on_hub_state_changed):
		EventBus.scrap_changed.connect(_on_hub_state_changed)
	if not EventBus.storage_changed.is_connected(_on_storage_changed):
		EventBus.storage_changed.connect(_on_storage_changed)


func _exit_tree() -> void:
	if EventBus.scrap_changed.is_connected(_on_hub_state_changed):
		EventBus.scrap_changed.disconnect(_on_hub_state_changed)
	if EventBus.storage_changed.is_connected(_on_storage_changed):
		EventBus.storage_changed.disconnect(_on_storage_changed)


func _build_background() -> void:
	var texture_rect := TextureRect.new()
	texture_rect.name = "Background"
	var image := Image.new()
	if image.load(BACKGROUND_PATH) == OK:
		texture_rect.texture = ImageTexture.create_from_image(image)
	else:
		push_warning("Hub background image load failed: %s" % BACKGROUND_PATH)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture_rect)

	var shade := ColorRect.new()
	shade.name = "ReadabilityShade"
	shade.color = Color(0.0, 0.0, 0.0, 0.22)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _build_status_band() -> void:
	var panel := Panel.new()
	panel.name = "StatusBand"
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_bottom = 86.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.06, 0.08, 0.78), Color(0.34, 0.42, 0.48, 0.9), 0))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)

	var title := Label.new()
	title.text = "외곽 은신처"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84))
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(title)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	row.add_child(text_box)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.90))
	text_box.add_child(_status_label)

	_recommend_label = Label.new()
	_recommend_label.add_theme_font_size_override("font_size", 13)
	_recommend_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.82))
	text_box.add_child(_recommend_label)


func _build_zone_buttons() -> void:
	_add_zone_button("격납고", "파츠 정비", Rect2(0.055, 0.245, 0.245, 0.255), _on_hangar_pressed)
	_add_zone_button("코어 연구대", "연구/레벨업", Rect2(0.380, 0.300, 0.235, 0.250), _on_core_research_pressed)
	_add_zone_button("출격 게이트", "던전 진입", Rect2(0.725, 0.255, 0.235, 0.335), _on_sortie_gate_pressed)
	_add_zone_button("작전 단말", "기록", Rect2(0.055, 0.640, 0.260, 0.230), _on_operation_pressed)
	_add_zone_button("시스템 콘솔", "옵션", Rect2(0.710, 0.650, 0.255, 0.235), _on_system_pressed)


func _add_zone_button(title: String, subtitle: String, rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.name = "%sButton" % title.replace(" ", "")
	button.text = "%s\n%s" % [title, subtitle]
	button.anchor_left = rect.position.x
	button.anchor_top = rect.position.y
	button.anchor_right = rect.position.x + rect.size.x
	button.anchor_bottom = rect.position.y + rect.size.y
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.05, 0.08, 0.10, 0.38), Color(0.75, 0.86, 0.88, 0.55), 6))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.09, 0.18, 0.18, 0.58), Color(0.55, 0.92, 0.88, 0.88), 6))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.15, 0.24, 0.22, 0.70), Color(0.90, 0.72, 0.34, 0.90), 6))
	button.pressed.connect(callback)
	add_child(button)


func _build_dialogs() -> void:
	_operation_dialog = AcceptDialog.new()
	_operation_dialog.title = "작전 단말"
	add_child(_operation_dialog)

	_system_dialog = AcceptDialog.new()
	_system_dialog.title = "시스템 콘솔"
	add_child(_system_dialog)


func _refresh_status() -> void:
	var staged_count: int = GameState.sortie_inventory.size() + _equipped_sortie_count()
	_status_label.text = "크레딧 %d  |  고철 %d  |  창고 파츠 %d  |  출격 세팅 %d" % [
		GameState.meta_credits,
		GameState.meta_scrap,
		GameState.storage_parts.size(),
		staged_count
	]
	_recommend_label.text = _recommendation_text()


func _recommendation_text() -> String:
	var broken_count: int = 0
	for part: PartsData in GameState.storage_parts:
		if part != null and part.is_broken():
			broken_count += 1
	if broken_count > 0:
		return "추천: 파손 파츠 %d개 수리 또는 분해 가능" % broken_count
	if _equipped_sortie_count() <= 0 and not GameState.storage_parts.is_empty():
		return "추천: 격납고에서 장착 파츠를 골라 출격 준비"
	if _equipped_sortie_count() > 0:
		return "추천: 출격 게이트에서 코어 빌드 확인 후 던전 진입"
	return "추천: 출격 게이트에서 첫 런 시작"


func _on_hub_state_changed(_amount: int) -> void:
	_refresh_status()


func _on_storage_changed(_parts: Array) -> void:
	_refresh_status()


func _on_hangar_pressed() -> void:
	get_tree().change_scene_to_file(HANGAR_SCENE)


func _on_core_research_pressed() -> void:
	GameState.core_select_initial_tab = "research"
	get_tree().change_scene_to_file(CORE_SELECT_SCENE)


func _on_sortie_gate_pressed() -> void:
	GameState.core_select_initial_tab = "sortie"
	get_tree().change_scene_to_file(CORE_SELECT_SCENE)


func _on_operation_pressed() -> void:
	var lines: Array[String] = [
		"총 런: %d  |  성공: %d  |  실패: %d  |  최고 도달층: %d" % [
			GameState.total_runs,
			GameState.successful_runs,
			GameState.failed_runs,
			GameState.highest_floor,
		]
	]
	if GameState.last_run_summary.is_empty():
		lines.append("최근 런 기록 없음")
	else:
		var success_text: String = "성공" if bool(GameState.last_run_summary.get("success", false)) else "실패"
		lines.append("최근 런: %s / %d층 / 크레딧 %d / 고철 %d" % [
			success_text,
			int(GameState.last_run_summary.get("reached_floor", 0)),
			int(GameState.last_run_summary.get("recovered_credits", 0)),
			int(GameState.last_run_summary.get("recovered_scrap", 0)),
		])
		lines.append("회수 파츠 %d개 / 손실 파츠 %d개" % [
			int(GameState.last_run_summary.get("recovered_part_count", 0)),
			int(GameState.last_run_summary.get("lost_part_count", 0)),
		])
	_operation_dialog.dialog_text = "\n".join(lines)
	_operation_dialog.popup_centered()


func _on_system_pressed() -> void:
	GameState.save_meta_progress()
	_system_dialog.dialog_text = "저장 완료\n\n옵션 메뉴는 데모 MVP에서 스텁으로 유지됩니다."
	_system_dialog.popup_centered()


func _equipped_sortie_count() -> int:
	var count: int = 0
	for slot: CoreData.CoreSlot in SLOT_ORDER:
		if GameState.sortie_equipped_parts.get(slot) != null:
			count += 1
	return count


func _panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style
