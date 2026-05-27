extends Node

class_name MechaEntity

const UNDEFINED_BEHAVIOR_META: String = "undefined_behavior_modifier"
const UNDEFINED_BEHAVIOR_MIN: float = -0.20
const UNDEFINED_BEHAVIOR_MAX: float = 0.60
const COUNTER_INSTINCT_META: String = "counter_instinct_active"
const ZOMBIE_PENDING_META: String = "zombie_process_pending"
const ZOMBIE_ACTIVE_META: String = "zombie_process_active"
const ZOMBIE_CONSUMED_META: String = "zombie_process_consumed"
const SIEGE_BUFF_KEY: int = 1005
const STATIC_OUTPUT_AFFIX_BONUSES: Dictionary = {
	"mindless": -0.10,
	"greedy": 0.10,
	"overload": 0.25,
}

var available_skills: Array[SkillData] = []
var _skill_to_part: Dictionary = {}  # SkillData -> PartsData (코어 스킬은 null)
var _serious_punch_pending: bool = false
var _serious_punch_used_parts: Dictionary = {}  # PartsData -> true
var _turn_skill_use_count: int = 0
var _next_skill_free: bool = false
var _granted_actions_pending: int = 0
var _active_buffs: Dictionary = {}  # int(SkillBuff) -> Dictionary
var _single_use_skills: Dictionary = {}  # SkillData -> true
var _current_enemy_targets: Array[EnemyEntity] = []
var _pending_block_hits: int = 0
var _pending_counter_damage: float = 0.0
var _pending_counter_ratio: float = 0.0


func setup() -> void:
	GameState.recalculate_runtime_stats()
	_skill_to_part.clear()
	available_skills = GameState.get_combat_skill_order()
	for skill: SkillData in available_skills:
		var part: PartsData = GameState.get_part_for_combat_skill(skill)
		if part != null:
			_skill_to_part[skill] = part


func get_available_skills() -> Array[SkillData]:
	return available_skills.filter(func(s: SkillData) -> bool:
		if not get_part_ability_disable_reason(s).is_empty():
			return false
		if _single_use_skills.has(s):
			return false
		var part: PartsData = _skill_to_part.get(s)
		if part != null and not _part_allows_skill_use(part):
			return false
		return true
	)


func get_display_skills() -> Array[SkillData]:
	return available_skills


func can_use_skill(skill: SkillData) -> bool:
	if skill == null:
		return false
	if not available_skills.has(skill):
		return false
	if _single_use_skills.has(skill):
		return false
	if not get_part_ability_disable_reason(skill).is_empty():
		return false
	var part: PartsData = _skill_to_part.get(skill)
	if part != null and not _part_allows_skill_use(part):
		return false
	return true


func on_player_turn_started() -> void:
	_turn_skill_use_count = 0
	_refresh_turn_start_affixes()
	_activate_pending_zombie_parts()
	_tick_player_buffs()


func on_player_turn_ended() -> void:
	_expire_active_zombie_parts()


func set_current_enemy_targets(targets: Array) -> void:
	_current_enemy_targets.clear()
	for target in targets:
		if target is EnemyEntity:
			_current_enemy_targets.append(target as EnemyEntity)


func get_turn_action_delta() -> int:
	return -1 if _is_siege_mode_active() else 0


func consume_granted_actions() -> int:
	var out: int = _granted_actions_pending
	_granted_actions_pending = 0
	return out


func get_skill_action_cost(skill: SkillData) -> int:
	if skill == null:
		return 0
	if _next_skill_free:
		return 0
	var cost: int = skill.skill_action_cost
	var part: PartsData = _get_skill_part(skill)
	if part != null and not part.is_broken():
		if _has_affix(part, "productive"):
			cost -= 1
		if _has_affix(part, "kernel_panic") and _is_low_hp_state():
			cost -= 1
		if _has_affix(part, "momentum") and _turn_skill_use_count == 1:
			cost -= 1
	return maxi(cost, 0)


func get_part_at_slot(slot_index: int) -> PartsData:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		if int(slot) == slot_index:
			return GameState.equipped_parts[slot]
	return null


## 지정 슬롯의 파츠를 강탈당함. 슬롯을 비우고 스킬 목록에서 제거.
func steal_part_at_slot(slot_index: int) -> PartsData:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		if int(slot) != slot_index:
			continue
		var part: PartsData = GameState.equipped_parts[slot]
		if part == null:
			return null
		GameState.equipped_parts[slot] = null
		for skill: SkillData in part.parts_skills:
			available_skills.erase(skill)
			_skill_to_part.erase(skill)
		GameState.sync_runtime_extra_arm_slot()
		EventBus.part_stolen.emit(part, slot_index)
		print("[MechaEntity] '%s' 강탈됨 — 슬롯 %d 비워짐" % [part.parts_name, slot_index])
		return part
	return null


func notify_part_broken(part: PartsData) -> void:
	_mark_part_broken(part)


## `use_skill`의 공격 피해량과 동일한 계수 (UI 예상 피해용).
func get_preview_outgoing_damage(skill: SkillData, target: Node = null) -> float:
	if skill == null or skill.skill_damage <= 0.0:
		return 0.0
	var hits: int = _effective_hit_count(skill)
	return skill.skill_damage * GameState.attack_multiplier * _output_mult(skill, target, false) * float(hits)


## `use_skill`의 HP 회복과 동일한 상한(코어 최대 HP) 적용 후 실제로 오를 양
func get_preview_effective_hp_heal(skill: SkillData) -> float:
	if skill == null or skill.skill_heal <= 0.0 or skill.has_buff or GameState.current_core == null:
		return 0.0
	var predicted: float = skill.skill_heal * _output_mult(skill, null, false)
	return minf(predicted, maxf(GameState.current_core.core_hp - GameState.current_hp, 0.0))


## `use_skill`의 쉴드 회복과 동일한 상한(코어 최대 쉴드) 적용 후 실제로 오를 양
func get_preview_effective_shield_heal(skill: SkillData) -> float:
	if skill == null or GameState.current_core == null:
		return 0.0
	var shield_value: float = 0.0
	if skill.shield_amount > 0.0 and not skill.has_buff:
		shield_value += skill.shield_amount
	if skill.skill_defense > 0.0 and not skill.has_buff and not skill.has_counter_attack and skill.invincible_hit_count <= 0:
		shield_value += skill.skill_defense
	if shield_value <= 0.0:
		return 0.0
	var predicted: float = shield_value * _output_mult(skill, null, false)
	return minf(predicted, maxf(GameState.current_core.core_shield - GameState.current_shield, 0.0))


func use_skill(skill: SkillData, target: Variant) -> void:
	if skill == null:
		return
	var free_for_this_skill: bool = _next_skill_free
	if free_for_this_skill:
		_next_skill_free = false

	if skill.core_skill_role == SkillData.CoreSkillRole.PART_ABILITY:
		_use_part_ability(skill)

	var target_node: Node = target as Node if target is Node else null
	var mult: float = _output_mult(skill, target_node, true)
	var dealt_damage: float = 0.0
	if skill.skill_damage > 0.0 and target is Node:
		dealt_damage = _deal_single_target_damage(skill, target as Node, mult)

	if skill.has_debuff and target != null and target is Node and (target as Node).has_method("_apply_debuff"):
		(target as Node)._apply_debuff(skill.debuff_type, _debuff_turns(skill))
		EventBus.skill_debuff_applied.emit(target as Node, skill, skill.debuff_type)

	_apply_self_effects(skill, target, mult, dealt_damage)
	_finalize_skill_use(skill, free_for_this_skill)


func use_multi_target_skill(skill: SkillData, targets: Array) -> void:
	if skill == null or targets.is_empty():
		return
	var free_for_this_skill: bool = _next_skill_free
	if free_for_this_skill:
		_next_skill_free = false

	if skill.core_skill_role == SkillData.CoreSkillRole.PART_ABILITY:
		_use_part_ability(skill)

	var mult: float = _output_mult_for_targets(skill, targets, true)
	var dealt_damage: float = 0.0
	if skill.skill_damage > 0.0:
		var total_damage: float = skill.skill_damage * GameState.attack_multiplier * mult
		var damage_per_target: float = total_damage / float(targets.size())
		for target: EnemyEntity in targets:
			if target == null or not target.has_method("take_damage"):
				continue
			dealt_damage += float(target.take_damage(damage_per_target, skill.armor_penetration))
		print("  > 멀티타겟 공격: %s (총 %.0f / 대상당 %.0f 데미지%s)" % [
			skill.skill_name,
			total_damage,
			damage_per_target,
			_mult_note(mult)
		])

	if skill.has_debuff:
		for target: EnemyEntity in targets:
			if target != null and target.has_method("_apply_debuff"):
				target._apply_debuff(skill.debuff_type, _debuff_turns(skill))
				EventBus.skill_debuff_applied.emit(target, skill, skill.debuff_type)

	_apply_self_effects(skill, self, mult, dealt_damage)
	_finalize_skill_use(skill, free_for_this_skill)


func get_part_ability_disable_reason(skill: SkillData) -> String:
	if skill == null or skill.core_skill_role != SkillData.CoreSkillRole.PART_ABILITY:
		return ""
	match skill.part_ability_kind:
		SkillData.PartAbilityKind.EMERGENCY_SWAP:
			if _find_emergency_swap_part() == null:
				return "교체 가능한 인벤토리 파츠 없음"
		SkillData.PartAbilityKind.BROKEN_THROW, SkillData.PartAbilityKind.SCRAP_PATCH:
			if not _has_broken_part_to_consume():
				return "소모할 파손 파츠 없음"
		_:
			return "미구현 파츠 어빌리티"
	return ""


func _use_part_ability(skill: SkillData) -> void:
	match skill.part_ability_kind:
		SkillData.PartAbilityKind.EMERGENCY_SWAP:
			_use_emergency_swap()
		SkillData.PartAbilityKind.BROKEN_THROW, SkillData.PartAbilityKind.SCRAP_PATCH:
			_consume_broken_part()


func _use_emergency_swap() -> void:
	var incoming: PartsData = _find_emergency_swap_part()
	if incoming == null:
		return
	var slot: CoreData.CoreSlot = _slot_for_part_type(incoming.parts_type)
	var existing: PartsData = GameState.equipped_parts.get(slot)
	if existing != null:
		_break_part(existing)
	if not GameState.remove_from_inventory(incoming):
		return
	if existing != null:
		GameState.add_to_inventory(existing)
	GameState.equip_part(incoming, slot)
	setup()
	print("  > [긴급 교체] %s 장착" % incoming.parts_name)


func _find_emergency_swap_part() -> PartsData:
	for part: PartsData in GameState.inventory:
		if part != null and not part.is_broken():
			return part
	return null


func _has_broken_part_to_consume() -> bool:
	for part: PartsData in GameState.inventory:
		if part != null and part.is_broken():
			return true
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var equipped: PartsData = GameState.equipped_parts[slot]
		if equipped != null and equipped.is_broken():
			return true
	return false


func _consume_broken_part() -> PartsData:
	for part: PartsData in GameState.inventory:
		if part != null and part.is_broken():
			GameState.remove_from_inventory(part)
			print("  > [파손 파츠 소모] %s" % part.parts_name)
			return part
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var equipped: PartsData = GameState.equipped_parts[slot]
		if equipped != null and equipped.is_broken():
			GameState.unequip_part(slot)
			print("  > [파손 파츠 소모] %s" % equipped.parts_name)
			return equipped
	return null


func _slot_for_part_type(part_type: PartsData.PartsType) -> CoreData.CoreSlot:
	match part_type:
		PartsData.PartsType.ARM_L:
			return CoreData.CoreSlot.ARM_L
		PartsData.PartsType.ARM_R:
			return CoreData.CoreSlot.ARM_R
		PartsData.PartsType.BACK:
			return CoreData.CoreSlot.BACK
		PartsData.PartsType.LEG:
			return CoreData.CoreSlot.LEG
	return CoreData.CoreSlot.ARM_L


func _deal_single_target_damage(skill: SkillData, target: Node, mult: float) -> float:
	var part: PartsData = _get_skill_part(skill)
	var total_dealt: float = 0.0
	var hits: int = _effective_hit_count(skill)
	for _i: int in hits:
		var hit_target: Node = _resolve_hit_target(part, target)
		if hit_target == null or not hit_target.has_method("take_damage"):
			continue
		var actual_damage: float = skill.skill_damage * GameState.attack_multiplier * mult
		total_dealt += float(hit_target.take_damage(actual_damage, skill.armor_penetration))
	print("  > 공격: %s (%.0f x%d 데미지%s)" % [
		skill.skill_name,
		skill.skill_damage * GameState.attack_multiplier * mult,
		hits,
		_mult_note(mult)
	])
	return total_dealt


func _resolve_hit_target(part: PartsData, fallback: Node) -> Node:
	if not _has_affix(part, "mindless") or part.is_broken():
		return fallback
	var candidates: Array[EnemyEntity] = []
	for enemy: EnemyEntity in _current_enemy_targets:
		if enemy != null and enemy.is_targetable():
			candidates.append(enemy)
	if candidates.is_empty():
		return fallback
	return candidates[randi() % candidates.size()]


func _effective_hit_count(skill: SkillData) -> int:
	var hits: int = maxi(skill.hit_count, 1)
	var part: PartsData = _get_skill_part(skill)
	if _has_affix(part, "mindless") and not part.is_broken():
		hits += 3
	return hits


func _apply_self_effects(skill: SkillData, target: Variant, mult: float, dealt_damage: float) -> void:
	if skill.permanent_max_hp > 0.0 and GameState.current_core != null:
		GameState.current_core.core_hp += skill.permanent_max_hp
		GameState.heal_hp(skill.permanent_max_hp)
		print("  > 최대 HP +%.0f" % skill.permanent_max_hp)

	if skill.repairs_selected_part and target is PartsData:
		var part := target as PartsData
		part.durability = part.max_durability
		EventBus.part_durability_changed.emit(part)
		print("  > 현장 수리: %s 손상도 최대 복구" % part.parts_name)

	if skill.repairs_all_parts:
		for slot: CoreData.CoreSlot in GameState.equipped_parts:
			var part: PartsData = GameState.equipped_parts[slot]
			if part == null:
				continue
			var before: int = part.durability
			part.durability = mini(part.max_durability, part.durability + 2)
			if part.durability != before:
				EventBus.part_durability_changed.emit(part)
		print("  > 드론 정비: 전 파츠 손상도 +2")

	if skill.extends_buffs:
		_extend_active_buffs(maxi(skill.buff_turns, 1))

	if skill.has_buff:
		_apply_skill_buff(skill)

	if skill.invincible_hit_count > 0:
		_pending_block_hits += skill.invincible_hit_count

	if skill.has_counter_attack:
		_pending_block_hits = maxi(_pending_block_hits, maxi(skill.invincible_hit_count, 1))
		if skill.skill_defense > 0.0 and skill.skill_defense < 1.0:
			_pending_counter_ratio = maxf(_pending_counter_ratio, skill.skill_defense)
		else:
			_pending_counter_damage = maxf(_pending_counter_damage, skill.skill_defense)

	var shield_gain: float = 0.0
	if skill.shield_amount > 0.0 and not skill.has_buff:
		shield_gain += skill.shield_amount
	if skill.skill_defense > 0.0 and not skill.has_buff and not skill.has_counter_attack and skill.invincible_hit_count <= 0:
		shield_gain += skill.skill_defense
	if shield_gain > 0.0:
		var actual_shield: float = shield_gain * mult
		GameState.heal_shield(actual_shield)
		print("  > 방어: %s (쉴드 +%.0f%s)" % [skill.skill_name, actual_shield, _mult_note(mult)])

	if skill.skill_heal > 0.0 and not skill.has_buff:
		var actual_heal: float = skill.skill_heal * mult
		GameState.heal_hp(actual_heal)
		print("  > 회복: %s (HP +%.0f%s)" % [skill.skill_name, actual_heal, _mult_note(mult)])

	var drain_ratio: float = skill.heal_from_damage_ratio + _lifedrain_ratio(skill)
	if drain_ratio > 0.0 and dealt_damage > 0.0:
		var drain_heal: float = roundf(dealt_damage * drain_ratio)
		GameState.heal_hp(drain_heal)
		print("  > 흡수 회복: HP +%.0f" % drain_heal)

	if skill.grants_action > 0:
		_granted_actions_pending += skill.grants_action
	if skill.grants_next_free_skill:
		_next_skill_free = true


func _apply_skill_buff(skill: SkillData) -> void:
	if skill.is_toggle and skill.skill_id == 241:
		if _active_buffs.has(SIEGE_BUFF_KEY):
			_active_buffs.erase(SIEGE_BUFF_KEY)
			print("  > 시즈모드 해제")
		else:
			_active_buffs[SIEGE_BUFF_KEY] = {
				"turns": -1,
				"value": skill.buff_value,
				"source_skill_id": skill.skill_id,
			}
			print("  > 시즈모드 돌입")
		return

	var turns: int = maxi(skill.buff_turns, 1)
	_active_buffs[skill.buff_type] = {
		"turns": turns,
		"value": skill.buff_value,
		"flat": skill.skill_defense,
		"shield": skill.shield_amount,
		"heal": skill.skill_heal,
		"source_skill_id": skill.skill_id,
	}
	EventBus.skill_buff_applied.emit(self, skill, skill.buff_type)


func _extend_active_buffs(turns: int) -> void:
	for buff_type: int in _active_buffs.keys():
		var buff: Dictionary = _active_buffs[buff_type]
		if int(buff.get("turns", 0)) >= 0:
			buff["turns"] = int(buff.get("turns", 0)) + turns
		_active_buffs[buff_type] = buff


func _tick_player_buffs() -> void:
	var expired: Array[int] = []
	for buff_type: int in _active_buffs.keys():
		var buff: Dictionary = _active_buffs[buff_type]
		match buff_type:
			SkillData.SkillBuff.SHIELD_REGEN:
				var shield: float = float(buff.get("shield", 0.0))
				if shield > 0.0:
					GameState.heal_shield(shield)
			SkillData.SkillBuff.HEAL_UP:
				var heal: float = float(buff.get("heal", 0.0))
				if heal > 0.0:
					GameState.heal_hp(heal)
		var turns: int = int(buff.get("turns", 0))
		if turns > 0:
			turns -= 1
			buff["turns"] = turns
			if turns <= 0:
				expired.append(buff_type)
		_active_buffs[buff_type] = buff
	for buff_type: int in expired:
		_active_buffs.erase(buff_type)

	var siege_part: PartsData = _siege_mode_part()
	if siege_part != null and siege_part.durability > 0:
		siege_part.durability = maxi(siege_part.durability - 1, 0)
		EventBus.part_durability_changed.emit(siege_part)
		if siege_part.is_broken():
			_mark_part_broken(siege_part)


func _output_mult(skill: SkillData, target: Node = null, consume_temp: bool = false) -> float:
	var part: PartsData = _get_skill_part(skill)
	if part == null:
		return _global_output_mult()
	var mult: float = maxf(part.stat_multiplier, 0.01) * _global_output_mult()
	var bonus_sum: float = _affix_bonus_sum(part, target, consume_temp)
	mult *= maxf(1.0 + bonus_sum, 0.1)
	if part.is_worn():
		mult *= 0.7
	if part.parts_type == PartsData.PartsType.LEG and GameState.is_overloaded() and not _overload_penalty_ignored():
		mult *= 0.8
	return mult


func _output_mult_for_targets(skill: SkillData, targets: Array, consume_temp: bool = false) -> float:
	var part: PartsData = _get_skill_part(skill)
	if part == null:
		return _global_output_mult()
	var mult: float = maxf(part.stat_multiplier, 0.01) * _global_output_mult()
	var bonus_sum: float = _affix_bonus_sum_for_targets(part, targets, consume_temp)
	mult *= maxf(1.0 + bonus_sum, 0.1)
	if part.is_worn():
		mult *= 0.7
	if part.parts_type == PartsData.PartsType.LEG and GameState.is_overloaded() and not _overload_penalty_ignored():
		mult *= 0.8
	return mult


func _global_output_mult() -> float:
	var bonus: float = 0.0
	if _active_buffs.has(SkillData.SkillBuff.DAMAGE_BOOST):
		bonus += float((_active_buffs[SkillData.SkillBuff.DAMAGE_BOOST] as Dictionary).get("value", 0.0))
	if _active_buffs.has(SIEGE_BUFF_KEY):
		bonus += float((_active_buffs[SIEGE_BUFF_KEY] as Dictionary).get("value", 0.0))
	return maxf(1.0 + bonus, 0.1)


func _get_skill_part(skill: SkillData) -> PartsData:
	return _skill_to_part.get(skill)


func _has_affix(part: PartsData, affix_id: String) -> bool:
	return part != null and part.rolled_affixes.has(affix_id)


func _is_low_hp_state() -> bool:
	if GameState.current_core == null or GameState.current_core.core_hp <= 0.0:
		return false
	return (GameState.current_hp / GameState.current_core.core_hp) <= 0.3


func _refresh_turn_start_affixes() -> void:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		_refresh_undefined_behavior(part)


func _refresh_undefined_behavior(part: PartsData) -> void:
	if part == null:
		return
	if _has_affix(part, "undefined_behavior") and not part.is_broken():
		part.set_meta(UNDEFINED_BEHAVIOR_META, randf_range(UNDEFINED_BEHAVIOR_MIN, UNDEFINED_BEHAVIOR_MAX))
		return
	if part.has_meta(UNDEFINED_BEHAVIOR_META):
		part.remove_meta(UNDEFINED_BEHAVIOR_META)


func _affix_bonus_sum(part: PartsData, target: Node, consume_temp: bool) -> float:
	var targets: Array[Node] = []
	if target != null:
		targets.append(target)
	return _affix_bonus_sum_for_targets(part, targets, consume_temp)


func _affix_bonus_sum_for_targets(part: PartsData, targets: Array, consume_temp: bool) -> float:
	# 파괴된 파츠는 zombie_process 사용권만 남고 Affix 보정은 모두 꺼진다.
	if part == null or part.is_broken():
		return 0.0
	var sum: float = 0.0
	sum += _static_affix_bonus_sum(part)
	sum += _conditional_affix_bonus_sum(part, targets)
	sum += _runtime_affix_bonus_sum(part, consume_temp)
	return sum


func _static_affix_bonus_sum(part: PartsData) -> float:
	var sum: float = 0.0
	for affix_id: String in STATIC_OUTPUT_AFFIX_BONUSES:
		if _has_affix(part, affix_id):
			sum += float(STATIC_OUTPUT_AFFIX_BONUSES[affix_id])
	return sum


func _conditional_affix_bonus_sum(part: PartsData, targets: Array) -> float:
	var sum: float = 0.0
	if _has_affix(part, "kernel_panic") and _is_low_hp_state():
		sum += 0.30
	if _has_affix(part, "backdoor") and _any_target_has_debuff(targets):
		sum += 0.25
	return sum


func _runtime_affix_bonus_sum(part: PartsData, consume_temp: bool) -> float:
	var sum: float = 0.0
	sum += _undefined_behavior_bonus(part)
	sum += _counter_instinct_bonus(part, consume_temp)
	sum += _serious_punch_bonus(consume_temp)
	if _has_affix(part, "gambler"):
		sum += randf_range(0.0, 0.5) if consume_temp else 0.25
	return sum


func _undefined_behavior_bonus(part: PartsData) -> float:
	if not part.has_meta(UNDEFINED_BEHAVIOR_META):
		return 0.0
	var turn_mod: Variant = part.get_meta(UNDEFINED_BEHAVIOR_META)
	if typeof(turn_mod) == TYPE_FLOAT or typeof(turn_mod) == TYPE_INT:
		return float(turn_mod)
	return 0.0


func _counter_instinct_bonus(part: PartsData, consume_temp: bool) -> float:
	if _has_affix(part, "counter_instinct"):
		var active: bool = bool(part.get_meta(COUNTER_INSTINCT_META, false))
		if active:
			if consume_temp:
				part.set_meta(COUNTER_INSTINCT_META, false)
			return 0.20
	return 0.0


func _serious_punch_bonus(consume_temp: bool) -> float:
	if _serious_punch_pending:
		if consume_temp:
			_serious_punch_pending = false
		return 1.0
	return 0.0


func _any_target_has_debuff(targets: Array) -> bool:
	for target in targets:
		if target != null and target.has_method("has_any_debuff") and target.has_any_debuff():
			return true
	return false


func _lifedrain_ratio(skill: SkillData) -> float:
	var part: PartsData = _get_skill_part(skill)
	if _has_affix(part, "lifedrain") and not part.is_broken():
		return 0.15
	return 0.0


func _arm_serious_punch_if_needed(skill: SkillData) -> void:
	var part: PartsData = _get_skill_part(skill)
	if not _has_affix(part, "serious_punch") or part.is_broken():
		return
	if _serious_punch_used_parts.has(part):
		return
	_serious_punch_pending = true
	_serious_punch_used_parts[part] = true


func _finalize_skill_use(skill: SkillData, skip_durability_cost: bool = false) -> void:
	EventBus.skill_used.emit(self, skill)
	_arm_serious_punch_if_needed(skill)
	if skill.single_use_per_combat:
		_single_use_skills[skill] = true

	var part: PartsData = _skill_to_part.get(skill)
	if part != null:
		if _is_zombie_active(part):
			part.set_meta(ZOMBIE_ACTIVE_META, false)
			part.set_meta(ZOMBIE_CONSUMED_META, true)
		elif not skip_durability_cost and part.durability > 0:
			var loss: int = 1
			if _has_affix(part, "overload") and not part.is_broken():
				loss += 1
			part.durability = maxi(part.durability - loss, 0)
			EventBus.part_durability_changed.emit(part)
			if part.durability == 0:
				_mark_part_broken(part)

	_turn_skill_use_count += 1


func _break_part(part: PartsData) -> void:
	if part == null or part.is_broken():
		return
	part.durability = 0
	EventBus.part_durability_changed.emit(part)
	_mark_part_broken(part)


func _mark_part_broken(part: PartsData) -> void:
	if part == null:
		return
	if _has_affix(part, "zombie_process") and not bool(part.get_meta(ZOMBIE_CONSUMED_META, false)):
		part.set_meta(ZOMBIE_PENDING_META, true)
	print("  > [파츠 파괴] %s" % part.parts_name)
	GameState.sync_runtime_extra_arm_slot()


func _part_allows_skill_use(part: PartsData) -> bool:
	if part == null:
		return true
	if not part.is_broken():
		return true
	return _is_zombie_active(part)


func _is_zombie_active(part: PartsData) -> bool:
	return part != null and bool(part.get_meta(ZOMBIE_ACTIVE_META, false)) and not bool(part.get_meta(ZOMBIE_CONSUMED_META, false))


func _activate_pending_zombie_parts() -> void:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if part == null:
			continue
		if bool(part.get_meta(ZOMBIE_PENDING_META, false)) and not bool(part.get_meta(ZOMBIE_CONSUMED_META, false)):
			part.set_meta(ZOMBIE_PENDING_META, false)
			part.set_meta(ZOMBIE_ACTIVE_META, true)


func _expire_active_zombie_parts() -> void:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if part == null:
			continue
		if bool(part.get_meta(ZOMBIE_ACTIVE_META, false)):
			part.set_meta(ZOMBIE_ACTIVE_META, false)
			part.set_meta(ZOMBIE_CONSUMED_META, true)


func _activate_counter_instinct_on_hit() -> void:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if _has_affix(part, "counter_instinct") and not part.is_broken():
			part.set_meta(COUNTER_INSTINCT_META, true)


func _debuff_turns(skill: SkillData) -> int:
	return skill.buff_turns if skill.buff_turns > 0 else 2


func _is_siege_mode_active() -> bool:
	if not _active_buffs.has(SIEGE_BUFF_KEY):
		return false
	var buff: Dictionary = _active_buffs[SIEGE_BUFF_KEY]
	return int(buff.get("source_skill_id", 0)) == 241


func _siege_mode_part() -> PartsData:
	if not _is_siege_mode_active():
		return null
	for skill: SkillData in _skill_to_part.keys():
		if skill.skill_id == 241:
			return _skill_to_part[skill]
	return null


func _overload_penalty_ignored() -> bool:
	return _active_buffs.has(SkillData.SkillBuff.DAMAGE_REDUCTION) and int((_active_buffs[SkillData.SkillBuff.DAMAGE_REDUCTION] as Dictionary).get("source_skill_id", 0)) == 242


func _flat_damage_reduction() -> float:
	var value: float = 0.0
	if _active_buffs.has(SkillData.SkillBuff.DEFENSE_UP):
		value += float((_active_buffs[SkillData.SkillBuff.DEFENSE_UP] as Dictionary).get("flat", 0.0))
	return value


func _ratio_damage_reduction() -> float:
	var value: float = 0.0
	if _active_buffs.has(SkillData.SkillBuff.DAMAGE_REDUCTION):
		value += float((_active_buffs[SkillData.SkillBuff.DAMAGE_REDUCTION] as Dictionary).get("value", 0.0))
	return clampf(value, 0.0, 0.9)


func _evasion_chance() -> float:
	if not _active_buffs.has(SkillData.SkillBuff.EVASION_UP):
		return 0.0
	return clampf(float((_active_buffs[SkillData.SkillBuff.EVASION_UP] as Dictionary).get("value", 0.0)), 0.0, 0.95)


func _mult_note(mult: float) -> String:
	if mult >= 1.0:
		return ""
	if mult < 0.6:
		return " [손상-30%·과부하-20%]"
	if mult < 0.75:
		return " [손상-30%]"
	return " [과부하-20%]"


# GameState에 HP가 있으므로 위임하되, 방어·회피·반격 상태는 여기서 먼저 처리한다.
func take_damage(amount: float, penetration: float = 0.0, source: Node = null) -> float:
	var incoming: float = maxf(amount, 0.0)
	if incoming <= 0.0:
		return 0.0
	if _evasion_chance() > 0.0 and randf() < _evasion_chance():
		print("  > 플레이어 회피")
		return 0.0

	var blocked: bool = false
	if _pending_block_hits > 0:
		_pending_block_hits -= 1
		blocked = true

	var counter_damage: float = 0.0
	if blocked:
		counter_damage = maxf(_pending_counter_damage, incoming * _pending_counter_ratio)
		if _pending_block_hits <= 0:
			_pending_counter_damage = 0.0
			_pending_counter_ratio = 0.0
		print("  > 플레이어 차단")
	else:
		incoming = maxf(incoming - _flat_damage_reduction(), 0.0)
		incoming *= 1.0 - _ratio_damage_reduction()

	var dealt: float = 0.0
	if not blocked:
		print("  > 플레이어 피격: %.0f 데미지 (HP: %.0f → %.0f)" % [
			incoming,
			GameState.current_hp,
			maxf(GameState.current_hp - incoming, 0.0)
		])
		dealt = GameState.take_damage(incoming, penetration)
		_activate_counter_instinct_on_hit()

	if counter_damage > 0.0 and source != null and source.has_method("take_damage"):
		source.take_damage(counter_damage, 0.0)
		print("  > 반격: %.0f 데미지" % counter_damage)
	return dealt
