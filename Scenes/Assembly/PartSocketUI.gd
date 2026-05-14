class_name PartSocketUI
extends Panel

# ── 시그널 ──────────────────────────────
signal part_unequipped(slot: CoreData.CoreSlot)
signal part_dropped(part: PartsData, slot: CoreData.CoreSlot)

# ── 익스포트 ─────────────────────────────
@export var slot_type: CoreData.CoreSlot = CoreData.CoreSlot.ARM_L

# ── 내부 변수 ────────────────────────────
var equipped_part: PartsData = null

# 레이블 참조 (내부에서 직접 생성)
var _slot_name_label: Label
var _part_name_label: Label
var _skill_label: Label
var _durability_label: Label

# ── 스타일 상수 ──────────────────────────
const COLOR_EMPTY: Color             = Color(0.25, 0.25, 0.30, 1.0)
const COLOR_FILLED: Color            = Color(0.20, 0.35, 0.50, 1.0)
const COLOR_HOVER: Color             = Color(0.15, 0.50, 0.15, 1.0)
const COLOR_REJECT: Color            = Color(0.50, 0.15, 0.15, 1.0)
const COLOR_BORDER: Color            = Color(0.50, 0.50, 0.55, 1.0)
const COLOR_BORDER_HOVER: Color      = Color(0.30, 0.90, 0.30, 1.0)
const COLOR_BORDER_REJECT: Color     = Color(0.90, 0.30, 0.30, 1.0)
const COLOR_BORDER_FILLED: Color     = Color(0.35, 0.60, 0.90, 1.0)

# ── 스타일박스 ───────────────────────────
var _style_empty: StyleBoxFlat
var _style_filled: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_reject: StyleBoxFlat

# ── 초기화 ──────────────────────────────
func _ready() -> void:
	add_to_group("part_socket_drag_highlight")
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 부모가 레이아웃 전달하기 전까지 최소 터치 영역
	custom_minimum_size = Vector2(72, 72)

	_build_styles()
	_build_ui()
	_apply_style(_style_empty)

	gui_input.connect(_on_gui_input)


func on_drag_inventory_part(part: PartsData) -> void:
	if part == null:
		end_drag_inventory_highlight()
		return
	if _part_type_matches(part.parts_type):
		_apply_style(_style_hover)
	else:
		_refresh_display()


func end_drag_inventory_highlight() -> void:
	_refresh_display()


# 부모(AssemblyScene)가 ChassisPanel 너비에 맞춰 호출
func set_layout_size(s: Vector2) -> void:
	custom_minimum_size = s
	if _skill_label != null:
		_skill_label.custom_minimum_size = Vector2(maxf(0.0, s.x - 16.0), 0.0)

# ── UI 자체 생성 ─────────────────────────
func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   = 8
	vbox.offset_right  = -8
	vbox.offset_top    = 6
	vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	_slot_name_label = Label.new()
	_slot_name_label.add_theme_font_size_override("font_size", 11)
	_slot_name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_slot_name_label.text = _slot_display_name()
	vbox.add_child(_slot_name_label)

	_part_name_label = Label.new()
	_part_name_label.add_theme_font_size_override("font_size", 14)
	_part_name_label.text = "빈 슬롯"
	vbox.add_child(_part_name_label)

	_skill_label = Label.new()
	_skill_label.add_theme_font_size_override("font_size", 10)
	_skill_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	_skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skill_label.custom_minimum_size = Vector2(1, 0)
	vbox.add_child(_skill_label)

	_durability_label = Label.new()
	_durability_label.add_theme_font_size_override("font_size", 10)
	_durability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_durability_label)

# ── 퍼블릭 ───────────────────────────────
func set_equipped(part: PartsData) -> void:
	equipped_part = part
	_refresh_display()

func clear_equipped() -> void:
	equipped_part = null
	_refresh_display()

# ── 드래그앤드롭 수신 ────────────────────
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not data is Dictionary or not data.has("part"):
		return false
	var part: PartsData = data["part"]
	var compatible: bool = _part_type_matches(part.parts_type)
	if compatible:
		_apply_style(_style_hover)
	else:
		_apply_style(_style_reject)
	return compatible

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var part: PartsData = data["part"]
	part_dropped.emit(part, slot_type)

# ── 클릭으로 장착 해제 ───────────────────
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if equipped_part != null:
				part_unequipped.emit(slot_type)

# ── 드래그 이탈 시: 인벤 드래그 중이면 전역 하이라이트 규칙으로 복귀 (AssemblyScene이 DRAG_END에서 정리)
func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		if EventBus.assembly_drag_inventory_part != null:
			on_drag_inventory_part(EventBus.assembly_drag_inventory_part)
		else:
			_refresh_display()


# ── 헬퍼 ─────────────────────────────────
func _part_type_matches(parts_type: PartsData.PartsType) -> bool:
	match slot_type:
		CoreData.CoreSlot.ARM_L: return parts_type == PartsData.PartsType.ARM_L
		CoreData.CoreSlot.ARM_R: return parts_type == PartsData.PartsType.ARM_R
		CoreData.CoreSlot.BACK:  return parts_type == PartsData.PartsType.BACK
		CoreData.CoreSlot.LEG:   return parts_type == PartsData.PartsType.LEG
	return false

func _slot_display_name() -> String:
	match slot_type:
		CoreData.CoreSlot.ARM_L: return "[ 왼팔 ]"
		CoreData.CoreSlot.ARM_R: return "[ 오른팔 ]"
		CoreData.CoreSlot.BACK:  return "[ 등 ]"
		CoreData.CoreSlot.LEG:   return "[ 다리 ]"
	return "[ 슬롯 ]"

func _refresh_display() -> void:
	if equipped_part == null:
		_part_name_label.text = "빈 슬롯"
		_part_name_label.remove_theme_color_override("font_color")
		_skill_label.text = ""
		_durability_label.text = ""
		_apply_style(_style_empty)
	else:
		_part_name_label.text = equipped_part.parts_name
		if equipped_part.is_broken():
			_part_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		elif equipped_part.is_worn():
			_part_name_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.28))
		else:
			_part_name_label.remove_theme_color_override("font_color")
		_skill_label.text = equipped_part.parts_description
		var dur_str: String = "■".repeat(equipped_part.durability) + "□".repeat(equipped_part.max_durability - equipped_part.durability)
		_durability_label.text = dur_str
		if equipped_part.is_broken():
			_durability_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		elif equipped_part.is_worn():
			_durability_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.28))
		else:
			_durability_label.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
		_apply_style(_style_filled)

func _build_styles() -> void:
	_style_empty = StyleBoxFlat.new()
	_style_empty.bg_color = COLOR_EMPTY
	_style_empty.set_border_width_all(2)
	_style_empty.border_color = COLOR_BORDER
	_style_empty.set_corner_radius_all(4)

	_style_filled = _style_empty.duplicate()
	_style_filled.bg_color = COLOR_FILLED
	_style_filled.border_color = COLOR_BORDER_FILLED

	_style_hover = _style_empty.duplicate()
	_style_hover.bg_color = COLOR_HOVER
	_style_hover.border_color = COLOR_BORDER_HOVER
	_style_hover.set_border_width_all(3)

	_style_reject = _style_empty.duplicate()
	_style_reject.bg_color = COLOR_REJECT
	_style_reject.border_color = COLOR_BORDER_REJECT
	_style_reject.set_border_width_all(3)

func _apply_style(style: StyleBoxFlat) -> void:
	add_theme_stylebox_override("panel", style)
