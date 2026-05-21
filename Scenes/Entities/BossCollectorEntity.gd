extends EnemyEntity
class_name BossCollectorEntity

const COLLECTOR_ENEMY_ID: int = 301
const MAX_ARMS: int = 4

var active_arms: Array[CollectorArmEntity] = []

var skill_arm_theft_ref: SkillData = preload("res://Resources/Skills/skill_arm_theft.tres")
var arm_skill_pool: Array[SkillData] = [
	preload("res://Resources/Skills/skill_collector_crush.tres"),
	preload("res://Resources/Skills/skill_collector_sweep.tres"),
	preload("res://Resources/Skills/skill_collector_grab.tres"),
	preload("res://Resources/Skills/skill_collector_drill.tres"),
	preload("res://Resources/Skills/skill_collector_arm_shield.tres"),
]


func setup() -> void:
	current_hp = enemy_max_hp
	current_shield = enemy_max_shield
	_spawn_arms(MAX_ARMS)
	decide_next_actions()
	print("[%s] 등장 | HP: %.0f | 쉴드: %.0f | 팔: %d" % [
		enemy_name, current_hp, current_shield, active_arms.size()
	])


func setup_from_data(data: EnemyData) -> void:
	super.setup_from_data(data)


func decide_next_actions() -> void:
	_prune_defeated_arms()
	if active_arms.is_empty():
		print("[수집가] 팔 전멸 — 재수집 시작")
		EventBus.boss_arms_respawning.emit()
		_spawn_arms(MAX_ARMS)
		next_actions.clear()
		_publish_snipe_preview()
		return
	var theft_available: bool = active_arms.size() < MAX_ARMS
	_decide_with_theft_option(theft_available)


func execute_actions(target: Node) -> void:
	for action: SkillData in next_actions:
		if action == skill_arm_theft_ref:
			_apply_arm_theft(target)
		else:
			_execute_single_action(action, target)
	decide_next_actions()


func apply_core_shield_heal(amount: float) -> void:
	_heal_shield(amount)


func _decide_with_theft_option(include_theft: bool) -> void:
	next_actions.clear()
	if skills.is_empty() and not include_theft:
		_publish_snipe_preview()
		return
	var pool: Array[SkillData] = skills.duplicate()
	if include_theft and skill_arm_theft_ref != null:
		pool.append(skill_arm_theft_ref)
	var ap_remaining: int = enemy_action_count
	var candidates: Array[SkillData] = pool.filter(
		func(s: SkillData) -> bool: return s.skill_action_cost <= ap_remaining
	)
	while not candidates.is_empty():
		var chosen: SkillData = candidates[randi() % candidates.size()]
		next_actions.append(chosen)
		ap_remaining -= chosen.skill_action_cost
		candidates = pool.filter(
			func(s: SkillData) -> bool: return s.skill_action_cost <= ap_remaining
		)
	print("[%s] 다음 행동 예고: %s" % [
		enemy_name,
		" → ".join(next_actions.map(func(s: SkillData) -> String: return s.skill_name))
	])
	_publish_snipe_preview()


func _spawn_arms(count: int) -> void:
	if arm_skill_pool.is_empty():
		return
	for _i in count:
		var skill: SkillData = arm_skill_pool[randi() % arm_skill_pool.size()]
		var arm: CollectorArmEntity = CollectorArmEntity.create_default(_arm_name_for(skill), skill)
		arm.boss_core = self
		arm.attack_multiplier = attack_multiplier
		arm.setup()
		active_arms.append(arm)
		EventBus.boss_arm_spawned.emit(arm)


func _arm_name_for(skill: SkillData) -> String:
	match skill.skill_name:
		"유압 압착":
			return "압착 팔"
		"광역 스윕":
			return "스윕 팔"
		"연속 집기":
			return "집게 팔"
		"드릴 돌격":
			return "드릴 팔"
		"방어막":
			return "방어 팔"
		_:
			return "강탈 팔"


func _prune_defeated_arms() -> void:
	var living: Array[CollectorArmEntity] = []
	for arm: CollectorArmEntity in active_arms:
		if arm != null and not arm.is_defeated():
			living.append(arm)
	active_arms = living


func _apply_arm_theft(target: Node) -> void:
	if not target.has_method("steal_part_at_slot"):
		return
	var candidates: Array[int] = []
	for slot_idx in [SkillData.TargetSlot.ARM_L, SkillData.TargetSlot.ARM_R]:
		if target.get_part_at_slot(slot_idx) != null:
			candidates.append(slot_idx)
	if candidates.is_empty():
		print("[수집가] 팔 탈취 실패 — 플레이어 ARM 슬롯 비어 있음. 소타격 적용.")
		target.take_damage(10.0 * attack_multiplier)
		EventBus.skill_used.emit(self, skill_arm_theft_ref)
		return
	var chosen_slot: int = candidates[randi() % candidates.size()]
	var stolen: PartsData = target.steal_part_at_slot(chosen_slot)
	if stolen == null:
		return
	print("[수집가] '%s' 강탈 완료!" % stolen.parts_name)
	var new_arm: CollectorArmEntity = CollectorArmEntity.create_from_stolen(stolen)
	new_arm.boss_core = self
	new_arm.attack_multiplier = attack_multiplier
	new_arm.setup()
	active_arms.append(new_arm)
	EventBus.boss_arm_spawned.emit(new_arm)
	EventBus.skill_used.emit(self, skill_arm_theft_ref)
