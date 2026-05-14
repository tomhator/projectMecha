extends Node

class_name MechaEntity

var available_skills: Array[SkillData] = []
var _skill_to_part: Dictionary = {}  # SkillData → PartsData (코어 스킬은 null)

func setup() -> void:
	available_skills.clear()
	_skill_to_part.clear()
	available_skills.append_array(GameState.current_core.core_skills)
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if part != null:
			for skill: SkillData in part.parts_skills:
				available_skills.append(skill)
				_skill_to_part[skill] = part

func get_available_skills() -> Array[SkillData]:
	return available_skills.filter(func(s: SkillData) -> bool:
		return s.skill_type != SkillData.SkillType.PASSIVE
	)


## `use_skill`의 공격 피해량과 동일한 계수 (UI 예상 피해용).
func get_preview_outgoing_damage(skill: SkillData) -> float:
	if skill.skill_damage <= 0.0:
		return 0.0
	return skill.skill_damage * GameState.attack_multiplier * _output_mult(skill)


## `use_skill`의 HP 회복과 동일한 상한(코어 최대 HP) 적용 후 실제로 오를 양
func get_preview_effective_hp_heal(skill: SkillData) -> float:
	if skill.skill_heal <= 0.0 or GameState.current_core == null:
		return 0.0
	return minf(skill.skill_heal, maxf(GameState.current_core.core_hp - GameState.current_hp, 0.0))


## `use_skill`의 쉴드 회복과 동일한 상한(코어 최대 쉴드) 적용 후 실제로 오를 양
func get_preview_effective_shield_heal(skill: SkillData) -> float:
	if skill.skill_defense <= 0.0 or GameState.current_core == null:
		return 0.0
	return minf(skill.skill_defense, maxf(GameState.current_core.core_shield - GameState.current_shield, 0.0))


func use_skill(skill: SkillData, target: Node) -> void:
	var mult: float = _output_mult(skill)

	if skill.skill_damage > 0.0:
		if target != null and target.has_method("take_damage"):
			var actual_damage: float = skill.skill_damage * GameState.attack_multiplier * mult
			target.take_damage(actual_damage)
			print("  > 공격: %s (%.0f 데미지%s)" % [skill.skill_name, actual_damage, _mult_note(mult)])

	if skill.skill_defense > 0.0:
		var actual_shield: float = skill.skill_defense * mult
		GameState.heal_shield(actual_shield)
		print("  > 방어: %s (쉴드 +%.0f%s)" % [skill.skill_name, actual_shield, _mult_note(mult)])

	if skill.skill_heal > 0.0:
		var actual_heal: float = skill.skill_heal * mult
		GameState.heal_hp(actual_heal)
		print("  > 회복: %s (HP +%.0f%s)" % [skill.skill_name, actual_heal, _mult_note(mult)])

	EventBus.skill_used.emit(self, skill)

	var part: PartsData = _skill_to_part.get(skill)
	if part != null and part.durability > 0:
		part.durability -= 1
		EventBus.part_durability_changed.emit(part)
		if part.durability == 0:
			print("  > [파츠 파괴] %s" % part.parts_name)


func _output_mult(skill: SkillData) -> float:
	var part: PartsData = _skill_to_part.get(skill)
	if part == null:
		return 1.0
	var mult: float = 1.0
	if part.is_worn():
		mult *= 0.7
	if part.parts_type == PartsData.PartsType.LEG and GameState.is_overloaded():
		mult *= 0.8
	return mult


func _mult_note(mult: float) -> String:
	if mult >= 1.0:
		return ""
	if mult < 0.6:   # 0.7 × 0.8 = 0.56
		return " [손상-30%·과부하-20%]"
	if mult < 0.75:  # 0.7
		return " [손상-30%]"
	return " [과부하-20%]"  # 0.8

# GameState에 HP가 있으므로 위임 — 인터페이스 통일 목적
func take_damage(amount: float) -> void:
	print("  > 플레이어 피격: %.0f 데미지 (HP: %.0f → %.0f)" % [
		amount,
		GameState.current_hp,
		maxf(GameState.current_hp - amount, 0.0)
	])
	GameState.take_damage(amount)
