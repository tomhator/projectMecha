class_name PartCardUI
extends Panel

# ── 내부 변수 ────────────────────────────
var part_data: PartsData = null

var _icon_rect: TextureRect
var _condition_marker: Panel

# ── 스타일 상수 ──────────────────────────
const COLOR_BG: Color           = Color(0.18, 0.22, 0.28, 1.0)
const COLOR_BG_HOVER: Color     = Color(0.25, 0.32, 0.42, 1.0)
const COLOR_BORDER: Color       = Color(0.45, 0.50, 0.55, 1.0)

const COLOR_COMMON: Color  = Color(0.70, 0.70, 0.70, 1.0)
const COLOR_RARE: Color    = Color(0.35, 0.60, 0.95, 1.0)
const COLOR_EPIC: Color    = Color(0.75, 0.35, 0.95, 1.0)

const COLOR_WARN: Color    = Color(1.0, 0.6, 0.1)
const COLOR_BROKEN: Color  = Color(0.9, 0.2, 0.2)

# ── 스타일박스 ───────────────────────────
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat

# ── 초기화 ──────────────────────────────
func _ready() -> void:
	custom_minimum_size = Vector2(72, 72)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_build_styles()
	_build_ui()
	_apply_style(_style_normal)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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
func setup(p: PartsData) -> void:
	part_data = p
	if _icon_rect != null:
		_refresh_display()

# ── 드래그 발신 ──────────────────────────
func _get_drag_data(_pos: Vector2) -> Variant:
	if part_data == null:
		return null

	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(88, 88)

	var style_prev := StyleBoxFlat.new()
	style_prev.bg_color = Color(0.20, 0.30, 0.45, 0.90)
	style_prev.set_border_width_all(2)
	style_prev.border_color = _grade_color()
	style_prev.set_corner_radius_all(4)
	preview.add_theme_stylebox_override("panel", style_prev)

	var icon := TextureRect.new()
	icon.texture = part_data.icon_texture(72)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 10.0
	icon.offset_right = -10.0
	icon.offset_top = 10.0
	icon.offset_bottom = -10.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(icon)

	set_drag_preview(preview)
	EventBus.assembly_drag_inventory_part = part_data
	get_tree().call_group("part_socket_drag_highlight", "on_drag_inventory_part", part_data)
	return { "part": part_data }

# ── 호버 피드백 ──────────────────────────
func _on_mouse_entered() -> void:
	_apply_style(_style_hover)

func _on_mouse_exited() -> void:
	_apply_style(_style_normal)


# ── 헬퍼 ─────────────────────────────────
func _refresh_display() -> void:
	if part_data == null:
		return

	_icon_rect.texture = part_data.icon_texture()
	tooltip_text = part_data.assembly_tooltip_text()
	var marker_color: Color
	if part_data.is_broken():
		marker_color = COLOR_BROKEN
	elif part_data.is_worn():
		marker_color = COLOR_WARN
	else:
		marker_color = Color.TRANSPARENT
	_refresh_condition_marker(marker_color)

	# 테두리 등급 색
	_style_normal.border_color = _grade_color()
	_style_hover.border_color = _grade_color().lightened(0.12)
	_apply_style(_style_normal)


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


func _grade_color() -> Color:
	if part_data == null:
		return COLOR_BORDER
	match part_data.parts_grade:
		PartsData.PartsGrade.RARE: return COLOR_RARE
		PartsData.PartsGrade.EPIC: return COLOR_EPIC
		_: return COLOR_COMMON


func _build_styles() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = COLOR_BG
	_style_normal.set_border_width_all(2)
	_style_normal.border_color = COLOR_BORDER
	_style_normal.set_corner_radius_all(4)

	_style_hover = _style_normal.duplicate()
	_style_hover.bg_color = COLOR_BG_HOVER


func _apply_style(style: StyleBoxFlat) -> void:
	add_theme_stylebox_override("panel", style)
