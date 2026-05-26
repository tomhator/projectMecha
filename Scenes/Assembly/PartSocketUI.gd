class_name PartSocketUI
extends Panel

# ── 시그널 ──────────────────────────────
signal part_unequipped(slot: CoreData.CoreSlot)
signal part_dropped(part: PartsData, slot: CoreData.CoreSlot)
signal socket_selected(slot: CoreData.CoreSlot)

# ── 익스포트 ─────────────────────────────
@export var slot_type: CoreData.CoreSlot = CoreData.CoreSlot.ARM_L

# ── 내부 변수 ────────────────────────────
var equipped_part: PartsData = null
var _is_selected: bool = false

# 아이콘 참조 (내부에서 직접 생성)
var _icon_rect: TextureRect
var _condition_marker: Panel

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
var _style_selected: StyleBoxFlat

# ── 초기화 ──────────────────────────────
func _ready() -> void:
	add_to_group("part_socket_drag_highlight")
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 부모가 레이아웃 전달하기 전까지 최소 터치 영역
	custom_minimum_size = Vector2(72, 72)
	tooltip_text = _slot_tooltip_text()

	_build_styles()
	_build_ui()
	_apply_style(_style_empty)

	gui_input.connect(_on_gui_input)


func on_drag_inventory_part(part: PartsData) -> void:
	if part == null:
		end_drag_inventory_highlight()
		return
	if not part.is_broken() and _part_type_matches(part.parts_type):
		_apply_style(_style_hover)
	else:
		_refresh_display()


func end_drag_inventory_highlight() -> void:
	_refresh_display()


# 부모(AssemblyScene)가 ChassisPanel 너비에 맞춰 호출
func set_layout_size(s: Vector2) -> void:
	custom_minimum_size = s

# ── UI 자체 생성 ─────────────────────────
func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	_icon_rect = TextureRect.new()
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_icon_rect)

	_condition_marker = Panel.new()
	_condition_marker.anchor_left = 1.0
	_condition_marker.anchor_top = 0.0
	_condition_marker.anchor_right = 1.0
	_condition_marker.anchor_bottom = 0.0
	_condition_marker.offset_left = -18.0
	_condition_marker.offset_top = 8.0
	_condition_marker.offset_right = -8.0
	_condition_marker.offset_bottom = 18.0
	_condition_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_condition_marker.visible = false
	add_child(_condition_marker)

# ── 퍼블릭 ───────────────────────────────
func set_equipped(part: PartsData) -> void:
	equipped_part = part
	_refresh_display()

func clear_equipped() -> void:
	equipped_part = null
	_refresh_display()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_refresh_display()

# ── 드래그앤드롭 수신 ────────────────────
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not data is Dictionary or not data.has("part"):
		return false
	var part: PartsData = data["part"]
	var compatible: bool = not part.is_broken() and _part_type_matches(part.parts_type)
	if compatible:
		_apply_style(_style_hover)
	else:
		_apply_style(_style_reject)
	return compatible

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var part: PartsData = data["part"]
	part_dropped.emit(part, slot_type)

# ── 클릭 선택 ──────────────────────────────
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			socket_selected.emit(slot_type)

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

func _slot_tooltip_text() -> String:
	match slot_type:
		CoreData.CoreSlot.ARM_L: return "왼팔 슬롯"
		CoreData.CoreSlot.ARM_R: return "오른팔 슬롯"
		CoreData.CoreSlot.BACK: return "등 슬롯"
		CoreData.CoreSlot.LEG: return "다리 슬롯"
	return "파츠 슬롯"

func _refresh_display() -> void:
	if equipped_part == null:
		_icon_rect.texture = _placeholder_icon_texture()
		tooltip_text = _slot_tooltip_text()
		_refresh_condition_marker(Color.TRANSPARENT)
		_apply_style(_style_empty)
	else:
		_icon_rect.texture = equipped_part.icon_texture()
		tooltip_text = equipped_part.assembly_tooltip_text()
		var marker_color: Color
		if equipped_part.is_broken():
			marker_color = Color(1.0, 0.3, 0.3)
		elif equipped_part.is_worn():
			marker_color = Color(1.0, 0.72, 0.28)
		else:
			marker_color = Color.TRANSPARENT
		_refresh_condition_marker(marker_color)
		_apply_style(_style_filled)
	if _is_selected:
		_apply_style(_style_selected)


func _refresh_condition_marker(color: Color) -> void:
	_condition_marker.visible = color.a > 0.0
	if not _condition_marker.visible:
		return
	var marker_style := StyleBoxFlat.new()
	marker_style.bg_color = color
	marker_style.set_border_width_all(1)
	marker_style.border_color = color.lightened(0.22)
	marker_style.set_corner_radius_all(2)
	_condition_marker.add_theme_stylebox_override("panel", marker_style)


func _placeholder_icon_texture() -> Texture2D:
	var side: int = 64
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var outline := Color(0.42, 0.46, 0.54, 0.55)
	var body := Color(0.34, 0.38, 0.46, 0.30)
	image.fill_rect(Rect2i(5, 5, side - 10, side - 10), outline)
	image.fill_rect(Rect2i(9, 9, side - 18, side - 18), Color(0.0, 0.0, 0.0, 0.0))
	match slot_type:
		CoreData.CoreSlot.ARM_L:
			image.fill_rect(Rect2i(15, 13, 22, 16), body)
			image.fill_rect(Rect2i(28, 24, 14, 28), body)
			image.fill_rect(Rect2i(31, 43, 22, 10), body)
		CoreData.CoreSlot.ARM_R:
			image.fill_rect(Rect2i(27, 13, 22, 16), body)
			image.fill_rect(Rect2i(22, 24, 14, 28), body)
			image.fill_rect(Rect2i(11, 43, 22, 10), body)
		CoreData.CoreSlot.BACK:
			image.fill_rect(Rect2i(13, 14, 38, 16), body)
			image.fill_rect(Rect2i(18, 26, 28, 26), body)
		CoreData.CoreSlot.LEG:
			image.fill_rect(Rect2i(16, 12, 32, 14), body)
			image.fill_rect(Rect2i(16, 25, 12, 25), body)
			image.fill_rect(Rect2i(36, 25, 12, 25), body)
	return ImageTexture.create_from_image(image)

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

	_style_selected = _style_empty.duplicate()
	_style_selected.bg_color = Color(0.30, 0.28, 0.16, 1.0)
	_style_selected.border_color = Color(1.0, 0.82, 0.35, 1.0)
	_style_selected.set_border_width_all(3)

func _apply_style(style: StyleBoxFlat) -> void:
	add_theme_stylebox_override("panel", style)
