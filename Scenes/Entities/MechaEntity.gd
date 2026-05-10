extends Node

class_name MechaEntity

var available_skills: Array[SkillData] = []
var skill_cooldowns: Dictionary = {}
var _skill_to_part: Dictionary = {}  # SkillData → PartsData (코어 스킬은 null)

func setup() -> void:
	available_skills.clear()
	skill_cooldowns.clear()
	_skill_to_part.clear()
	available_skills.append_array(GameState.current_core.core_skills)
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if part != null:
			for skill: SkillData in part.parts_skills:
				available_skills.append(skill)
				_skill_to_part[skill] = part
	for skill in available_skills:
		skill_cooldowns[skill] = 0

func get_available_skills() -> Array[SkillData]:
	return available_skills.filter(func(s: SkillData) -> bool:
		return skill_cooldowns[s] == 0 and s.skill_type != SkillData.SkillType.PASSIVE
	)

func use_skill(skill: SkillData, target: Node) -> void:
	var damage_modifier: float = 1.0
	if _skill_to_part.has(skill) and _skill_to_part[skill] != null:
		if (_skill_to_part[skill] as PartsData).is_damaged:
			damage_modifier = 0.7
	match skill.skill_type:
		SkillData.SkillType.ATTACK:
			if target.has_method("take_damage"):
				var actual_damage: float = skill.skill_damage * GameState.attack_multiplier * damage_modifier
				target.take_damage(actual_damage)
				var damage_note: String = " [손상-30%]" if damage_modifier < 1.0 else ""
				print("  > 공격: %s (%.0f 데미지%s)" % [skill.skill_name, actual_damage, damage_note])
		SkillData.SkillType.DEFENSE:
			GameState.heal_shield(skill.skill_defense)
			print("  > 방어: %s (쉴드 +%.0f)" % [skill.skill_name, skill.skill_defense])
		SkillData.SkillType.HEAL:
			GameState.heal_hp(skill.skill_heal)
			print("  > 회복: %s (HP +%.0f)" % [skill.skill_name, skill.skill_heal])
		SkillData.SkillType.PASSIVE:
			pass

	if skill.skill_cooldown > 0:
		print("  > '%s' 쿨다운: %d턴" % [skill.skill_name, skill.skill_cooldown])
	skill_cooldowns[skill] = skill.skill_cooldown
	EventBus.skill_used.emit(self, skill)

func tick_cooldowns() -> void:
	for skill: SkillData in skill_cooldowns:
		if skill_cooldowns[skill] > 0:
			skill_cooldowns[skill] -= 1
			EventBus.skill_cooldown_changed.emit(self, skill, skill_cooldowns[skill])

# GameState에 HP가 있으므로 위임 — 인터페이스 통일 목적
func take_damage(amount: float) -> void:
	print("  > 플레이어 피격: %.0f 데미지 (HP: %.0f → %.0f)" % [
		amount,
		GameState.current_hp,
		maxf(GameState.current_hp - amount, 0.0)
	])
	GameState.take_damage(amount)
