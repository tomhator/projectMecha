extends Control

const DUNGEON_MAP_SCENE: String = "res://Scenes/Dungeon/DungeonMapScene.tscn"
const SLOT_NONE: int = -1

# ── 노드 레퍼런스 ────────────────────────
@onready var left_column: VBoxContainer       = $MainContainer/LeftColumn
@onready var right_column: VBoxContainer      = $MainContainer/RightColumn
@onready var chassis_panel: VBoxContainer     = $MainContainer/LeftColumn/ChassisPanel
@onready var inventory_title: Label           = $MainContainer/RightColumn/InventoryTitle
@onready var inventory_grid: GridContainer    = $MainContainer/RightColumn/ScrollContainer/InventoryGrid
@onready var payload_label: Label             = $PayloadLabel
@onready var payload_bar: ProgressBar         = $PayloadBar
@onready var close_button: Button             = $CloseButton
@onready var hint_label: Label                = $HintLabel
@onready var _ap_orbs_row: HBoxContainer      = $APOrbsRow

# ── 소켓 맵 ─────────────────────────────
var _sockets: Dictionary = {}  # CoreData.CoreSlot → PartSocketUI
var _inventory_cards: Dictionary = {}  # PartsData → PartCardUI
var _skill_preview_buttons: Dictionary = {}  # SkillData → Button

# 십자 그리드 3열 — ChassisPanel 너비로 셀 크기 계산 (코어는 정사각형)
const CHASSIS_COL_SEP: int = 8
const CELL_MIN: int = 72
const CELL_MAX: int = 220

const INVENTORY_COLS: int = 4
## 인벤토리 슬롯·카드는 정사각형 (픽셀 한 변 길이)
const INVENTORY_CELL_PX: int = 92
const SKILL_PREVIEW_SLOT_SIZE: Vector2 = Vector2(60.0, 60.0)

var _chassis_spacers: Array[Control] = []
var _core_placeholder_panel: Panel = null

var _selected_inventory_part: PartsData = null
var _selected_slot: int = SLOT_NONE
var _selected_skill: SkillData = null

var _selection_panel: Panel
var _selection_title: Label
var _selection_body: Label
var _equip_button: Button
var _unequip_button: Button
var _clear_button: Button

var _skill_preview_panel: Panel
var _skill_preview_container: HBoxContainer


# ── 초기화 ──────────────────────────────
func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	if not EventBus.inventory_add_failed.is_connected(_on_inventory_add_failed):
		EventBus.inventory_add_failed.connect(_on_inventory_add_failed)
	if not chassis_panel.resized.is_connected(_on_chassis_resized):
		chassis_panel.resized.connect(_on_chassis_resized)

	_build_sockets()
	_build_selection_panel()
	_build_skill_preview_panel()
	_rebuild_inventory()
	_update_payload()
	_refresh_selection_visuals()
	_update_selection_detail()
	call_deferred("_refresh_chassis_layout")


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		call_deferred("_clear_assembly_inventory_drag")


func _clear_assembly_inventory_drag() -> void:
	if EventBus.assembly_drag_inventory_part == null:
		return
	EventBus.assembly_drag_inventory_part = null
	get_tree().call_group("part_socket_drag_highlight", "end_drag_inventory_highlight")


# ── 소켓 구성 (십자 배치) ─────────────────
func _build_sockets() -> void:
	for child: Node in chassis_panel.get_children():
		child.queue_free()
	_sockets.clear()
	_chassis_spacers.clear()
	_core_placeholder_panel = null

	var row1 := _make_chassis_row()
	row1.add_child(_make_socket_spacer())
	var back_socket := _make_socket(CoreData.CoreSlot.BACK)
	_sockets[CoreData.CoreSlot.BACK] = back_socket
	row1.add_child(back_socket)
	row1.add_child(_make_socket_spacer())
	chassis_panel.add_child(row1)

	var row2 := _make_chassis_row()
	var armr_socket := _make_socket(CoreData.CoreSlot.ARM_R)
	_sockets[CoreData.CoreSlot.ARM_R] = armr_socket
	row2.add_child(armr_socket)
	row2.add_child(_make_core_placeholder())
	var arml_socket := _make_socket(CoreData.CoreSlot.ARM_L)
	_sockets[CoreData.CoreSlot.ARM_L] = arml_socket
	row2.add_child(arml_socket)
	if GameState.has_extra_arm_slot():
		var extra_socket := _make_socket(CoreData.CoreSlot.EXTRA_ARM)
		_sockets[CoreData.CoreSlot.EXTRA_ARM] = extra_socket
		row2.add_child(extra_socket)
	chassis_panel.add_child(row2)

	var row3 := _make_chassis_row()
	row3.add_child(_make_socket_spacer())
	var leg_socket := _make_socket(CoreData.CoreSlot.LEG)
	_sockets[CoreData.CoreSlot.LEG] = leg_socket
	row3.add_child(leg_socket)
	row3.add_child(_make_socket_spacer())
	chassis_panel.add_child(row3)

	for slot: CoreData.CoreSlot in _sockets:
		var equipped: PartsData = GameState.equipped_parts[slot]
		if equipped != null:
			_sockets[slot].set_equipped(equipped)

	_refresh_chassis_layout()


func _on_chassis_resized() -> void:
	_refresh_chassis_layout()


func _refresh_chassis_layout() -> void:
	var w: float = chassis_panel.size.x
	if w < 36.0:
		return
	var cell: int = int((w - float(CHASSIS_COL_SEP * 2)) / 3.0)
	cell = clampi(cell, CELL_MIN, CELL_MAX)
	var sz: Vector2 = Vector2(float(cell), float(cell))

	for spacer: Control in _chassis_spacers:
		spacer.custom_minimum_size = sz

	if _core_placeholder_panel != null:
		_core_placeholder_panel.custom_minimum_size = sz

	for slot: CoreData.CoreSlot in _sockets:
		var sk: PartSocketUI = _sockets[slot]
		sk.set_layout_size(sz)


# ── 섀시 레이아웃 헬퍼 ────────────────────
func _make_chassis_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", CHASSIS_COL_SEP)
	return row


func _make_socket_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(float(CELL_MIN), float(CELL_MIN))
	_chassis_spacers.append(spacer)
	return spacer


func _make_core_placeholder() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(float(CELL_MIN), float(CELL_MIN))
	_core_placeholder_panel = panel

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.15, 0.23, 1.0)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.65, 0.90, 1.0)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_right = -8
	vbox.offset_top = 8
	vbox.offset_bottom = -8
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var tag := Label.new()
	tag.text = "CORE"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color(0.5, 0.65, 0.85))
	vbox.add_child(tag)

	var name_lbl := Label.new()
	var core_name: String = GameState.current_core.core_name if GameState.current_core != null else "???"
	name_lbl.text = core_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_lbl)

	return panel


# ── 선택 상세 패널 ────────────────────────
func _build_selection_panel() -> void:
	if _selection_panel != null:
		return

	_selection_panel = Panel.new()
	_selection_panel.name = "SelectionPanel"
	_selection_panel.custom_minimum_size = Vector2(0.0, 168.0)
	_selection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_selection_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.13, 0.17, 0.96), Color(0.35, 0.40, 0.48)))
	right_column.add_child(_selection_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_selection_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	_selection_title = Label.new()
	_selection_title.add_theme_font_size_override("font_size", 14)
	_selection_title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	vbox.add_child(_selection_title)

	_selection_body = Label.new()
	_selection_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_body.clip_text = true
	_selection_body.custom_minimum_size = Vector2(0.0, 76.0)
	_selection_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_selection_body.add_theme_font_size_override("font_size", 11)
	_selection_body.add_theme_color_override("font_color", Color(0.74, 0.78, 0.84))
	vbox.add_child(_selection_body)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 8)
	vbox.add_child(action_row)

	_equip_button = _make_action_button("장착")
	_equip_button.pressed.connect(_on_equip_selected_pressed)
	action_row.add_child(_equip_button)

	_unequip_button = _make_action_button("해제")
	_unequip_button.pressed.connect(_on_unequip_selected_pressed)
	action_row.add_child(_unequip_button)

	_clear_button = _make_action_button("선택 해제")
	_clear_button.pressed.connect(_clear_selection)
	action_row.add_child(_clear_button)


func _make_action_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(96.0, 30.0)
	btn.focus_mode = Control.FOCUS_NONE
	return btn


# ── 전투 스킬 프리뷰 ──────────────────────
func _build_skill_preview_panel() -> void:
	if _skill_preview_panel != null:
		return

	_skill_preview_panel = Panel.new()
	_skill_preview_panel.name = "SkillPreviewPanel"
	_skill_preview_panel.anchor_left = 0.30
	_skill_preview_panel.anchor_top = 1.0
	_skill_preview_panel.anchor_right = 0.88
	_skill_preview_panel.anchor_bottom = 1.0
	_skill_preview_panel.offset_left = 0.0
	_skill_preview_panel.offset_top = -88.0
	_skill_preview_panel.offset_right = 0.0
	_skill_preview_panel.offset_bottom = -14.0
	_skill_preview_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.12, 0.16, 0.96), Color(0.36, 0.42, 0.50)))
	add_child(_skill_preview_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_skill_preview_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "전투 스킬 배치"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78))
	vbox.add_child(title)

	_skill_preview_container = HBoxContainer.new()
	_skill_preview_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_skill_preview_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_skill_preview_container)

	_refresh_skill_preview()


func _refresh_skill_preview() -> void:
	if _skill_preview_container == null:
		return
	for child: Node in _skill_preview_container.get_children():
		child.queue_free()
	_skill_preview_buttons.clear()

	var visible_count: int = 0
	for skill: SkillData in GameState.get_combat_skill_order():
		if skill == null:
			continue
		var btn := _make_skill_preview_button(skill)
		_skill_preview_container.add_child(btn)
		_skill_preview_buttons[skill] = btn
		visible_count += 1

	if visible_count == 0:
		var empty := Label.new()
		empty.text = "스킬 없음"
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.55, 0.58, 0.64))
		_skill_preview_container.add_child(empty)


func _make_skill_preview_button(skill: SkillData) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.icon = skill.icon_texture(44)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = SKILL_PREVIEW_SLOT_SIZE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = _skill_preview_tooltip(skill)
	btn.pressed.connect(_select_skill_preview.bind(skill))

	var source_part: PartsData = GameState.get_part_for_combat_skill(skill)
	var is_broken: bool = source_part != null and source_part.is_broken()
	if is_broken:
		btn.modulate = Color(0.55, 0.55, 0.55, 1.0)

	_apply_skill_button_style(btn, skill, is_broken, skill == _selected_skill)
	_add_skill_badge(btn, _skill_source_short(skill), Vector2(4.0, 4.0), false)
	_add_skill_badge(btn, str(skill.skill_action_cost), Vector2(-20.0, -20.0), true)
	return btn


func _apply_skill_button_style(btn: Button, skill: SkillData, is_broken: bool, selected: bool) -> void:
	var base_color: Color = _skill_type_color(skill)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.21, 1.0)
	style.set_border_width_all(2)
	style.border_color = base_color
	style.set_corner_radius_all(4)
	if is_broken:
		style.bg_color = Color(0.16, 0.08, 0.08, 1.0)
		style.border_color = Color(0.85, 0.24, 0.24, 1.0)
	if selected:
		style.border_color = Color(1.0, 0.82, 0.35, 1.0)
		style.set_border_width_all(3)

	var hover := style.duplicate()
	hover.bg_color = style.bg_color.lightened(0.10)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)


func _add_skill_badge(parent: Control, text: String, offset: Vector2, bottom_right: bool) -> void:
	var badge := Panel.new()
	if bottom_right:
		badge.anchor_left = 1.0
		badge.anchor_top = 1.0
		badge.anchor_right = 1.0
		badge.anchor_bottom = 1.0
		badge.offset_left = offset.x
		badge.offset_top = offset.y
		badge.offset_right = -4.0
		badge.offset_bottom = -4.0
	else:
		badge.anchor_left = 0.0
		badge.anchor_top = 0.0
		badge.anchor_right = 0.0
		badge.anchor_bottom = 0.0
		badge.offset_left = offset.x
		badge.offset_top = offset.y
		badge.offset_right = offset.x + 24.0
		badge.offset_bottom = offset.y + 16.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _make_panel_style(Color(0.04, 0.05, 0.07, 0.88), Color(0.35, 0.40, 0.48), 2))
	parent.add_child(badge)

	var label := Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.84))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)


# ── 인벤토리 재구성 ──────────────────────
func _rebuild_inventory() -> void:
	for child: Node in inventory_grid.get_children():
		child.queue_free()
	_inventory_cards.clear()

	inventory_grid.columns = INVENTORY_COLS
	var parts: Array = GameState.inventory.duplicate()
	var slots: int = GameState.get_inventory_capacity()
	for idx: int in range(slots):
		if idx < parts.size():
			var part: PartsData = parts[idx]
			var card := _make_card(part)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			inventory_grid.add_child(_wrap_inventory_square(card))
			card.setup(part)
			card.set_selected(part == _selected_inventory_part)
			_inventory_cards[part] = card
		else:
			var empty_p := _make_empty_inventory_cell()
			empty_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			empty_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
			inventory_grid.add_child(_wrap_inventory_square(empty_p))
	_update_inventory_header()


func _update_inventory_header() -> void:
	var capacity: int = GameState.get_inventory_capacity()
	inventory_title.text = "인벤토리 %d/%d" % [GameState.inventory.size(), capacity]
	if GameState.inventory.size() >= capacity:
		inventory_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.28))
	else:
		inventory_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))


func _wrap_inventory_square(inner: Control) -> AspectRatioContainer:
	var ar := AspectRatioContainer.new()
	ar.ratio = 1.0
	ar.custom_minimum_size = Vector2(float(INVENTORY_CELL_PX), float(INVENTORY_CELL_PX))
	ar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ar.add_child(inner)
	return ar


func _make_empty_inventory_cell() -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.12, 0.16, 0.85), Color(0.26, 0.30, 0.36), 4))
	return p


# ── 소켓/카드 팩토리 ──────────────────────
func _make_socket(slot: CoreData.CoreSlot) -> PartSocketUI:
	var socket := PartSocketUI.new()
	socket.slot_type = slot
	socket.part_dropped.connect(_on_socket_drop)
	socket.socket_selected.connect(_select_socket)
	return socket


func _make_card(_part: PartsData) -> PartCardUI:
	var card := PartCardUI.new()
	card.part_selected.connect(_select_inventory_part)
	return card


# ── 선택/액션 ─────────────────────────────
func _select_inventory_part(part: PartsData) -> void:
	_selected_inventory_part = part
	_selected_slot = SLOT_NONE
	_selected_skill = null
	_refresh_selection_visuals()
	_update_selection_detail()


func _select_socket(slot: CoreData.CoreSlot) -> void:
	_selected_slot = int(slot)
	_selected_inventory_part = null
	_selected_skill = null
	_refresh_selection_visuals()
	_update_selection_detail()


func _select_skill_preview(skill: SkillData) -> void:
	_selected_skill = skill
	_selected_inventory_part = null
	_selected_slot = GameState.get_slot_for_combat_skill(skill)
	_refresh_selection_visuals()
	_update_selection_detail()


func _clear_selection() -> void:
	_selected_inventory_part = null
	_selected_slot = SLOT_NONE
	_selected_skill = null
	_refresh_selection_visuals()
	_update_selection_detail()


func _refresh_selection_visuals() -> void:
	for part: PartsData in _inventory_cards:
		var card: PartCardUI = _inventory_cards[part]
		card.set_selected(part == _selected_inventory_part)
	for slot: CoreData.CoreSlot in _sockets:
		var socket: PartSocketUI = _sockets[slot]
		socket.set_selected(int(slot) == _selected_slot)
	_refresh_skill_preview()


func _update_selection_detail() -> void:
	if _selection_panel == null:
		return

	if _selected_skill != null:
		_update_skill_detail(_selected_skill)
	elif _selected_inventory_part != null:
		_update_part_detail(_selected_inventory_part)
	elif _selected_slot != SLOT_NONE:
		_update_slot_detail(_selected_slot)
	else:
		_selection_title.text = "선택 없음"
		_selection_body.text = "인벤토리 파츠나 장착 슬롯을 선택하세요."

	_refresh_action_buttons()


func _update_skill_detail(skill: SkillData) -> void:
	_selection_title.text = "스킬: %s" % skill.skill_name
	var part: PartsData = GameState.get_part_for_combat_skill(skill)
	var disable_reason: String = "파츠 파괴됨" if part != null and part.is_broken() else ""
	var lines: Array[String] = [
		"출처: %s" % _skill_source_text(skill),
		skill.combat_tooltip_text(disable_reason),
	]
	_selection_body.text = "\n".join(lines)


func _update_part_detail(part: PartsData) -> void:
	_selection_title.text = part.display_name()
	var target_slot: CoreData.CoreSlot = _slot_for_part_type(part.parts_type)
	if _selected_slot == int(CoreData.CoreSlot.EXTRA_ARM) and _part_matches_slot(part, CoreData.CoreSlot.EXTRA_ARM):
		target_slot = CoreData.CoreSlot.EXTRA_ARM
	var lines: Array[String] = [
		part.assembly_tooltip_text(),
		"장착 위치: %s" % _slot_display_name(target_slot),
	]
	if (part.parts_type == PartsData.PartsType.ARM_L or part.parts_type == PartsData.PartsType.ARM_R) and GameState.has_extra_arm_slot():
		lines.append("추가 팔 슬롯에도 장착 가능")
	if part.is_broken():
		lines.append("파손 상태: 장착 불가")
	else:
		var existing: PartsData = GameState.equipped_parts.get(target_slot)
		if existing != null:
			lines.append("교체 시 기존 파츠 파손: %s" % existing.display_name())
	_selection_body.text = "\n".join(lines)


func _update_slot_detail(slot_index: int) -> void:
	var slot: CoreData.CoreSlot = _slot_from_index(slot_index)
	var part: PartsData = GameState.equipped_parts.get(slot)
	_selection_title.text = "%s 슬롯" % _slot_display_name(slot)
	if part == null:
		_selection_body.text = "비어 있음"
		return
	var lines: Array[String] = [
		part.assembly_tooltip_text(),
		"해제하거나 교체하면 이 파츠는 파손 상태로 인벤토리에 돌아갑니다.",
	]
	_selection_body.text = "\n".join(lines)


func _refresh_action_buttons() -> void:
	if _equip_button == null or _unequip_button == null:
		return

	var can_equip: bool = false
	var equip_text: String = "장착"
	if _selected_inventory_part != null and not _selected_inventory_part.is_broken():
		var target_slot: CoreData.CoreSlot = _slot_for_part_type(_selected_inventory_part.parts_type)
		if _selected_slot == int(CoreData.CoreSlot.EXTRA_ARM) and _part_matches_slot(_selected_inventory_part, CoreData.CoreSlot.EXTRA_ARM):
			target_slot = CoreData.CoreSlot.EXTRA_ARM
		var existing: PartsData = GameState.equipped_parts.get(target_slot)
		can_equip = target_slot != CoreData.CoreSlot.EXTRA_ARM or GameState.has_extra_arm_slot()
		equip_text = "교체" if existing != null else "장착"
	_equip_button.text = equip_text
	_equip_button.disabled = not can_equip
	_equip_button.tooltip_text = "" if can_equip else "장착 가능한 인벤토리 파츠를 선택하세요."

	var can_unequip: bool = false
	if _selected_slot != SLOT_NONE:
		var slot_part: PartsData = GameState.equipped_parts.get(_selected_slot)
		can_unequip = slot_part != null and not GameState.is_inventory_full()
	_unequip_button.disabled = not can_unequip
	_unequip_button.tooltip_text = "" if can_unequip else "빈 슬롯이 필요합니다."
	_clear_button.disabled = _selected_inventory_part == null and _selected_slot == SLOT_NONE and _selected_skill == null


func _on_equip_selected_pressed() -> void:
	if _selected_inventory_part == null:
		return
	if _selected_inventory_part.is_broken():
		_set_hint("파손된 파츠는 장착할 수 없습니다.", Color(1.0, 0.45, 0.35))
		return
	var target_slot: CoreData.CoreSlot = _slot_for_part_type(_selected_inventory_part.parts_type)
	if _selected_slot == int(CoreData.CoreSlot.EXTRA_ARM) and _part_matches_slot(_selected_inventory_part, CoreData.CoreSlot.EXTRA_ARM):
		target_slot = CoreData.CoreSlot.EXTRA_ARM
	_on_socket_drop(_selected_inventory_part, target_slot)


func _on_unequip_selected_pressed() -> void:
	if _selected_slot == SLOT_NONE:
		return
	_on_socket_unequip(_slot_from_index(_selected_slot))


# ── 이벤트 핸들러 ────────────────────────
func _on_socket_drop(part: PartsData, slot: CoreData.CoreSlot) -> void:
	if part == null:
		return
	if part.is_broken():
		_set_hint("파손된 파츠는 장착할 수 없습니다.", Color(1.0, 0.45, 0.35))
		return
	if not _part_matches_slot(part, slot):
		_set_hint("%s 슬롯에는 맞지 않는 파츠입니다." % _slot_display_name(slot), Color(1.0, 0.45, 0.35))
		return

	var existing: PartsData = GameState.equipped_parts[slot]
	if not GameState.remove_from_inventory(part):
		_set_hint("인벤토리에서 파츠를 찾을 수 없습니다.", Color(1.0, 0.45, 0.35))
		return

	if existing != null:
		if existing.durability > 0:
			existing.durability = 0
			EventBus.part_durability_changed.emit(existing)
		GameState.add_to_inventory(existing)

	GameState.equip_part(part, slot)
	_selected_inventory_part = null
	_selected_slot = int(slot)
	_selected_skill = null
	_build_sockets()
	_rebuild_inventory()
	_update_payload()
	_refresh_selection_visuals()
	_update_selection_detail()


func _on_socket_unequip(slot: CoreData.CoreSlot) -> void:
	var part: PartsData = GameState.equipped_parts[slot]
	if part == null:
		return
	if GameState.is_inventory_full():
		_set_hint("인벤토리가 가득 차서 해제할 수 없습니다.", Color(1.0, 0.72, 0.28))
		_update_selection_detail()
		return

	GameState.unequip_part(slot)
	if part.durability > 0:
		part.durability = 0
		EventBus.part_durability_changed.emit(part)
	GameState.add_to_inventory(part)

	_selected_inventory_part = part
	_selected_slot = SLOT_NONE
	_selected_skill = null
	_build_sockets()
	_rebuild_inventory()
	_update_payload()
	_refresh_selection_visuals()
	_update_selection_detail()


func _on_inventory_add_failed(part: PartsData) -> void:
	var part_name: String = part.display_name() if part != null else "파츠"
	_set_hint("인벤토리 가득 참: %s 유실" % part_name, Color(1.0, 0.45, 0.35))
	_rebuild_inventory()
	_update_selection_detail()


func _on_close_pressed() -> void:
	get_tree().change_scene_to_file(DUNGEON_MAP_SCENE)


# ── 하중/행동력 표시 갱신 ─────────────────
func _update_payload() -> void:
	var cur: float = GameState.current_payload
	var max_p: float = GameState.get_max_payload()
	payload_label.text = "하중: %.0f / %.0f" % [cur, max_p]

	payload_bar.max_value = max_p
	payload_bar.value = cur

	if cur > max_p:
		payload_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		_set_hint("하중 초과: LEG 스킬 출력 -20%", Color(1.0, 0.4, 0.4))
	else:
		payload_label.remove_theme_color_override("font_color")
		_set_hint("파츠 선택 후 장착하거나 슬롯으로 드래그하세요.", Color(0.65, 0.65, 0.65))

	_update_ap_orbs()
	_refresh_skill_preview()


func _update_ap_orbs() -> void:
	if _ap_orbs_row == null:
		return
	for child: Node in _ap_orbs_row.get_children():
		child.queue_free()

	var tag := Label.new()
	tag.text = "행동력"
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ap_orbs_row.add_child(tag)

	var ap: int = GameState.get_max_action_count()
	for _i: int in range(ap):
		var orb := ColorRect.new()
		orb.custom_minimum_size = Vector2(18.0, 18.0)
		orb.color = Color(0.35, 0.85, 0.45, 1.0)
		_ap_orbs_row.add_child(orb)


# ── 표시 헬퍼 ─────────────────────────────
func _set_hint(text: String, color: Color) -> void:
	hint_label.text = text
	hint_label.add_theme_color_override("font_color", color)


func _make_panel_style(bg: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.set_corner_radius_all(radius)
	return style


func _slot_for_part_type(parts_type: PartsData.PartsType) -> CoreData.CoreSlot:
	match parts_type:
		PartsData.PartsType.ARM_L: return CoreData.CoreSlot.ARM_L
		PartsData.PartsType.ARM_R: return CoreData.CoreSlot.ARM_R
		PartsData.PartsType.BACK: return CoreData.CoreSlot.BACK
		PartsData.PartsType.LEG: return CoreData.CoreSlot.LEG
	return CoreData.CoreSlot.ARM_L


func _part_matches_slot(part: PartsData, slot: CoreData.CoreSlot) -> bool:
	if part == null:
		return false
	if slot == CoreData.CoreSlot.EXTRA_ARM:
		return part.parts_type == PartsData.PartsType.ARM_L or part.parts_type == PartsData.PartsType.ARM_R
	return _slot_for_part_type(part.parts_type) == slot


func _slot_from_index(slot_index: int) -> CoreData.CoreSlot:
	match slot_index:
		CoreData.CoreSlot.ARM_L: return CoreData.CoreSlot.ARM_L
		CoreData.CoreSlot.ARM_R: return CoreData.CoreSlot.ARM_R
		CoreData.CoreSlot.EXTRA_ARM: return CoreData.CoreSlot.EXTRA_ARM
		CoreData.CoreSlot.BACK: return CoreData.CoreSlot.BACK
		CoreData.CoreSlot.LEG: return CoreData.CoreSlot.LEG
	return CoreData.CoreSlot.ARM_L


func _slot_display_name(slot: int) -> String:
	match slot:
		CoreData.CoreSlot.ARM_L: return "왼팔"
		CoreData.CoreSlot.ARM_R: return "오른팔"
		CoreData.CoreSlot.EXTRA_ARM: return "추가 팔"
		CoreData.CoreSlot.BACK: return "등"
		CoreData.CoreSlot.LEG: return "다리"
	return "알 수 없음"


func _slot_short(slot: int) -> String:
	match slot:
		CoreData.CoreSlot.ARM_L: return "왼"
		CoreData.CoreSlot.ARM_R: return "오"
		CoreData.CoreSlot.EXTRA_ARM: return "추"
		CoreData.CoreSlot.BACK: return "등"
		CoreData.CoreSlot.LEG: return "다"
	return "?"


func _skill_source_short(skill: SkillData) -> String:
	if skill == GameState.active_basic_attack:
		return "기본"
	if skill == GameState.active_part_ability:
		return "어빌"
	var slot: int = GameState.get_slot_for_combat_skill(skill)
	if slot >= 0:
		return _slot_short(slot)
	return "?"


func _skill_source_text(skill: SkillData) -> String:
	if skill == GameState.active_basic_attack:
		return "기본 코어 공격"
	if skill == GameState.active_part_ability:
		return "파츠 활용 어빌리티"
	var slot: int = GameState.get_slot_for_combat_skill(skill)
	if slot >= 0:
		var part: PartsData = GameState.get_part_for_combat_skill(skill)
		var part_name: String = part.display_name() if part != null else "파츠"
		return "%s 슬롯 · %s" % [_slot_display_name(slot), part_name]
	return "알 수 없음"


func _skill_preview_tooltip(skill: SkillData) -> String:
	var part: PartsData = GameState.get_part_for_combat_skill(skill)
	var disable_reason: String = "파츠 파괴됨" if part != null and part.is_broken() else ""
	return "%s\n%s" % [_skill_source_text(skill), skill.combat_tooltip_text(disable_reason)]


func _skill_type_color(skill: SkillData) -> Color:
	match skill.skill_type:
		SkillData.SkillType.ATTACK: return Color(0.96, 0.38, 0.28, 1.0)
		SkillData.SkillType.DEFENSE: return Color(0.30, 0.62, 0.96, 1.0)
		SkillData.SkillType.HEAL: return Color(0.34, 0.88, 0.50, 1.0)
		SkillData.SkillType.PASSIVE: return Color(0.92, 0.72, 0.28, 1.0)
	return Color(0.78, 0.78, 0.80, 1.0)
