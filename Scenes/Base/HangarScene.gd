extends Control

const HUB_SCENE: String = "res://Scenes/Base/HubScene.tscn"
const CELL_SIZE: Vector2 = Vector2(142.0, 78.0)
const INVENTORY_CAPACITY: int = 16
const SLOT_ORDER: Array[CoreData.CoreSlot] = [
	CoreData.CoreSlot.ARM_L,
	CoreData.CoreSlot.ARM_R,
	CoreData.CoreSlot.EXTRA_ARM,
	CoreData.CoreSlot.BACK,
	CoreData.CoreSlot.LEG,
]

enum SelectionSource { NONE, STORAGE, SORTIE_INVENTORY, EQUIPPED }

var _storage_grid: GridContainer
var _equipped_grid: GridContainer
var _sortie_grid: GridContainer
var _detail_title: Label
var _detail_body: Label
var _resource_label: Label
var _equip_button: Button
var _to_inventory_button: Button
var _return_button: Button
var _repair_button: Button
var _dismantle_button: Button
var _return_all_button: Button

var _selected_part: PartsData = null
var _selected_source: SelectionSource = SelectionSource.NONE
var _selected_slot: CoreData.CoreSlot = CoreData.CoreSlot.ARM_L


func _ready() -> void:
	_build_shell()
	_refresh_all()
	if not EventBus.storage_changed.is_connected(_on_storage_changed):
		EventBus.storage_changed.connect(_on_storage_changed)
	if not EventBus.scrap_changed.is_connected(_on_scrap_changed):
		EventBus.scrap_changed.connect(_on_scrap_changed)


func _exit_tree() -> void:
	if EventBus.storage_changed.is_connected(_on_storage_changed):
		EventBus.storage_changed.disconnect(_on_storage_changed)
	if EventBus.scrap_changed.is_connected(_on_scrap_changed):
		EventBus.scrap_changed.disconnect(_on_scrap_changed)


func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.070, 0.078, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_top", 14)
	root.add_theme_constant_override("margin_bottom", 16)
	add_child(root)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	root.add_child(main)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	main.add_child(top)

	var title := Label.new()
	title.text = "격납고"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.90, 0.82))
	top.add_child(title)

	_resource_label = Label.new()
	_resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_resource_label.add_theme_font_size_override("font_size", 14)
	_resource_label.add_theme_color_override("font_color", Color(0.74, 0.82, 0.84))
	top.add_child(_resource_label)

	var back := Button.new()
	back.text = "은신처"
	back.custom_minimum_size = Vector2(128.0, 40.0)
	back.pressed.connect(_on_back_pressed)
	top.add_child(back)

	var split := HBoxContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 12)
	main.add_child(split)

	split.add_child(_make_storage_panel())
	split.add_child(_make_sortie_panel())
	split.add_child(_make_detail_panel())


func _make_storage_panel() -> Panel:
	var panel := _make_panel(Color(0.08, 0.10, 0.12, 1.0), Vector2(390.0, 0.0))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = _panel_body(panel)
	body.add_child(_make_section_label("영구 창고"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	_storage_grid = GridContainer.new()
	_storage_grid.columns = 2
	_storage_grid.add_theme_constant_override("h_separation", 8)
	_storage_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_storage_grid)
	return panel


func _make_sortie_panel() -> Panel:
	var panel := _make_panel(Color(0.07, 0.095, 0.11, 1.0), Vector2(510.0, 0.0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = _panel_body(panel)
	body.add_child(_make_section_label("출격 장착 슬롯"))

	_equipped_grid = GridContainer.new()
	_equipped_grid.columns = 2
	_equipped_grid.add_theme_constant_override("h_separation", 8)
	_equipped_grid.add_theme_constant_override("v_separation", 8)
	body.add_child(_equipped_grid)

	var inventory_header := HBoxContainer.new()
	inventory_header.add_child(_make_section_label("런 인벤토리 16칸"))
	_return_all_button = Button.new()
	_return_all_button.text = "되돌리기"
	_return_all_button.custom_minimum_size = Vector2(104.0, 32.0)
	_return_all_button.pressed.connect(_on_return_all_pressed)
	inventory_header.add_child(_return_all_button)
	body.add_child(inventory_header)

	_sortie_grid = GridContainer.new()
	_sortie_grid.columns = 4
	_sortie_grid.add_theme_constant_override("h_separation", 8)
	_sortie_grid.add_theme_constant_override("v_separation", 8)
	body.add_child(_sortie_grid)
	return panel


func _make_detail_panel() -> Panel:
	var panel := _make_panel(Color(0.10, 0.11, 0.12, 1.0), Vector2(320.0, 0.0))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = _panel_body(panel)
	body.add_child(_make_section_label("상세 / 작업"))

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 18)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_detail_title)

	_detail_body = Label.new()
	_detail_body.custom_minimum_size = Vector2(0.0, 260.0)
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.add_theme_font_size_override("font_size", 12)
	_detail_body.add_theme_color_override("font_color", Color(0.76, 0.80, 0.82))
	body.add_child(_detail_body)

	_equip_button = _make_action_button("장착")
	_equip_button.pressed.connect(_on_equip_pressed)
	body.add_child(_equip_button)

	_to_inventory_button = _make_action_button("런 인벤토리")
	_to_inventory_button.pressed.connect(_on_to_inventory_pressed)
	body.add_child(_to_inventory_button)

	_return_button = _make_action_button("창고로")
	_return_button.pressed.connect(_on_return_pressed)
	body.add_child(_return_button)

	_repair_button = _make_action_button("수리")
	_repair_button.pressed.connect(_on_repair_pressed)
	body.add_child(_repair_button)

	_dismantle_button = _make_action_button("분해")
	_dismantle_button.pressed.connect(_on_dismantle_pressed)
	body.add_child(_dismantle_button)
	return panel


func _refresh_all() -> void:
	_validate_selection()
	_refresh_header()
	_refresh_storage()
	_refresh_equipped()
	_refresh_sortie_inventory()
	_refresh_detail()
	_refresh_actions()


func _refresh_header() -> void:
	_resource_label.text = "크레딧 %d  |  고철 %d  |  창고 %d  |  출격 인벤토리 %d/%d" % [
		GameState.meta_credits,
		GameState.meta_scrap,
		GameState.storage_parts.size(),
		GameState.sortie_inventory.size(),
		INVENTORY_CAPACITY,
	]


func _refresh_storage() -> void:
	for child: Node in _storage_grid.get_children():
		child.queue_free()
	if GameState.storage_parts.is_empty():
		_storage_grid.add_child(_make_empty_label("창고 파츠 없음"))
		return
	for part: PartsData in GameState.storage_parts:
		_storage_grid.add_child(_make_part_button(part, SelectionSource.STORAGE))


func _refresh_equipped() -> void:
	for child: Node in _equipped_grid.get_children():
		child.queue_free()
	for slot: CoreData.CoreSlot in SLOT_ORDER:
		# 추가 팔 슬롯은 「진화 군주」 제공 파츠가 있을 때만 노출 (없으면 숨김 — 조립/전투와 동일 규칙)
		if slot == CoreData.CoreSlot.EXTRA_ARM and not GameState.has_sortie_extra_arm_slot():
			continue
		var part: PartsData = GameState.sortie_equipped_parts.get(slot)
		var button := Button.new()
		button.custom_minimum_size = CELL_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.text = "%s\n%s" % [_slot_display_name(slot), part.display_name() if part != null else "비어 있음"]
		button.disabled = part == null
		if part != null:
			button.tooltip_text = part.assembly_tooltip_text()
			button.pressed.connect(_select_part.bind(part, SelectionSource.EQUIPPED, slot))
			_apply_part_button_style(button, part)
		_equipped_grid.add_child(button)


func _refresh_sortie_inventory() -> void:
	for child: Node in _sortie_grid.get_children():
		child.queue_free()
	for index: int in range(INVENTORY_CAPACITY):
		if index < GameState.sortie_inventory.size():
			_sortie_grid.add_child(_make_part_button(GameState.sortie_inventory[index], SelectionSource.SORTIE_INVENTORY))
		else:
			var empty := Button.new()
			empty.text = "빈 칸"
			empty.disabled = true
			empty.custom_minimum_size = Vector2(108.0, 58.0)
			_sortie_grid.add_child(empty)


func _refresh_detail() -> void:
	if _selected_part == null:
		_detail_title.text = "선택 없음"
		_detail_body.text = "창고 파츠, 출격 슬롯, 런 인벤토리 항목을 선택하세요."
		return
	var lines: Array[String] = [
		_selected_part.assembly_tooltip_text(),
		"",
		"수리 비용: 고철 %d" % GameState.repair_cost_for_part(_selected_part),
		"분해 획득: 고철 %d" % GameState.dismantle_value_for_part(_selected_part),
	]
	if _selected_part.is_broken():
		lines.append("파손 파츠는 수리 전 장착/출격 인벤토리 이동 불가")
	_detail_title.text = _selected_part.display_name()
	_detail_body.text = "\n".join(lines)


func _refresh_actions() -> void:
	var has_part: bool = _selected_part != null
	var selected_storage: bool = _selected_source == SelectionSource.STORAGE
	var selected_sortie_inv: bool = _selected_source == SelectionSource.SORTIE_INVENTORY
	var selected_equipped: bool = _selected_source == SelectionSource.EQUIPPED
	var movable: bool = has_part and not _selected_part.is_broken()

	_equip_button.disabled = not movable or selected_equipped
	_to_inventory_button.disabled = not movable or not selected_storage or GameState.sortie_inventory.size() >= INVENTORY_CAPACITY
	_return_button.disabled = not has_part or (not selected_sortie_inv and not selected_equipped)
	_repair_button.disabled = not (has_part and selected_storage and _selected_part.is_worn() and GameState.meta_scrap >= GameState.repair_cost_for_part(_selected_part))
	_dismantle_button.disabled = not (has_part and selected_storage)
	_return_all_button.disabled = GameState.sortie_inventory.is_empty() and _sortie_equipped_count() <= 0

	if has_part and not _selected_part.is_broken():
		_equip_button.text = "%s 장착" % _slot_display_name(_slot_for_part_type(_selected_part.parts_type))
	else:
		_equip_button.text = "장착"


func _make_part_button(part: PartsData, source: SelectionSource) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CELL_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.text = _part_button_text(part)
	button.tooltip_text = part.assembly_tooltip_text()
	button.pressed.connect(_select_part.bind(part, source, CoreData.CoreSlot.ARM_L))
	_apply_part_button_style(button, part)
	return button


func _part_button_text(part: PartsData) -> String:
	var state: String = "파손" if part.is_broken() else "손상" if part.is_worn() else "정상"
	return "[%s] %s\n%s / %d-%d" % [
		PartsData.PartsType.keys()[part.parts_type],
		part.display_name(),
		state,
		part.durability,
		part.max_durability,
	]


func _apply_part_button_style(button: Button, part: PartsData) -> void:
	var bg := Color(0.12, 0.15, 0.17, 1.0)
	if part.is_broken():
		bg = Color(0.20, 0.08, 0.08, 1.0)
	elif part.is_worn():
		bg = Color(0.18, 0.14, 0.08, 1.0)
	button.add_theme_stylebox_override("normal", _button_style(bg, _grade_color(part), 4))
	button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.08), Color(0.92, 0.86, 0.52), 4))


func _select_part(part: PartsData, source: SelectionSource, slot: CoreData.CoreSlot) -> void:
	_selected_part = part
	_selected_source = source
	_selected_slot = slot
	_refresh_detail()
	_refresh_actions()


func _on_equip_pressed() -> void:
	if _selected_part == null:
		return
	var target_slot: CoreData.CoreSlot = _slot_for_part_type(_selected_part.parts_type)
	if GameState.equip_sortie_part(_selected_part, target_slot):
		_selected_source = SelectionSource.EQUIPPED
		_selected_slot = target_slot
	_refresh_all()


func _on_to_inventory_pressed() -> void:
	if _selected_part == null:
		return
	if GameState.move_storage_to_sortie_inventory(_selected_part):
		_selected_source = SelectionSource.SORTIE_INVENTORY
	_refresh_all()


func _on_return_pressed() -> void:
	if _selected_part == null:
		return
	if _selected_source == SelectionSource.SORTIE_INVENTORY:
		GameState.move_sortie_inventory_to_storage(_selected_part)
		_selected_source = SelectionSource.STORAGE
	elif _selected_source == SelectionSource.EQUIPPED:
		GameState.unequip_sortie_part(_selected_slot)
		_selected_source = SelectionSource.STORAGE
	_refresh_all()


func _on_repair_pressed() -> void:
	if _selected_part == null:
		return
	GameState.repair_storage_part(_selected_part)
	_refresh_all()


func _on_dismantle_pressed() -> void:
	if _selected_part == null:
		return
	if GameState.dismantle_storage_part(_selected_part):
		_clear_selection()
	_refresh_all()


func _on_return_all_pressed() -> void:
	GameState.return_sortie_loadout_to_storage()
	_clear_selection()
	_refresh_all()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)


func _on_storage_changed(_parts: Array) -> void:
	_refresh_all()


func _on_scrap_changed(_amount: int) -> void:
	_refresh_all()


func _clear_selection() -> void:
	_selected_part = null
	_selected_source = SelectionSource.NONE
	_selected_slot = CoreData.CoreSlot.ARM_L


func _validate_selection() -> void:
	if _selected_part == null:
		return
	match _selected_source:
		SelectionSource.STORAGE:
			if not GameState.storage_parts.has(_selected_part):
				_clear_selection()
		SelectionSource.SORTIE_INVENTORY:
			if not GameState.sortie_inventory.has(_selected_part):
				_clear_selection()
		SelectionSource.EQUIPPED:
			if GameState.sortie_equipped_parts.get(_selected_slot) != _selected_part:
				_clear_selection()
		_:
			_clear_selection()


func _sortie_equipped_count() -> int:
	var count: int = 0
	for slot: CoreData.CoreSlot in SLOT_ORDER:
		if GameState.sortie_equipped_parts.get(slot) != null:
			count += 1
	return count


func _make_panel(bg: Color, minimum_size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _button_style(bg, Color(0.28, 0.34, 0.38), 6))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	return panel


func _panel_body(panel: Panel) -> VBoxContainer:
	var margin: MarginContainer = panel.get_child(0) as MarginContainer
	return margin.get_child(0) as VBoxContainer


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.84))
	return label


func _make_empty_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = CELL_SIZE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.50, 0.56, 0.58))
	return label


func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 38.0)
	return button


func _button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _grade_color(part: PartsData) -> Color:
	match part.grade():
		PartsData.PartsGrade.RARE: return Color(0.36, 0.62, 0.96, 1.0)
		PartsData.PartsGrade.EPIC: return Color(0.78, 0.40, 0.96, 1.0)
		_: return Color(0.72, 0.72, 0.70, 1.0)


func _slot_for_part_type(parts_type: PartsData.PartsType) -> CoreData.CoreSlot:
	match parts_type:
		PartsData.PartsType.ARM_L: return CoreData.CoreSlot.ARM_L
		PartsData.PartsType.ARM_R: return CoreData.CoreSlot.ARM_R
		PartsData.PartsType.BACK: return CoreData.CoreSlot.BACK
		PartsData.PartsType.LEG: return CoreData.CoreSlot.LEG
	return CoreData.CoreSlot.ARM_L


func _slot_display_name(slot: int) -> String:
	match slot:
		CoreData.CoreSlot.ARM_L: return "왼팔"
		CoreData.CoreSlot.ARM_R: return "오른팔"
		CoreData.CoreSlot.EXTRA_ARM: return "추가 팔"
		CoreData.CoreSlot.BACK: return "등"
		CoreData.CoreSlot.LEG: return "다리"
	return "알 수 없음"
