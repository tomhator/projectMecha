extends Control

const CORE_VANGUARD_PATH := "res://Resources/Cores/core_vanguard.tres"
const CORE_STRIKER_PATH := "res://Resources/Cores/core_striker.tres"
const CORE_BULWARK_PATH := "res://Resources/Cores/core_bulwark.tres"

const CARD_SIZE := Vector2(200.0, 240.0)

@onready var cards_row: HBoxContainer = $MarginRoot/CenterArea/CardsRow
@onready var sortie_button: Button = $MarginRoot/CenterArea/SortieButton

var _selected_path: String = ""
var _card_panels: Array[Panel] = []


func _ready() -> void:
	sortie_button.disabled = true
	sortie_button.text = "출격"
	_build_cards()


func _build_cards() -> void:
	var defs: Array[Dictionary] = [
		{
			"path": CORE_VANGUARD_PATH,
			"title": "범용 코어",
			"subtitle": "Vanguard",
			"desc": "평균적인 스탯, 제약 없음."
		},
		{
			"path": CORE_STRIKER_PATH,
			"title": "경량 코어",
			"subtitle": "Striker",
			"desc": "공격력 보정 / 턴당 스킬 2회 / 하중 제한↓"
		},
		{
			"path": CORE_BULWARK_PATH,
			"title": "방어 코어",
			"subtitle": "Bulwark",
			"desc": "체력↑ / 공격력↓ / 공격 횟수↓"
		},
	]

	for def: Dictionary in defs:
		var card: Panel = _make_core_card(def)
		cards_row.add_child(card)
		_card_panels.append(card)

	sortie_button.pressed.connect(_on_sortie_pressed)


func _make_core_card(def: Dictionary) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = CARD_SIZE
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.14, 0.16, 0.2, 1.0)
	base.set_border_width_all(1)
	base.border_color = Color(0.35, 0.38, 0.44, 1.0)
	base.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", base)
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 10.0
	vb.offset_right = -10.0
	vb.offset_top = 10.0
	vb.offset_bottom = -10.0
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(180.0, 72.0)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var img: Image = Image.create(int(tex.custom_minimum_size.x), int(tex.custom_minimum_size.y), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.15, 0.2, 0.28, 1.0))
	tex.texture = ImageTexture.create_from_image(img)
	vb.add_child(tex)

	var t := Label.new()
	t.text = def["title"] as String
	t.add_theme_font_size_override("font_size", 16)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	var st := Label.new()
	st.text = def["subtitle"] as String
	st.add_theme_font_size_override("font_size", 11)
	st.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(st)

	var d := Label.new()
	d.text = def["desc"] as String
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 11)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(d)

	var sel := Button.new()
	sel.text = "이 코어 선택"
	sel.pressed.connect(_on_card_select.bind(def["path"] as String, panel))
	vb.add_child(sel)

	return panel


func _on_card_select(path: String, panel: Panel) -> void:
	_selected_path = path
	sortie_button.disabled = false
	for p: Panel in _card_panels:
		var st := StyleBoxFlat.new()
		if p == panel:
			st.bg_color = Color(0.22, 0.32, 0.48, 1.0)
			st.set_border_width_all(2)
			st.border_color = Color(0.5, 0.75, 1.0, 1.0)
		else:
			st.bg_color = Color(0.14, 0.16, 0.2, 1.0)
			st.set_border_width_all(1)
			st.border_color = Color(0.35, 0.38, 0.44, 1.0)
		st.set_corner_radius_all(8)
		p.add_theme_stylebox_override("panel", st)


func _on_sortie_pressed() -> void:
	if _selected_path.is_empty():
		return
	var core: CoreData = load(_selected_path) as CoreData
	if core == null:
		push_error("코어 데이터를 찾을 수 없습니다: " + _selected_path)
		return
	GameState.start_run(core)
	DungeonManager.start_dungeon()
