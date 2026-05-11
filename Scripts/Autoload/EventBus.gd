extends Node

signal combat_started
signal combat_ended(player_win: bool)
signal parts_equipped(parts: PartsData, slot: CoreData.CoreSlot)
signal parts_unequipped(parts: PartsData, slot: CoreData.CoreSlot)
signal credits_changed(new_amount: int)
signal floor_changed(new_floor: int)

signal hp_changed(entity: Node, new_hp: float, max_hp: float)
signal shield_changed(entity: Node, new_shield: float, max_shield: float)
signal payload_changed(entity: Node, new_payload: float, max_payload: float)

signal action_count_changed(entity: Node, new_action_count: int)
signal skill_used(entity: Node, skill: SkillData)
signal skill_cooldown_changed(entity: Node, skill: SkillData, new_cooldown: int)
signal skill_buff_applied(entity: Node, skill: SkillData, buff_type: SkillData.SkillBuff)
signal skill_debuff_applied(entity: Node, skill: SkillData, debuff_type: SkillData.SkillDebuff)
signal skill_target_changed(entity: Node, skill: SkillData, target: SkillData.SkillTarget)
signal skill_damage_changed(entity: Node, skill: SkillData, new_damage: float)
signal skill_defense_changed(entity: Node, skill: SkillData, new_defense: float)

signal inventory_changed(inventory: Array)
