extends Node

class_name EnemyEntity

@export var enemy_name: String = ""
@export var enemy_max_hp: float = 0.0
@export var enemy_max_shield: float = 0.0
@export var attack_multiplier: float = 1.0
@export var enemy_action_count: int = 2
@export var skills: Array[SkillData] = []

var current_hp: float = 0.0
var current_shield: float = 0.0
var next_actions: Array[SkillData] = []

func setup() -> void:
	current_hp = enemy_max_hp
	current_shield = enemy_max_shield
	decide_next_actions()
	print("[%s] 등장 | HP: %.0f | 쉴드: %.0f" % [enemy_name, current_hp, current_shield])

func setup_from_data(data: EnemyData) -> void:
	enemy_name = data.enemy_name
	enemy_max_hp = data.enemy_max_hp
	enemy_max_shield = data.enemy_max_shield
	attack_multiplier = data.attack_multiplier
	enemy_action_count = data.enemy_action_count
	skills = data.skills

func take_damage(damage: float) -> void:
	var absorbed: float = minf(current_shield, damage)
	current_shield -= absorbed
	current_hp -= (damage - absorbed)
	current_hp = maxf(current_hp, 0.0)
	print("  > [%s] 피격: %.0f 데미지 (HP: %.0f | 쉴드: %.0f)" % [
		enemy_name, damage, current_hp, current_shield
	])
	EventBus.hp_changed.emit(self, current_hp, enemy_max_hp)
	EventBus.shield_changed.emit(self, current_shield, enemy_max_shield)
	if is_defeated():
		print("  > [%s] 격파!" % enemy_name)

func is_defeated() -> bool:
	return current_hp <= 0.0

func execute_actions(target: Node) -> void:
	for action: SkillData in next_actions:
		print("[%s] '%s' 사용" % [enemy_name, action.skill_name])
		if action.skill_damage > 0.0:
			target.take_damage(action.skill_damage * attack_multiplier)
		if action.skill_defense > 0.0:
			_heal_shield(action.skill_defense)
			print("  > [%s] 쉴드 +%.0f" % [enemy_name, action.skill_defense])
		if action.skill_heal > 0.0:
			_heal_hp(action.skill_heal)
			print("  > [%s] HP +%.0f" % [enemy_name, action.skill_heal])
		EventBus.skill_used.emit(self, action)
	decide_next_actions()

func decide_next_actions() -> void:
	next_actions.clear()
	if skills.is_empty():
		return
	var ap_remaining: int = enemy_action_count
	var candidates: Array[SkillData] = skills.filter(
		func(s: SkillData) -> bool: return s.skill_action_cost <= ap_remaining
	)
	while not candidates.is_empty():
		var chosen: SkillData = candidates[randi() % candidates.size()]
		next_actions.append(chosen)
		ap_remaining -= chosen.skill_action_cost
		candidates = skills.filter(
			func(s: SkillData) -> bool: return s.skill_action_cost <= ap_remaining
		)
	print("[%s] 다음 행동 예고: %s" % [
		enemy_name,
		" → ".join(next_actions.map(func(s: SkillData) -> String: return s.skill_name))
	])

func _heal_hp(amount: float) -> void:
	current_hp = minf(current_hp + amount, enemy_max_hp)
	EventBus.hp_changed.emit(self, current_hp, enemy_max_hp)

func _heal_shield(amount: float) -> void:
	current_shield = minf(current_shield + amount, enemy_max_shield)
	EventBus.shield_changed.emit(self, current_shield, enemy_max_shield)
