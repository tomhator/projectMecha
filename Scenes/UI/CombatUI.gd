extends Control
class_name CombatUI

signal skill_selected(skill: SkillData, target: Node)

const BATTLE_H_SEP: float = 24.0
const ENEMY_COL_WIDTH_FRAC: float = 0.6
const ENEMY_COL_MIN_W: float = 200.0
const ENEMY_COL_MAX_W: float = 500.0

@onready var battle_hbox: HBoxContainer = %BattleHBox
@onready var player_column: VBoxContainer = %PlayerColumn
@onready var enemy_column: VBoxContainer = %EnemyColumn
@onready var skill_container: HBoxContainer = %SkillContainer
@onready var enemy_container: HBoxContainer = %EnemyContainer
@onready var action_orbs_row: HBoxContainer = %ActionOrbsRow
@onready var core_name_label: Label = %CoreNameLabel
@onready var parts_labels: VBoxContainer = %PartsLabels

var _current_enemies: Array[EnemyEntity] = []
var _enemy_hp_bars: Dictionary = {}
var _enemy_shield_bars: Dictionary = {}
var _enemy_preview_labels: Dictionary = {}
var _enemy_target_buttons: Dictionary = {}

var _pending_skill: SkillData = null
var _actions_remaining: int = 0


func _ready() -> void:
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.skill_used.connect(_on_skill_used_global)
	battle_hbox.resized.connect(_apply_battle_column_split)
	_refresh_player_strip_from_state()
	_apply_battle_column_split.call_deferred()


func _apply_battle_column_split() -> void:
	var total: float = battle_hbox.size.x
	if total < 2.0:
		return
	var avail: float = maxf(total - BATTLE_H_SEP, 0.0)
	var right_w: float = clampf(avail * ENEMY_COL_WIDTH_FRAC, ENEMY_COL_MIN_W, ENEMY_COL_MAX_W)
	var left_budget: float = avail - right_w
	if left_budget < 64.0:
		right_w = maxf(avail - 64.0, 0.0)
		right_w = clampf(right_w, 0.0, ENEMY_COL_MAX_W)
	enemy_column.custom_minimum_size = Vector2(right_w, 0.0)


func _refresh_player_strip_from_state() -> void:
	if GameState.current_core != null:
		core_name_label.text = GameState.current_core.core_name
	_update_parts_display()


func _update_parts_display() -> void:
	for child: Node in parts_labels.get_children():
		child.queue_free()
	if GameState.current_core == null:
		return
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		var line := Label.new()
		var slot_name: String = CoreData.CoreSlot.keys()[slot]
		if part != null:
			line.text = "%s: %s" % [slot_name, part.parts_name]
		else:
			line.text = "%s: (빈 슬롯)" % slot_name
		line.add_theme_font_size_override("font_size", 11)
		parts_labels.add_child(line)


func on_player_action_required(
	available_skills: Array[SkillData],
	enemies: Array[EnemyEntity],
	actions_remaining: int
) -> void:
	_pending_skill = null
	_set_enemy_targeting_enabled(false)
	_current_enemies = enemies
	_actions_remaining = actions_remaining
	_rebuild_action_orbs()
	_rebuild_skill_buttons(available_skills)
	_rebuild_enemy_bars(enemies)
	_update_enemy_preview()
	_apply_battle_column_split.call_deferred()


func _rebuild_action_orbs() -> void:
	for child: Node in action_orbs_row.get_children():
		child.queue_free()
	var max_act: int = GameState.current_core.core_action_count if GameState.current_core != null else 1
	for i: int in max_act:
		var orb := ColorRect.new()
		orb.custom_minimum_size = Vector2(22.0, 22.0)
		if i < _actions_remaining:
			orb.color = Color(0.35, 0.85, 0.45, 1.0)
		else:
			orb.color = Color(0.22, 0.25, 0.28, 1.0)
		action_orbs_row.add_child(orb)


func _rebuild_skill_buttons(available_skills: Array[SkillData]) -> void:
	for child: Node in skill_container.get_children():
		child.queue_free()
	for skill: SkillData in available_skills:
		var btn: Button = Button.new()
		btn.text = "%s [%d]" % [skill.skill_name, skill.skill_action_cost]
		btn.pressed.connect(_on_skill_button_pressed.bind(skill))
		skill_container.add_child(btn)


func _on_skill_button_pressed(skill: SkillData) -> void:
	var living: Array[EnemyEntity] = _living_enemies()
	if skill.skill_target == SkillData.SkillTarget.ENEMY and living.size() > 1:
		_pending_skill = skill
		_set_enemy_targeting_enabled(true)
		_set_skill_buttons_disabled(true)
		return

	_set_skill_buttons_disabled(true)
	var target: Node = _pick_default_target(skill)
	if target != null:
		skill_selected.emit(skill, target)
	else:
		_set_skill_buttons_disabled(false)


func _living_enemies() -> Array[EnemyEntity]:
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
	_set_enemy_targeting_enabled(false)
	skill_selected.emit(sk, enemy)


func _set_enemy_targeting_enabled(on: bool) -> void:
	for enemy: EnemyEntity in _enemy_target_buttons:
		var btn: Button = _enemy_target_buttons[enemy] as Button
		if btn == null:
			continue
		btn.disabled = not on or enemy.is_defeated()


func _set_skill_buttons_disabled(disabled: bool) -> void:
	for child: Node in skill_container.get_children():
		if child is Button:
			(child as Button).disabled = disabled


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
	for enemy: EnemyEntity in _enemy_preview_labels:
		var lbl: Label = _enemy_preview_labels[enemy] as Label
		if lbl == null:
			continue
		if enemy.is_defeated():
			lbl.text = ""
		elif not enemy.next_actions.is_empty():
			var names: Array = enemy.next_actions.map(func(s: SkillData) -> String: return s.skill_name)
			lbl.text = "예고: %s" % " → ".join(names)
		else:
			lbl.text = ""


func _rebuild_enemy_bars(enemies: Array[EnemyEntity]) -> void:
	for child: Node in enemy_container.get_children():
		child.queue_free()
	_enemy_hp_bars.clear()
	_enemy_shield_bars.clear()
	_enemy_preview_labels.clear()
	_enemy_target_buttons.clear()

	for enemy: EnemyEntity in enemies:
		var btn := Button.new()
		btn.flat = true
		btn.disabled = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_enemy_target_clicked.bind(enemy))
		btn.custom_minimum_size = Vector2(72.0, 120.0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_enemy_target_buttons[enemy] = btn

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

		var preview := Label.new()
		preview.add_theme_font_size_override("font_size", 11)
		preview.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		vbox.add_child(preview)
		_enemy_preview_labels[enemy] = preview

		var name_label := Label.new()
		name_label.text = enemy.enemy_name
		name_label.add_theme_font_size_override("font_size", 13)
		vbox.add_child(name_label)

		var hp_bar := ProgressBar.new()
		hp_bar.max_value = enemy.enemy_max_hp
		hp_bar.value = enemy.current_hp
		hp_bar.custom_minimum_size = Vector2(0.0, 16.0)
		hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp_bar.show_percentage = false
		vbox.add_child(hp_bar)
		_enemy_hp_bars[enemy] = hp_bar

		if enemy.enemy_max_shield > 0.0:
			var shield_bar := ProgressBar.new()
			shield_bar.max_value = enemy.enemy_max_shield
			shield_bar.value = enemy.current_shield
			shield_bar.custom_minimum_size = Vector2(0.0, 14.0)
			shield_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			shield_bar.show_percentage = false
			vbox.add_child(shield_bar)
			_enemy_shield_bars[enemy] = shield_bar

		enemy_container.add_child(btn)

	_update_enemy_preview()


func _on_skill_used_global(entity: Node, _skill: SkillData) -> void:
	if entity is EnemyEntity:
		_update_enemy_preview()


func _on_hp_changed(entity: Node, new_hp: float, max_hp: float) -> void:
	if entity is EnemyEntity:
		var e: EnemyEntity = entity as EnemyEntity
		if _enemy_hp_bars.has(e):
			(_enemy_hp_bars[e] as ProgressBar).value = new_hp
		_update_enemy_preview()
		return


func _on_shield_changed(entity: Node, new_shield: float, max_shield: float) -> void:
	if entity is EnemyEntity:
		var e: EnemyEntity = entity as EnemyEntity
		if _enemy_shield_bars.has(e):
			(_enemy_shield_bars[e] as ProgressBar).value = new_shield
		return
