extends Resource

class_name AbilityTreeNode

@export var node_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var point_cost: int = 1
@export var required_node_id: String = ""

@export var stat_attack_multiplier_bonus: float = 0.0
@export var stat_hp_bonus: float = 0.0
@export var stat_shield_bonus: float = 0.0
@export var stat_action_count_bonus: int = 0

@export var unlocks_core_skill: SkillData = null
