extends Node

class_name MechaEntity

var available_skills: Array[SkillData] = []
var skill_cooldowns: Dictionary = {}

func setup() -> void: 
	available_skills.clear()
	available_skills.append_array(GameState.current_core.core_skills)
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if part != null:
			available_skills.append_array(part.parts_skills)
	for skill in available_skills:
		skill_cooldowns[skill] = 0

func get_available_skills() -> Array[SkillData]:
	return available_skills.filter(func(s: SkillData) -> bool:
		return skill_cooldowns[s] == 0 and s.skill_type != SkillData.SkillType.PASSIVE
	)

func use_skill(skill: SkillData, target: Node) -> void:
	match skill.skill_type:
		SkillData.SkillType.ATTACK:
			if target.has_method("take_damage"):
				target.take_damage(skill.skill_damage)
				print("  > 공격: %s (%.0f 데미지)" % [skill.skill_name, skill.skill_damage])
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
