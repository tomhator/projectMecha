extends Node

@onready var turn_manager: TurnManager = $TurnManager
@onready var player_mecha: MechaEntity = $MechaEntity
@onready var combat_ui: CombatUI = $CombatUI

var enemies: Array[EnemyEntity] = []

func _ready() -> void:
	for child: Node in get_children():
		if child is EnemyEntity:
			enemies.append(child)

	combat_ui.skill_selected.connect(turn_manager.on_skill_selected)
	turn_manager.player_action_required.connect(combat_ui.on_player_action_required)
	turn_manager.combat_ended.connect(_on_combat_ended)

	player_mecha.add_to_group("player")
	turn_manager.start_combat(player_mecha, enemies)

func _on_combat_ended(player_won: bool) -> void:
	if player_won:
		print("Player won")
		DungeonManager.on_room_cleared()
	else:
		print("Player lost")
		DungeonManager.on_room_cleared()
