extends SceneTree

const ARM_L_PATH: String = "res://Resources/Parts/arm_l/arm_l_gr21.tres"
const ARM_R_PATH: String = "res://Resources/Parts/arm_r/arm_r_gr21.tres"
const BACK_PATH: String = "res://Resources/Parts/back/back_fr1.tres"

var _failed: bool = false
var _snapshot: Dictionary = {}
var _gs: Node = null


func _initialize() -> void:
	_gs = root.get_node_or_null("GameState")
	if _gs == null:
		_fail("Missing GameState autoload")
		quit(1)
		return
	_snapshot = _take_snapshot()
	_reset_base_state()
	_check_part_save_restore()
	_check_success_settlement()
	_check_failure_settlement()
	_check_services_and_capacity()
	_restore_snapshot(_snapshot)
	if _failed:
		print("Base state: FAIL")
		quit(1)
	else:
		print("Base state: PASS")
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


func _reset_base_state() -> void:
	_gs.set("is_run_active", false)
	_gs.set("current_floor", 0)
	_gs.set("meta_credits", 0)
	_gs.set("meta_scrap", 0)
	(_gs.get("storage_parts") as Array).clear()
	(_gs.get("sortie_inventory") as Array).clear()
	_gs.set("sortie_equipped_parts", _empty_slots())
	(_gs.get("last_run_summary") as Dictionary).clear()
	_gs.set("total_runs", 0)
	_gs.set("successful_runs", 0)
	_gs.set("failed_runs", 0)
	_gs.set("highest_floor", 0)
	(_gs.get("inventory") as Array).clear()
	_gs.set("equipped_parts", _empty_slots())
	_gs.set("credits", 0)
	_gs.set("run_scrap", 0)


func _check_part_save_restore() -> void:
	var part: PartsData = _make_part(ARM_L_PATH, ["greedy", "overload"], 2)
	part.stat_multiplier = 1.23
	part.parts_weight = 42.0
	var saved: Dictionary = _gs.call("_part_to_save_dict", part)
	var restored: PartsData = _gs.call("_part_from_save_dict", saved)
	_assert_true(restored != null, "Stored part did not restore")
	if restored == null:
		return
	_assert_true(restored.template_path == ARM_L_PATH, "template_path was not restored")
	_assert_true(is_equal_approx(restored.stat_multiplier, 1.23), "stat_multiplier was not restored")
	_assert_true(restored.rolled_affixes == ["greedy", "overload"], "rolled_affixes were not restored")
	_assert_true(restored.durability == 2, "durability was not restored")
	_assert_true(is_equal_approx(restored.parts_weight, 42.0), "rolled weight was not restored")
	print("Base OK: part save and restore")


func _check_success_settlement() -> void:
	_reset_base_state()
	var equipped: PartsData = _make_part(ARM_L_PATH)
	var carried: PartsData = _make_part(BACK_PATH)
	(_gs.get("storage_parts") as Array).append(equipped)
	(_gs.get("storage_parts") as Array).append(carried)
	_assert_true(bool(_gs.call("equip_sortie_part", equipped, CoreData.CoreSlot.ARM_L)), "Could not stage equipped part")
	_assert_true(bool(_gs.call("move_storage_to_sortie_inventory", carried)), "Could not stage sortie inventory")
	_gs.call("start_run")
	_gs.call("add_credits", 100)
	_gs.call("add_scrap", 30)
	_gs.set("current_floor", 11)
	_gs.call("end_run", true)
	_assert_true(int(_gs.get("meta_credits")) == 100, "Success settlement did not recover 100% credits")
	_assert_true(int(_gs.get("meta_scrap")) == 30, "Success settlement did not recover 100% scrap")
	_assert_true((_gs.get("storage_parts") as Array).size() == 2, "Success settlement did not recover equipped + inventory parts")
	_assert_true(int((_gs.get("last_run_summary") as Dictionary).get("lost_part_count", -1)) == 0, "Success settlement lost parts")
	print("Base OK: success settlement")


func _check_failure_settlement() -> void:
	_reset_base_state()
	var equipped: PartsData = _make_part(ARM_R_PATH)
	var carried: PartsData = _make_part(BACK_PATH)
	(_gs.get("storage_parts") as Array).append(equipped)
	(_gs.get("storage_parts") as Array).append(carried)
	_assert_true(bool(_gs.call("equip_sortie_part", equipped, CoreData.CoreSlot.ARM_R)), "Could not stage failure equipped part")
	_assert_true(bool(_gs.call("move_storage_to_sortie_inventory", carried)), "Could not stage failure inventory part")
	_gs.call("start_run")
	_gs.call("add_credits", 101)
	_gs.call("add_scrap", 11)
	_gs.set("current_floor", 7)
	_gs.call("end_run", false)
	_assert_true(int(_gs.get("meta_credits")) == 50, "Failure settlement did not recover 50% credits")
	_assert_true(int(_gs.get("meta_scrap")) == 5, "Failure settlement did not recover 50% scrap")
	_assert_true((_gs.get("storage_parts") as Array).size() == 1, "Failure settlement did not recover only inventory parts")
	_assert_true(int((_gs.get("last_run_summary") as Dictionary).get("lost_part_count", -1)) == 1, "Failure settlement did not record equipped part loss")
	print("Base OK: failure settlement")


func _check_services_and_capacity() -> void:
	_reset_base_state()
	var broken: PartsData = _make_part(ARM_L_PATH, [], 0)
	(_gs.get("storage_parts") as Array).append(broken)
	_gs.set("meta_scrap", int(_gs.call("repair_cost_for_part", broken)))
	_assert_true(bool(_gs.call("repair_storage_part", broken)), "Repair service failed")
	_assert_true(broken.durability == broken.max_durability, "Repair did not restore durability")
	var scrap_before: int = int(_gs.get("meta_scrap"))
	_assert_true(bool(_gs.call("dismantle_storage_part", broken)), "Dismantle service failed")
	_assert_true(int(_gs.get("meta_scrap")) == scrap_before + int(_gs.call("dismantle_value_for_part", broken)), "Dismantle did not pay scrap")

	_reset_base_state()
	var capacity: int = int(_gs.call("get_inventory_capacity"))
	for i: int in range(capacity):
		(_gs.get("storage_parts") as Array).append(_make_part(ARM_L_PATH))
	var extra: PartsData = _make_part(ARM_L_PATH)
	(_gs.get("storage_parts") as Array).append(extra)
	for i: int in range(capacity):
		var first_part: PartsData = (_gs.get("storage_parts") as Array)[0]
		_assert_true(bool(_gs.call("move_storage_to_sortie_inventory", first_part)), "Sortie inventory rejected valid part")
	_assert_true(not bool(_gs.call("move_storage_to_sortie_inventory", extra)), "Sortie inventory accepted overflow")
	print("Base OK: services and capacity")


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
	for part: Variant in value:
		if part is PartsData:
			out.append(part)
	return out
