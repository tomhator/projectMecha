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
@onready var selection_status: Label = %SelectionStatus
@onready var turn_label: Label = %TurnLabel

var _current_enemies: Array[EnemyEntity] = []
## EnemyEntity 인스턴스 ID → UI 위젯 (노드 참조 키 불일치 방지)
var _enemy_hp_bars: Dictionary = {}  # int → ProgressBar
var _enemy_shield_bars: Dictionary = {}  # int → ProgressBar
var _enemy_hp_value_labels: Dictionary = {}  # int → Label
var _enemy_shield_value_labels: Dictionary = {}  # int → Label
var _enemy_preview_labels: Dictionary = {}  # int → Label
var _enemy_target_buttons: Dictionary = {}  # int → Button
var _skill_buttons: Dictionary = {}  # SkillData -> Button

var _pending_skill: SkillData = null
var _actions_remaining: int = 0
var _hover_damage_preview_enemy: EnemyEntity = null
var _hover_self_for_preview: bool = false
var _player_preview_label: Label = null
var _player_target_catcher: Button = null


func _ready() -> void:
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.skill_used.connect(_on_skill_used_global)
	EventBus.combat_turn_changed.connect(_on_combat_turn_changed)
	EventBus.part_durability_changed.connect(_on_part_durability_changed)
	battle_hbox.resized.connect(_apply_battle_column_split)
	_refresh_player_strip_from_state()
	_ensure_player_target_strip()
	_apply_battle_column_split.call_deferred()


func _on_combat_turn_changed(turn: int) -> void:
	if turn_label != null:
		turn_label.text = "턴 %d" % turn


func _on_part_durability_changed(_part: PartsData) -> void:
	_update_parts_display()


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
		line.add_theme_font_size_override("font_size", 11)
		if part != null:
			var dur_str: String = "■".repeat(part.durability) + "□".repeat(part.max_durability - part.durability)
			line.text = "%s: %s  %s" % [_slot_korean(slot), part.parts_name, dur_str]
			if part.is_broken():
				line.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			elif part.is_worn():
				line.add_theme_color_override("font_color", Color(1.0, 0.72, 0.28))
		else:
			line.text = "%s: (빈 슬롯)" % _slot_korean(slot)
			line.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		parts_labels.add_child(line)


func _slot_korean(slot: CoreData.CoreSlot) -> String:
	match slot:
		CoreData.CoreSlot.ARM_L: return "왼팔"
		CoreData.CoreSlot.ARM_R: return "오른팔"
		CoreData.CoreSlot.BACK:  return "등"
		CoreData.CoreSlot.LEG:   return "다리"
	return "슬롯"


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
	_rebuild_action_orbs()
	_rebuild_skill_buttons(available_skills)
	_rebuild_enemy_bars(enemies)
	_update_enemy_preview()
	_refresh_player_preview_label()
	_set_selection_status("스킬을 선택하세요.")
	_apply_battle_column_split.call_deferred()


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
	for child: Node in skill_container.get_children():
		child.queue_free()
	_skill_buttons.clear()
	for skill: SkillData in available_skills:
		var btn: Button = Button.new()
		btn.text = "%s [%d]" % [skill.skill_name, skill.skill_action_cost]
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_skill_button_pressed.bind(skill))
		skill_container.add_child(btn)
		_skill_buttons[skill] = btn


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
		b.disabled = false
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
	for enemy: EnemyEntity in _current_enemies:
		var id: int = enemy.get_instance_id()
		if not _enemy_preview_labels.has(id):
			continue
		var lbl: Label = _enemy_preview_labels[id] as Label
		if lbl == null:
			continue
		if enemy.is_defeated():
			lbl.text = ""
		elif _pending_skill != null and _hover_damage_preview_enemy == enemy:
			lbl.text = _damage_preview_text_for_hover(enemy)
		elif not enemy.next_actions.is_empty():
			var names: Array = enemy.next_actions.map(func(s: SkillData) -> String: return s.skill_name)
			lbl.text = "예고: %s" % " → ".join(names)
		else:
			lbl.text = ""


func _damage_preview_text_for_hover(enemy: EnemyEntity) -> String:
	var mecha: Node = get_tree().get_first_node_in_group("player")
	if mecha == null or not (mecha is MechaEntity):
		return ""
	var m: MechaEntity = mecha as MechaEntity
	var dmg: float = m.get_preview_outgoing_damage(_pending_skill)
	var hp_gain: float = m.get_preview_effective_hp_heal(_pending_skill)
	var sh_gain: float = m.get_preview_effective_shield_heal(_pending_skill)
	var parts: PackedStringArray = []
	if dmg > 0.0:
		var split: Vector2 = enemy.preview_incoming_damage_split(dmg)
		parts.append("예상 피해 %.0f (쉴드 %.0f · HP %.0f)" % [dmg, split.x, split.y])
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
	parts_labels.add_sibling(_player_preview_label)

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
		_player_target_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
		_player_target_catcher.flat = false
		_player_target_catcher.text = "내 메카 클릭"
		_style_player_target_catcher_active()
	else:
		_player_target_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_player_target_catcher.flat = true
		_player_target_catcher.text = ""
		_clear_player_target_catcher_style()


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
	_enemy_preview_labels.clear()
	_enemy_target_buttons.clear()

	for enemy: EnemyEntity in enemies:
		var eid: int = enemy.get_instance_id()
		var btn := Button.new()
		btn.flat = true
		btn.disabled = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_enemy_target_clicked.bind(enemy))
		btn.mouse_entered.connect(_on_enemy_hover.bind(enemy, true))
		btn.mouse_exited.connect(_on_enemy_hover.bind(enemy, false))
		btn.custom_minimum_size = Vector2(72.0, 120.0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

		var preview := Label.new()
		preview.add_theme_font_size_override("font_size", 11)
		preview.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		vbox.add_child(preview)
		_enemy_preview_labels[eid] = preview

		var name_label := Label.new()
		name_label.text = enemy.enemy_name
		name_label.add_theme_font_size_override("font_size", 13)
		vbox.add_child(name_label)

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

		enemy_container.add_child(btn)

	_update_enemy_preview()


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


func _on_skill_used_global(entity: Node, _skill: SkillData) -> void:
	if entity is EnemyEntity:
		_update_enemy_preview()


func _on_hp_changed(entity: Node, new_hp: float, max_hp: float) -> void:
	if entity is EnemyEntity:
		var e: EnemyEntity = entity as EnemyEntity
		var id: int = e.get_instance_id()
		if _enemy_hp_bars.has(id):
			var hb: ProgressBar = _enemy_hp_bars[id] as ProgressBar
			hb.max_value = maxf(max_hp, 1.0)
			hb.value = new_hp
		_set_enemy_hp_number_text(id, new_hp, max_hp)
		_update_enemy_preview()
		return
	if entity == GameState:
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
		_refresh_player_preview_label()
