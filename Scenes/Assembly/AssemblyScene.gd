extends Control

const DUNGEON_MAP_SCENE: String = "res://Scenes/Dungeon/DungeonMapScene.tscn"

# ── 노드 레퍼런스 ────────────────────────
@onready var chassis_panel: VBoxContainer   = $MainContainer/LeftColumn/ChassisPanel
@onready var inventory_grid: GridContainer  = $MainContainer/RightColumn/ScrollContainer/InventoryGrid
@onready var payload_label: Label           = $PayloadLabel
@onready var payload_bar: ProgressBar       = $PayloadBar
@onready var close_button: Button           = $CloseButton
@onready var hint_label: Label              = $HintLabel

# ── 소켓 맵 ─────────────────────────────
var _sockets: Dictionary = {}  # CoreData.CoreSlot → PartSocketUI

# 십자 그리드 3열 — ChassisPanel 너비로 셀 크기 계산 (코어는 정사각형)
const CHASSIS_COL_SEP: int = 8
const CELL_MIN: int = 72
const CELL_MAX: int = 220

const INVENTORY_COLS: int = 5
const INVENTORY_ROWS: int = 6
const INVENTORY_SLOTS: int = INVENTORY_COLS * INVENTORY_ROWS

var _chassis_spacers: Array[Control] = []
var _core_placeholder_panel: Panel = null

# ── 초기화 ──────────────────────────────
func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	if not chassis_panel.resized.is_connected(_on_chassis_resized):
		chassis_panel.resized.connect(_on_chassis_resized)
	_build_sockets()
	_rebuild_inventory()
	_update_payload()
	call_deferred("_refresh_chassis_layout")

# ── 소켓 구성 (십자 배치) ─────────────────
func _build_sockets() -> void:
	for child: Node in chassis_panel.get_children():
		child.queue_free()
	_sockets.clear()
	_chassis_spacers.clear()
	_core_placeholder_panel = null

	# Row 1: [빈칸] [BACK] [빈칸]
	var row1 := _make_chassis_row()
	row1.add_child(_make_socket_spacer())
	var back_socket := _make_socket(CoreData.CoreSlot.BACK)
	_sockets[CoreData.CoreSlot.BACK] = back_socket
	row1.add_child(back_socket)
	row1.add_child(_make_socket_spacer())
	chassis_panel.add_child(row1)

	# Row 2: [ARM_R] [코어 플레이스홀더] [ARM_L]
	# 코어가 카메라를 바라보므로 메크 기준 오른팔이 화면 왼쪽에 위치
	var row2 := _make_chassis_row()
	var armr_socket := _make_socket(CoreData.CoreSlot.ARM_R)
	_sockets[CoreData.CoreSlot.ARM_R] = armr_socket
	row2.add_child(armr_socket)
	row2.add_child(_make_core_placeholder())
	var arml_socket := _make_socket(CoreData.CoreSlot.ARM_L)
	_sockets[CoreData.CoreSlot.ARM_L] = arml_socket
	row2.add_child(arml_socket)
	chassis_panel.add_child(row2)

	# Row 3: [빈칸] [LEG] [빈칸]
	var row3 := _make_chassis_row()
	row3.add_child(_make_socket_spacer())
	var leg_socket := _make_socket(CoreData.CoreSlot.LEG)
	_sockets[CoreData.CoreSlot.LEG] = leg_socket
	row3.add_child(leg_socket)
	row3.add_child(_make_socket_spacer())
	chassis_panel.add_child(row3)

	# 트리 진입(_ready) 완료 후 장착 파츠 반영
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
	row.add_theme_constant_override("separation", 8)
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
	style.bg_color = Color(0.12, 0.18, 0.28, 1.0)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.65, 0.90, 1.0)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   = 8
	vbox.offset_right  = -8
	vbox.offset_top    = 8
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
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	return panel

# ── 인벤토리 재구성 ──────────────────────
func _rebuild_inventory() -> void:
	for child: Node in inventory_grid.get_children():
		child.queue_free()

	var parts: Array = GameState.inventory.duplicate()
	var idx: int = 0
	while idx < INVENTORY_SLOTS:
		if idx < parts.size():
			var part: PartsData = parts[idx]
			var card := _make_card(part)
			card.custom_minimum_size = Vector2(104.0, 76.0)
			inventory_grid.add_child(card)
			card.setup(part)
		else:
			inventory_grid.add_child(_make_empty_inventory_cell())
		idx += 1


func _make_empty_inventory_cell() -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(104.0, 76.0)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.12, 0.14, 0.18, 0.85)
	st.set_border_width_all(1)
	st.border_color = Color(0.28, 0.32, 0.38, 1.0)
	st.set_corner_radius_all(4)
	p.add_theme_stylebox_override("panel", st)
	return p

# ── 소켓 팩토리 ─────────────────────────
# 각 PartSocketUI는 _ready()에서 자체적으로 UI를 구성한다.
func _make_socket(slot: CoreData.CoreSlot) -> PartSocketUI:
	var socket := PartSocketUI.new()
	socket.slot_type = slot
	socket.part_dropped.connect(_on_socket_drop)
	socket.part_unequipped.connect(_on_socket_unequip)
	return socket

# ── 카드 팩토리 ─────────────────────────
# 각 PartCardUI는 _ready()에서 자체적으로 UI를 구성한다.
# setup()은 add_child() 이후 트리 진입 → _ready() 실행 뒤 호출한다.
func _make_card(_part: PartsData) -> PartCardUI:
	var card := PartCardUI.new()
	return card

# ── 이벤트 핸들러 ────────────────────────
func _on_socket_drop(part: PartsData, slot: CoreData.CoreSlot) -> void:
	# 기존 슬롯 파츠 → 인벤토리 반환
	var existing: PartsData = GameState.equipped_parts[slot]
	if existing != null:
		GameState.inventory.append(existing)

	GameState.inventory.erase(part)
	GameState.equip_part(part, slot)
	EventBus.inventory_changed.emit(GameState.inventory)

	# 소켓 시각 업데이트
	_sockets[slot].set_equipped(part)
	_rebuild_inventory()
	_update_payload()

func _on_socket_unequip(slot: CoreData.CoreSlot) -> void:
	var part: PartsData = GameState.equipped_parts[slot]
	if part == null:
		return
	GameState.unequip_part(slot)
	GameState.inventory.append(part)
	EventBus.inventory_changed.emit(GameState.inventory)

	_sockets[slot].clear_equipped()
	_rebuild_inventory()
	_update_payload()

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file(DUNGEON_MAP_SCENE)

# ── 하중 표시 갱신 ────────────────────────
func _update_payload() -> void:
	var cur: float = GameState.current_payload
	var max_p: float = GameState.current_core.core_max_payload
	payload_label.text = "하중: %.0f / %.0f" % [cur, max_p]

	payload_bar.max_value = max_p
	payload_bar.value = cur

	# 하중 초과 경고
	if cur > max_p:
		payload_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		hint_label.text = "⚠ 하중 초과! 다리 파츠 등을 해제하세요."
		hint_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	else:
		payload_label.remove_theme_color_override("font_color")
		hint_label.text = "파츠를 소켓으로 끌어다 놓아 장착하세요. 소켓 클릭으로 해제."
		hint_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
