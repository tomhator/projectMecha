class_name PartCardUI
extends Panel

# ── 내부 변수 ────────────────────────────
var part_data: PartsData = null

# 레이블 참조 (내부에서 직접 생성)
var _part_name_label: Label
var _type_label: Label
var _skill_label: Label
var _weight_label: Label

# ── 스타일 상수 ──────────────────────────
const COLOR_BG: Color           = Color(0.18, 0.22, 0.28, 1.0)
const COLOR_BG_HOVER: Color     = Color(0.25, 0.32, 0.42, 1.0)
const COLOR_BORDER: Color       = Color(0.45, 0.50, 0.55, 1.0)

const COLOR_COMMON: Color = Color(0.70, 0.70, 0.70, 1.0)
const COLOR_RARE: Color   = Color(0.35, 0.60, 0.95, 1.0)
const COLOR_EPIC: Color   = Color(0.75, 0.35, 0.95, 1.0)

# ── 스타일박스 ───────────────────────────
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat

# ── 초기화 ──────────────────────────────
func _ready() -> void:
	custom_minimum_size = Vector2(220, 80)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_styles()
	_build_ui()
	_apply_style(_style_normal)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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

	_part_name_label = Label.new()
	_part_name_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_part_name_label)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 10)
	_type_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(_type_label)

	_skill_label = Label.new()
	_skill_label.add_theme_font_size_override("font_size", 10)
	_skill_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	_skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skill_label.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(_skill_label)

	_weight_label = Label.new()
	_weight_label.add_theme_font_size_override("font_size", 10)
	_weight_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(_weight_label)

# ── 퍼블릭 ───────────────────────────────
func setup(p: PartsData) -> void:
	part_data = p
	# _build_ui가 _ready에서 실행되므로, 레이블이 아직 없을 수 있음
	# _ready 이후에 setup이 호출되는 경우만 refresh 실행
	if _part_name_label != null:
		_refresh_display()

# ── 드래그 발신 ──────────────────────────
func _get_drag_data(_pos: Vector2) -> Variant:
	if part_data == null:
		return null

	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(180, 50)

	var style_prev := StyleBoxFlat.new()
	style_prev.bg_color = Color(0.20, 0.30, 0.45, 0.90)
	style_prev.set_border_width_all(2)
	style_prev.border_color = _grade_color()
	style_prev.set_corner_radius_all(4)
	preview.add_theme_stylebox_override("panel", style_prev)

	var lbl := Label.new()
	lbl.text = part_data.parts_name
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	preview.add_child(lbl)

	set_drag_preview(preview)
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

	var damage_tag: String = " ⚠손상" if part_data.is_damaged else ""
	_part_name_label.text = part_data.parts_name + damage_tag
	_part_name_label.add_theme_color_override("font_color", _grade_color())

	_type_label.text = "[%s]" % PartsData.PartsType.keys()[part_data.parts_type]
	_skill_label.text = part_data.parts_description
	_weight_label.text = "하중 %.0f" % part_data.parts_weight

	# 테두리를 등급 색으로
	_style_normal.border_color = _grade_color()
	_apply_style(_style_normal)

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
