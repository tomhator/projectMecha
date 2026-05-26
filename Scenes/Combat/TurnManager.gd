extends Node

class_name TurnManager

enum TurnPhase { PLAYER_TURN, ENEMY_TURN, COMBAT_END }

signal phase_changed(phase: TurnPhase)
signal player_action_required(available_skills: Array[SkillData], enemies: Array[EnemyEntity], actions_remaining: int)
signal combat_ended(player_won: bool)

var current_phase: TurnPhase = TurnPhase.PLAYER_TURN
var player_mecha: MechaEntity = null
var enemies: Array[EnemyEntity] = []
var actions_left: int = 0
var current_turn: int = 0
var _counted_defeated_enemies: Array[EnemyEntity] = []

func start_combat_untyped(mecha: Node, enemy_list: Array) -> void:
	if not (mecha is MechaEntity):
		push_error("TurnManager.start_combat_untyped: mecha must be MechaEntity")
		return
	var typed_enemies: Array[EnemyEntity] = []
	for enemy in enemy_list:
		if enemy is EnemyEntity:
			typed_enemies.append(enemy)
		else:
			push_error("TurnManager.start_combat_untyped: enemy must be EnemyEntity")
	start_combat(mecha as MechaEntity, typed_enemies)


func start_combat(mecha: MechaEntity, enemy_list: Array[EnemyEntity]) -> void:
	player_mecha = mecha
	enemies = enemy_list
	current_turn = 0
	_counted_defeated_enemies.clear()
	if not EventBus.boss_arm_spawned.is_connected(add_enemy):
		EventBus.boss_arm_spawned.connect(add_enemy)
	if not EventBus.enemy_spawn_requested.is_connected(add_enemy):
		EventBus.enemy_spawn_requested.connect(add_enemy)
	player_mecha.setup()
	for enemy: EnemyEntity in enemies:
		enemy.setup()
	print("=== 전투 시작 | 적 수: %d ===" % enemies.size())
	EventBus.combat_started.emit()
	start_player_turn()

func start_player_turn() -> void:
	for enemy: EnemyEntity in enemies:
		if not enemy.is_defeated():
			enemy.tick_debuffs()
	_prune_defeated_boss_arms()
	_count_new_defeats()
	if _check_combat_end():
		return
	current_phase = TurnPhase.PLAYER_TURN
	actions_left = GameState.current_action_count
	current_turn += 1
	player_mecha.on_player_turn_started()
	EventBus.combat_turn_changed.emit(current_turn)
	phase_changed.emit(current_phase)
	var usable: Array[SkillData] = _get_usable_skills()
	print("--- [턴 %d · 플레이어] HP: %.0f | 쉴드: %.0f | 행동력: %d | 사용 가능 스킬: %s ---" % [
		current_turn,
		GameState.current_hp,
		GameState.current_shield,
		actions_left,
		usable.map(func(s: SkillData) -> String: return s.skill_name)
	])
	if usable.is_empty():
		print("[TurnManager] 사용 가능한 스킬 없음 — 자동 턴 종료")
		start_enemy_turn()
		return
	player_action_required.emit(_get_display_skills(), enemies, actions_left)

func on_skill_selected(skill: SkillData, target: Node) -> void:
	if current_phase != TurnPhase.PLAYER_TURN:
		return
	if skill == null or not player_mecha.can_use_skill(skill) or skill.skill_action_cost > actions_left:
		print("[TurnManager] 사용 불가 스킬 무시: %s" % ("null" if skill == null else skill.skill_name))
		player_action_required.emit(_get_display_skills(), enemies, actions_left)
		return
	if skill.is_multi_target_enemy_skill():
		var targets: Array[EnemyEntity] = _get_targetable_enemies(SkillData.MULTI_TARGET_MAX_TARGETS)
		if targets.is_empty():
			print("[TurnManager] 타겟 가능한 적 없음 — 스킬 사용 취소: %s" % skill.skill_name)
			player_action_required.emit(_get_display_skills(), enemies, actions_left)
			return
		print("[플레이어] '%s' 사용 → 멀티타겟: %s" % [
			skill.skill_name,
			", ".join(targets.map(func(enemy: EnemyEntity) -> String: return enemy.enemy_name))
		])
		player_mecha.use_multi_target_skill(skill, targets)
		actions_left -= skill.skill_action_cost
		_prune_defeated_boss_arms()
		_count_new_defeats()
		if _check_combat_end():
			return
		var multi_usable: Array[SkillData] = _get_usable_skills()
		if actions_left <= 0 or multi_usable.is_empty():
			start_enemy_turn()
		else:
			player_action_required.emit(_get_display_skills(), enemies, actions_left)
		return
	if skill.skill_target == SkillData.SkillTarget.ENEMY:
		if target == null or not (target is EnemyEntity) or not (target as EnemyEntity).is_targetable():
			print("[TurnManager] 유효하지 않은 타겟 — 스킬 사용 취소: %s" % skill.skill_name)
			player_action_required.emit(_get_display_skills(), enemies, actions_left)
			return
	var target_name: String = "없음" if target == null else str(target.name)
	print("[플레이어] '%s' 사용 → 타겟: %s" % [skill.skill_name, target_name])
	player_mecha.use_skill(skill, target)
	actions_left -= skill.skill_action_cost
	_prune_defeated_boss_arms()
	_count_new_defeats()
	if _check_combat_end():
		return
	var usable: Array[SkillData] = _get_usable_skills()
	if actions_left <= 0 or usable.is_empty():
		start_enemy_turn()
	else:
		player_action_required.emit(_get_display_skills(), enemies, actions_left)


func on_end_turn_requested() -> void:
	if current_phase != TurnPhase.PLAYER_TURN:
		return
	if actions_left <= 0:
		return
	print("[플레이어] 턴 종료 버튼 선택")
	start_enemy_turn()

func start_enemy_turn() -> void:
	_notify_collectors_player_turn_ended()
	current_phase = TurnPhase.ENEMY_TURN
	phase_changed.emit(current_phase)
	print("--- [적 턴] ---")
	for enemy: EnemyEntity in enemies:
		if not enemy.is_defeated():
			enemy.execute_actions(player_mecha, enemies)
			_prune_defeated_boss_arms()
			_count_new_defeats()
			if _check_combat_end():
				return
	start_player_turn()

func _get_usable_skills() -> Array[SkillData]:
	return player_mecha.get_available_skills().filter(
		func(s: SkillData) -> bool: return s.skill_action_cost <= actions_left
	)

func _get_display_skills() -> Array[SkillData]:
	return player_mecha.get_display_skills()


func _get_targetable_enemies(max_targets: int) -> Array[EnemyEntity]:
	var out: Array[EnemyEntity] = []
	for enemy: EnemyEntity in enemies:
		if not is_instance_valid(enemy) or not enemy.is_targetable():
			continue
		out.append(enemy)
		if out.size() >= max_targets:
			break
	return out


func add_enemy(enemy: EnemyEntity) -> void:
	if enemy in enemies:
		return
	if enemy.get_parent() == null and get_parent() != null:
		get_parent().add_child(enemy)
	enemies.append(enemy)
	print("[TurnManager] 적 추가: %s (현재 적 수: %d)" % [enemy.enemy_name, enemies.size()])
	EventBus.enemy_added.emit(enemy)

func get_defeated_enemy_count() -> int:
	return _counted_defeated_enemies.size()


func _count_new_defeats() -> void:
	for enemy: EnemyEntity in enemies:
		if enemy is CollectorArmEntity or not enemy.counts_for_combat_rewards:
			continue
		if enemy.is_defeated() and not _counted_defeated_enemies.has(enemy):
			_counted_defeated_enemies.append(enemy)


func _prune_defeated_boss_arms() -> void:
	var removed: bool = false
	var removed_nodes: Array[EnemyEntity] = []
	for i: int in range(enemies.size() - 1, -1, -1):
		var enemy: EnemyEntity = enemies[i]
		if enemy is CollectorArmEntity and enemy.is_defeated():
			enemies.remove_at(i)
			removed = true
			removed_nodes.append(enemy)
			print("[TurnManager] 파괴된 수집가 팔 제거: %s (현재 적 수: %d)" % [enemy.enemy_name, enemies.size()])
	if removed:
		for enemy: EnemyEntity in enemies:
			if enemy is BossCollectorEntity:
				var collector := enemy as BossCollectorEntity
				for removed_node: EnemyEntity in removed_nodes:
					collector.on_arm_defeated(removed_node as CollectorArmEntity)
				collector.prune_defeated_arms()
		for removed_node: EnemyEntity in removed_nodes:
			if removed_node.is_inside_tree():
				removed_node.queue_free()
			else:
				removed_node.free()


func _notify_collectors_player_turn_ended() -> void:
	for enemy: EnemyEntity in enemies:
		if enemy is BossCollectorEntity and not enemy.is_defeated():
			(enemy as BossCollectorEntity).on_player_turn_ended()


func _check_combat_end() -> bool:
	if GameState.current_hp <= 0.0:
		_end_combat(false)
		return true
	for enemy: EnemyEntity in enemies:
		if enemy is BossCollectorEntity and enemy.is_defeated():
			_end_combat(true)
			return true
	var all_defeated: bool = enemies.all(
		func(e: EnemyEntity) -> bool: return e.is_defeated()
	)
	if all_defeated:
		_end_combat(true)
		return true
	return false

func _end_combat(player_won: bool) -> void:
	current_phase = TurnPhase.COMBAT_END
	phase_changed.emit(current_phase)
	if player_won:
		print("=== 전투 승리 ===")
	else:
		print("=== 전투 패배 | 런 종료 ===")
	EventBus.combat_ended.emit(player_won)
	combat_ended.emit(player_won)
