extends Node

class_name TurnManager

enum TurnPhase { PLAYER_TURN, ENEMY_TURN, COMBAT_END }

signal phase_changed(phase: TurnPhase) # UI상태 전환용
signal player_action_required(available_skills: Array[SkillData], enemies: Array[EnemyEntity]) # CombatUI에 스킬 목록 전달
signal combat_ended(player_won: bool) # 씬 전환용

var current_phase: TurnPhase = TurnPhase.PLAYER_TURN
var player_mecha: MechaEntity = null
var enemies: Array[EnemyEntity] = []
var skills_used_this_turn: int = 0
var actions_left: int = 0

func start_combat(mecha: MechaEntity, enemy_list: Array[EnemyEntity]) -> void:
	player_mecha = mecha
	enemies = enemy_list
	player_mecha.setup()
	for enemy: EnemyEntity in enemies:
		enemy.setup()
	print("=== 전투 시작 | 적 수: %d ===" % enemies.size())
	EventBus.combat_started.emit()
	start_player_turn()

func start_player_turn() -> void:
	current_phase = TurnPhase.PLAYER_TURN
	actions_left = GameState.current_action_count
	player_mecha.tick_cooldowns()
	phase_changed.emit(current_phase)
	var usable: Array[SkillData] = player_mecha.get_available_skills()
	print("--- [플레이어 턴] HP: %.0f | 쉴드: %.0f | 행동 횟수: %d | 사용 가능 스킬: %s ---" % [
		GameState.current_hp,
		GameState.current_shield,
		actions_left,
		usable.map(func(s: SkillData) -> String: return s.skill_name)
	])
	player_action_required.emit(usable, enemies)

func on_skill_selected(skill: SkillData, target: Node) -> void:
	if current_phase != TurnPhase.PLAYER_TURN:
		return
	var target_name: String = target.name if target != null else "없음"
	print("[플레이어] '%s' 사용 → 타겟: %s" % [skill.skill_name, target_name])
	player_mecha.use_skill(skill, target)
	actions_left -= 1
	if _check_combat_end():
		return
	if actions_left <= 0:
		start_enemy_turn()
	else:
		player_action_required.emit(player_mecha.get_available_skills(), enemies)

func start_enemy_turn() -> void:
	current_phase = TurnPhase.ENEMY_TURN
	phase_changed.emit(current_phase)
	print("--- [적 턴] ---")
	for enemy: EnemyEntity in enemies:
		if not enemy.is_defeated():
			enemy.execute_action(player_mecha)
			if _check_combat_end():
				return
	start_player_turn()

func _check_combat_end() -> bool:
	if GameState.current_hp <= 0.0:
		_end_combat(false)
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
