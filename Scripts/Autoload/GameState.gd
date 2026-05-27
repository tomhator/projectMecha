extends Node

const CORE_BASE_PATH := "res://Resources/Cores/core_base.tres"
const DEFAULT_BASIC_ATTACK_PATH := "res://Resources/Skills/skill_core_single_shot.tres"
const DEFAULT_PART_ABILITY_PATH := "res://Resources/Skills/skill_core_emergency_swap.tres"
const META_PROGRESS_PATH := "user://core_research.cfg"
const BASE_INVENTORY_CAPACITY: int = 16
const FAILURE_RECOVERY_RATE: float = 0.5
const COMBAT_SKILL_PART_SLOT_ORDER: Array[CoreData.CoreSlot] = [
	CoreData.CoreSlot.ARM_L,
	CoreData.CoreSlot.ARM_R,
	CoreData.CoreSlot.BACK,
	CoreData.CoreSlot.LEG,
]
const PART_REPAIR_COST: Dictionary = {
	PartsData.PartsGrade.COMMON: 8,
	PartsData.PartsGrade.RARE: 20,
	PartsData.PartsGrade.EPIC: 45,
}
const PART_DISMANTLE_VALUE: Dictionary = {
	PartsData.PartsGrade.COMMON: 6,
	PartsData.PartsGrade.RARE: 16,
	PartsData.PartsGrade.EPIC: 36,
}

# --- 런 메타 정보 ---
var is_run_active: bool = false
var current_floor: int = 0
var current_core: CoreData = null

# --- 거점 성장 / 출격 로드아웃 ---
var meta_credits: int = 0
var meta_scrap: int = 0
var ability_node_levels: Dictionary = {}
var unlocked_part_ability_ids: Array[int] = [301]
var active_basic_attack: SkillData = null
var active_part_ability: SkillData = null
var active_tree_node_ids: Dictionary = {}
var active_core_visuals: Dictionary = {}
var core_select_initial_tab: String = "sortie"

# --- 거점 파츠 상태 ---
var storage_parts: Array[PartsData] = []
var sortie_inventory: Array[PartsData] = []
var sortie_equipped_parts: Dictionary = {
	CoreData.CoreSlot.ARM_L: null,
	CoreData.CoreSlot.ARM_R: null,
	CoreData.CoreSlot.BACK: null,
	CoreData.CoreSlot.LEG: null
}
var last_run_summary: Dictionary = {}
var total_runs: int = 0
var successful_runs: int = 0
var failed_runs: int = 0
var highest_floor: int = 0

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

# 런 인벤토리 상태
var inventory: Array[PartsData] = []

# 런 재화
var credits: int = 0
var run_scrap: int = 0

# 공격 배율
var attack_multiplier: float = 1.0


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
	equipped_parts = _empty_slot_dictionary()
	for slot: CoreData.CoreSlot in COMBAT_SKILL_PART_SLOT_ORDER:
		var sortie_part: PartsData = sortie_equipped_parts.get(slot)
		if sortie_part != null:
			equipped_parts[slot] = _duplicate_part_for_runtime(sortie_part)
	inventory = _duplicate_part_array_for_runtime(sortie_inventory)
	credits = 0
	run_scrap = 0
	_recalculate_runtime_payload_and_actions()
	EventBus.credits_changed.emit(credits)
	EventBus.scrap_changed.emit(run_scrap)
	EventBus.inventory_changed.emit(inventory)
	EventBus.hp_changed.emit(self, current_hp, current_core.core_hp)
	EventBus.shield_changed.emit(self, current_shield, current_core.core_shield)
	EventBus.payload_changed.emit(self, current_payload, get_max_payload())
	EventBus.action_count_changed.emit(self, current_action_count)


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


func end_run(success: bool = true) -> void:
	if not is_run_active:
		return
	var reached_floor: int = current_floor
	var earned_credits: int = maxi(credits, 0)
	var earned_scrap: int = maxi(run_scrap, 0)
	var recovered_credits: int = earned_credits if success else floori(float(earned_credits) * FAILURE_RECOVERY_RATE)
	var recovered_scrap: int = earned_scrap if success else floori(float(earned_scrap) * FAILURE_RECOVERY_RATE)
	var recovered_parts: Array[PartsData] = []
	var lost_parts: Array[PartsData] = []

	for part: PartsData in inventory:
		if part != null:
			recovered_parts.append(part)
	if success:
		for slot: CoreData.CoreSlot in COMBAT_SKILL_PART_SLOT_ORDER:
			var equipped: PartsData = equipped_parts.get(slot)
			if equipped != null:
				recovered_parts.append(equipped)
	else:
		for slot: CoreData.CoreSlot in COMBAT_SKILL_PART_SLOT_ORDER:
			var lost: PartsData = equipped_parts.get(slot)
			if lost != null:
				lost_parts.append(lost)

	for part: PartsData in recovered_parts:
		storage_parts.append(part)

	meta_credits += recovered_credits
	meta_scrap += recovered_scrap
	total_runs += 1
	if success:
		successful_runs += 1
	else:
		failed_runs += 1
	highest_floor = maxi(highest_floor, reached_floor)
	last_run_summary = {
		"success": success,
		"reached_floor": reached_floor,
		"run_credits": earned_credits,
		"recovered_credits": recovered_credits,
		"run_scrap": earned_scrap,
		"recovered_scrap": recovered_scrap,
		"recovered_part_count": recovered_parts.size(),
		"lost_part_count": lost_parts.size(),
		"recovered_part_names": _part_display_names(recovered_parts),
		"lost_part_names": _part_display_names(lost_parts),
	}

	is_run_active = false
	credits = 0
	run_scrap = 0
	inventory.clear()
	equipped_parts = _empty_slot_dictionary()
	sortie_inventory.clear()
	sortie_equipped_parts = _empty_slot_dictionary()
	_recalculate_runtime_payload_and_actions()
	_save_meta_progress()
	EventBus.credits_changed.emit(credits)
	EventBus.scrap_changed.emit(meta_scrap)
	EventBus.inventory_changed.emit(inventory)
	EventBus.storage_changed.emit(storage_parts)


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


func get_inventory_capacity() -> int:
	return BASE_INVENTORY_CAPACITY


func get_inventory_free_slots() -> int:
	return maxi(get_inventory_capacity() - inventory.size(), 0)


func is_inventory_full() -> bool:
	return get_inventory_free_slots() <= 0


func can_add_to_inventory(part: PartsData = null) -> bool:
	return part != null and not is_inventory_full()


func remove_from_inventory(part: PartsData) -> bool:
	if part == null or not inventory.has(part):
		return false
	inventory.erase(part)
	EventBus.inventory_changed.emit(inventory)
	return true


func add_to_inventory(part: PartsData) -> bool:
	if part == null:
		return false
	if is_inventory_full():
		EventBus.inventory_add_failed.emit(part)
		return false
	inventory.append(part)
	EventBus.inventory_changed.emit(inventory)
	return true


func get_combat_skill_order() -> Array[SkillData]:
	var ordered: Array[SkillData] = []
	if active_basic_attack != null:
		ordered.append(active_basic_attack)
	if active_part_ability != null:
		ordered.append(active_part_ability)
	for slot: CoreData.CoreSlot in COMBAT_SKILL_PART_SLOT_ORDER:
		var part: PartsData = equipped_parts.get(slot)
		if part == null:
			continue
		for skill: SkillData in part.parts_skills:
			if skill != null:
				ordered.append(skill)
	return ordered


func get_slot_for_combat_skill(skill: SkillData) -> int:
	if skill == null:
		return -1
	if skill == active_basic_attack or skill == active_part_ability:
		return -1
	for slot: CoreData.CoreSlot in COMBAT_SKILL_PART_SLOT_ORDER:
		var part: PartsData = equipped_parts.get(slot)
		if part != null and part.parts_skills.has(skill):
			return int(slot)
	return -1


func get_part_for_combat_skill(skill: SkillData) -> PartsData:
	var slot: int = get_slot_for_combat_skill(skill)
	if slot < 0:
		return null
	return equipped_parts.get(slot)


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


func add_scrap(amount: int) -> void:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return
	if is_run_active:
		run_scrap += safe_amount
		EventBus.scrap_changed.emit(run_scrap)
	else:
		meta_scrap += safe_amount
		EventBus.scrap_changed.emit(meta_scrap)
		_save_meta_progress()


func spend_scrap(amount: int) -> bool:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return true
	if meta_scrap < safe_amount:
		return false
	meta_scrap -= safe_amount
	EventBus.scrap_changed.emit(meta_scrap)
	_save_meta_progress()
	return true


func repair_storage_part(part: PartsData) -> bool:
	if part == null or not storage_parts.has(part) or not part.is_worn():
		return false
	var cost: int = repair_cost_for_part(part)
	if not spend_scrap(cost):
		return false
	part.durability = part.max_durability
	EventBus.part_durability_changed.emit(part)
	EventBus.storage_changed.emit(storage_parts)
	_save_meta_progress()
	return true


func dismantle_storage_part(part: PartsData) -> bool:
	if part == null or not storage_parts.has(part):
		return false
	storage_parts.erase(part)
	meta_scrap += dismantle_value_for_part(part)
	EventBus.scrap_changed.emit(meta_scrap)
	EventBus.storage_changed.emit(storage_parts)
	_save_meta_progress()
	return true


func repair_cost_for_part(part: PartsData) -> int:
	if part == null:
		return 0
	return int(PART_REPAIR_COST.get(part.grade(), 8))


func dismantle_value_for_part(part: PartsData) -> int:
	if part == null:
		return 0
	return int(PART_DISMANTLE_VALUE.get(part.grade(), 6))


func get_sortie_inventory_free_slots() -> int:
	return maxi(BASE_INVENTORY_CAPACITY - sortie_inventory.size(), 0)


func move_storage_to_sortie_inventory(part: PartsData) -> bool:
	if part == null or not storage_parts.has(part) or part.is_broken():
		return false
	if sortie_inventory.size() >= BASE_INVENTORY_CAPACITY:
		return false
	storage_parts.erase(part)
	sortie_inventory.append(part)
	_save_meta_progress()
	EventBus.storage_changed.emit(storage_parts)
	return true


func move_sortie_inventory_to_storage(part: PartsData) -> bool:
	if part == null or not sortie_inventory.has(part):
		return false
	sortie_inventory.erase(part)
	storage_parts.append(part)
	_save_meta_progress()
	EventBus.storage_changed.emit(storage_parts)
	return true


func equip_sortie_part(part: PartsData, slot: CoreData.CoreSlot) -> bool:
	if part == null or part.is_broken() or not _part_matches_slot(part, slot):
		return false
	var found: bool = false
	if storage_parts.has(part):
		storage_parts.erase(part)
		found = true
	elif sortie_inventory.has(part):
		sortie_inventory.erase(part)
		found = true
	if not found:
		return false
	var previous: PartsData = sortie_equipped_parts.get(slot)
	if previous != null:
		storage_parts.append(previous)
	sortie_equipped_parts[slot] = part
	_save_meta_progress()
	EventBus.storage_changed.emit(storage_parts)
	return true


func unequip_sortie_part(slot: CoreData.CoreSlot) -> bool:
	var part: PartsData = sortie_equipped_parts.get(slot)
	if part == null:
		return false
	sortie_equipped_parts[slot] = null
	storage_parts.append(part)
	_save_meta_progress()
	EventBus.storage_changed.emit(storage_parts)
	return true


func return_sortie_loadout_to_storage() -> void:
	for part: PartsData in sortie_inventory:
		if part != null:
			storage_parts.append(part)
	sortie_inventory.clear()
	for slot: CoreData.CoreSlot in COMBAT_SKILL_PART_SLOT_ORDER:
		var part: PartsData = sortie_equipped_parts.get(slot)
		if part != null:
			storage_parts.append(part)
	sortie_equipped_parts = _empty_slot_dictionary()
	_save_meta_progress()
	EventBus.storage_changed.emit(storage_parts)


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


func save_meta_progress() -> void:
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
	meta_scrap = maxi(int(config.get_value("base", "meta_scrap", meta_scrap)), 0)
	total_runs = maxi(int(config.get_value("records", "total_runs", total_runs)), 0)
	successful_runs = maxi(int(config.get_value("records", "successful_runs", successful_runs)), 0)
	failed_runs = maxi(int(config.get_value("records", "failed_runs", failed_runs)), 0)
	highest_floor = maxi(int(config.get_value("records", "highest_floor", highest_floor)), 0)
	var saved_summary: Variant = config.get_value("records", "last_run_summary", {})
	if typeof(saved_summary) == TYPE_DICTIONARY:
		last_run_summary = saved_summary
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
	storage_parts = _load_part_array(config.get_value("storage", "parts", []))
	sortie_inventory = _load_part_array(config.get_value("storage", "sortie_inventory", []))
	sortie_equipped_parts = _load_equipped_parts(config.get_value("storage", "sortie_equipped_parts", {}))


func _save_meta_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("research", "meta_credits", meta_credits)
	config.set_value("research", "node_levels", ability_node_levels)
	config.set_value("research", "part_abilities", unlocked_part_ability_ids)
	config.set_value("base", "meta_scrap", meta_scrap)
	config.set_value("storage", "parts", _save_part_array(storage_parts))
	config.set_value("storage", "sortie_inventory", _save_part_array(sortie_inventory))
	config.set_value("storage", "sortie_equipped_parts", _save_equipped_parts(sortie_equipped_parts))
	config.set_value("records", "last_run_summary", last_run_summary)
	config.set_value("records", "total_runs", total_runs)
	config.set_value("records", "successful_runs", successful_runs)
	config.set_value("records", "failed_runs", failed_runs)
	config.set_value("records", "highest_floor", highest_floor)
	var error: Error = config.save(META_PROGRESS_PATH)
	if error != OK:
		push_warning("Core research progress save failed: %s" % error)


func _save_part_array(parts: Array[PartsData]) -> Array:
	var out: Array = []
	for part: PartsData in parts:
		var data: Dictionary = _part_to_save_dict(part)
		if not data.is_empty():
			out.append(data)
	return out


func _load_part_array(saved: Variant) -> Array[PartsData]:
	var out: Array[PartsData] = []
	if typeof(saved) != TYPE_ARRAY:
		return out
	for data: Variant in saved:
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var part: PartsData = _part_from_save_dict(data)
		if part != null:
			out.append(part)
	return out


func _save_equipped_parts(parts: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for slot: CoreData.CoreSlot in COMBAT_SKILL_PART_SLOT_ORDER:
		var part: PartsData = parts.get(slot)
		if part != null:
			out[str(int(slot))] = _part_to_save_dict(part)
	return out


func _load_equipped_parts(saved: Variant) -> Dictionary:
	var out: Dictionary = _empty_slot_dictionary()
	if typeof(saved) != TYPE_DICTIONARY:
		return out
	for key: Variant in saved:
		var part_data: Variant = saved[key]
		if typeof(part_data) != TYPE_DICTIONARY:
			continue
		var slot: CoreData.CoreSlot = _slot_from_save_key(str(key))
		var part: PartsData = _part_from_save_dict(part_data)
		if part != null:
			out[slot] = part
	return out


func _part_to_save_dict(part: PartsData) -> Dictionary:
	if part == null:
		return {}
	var path: String = part.template_path
	if path.is_empty():
		path = part.resource_path
	if path.is_empty():
		return {}
	return {
		"template_path": path,
		"stat_multiplier": part.stat_multiplier,
		"rolled_affixes": part.rolled_affixes.duplicate(),
		"durability": part.durability,
		"max_durability": part.max_durability,
		"parts_grade": int(part.parts_grade),
		"parts_weight": part.parts_weight,
		"ap_contribution": part.ap_contribution,
		"max_load_bonus": part.max_load_bonus,
	}


func _part_from_save_dict(data: Dictionary) -> PartsData:
	var path: String = str(data.get("template_path", ""))
	if path.is_empty():
		return null
	var template: PartsData = load(path) as PartsData
	if template == null:
		push_warning("Stored part template missing: %s" % path)
		return null
	var part: PartsData = template.duplicate(true) as PartsData
	if part == null:
		return null
	part.template_path = path
	part.stat_multiplier = float(data.get("stat_multiplier", part.stat_multiplier))
	part.rolled_affixes.clear()
	var saved_affixes: Variant = data.get("rolled_affixes", [])
	if typeof(saved_affixes) == TYPE_ARRAY:
		for affix: Variant in saved_affixes:
			part.rolled_affixes.append(str(affix))
	part.max_durability = int(data.get("max_durability", part.max_durability))
	part.durability = int(data.get("durability", part.durability))
	part.parts_grade = int(data.get("parts_grade", part.grade()))
	part.parts_weight = float(data.get("parts_weight", part.parts_weight))
	part.ap_contribution = int(data.get("ap_contribution", part.ap_contribution))
	part.max_load_bonus = int(data.get("max_load_bonus", part.max_load_bonus))
	part._normalize_durability()
	return part


func _duplicate_part_for_runtime(part: PartsData) -> PartsData:
	if part == null:
		return null
	var copy: PartsData = part.duplicate(true) as PartsData
	if copy != null and copy.template_path.is_empty():
		copy.template_path = part.template_path
	return copy


func _duplicate_part_array_for_runtime(parts: Array[PartsData]) -> Array[PartsData]:
	var out: Array[PartsData] = []
	for part: PartsData in parts:
		var copy: PartsData = _duplicate_part_for_runtime(part)
		if copy != null:
			out.append(copy)
	return out


func _empty_slot_dictionary() -> Dictionary:
	return {
		CoreData.CoreSlot.ARM_L: null,
		CoreData.CoreSlot.ARM_R: null,
		CoreData.CoreSlot.BACK: null,
		CoreData.CoreSlot.LEG: null
	}


func _slot_from_save_key(key: String) -> CoreData.CoreSlot:
	match int(key):
		CoreData.CoreSlot.ARM_L: return CoreData.CoreSlot.ARM_L
		CoreData.CoreSlot.ARM_R: return CoreData.CoreSlot.ARM_R
		CoreData.CoreSlot.BACK: return CoreData.CoreSlot.BACK
		CoreData.CoreSlot.LEG: return CoreData.CoreSlot.LEG
	return CoreData.CoreSlot.ARM_L


func _part_matches_slot(part: PartsData, slot: CoreData.CoreSlot) -> bool:
	if part == null:
		return false
	match slot:
		CoreData.CoreSlot.ARM_L: return part.parts_type == PartsData.PartsType.ARM_L
		CoreData.CoreSlot.ARM_R: return part.parts_type == PartsData.PartsType.ARM_R
		CoreData.CoreSlot.BACK: return part.parts_type == PartsData.PartsType.BACK
		CoreData.CoreSlot.LEG: return part.parts_type == PartsData.PartsType.LEG
	return false


func _recalculate_runtime_payload_and_actions() -> void:
	current_payload = 0.0
	for slot: CoreData.CoreSlot in [CoreData.CoreSlot.ARM_L, CoreData.CoreSlot.ARM_R, CoreData.CoreSlot.BACK]:
		var part: PartsData = equipped_parts.get(slot)
		if part != null:
			current_payload += part.parts_weight
	current_action_count = get_max_action_count()


func _part_display_names(parts: Array[PartsData]) -> Array[String]:
	var names: Array[String] = []
	for part: PartsData in parts:
		if part != null:
			names.append(part.display_name())
	return names
