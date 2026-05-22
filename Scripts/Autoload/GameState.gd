extends Node

const CORE_BASE_PATH := "res://Resources/Cores/core_base.tres"
const DEFAULT_BASIC_ATTACK_PATH := "res://Resources/Skills/skill_core_single_shot.tres"
const DEFAULT_PART_ABILITY_PATH := "res://Resources/Skills/skill_core_emergency_swap.tres"
const META_PROGRESS_PATH := "user://core_research.cfg"

# --- 런 메타 정보 ---
var is_run_active: bool = false
var current_floor: int = 0
var current_core: CoreData = null

# --- 거점 성장 / 출격 로드아웃 ---
var meta_credits: int = 0
var ability_node_levels: Dictionary = {}
var unlocked_part_ability_ids: Array[int] = [301]
var active_basic_attack: SkillData = null
var active_part_ability: SkillData = null
var active_tree_node_ids: Dictionary = {}
var active_core_visuals: Dictionary = {}

# --- 메카 런타임 상태 ---
var current_hp: float = 0.0
var current_shield: float = 0.0
var current_payload: float = 0.0
var current_action_count: int = 0

# 부품 장착 상태
# key: CoreData.CoreSlot, value: PartsData (null이면 빈 슬롯)
var equipped_parts: Dictionary = {
	CoreData.CoreSlot.ARM_L: null,
	CoreData.CoreSlot.ARM_R: null,
	CoreData.CoreSlot.BACK: null,
	CoreData.CoreSlot.LEG: null
}

# 인벤토리 상태
var inventory: Array[PartsData] = []

# 재화
var credits: int = 0

# 공격 배율
var attack_multiplier: float = 1.0

# -----------------------------------


func _ready() -> void:
	_load_meta_progress()


func start_run() -> void:
	var template: CoreData = load(CORE_BASE_PATH) as CoreData
	current_core = template.duplicate() as CoreData
	is_run_active = true
	current_floor = 1
	active_core_visuals.clear()
	if active_basic_attack == null:
		active_basic_attack = load(DEFAULT_BASIC_ATTACK_PATH) as SkillData
	if active_part_ability == null:
		active_part_ability = load(DEFAULT_PART_ABILITY_PATH) as SkillData
	EventBus.floor_changed.emit(current_floor)
	current_hp = current_core.core_hp
	current_shield = current_core.core_shield
	current_payload = 0.0
	current_action_count = current_core.core_action_count
	attack_multiplier = current_core.core_attack_multiplier
	equipped_parts = {
		CoreData.CoreSlot.ARM_L: null,
		CoreData.CoreSlot.ARM_R: null,
		CoreData.CoreSlot.BACK: null,
		CoreData.CoreSlot.LEG: null
	}
	credits = 0
	inventory = []
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)


func apply_tree_node(node: AbilityTreeNode, level: int = 1) -> void:
	var safe_level: int = clampi(level, 1, 5)
	attack_multiplier += node.attack_bonus_at_level(safe_level)
	var hp_bonus: float = node.hp_bonus_at_level(safe_level)
	if hp_bonus != 0.0:
		current_core.core_hp += hp_bonus
		current_hp += hp_bonus
	var shield_bonus: float = node.shield_bonus_at_level(safe_level)
	if shield_bonus != 0.0:
		current_core.core_shield += shield_bonus
		current_shield += shield_bonus
	var action_bonus: int = node.action_bonus_at_level(safe_level)
	if action_bonus != 0:
		current_core.core_action_count += action_bonus
		current_action_count += action_bonus
	var payload_bonus: float = node.payload_bonus_at_level(safe_level)
	if payload_bonus != 0.0:
		current_core.core_max_payload += payload_bonus
	if not node.visual_slot.is_empty() and not node.visual_variant.is_empty():
		active_core_visuals[node.visual_slot] = node.visual_variant
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)
	EventBus.action_count_changed.emit(self, current_action_count)


func end_run() -> void:
	if is_run_active:
		meta_credits += maxi(credits, 0)
		_save_meta_progress()
	is_run_active = false


func unlock_tree_node(node: AbilityTreeNode) -> bool:
	if node == null or is_tree_node_unlocked(node.node_id):
		return false
	if node.tier > 1 and not _has_unlocked_tier(node.tier - 1):
		return false
	if meta_credits < node.research_cost:
		return false
	meta_credits -= node.research_cost
	ability_node_levels[node.node_id] = 1
	_save_meta_progress()
	return true


func level_tree_node(node: AbilityTreeNode) -> bool:
	if node == null or not is_tree_node_unlocked(node.node_id):
		return false
	var current_level: int = get_tree_node_level(node.node_id)
	if current_level >= 5:
		return false
	var cost: int = node.level_cost(current_level + 1)
	if meta_credits < cost:
		return false
	meta_credits -= cost
	ability_node_levels[node.node_id] = current_level + 1
	_save_meta_progress()
	return true


func is_tree_node_unlocked(node_id: String) -> bool:
	return get_tree_node_level(node_id) > 0


func get_tree_node_level(node_id: String) -> int:
	return int(ability_node_levels.get(node_id, 0))


func set_run_tree_node(node: AbilityTreeNode) -> void:
	if node == null or not is_tree_node_unlocked(node.node_id):
		return
	active_tree_node_ids[node.tier] = node.node_id


func clear_run_tree_node(tier: int) -> void:
	active_tree_node_ids.erase(tier)


func set_run_basic_attack(skill: SkillData) -> void:
	if skill != null and skill.core_skill_role == SkillData.CoreSkillRole.BASIC_ATTACK:
		active_basic_attack = skill


func set_run_part_ability(skill: SkillData) -> void:
	if skill != null and is_part_ability_unlocked(skill):
		active_part_ability = skill


func is_part_ability_unlocked(skill: SkillData) -> bool:
	return skill != null and unlocked_part_ability_ids.has(skill.skill_id)


func unlock_part_ability(skill_id: int) -> void:
	if skill_id > 0 and not unlocked_part_ability_ids.has(skill_id):
		unlocked_part_ability_ids.append(skill_id)
		_save_meta_progress()


func _has_unlocked_tier(tier: int) -> bool:
	for node_id: String in ability_node_levels:
		if node_id.contains("_t%d_" % tier):
			return true
	return false


func _load_meta_progress() -> void:
	var config := ConfigFile.new()
	if config.load(META_PROGRESS_PATH) != OK:
		return
	meta_credits = maxi(int(config.get_value("research", "meta_credits", meta_credits)), 0)
	var saved_levels: Variant = config.get_value("research", "node_levels", {})
	if typeof(saved_levels) == TYPE_DICTIONARY:
		ability_node_levels = saved_levels
	var saved_abilities: Variant = config.get_value("research", "part_abilities", [301])
	if typeof(saved_abilities) == TYPE_ARRAY:
		unlocked_part_ability_ids.clear()
		for skill_id: Variant in saved_abilities:
			var typed_id: int = int(skill_id)
			if typed_id > 0 and not unlocked_part_ability_ids.has(typed_id):
				unlocked_part_ability_ids.append(typed_id)
	if not unlocked_part_ability_ids.has(301):
		unlocked_part_ability_ids.append(301)


func _save_meta_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("research", "meta_credits", meta_credits)
	config.set_value("research", "node_levels", ability_node_levels)
	config.set_value("research", "part_abilities", unlocked_part_ability_ids)
	var error: Error = config.save(META_PROGRESS_PATH)
	if error != OK:
		push_warning("Core research progress save failed: %s" % error)

func advance_floor() -> void:
	current_floor += 1
	EventBus.floor_changed.emit(current_floor)

# 부품 장착/해제
func equip_part(part: PartsData, slot: CoreData.CoreSlot) -> void:
	var prev: PartsData = equipped_parts[slot]
	if slot != CoreData.CoreSlot.LEG:
		if prev != null:
			current_payload -= prev.parts_weight
		current_payload += part.parts_weight
	equipped_parts[slot] = part
	current_action_count = get_max_action_count()
	EventBus.parts_equipped.emit(part, slot)
	EventBus.payload_changed.emit(self, current_payload, get_max_payload())
	EventBus.action_count_changed.emit(self, current_action_count)

func unequip_part(slot: CoreData.CoreSlot) -> void:
	var prev: PartsData = equipped_parts[slot]
	if slot != CoreData.CoreSlot.LEG and prev != null:
		current_payload -= prev.parts_weight
	equipped_parts[slot] = null
	current_action_count = get_max_action_count()
	EventBus.parts_unequipped.emit(prev, slot)
	EventBus.payload_changed.emit(self, current_payload, get_max_payload())
	EventBus.action_count_changed.emit(self, current_action_count)

func get_max_payload() -> float:
	if current_core == null:
		return 0.0
	var leg: PartsData = equipped_parts.get(CoreData.CoreSlot.LEG)
	var leg_bonus: float = float(leg.max_load_bonus) if leg != null else 0.0
	return current_core.core_max_payload + leg_bonus

func get_max_action_count() -> int:
	if current_core == null:
		return 0
	var total: int = current_core.core_action_count
	for slot: CoreData.CoreSlot in [CoreData.CoreSlot.ARM_L, CoreData.CoreSlot.ARM_R, CoreData.CoreSlot.BACK]:
		var p: PartsData = equipped_parts.get(slot)
		if p != null:
			total += p.ap_contribution
	return total

func is_overloaded() -> bool:
	return current_payload > get_max_payload()

# 재화 추가/차감
func add_credits(amount: int) -> void:
	credits += amount
	EventBus.credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	EventBus.credits_changed.emit(credits)
	return true

# HP/Shield
func take_damage(amount: float, penetration: float = 0.0) -> void:
	var pen := clampf(penetration, 0.0, 1.0)
	var absorbed: float = minf(current_shield, amount * (1.0 - pen))
	current_shield -= absorbed
	current_hp -= amount - absorbed
	current_hp = maxf(current_hp, 0.0)
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)

func heal_hp(amount: float) -> void:
	current_hp = minf(current_hp + amount, current_core.core_hp)
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)

func heal_shield(amount: float) -> void:
	current_shield = minf(current_shield + amount, current_core.core_shield)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)

# 인벤토리 관리
func add_to_inventory(part: PartsData) -> void:
	inventory.append(part)
	EventBus.inventory_changed.emit(inventory)
