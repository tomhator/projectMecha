extends Node

class_name EnemyEntity

@export var enemy_name: String = ""
@export var enemy_tier: EnemyData.EnemyTier = EnemyData.EnemyTier.NORMAL
@export var enemy_sprite: Texture2D = null
@export var counts_for_combat_rewards: bool = true
@export var enemy_max_hp: float = 0.0
@export var enemy_max_shield: float = 0.0
@export var attack_multiplier: float = 1.0
@export var enemy_action_count: int = 2
@export var skills: Array[SkillData] = []
const SNIPE_SLOT_NONE: int = -1

var current_hp: float = 0.0
var current_shield: float = 0.0
var next_actions: Array[SkillData] = []
var _preview_target_slot: int = SNIPE_SLOT_NONE
var _active_debuffs: Dictionary = {}  # SkillData.SkillDebuff (int) → turns_remaining
var _skill_use_counts: Dictionary = {}  # SkillData -> executions this combat

func setup() -> void:
	current_hp = enemy_max_hp
	current_shield = enemy_max_shield
	decide_next_actions()
	print("[%s] 등장 | HP: %.0f | 쉴드: %.0f" % [enemy_name, current_hp, current_shield])

func setup_from_data(data: EnemyData) -> void:
	enemy_name = data.enemy_name
	enemy_tier = data.enemy_tier
	enemy_sprite = data.enemy_sprite
	counts_for_combat_rewards = data.counts_for_combat_rewards
	enemy_max_hp = data.enemy_max_hp
	enemy_max_shield = data.enemy_max_shield
	attack_multiplier = data.attack_multiplier
	enemy_action_count = data.enemy_action_count
	skills = data.skills

func take_damage(damage: float, penetration: float = 0.0) -> void:
	damage = maxf(damage, 0.0)
	current_shield = clampf(current_shield, 0.0, enemy_max_shield)
	current_hp = clampf(current_hp, 0.0, enemy_max_hp)
	var pen := clampf(penetration, 0.0, 1.0)
	var absorbed: float = minf(current_shield, damage * (1.0 - pen))
	current_shield -= absorbed
	current_hp -= (damage - absorbed)
	current_hp = clampf(current_hp, 0.0, enemy_max_hp)
	current_shield = clampf(current_shield, 0.0, enemy_max_shield)
	var to_hp: float = damage - absorbed
	var absorb_note: String = ""
	if absorbed > 0.0:
		absorb_note = " — 쉴드 %.0f 흡수, HP에 %.0f" % [absorbed, to_hp]
	elif damage > 0.0:
		absorb_note = " — 쉴드 없음, HP에 전부"
	if pen > 0.0:
		absorb_note += " [관통 %.0f%%]" % (pen * 100)
	print("  > [%s] 피격: %.0f 데미지%s → HP: %.0f | 쉴드: %.0f" % [
		enemy_name, damage, absorb_note, current_hp, current_shield
	])
	EventBus.hp_changed.emit(self, current_hp, enemy_max_hp)
	EventBus.shield_changed.emit(self, current_shield, enemy_max_shield)
	if is_defeated():
		print("  > [%s] 격파!" % enemy_name)
		_preview_target_slot = SNIPE_SLOT_NONE
		EventBus.enemy_snipe_preview_changed.emit(self, _preview_target_slot, false)


## `take_damage`와 동일한 흡수 규칙으로, 들어오는 피해가 쉴드·HP에 어떻게 나뉘는지 미리 계산 (UI 프리뷰용).
func preview_incoming_damage_split(damage: float, penetration: float = 0.0) -> Vector2:
	damage = maxf(damage, 0.0)
	var sh: float = clampf(current_shield, 0.0, enemy_max_shield)
	var pen := clampf(penetration, 0.0, 1.0)
	var absorbed: float = minf(sh, damage * (1.0 - pen))
	var to_hp: float = damage - absorbed
	return Vector2(absorbed, to_hp)


func is_defeated() -> bool:
	return current_hp <= 0.0


func is_targetable() -> bool:
	return not is_defeated()


func execute_actions(target: Node, allies: Array = []) -> void:
	for action: SkillData in next_actions:
		_execute_single_action(action, target, allies)
	decide_next_actions()


func _execute_single_action(action: SkillData, target: Node, allies: Array = []) -> void:
	print("[%s] '%s' 사용" % [enemy_name, action.skill_name])
	var effect_target: Node = target
	if action.skill_target == SkillData.SkillTarget.SELF:
		effect_target = self
	elif action.skill_target == SkillData.SkillTarget.ALLY:
		effect_target = _resolve_ally_target(action, allies)
	if action.skill_damage > 0.0:
		var hits: int = maxi(action.hit_count, 1)
		for _i in hits:
			target.take_damage(action.skill_damage * attack_multiplier, action.armor_penetration)
		if action.target_slot != SkillData.TargetSlot.NONE:
			_apply_snipe_to_slot(target, action.target_slot)
	if action.skill_defense > 0.0 and effect_target is EnemyEntity:
		(effect_target as EnemyEntity).restore_shield(action.skill_defense)
	if action.skill_heal > 0.0 and effect_target is EnemyEntity:
		(effect_target as EnemyEntity).restore_hp(action.skill_heal)
	if action.summon_enemy != null and _can_execute_summon(action):
		_summon_enemy(action.summon_enemy)
	_skill_use_counts[action] = int(_skill_use_counts.get(action, 0)) + 1
	EventBus.skill_used.emit(self, action)


func _apply_snipe_to_slot(target: Node, slot_index: int) -> void:
	if not target.has_method("get_part_at_slot"):
		return
	var part: PartsData = target.get_part_at_slot(slot_index)
	if part == null:
		print("  > [저격] 슬롯 %d 비어 있음 — 내구도 효과 무효" % slot_index)
		return
	if part.is_broken():
		print("  > [저격] %s 이미 파괴됨 — 내구도 효과 무효" % part.parts_name)
		return
	part.durability = maxi(part.durability - 1, 0)
	EventBus.part_durability_changed.emit(part)
	print("  > [저격] %s 내구도 감소 → %d" % [part.parts_name, part.durability])
	if part.is_broken():
		print("  > [파츠 파괴] %s" % part.parts_name)

func decide_next_actions() -> void:
	next_actions.clear()
	if skills.is_empty():
		_publish_snipe_preview()
		return
	var ap_remaining: int = enemy_action_count
	var candidates: Array[SkillData] = skills.filter(
		func(s: SkillData) -> bool: return s.skill_action_cost <= ap_remaining and _can_preview_skill(s)
	)
	while not candidates.is_empty():
		var chosen: SkillData = candidates[randi() % candidates.size()]
		next_actions.append(chosen)
		ap_remaining -= chosen.skill_action_cost
		candidates = skills.filter(
			func(s: SkillData) -> bool: return s.skill_action_cost <= ap_remaining and _can_preview_skill(s)
		)
	print("[%s] 다음 행동 예고: %s" % [
		enemy_name,
		" → ".join(next_actions.map(func(s: SkillData) -> String: return s.skill_name))
	])
	_publish_snipe_preview()


func _publish_snipe_preview() -> void:
	_preview_target_slot = _resolve_snipe_preview_slot()
	var active: bool = _preview_target_slot != SNIPE_SLOT_NONE and not is_defeated()
	EventBus.enemy_snipe_preview_changed.emit(self, _preview_target_slot, active)


func _resolve_snipe_preview_slot() -> int:
	for action: SkillData in next_actions:
		if action == null:
			continue
		if action.skill_target != SkillData.SkillTarget.ENEMY:
			continue
		if action.target_slot == SNIPE_SLOT_NONE:
			continue
		if not _player_has_part_at(action.target_slot):
			continue
		return action.target_slot
	return SNIPE_SLOT_NONE


func _player_has_part_at(slot_index: int) -> bool:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		if int(slot) == slot_index:
			return GameState.equipped_parts[slot] != null
	return false

func _apply_debuff(debuff_type: int, turns: int = 2) -> void:
	_active_debuffs[debuff_type] = turns
	print("  > [%s] 디버프 적용: %d (%d턴)" % [enemy_name, debuff_type, turns])

func has_any_debuff() -> bool:
	return not _active_debuffs.is_empty()

func tick_debuffs() -> void:
	var expired: Array = []
	for debuff: int in _active_debuffs:
		_active_debuffs[debuff] -= 1
		if _active_debuffs[debuff] <= 0:
			expired.append(debuff)
	for d: int in expired:
		_active_debuffs.erase(d)


func restore_hp(amount: float) -> void:
	var before: float = current_hp
	current_hp = minf(current_hp + amount, enemy_max_hp)
	EventBus.hp_changed.emit(self, current_hp, enemy_max_hp)
	print("  > [%s] HP +%.0f" % [enemy_name, current_hp - before])

func restore_shield(amount: float) -> void:
	var before: float = clampf(current_shield, 0.0, enemy_max_shield)
	current_shield = before
	var add: float = maxf(amount, 0.0)
	var after: float = minf(current_shield + add, enemy_max_shield)
	var gained: float = after - before
	current_shield = after
	EventBus.shield_changed.emit(self, current_shield, enemy_max_shield)
	if add > 0.0:
		if gained < add - 0.001:
			print(
				"  > [%s] 쉴드 회복 시도 +%.0f → 실제 +%.0f (최대 %.0f / 현재 %.0f)"
				% [enemy_name, add, gained, enemy_max_shield, current_shield]
			)
		else:
			print("  > [%s] 쉴드 +%.0f (%.0f / %.0f)" % [enemy_name, gained, current_shield, enemy_max_shield])


func _heal_hp(amount: float) -> void:
	restore_hp(amount)


func _heal_shield(amount: float) -> void:
	restore_shield(amount)


func _can_preview_skill(skill: SkillData) -> bool:
	return skill.summon_enemy == null or _can_execute_summon(skill)


func _can_execute_summon(skill: SkillData) -> bool:
	if skill.summon_enemy == null:
		return false
	if skill.summon_limit_per_combat <= 0:
		return true
	return int(_skill_use_counts.get(skill, 0)) < skill.summon_limit_per_combat


func _summon_enemy(data: EnemyData) -> void:
	var summoned := EnemyEntity.new()
	summoned.name = data.enemy_name
	summoned.setup_from_data(data)
	summoned.setup()
	EventBus.enemy_spawn_requested.emit(summoned)


func _resolve_ally_target(action: SkillData, allies: Array) -> EnemyEntity:
	var living: Array[EnemyEntity] = []
	for ally in allies:
		if ally is EnemyEntity and not (ally as EnemyEntity).is_defeated():
			living.append(ally as EnemyEntity)
	if living.is_empty():
		return self
	if action.skill_heal > 0.0:
		var selected_hp: EnemyEntity = living[0]
		for ally: EnemyEntity in living:
			if _hp_ratio(ally) < _hp_ratio(selected_hp):
				selected_hp = ally
		return selected_hp
	if action.skill_defense > 0.0:
		var shield_targets: Array[EnemyEntity] = living.filter(
			func(ally: EnemyEntity) -> bool: return ally.enemy_max_shield > ally.current_shield
		)
		if shield_targets.is_empty():
			return self
		var selected_shield: EnemyEntity = shield_targets[0]
		for ally: EnemyEntity in shield_targets:
			if ally.current_shield < selected_shield.current_shield:
				selected_shield = ally
		return selected_shield
	return self


func _hp_ratio(enemy: EnemyEntity) -> float:
	if enemy.enemy_max_hp <= 0.0:
		return 1.0
	return enemy.current_hp / enemy.enemy_max_hp
