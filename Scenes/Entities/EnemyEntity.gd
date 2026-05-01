extends Node

class_name EnemyEntity

@export var enemy_name: String = ""
@export var enemy_max_hp: float = 0.0
@export var enemy_max_shield: float = 0.0
@export var attack_multiplier: float = 1.0
@export var skills: Array[SkillData] = []

var current_hp: float = 0.0
var current_shield: float = 0.0
var next_action: SkillData = null # 다음 턴에 사용할 스킬  (GDD §5.3)

func setup() -> void:
	current_hp = enemy_max_hp
	current_shield = enemy_max_shield
	decide_next_action()
	print("[%s] 등장 | HP: %.0f | 쉴드: %.0f" % [enemy_name, current_hp, current_shield])

# 자체 HP 보유 — 전투 씬 한정 객체
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

func execute_action(target: Node) -> void:
	if next_action == null:
		return
	print("[%s] '%s' 사용" % [enemy_name, next_action.skill_name])
	match next_action.skill_type:
		SkillData.SkillType.ATTACK:
			target.take_damage(next_action.skill_damage * attack_multiplier)
		SkillData.SkillType.DEFENSE:
			_heal_shield(next_action.skill_defense)
			print("  > [%s] 쉴드 +%.0f" % [enemy_name, next_action.skill_defense])
		SkillData.SkillType.HEAL:
			_heal_hp(next_action.skill_heal)
			print("  > [%s] HP +%.0f" % [enemy_name, next_action.skill_heal])
		SkillData.SkillType.PASSIVE:
			pass
	EventBus.skill_used.emit(self, next_action)
	decide_next_action()

# 다음 턴에 사용할 스킬 결정
func decide_next_action() -> void:
	if skills.is_empty():
		next_action = null
		return
	next_action = skills[randi() % skills.size()]
	print("[%s] 다음 행동 예고: '%s'" % [enemy_name, next_action.skill_name])

func _heal_hp(amount: float) -> void:
	current_hp = minf(current_hp + amount, enemy_max_hp)
	EventBus.hp_changed.emit(self, current_hp, enemy_max_hp)

func _heal_shield(amount: float) -> void:
	current_shield = minf(current_shield + amount, enemy_max_shield)
	EventBus.shield_changed.emit(self, current_shield, enemy_max_shield)
