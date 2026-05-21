extends Control

const TREE_POINTS: int = 3

const NODE_PATHS: Array[String] = [
	"res://Resources/AbilityTree/node_attack_1.tres",
	"res://Resources/AbilityTree/node_attack_2.tres",
	"res://Resources/AbilityTree/node_attack_core.tres",
	"res://Resources/AbilityTree/node_defense_1.tres",
	"res://Resources/AbilityTree/node_defense_2.tres",
	"res://Resources/AbilityTree/node_defense_core.tres",
	"res://Resources/AbilityTree/node_mobility_1.tres",
	"res://Resources/AbilityTree/node_mobility_2.tres",
	"res://Resources/AbilityTree/node_mobility_core.tres",
]

const BRANCH_ORDER: Array[String] = ["attack", "defense", "mobility"]
const BRANCH_LABELS: Dictionary = {
	"attack": "[ 공격 분기 ]",
	"defense": "[ 방어 분기 ]",
	"mobility": "[ 기동 분기 ]",
}

@onready var cards_row: HBoxContainer = $MarginRoot/CenterArea/CardsRow
@onready var sortie_button: Button = $MarginRoot/CenterArea/SortieButton
@onready var title_label: Label = $MarginRoot/CenterArea/TitleLabel

var _nodes: Array[AbilityTreeNode] = []
var _selected_ids: Array[String] = []
var _remaining_points: int = TREE_POINTS
var _points_label: Label = null
var _card_meta: Dictionary = {}  # node_id → { panel, button }


func _ready() -> void:
	title_label.text = "어빌리티 트리"
	sortie_button.disabled = false
	sortie_button.text = "출격"
	_load_nodes()
	_build_points_label()
	_build_tree_ui()
	sortie_button.pressed.connect(_on_sortie_pressed)


func _load_nodes() -> void:
	for path: String in NODE_PATHS:
		var node: AbilityTreeNode = load(path) as AbilityTreeNode
		if node != null:
			_nodes.append(node)


func _build_points_label() -> void:
	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 15)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$MarginRoot/CenterArea.add_child(_points_label)
	$MarginRoot/CenterArea.move_child(_points_label, 1)
	_refresh_points_label()


func _refresh_points_label() -> void:
	_points_label.text = "포인트: %d / %d  |  코어 스킬: %s" % [
		_remaining_points, TREE_POINTS,
		_get_active_core_skill_name()
	]


func _get_active_core_skill_name() -> String:
	for id: String in _selected_ids:
		var node: AbilityTreeNode = _find_node(id)
		if node != null and node.unlocks_core_skill != null:
			return node.unlocks_core_skill.skill_name
	return "없음"


func _build_tree_ui() -> void:
	var branches: Dictionary = {}
	for key: String in BRANCH_ORDER:
		branches[key] = []

	for n: AbilityTreeNode in _nodes:
		for key: String in BRANCH_ORDER:
			if n.node_id.begins_with("node_" + key):
				branches[key].append(n)
				break

	for key: String in BRANCH_ORDER:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(210, 0)
		col.add_theme_constant_override("separation", 8)
		cards_row.add_child(col)

		var branch_title := Label.new()
		branch_title.text = BRANCH_LABELS[key]
		branch_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_title.add_theme_font_size_override("font_size", 13)
		col.add_child(branch_title)

		var sorted: Array = branches[key].duplicate()
		sorted.sort_custom(func(a: AbilityTreeNode, b: AbilityTreeNode) -> bool:
			return a.node_id < b.node_id
		)
		for n: AbilityTreeNode in sorted:
			col.add_child(_make_node_card(n))


func _make_node_card(node: AbilityTreeNode) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(200, 130)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 8.0; vb.offset_right = -8.0
	vb.offset_top = 8.0; vb.offset_bottom = -8.0
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	var name_lbl := Label.new()
	name_lbl.text = node.display_name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = node.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(desc_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "비용: %d pt" % node.point_cost
	cost_lbl.add_theme_font_size_override("font_size", 10)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(cost_lbl)

	var btn := Button.new()
	btn.pressed.connect(_on_node_toggled.bind(node))
	vb.add_child(btn)

	_card_meta[node.node_id] = {"panel": panel, "button": btn}
	_refresh_card(node)
	return panel


func _on_node_toggled(node: AbilityTreeNode) -> void:
	if _selected_ids.has(node.node_id):
		if _can_deselect(node):
			_selected_ids.erase(node.node_id)
			_remaining_points += node.point_cost
	else:
		if _remaining_points >= node.point_cost and _can_select(node):
			_selected_ids.append(node.node_id)
			_remaining_points -= node.point_cost

	_refresh_all_cards()
	_refresh_points_label()


func _can_select(node: AbilityTreeNode) -> bool:
	if node.required_node_id.is_empty():
		return true
	return _selected_ids.has(node.required_node_id)


func _can_deselect(node: AbilityTreeNode) -> bool:
	for other_id: String in _selected_ids:
		if other_id == node.node_id:
			continue
		var other: AbilityTreeNode = _find_node(other_id)
		if other != null and other.required_node_id == node.node_id:
			return false
	return true


func _find_node(node_id: String) -> AbilityTreeNode:
	for n: AbilityTreeNode in _nodes:
		if n.node_id == node_id:
			return n
	return null


func _refresh_all_cards() -> void:
	for n: AbilityTreeNode in _nodes:
		_refresh_card(n)


func _refresh_card(node: AbilityTreeNode) -> void:
	var meta: Dictionary = _card_meta.get(node.node_id, {})
	if meta.is_empty():
		return
	var panel: Panel = meta["panel"]
	var btn: Button = meta["button"]

	var is_selected: bool = _selected_ids.has(node.node_id)
	var can_sel: bool = _can_select(node) and _remaining_points >= node.point_cost

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)

	if is_selected:
		style.bg_color = Color(0.18, 0.38, 0.60, 1.0)
		style.border_color = Color(0.50, 0.80, 1.00, 1.0)
		btn.text = "해제"
		btn.disabled = false
	elif can_sel:
		style.bg_color = Color(0.14, 0.20, 0.14, 1.0)
		style.border_color = Color(0.35, 0.70, 0.35, 1.0)
		btn.text = "선택"
		btn.disabled = false
	else:
		style.bg_color = Color(0.10, 0.10, 0.12, 1.0)
		style.border_color = Color(0.25, 0.25, 0.28, 1.0)
		btn.text = "선택"
		btn.disabled = true

	panel.add_theme_stylebox_override("panel", style)


func _on_sortie_pressed() -> void:
	GameState.start_run()
	for node_id: String in _selected_ids:
		var node: AbilityTreeNode = _find_node(node_id)
		if node != null:
			GameState.apply_tree_node(node)
	DungeonManager.start_dungeon()
