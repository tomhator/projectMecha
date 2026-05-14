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
	damage = maxf(damage, 0.0)
	# 쉴드·HP가 이전 프레임/버그로 범위를 벗어나면 흡수 계산이 깨질 수 있음 → 먼저 클램프
	current_shield = clampf(current_shield, 0.0, enemy_max_shield)
	current_hp = clampf(current_hp, 0.0, enemy_max_hp)
	var absorbed: float = minf(current_shield, damage)
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
	print("  > [%s] 피격: %.0f 데미지%s → HP: %.0f | 쉴드: %.0f" % [
		enemy_name, damage, absorb_note, current_hp, current_shield
	])
	EventBus.hp_changed.emit(self, current_hp, enemy_max_hp)
	EventBus.shield_changed.emit(self, current_shield, enemy_max_shield)
	if is_defeated():
		print("  > [%s] 격파!" % enemy_name)


## `take_damage`와 동일한 흡수 규칙으로, 들어오는 피해가 쉴드·HP에 어떻게 나뉘는지 미리 계산 (UI 프리뷰용).
func preview_incoming_damage_split(damage: float) -> Vector2:
	damage = maxf(damage, 0.0)
	var sh: float = clampf(current_shield, 0.0, enemy_max_shield)
	var absorbed: float = minf(sh, damage)
	var to_hp: float = damage - absorbed
	return Vector2(absorbed, to_hp)


func is_defeated() -> bool:
	return current_hp <= 0.0

func execute_actions(target: Node) -> void:
	for action: SkillData in next_actions:
		print("[%s] '%s' 사용" % [enemy_name, action.skill_name])
		if action.skill_damage > 0.0:
			target.take_damage(action.skill_damage * attack_multiplier)
		if action.skill_defense > 0.0:
			_heal_shield(action.skill_defense)
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
