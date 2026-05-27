extends Control

const BASIC_ATTACK_PATHS: Array[String] = [
	"res://Resources/Skills/skill_core_particle_beam.tres",
	"res://Resources/Skills/skill_core_single_shot.tres",
	"res://Resources/Skills/skill_core_makeshift_barrier.tres",
]
const PART_ABILITY_PATHS: Array[String] = [
	"res://Resources/Skills/skill_core_emergency_swap.tres",
	"res://Resources/Skills/skill_core_broken_throw.tres",
	"res://Resources/Skills/skill_core_scrap_patch.tres",
]
const HUB_SCENE: String = "res://Scenes/Base/HubScene.tscn"
const TRACK_LABELS: Dictionary = {
	AbilityTreeNode.Track.ATTACK: "공격",
	AbilityTreeNode.Track.DEFENSE: "방어",
	AbilityTreeNode.Track.UTILITY: "유틸",
}
const TRACK_COLORS: Dictionary = {
	AbilityTreeNode.Track.ATTACK: Color(0.56, 0.22, 0.18),
	AbilityTreeNode.Track.DEFENSE: Color(0.16, 0.34, 0.52),
	AbilityTreeNode.Track.UTILITY: Color(0.24, 0.42, 0.23),
}
const DUNGEON_INTEL: PackedStringArray = [
	"매립지 진입",
	"적 성향: 일반 적은 부품 압박보다 직접 코어 피해가 높다.",
	"환경: 파츠 보상과 작업대가 중반부터 열려 교체 타이밍이 중요하다.",
	"보스 힌트: 첫 보스 전후로 파손 파츠 활용 어빌리티가 확장된다.",
]
const RESEARCH_CARD_SIZE: float = 268.0
const RESEARCH_GRID_SEPARATION: int = 10
const SORTIE_PREVIEW_WIDTH: float = 316.0
const SORTIE_CONTROLS_WIDTH: float = 936.0
const CORE_PREVIEW_TIER_SLOTS: Dictionary = {
	1: "sensor_mast",
	2: "cockpit_shell",
	3: "shoulder_frame",
	4: "rear_pack",
	5: "front_plating",
}
const CORE_PREVIEW_SLOT_LABELS: Dictionary = {
	"sensor_mast": "상부 센서 마스트",
	"cockpit_shell": "조종석 장갑",
	"shoulder_frame": "견부 프레임",
	"rear_pack": "후방 장비팩",
	"front_plating": "전면 장갑판",
}

@onready var cards_row: HBoxContainer = $MarginRoot/CenterArea/CardsRow
@onready var sortie_button: Button = $MarginRoot/CenterArea/SortieButton
@onready var title_label: Label = $MarginRoot/CenterArea/TitleLabel
@onready var center_area: VBoxContainer = $MarginRoot/CenterArea

var _nodes: Array[AbilityTreeNode] = []
var _nodes_by_id: Dictionary = {}
var _basic_attacks: Array[SkillData] = []
var _part_abilities: Array[SkillData] = []
var _view_host: VBoxContainer = null
var _view_scroll: ScrollContainer = null
var _meta_label: Label = null


func _ready() -> void:
	_load_ability_nodes()
	_load_skills(BASIC_ATTACK_PATHS, _basic_attacks)
	_load_skills(PART_ABILITY_PATHS, _part_abilities)
	_ensure_loadout_defaults()
	_build_shell()
	if GameState.core_select_initial_tab == "research":
		_show_research_view()
	else:
		_show_sortie_view()


func _load_ability_nodes() -> void:
	var dir := DirAccess.open("res://Resources/AbilityTree")
	if dir == null:
		push_error("Ability tree directory missing")
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var node: AbilityTreeNode = load("res://Resources/AbilityTree/%s" % file_name) as AbilityTreeNode
			if node != null:
				_nodes.append(node)
				_nodes_by_id[node.node_id] = node
		file_name = dir.get_next()
	dir.list_dir_end()
	_nodes.sort_custom(func(a: AbilityTreeNode, b: AbilityTreeNode) -> bool:
		if a.tier == b.tier:
			return a.track < b.track
		return a.tier < b.tier
	)


func _load_skills(paths: Array[String], out: Array[SkillData]) -> void:
	for path: String in paths:
		var skill: SkillData = load(path) as SkillData
		if skill != null:
			out.append(skill)


func _ensure_loadout_defaults() -> void:
	if GameState.active_basic_attack == null and not _basic_attacks.is_empty():
		GameState.set_run_basic_attack(_basic_attacks[1])
	if GameState.active_part_ability == null and not _part_abilities.is_empty():
		GameState.set_run_part_ability(_part_abilities[0])


func _build_shell() -> void:
	title_label.text = "코어 설계"
	cards_row.visible = false
	sortie_button.visible = false

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 8)
	center_area.add_child(nav)
	center_area.move_child(nav, 1)

	var hub_button := Button.new()
	hub_button.text = "은신처"
	hub_button.pressed.connect(_on_hub_pressed)
	nav.add_child(hub_button)

	var research_button := Button.new()
	research_button.text = "코어 연구"
	research_button.pressed.connect(_show_research_view)
	nav.add_child(research_button)

	var sortie_view_button := Button.new()
	sortie_view_button.text = "출격 준비"
	sortie_view_button.pressed.connect(_show_sortie_view)
	nav.add_child(sortie_view_button)

	_meta_label = Label.new()
	_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meta_label.add_theme_font_size_override("font_size", 13)
	center_area.add_child(_meta_label)
	center_area.move_child(_meta_label, 2)

	_view_scroll = ScrollContainer.new()
	_view_scroll.custom_minimum_size = Vector2(980.0, 500.0)
	_view_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_area.add_child(_view_scroll)
	center_area.move_child(_view_scroll, 3)

	_view_host = VBoxContainer.new()
	_view_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view_host.add_theme_constant_override("separation", 12)
	_view_scroll.add_child(_view_host)


func _show_research_view() -> void:
	_clear_view()
	_refresh_meta_label()
	_view_host.add_child(_make_note("잠긴 노드도 효과 축을 확인할 수 있다. 이전 티어에서 하나라도 구매하면 다음 티어 연구가 열린다."))
	for tier: int in range(1, 6):
		_view_host.add_child(_make_section_label("T%d 연구" % tier))
		var center := CenterContainer.new()
		center.name = "ResearchTierCenter%d" % tier
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var grid := GridContainer.new()
		grid.name = "ResearchTierGrid%d" % tier
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", RESEARCH_GRID_SEPARATION)
		grid.add_theme_constant_override("v_separation", RESEARCH_GRID_SEPARATION)
		for node: AbilityTreeNode in _nodes_for_tier(tier):
			grid.add_child(_make_research_card(node))
		center.add_child(grid)
		_view_host.add_child(center)


func _show_sortie_view() -> void:
	_clear_view()
	_refresh_meta_label()

	var split := HBoxContainer.new()
	split.name = "SortieSplit"
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 14)
	split.add_child(_make_core_preview())

	var controls_scroll := ScrollContainer.new()
	controls_scroll.name = "SortieControlsScroll"
	controls_scroll.custom_minimum_size = Vector2(SORTIE_CONTROLS_WIDTH, 500.0)
	controls_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_scroll.add_child(_make_sortie_controls())
	split.add_child(controls_scroll)
	_view_host.add_child(split)


func _make_sortie_controls() -> VBoxContainer:
	var controls := VBoxContainer.new()
	controls.name = "SortieControls"
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 12)
	controls.add_child(_make_dungeon_intel())
	controls.add_child(_make_section_label("기본 공격 택 1"))
	controls.add_child(_make_skill_choice_row(_basic_attacks, true))
	controls.add_child(_make_section_label("어빌리티 트리 로드아웃"))
	for tier: int in range(1, 6):
		controls.add_child(_make_sortie_tier_row(tier))
	controls.add_child(_make_section_label("파츠 활용 어빌리티 택 1"))
	controls.add_child(_make_skill_choice_row(_part_abilities, false))
	controls.add_child(_make_loadout_preview())

	var start_button := Button.new()
	start_button.text = "출격"
	start_button.custom_minimum_size = Vector2(220.0, 44.0)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_on_sortie_pressed)
	controls.add_child(start_button)
	return controls


func _make_core_preview() -> Panel:
	var panel := _make_card_panel(Vector2(SORTIE_PREVIEW_WIDTH, 500.0), Color(0.10, 0.14, 0.18))
	panel.name = "CorePreview"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body: VBoxContainer = panel.get_child(0) as VBoxContainer
	body.add_child(_make_card_title("현재 코어 외형"))
	body.add_child(_make_wrapped_label("중앙 조종석과 그 주변 외장 슬롯을 이번 출격 노드 기준으로 표시한다.", 11))

	var frame := VBoxContainer.new()
	frame.name = "CorePreviewFrame"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_constant_override("separation", 8)
	for tier: int in range(1, 6):
		frame.add_child(_make_core_preview_slot(tier))
	body.add_child(frame)

	var attack_name: String = GameState.active_basic_attack.skill_name if GameState.active_basic_attack != null else "없음"
	var ability_name: String = GameState.active_part_ability.skill_name if GameState.active_part_ability != null else "없음"
	body.add_child(_make_wrapped_label("기본 공격: %s\n파츠 활용: %s" % [attack_name, ability_name], 11))
	body.add_child(_make_wrapped_label(_stat_preview_text(), 11))
	return panel


func _make_core_preview_slot(tier: int) -> Panel:
	var node: AbilityTreeNode = _selected_node_for_tier(tier)
	var color: Color = Color(0.20, 0.23, 0.28) if node == null else TRACK_COLORS[node.track]
	var panel := _make_card_panel(Vector2(0.0, 62.0), color)
	panel.name = "CorePreviewSlot%d" % tier
	var body: VBoxContainer = panel.get_child(0) as VBoxContainer
	var slot_key: String = str(CORE_PREVIEW_TIER_SLOTS.get(tier, ""))
	var slot_name: String = str(CORE_PREVIEW_SLOT_LABELS.get(slot_key, slot_key))
	var variant_text: String = "비어 있음"
	if node != null:
		slot_name = _core_slot_label(node.visual_slot)
		variant_text = "%s [%s] / %s" % [node.display_name, TRACK_LABELS[node.track], _core_variant_label(node)]
	body.add_child(_make_card_title("T%d %s" % [tier, slot_name]))
	body.add_child(_make_wrapped_label(variant_text, 10))
	return panel


func _make_research_card(node: AbilityTreeNode) -> Panel:
	var panel := _make_card_panel(Vector2(RESEARCH_CARD_SIZE, RESEARCH_CARD_SIZE), TRACK_COLORS[node.track])
	panel.name = "ResearchCard_%s" % node.node_id
	var body: VBoxContainer = panel.get_child(0) as VBoxContainer
	body.add_child(_make_card_title("%s [%s]" % [node.display_name, TRACK_LABELS[node.track]]))
	body.add_child(_make_wrapped_label(node.description, 11))
	body.add_child(_make_wrapped_label("외장: %s / %s" % [_core_slot_label(node.visual_slot), _core_variant_label(node)], 10))
	body.add_child(_make_wrapped_label(node.level_five_bonus_text, 10))

	var level: int = GameState.get_tree_node_level(node.node_id)
	var status := Label.new()
	status.text = "레벨 %d / 5" % level if level > 0 else "잠김 - 연구 비용 %d" % node.research_cost
	status.add_theme_font_size_override("font_size", 11)
	body.add_child(status)

	var action := Button.new()
	if level <= 0:
		action.text = "연구"
		action.disabled = not _can_research_node(node)
		action.pressed.connect(_on_research_pressed.bind(node))
	elif level < 5:
		action.text = "레벨업 %d" % node.level_cost(level + 1)
		action.disabled = GameState.meta_credits < node.level_cost(level + 1)
		action.pressed.connect(_on_level_pressed.bind(node))
	else:
		action.text = "최대 레벨"
		action.disabled = true
	body.add_child(action)
	return panel


func _make_sortie_tier_row(tier: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var header := HBoxContainer.new()
	header.add_child(_make_section_label("T%d" % tier))
	var clear_button := Button.new()
	clear_button.text = "비움"
	clear_button.pressed.connect(_on_clear_tier_pressed.bind(tier))
	header.add_child(clear_button)
	box.add_child(header)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for node: AbilityTreeNode in _nodes_for_tier(tier):
		row.add_child(_make_sortie_node_button(node))
	box.add_child(row)
	return box


func _make_sortie_node_button(node: AbilityTreeNode) -> Button:
	var level: int = GameState.get_tree_node_level(node.node_id)
	var button := Button.new()
	button.custom_minimum_size = Vector2(286.0, 60.0)
	button.text = "%s [%s]\n%s" % [
		node.display_name,
		TRACK_LABELS[node.track],
		"레벨 %d" % level if level > 0 else "미연구"
	]
	button.disabled = level <= 0
	button.pressed.connect(_on_sortie_node_pressed.bind(node))
	if str(GameState.active_tree_node_ids.get(node.tier, "")) == node.node_id:
		button.modulate = Color(0.8, 1.0, 0.82)
	return button


func _make_skill_choice_row(skills: Array[SkillData], basic_attack: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for skill: SkillData in skills:
		var panel := _make_card_panel(Vector2(300.0, 132.0), Color(0.14, 0.16, 0.19))
		var body: VBoxContainer = panel.get_child(0) as VBoxContainer
		body.add_child(_make_card_title(skill.skill_name))
		body.add_child(_make_wrapped_label("%s\n행동력 %d" % [skill.skill_description, skill.skill_action_cost], 11))
		var button := Button.new()
		var selected: bool = GameState.active_basic_attack == skill if basic_attack else GameState.active_part_ability == skill
		button.text = "선택됨" if selected else "선택"
		button.disabled = selected or (not basic_attack and not GameState.is_part_ability_unlocked(skill))
		if not basic_attack and not GameState.is_part_ability_unlocked(skill):
			button.text = "잠김"
		if basic_attack:
			button.pressed.connect(_on_basic_attack_pressed.bind(skill))
		else:
			button.pressed.connect(_on_part_ability_pressed.bind(skill))
		body.add_child(button)
		row.add_child(panel)
	return row


func _make_dungeon_intel() -> Panel:
	var panel := _make_card_panel(Vector2(936.0, 126.0), Color(0.18, 0.20, 0.24))
	var body: VBoxContainer = panel.get_child(0) as VBoxContainer
	for i: int in DUNGEON_INTEL.size():
		var label := _make_wrapped_label(DUNGEON_INTEL[i], 14 if i == 0 else 11)
		body.add_child(label)
	return panel


func _make_loadout_preview() -> Panel:
	var panel := _make_card_panel(Vector2(936.0, 150.0), Color(0.12, 0.20, 0.18))
	var body: VBoxContainer = panel.get_child(0) as VBoxContainer
	body.add_child(_make_card_title("출격 빌드 미리보기"))
	var attack_name: String = GameState.active_basic_attack.skill_name if GameState.active_basic_attack != null else "없음"
	var ability_name: String = GameState.active_part_ability.skill_name if GameState.active_part_ability != null else "없음"
	body.add_child(_make_wrapped_label("기본 공격: %s | 파츠 활용: %s" % [attack_name, ability_name], 11))

	var visuals: PackedStringArray = []
	for tier: int in range(1, 6):
		var node: AbilityTreeNode = _selected_node_for_tier(tier)
		if node == null:
			visuals.append("T%d 비움" % tier)
		else:
			visuals.append("T%d %s -> %s" % [tier, node.display_name, _core_slot_label(node.visual_slot)])
	body.add_child(_make_wrapped_label("코어 외장: %s" % " | ".join(visuals), 11))
	body.add_child(_make_wrapped_label(_stat_preview_text(), 11))
	return panel


func _stat_preview_text() -> String:
	var attack_bonus: float = 0.0
	var hp_bonus: float = 0.0
	var shield_bonus: float = 0.0
	var action_bonus: int = 0
	var payload_bonus: float = 0.0
	for tier: int in range(1, 6):
		var node: AbilityTreeNode = _selected_node_for_tier(tier)
		if node == null:
			continue
		var level: int = GameState.get_tree_node_level(node.node_id)
		attack_bonus += node.attack_bonus_at_level(level)
		hp_bonus += node.hp_bonus_at_level(level)
		shield_bonus += node.shield_bonus_at_level(level)
		action_bonus += node.action_bonus_at_level(level)
		payload_bonus += node.payload_bonus_at_level(level)
	return "트리 보정: 공격 +%d%% | HP +%.0f | 쉴드 +%.0f | 행동력 +%d | 하중 +%.0f" % [
		roundi(attack_bonus * 100.0), hp_bonus, shield_bonus, action_bonus, payload_bonus
	]


func _core_slot_label(visual_slot: String) -> String:
	return str(CORE_PREVIEW_SLOT_LABELS.get(visual_slot, visual_slot))


func _core_variant_label(node: AbilityTreeNode) -> String:
	if node == null:
		return ""
	return "%s형 모듈" % TRACK_LABELS[node.track]


func _make_card_panel(minimum_size: Vector2, bg_color: Color) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(0.34, 0.37, 0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 8.0
	body.offset_top = 8.0
	body.offset_right = -8.0
	body.offset_bottom = -8.0
	body.add_theme_constant_override("separation", 4)
	panel.add_child(body)
	return panel


func _make_card_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	return label


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label


func _make_wrapped_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return label


func _make_note(text: String) -> Label:
	var note := _make_wrapped_label(text, 12)
	note.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	return note


func _clear_view() -> void:
	for child: Node in _view_host.get_children():
		child.queue_free()


func _refresh_meta_label() -> void:
	if _meta_label != null:
		_meta_label.text = "거점 크레딧: %d | 고철: %d | 출격 노드는 연구한 티어에서 1개씩만 장착" % [
			GameState.meta_credits,
			GameState.meta_scrap
		]


func _nodes_for_tier(tier: int) -> Array[AbilityTreeNode]:
	return _nodes.filter(func(node: AbilityTreeNode) -> bool: return node.tier == tier)


func _selected_node_for_tier(tier: int) -> AbilityTreeNode:
	var node_id: String = str(GameState.active_tree_node_ids.get(tier, ""))
	return _nodes_by_id.get(node_id) as AbilityTreeNode


func _can_research_node(node: AbilityTreeNode) -> bool:
	if node.tier == 1:
		return GameState.meta_credits >= node.research_cost
	for lower: AbilityTreeNode in _nodes_for_tier(node.tier - 1):
		if GameState.is_tree_node_unlocked(lower.node_id):
			return GameState.meta_credits >= node.research_cost
	return false


func _on_research_pressed(node: AbilityTreeNode) -> void:
	GameState.unlock_tree_node(node)
	_show_research_view()


func _on_level_pressed(node: AbilityTreeNode) -> void:
	GameState.level_tree_node(node)
	_show_research_view()


func _on_basic_attack_pressed(skill: SkillData) -> void:
	GameState.set_run_basic_attack(skill)
	_show_sortie_view()


func _on_part_ability_pressed(skill: SkillData) -> void:
	GameState.set_run_part_ability(skill)
	_show_sortie_view()


func _on_sortie_node_pressed(node: AbilityTreeNode) -> void:
	GameState.set_run_tree_node(node)
	_show_sortie_view()


func _on_clear_tier_pressed(tier: int) -> void:
	GameState.clear_run_tree_node(tier)
	_show_sortie_view()


func _on_hub_pressed() -> void:
	get_tree().change_scene_to_file(HUB_SCENE)


func _on_sortie_pressed() -> void:
	GameState.start_run()
	for tier: int in range(1, 6):
		var node: AbilityTreeNode = _selected_node_for_tier(tier)
		if node != null:
			GameState.apply_tree_node(node, GameState.get_tree_node_level(node.node_id))
	DungeonManager.start_dungeon()
