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

func use_skill(skill: SkillData, target: Node) -> void:
	var damage_modifier: float = 1.0
	if _skill_to_part.has(skill) and _skill_to_part[skill] != null:
		if (_skill_to_part[skill] as PartsData).is_damaged:
			damage_modifier = 0.7

	if skill.skill_damage > 0.0:
		if target != null and target.has_method("take_damage"):
			var actual_damage: float = skill.skill_damage * GameState.attack_multiplier * damage_modifier
			target.take_damage(actual_damage)
			var damage_note: String = " [손상-30%]" if damage_modifier < 1.0 else ""
			print("  > 공격: %s (%.0f 데미지%s)" % [skill.skill_name, actual_damage, damage_note])

	if skill.skill_defense > 0.0:
		GameState.heal_shield(skill.skill_defense)
		print("  > 방어: %s (쉴드 +%.0f)" % [skill.skill_name, skill.skill_defense])

	if skill.skill_heal > 0.0:
		GameState.heal_hp(skill.skill_heal)
		print("  > 회복: %s (HP +%.0f)" % [skill.skill_name, skill.skill_heal])

	EventBus.skill_used.emit(self, skill)

# GameState에 HP가 있으므로 위임 — 인터페이스 통일 목적
func take_damage(amount: float) -> void:
	print("  > 플레이어 피격: %.0f 데미지 (HP: %.0f → %.0f)" % [
		amount,
		GameState.current_hp,
		maxf(GameState.current_hp - amount, 0.0)
	])
	GameState.take_damage(amount)
