extends Control
class_name CombatUI

signal skill_selected(skill: SkillData, target: Node)
signal end_turn_requested

const BATTLE_H_SEP: float = 32.0
const PLAYER_STAGE_WIDTH: float = 240.0
const ENEMY_COL_MIN_W: float = 420.0
const ENEMY_COL_MAX_W: float = 760.0
const SKILL_SLOT_SIZE: Vector2 = Vector2(72.0, 72.0)
const ENEMY_SLOT_SIZE: Vector2 = Vector2(140.0, 268.0)
const ENEMY_SPRITE_SIZE: Vector2 = Vector2(108.0, 116.0)
const HUD_CORE_CELL: int = -1
const SNIPE_SLOT_NONE: int = -1

@onready var battle_hbox: HBoxContainer = %BattleHBox
@onready var player_column: VBoxContainer = %PlayerColumn
@onready var enemy_column: VBoxContainer = %EnemyColumn
@onready var skill_container: HBoxContainer = %SkillContainer
@onready var enemy_container: HBoxContainer = %EnemyContainer
@onready var action_orbs_row: HBoxContainer = %ActionOrbsRow
@onready var core_name_label: Label = %CoreNameLabel
@onready var _mech_illustration: Control = %MechIllustration
@onready var selection_status: Label = %SelectionStatus
@onready var turn_label: Label = %TurnLabel
@onready var end_turn_button: Button = %EndTurnButton

var _current_enemies: Array[EnemyEntity] = []
## EnemyEntity 인스턴스 ID → UI 위젯 (노드 참조 키 불일치 방지)
var _enemy_hp_bars: Dictionary = {}  # int → ProgressBar
var _enemy_shield_bars: Dictionary = {}  # int → ProgressBar
var _enemy_hp_value_labels: Dictionary = {}  # int → Label
var _enemy_shield_value_labels: Dictionary = {}  # int → Label
var _enemy_forecast_labels: Dictionary = {}  # int → Label (적 행동 예고)
var _enemy_hover_preview_labels: Dictionary = {}  # int → Label (호버 예상값)
var _enemy_target_buttons: Dictionary = {}  # int → Button
var _skill_buttons: Dictionary = {}  # SkillData -> Button
var _skill_disable_reasons: Dictionary = {}  # SkillData -> String

var _pending_skill: SkillData = null
var _actions_remaining: int = 0
var _hover_damage_preview_enemy: EnemyEntity = null
var _hover_self_for_preview: bool = false
var _player_preview_label: Label = null
var _player_target_catcher: Button = null
const MECH_TEXTURE_PATHS: Dictionary = {
	"core": "res://Asset/UI/Mecha/core.png",
	"arm_l": "res://Asset/UI/Mecha/arm_l.png",
	"arm_r": "res://Asset/UI/Mecha/arm_r.png",
	"back": "res://Asset/UI/Mecha/back.png",
	"leg": "res://Asset/UI/Mecha/leg.png",
}

var _mech_layers: Dictionary = {}   # CoreData.CoreSlot → TextureRect (slot layers)
var _core_visual_layers: Dictionary = {}  # Core exterior slot -> Panel
var _hud_icons: Dictionary = {}     # CoreData.CoreSlot → Panel (status HUD)
var _broken_skills: Dictionary = {}  # SkillData → true (파괴된 파츠 소속 스킬)
var _enemy_snipe_slots: Dictionary = {}  # enemy_instance_id -> int(slot)
var _active_snipe_slot: int = SNIPE_SLOT_NONE
var _snipe_pulse_tween: Tween = null

const SHAKE_THRESHOLD: float = 15.0
const FLOAT_COLORS: Dictionary = {
	"damage": Color(1.0, 0.3, 0.3),
	"heal":   Color(0.3, 1.0, 0.3),
	"shield": Color(0.3, 0.7, 1.0),
}
const LOG_MAX_LINES: int = 8
var _log_lines: Array[String] = []
var _combat_log_label: RichTextLabel = null
var _shake_tween: Tween = null
var _prev_player_hp: float = 0.0
var _prev_player_shield: float = 0.0


func _ready() -> void:
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.skill_used.connect(_on_skill_used_global)
	EventBus.combat_turn_changed.connect(_on_combat_turn_changed)
	EventBus.part_durability_changed.connect(_on_part_durability_changed)
	EventBus.enemy_snipe_preview_changed.connect(_on_enemy_snipe_preview_changed)
	EventBus.part_stolen.connect(_on_part_stolen)
	EventBus.enemy_added.connect(_on_enemy_added)
	EventBus.skill_debuff_applied.connect(_on_debuff_applied)
	EventBus.boss_arms_respawning.connect(_on_boss_arms_respawning)
	battle_hbox.resized.connect(_apply_battle_column_split)
	_build_mech_layers()
	_build_parts_hud()
	_build_combat_log()
	_refresh_player_strip_from_state()
	_ensure_player_target_strip()
	if end_turn_button != null and not end_turn_button.pressed.is_connected(_on_end_turn_button_pressed):
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	_set_end_turn_button_enabled(false)
	_apply_battle_column_split.call_deferred()
	_prev_player_hp = GameState.current_hp
	_prev_player_shield = GameState.current_shield


func _on_combat_turn_changed(turn: int) -> void:
	if turn_label != null:
		turn_label.text = "턴 %d" % turn


func _on_part_durability_changed(part: PartsData) -> void:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		if GameState.equipped_parts[slot] == part:
			_refresh_hud_icon(slot)
			if part.is_broken():
				add_log("[파괴] %s" % part.parts_name)
			break


func _on_part_stolen(_part: PartsData, _slot: int) -> void:
	_build_parts_hud()
	_refresh_player_preview_label()
	var mecha: MechaEntity = _get_player_mecha()
	if mecha == null:
		return
	var usable: Array[SkillData] = mecha.get_available_skills().filter(
		func(s: SkillData) -> bool: return s.skill_action_cost <= _actions_remaining
	)
	_rebuild_skill_buttons(usable)


func _on_enemy_added(enemy: EnemyEntity) -> void:
	_prune_invalid_current_enemies()
	if enemy not in _current_enemies:
		_current_enemies.append(enemy)
	_rebuild_enemy_bars(_current_enemies)
	_update_enemy_preview()
	_prune_stale_snipe_sources()
	_recompute_snipe_highlight()


func _get_player_mecha() -> MechaEntity:
	for node: Node in get_tree().get_nodes_in_group("player"):
		if node is MechaEntity:
			return node as MechaEntity
	return null


func _apply_battle_column_split() -> void:
	var total: float = battle_hbox.size.x
	if total < 2.0:
		return
	var avail: float = maxf(total - BATTLE_H_SEP, 0.0)
	player_column.custom_minimum_size = Vector2(PLAYER_STAGE_WIDTH, 0.0)
	var right_w: float = clampf(avail - PLAYER_STAGE_WIDTH, ENEMY_COL_MIN_W, ENEMY_COL_MAX_W)
	if avail < PLAYER_STAGE_WIDTH + ENEMY_COL_MIN_W:
		right_w = maxf(avail - PLAYER_STAGE_WIDTH, 220.0)
	enemy_column.custom_minimum_size = Vector2(right_w, 0.0)


func _refresh_player_strip_from_state() -> void:
	if GameState.current_core != null:
		core_name_label.text = GameState.current_core.core_name
	_refresh_all_mech_layers()
	_refresh_all_hud_icons()
	_apply_snipe_highlight()


# ── 메카 일러스트 ─────────────────────────────────────────────────────────────

func _build_mech_layers() -> void:
	# [slot_or_null, texture_key, fallback_color, position, size, z_index]
	# null = 코어 몸통 (항상 표시, CoreData.CoreSlot 아님)
	var specs: Array = [
		[CoreData.CoreSlot.BACK,  "back",  Color(0.40, 0.40, 0.50), Vector2(5,   5),   Vector2(28, 50), 0],
		[CoreData.CoreSlot.LEG,   "leg",   Color(0.35, 0.35, 0.40), Vector2(32, 107),  Vector2(60, 55), 1],
		[null,                    "core",  Color(0.65, 0.65, 0.70), Vector2(30,  20),  Vector2(75, 90), 2],
		[CoreData.CoreSlot.ARM_R, "arm_r", Color(0.30, 0.45, 0.70), Vector2(98,  40),  Vector2(40, 72), 3],
		[CoreData.CoreSlot.ARM_L, "arm_l", Color(0.30, 0.65, 0.65), Vector2(5,   52),  Vector2(30, 58), 4],
	]
	for spec in specs:
		var slot = spec[0]
		var tex_key: String = spec[1]
		var fallback: Color = spec[2]
		var pos: Vector2 = spec[3]
		var layer_size: Vector2 = spec[4]
		var layer_z: int = spec[5]
		var rect := TextureRect.new()
		rect.texture = _load_mech_texture(tex_key, fallback, layer_size)
		rect.position = pos
		rect.size = layer_size
		rect.z_index = layer_z
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mech_illustration.add_child(rect)
		if slot != null:
			_mech_layers[slot] = rect
	_build_core_visual_layers()


func _load_mech_texture(texture_key: String, fallback_color: Color, layer_size: Vector2) -> Texture2D:
	var path: String = MECH_TEXTURE_PATHS.get(texture_key, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	return _make_fallback_texture(fallback_color, layer_size)


func _make_fallback_texture(color: Color, layer_size: Vector2) -> Texture2D:
	var w: int = maxi(int(layer_size.x), 1)
	var h: int = maxi(int(layer_size.y), 1)
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _refresh_all_mech_layers() -> void:
	for slot: CoreData.CoreSlot in [
		CoreData.CoreSlot.BACK, CoreData.CoreSlot.LEG,
		CoreData.CoreSlot.ARM_R, CoreData.CoreSlot.ARM_L
	]:
		_refresh_mech_layer(slot)
	_refresh_core_visual_layers()


func _refresh_mech_layer(slot: CoreData.CoreSlot) -> void:
	if slot not in _mech_layers:
		return
	var rect: TextureRect = _mech_layers[slot]
	rect.visible = GameState.equipped_parts.get(slot) != null
	_apply_snipe_highlight()


func _build_core_visual_layers() -> void:
	var specs: Dictionary = {
		"top_cover": [Vector2(48, 24), Vector2(38, 10)],
		"front_hood": [Vector2(72, 48), Vector2(24, 24)],
		"side_armor": [Vector2(34, 48), Vector2(12, 42)],
		"rear_pack": [Vector2(28, 30), Vector2(10, 34)],
		"core_spine": [Vector2(56, 36), Vector2(8, 62)],
	}
	for visual_slot: String in specs:
		var spec: Array = specs[visual_slot]
		var panel := Panel.new()
		panel.position = spec[0]
		panel.size = spec[1]
		panel.z_index = 5
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mech_illustration.add_child(panel)
		_core_visual_layers[visual_slot] = panel
	_refresh_core_visual_layers()


func _refresh_core_visual_layers() -> void:
	for visual_slot: String in _core_visual_layers:
		var panel: Panel = _core_visual_layers[visual_slot]
		var variant: String = str(GameState.active_core_visuals.get(visual_slot, ""))
		panel.visible = not variant.is_empty()
		if variant.is_empty():
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = _core_visual_color(variant)
		style.border_color = Color(0.8, 0.85, 0.9, 0.75)
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		panel.add_theme_stylebox_override("panel", style)


func _core_visual_color(variant: String) -> Color:
	if variant.begins_with("attack"):
		return Color(0.86, 0.32, 0.24, 0.9)
	if variant.begins_with("defense"):
		return Color(0.26, 0.62, 0.92, 0.9)
	return Color(0.42, 0.82, 0.40, 0.9)


# ── 파츠 상태 HUD (좌하단 십자형) ────────────────────────────────────────────

func _build_parts_hud() -> void:
	var container := Control.new()
	container.custom_minimum_size = Vector2(96, 96)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(grid)

	# 십자형 배치 (row by row): null = 빈 칸
	var cross: Array = [
		null,                    CoreData.CoreSlot.BACK,  null,
		CoreData.CoreSlot.ARM_R, HUD_CORE_CELL,           CoreData.CoreSlot.ARM_L,
		null,                    CoreData.CoreSlot.LEG,   null,
	]
	for key in cross:
		if key == null:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(32, 32)
			spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(spacer)
		else:
			var is_core: bool = (typeof(key) == TYPE_INT and int(key) == HUD_CORE_CELL)
			var panel := Panel.new()
			panel.custom_minimum_size = Vector2(32, 32)
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var lbl := Label.new()
			lbl.text = "코" if is_core else _slot_short(key as CoreData.CoreSlot)
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(lbl)
			if not is_core:
				_hud_icons[key as CoreData.CoreSlot] = panel
			grid.add_child(panel)

	var bottom_hbox: HBoxContainer = $BottomBar/BottomHBox
	bottom_hbox.add_child(container)
	bottom_hbox.move_child(container, 0)
	_refresh_all_hud_icons()


func _refresh_all_hud_icons() -> void:
	for slot: CoreData.CoreSlot in [
		CoreData.CoreSlot.BACK, CoreData.CoreSlot.LEG,
		CoreData.CoreSlot.ARM_R, CoreData.CoreSlot.ARM_L
	]:
		_refresh_hud_icon(slot)


func _refresh_hud_icon(slot: CoreData.CoreSlot) -> void:
	if slot not in _hud_icons:
		return
	var panel: Panel = _hud_icons[slot]
	var part: PartsData = GameState.equipped_parts.get(slot)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(2)

	if part == null:
		style.bg_color = Color(0.12, 0.12, 0.12, 0.7)
		style.set_border_width_all(1)
		style.border_color = Color(0.35, 0.35, 0.35)
		panel.modulate = Color(1, 1, 1, 1)
		_clear_hud_broken_overlay(panel)
	elif part.is_broken():
		style.bg_color = Color(0.20, 0.05, 0.05, 0.9)
		style.set_border_width_all(2)
		style.border_color = Color(0.9, 0.2, 0.2)
		panel.modulate = Color(0.45, 0.45, 0.45, 1)
		_ensure_hud_broken_overlay(panel)
	elif part.is_worn():
		style.bg_color = Color(0.18, 0.15, 0.08, 0.9)
		style.set_border_width_all(2)
		style.border_color = Color(1.0, 0.7, 0.2)
		panel.modulate = Color(1, 1, 1, 0.55)
		_clear_hud_broken_overlay(panel)
	else:
		style.bg_color = Color(0.10, 0.18, 0.10, 0.9)
		style.set_border_width_all(1)
		style.border_color = Color(0.3, 0.75, 0.3)
		panel.modulate = Color(1, 1, 1, 1)
		_clear_hud_broken_overlay(panel)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("base_modulate", panel.modulate)
	panel.set_meta("base_style", style.duplicate())
	_apply_snipe_highlight()


func _ensure_hud_broken_overlay(panel: Panel) -> void:
	if panel.has_meta("x_lbl"):
		(panel.get_meta("x_lbl") as Label).visible = true
		return
	var lbl := Label.new()
	lbl.text = "✕"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
	panel.set_meta("x_lbl", lbl)


func _clear_hud_broken_overlay(panel: Panel) -> void:
	if panel.has_meta("x_lbl"):
		(panel.get_meta("x_lbl") as Label).visible = false


func _slot_short(slot: CoreData.CoreSlot) -> String:
	match slot:
		CoreData.CoreSlot.ARM_L: return "왼"
		CoreData.CoreSlot.ARM_R: return "오"
		CoreData.CoreSlot.BACK:  return "등"
		CoreData.CoreSlot.LEG:   return "다"
	return "?"


func on_player_action_required(
	available_skills: Array[SkillData],
	enemies: Array[EnemyEntity],
	actions_remaining: int
) -> void:
	_pending_skill = null
	_hover_damage_preview_enemy = null
	_hover_self_for_preview = false
	_set_player_self_target_pending(false)
	_set_enemy_targeting_enabled(false)
	_apply_enemy_targeting_border(false)
	_current_enemies = enemies
	_actions_remaining = actions_remaining
	_prune_stale_snipe_sources()
	_rebuild_action_orbs()
	_rebuild_skill_buttons(available_skills)
	_rebuild_enemy_bars(enemies)
	_update_enemy_preview()
	_refresh_player_preview_label()
	_set_selection_status("스킬을 선택하세요.")
	_set_end_turn_button_enabled(actions_remaining > 0)
	_recompute_snipe_highlight()
	_apply_battle_column_split.call_deferred()


func _set_end_turn_button_enabled(enabled: bool) -> void:
	if end_turn_button == null:
		return
	end_turn_button.disabled = not enabled
	end_turn_button.tooltip_text = "" if enabled else "행동력이 없으면 턴이 자동 종료됩니다."


func _on_end_turn_button_pressed() -> void:
	if _actions_remaining <= 0:
		return
	_pending_skill = null
	_hover_damage_preview_enemy = null
	_hover_self_for_preview = false
	_set_player_self_target_pending(false)
	_set_enemy_targeting_enabled(false)
	_apply_enemy_targeting_border(false)
	_set_skill_buttons_disabled(false)
	_set_selection_status("턴을 종료합니다.")
	_set_end_turn_button_enabled(false)
	end_turn_requested.emit()


func _rebuild_action_orbs() -> void:
	for child: Node in action_orbs_row.get_children():
		child.queue_free()
	var max_act: int = GameState.current_action_count if GameState.current_core != null else 1
	for i: int in max_act:
		var orb := ColorRect.new()
		orb.custom_minimum_size = Vector2(22.0, 22.0)
		if i < _actions_remaining:
			orb.color = Color(0.35, 0.85, 0.45, 1.0)
		else:
			orb.color = Color(0.22, 0.25, 0.28, 1.0)
		action_orbs_row.add_child(orb)


func _rebuild_skill_buttons(available_skills: Array[SkillData]) -> void:
	_broken_skills.clear()
	_skill_disable_reasons.clear()
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot] as PartsData
		if part != null and part.is_broken():
			for s: SkillData in part.parts_skills:
				_broken_skills[s] = true

	for child: Node in skill_container.get_children():
		child.queue_free()
	_skill_buttons.clear()
	for skill: SkillData in available_skills:
		var btn: Button = Button.new()
		btn.text = ""
		btn.icon = skill.icon_texture(56)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.custom_minimum_size = SKILL_SLOT_SIZE
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.focus_mode = Control.FOCUS_NONE
		var disable_reason: String = _skill_disable_reason(skill)
		btn.tooltip_text = skill.combat_tooltip_text(disable_reason)
		btn.set_meta("skill_tooltip", skill.combat_tooltip_text())
		_add_skill_ap_badge(btn, skill.skill_action_cost)
		if not disable_reason.is_empty():
			btn.disabled = true
			_skill_disable_reasons[skill] = disable_reason
		else:
			btn.pressed.connect(_on_skill_button_pressed.bind(skill))
		skill_container.add_child(btn)
		_skill_buttons[skill] = btn


func _skill_disable_reason(skill: SkillData) -> String:
	if _broken_skills.has(skill):
		return "파츠 파괴됨"
	var mecha: MechaEntity = _get_player_mecha()
	if mecha != null:
		var part_ability_reason: String = mecha.get_part_ability_disable_reason(skill)
		if not part_ability_reason.is_empty():
			return part_ability_reason
	if skill.skill_action_cost > _actions_remaining:
		return "AP 부족 (%d 필요 / %d 보유)" % [skill.skill_action_cost, _actions_remaining]
	return ""


func _add_skill_ap_badge(btn: Button, action_cost: int) -> void:
	var badge := Panel.new()
	badge.anchor_left = 1.0
	badge.anchor_top = 1.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = -27.0
	badge.offset_top = -25.0
	badge.offset_right = -5.0
	badge.offset_bottom = -5.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.16, 0.96)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.88, 0.98, 1.0)
	style.set_corner_radius_all(3)
	badge.add_theme_stylebox_override("panel", style)
	btn.add_child(badge)

	var label := Label.new()
	label.text = "%d" % action_cost
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)


func _on_skill_button_pressed(skill: SkillData) -> void:
	var living: Array[EnemyEntity] = _living_enemies()
	if skill.skill_target == SkillData.SkillTarget.ENEMY and not living.is_empty():
		_pending_skill = skill
		_hover_self_for_preview = false
		_set_player_self_target_pending(false)
		_set_selection_status("「%s」 — 대상 적을 클릭하세요" % skill.skill_name)
		_set_enemy_targeting_enabled(true)
		_apply_enemy_targeting_border(true)
		_set_skill_buttons_disabled(true, skill)
		_refresh_player_preview_label()
		return

	if skill.skill_target == SkillData.SkillTarget.SELF:
		_pending_skill = skill
		_hover_damage_preview_enemy = null
		_hover_self_for_preview = false
		_set_enemy_targeting_enabled(false)
		_apply_enemy_targeting_border(false)
		_set_selection_status("「%s」 — 내 메카(왼쪽 패널)을 클릭하세요" % skill.skill_name)
		_set_skill_buttons_disabled(true, skill)
		_set_player_self_target_pending(true)
		_refresh_player_preview_label()
		return

	var target: Node = _pick_default_target(skill)
	if skill.skill_target == SkillData.SkillTarget.ENEMY and target is EnemyEntity:
		_set_selection_status("「%s」 → %s" % [skill.skill_name, (target as EnemyEntity).enemy_name])
	elif skill.skill_target == SkillData.SkillTarget.SELF:
		_set_selection_status("「%s」 — 자기 적용" % skill.skill_name)
	else:
		_set_selection_status("「%s」" % skill.skill_name)

	_set_skill_buttons_disabled(true, skill)
	if target != null:
		skill_selected.emit(skill, target)
	else:
		_set_selection_status("스킬을 선택하세요.")
		_set_skill_buttons_disabled(false)


func _living_enemies() -> Array[EnemyEntity]:
	_prune_invalid_current_enemies()
	var out: Array[EnemyEntity] = []
	for e: EnemyEntity in _current_enemies:
		if not e.is_defeated():
			out.append(e)
	return out


func _on_enemy_target_clicked(enemy: EnemyEntity) -> void:
	if _pending_skill == null:
		return
	var sk: SkillData = _pending_skill
	_pending_skill = null
	_hover_damage_preview_enemy = null
	_set_player_self_target_pending(false)
	_set_enemy_targeting_enabled(false)
	_apply_enemy_targeting_border(false)
	_set_selection_status("「%s」 → %s" % [sk.skill_name, enemy.enemy_name])
	skill_selected.emit(sk, enemy)
	_refresh_player_preview_label()


func _set_enemy_targeting_enabled(on: bool) -> void:
	for enemy: EnemyEntity in _current_enemies:
		var id: int = enemy.get_instance_id()
		if not _enemy_target_buttons.has(id):
			continue
		var btn: Button = _enemy_target_buttons[id] as Button
		if btn == null:
			continue
		btn.disabled = not on or enemy.is_defeated()


## 스킬 버튼은 타겟 확정 전까지 항상 활성 상태로 두고, 펜딩 스킬만 시각적으로 강조한다.
## `disabled` 인자는 강조를 모두 해제할지(false), 펜딩 스킬을 강조할지(true)를 의미하며,
## 더 이상 실제로 버튼을 비활성화하지 않는다. (다른 스킬로 자유롭게 교체 가능)
func _set_skill_buttons_disabled(disabled: bool, except_skill: SkillData = null) -> void:
	for s: SkillData in _skill_buttons.keys():
		var b: Button = _skill_buttons[s] as Button
		var fixed_disabled: bool = _skill_disable_reasons.has(s)
		b.disabled = fixed_disabled
		var base_tooltip: String = str(b.get_meta("skill_tooltip", ""))
		if fixed_disabled:
			b.tooltip_text = s.combat_tooltip_text(_skill_disable_reasons[s])
			_clear_skill_button_decoration(b)
			continue
		b.tooltip_text = base_tooltip
		if disabled and except_skill != null and s == except_skill:
			_style_skill_button_pending(b)
		else:
			_clear_skill_button_decoration(b)


func _set_selection_status(text: String) -> void:
	if selection_status != null:
		selection_status.text = text


func _style_skill_button_pending(b: Button) -> void:
	_clear_skill_button_decoration(b)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.38, 0.28, 1.0)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 1.0, 0.7, 1.0)
	sb.set_corner_radius_all(5)
	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = Color(0.26, 0.46, 0.34, 1.0)
	sb_hover.border_color = Color(0.65, 1.0, 0.82, 1.0)
	var sb_pressed: StyleBoxFlat = sb.duplicate()
	sb_pressed.bg_color = Color(0.16, 0.32, 0.22, 1.0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("pressed", sb_pressed)
	b.add_theme_color_override("font_color", Color(0.95, 1.0, 0.85, 1.0))
	b.add_theme_color_override("font_hover_color", Color(0.98, 1.0, 0.92, 1.0))


func _clear_skill_button_decoration(b: Button) -> void:
	b.remove_theme_stylebox_override("normal")
	b.remove_theme_stylebox_override("hover")
	b.remove_theme_stylebox_override("pressed")
	b.remove_theme_stylebox_override("disabled")
	b.remove_theme_color_override("font_color")
	b.remove_theme_color_override("font_hover_color")


func _apply_enemy_targeting_border(active: bool) -> void:
	for enemy: EnemyEntity in _current_enemies:
		var id: int = enemy.get_instance_id()
		if not _enemy_target_buttons.has(id):
			continue
		var b: Button = _enemy_target_buttons[id] as Button
		if b == null:
			continue
		b.modulate = Color.WHITE
		if not active:
			b.flat = true
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
			continue
		if enemy.is_defeated():
			continue
		b.flat = false
		var sb_n := StyleBoxFlat.new()
		sb_n.bg_color = Color(0.14, 0.18, 0.24, 0.92)
		sb_n.set_border_width_all(2)
		sb_n.border_color = Color(0.35, 0.82, 0.98, 1.0)
		sb_n.set_corner_radius_all(6)
		var sb_h: StyleBoxFlat = sb_n.duplicate() as StyleBoxFlat
		sb_h.set_border_width_all(3)
		sb_h.border_color = Color(0.55, 0.95, 1.0, 1.0)
		b.add_theme_stylebox_override("normal", sb_n)
		b.add_theme_stylebox_override("hover", sb_h)


func _on_enemy_hover(enemy: EnemyEntity, inside: bool) -> void:
	if _pending_skill == null:
		return
	if not _enemy_target_buttons.has(enemy.get_instance_id()):
		return
	var b: Button = _enemy_target_buttons[enemy.get_instance_id()] as Button
	if b == null or b.disabled:
		return
	if inside:
		b.modulate = Color(1.12, 1.18, 1.25)
		_hover_damage_preview_enemy = enemy
		_update_enemy_preview()
	else:
		b.modulate = Color.WHITE
		if _hover_damage_preview_enemy == enemy:
			_hover_damage_preview_enemy = null
		_update_enemy_preview()


func _pick_default_target(skill: SkillData) -> Node:
	match skill.skill_target:
		SkillData.SkillTarget.ENEMY:
			for enemy: EnemyEntity in _current_enemies:
				if not enemy.is_defeated():
					return enemy
		SkillData.SkillTarget.SELF:
			return get_tree().get_first_node_in_group("player")
	return null


func _update_enemy_preview() -> void:
	_prune_invalid_current_enemies()
	for enemy: EnemyEntity in _current_enemies:
		var id: int = enemy.get_instance_id()
		if not _enemy_forecast_labels.has(id) or not _enemy_hover_preview_labels.has(id):
			continue
		var forecast_lbl: Label = _enemy_forecast_labels[id] as Label
		var hover_lbl: Label = _enemy_hover_preview_labels[id] as Label
		if forecast_lbl == null or hover_lbl == null:
			continue
		if enemy.is_defeated():
			_set_enemy_label_text(forecast_lbl, "")
			_set_enemy_label_text(hover_lbl, "")
			continue

		if not enemy.next_actions.is_empty():
			var names: Array = enemy.next_actions.map(func(s: SkillData) -> String: return s.skill_name)
			_set_enemy_label_text(forecast_lbl, "예고: %s" % " → ".join(names))
		else:
			_set_enemy_label_text(forecast_lbl, "")

		if _pending_skill != null and _hover_damage_preview_enemy == enemy:
			_set_enemy_label_text(hover_lbl, _damage_preview_text_for_hover(enemy))
		else:
			_set_enemy_label_text(hover_lbl, "")


func _set_enemy_label_text(lbl: Label, text: String) -> void:
	lbl.text = text
	lbl.visible = not text.is_empty()


func _damage_preview_text_for_hover(enemy: EnemyEntity) -> String:
	var mecha: Node = get_tree().get_first_node_in_group("player")
	if mecha == null or not (mecha is MechaEntity):
		return ""
	var m: MechaEntity = mecha as MechaEntity
	var dmg: float = m.get_preview_outgoing_damage(_pending_skill, enemy)
	var hp_gain: float = m.get_preview_effective_hp_heal(_pending_skill)
	var sh_gain: float = m.get_preview_effective_shield_heal(_pending_skill)
	var parts: PackedStringArray = []
	if dmg > 0.0:
		var split: Vector2 = enemy.preview_incoming_damage_split(dmg, _pending_skill.armor_penetration)
		var effective_damage: float = split.x + split.y
		parts.append("예상 피해 %.0f (쉴드 %.0f · HP %.0f)" % [effective_damage, split.x, split.y])
	var self_bits: PackedStringArray = []
	if _pending_skill.skill_heal > 0.0:
		self_bits.append("나 HP +%.0f" % hp_gain)
	if _pending_skill.skill_defense > 0.0:
		self_bits.append("나 쉴드 +%.0f" % sh_gain)
	if not self_bits.is_empty():
		parts.append(" · ".join(self_bits))
	if parts.is_empty():
		return "예상 수치 없음"
	return " · ".join(parts)


func _ensure_player_target_strip() -> void:
	if _player_preview_label != null:
		return
	_player_preview_label = Label.new()
	_player_preview_label.add_theme_font_size_override("font_size", 11)
	_player_preview_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	_player_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mech_illustration.add_sibling(_player_preview_label)

	_player_target_catcher = Button.new()
	_player_target_catcher.flat = true
	_player_target_catcher.text = ""
	_player_target_catcher.focus_mode = Control.FOCUS_NONE
	_player_target_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_target_catcher.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_target_catcher.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_target_catcher.custom_minimum_size = Vector2(0.0, 120.0)
	_player_target_catcher.pressed.connect(_on_player_target_clicked)
	_player_target_catcher.mouse_entered.connect(_on_player_target_hover.bind(true))
	_player_target_catcher.mouse_exited.connect(_on_player_target_hover.bind(false))
	player_column.add_child(_player_target_catcher)


func _set_player_self_target_pending(on: bool) -> void:
	if _player_target_catcher == null:
		return
	if on:
		_set_player_column_highlight(true)
		_player_target_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
		_player_target_catcher.flat = false
		_player_target_catcher.text = "내 메카 클릭"
		_style_player_target_catcher_active()
	else:
		_set_player_column_highlight(false)
		_player_target_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_player_target_catcher.flat = true
		_player_target_catcher.text = ""
		_clear_player_target_catcher_style()


func _set_player_column_highlight(on: bool) -> void:
	if player_column == null:
		return
	if on:
		player_column.modulate = Color(0.9, 1.0, 0.92, 1.0)
	else:
		player_column.modulate = Color.WHITE


func _style_player_target_catcher_active() -> void:
	if _player_target_catcher == null:
		return
	var b: Button = _player_target_catcher
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.22, 0.18, 0.62)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.55, 1.0, 0.78, 1.0)
	sb.set_corner_radius_all(6)
	var sb_h: StyleBoxFlat = sb.duplicate()
	sb_h.bg_color = Color(0.18, 0.30, 0.22, 0.82)
	sb_h.set_border_width_all(3)
	sb_h.border_color = Color(0.7, 1.0, 0.86, 1.0)
	var sb_p: StyleBoxFlat = sb.duplicate()
	sb_p.bg_color = Color(0.10, 0.18, 0.14, 0.85)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_h)
	b.add_theme_stylebox_override("pressed", sb_p)
	b.add_theme_color_override("font_color", Color(0.92, 1.0, 0.95, 1.0))
	b.add_theme_color_override("font_hover_color", Color(0.98, 1.0, 0.98, 1.0))


func _clear_player_target_catcher_style() -> void:
	if _player_target_catcher == null:
		return
	var b: Button = _player_target_catcher
	b.remove_theme_stylebox_override("normal")
	b.remove_theme_stylebox_override("hover")
	b.remove_theme_stylebox_override("pressed")
	b.remove_theme_color_override("font_color")
	b.remove_theme_color_override("font_hover_color")


func _on_player_target_clicked() -> void:
	if _pending_skill == null or _pending_skill.skill_target != SkillData.SkillTarget.SELF:
		return
	var sk: SkillData = _pending_skill
	_pending_skill = null
	_hover_self_for_preview = false
	_set_player_self_target_pending(false)
	var target: Node = _pick_default_target(sk)
	_set_selection_status("「%s」 — 자기 적용" % sk.skill_name)
	skill_selected.emit(sk, target)
	_refresh_player_preview_label()


func _on_player_target_hover(inside: bool) -> void:
	if _pending_skill == null or _pending_skill.skill_target != SkillData.SkillTarget.SELF:
		return
	_hover_self_for_preview = inside
	_refresh_player_preview_label()


func _self_skill_preview_text(skill: SkillData) -> String:
	var mecha: Node = get_tree().get_first_node_in_group("player")
	if mecha == null or not (mecha is MechaEntity):
		return ""
	var m: MechaEntity = mecha as MechaEntity
	var hp_gain: float = m.get_preview_effective_hp_heal(skill)
	var sh_gain: float = m.get_preview_effective_shield_heal(skill)
	var bits: PackedStringArray = []
	if skill.skill_heal > 0.0:
		bits.append("HP +%.0f" % hp_gain)
	if skill.skill_defense > 0.0:
		bits.append("쉴드 +%.0f" % sh_gain)
	if bits.is_empty():
		return "회복·쉴드 수치 없음"
	return "예상 " + " · ".join(bits)


func _refresh_player_preview_label() -> void:
	if _player_preview_label == null:
		return
	if _pending_skill != null and _pending_skill.skill_target == SkillData.SkillTarget.SELF and _hover_self_for_preview:
		_player_preview_label.text = _self_skill_preview_text(_pending_skill)
	else:
		_player_preview_label.text = ""


func _rebuild_enemy_bars(enemies: Array[EnemyEntity]) -> void:
	for child: Node in enemy_container.get_children():
		child.queue_free()
	_enemy_hp_bars.clear()
	_enemy_shield_bars.clear()
	_enemy_hp_value_labels.clear()
	_enemy_shield_value_labels.clear()
	_enemy_forecast_labels.clear()
	_enemy_hover_preview_labels.clear()
	_enemy_target_buttons.clear()
	var collector_lanes: Dictionary = {}
	if _has_collector_formation(enemies):
		collector_lanes = _build_collector_lanes()

	for enemy: EnemyEntity in enemies:
		if not is_instance_valid(enemy):
			continue
		var eid: int = enemy.get_instance_id()
		var btn := Button.new()
		btn.flat = true
		btn.disabled = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_enemy_target_clicked.bind(enemy))
		btn.mouse_entered.connect(_on_enemy_hover.bind(enemy, true))
		btn.mouse_exited.connect(_on_enemy_hover.bind(enemy, false))
		btn.custom_minimum_size = ENEMY_SLOT_SIZE
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_enemy_target_buttons[eid] = btn

		var vbox := VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 4)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_child(vbox)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 8.0
		vbox.offset_right = -8.0
		vbox.offset_top = 4.0
		vbox.offset_bottom = -4.0

		var forecast := Label.new()
		forecast.add_theme_font_size_override("font_size", 11)
		forecast.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		forecast.clip_text = true
		forecast.visible = false
		forecast.custom_minimum_size = Vector2(0.0, 14.0)
		vbox.add_child(forecast)
		_enemy_forecast_labels[eid] = forecast

		var preview := Label.new()
		preview.add_theme_font_size_override("font_size", 11)
		preview.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0, 1.0))
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview.clip_text = true
		preview.visible = false
		preview.custom_minimum_size = Vector2(0.0, 14.0)
		vbox.add_child(preview)
		_enemy_hover_preview_labels[eid] = preview

		var name_label := Label.new()
		name_label.text = enemy.enemy_name
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.clip_text = true
		name_label.max_lines_visible = 2
		vbox.add_child(name_label)

		var role_label := _collector_role_label(enemy)
		if not role_label.is_empty():
			var role := Label.new()
			role.text = role_label
			role.add_theme_font_size_override("font_size", 10)
			role.add_theme_color_override("font_color", _collector_role_color(enemy))
			role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			role.clip_text = true
			role.custom_minimum_size = Vector2(0.0, 12.0)
			vbox.add_child(role)
			if enemy is BossCollectorEntity:
				_style_collector_core_button(btn, enemy as BossCollectorEntity)

		var sprite_frame := Panel.new()
		sprite_frame.custom_minimum_size = ENEMY_SPRITE_SIZE
		sprite_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sprite_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0.10, 0.12, 0.15, 0.95)
		frame_style.set_border_width_all(1)
		frame_style.border_color = Color(0.34, 0.38, 0.46, 1.0)
		frame_style.set_corner_radius_all(4)
		sprite_frame.add_theme_stylebox_override("panel", frame_style)
		vbox.add_child(sprite_frame)

		var sprite := TextureRect.new()
		sprite.texture = _enemy_sprite_texture(enemy)
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite_frame.add_child(sprite)
		sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sprite.offset_left = 8.0
		sprite.offset_right = -8.0
		sprite.offset_top = 8.0
		sprite.offset_bottom = -8.0

		var hp_row := Control.new()
		hp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp_row.custom_minimum_size = Vector2(0.0, 16.0)
		vbox.add_child(hp_row)

		var hp_bar := ProgressBar.new()
		hp_bar.max_value = enemy.enemy_max_hp
		hp_bar.value = enemy.current_hp
		hp_bar.show_percentage = false
		hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hp_row.add_child(hp_bar)
		hp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_enemy_hp_bars[eid] = hp_bar

		var hp_val := Label.new()
		hp_val.add_theme_font_size_override("font_size", 10)
		hp_val.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92, 1.0))
		hp_val.add_theme_color_override("font_outline_color", Color(0.08, 0.09, 0.12, 0.95))
		hp_val.add_theme_constant_override("outline_size", 2)
		hp_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hp_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hp_row.add_child(hp_val)
		hp_val.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hp_val.offset_left = 4.0
		hp_val.offset_right = -4.0
		_enemy_hp_value_labels[eid] = hp_val
		_set_enemy_hp_number_text(eid, enemy.current_hp, enemy.enemy_max_hp)

		if enemy.enemy_max_shield > 0.0:
			var sh_row := Control.new()
			sh_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sh_row.custom_minimum_size = Vector2(0.0, 14.0)
			vbox.add_child(sh_row)

			var shield_bar := ProgressBar.new()
			shield_bar.max_value = enemy.enemy_max_shield
			shield_bar.value = enemy.current_shield
			shield_bar.show_percentage = false
			shield_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sh_row.add_child(shield_bar)
			shield_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_enemy_shield_bars[eid] = shield_bar

			var sh_val := Label.new()
			sh_val.add_theme_font_size_override("font_size", 10)
			sh_val.add_theme_color_override("font_color", Color(0.65, 0.82, 0.98, 1.0))
			sh_val.add_theme_color_override("font_outline_color", Color(0.06, 0.1, 0.14, 0.95))
			sh_val.add_theme_constant_override("outline_size", 2)
			sh_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sh_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sh_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sh_row.add_child(sh_val)
			sh_val.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			sh_val.offset_left = 4.0
			sh_val.offset_right = -4.0
			_enemy_shield_value_labels[eid] = sh_val
			_set_enemy_shield_number_text(eid, enemy.current_shield, enemy.enemy_max_shield)

		var slot_parent: Control = enemy_container
		if not collector_lanes.is_empty():
			slot_parent = _collector_lane_for(enemy, collector_lanes)
		slot_parent.add_child(btn)

	_update_enemy_preview()
	_recompute_snipe_highlight()


func _has_collector_formation(enemies: Array[EnemyEntity]) -> bool:
	for enemy: EnemyEntity in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy is BossCollectorEntity:
			return true
	return false


func _prune_invalid_current_enemies() -> void:
	var living_refs: Array[EnemyEntity] = []
	for enemy: EnemyEntity in _current_enemies:
		if is_instance_valid(enemy):
			living_refs.append(enemy)
	_current_enemies = living_refs


func _build_collector_lanes() -> Dictionary:
	var formation := HBoxContainer.new()
	formation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	formation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	formation.alignment = BoxContainer.ALIGNMENT_CENTER
	formation.add_theme_constant_override("separation", 10)
	enemy_container.add_child(formation)
	return {
		"front": _add_collector_lane(formation, "전열"),
		"mid": _add_collector_lane(formation, "팔"),
		"back": _add_collector_lane(formation, "코어"),
	}


func _add_collector_lane(formation: HBoxContainer, title: String) -> HBoxContainer:
	var lane := VBoxContainer.new()
	lane.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lane.alignment = BoxContainer.ALIGNMENT_CENTER
	lane.add_theme_constant_override("separation", 4)
	formation.add_child(lane)

	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.70, 0.76, 0.86, 1.0))
	lane.add_child(label)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	lane.add_child(row)
	return row


func _collector_lane_for(enemy: EnemyEntity, lanes: Dictionary) -> Control:
	if enemy is BossCollectorEntity:
		return lanes["back"] as Control
	if enemy is CollectorArmEntity and (enemy as CollectorArmEntity).is_defense_arm:
		return lanes["front"] as Control
	return lanes["mid"] as Control


func _collector_role_label(enemy: EnemyEntity) -> String:
	if enemy is BossCollectorEntity:
		var boss := enemy as BossCollectorEntity
		if boss.is_exposed():
			return "코어 노출"
		var protection: int = int(round(boss.get_core_protection_ratio() * 100.0))
		return "코어 보호 %d%%" % protection
	if enemy is CollectorArmEntity and (enemy as CollectorArmEntity).is_defense_arm:
		return "방어 팔"
	if enemy is CollectorArmEntity:
		return "보호 팔"
	return ""


func _collector_role_color(enemy: EnemyEntity) -> Color:
	if enemy is BossCollectorEntity and (enemy as BossCollectorEntity).is_exposed():
		return Color(1.0, 0.70, 0.28, 1.0)
	if enemy is CollectorArmEntity and (enemy as CollectorArmEntity).is_defense_arm:
		return Color(0.44, 0.86, 1.0, 1.0)
	return Color(0.88, 0.78, 0.54, 1.0)


func _style_collector_core_button(btn: Button, boss: BossCollectorEntity) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	if boss.is_exposed():
		style.bg_color = Color(0.26, 0.15, 0.08, 0.88)
		style.border_color = Color(1.0, 0.70, 0.28, 1.0)
	else:
		style.bg_color = Color(0.16, 0.10, 0.13, 0.70)
		style.border_color = Color(0.82, 0.34, 0.42, 0.90)
	btn.flat = false
	btn.add_theme_stylebox_override("normal", style)


func _enemy_sprite_texture(enemy: EnemyEntity) -> Texture2D:
	if enemy.enemy_sprite != null:
		return enemy.enemy_sprite

	var image := Image.create(112, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var color := _enemy_placeholder_color(enemy.enemy_tier)
	image.fill_rect(Rect2i(33, 16, 46, 50), color.darkened(0.28))
	image.fill_rect(Rect2i(40, 9, 32, 19), color)
	image.fill_rect(Rect2i(20, 29, 22, 14), color.lightened(0.10))
	image.fill_rect(Rect2i(70, 29, 22, 14), color.lightened(0.10))
	image.fill_rect(Rect2i(38, 63, 14, 22), color)
	image.fill_rect(Rect2i(60, 63, 14, 22), color)
	image.fill_rect(Rect2i(27, 83, 27, 7), color.darkened(0.08))
	image.fill_rect(Rect2i(58, 83, 27, 7), color.darkened(0.08))
	return ImageTexture.create_from_image(image)


func _enemy_placeholder_color(tier: EnemyData.EnemyTier) -> Color:
	match tier:
		EnemyData.EnemyTier.ELITE: return Color(0.94, 0.56, 0.24, 1.0)
		EnemyData.EnemyTier.BOSS: return Color(0.88, 0.28, 0.40, 1.0)
		_: return Color(0.72, 0.44, 0.38, 1.0)


func _set_enemy_hp_number_text(id: int, cur: float, maxv: float) -> void:
	if not _enemy_hp_value_labels.has(id):
		return
	var lab: Label = _enemy_hp_value_labels[id] as Label
	if lab != null:
		lab.text = "%.0f / %.0f" % [cur, maxv]


func _set_enemy_shield_number_text(id: int, cur: float, maxv: float) -> void:
	if not _enemy_shield_value_labels.has(id):
		return
	var lab: Label = _enemy_shield_value_labels[id] as Label
	if lab != null:
		lab.text = "%.0f / %.0f" % [cur, maxv]


func _on_enemy_snipe_preview_changed(enemy: EnemyEntity, target_slot: int, active: bool) -> void:
	if enemy == null:
		return
	var enemy_id: int = enemy.get_instance_id()
	if not active or enemy.is_defeated() or target_slot == SNIPE_SLOT_NONE:
		_enemy_snipe_slots.erase(enemy_id)
	else:
		_enemy_snipe_slots[enemy_id] = target_slot
	_recompute_snipe_highlight()


func _prune_stale_snipe_sources() -> void:
	var alive_ids: Dictionary = {}
	for enemy: EnemyEntity in _current_enemies:
		if enemy == null or enemy.is_defeated():
			continue
		alive_ids[enemy.get_instance_id()] = true
	for enemy_id in _enemy_snipe_slots.keys().duplicate():
		if not alive_ids.has(enemy_id):
			_enemy_snipe_slots.erase(enemy_id)


func _recompute_snipe_highlight() -> void:
	_prune_stale_snipe_sources()
	var picked: int = SNIPE_SLOT_NONE
	for enemy: EnemyEntity in _current_enemies:
		if enemy == null or enemy.is_defeated():
			continue
		var enemy_id: int = enemy.get_instance_id()
		if _enemy_snipe_slots.has(enemy_id):
			picked = int(_enemy_snipe_slots[enemy_id])
			break
	_active_snipe_slot = picked
	_apply_snipe_highlight()


func _apply_snipe_highlight() -> void:
	var has_target: bool = _active_snipe_slot != SNIPE_SLOT_NONE
	for key in _mech_layers.keys():
		var slot: CoreData.CoreSlot = key as CoreData.CoreSlot
		var layer: TextureRect = _mech_layers[slot] as TextureRect
		if layer == null:
			continue
		layer.remove_theme_stylebox_override("normal")
		layer.modulate = Color.WHITE
		if has_target:
			if int(slot) == _active_snipe_slot:
				var sb := StyleBoxFlat.new()
				sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
				sb.set_border_width_all(2)
				sb.border_color = Color(1.0, 0.86, 0.2, 1.0)
				sb.set_corner_radius_all(4)
				layer.add_theme_stylebox_override("normal", sb)
			else:
				layer.modulate = Color(0.5, 0.5, 0.5, 1.0)

	for key in _hud_icons.keys():
		var slot: CoreData.CoreSlot = key as CoreData.CoreSlot
		var panel: Panel = _hud_icons[slot] as Panel
		if panel == null:
			continue
		var base_modulate: Color = Color.WHITE
		if panel.has_meta("base_modulate"):
			var maybe_color: Variant = panel.get_meta("base_modulate")
			if typeof(maybe_color) == TYPE_COLOR:
				base_modulate = maybe_color
		if panel.has_meta("base_style"):
			var base_style: StyleBoxFlat = panel.get_meta("base_style") as StyleBoxFlat
			if base_style != null:
				panel.add_theme_stylebox_override("panel", base_style.duplicate())
		panel.modulate = base_modulate
		if not has_target:
			continue
		if int(slot) == _active_snipe_slot:
			var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if style != null:
				style.set_border_width_all(maxi(style.border_width_left, 2))
				style.border_color = Color(1.0, 0.86, 0.2, 1.0)
				panel.add_theme_stylebox_override("panel", style)
		else:
			panel.modulate = Color(base_modulate.r * 0.6, base_modulate.g * 0.6, base_modulate.b * 0.6, base_modulate.a)

	if _snipe_pulse_tween != null:
		_snipe_pulse_tween.kill()
		_snipe_pulse_tween = null
	if has_target:
		var target_layer: TextureRect = null
		for key in _mech_layers.keys():
			var slot: CoreData.CoreSlot = key as CoreData.CoreSlot
			if int(slot) == _active_snipe_slot:
				target_layer = _mech_layers[slot] as TextureRect
				break
		if target_layer != null:
			_snipe_pulse_tween = create_tween().set_loops()
			_snipe_pulse_tween.tween_property(target_layer, "modulate:a", 0.72, 0.3)
			_snipe_pulse_tween.tween_property(target_layer, "modulate:a", 1.0, 0.3)


func _on_skill_used_global(entity: Node, skill: SkillData) -> void:
	var who: String = "플레이어"
	if entity is EnemyEntity:
		who = (entity as EnemyEntity).enemy_name
		_update_enemy_preview()
		_recompute_snipe_highlight()
	add_log("[%s] %s" % [who, skill.skill_name])


func _on_hp_changed(entity: Node, new_hp: float, max_hp: float) -> void:
	if entity is EnemyEntity:
		var e: EnemyEntity = entity as EnemyEntity
		var id: int = e.get_instance_id()
		if _enemy_hp_bars.has(id):
			var hb: ProgressBar = _enemy_hp_bars[id] as ProgressBar
			var delta: float = new_hp - hb.value
			hb.max_value = maxf(max_hp, 1.0)
			hb.value = new_hp
			if delta < -0.1:
				var pos: Vector2 = hb.global_position + Vector2(hb.size.x * 0.5, 0.0)
				_spawn_floating_label("-%.0f" % absf(delta), pos, FLOAT_COLORS["damage"])
		_set_enemy_hp_number_text(id, new_hp, max_hp)
		_update_enemy_preview()
		_recompute_snipe_highlight()
		return
	if entity == GameState:
		var delta: float = new_hp - _prev_player_hp
		_prev_player_hp = new_hp
		if delta < -0.1 and player_column != null:
			var pos: Vector2 = player_column.global_position + Vector2(player_column.size.x * 0.5, player_column.size.y * 0.3)
			_spawn_floating_label("-%.0f" % absf(delta), pos, FLOAT_COLORS["damage"])
			if absf(delta) > SHAKE_THRESHOLD:
				trigger_screen_shake()
		elif delta > 0.1 and player_column != null:
			var pos: Vector2 = player_column.global_position + Vector2(player_column.size.x * 0.5, player_column.size.y * 0.3)
			_spawn_floating_label("+%.0f" % delta, pos, FLOAT_COLORS["heal"])
		_refresh_player_preview_label()


func _on_shield_changed(entity: Node, new_shield: float, max_shield: float) -> void:
	if entity is EnemyEntity:
		var e: EnemyEntity = entity as EnemyEntity
		var id: int = e.get_instance_id()
		if _enemy_shield_bars.has(id):
			var sb: ProgressBar = _enemy_shield_bars[id] as ProgressBar
			sb.max_value = maxf(max_shield, 1.0)
			sb.value = new_shield
		_set_enemy_shield_number_text(id, new_shield, max_shield)
		return
	if entity == GameState:
		var delta: float = new_shield - _prev_player_shield
		_prev_player_shield = new_shield
		if player_column != null:
			if delta < -0.1:
				var pos: Vector2 = player_column.global_position + Vector2(player_column.size.x * 0.5, player_column.size.y * 0.4)
				_spawn_floating_label("-%.0f" % absf(delta), pos, FLOAT_COLORS["damage"])
			elif delta > 0.1:
				var pos: Vector2 = player_column.global_position + Vector2(player_column.size.x * 0.5, player_column.size.y * 0.4)
				_spawn_floating_label("+%.0f" % delta, pos, FLOAT_COLORS["shield"])
		_refresh_player_preview_label()


# ── 플로팅 데미지 레이블 ─────────────────────────────────────────────────────

func _spawn_floating_label(text: String, global_pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.z_index = 100
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.position = global_pos - global_position + Vector2(randf_range(-10.0, 10.0), -20.0)
	add_child(lbl)
	var start_y: float = lbl.position.y
	var t := lbl.create_tween()
	t.tween_property(lbl, "position:y", start_y - 40.0, 0.8)
	t.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.3)
	t.tween_callback(lbl.queue_free)


# ── 카메라 셰이크 ─────────────────────────────────────────────────────────────

func trigger_screen_shake(intensity: float = 1.0) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	for _i in 3:
		var offset := Vector2(randf_range(-5.0, 5.0), randf_range(-3.0, 3.0)) * intensity
		_shake_tween.tween_property(self, "position", offset, 0.05)
	_shake_tween.tween_property(self, "position", Vector2.ZERO, 0.05)


# ── 전투 로그 패널 ────────────────────────────────────────────────────────────

func _build_combat_log() -> void:
	_combat_log_label = RichTextLabel.new()
	_combat_log_label.bbcode_enabled = false
	_combat_log_label.fit_content = false
	_combat_log_label.scroll_active = false
	_combat_log_label.custom_minimum_size = Vector2(0.0, 110.0)
	_combat_log_label.add_theme_font_size_override("normal_font_size", 11)
	_combat_log_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_combat_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_column.add_child(_combat_log_label)

func add_log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > LOG_MAX_LINES:
		_log_lines.pop_front()
	if _combat_log_label != null:
		_combat_log_label.text = "\n".join(_log_lines)


# ── 디버프·재수집 핸들러 ──────────────────────────────────────────────────────

func _on_debuff_applied(target: Node, skill: SkillData, _debuff_type: int) -> void:
	if target is EnemyEntity:
		add_log("[디버프] %s ← %s" % [(target as EnemyEntity).enemy_name, skill.skill_name])

func _on_boss_arms_respawning() -> void:
	add_log("[수집가] 새 팔을 수집합니다...")
	await get_tree().create_timer(0.5).timeout
	add_log("[수집가] 팔 수집 완료")
