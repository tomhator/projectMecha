extends SceneTree

const SLOT_ARM_L: int = 0
const SLOT_ARM_R: int = 1
const SLOT_BACK: int = 2
const TARGET_SLOT_NONE: int = -1
const SKILL_TYPE_PASSIVE: int = 3
const COLLECTOR_ENEMY_ID: int = 301

const MECHA_SCRIPT_PATH: String = "res://Scenes/Entities/MechaEntity.gd"
const ENEMY_SCRIPT_PATH: String = "res://Scenes/Entities/EnemyEntity.gd"
const TURN_MANAGER_SCRIPT_PATH: String = "res://Scenes/Combat/TurnManager.gd"
const SKILL_SCRIPT_PATH: String = "res://Resources/SkillData.gd"

var _failed: bool = false


func _initialize() -> void:
	randomize()
	_check_normal_enemies_have_no_snipe()
	await _check_broken_part_skill_and_affix()
	await _check_auto_turn_end_when_no_usable_skills()
	await _check_back_snipe()
	await _check_collector_boss_flow()
	if _failed:
		print("P0 combat flows: FAIL")
		quit(1)
	else:
		print("P0 combat flows: PASS")
		quit(0)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _game_state() -> Node:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		_fail("Missing GameState autoload")
	return game_state


func _event_bus() -> Node:
	var event_bus := root.get_node_or_null("EventBus")
	if event_bus == null:
		_fail("Missing EventBus autoload")
	return event_bus


func _reset_run() -> void:
	var game_state := _game_state()
	if game_state != null:
		game_state.call("start_run")


func _load_resource(path: String) -> Resource:
	var res := load(path) as Resource
	if res == null:
		_fail("Resource load failed: %s" % path)
	return res


func _load_part(path: String) -> Resource:
	var part := _load_resource(path)
	if part == null:
		return null
	return part.duplicate(true) as Resource


func _new_mecha() -> Node:
	return load(MECHA_SCRIPT_PATH).new()


func _new_enemy() -> Node:
	return load(ENEMY_SCRIPT_PATH).new()


func _new_turn_manager() -> Node:
	return load(TURN_MANAGER_SCRIPT_PATH).new()


func _enemy_from_data(path: String) -> Node:
	var data := _load_resource(path)
	if data == null:
		return null
	var script_path: String = "res://Scenes/Entities/BossCollectorEntity.gd" if int(data.get("enemy_id")) == COLLECTOR_ENEMY_ID else "res://Scenes/Entities/EnemyEntity.gd"
	var enemy: Node = load(script_path).new()
	enemy.call("setup_from_data", data)
	return enemy


func _set_equipped_part(slot: int, part: Resource) -> void:
	_game_state().get("equipped_parts")[slot] = part


func _get_equipped_part(slot: int) -> Resource:
	return _game_state().get("equipped_parts")[slot]


func _dispose_node(node: Node) -> void:
	if node == null:
		return
	if node.is_inside_tree():
		node.queue_free()
	else:
		node.free()


func _check_normal_enemies_have_no_snipe() -> void:
	for path: String in [
		"res://Resources/Enemies/enemy_scrapper.tres",
		"res://Resources/Enemies/enemy_rusher.tres",
	]:
		var data := _load_resource(path)
		if data == null:
			continue
		for skill in data.get("skills"):
			_assert_true(int(skill.get("target_slot")) == TARGET_SLOT_NONE, "%s has snipe skill: %s" % [data.get("enemy_name"), skill.get("skill_name")])
	print("P0 OK: normal enemies have no snipe previews")


func _check_broken_part_skill_and_affix() -> void:
	_reset_run()
	var mecha := _new_mecha()
	root.add_child(mecha)
	var part := _load_part("res://Resources/Parts/arm_l/arm_l_gr21.tres")
	if part == null:
		_dispose_node(mecha)
		return
	var skill = part.get("parts_skills")[0]
	part.set("rolled_affixes", ["greedy", "overload"])
	part.set("durability", 0)
	_set_equipped_part(SLOT_ARM_L, part)
	mecha.call("setup")
	_assert_true(mecha.call("get_display_skills").has(skill), "Broken part skill missing from display list")
	_assert_true(not mecha.call("get_available_skills").has(skill), "Broken part skill still usable")
	var enemy := _new_enemy()
	root.add_child(enemy)
	enemy.set("enemy_name", "검증 더미")
	enemy.set("enemy_max_hp", 100.0)
	enemy.set("current_hp", 100.0)
	var preview: float = float(mecha.call("get_preview_outgoing_damage", skill, enemy))
	var affix_bonus: float = float(mecha.call("_affix_bonus_sum", part, enemy, false))
	_assert_true(is_equal_approx(affix_bonus, 0.0), "Broken part affix bonus still applied")
	_assert_true(preview > 0.0, "Broken part preview unexpectedly zero")
	_dispose_node(mecha)
	_dispose_node(enemy)
	await process_frame
	print("P0 OK: broken part skill disabled and affix ignored")


func _check_auto_turn_end_when_no_usable_skills() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var enemy := _new_enemy()
	var manager := _new_turn_manager()
	root.add_child(mecha)
	root.add_child(enemy)
	root.add_child(manager)
	var part := _load_part("res://Resources/Parts/arm_l/arm_l_gr21.tres")
	var enemy_skill_source := _load_resource("res://Resources/Skills/skill_rapid_fire.tres")
	if part == null or enemy_skill_source == null:
		_dispose_node(manager)
		_dispose_node(mecha)
		_dispose_node(enemy)
		return
	var enemy_skill := enemy_skill_source.duplicate(true)
	part.set("durability", 0)
	_set_equipped_part(SLOT_ARM_L, part)
	enemy.set("enemy_name", "행동 없음 검증 적")
	enemy.set("enemy_max_hp", 20.0)
	enemy.set("enemy_action_count", 1)
	enemy.get("skills").clear()
	enemy_skill.set("skill_damage", 200.0)
	enemy_skill.set("skill_action_cost", 1)
	enemy.get("skills").append(enemy_skill)
	manager.call("start_combat_untyped", mecha, [enemy])
	await process_frame
	_assert_true(int(manager.get("current_turn")) >= 1 and int(manager.get("current_phase")) != 0, "No usable skills did not auto-end player turn")
	_dispose_node(manager)
	_dispose_node(mecha)
	_dispose_node(enemy)
	await process_frame
	print("P0 OK: no usable skills auto-end player turn")


func _check_back_snipe() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var enemy := _new_enemy()
	root.add_child(mecha)
	root.add_child(enemy)
	var part := _load_part("res://Resources/Parts/back/back_fr1.tres")
	var emp := _load_resource("res://Resources/Skills/skill_emp_shock.tres")
	if part == null or emp == null:
		_dispose_node(mecha)
		_dispose_node(enemy)
		return
	part.set("durability", 3)
	_set_equipped_part(SLOT_BACK, part)
	mecha.call("setup")
	enemy.set("enemy_name", "EMP 검증 적")
	enemy.set("enemy_max_hp", 20.0)
	enemy.set("enemy_action_count", 2)
	enemy.get("skills").clear()
	enemy.get("skills").append(emp)
	enemy.call("setup")
	enemy.get("next_actions").clear()
	enemy.get("next_actions").append(emp)
	var durability_before: int = int(part.get("durability"))
	enemy.call("execute_actions", mecha)
	_assert_true(int(part.get("durability")) == durability_before - 1, "BACK snipe did not reduce durability")
	_set_equipped_part(SLOT_BACK, null)
	mecha.call("setup")
	enemy.get("next_actions").clear()
	enemy.get("next_actions").append(emp)
	_game_state().set("current_shield", 0.0)
	var hp_before: float = float(_game_state().get("current_hp"))
	enemy.call("execute_actions", mecha)
	_assert_true(float(_game_state().get("current_hp")) < hp_before, "Empty BACK snipe did not deal HP damage")
	_assert_true(mecha.call("get_part_at_slot", SLOT_BACK) == null, "BACK slot unexpectedly occupied")
	_dispose_node(mecha)
	_dispose_node(enemy)
	await process_frame
	print("P0 OK: BACK snipe durability and empty slot behavior")


func _check_collector_boss_flow() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var manager := _new_turn_manager()
	var boss := _enemy_from_data("res://Resources/Enemies/enemy_collector.tres")
	var player_arm := _load_part("res://Resources/Parts/arm_r/arm_r_gr21.tres")
	if player_arm != null:
		_set_equipped_part(SLOT_ARM_R, player_arm)
	root.add_child(mecha)
	root.add_child(manager)
	root.add_child(boss)
	manager.call("start_combat_untyped", mecha, [boss])
	await process_frame
	_assert_true(manager.get("enemies").size() == 5, "Collector start should have core + 4 arms")
	_assert_true(boss.get("active_arms").size() == 4, "Collector active arms should start at 4")

	var first_arm: Node = boss.get("active_arms")[0]
	first_arm.call("take_damage", 999.0)
	manager.call("_prune_defeated_boss_arms")
	_assert_true(manager.get("enemies").size() == 4, "Defeated collector arm remains in enemies")
	_assert_true(boss.get("active_arms").size() == 3, "Defeated collector arm remains active")

	for arm in boss.get("active_arms").duplicate():
		arm.call("take_damage", 999.0)
	manager.call("_prune_defeated_boss_arms")
	boss.call("decide_next_actions")
	await process_frame
	_assert_true(boss.get("active_arms").size() == 4, "Collector did not recollect 4 arms")
	_assert_true(manager.get("enemies").size() == 5, "Recollected arms not added to enemies")

	var arm_part := _load_part("res://Resources/Parts/arm_r/arm_r_gr21.tres")
	if arm_part != null:
		_set_equipped_part(SLOT_ARM_R, arm_part)
		mecha.call("setup")
		for arm in boss.get("active_arms").duplicate():
			arm.call("take_damage", 999.0)
		manager.call("_prune_defeated_boss_arms")
		boss.call("_apply_arm_theft", mecha)
		await process_frame
		_assert_true(_get_equipped_part(SLOT_ARM_R) == null, "Arm theft did not empty player ARM slot")
		var stolen_found: bool = false
		for enemy in manager.get("enemies"):
			if String(enemy.get("enemy_name")).begins_with("강탈된 "):
				stolen_found = true
		_assert_true(stolen_found, "Stolen arm entity not added to enemies")

	boss.call("take_damage", 9999.0)
	_assert_true(bool(manager.call("_check_combat_end")), "Collector core defeat did not end combat")
	_assert_true(int(manager.get("current_phase")) == 2, "Collector core defeat did not set combat end")
	var nodes_to_dispose: Array = []
	for enemy in manager.get("enemies"):
		if enemy not in nodes_to_dispose:
			nodes_to_dispose.append(enemy)
	for arm in boss.get("active_arms"):
		if arm not in nodes_to_dispose:
			nodes_to_dispose.append(arm)
	nodes_to_dispose.append(manager)
	nodes_to_dispose.append(mecha)
	var event_bus := _event_bus()
	if event_bus != null:
		var arm_signal := Signal(event_bus, "boss_arm_spawned")
		var add_enemy_callable := Callable(manager, "add_enemy")
		if arm_signal.is_connected(add_enemy_callable):
			arm_signal.disconnect(add_enemy_callable)
	for node in nodes_to_dispose:
		_dispose_node(node)
	await process_frame
	await process_frame
	await process_frame
	print("P0 OK: collector boss arms, theft, and core victory")
