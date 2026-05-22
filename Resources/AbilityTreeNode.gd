extends Resource

class_name AbilityTreeNode

enum Track { ATTACK, DEFENSE, UTILITY }

@export var node_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export_range(1, 5, 1) var tier: int = 1
@export var track: Track = Track.ATTACK
@export var research_cost: int = 40
@export var level_cost_step: int = 20
@export var level_five_bonus_text: String = ""
@export var visual_slot: String = ""
@export var visual_variant: String = ""

@export var stat_attack_multiplier_bonus: float = 0.0
@export var stat_hp_bonus: float = 0.0
@export var stat_shield_bonus: float = 0.0
@export var stat_action_count_bonus: int = 0
@export var stat_payload_bonus: float = 0.0

func level_cost(next_level: int) -> int:
	return research_cost + maxi(next_level - 1, 0) * level_cost_step


func attack_bonus_at_level(level: int) -> float:
	return stat_attack_multiplier_bonus * clampi(level, 1, 5)


func hp_bonus_at_level(level: int) -> float:
	return stat_hp_bonus * clampi(level, 1, 5)


func shield_bonus_at_level(level: int) -> float:
	return stat_shield_bonus * clampi(level, 1, 5)


func action_bonus_at_level(level: int) -> int:
	return stat_action_count_bonus * clampi(level, 1, 5)


func payload_bonus_at_level(level: int) -> float:
	return stat_payload_bonus * clampi(level, 1, 5)
