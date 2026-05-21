extends Node

@onready var turn_manager: TurnManager = $TurnManager
@onready var player_mecha: MechaEntity = $MechaEntity
@onready var combat_ui: CombatUI = $CombatUI

var enemies: Array[EnemyEntity] = []

func _ready() -> void:
	if not EventBus.boss_arm_spawned.is_connected(_on_boss_arm_spawned):
		EventBus.boss_arm_spawned.connect(_on_boss_arm_spawned)

	var enemy_data_list: Array[EnemyData] = DungeonManager.get_enemies_for_current_room()
	for data: EnemyData in enemy_data_list:
		var entity: EnemyEntity
		if data.enemy_id == BossCollectorEntity.COLLECTOR_ENEMY_ID:
			entity = BossCollectorEntity.new()
		else:
			entity = EnemyEntity.new()
		entity.name = data.enemy_name
		add_child(entity)
		entity.setup_from_data(data)
		enemies.append(entity)

	combat_ui.skill_selected.connect(turn_manager.on_skill_selected)
	combat_ui.end_turn_requested.connect(turn_manager.on_end_turn_requested)
	turn_manager.player_action_required.connect(combat_ui.on_player_action_required)
	turn_manager.combat_ended.connect(_on_combat_ended)

	player_mecha.add_to_group("player")
	turn_manager.start_combat(player_mecha, enemies)

func _on_boss_arm_spawned(arm: EnemyEntity) -> void:
	if arm.get_parent() == null:
		add_child(arm)
	arm.name = arm.enemy_name
	turn_manager.add_enemy(arm)


func _on_combat_ended(player_won: bool) -> void:
	if player_won:
		print("Player won")
		DungeonManager.on_room_cleared()
	else:
		print("Player lost")
		DungeonManager.on_run_failed()
