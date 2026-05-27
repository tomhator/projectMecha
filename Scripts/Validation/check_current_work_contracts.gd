extends SceneTree

const ARM_L_PATH: String = "res://Resources/Parts/arm_l/arm_l_gr21.tres"
const ARM_L_ALT_PATH: String = "res://Resources/Parts/arm_l/arm_l_ml7.tres"
const ARM_R_PATH: String = "res://Resources/Parts/arm_r/arm_r_gr21.tres"
const BACK_PATH: String = "res://Resources/Parts/back/back_fr1.tres"
const LEG_PATH: String = "res://Resources/Parts/leg/leg_strider1.tres"
const REWARD_SCENE_SCRIPT: String = "res://Scenes/Dungeon/RewardScene.gd"
const MAX_DURABILITY_BY_AFFIX_COUNT: Array[int] = [3, 3, 5, 5, 7, 7]

var _failed: bool = false
var _gs: Node = null
var _snapshot: Dictionary = {}


func _initialize() -> void:
	seed(20260527)
	_gs = root.get_node_or_null("GameState")
	if _gs == null:
		_fail("Missing GameState autoload")
		quit(1)
		return
	_snapshot = _take_snapshot()
	_reset_state()
	_check_base_sortie_runtime_contracts()
	_check_reward_scene_contracts()
	_check_parts_factory_contracts()
	_check_ability_tree_contracts()
	_restore_snapshot(_snapshot)
	if _failed:
		print("Current work contracts: FAIL")
		quit(1)
	else:
		print("Current work contracts: PASS")
		quit(0)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _take_snapshot() -> Dictionary:
	return {
		"meta_credits": _gs.get("meta_credits"),
		"meta_scrap": _gs.get("meta_scrap"),
		"ability_node_levels": (_gs.get("ability_node_levels") as Dictionary).duplicate(true),
		"unlocked_part_ability_ids": (_gs.get("unlocked_part_ability_ids") as Array).duplicate(),
		"active_basic_attack": _gs.get("active_basic_attack"),
		"active_part_ability": _gs.get("active_part_ability"),
		"active_tree_node_ids": (_gs.get("active_tree_node_ids") as Dictionary).duplicate(true),
		"active_core_visuals": (_gs.get("active_core_visuals") as Dictionary).duplicate(true),
		"core_select_initial_tab": _gs.get("core_select_initial_tab"),
		"storage_parts": (_gs.get("storage_parts") as Array).duplicate(),
		"sortie_inventory": (_gs.get("sortie_inventory") as Array).duplicate(),
		"sortie_equipped_parts": (_gs.get("sortie_equipped_parts") as Dictionary).duplicate(),
		"last_run_summary": (_gs.get("last_run_summary") as Dictionary).duplicate(true),
		"total_runs": _gs.get("total_runs"),
		"successful_runs": _gs.get("successful_runs"),
		"failed_runs": _gs.get("failed_runs"),
		"highest_floor": _gs.get("highest_floor"),
		"is_run_active": _gs.get("is_run_active"),
		"current_floor": _gs.get("current_floor"),
		"current_core": _gs.get("current_core"),
		"current_hp": _gs.get("current_hp"),
		"current_shield": _gs.get("current_shield"),
		"current_payload": _gs.get("current_payload"),
		"current_action_count": _gs.get("current_action_count"),
		"equipped_parts": (_gs.get("equipped_parts") as Dictionary).duplicate(),
		"inventory": (_gs.get("inventory") as Array).duplicate(),
		"credits": _gs.get("credits"),
		"run_scrap": _gs.get("run_scrap"),
		"attack_multiplier": _gs.get("attack_multiplier"),
	}


func _restore_snapshot(snapshot: Dictionary) -> void:
	_gs.set("meta_credits", int(snapshot["meta_credits"]))
	_gs.set("meta_scrap", int(snapshot["meta_scrap"]))
	_gs.set("ability_node_levels", snapshot["ability_node_levels"])
	_gs.set("unlocked_part_ability_ids", _typed_int_array(snapshot["unlocked_part_ability_ids"]))
	_gs.set("active_basic_attack", snapshot["active_basic_attack"])
	_gs.set("active_part_ability", snapshot["active_part_ability"])
	_gs.set("active_tree_node_ids", snapshot["active_tree_node_ids"])
	_gs.set("active_core_visuals", snapshot["active_core_visuals"])
	_gs.set("core_select_initial_tab", str(snapshot["core_select_initial_tab"]))
	_gs.set("storage_parts", _typed_part_array(snapshot["storage_parts"]))
	_gs.set("sortie_inventory", _typed_part_array(snapshot["sortie_inventory"]))
	_gs.set("sortie_equipped_parts", snapshot["sortie_equipped_parts"])
	_gs.set("last_run_summary", snapshot["last_run_summary"])
	_gs.set("total_runs", int(snapshot["total_runs"]))
	_gs.set("successful_runs", int(snapshot["successful_runs"]))
	_gs.set("failed_runs", int(snapshot["failed_runs"]))
	_gs.set("highest_floor", int(snapshot["highest_floor"]))
	_gs.set("is_run_active", bool(snapshot["is_run_active"]))
	_gs.set("current_floor", int(snapshot["current_floor"]))
	_gs.set("current_core", snapshot["current_core"])
	_gs.set("current_hp", float(snapshot["current_hp"]))
	_gs.set("current_shield", float(snapshot["current_shield"]))
	_gs.set("current_payload", float(snapshot["current_payload"]))
	_gs.set("current_action_count", int(snapshot["current_action_count"]))
	_gs.set("equipped_parts", snapshot["equipped_parts"])
	_gs.set("inventory", _typed_part_array(snapshot["inventory"]))
	_gs.set("credits", int(snapshot["credits"]))
	_gs.set("run_scrap", int(snapshot["run_scrap"]))
	_gs.set("attack_multiplier", float(snapshot["attack_multiplier"]))
	_gs.call("save_meta_progress")


func _reset_state() -> void:
	_gs.set("is_run_active", false)
	_gs.set("current_floor", 0)
	_gs.set("meta_credits", 0)
	_gs.set("meta_scrap", 0)
	_gs.set("ability_node_levels", {})
	_gs.set("unlocked_part_ability_ids", _typed_int_array([301]))
	_gs.set("active_basic_attack", null)
	_gs.set("active_part_ability", null)
	_gs.set("active_tree_node_ids", {})
	_gs.set("active_core_visuals", {})
	_gs.set("storage_parts", _typed_part_array([]))
	_gs.set("sortie_inventory", _typed_part_array([]))
	_gs.set("sortie_equipped_parts", _empty_slots())
	_gs.set("last_run_summary", {})
	_gs.set("total_runs", 0)
	_gs.set("successful_runs", 0)
	_gs.set("failed_runs", 0)
	_gs.set("highest_floor", 0)
	_gs.set("current_core", null)
	_gs.set("current_hp", 0.0)
	_gs.set("current_shield", 0.0)
	_gs.set("current_payload", 0.0)
	_gs.set("current_action_count", 0)
	_gs.set("equipped_parts", _empty_slots())
	_gs.set("inventory", _typed_part_array([]))
	_gs.set("credits", 0)
	_gs.set("run_scrap", 0)
	_gs.set("attack_multiplier", 1.0)


func _check_base_sortie_runtime_contracts() -> void:
	_reset_state()
	var arm: PartsData = _make_part(ARM_L_PATH)
	var arm_alt: PartsData = _make_part(ARM_L_ALT_PATH)
	var arm_r: PartsData = _make_part(ARM_R_PATH)
	var back: PartsData = _make_part(BACK_PATH)
	var leg: PartsData = _make_part(LEG_PATH)
	var broken_back: PartsData = _make_part(BACK_PATH, [], 0)
	if arm == null or arm_alt == null or arm_r == null or back == null or leg == null or broken_back == null:
		return

	_gs.get("storage_parts").append(arm)
	_gs.get("storage_parts").append(arm_alt)
	_gs.get("storage_parts").append(arm_r)
	_gs.get("storage_parts").append(back)
	_gs.get("storage_parts").append(leg)
	_gs.get("storage_parts").append(broken_back)

	_assert_true(not bool(_gs.call("equip_sortie_part", arm_r, CoreData.CoreSlot.ARM_L)), "Sortie equip accepted a mismatched slot")
	_assert_true(bool(_gs.call("equip_sortie_part", arm, CoreData.CoreSlot.ARM_L)), "Sortie equip rejected valid ARM_L")
	_assert_true(bool(_gs.call("equip_sortie_part", arm_alt, CoreData.CoreSlot.ARM_L)), "Sortie equip rejected replacement ARM_L")
	_assert_true(_gs.get("sortie_equipped_parts")[CoreData.CoreSlot.ARM_L] == arm_alt, "Sortie replacement did not occupy ARM_L")
	_assert_true((_gs.get("storage_parts") as Array).has(arm), "Sortie replacement did not return previous part to storage")
	_assert_true(bool(_gs.call("equip_sortie_part", arm_r, CoreData.CoreSlot.ARM_R)), "Sortie equip rejected valid ARM_R")
	_assert_true(bool(_gs.call("equip_sortie_part", leg, CoreData.CoreSlot.LEG)), "Sortie equip rejected valid LEG")
	_assert_true(bool(_gs.call("move_storage_to_sortie_inventory", back)), "Sortie inventory rejected valid part")
	_assert_true(not bool(_gs.call("move_storage_to_sortie_inventory", broken_back)), "Sortie inventory accepted a broken part")
	_assert_true(not bool(_gs.call("equip_sortie_part", broken_back, CoreData.CoreSlot.BACK)), "Sortie equip accepted a broken part")

	_gs.call("start_run")
	var runtime_arm: PartsData = _gs.get("equipped_parts")[CoreData.CoreSlot.ARM_L]
	var runtime_arm_r: PartsData = _gs.get("equipped_parts")[CoreData.CoreSlot.ARM_R]
	var runtime_leg: PartsData = _gs.get("equipped_parts")[CoreData.CoreSlot.LEG]
	var runtime_inventory: Array = _gs.get("inventory")
	_assert_true(runtime_arm != null and runtime_arm != arm_alt, "Runtime equipped part was not duplicated from sortie loadout")
	_assert_true(runtime_inventory.size() == 1 and runtime_inventory[0] != back, "Runtime inventory was not duplicated from sortie inventory")
	_assert_true(is_equal_approx(float(_gs.get("current_payload")), runtime_arm.parts_weight + runtime_arm_r.parts_weight), "Runtime payload must count ARM/BACK, not LEG")
	_assert_true(is_equal_approx(float(_gs.call("get_max_payload")), _gs.get("current_core").core_max_payload + runtime_leg.max_load_bonus), "Runtime max payload did not include LEG bonus")
	runtime_arm.durability = 0
	_assert_true(arm_alt.durability == arm_alt.max_durability, "Runtime durability mutation leaked into staged sortie part")
	_gs.set("credits", 12)
	_gs.set("run_scrap", 8)
	_gs.set("current_floor", 4)
	_gs.call("end_run", false)
	_assert_true(int(_gs.get("meta_credits")) == 6, "Failure settlement did not recover 50% credits")
	_assert_true(int(_gs.get("meta_scrap")) == 4, "Failure settlement did not recover 50% scrap")
	_assert_true(int((_gs.get("last_run_summary") as Dictionary).get("recovered_part_count", -1)) == 1, "Failure settlement did not recover only runtime inventory parts")
	_assert_true(int((_gs.get("last_run_summary") as Dictionary).get("lost_part_count", -1)) == 3, "Failure settlement did not lose runtime equipped parts")
	print("Current OK: base sortie runtime duplication and failure settlement")


func _check_reward_scene_contracts() -> void:
	var script: GDScript = load(REWARD_SCENE_SCRIPT) as GDScript
	if script == null:
		_fail("RewardScene script failed to load")
		return
	var scene: Node = script.new() as Node
	_check_reward_room(scene, RoomData.RoomType.BATTLE_NORMAL, PartsData.PartsGrade.COMMON, 15, 25, 3, 6)
	_check_reward_room(scene, RoomData.RoomType.BATTLE_ELITE, PartsData.PartsGrade.RARE, 45, 65, 8, 14)
	_check_reward_room(scene, RoomData.RoomType.BOSS, PartsData.PartsGrade.EPIC, 85, 105, 20, 30)
	for _i: int in range(50):
		var chest_room: RoomData = _make_room(RoomData.RoomType.CHEST)
		var grade: int = int(scene.call("_determine_grade", chest_room))
		_assert_true(grade == PartsData.PartsGrade.RARE or grade == PartsData.PartsGrade.EPIC, "Chest reward grade escaped RARE/EPIC")
		_assert_true(int(scene.call("_determine_credits", chest_room)) == 0, "Chest unexpectedly grants credits")
		_assert_true(int(scene.call("_determine_scrap", chest_room)) == 0, "Chest unexpectedly grants scrap")
	var reward_manager: Node = root.get_node_or_null("RewardManager")
	if reward_manager == null:
		_fail("Missing RewardManager autoload")
		scene.free()
		return
	var drops: Array = reward_manager.call("generate_combat_drops", PartsData.PartsGrade.COMMON, 0)
	_assert_true(drops.is_empty(), "Combat reward generated drops for zero defeated enemies")
	scene.free()
	print("Current OK: reward grade, credit, scrap, and zero-drop contracts")


func _check_reward_room(scene: Node, room_type: RoomData.RoomType, expected_grade: PartsData.PartsGrade, credit_min: int, credit_max: int, scrap_min: int, scrap_max: int) -> void:
	var room: RoomData = _make_room(room_type)
	_assert_true(int(scene.call("_determine_grade", room)) == expected_grade, "Reward grade mismatch for room type %d" % room_type)
	for _i: int in range(80):
		var credits: int = int(scene.call("_determine_credits", room))
		var scrap: int = int(scene.call("_determine_scrap", room))
		_assert_true(credits >= credit_min and credits <= credit_max, "Reward credits out of range for room type %d: %d" % [room_type, credits])
		_assert_true(scrap >= scrap_min and scrap <= scrap_max, "Reward scrap out of range for room type %d: %d" % [room_type, scrap])


func _check_parts_factory_contracts() -> void:
	var parts_factory: Node = root.get_node_or_null("PartsFactory")
	if parts_factory == null:
		_fail("Missing PartsFactory autoload")
		return
	var template: PartsData = load(BACK_PATH) as PartsData
	if template == null:
		_fail("PartsFactory template missing")
		return
	_check_generated_grade(parts_factory, template, PartsData.PartsGrade.COMMON, 0, 1)
	_check_generated_grade(parts_factory, template, PartsData.PartsGrade.RARE, 2, 3)
	_check_generated_grade(parts_factory, template, PartsData.PartsGrade.EPIC, 4, 5)

	var leg_template: PartsData = PartsData.new()
	leg_template.parts_type = PartsData.PartsType.LEG
	leg_template.affix_pool = ["evolution_lord", "greedy", "productive"]
	var leg_pool: PackedStringArray = parts_factory.call("_filtered_affix_pool", leg_template)
	_assert_true(not _packed_string_array_has(leg_pool, "evolution_lord"), "evolution_lord remained in LEG affix pool")

	var back_template: PartsData = PartsData.new()
	back_template.parts_type = PartsData.PartsType.BACK
	back_template.affix_pool = ["evolution_lord", "greedy"]
	var back_pool: PackedStringArray = parts_factory.call("_filtered_affix_pool", back_template)
	_assert_true(_packed_string_array_has(back_pool, "evolution_lord"), "evolution_lord was removed from BACK affix pool")

	var affix_part: PartsData = PartsData.new()
	affix_part.parts_weight = 10.0
	affix_part.max_durability = 5
	affix_part.rolled_affixes = ["greedy", "productive", "meticulous"]
	parts_factory.call("_apply_on_equip_affixes", affix_part)
	_assert_true(is_equal_approx(affix_part.parts_weight, 12.0), "greedy/productive weight modifiers did not stack")
	_assert_true(affix_part.max_durability == 6, "meticulous did not round durability bonus")
	print("Current OK: parts factory grade, affix, and slot-filter contracts")


func _check_generated_grade(parts_factory: Node, template: PartsData, grade: PartsData.PartsGrade, min_affixes: int, max_affixes: int) -> void:
	for _i: int in range(60):
		var generated: PartsData = parts_factory.call("generate", template, grade) as PartsData
		if generated == null:
			_fail("PartsFactory generated null")
			return
		var affix_count: int = generated.rolled_affixes.size()
		_assert_true(affix_count >= min_affixes and affix_count <= max_affixes, "Generated affix count out of range for grade %d: %d" % [grade, affix_count])
		_assert_true(generated.grade() == grade, "Generated part grade does not match affix count range")
		_assert_true(generated.parts_grade == generated.grade(), "Generated parts_grade cache mismatch")
		_assert_true(generated.template_path == template.resource_path, "Generated part missing template_path")
		_assert_true(generated.stat_multiplier >= 0.70 and generated.stat_multiplier <= 1.50, "Generated stat_multiplier out of range")
		_assert_true(generated.durability == generated.max_durability, "Generated part durability is not full")
		_assert_true(_affixes_are_unique_and_from_pool(generated, template.affix_pool), "Generated affixes are duplicated or outside pool")
		var base_max: int = MAX_DURABILITY_BY_AFFIX_COUNT[mini(affix_count, MAX_DURABILITY_BY_AFFIX_COUNT.size() - 1)]
		var expected_max: int = roundi(float(base_max) * 1.10) if generated.rolled_affixes.has("meticulous") else base_max
		_assert_true(generated.max_durability == expected_max, "Generated max durability mismatch for affix count %d" % affix_count)


func _check_ability_tree_contracts() -> void:
	_reset_state()
	var t1_attack: AbilityTreeNode = load("res://Resources/AbilityTree/node_attack_1.tres") as AbilityTreeNode
	var t1_defense: AbilityTreeNode = load("res://Resources/AbilityTree/node_defense_1.tres") as AbilityTreeNode
	var t2_utility: AbilityTreeNode = load("res://Resources/AbilityTree/node_mobility_2.tres") as AbilityTreeNode
	var t3_utility: AbilityTreeNode = load("res://Resources/AbilityTree/node_mobility_core.tres") as AbilityTreeNode
	if t1_attack == null or t1_defense == null or t2_utility == null or t3_utility == null:
		_fail("Ability tree fixtures missing")
		return
	_gs.set("meta_credits", 1000)
	_assert_true(not bool(_gs.call("unlock_tree_node", t2_utility)), "Ability tree unlocked T2 before any T1 node")
	_assert_true(bool(_gs.call("unlock_tree_node", t1_attack)), "Ability tree rejected valid T1 unlock")
	_assert_true(bool(_gs.call("unlock_tree_node", t2_utility)), "Ability tree rejected T2 after T1 unlock")
	_gs.call("set_run_tree_node", t1_attack)
	_assert_true(str((_gs.get("active_tree_node_ids") as Dictionary).get(1, "")) == t1_attack.node_id, "Ability tree did not select T1 node")
	_gs.call("set_run_tree_node", t1_defense)
	_assert_true(str((_gs.get("active_tree_node_ids") as Dictionary).get(1, "")) == t1_attack.node_id, "Ability tree selected a locked same-tier node")
	_gs.set("ability_node_levels", {
		t1_attack.node_id: 1,
		t1_defense.node_id: 1,
		t3_utility.node_id: 5,
	})
	_gs.call("set_run_tree_node", t1_defense)
	_assert_true(str((_gs.get("active_tree_node_ids") as Dictionary).get(1, "")) == t1_defense.node_id, "Ability tree did not replace same-tier loadout")
	_assert_true(t3_utility.action_bonus_at_level(4) == 0, "Action bonus applied before level 5")
	_assert_true(t3_utility.action_bonus_at_level(5) == 1, "Action bonus did not apply at level 5")

	_gs.call("start_run")
	var base_actions: int = int(_gs.get("current_action_count"))
	var base_payload: float = float(_gs.call("get_max_payload"))
	_gs.call("apply_tree_node", t3_utility, 5)
	_assert_true(int(_gs.get("current_action_count")) == base_actions + 1, "Level 5 action node did not increase runtime action count")
	_assert_true(is_equal_approx(float(_gs.call("get_max_payload")), base_payload + t3_utility.payload_bonus_at_level(5)), "Ability payload bonus did not affect max payload")
	_assert_true(str((_gs.get("active_core_visuals") as Dictionary).get(t3_utility.visual_slot, "")) == t3_utility.visual_variant, "Ability visual slot was not applied")
	print("Current OK: ability tree research, loadout, and runtime application contracts")


func _make_room(room_type: RoomData.RoomType) -> RoomData:
	var room: RoomData = RoomData.new()
	room.room_type = room_type
	return room


func _make_part(path: String, affixes: Array[String] = [], durability: int = -1) -> PartsData:
	var template: PartsData = load(path) as PartsData
	if template == null:
		_fail("Part template missing: %s" % path)
		return null
	var part: PartsData = template.duplicate(true) as PartsData
	part.template_path = path
	part.rolled_affixes = affixes.duplicate()
	part.parts_grade = part.grade()
	if durability >= 0:
		part.durability = durability
	part._normalize_durability()
	return part


func _empty_slots() -> Dictionary:
	return {
		CoreData.CoreSlot.ARM_L: null,
		CoreData.CoreSlot.ARM_R: null,
		CoreData.CoreSlot.BACK: null,
		CoreData.CoreSlot.LEG: null
	}


func _typed_part_array(value: Variant) -> Array[PartsData]:
	var out: Array[PartsData] = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for item: Variant in value:
		if item is PartsData:
			out.append(item)
	return out


func _typed_int_array(value: Variant) -> Array[int]:
	var out: Array[int] = []
	if typeof(value) != TYPE_ARRAY:
		return out
	for item: Variant in value:
		out.append(int(item))
	return out


func _packed_string_array_has(values: PackedStringArray, needle: String) -> bool:
	for value: String in values:
		if value == needle:
			return true
	return false


func _affixes_are_unique_and_from_pool(part: PartsData, pool: Array[String]) -> bool:
	var seen: Dictionary = {}
	for affix_id: String in part.rolled_affixes:
		if seen.has(affix_id):
			return false
		if not pool.has(affix_id):
			return false
		seen[affix_id] = true
	return true
