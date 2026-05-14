class_name PartCardUI
extends Panel

# ── 내부 변수 ────────────────────────────
var part_data: PartsData = null

var _part_name_label: Label
var _type_label: Label
var _skill_label: Label
var _weight_label: Label
var _durability_label: Label
var _affix_label: Label

# ── 스타일 상수 ──────────────────────────
const COLOR_BG: Color           = Color(0.18, 0.22, 0.28, 1.0)
const COLOR_BG_HOVER: Color     = Color(0.25, 0.32, 0.42, 1.0)
const COLOR_BORDER: Color       = Color(0.45, 0.50, 0.55, 1.0)

const COLOR_COMMON: Color  = Color(0.70, 0.70, 0.70, 1.0)
const COLOR_RARE: Color    = Color(0.35, 0.60, 0.95, 1.0)
const COLOR_EPIC: Color    = Color(0.75, 0.35, 0.95, 1.0)

const COLOR_WARN: Color    = Color(1.0, 0.6, 0.1)
const COLOR_BROKEN: Color  = Color(0.9, 0.2, 0.2)
const COLOR_DUR_OK: Color  = Color(0.3, 0.85, 0.4)
const COLOR_AFFIX: Color   = Color(0.85, 0.75, 1.0)

const PREFIX_TABLE: Array[Array] = [
	[0.70, 0.84, "낡은"],
	[0.85, 0.99, ""],
	[1.00, 1.14, "정밀한"],
	[1.15, 1.29, "강화된"],
	[1.30, 1.50, "완벽한"],
]

const AFFIX_NAMES: Dictionary = {
	"evolution_lord":    "진화 군주",
	"mindless":          "무지성",
	"greedy":            "과한 욕심",
	"productive":        "생산성 향상",
	"meticulous":        "꼼꼼한 설계",
	"overload":          "과부하 모드",
	"counter_instinct":  "반격 본능",
	"gambler":           "도박사",
	"lifedrain":         "흡수 코팅",
	"momentum":          "탄력",
	"serious_punch":     "진심펀치",
	"zombie_process":    "좀비 프로세스",
	"kernel_panic":      "커널 패닉",
	"undefined_behavior":"개발자도 모름",
	"backdoor":          "백도어",
}

# ── 스타일박스 ───────────────────────────
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat

# ── 초기화 ──────────────────────────────
func _ready() -> void:
	custom_minimum_size = Vector2(220, 110)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_build_styles()
	_build_ui()
	_apply_style(_style_normal)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_on_resized)
	_on_resized()

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

	# 줄 1: 이름 + 접두사 + 상태 태그
	_part_name_label = Label.new()
	_part_name_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_part_name_label)

	# 줄 2: 타입
	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 10)
	_type_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(_type_label)

	# 줄 3: 스킬 설명
	_skill_label = Label.new()
	_skill_label.add_theme_font_size_override("font_size", 10)
	_skill_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	_skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skill_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_skill_label.max_lines_visible = 3
	vbox.add_child(_skill_label)

	# 줄 4: 하중 + 손상도 (HBox)
	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	_weight_label = Label.new()
	_weight_label.add_theme_font_size_override("font_size", 10)
	_weight_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	_weight_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_weight_label)

	_durability_label = Label.new()
	_durability_label.add_theme_font_size_override("font_size", 10)
	_durability_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	hbox.add_child(_durability_label)

	# 줄 5: affix 목록 (없으면 숨김)
	_affix_label = Label.new()
	_affix_label.add_theme_font_size_override("font_size", 9)
	_affix_label.add_theme_color_override("font_color", COLOR_AFFIX)
	_affix_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_affix_label.custom_minimum_size = Vector2(200, 0)
	_affix_label.visible = false
	vbox.add_child(_affix_label)

# ── 퍼블릭 ───────────────────────────────
func setup(p: PartsData) -> void:
	part_data = p
	if _part_name_label != null:
		_refresh_display()

# ── 드래그 발신 ──────────────────────────
func _get_drag_data(_pos: Vector2) -> Variant:
	if part_data == null:
		return null

	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(120, 120)

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
	EventBus.assembly_drag_inventory_part = part_data
	get_tree().call_group("part_socket_drag_highlight", "on_drag_inventory_part", part_data)
	return { "part": part_data }

# ── 호버 피드백 ──────────────────────────
func _on_mouse_entered() -> void:
	_apply_style(_style_hover)

func _on_mouse_exited() -> void:
	_apply_style(_style_normal)


func _on_resized() -> void:
	var inner: float = maxf(32.0, size.x - 16.0)
	if _skill_label != null:
		_skill_label.custom_minimum_size = Vector2(inner, 0.0)


# ── 헬퍼 ─────────────────────────────────
func _refresh_display() -> void:
	if part_data == null:
		return

	# 줄 1: 접두사 + 이름 + 상태 태그
	var prefix := ""
	for entry: Array in PREFIX_TABLE:
		if part_data.stat_multiplier >= entry[0] and part_data.stat_multiplier <= entry[1]:
			prefix = entry[2]
			break

	var tag := ""
	var name_color := _grade_color()
	if part_data.is_broken():
		tag = "💀"
		name_color = COLOR_BROKEN
	elif part_data.is_worn():
		tag = "⚠"
		name_color = COLOR_WARN

	var display_name: String = (prefix + " " + part_data.parts_name).strip_edges()
	if not tag.is_empty():
		display_name += " " + tag
	_part_name_label.text = display_name
	_part_name_label.add_theme_color_override("font_color", name_color)

	# 줄 2: 타입
	_type_label.text = "[%s]" % PartsData.PartsType.keys()[part_data.parts_type]

	# 줄 3: 스킬 설명
	_skill_label.text = part_data.parts_description

	# 줄 4: 하중 + 손상도 블록
	_weight_label.text = "하중 %.0f" % part_data.parts_weight

	var filled := "■".repeat(part_data.durability)
	var empty := "□".repeat(part_data.max_durability - part_data.durability)
	_durability_label.text = filled + empty

	var dur_color: Color
	if part_data.is_broken():
		dur_color = COLOR_BROKEN
	elif part_data.is_worn():
		dur_color = COLOR_WARN
	else:
		dur_color = COLOR_DUR_OK
	_durability_label.add_theme_color_override("font_color", dur_color)

	# 줄 5: affix 이름 목록
	if part_data.rolled_affixes.is_empty():
		_affix_label.visible = false
	else:
		var names: Array[String] = []
		for affix_id: String in part_data.rolled_affixes:
			names.append(AFFIX_NAMES.get(affix_id, affix_id))
		_affix_label.text = "  ".join(names)
		_affix_label.visible = true

	# 테두리 등급 색
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
