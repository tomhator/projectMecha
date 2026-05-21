extends Node

class_name MechaEntity

var available_skills: Array[SkillData] = []
var _skill_to_part: Dictionary = {}  # SkillData → PartsData (코어 스킬은 null)
var _serious_punch_pending: bool = false

func setup() -> void:
	available_skills.clear()
	_skill_to_part.clear()
	if GameState.active_core_skill != null:
		available_skills.append(GameState.active_core_skill)
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if part != null:
			for skill: SkillData in part.parts_skills:
				available_skills.append(skill)
				_skill_to_part[skill] = part

func get_available_skills() -> Array[SkillData]:
	return available_skills.filter(func(s: SkillData) -> bool:
		if s.skill_type == SkillData.SkillType.PASSIVE:
			return false
		var part: PartsData = _skill_to_part.get(s)
		if part != null and part.is_broken():
			return false
		return true
	)


func get_display_skills() -> Array[SkillData]:
	return available_skills.filter(func(s: SkillData) -> bool:
		return s.skill_type != SkillData.SkillType.PASSIVE
	)


func can_use_skill(skill: SkillData) -> bool:
	if skill == null:
		return false
	if not available_skills.has(skill):
		return false
	if skill.skill_type == SkillData.SkillType.PASSIVE:
		return false
	var part: PartsData = _skill_to_part.get(skill)
	if part != null and part.is_broken():
		return false
	return true


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
		EventBus.part_stolen.emit(part, slot_index)
		print("[MechaEntity] '%s' 강탈됨 — 슬롯 %d 비워짐" % [part.parts_name, slot_index])
		return part
	return null


## `use_skill`의 공격 피해량과 동일한 계수 (UI 예상 피해용).
func get_preview_outgoing_damage(skill: SkillData, target: Node = null) -> float:
	if skill.skill_damage <= 0.0:
		return 0.0
	return skill.skill_damage * GameState.attack_multiplier * _output_mult(skill, target, false)


## `use_skill`의 HP 회복과 동일한 상한(코어 최대 HP) 적용 후 실제로 오를 양
func get_preview_effective_hp_heal(skill: SkillData) -> float:
	if skill.skill_heal <= 0.0 or GameState.current_core == null:
		return 0.0
	var predicted: float = skill.skill_heal * _output_mult(skill, null, false)
	return minf(predicted, maxf(GameState.current_core.core_hp - GameState.current_hp, 0.0))


## `use_skill`의 쉴드 회복과 동일한 상한(코어 최대 쉴드) 적용 후 실제로 오를 양
func get_preview_effective_shield_heal(skill: SkillData) -> float:
	if skill.skill_defense <= 0.0 or GameState.current_core == null:
		return 0.0
	var predicted: float = skill.skill_defense * _output_mult(skill, null, false)
	return minf(predicted, maxf(GameState.current_core.core_shield - GameState.current_shield, 0.0))


func use_skill(skill: SkillData, target: Node) -> void:
	var mult: float = _output_mult(skill, target, true)

	if skill.skill_damage > 0.0:
		if target != null and target.has_method("take_damage"):
			var actual_damage: float = skill.skill_damage * GameState.attack_multiplier * mult
			target.take_damage(actual_damage, skill.armor_penetration)
			print("  > 공격: %s (%.0f 데미지%s)" % [skill.skill_name, actual_damage, _mult_note(mult)])

	if skill.skill_defense > 0.0:
		var actual_shield: float = skill.skill_defense * mult
		GameState.heal_shield(actual_shield)
		print("  > 방어: %s (쉴드 +%.0f%s)" % [skill.skill_name, actual_shield, _mult_note(mult)])

	if skill.skill_heal > 0.0:
		var actual_heal: float = skill.skill_heal * mult
		GameState.heal_hp(actual_heal)
		print("  > 회복: %s (HP +%.0f%s)" % [skill.skill_name, actual_heal, _mult_note(mult)])

	if skill.has_debuff and target != null and target.has_method("_apply_debuff"):
		target._apply_debuff(skill.debuff_type)
		EventBus.skill_debuff_applied.emit(target, skill, skill.debuff_type)

	EventBus.skill_used.emit(self, skill)
	_arm_serious_punch_if_needed(skill)

	var part: PartsData = _skill_to_part.get(skill)
	if part != null and part.durability > 0:
		part.durability -= 1
		EventBus.part_durability_changed.emit(part)
		if part.durability == 0:
			print("  > [파츠 파괴] %s" % part.parts_name)


func _output_mult(skill: SkillData, target: Node = null, consume_temp: bool = false) -> float:
	var part: PartsData = _get_skill_part(skill)
	if part == null:
		return 1.0
	var mult: float = 1.0
	var bonus_sum: float = _affix_bonus_sum(part, target, consume_temp)
	mult *= maxf(1.0 + bonus_sum, 0.1)
	if part.is_worn():
		mult *= 0.7
	if part.parts_type == PartsData.PartsType.LEG and GameState.is_overloaded():
		mult *= 0.8
	return mult


func _get_skill_part(skill: SkillData) -> PartsData:
	return _skill_to_part.get(skill)


func _has_affix(part: PartsData, affix_id: String) -> bool:
	return part != null and part.rolled_affixes.has(affix_id)


func _is_low_hp_state() -> bool:
	if GameState.current_core == null or GameState.current_core.core_hp <= 0.0:
		return false
	return (GameState.current_hp / GameState.current_core.core_hp) <= 0.3


func _affix_bonus_sum(part: PartsData, target: Node, consume_temp: bool) -> float:
	# 파괴된 파츠는 Affix 효과 없음
	# TODO: zombie_process affix 구현 시 → and not _has_affix(part, "zombie_process")
	if part != null and part.is_broken():
		return 0.0
	var sum: float = 0.0
	if _has_affix(part, "mindless"):
		sum -= 0.10
	if _has_affix(part, "greedy"):
		sum += 0.10
	if _has_affix(part, "overload"):
		sum += 0.25
	if _has_affix(part, "kernel_panic") and _is_low_hp_state():
		sum += 0.30
	if _has_affix(part, "backdoor") and target != null and target.has_method("has_any_debuff") and target.has_any_debuff():
		sum += 0.25

	if part.has_meta("undefined_behavior_modifier"):
		var turn_mod: Variant = part.get_meta("undefined_behavior_modifier")
		if typeof(turn_mod) in [TYPE_FLOAT, TYPE_INT]:
			sum += float(turn_mod)

	if _has_affix(part, "counter_instinct"):
		var active: bool = bool(part.get_meta("counter_instinct_active", false))
		if active:
			sum += 0.20
			if consume_temp:
				part.set_meta("counter_instinct_active", false)

	if _serious_punch_pending:
		sum += 1.0
		if consume_temp:
			_serious_punch_pending = false

	return sum


func _arm_serious_punch_if_needed(skill: SkillData) -> void:
	var part: PartsData = _get_skill_part(skill)
	if _has_affix(part, "serious_punch"):
		_serious_punch_pending = true


func _activate_counter_instinct_on_hit() -> void:
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if _has_affix(part, "counter_instinct"):
			part.set_meta("counter_instinct_active", true)


func _mult_note(mult: float) -> String:
	if mult >= 1.0:
		return ""
	if mult < 0.6:   # 0.7 × 0.8 = 0.56
		return " [손상-30%·과부하-20%]"
	if mult < 0.75:  # 0.7
		return " [손상-30%]"
	return " [과부하-20%]"  # 0.8

# GameState에 HP가 있으므로 위임 — 인터페이스 통일 목적
func take_damage(amount: float, penetration: float = 0.0) -> void:
	print("  > 플레이어 피격: %.0f 데미지 (HP: %.0f → %.0f)" % [
		amount,
		GameState.current_hp,
		maxf(GameState.current_hp - amount, 0.0)
	])
	GameState.take_damage(amount, penetration)
	_activate_counter_instinct_on_hit()
