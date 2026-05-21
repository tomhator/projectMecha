extends EnemyEntity
class_name CollectorArmEntity

var boss_core: EnemyEntity = null
var stolen_from_part: PartsData = null


static func create_default(arm_type: String, arm_skill: SkillData) -> CollectorArmEntity:
	var arm := CollectorArmEntity.new()
	arm.enemy_name = arm_type
	arm.enemy_max_hp = 45.0
	arm.enemy_max_shield = 0.0
	arm.attack_multiplier = 1.3
	arm.enemy_action_count = 2
	arm.skills = [arm_skill]
	return arm


static func create_from_stolen(part: PartsData) -> CollectorArmEntity:
	var arm := CollectorArmEntity.new()
	arm.stolen_from_part = part
	arm.enemy_name = "강탈된 " + part.parts_name
	arm.enemy_max_hp = 45.0
	arm.enemy_max_shield = 0.0
	arm.attack_multiplier = 1.3
	arm.enemy_action_count = 2
	if not part.parts_skills.is_empty():
		arm.skills = [part.parts_skills[0]]
	return arm


func _execute_single_action(action: SkillData, target: Node) -> void:
	if action.skill_name == "방어막" and boss_core != null and boss_core.has_method("apply_core_shield_heal"):
		print("[%s] '%s' 사용 → 코어 쉴드 강화" % [enemy_name, action.skill_name])
		boss_core.apply_core_shield_heal(action.skill_defense)
		EventBus.skill_used.emit(self, action)
		return
	super._execute_single_action(action, target)
