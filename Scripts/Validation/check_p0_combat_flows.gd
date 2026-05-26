extends SceneTree


const SLOT_ARM_L: int = 0
const SLOT_ARM_R: int = 1
const SLOT_BACK: int = 2
const SLOT_LEG: int = 3
const TARGET_SLOT_NONE: int = -1
const SKILL_TYPE_PASSIVE: int = 3

const MECHA_SCRIPT_PATH: String = "res://Scenes/Entities/MechaEntity.gd"
const ENEMY_SCRIPT_PATH: String = "res://Scenes/Entities/EnemyEntity.gd"
const TURN_MANAGER_SCRIPT_PATH: String = "res://Scenes/Combat/TurnManager.gd"
const SKILL_SCRIPT_PATH: String = "res://Resources/SkillData.gd"

var _failed: bool = false


func _initialize() -> void:
	randomize()
	await _check_broken_part_skill_and_affix()
	await _check_undefined_behavior_affix_turn_start()
	await _check_basic_attack_remains_when_parts_break()
	_check_inventory_capacity()
	_check_combat_skill_order()
	await _check_core_part_abilities()
	await _check_back_snipe()
	await _check_breaker_arm_snipe()
	await _check_support_ally_targets()
	await _check_caller_summon_flow()
	await _check_junkyard_elites()
	await _check_collector_protection_and_exposure()
	await _check_multi_target_player_skill()
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


func _new_combat_dummy(name: String, hp: float = 100.0) -> Node:
	var enemy := _new_enemy()
	enemy.set("enemy_name", name)
	enemy.set("enemy_max_hp", hp)
	enemy.set("current_hp", hp)
	enemy.set("enemy_action_count", 0)
	return enemy


func _new_untargetable_dummy(name: String, hp: float = 100.0) -> Node:
	var script := GDScript.new()
	script.source_code = (
		"extends \"res://Scenes/Entities/EnemyEntity.gd\"\n\n"
		+ "func is_targetable() -> bool:\n"
		+ "\treturn false\n"
	)
	var err: Error = script.reload()
	if err != OK:
		_fail("Untargetable enemy script compile failed")
		return null
	var enemy: Node = script.new() as Node
	enemy.set("enemy_name", name)
	enemy.set("enemy_max_hp", hp)
	enemy.set("current_hp", hp)
	enemy.set("enemy_action_count", 0)
	return enemy


func _new_turn_manager() -> Node:
	return load(TURN_MANAGER_SCRIPT_PATH).new()


func _enemy_from_data(path: String) -> Node:
	var data := _load_resource(path)
	if data == null:
		return null
	var enemy := _new_enemy()
	enemy.call("setup_from_data", data)
	return enemy


func _collector_from_data() -> Node:
	var data := _load_resource("res://Resources/Enemies/enemy_collector.tres")
	if data == null:
		return null
	var boss: Node = load("res://Scenes/Entities/BossCollectorEntity.gd").new()
	boss.call("setup_from_data", data)
	return boss


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


func _has_descendant_label_text(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text == text:
		return true
	for child: Node in node.get_children():
		if _has_descendant_label_text(child, text):
			return true
	return false


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


func _check_undefined_behavior_affix_turn_start() -> void:
	_reset_run()
	var manager := _new_turn_manager()
	var mecha := _new_mecha()
	var enemy := _new_combat_dummy("undefined_behavior 검증 적")
	var part := _load_part("res://Resources/Parts/arm_l/arm_l_gr21.tres")
	if part == null:
		_dispose_node(manager)
		_dispose_node(mecha)
		_dispose_node(enemy)
		return
	var skill := (part.get("parts_skills")[0] as SkillData).duplicate(true) as SkillData
	skill.skill_damage = 20.0
	skill.skill_action_cost = 1
	skill.skill_target = SkillData.SkillTarget.ENEMY
	skill.hit_count = 1
	var part_skills: Array[SkillData] = [skill]
	var affixes: Array[String] = ["undefined_behavior"]
	part.set("parts_skills", part_skills)
	part.set("rolled_affixes", affixes)
	part.set("stat_multiplier", 1.0)
	part.set("max_durability", 3)
	part.set("durability", 3)
	_set_equipped_part(SLOT_ARM_L, part)
	root.add_child(manager)
	root.add_child(mecha)
	root.add_child(enemy)
	manager.call("start_combat_untyped", mecha, [enemy])
	await process_frame
	_assert_true(part.has_meta("undefined_behavior_modifier"), "undefined_behavior modifier was not generated on player turn start")
	var turn_mod: float = float(part.get_meta("undefined_behavior_modifier"))
	_assert_true(turn_mod >= -0.20 and turn_mod <= 0.60, "undefined_behavior modifier outside expected range")
	var expected_damage: float = skill.skill_damage * float(_game_state().get("attack_multiplier")) * maxf(1.0 + turn_mod, 0.1)
	var preview: float = float(mecha.call("get_preview_outgoing_damage", skill, enemy))
	_assert_true(is_equal_approx(preview, expected_damage), "undefined_behavior modifier did not affect preview damage")
	var hp_before: float = float(enemy.get("current_hp"))
	mecha.call("use_skill", skill, enemy)
	_assert_true(is_equal_approx(hp_before - float(enemy.get("current_hp")), expected_damage), "undefined_behavior modifier did not affect actual damage")
	part.set("durability", 0)
	mecha.call("on_player_turn_started")
	_assert_true(not part.has_meta("undefined_behavior_modifier"), "Broken undefined_behavior part kept turn modifier")
	var broken_affix_bonus: float = float(mecha.call("_affix_bonus_sum", part, enemy, false))
	_assert_true(is_equal_approx(broken_affix_bonus, 0.0), "Broken undefined_behavior part still applied affix bonus")
	for node in [manager, mecha, enemy]:
		_dispose_node(node)
	await process_frame
	print("P0 OK: undefined_behavior turn-start modifier, output, and broken cleanup")


func _check_basic_attack_remains_when_parts_break() -> void:
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
	enemy.set("enemy_name", "기본 공격 검증 적")
	enemy.set("enemy_max_hp", 20.0)
	enemy.set("enemy_action_count", 1)
	enemy.get("skills").clear()
	enemy_skill.set("skill_damage", 200.0)
	enemy_skill.set("skill_action_cost", 1)
	enemy.get("skills").append(enemy_skill)
	manager.call("start_combat_untyped", mecha, [enemy])
	await process_frame
	_assert_true(int(manager.get("current_turn")) >= 1 and int(manager.get("current_phase")) == 0, "Basic attack did not keep the player turn active")
	_assert_true(not mecha.call("get_available_skills").is_empty(), "No fallback basic attack available after part break")
	_dispose_node(manager)
	_dispose_node(mecha)
	_dispose_node(enemy)
	await process_frame
	print("P0 OK: basic attack remains when part skills break")


func _check_inventory_capacity() -> void:
	_reset_run()
	var game_state := _game_state()
	if game_state == null:
		return
	var capacity: int = int(game_state.call("get_inventory_capacity"))
	for i: int in range(capacity):
		var part := _load_part("res://Resources/Parts/arm_l/arm_l_gr21.tres")
		if part == null:
			return
		_assert_true(bool(game_state.call("add_to_inventory", part)), "Inventory rejected part before capacity at index %d" % i)
	var extra := _load_part("res://Resources/Parts/arm_l/arm_l_ml7.tres")
	if extra == null:
		return
	_assert_true(not bool(game_state.call("add_to_inventory", extra)), "Inventory accepted a part beyond capacity")
	_assert_true(game_state.get("inventory").size() == capacity, "Inventory size exceeded capacity")
	print("P0 OK: inventory capacity rejects overflow")


func _check_combat_skill_order() -> void:
	_reset_run()
	var arm_l := _load_part("res://Resources/Parts/arm_l/arm_l_gr21.tres")
	var arm_r := _load_part("res://Resources/Parts/arm_r/arm_r_gr21.tres")
	var back := _load_part("res://Resources/Parts/back/back_fr1.tres")
	var leg := _load_part("res://Resources/Parts/leg/leg_strider1.tres")
	if arm_l == null or arm_r == null or back == null or leg == null:
		return
	_set_equipped_part(SLOT_ARM_L, arm_l)
	_set_equipped_part(SLOT_ARM_R, arm_r)
	_set_equipped_part(SLOT_BACK, back)
	_set_equipped_part(SLOT_LEG, leg)

	var ordered: Array = _game_state().call("get_combat_skill_order")
	_assert_true(ordered.size() >= 6, "Combat skill order missing core or part skills")
	_assert_true(ordered[0] == _game_state().get("active_basic_attack"), "Basic attack is not first in combat skill order")
	_assert_true(ordered[1] == _game_state().get("active_part_ability"), "Part ability is not second in combat skill order")
	_assert_true(ordered[2] == arm_l.get("parts_skills")[0], "ARM_L skill is not third in combat skill order")
	_assert_true(ordered[3] == arm_r.get("parts_skills")[0], "ARM_R skill is not fourth in combat skill order")
	_assert_true(ordered[4] == back.get("parts_skills")[0], "BACK skill is not fifth in combat skill order")
	_assert_true(ordered[5] == leg.get("parts_skills")[0], "LEG skill is not sixth in combat skill order")
	print("P0 OK: combat skill order is stable")


func _check_core_part_abilities() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var enemy := _new_enemy()
	root.add_child(mecha)
	root.add_child(enemy)
	enemy.set("enemy_name", "파츠 어빌리티 검증 적")
	enemy.set("enemy_max_hp", 100.0)
	enemy.set("current_hp", 100.0)

	var emergency_swap := _load_resource("res://Resources/Skills/skill_core_emergency_swap.tres")
	var broken_throw := _load_resource("res://Resources/Skills/skill_core_broken_throw.tres")
	var scrap_patch := _load_resource("res://Resources/Skills/skill_core_scrap_patch.tres")
	var old_arm := _load_part("res://Resources/Parts/arm_l/arm_l_gr21.tres")
	var new_arm := _load_part("res://Resources/Parts/arm_l/arm_l_ml7.tres")
	var scrap := _load_part("res://Resources/Parts/back/back_fr1.tres")
	if emergency_swap == null or broken_throw == null or scrap_patch == null or old_arm == null or new_arm == null or scrap == null:
		_dispose_node(mecha)
		_dispose_node(enemy)
		return

	_set_equipped_part(SLOT_ARM_L, old_arm)
	_game_state().get("inventory").append(new_arm)
	_game_state().set("active_part_ability", emergency_swap)
	mecha.call("setup")
	mecha.call("use_skill", emergency_swap, mecha)
	_assert_true(_get_equipped_part(SLOT_ARM_L) == new_arm, "Emergency swap did not equip inventory part")
	_assert_true(bool(old_arm.call("is_broken")), "Emergency swap did not break replaced part")

	scrap.set("durability", 0)
	_game_state().get("inventory").append(scrap)
	_game_state().set("active_part_ability", broken_throw)
	mecha.call("setup")
	var hp_before: float = float(enemy.get("current_hp"))
	var throw_inventory_before: int = _game_state().get("inventory").size()
	mecha.call("use_skill", broken_throw, enemy)
	_assert_true(float(enemy.get("current_hp")) < hp_before, "Broken throw did not damage enemy")
	_assert_true(_game_state().get("inventory").size() == throw_inventory_before - 1, "Broken throw did not consume broken part")

	old_arm.set("durability", 0)
	_game_state().get("inventory").append(old_arm)
	_game_state().set("current_shield", 0.0)
	_game_state().set("active_part_ability", scrap_patch)
	mecha.call("setup")
	var patch_inventory_before: int = _game_state().get("inventory").size()
	mecha.call("use_skill", scrap_patch, mecha)
	_assert_true(float(_game_state().get("current_shield")) > 0.0, "Scrap patch did not add shield")
	_assert_true(_game_state().get("inventory").size() == patch_inventory_before - 1, "Scrap patch did not consume broken part")
	_dispose_node(mecha)
	_dispose_node(enemy)
	await process_frame
	print("P0 OK: core part abilities swap, throw, and patch")


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


func _check_breaker_arm_snipe() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var breaker := _enemy_from_data("res://Resources/Enemies/enemy_cutting_claw.tres")
	var arm := _load_part("res://Resources/Parts/arm_l/arm_l_gr21.tres")
	var arm_cut := _load_resource("res://Resources/Skills/skill_arm_cut.tres")
	if arm == null or arm_cut == null or breaker == null:
		_dispose_node(mecha)
		_dispose_node(breaker)
		return
	root.add_child(mecha)
	root.add_child(breaker)
	arm.set("durability", 3)
	_set_equipped_part(SLOT_ARM_L, arm)
	mecha.call("setup")
	breaker.call("setup")
	breaker.get("next_actions").clear()
	breaker.get("next_actions").append(arm_cut)
	breaker.call("_publish_snipe_preview")
	_assert_true(int(breaker.get("_preview_target_slot")) == SLOT_ARM_L, "Breaker ARM preview did not target ARM_L")
	var durability_before: int = int(arm.get("durability"))
	breaker.call("execute_actions", mecha)
	_assert_true(int(arm.get("durability")) == durability_before - 1, "Breaker ARM cut did not reduce durability")

	_set_equipped_part(SLOT_ARM_L, null)
	mecha.call("setup")
	breaker.get("next_actions").clear()
	breaker.get("next_actions").append(arm_cut)
	breaker.call("_publish_snipe_preview")
	_assert_true(int(breaker.get("_preview_target_slot")) == TARGET_SLOT_NONE, "Empty ARM slot still showed Breaker preview")
	_game_state().set("current_shield", 0.0)
	var hp_before: float = float(_game_state().get("current_hp"))
	breaker.call("execute_actions", mecha)
	_assert_true(float(_game_state().get("current_hp")) < hp_before, "Empty ARM Breaker hit did not damage HP")
	_dispose_node(mecha)
	_dispose_node(breaker)
	await process_frame
	print("P0 OK: Breaker ARM preview and durability flow")


func _check_support_ally_targets() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var drone := _enemy_from_data("res://Resources/Enemies/enemy_patch_drone.tres")
	var weak_ally := _enemy_from_data("res://Resources/Enemies/enemy_junk_rammer.tres")
	var shield_ally := _new_enemy()
	var repair := _load_resource("res://Resources/Skills/skill_emergency_repair_enemy.tres")
	var patch_shield := _load_resource("res://Resources/Skills/skill_patch_shield.tres")
	if drone == null or weak_ally == null or repair == null or patch_shield == null:
		_dispose_node(mecha)
		_dispose_node(drone)
		_dispose_node(weak_ally)
		_dispose_node(shield_ally)
		return
	root.add_child(mecha)
	root.add_child(drone)
	root.add_child(weak_ally)
	root.add_child(shield_ally)
	drone.call("setup")
	weak_ally.call("setup")
	shield_ally.set("enemy_name", "실드 지원 검증 적")
	shield_ally.set("enemy_max_hp", 10.0)
	shield_ally.set("enemy_max_shield", 10.0)
	shield_ally.set("current_hp", 10.0)
	shield_ally.set("current_shield", 0.0)
	weak_ally.call("take_damage", 12.0)
	var weak_hp_before: float = float(weak_ally.get("current_hp"))
	drone.get("next_actions").clear()
	drone.get("next_actions").append(repair)
	drone.call("execute_actions", mecha, [drone, weak_ally, shield_ally])
	_assert_true(float(weak_ally.get("current_hp")) > weak_hp_before, "Support repair did not heal lowest HP ratio ally")

	drone.set("current_shield", drone.get("enemy_max_shield"))
	var shield_before: float = float(shield_ally.get("current_shield"))
	drone.get("next_actions").clear()
	drone.get("next_actions").append(patch_shield)
	drone.call("execute_actions", mecha, [drone, weak_ally, shield_ally])
	_assert_true(float(shield_ally.get("current_shield")) > shield_before, "Support shield did not protect lowest shield ally")
	_dispose_node(mecha)
	_dispose_node(drone)
	_dispose_node(weak_ally)
	_dispose_node(shield_ally)
	await process_frame
	print("P0 OK: Support ally heal and shield targeting")


func _check_caller_summon_flow() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var caller := _enemy_from_data("res://Resources/Enemies/enemy_signal_dummy.tres")
	var manager := _new_turn_manager()
	var scrap_call := _load_resource("res://Resources/Skills/skill_scrap_call.tres")
	if caller == null or scrap_call == null:
		_dispose_node(mecha)
		_dispose_node(caller)
		_dispose_node(manager)
		return
	root.add_child(mecha)
	root.add_child(caller)
	root.add_child(manager)
	manager.call("start_combat_untyped", mecha, [caller])
	caller.get("next_actions").clear()
	caller.get("next_actions").append(scrap_call)
	caller.call("execute_actions", mecha, [caller])
	await process_frame
	_assert_true(manager.get("enemies").size() == 2, "Caller did not add exactly one summoned enemy")
	_assert_true(not bool(caller.call("_can_execute_summon", scrap_call)), "Caller summon remained available after one use")
	var summoned: Node = manager.get("enemies")[1]
	caller.call("take_damage", 999.0)
	manager.call("_count_new_defeats")
	_assert_true(not bool(manager.call("_check_combat_end")), "Summoned enemy did not keep combat active")
	summoned.call("take_damage", 999.0)
	manager.call("_count_new_defeats")
	_assert_true(int(manager.call("get_defeated_enemy_count")) == 1, "Summoned enemy counted toward combat drops")
	_assert_true(bool(manager.call("_check_combat_end")), "Caller combat did not end after summon defeat")
	_dispose_node(manager)
	_dispose_node(mecha)
	for enemy in [caller, summoned]:
		_dispose_node(enemy)
	await process_frame
	print("P0 OK: Caller one-shot summon and drop exclusion")


func _check_junkyard_elites() -> void:
	_reset_run()
	var dungeon_manager := root.get_node_or_null("DungeonManager")
	_assert_true(dungeon_manager != null, "Missing DungeonManager autoload")
	if dungeon_manager != null:
		var previous_room = dungeon_manager.call("get_current_room")
		var elite_room := RoomData.new()
		elite_room.room_type = RoomData.RoomType.BATTLE_ELITE
		dungeon_manager.set("_current_choice", elite_room)
		var elite_pool_pick: Array = dungeon_manager.call("get_enemies_for_current_room")
		_assert_true(elite_pool_pick.size() == 1, "Junkyard elite room should pick exactly one enemy")
		if not elite_pool_pick.is_empty():
			_assert_true((elite_pool_pick[0] as EnemyData).enemy_tier == EnemyData.EnemyTier.ELITE, "Junkyard elite room picked a non-elite enemy")
		dungeon_manager.set("_current_choice", previous_room)
	var mecha := _new_mecha()
	var compactor := _enemy_from_data("res://Resources/Enemies/enemy_compactor.tres")
	var recovery_tow := _enemy_from_data("res://Resources/Enemies/enemy_recovery_tow.tres")
	if compactor == null or recovery_tow == null:
		_dispose_node(mecha)
		_dispose_node(compactor)
		_dispose_node(recovery_tow)
		return
	root.add_child(mecha)
	root.add_child(compactor)
	root.add_child(recovery_tow)
	mecha.call("setup")
	compactor.call("setup")
	recovery_tow.call("setup")
	_assert_true(int(compactor.get("enemy_tier")) == 1, "Compactor is not ELITE tier")
	_assert_true(int(recovery_tow.get("enemy_tier")) == 1, "Recovery tow is not ELITE tier")
	_assert_true(float(compactor.get("enemy_max_shield")) >= 30.0, "Compactor shield is too low for Anchor role")

	var compactor_slam := _load_resource("res://Resources/Skills/skill_compactor_slam.tres")
	var compactor_reinforce := _load_resource("res://Resources/Skills/skill_compactor_reinforce.tres")
	if compactor_slam == null or compactor_reinforce == null:
		_dispose_node(mecha)
		_dispose_node(compactor)
		_dispose_node(recovery_tow)
		return
	_game_state().set("current_shield", 0.0)
	var hp_before: float = float(_game_state().get("current_hp"))
	compactor.get("next_actions").clear()
	compactor.get("next_actions").append(compactor_slam)
	compactor.call("execute_actions", mecha, [compactor, recovery_tow])
	_assert_true(float(_game_state().get("current_hp")) < hp_before, "Compactor heavy attack did not damage player HP")
	compactor.set("current_shield", 0.0)
	compactor.get("next_actions").clear()
	compactor.get("next_actions").append(compactor_reinforce)
	compactor.call("execute_actions", mecha, [compactor, recovery_tow])
	_assert_true(float(compactor.get("current_shield")) > 0.0, "Compactor reinforce did not restore shield")

	var leg := _load_part("res://Resources/Parts/leg/leg_strider1.tres")
	var back := _load_part("res://Resources/Parts/back/back_fr1.tres")
	var leg_drag := _load_resource("res://Resources/Skills/skill_tow_leg_drag.tres")
	var back_yank := _load_resource("res://Resources/Skills/skill_tow_back_yank.tres")
	var recover_shield := _load_resource("res://Resources/Skills/skill_scrap_recover_shield.tres")
	if leg == null or back == null or leg_drag == null or back_yank == null or recover_shield == null:
		_dispose_node(mecha)
		_dispose_node(compactor)
		_dispose_node(recovery_tow)
		return
	leg.set("durability", 3)
	back.set("durability", 3)
	_set_equipped_part(SLOT_LEG, leg)
	_set_equipped_part(SLOT_BACK, back)
	mecha.call("setup")
	recovery_tow.get("next_actions").clear()
	recovery_tow.get("next_actions").append(leg_drag)
	recovery_tow.call("_publish_snipe_preview")
	_assert_true(int(recovery_tow.get("_preview_target_slot")) == SLOT_LEG, "Recovery tow LEG preview did not target LEG")
	var leg_durability_before: int = int(leg.get("durability"))
	recovery_tow.call("execute_actions", mecha, [compactor, recovery_tow])
	_assert_true(int(leg.get("durability")) == leg_durability_before - 1, "Recovery tow LEG drag did not reduce durability")

	recovery_tow.get("next_actions").clear()
	recovery_tow.get("next_actions").append(back_yank)
	recovery_tow.call("_publish_snipe_preview")
	_assert_true(int(recovery_tow.get("_preview_target_slot")) == SLOT_BACK, "Recovery tow BACK preview did not target BACK")
	var back_durability_before: int = int(back.get("durability"))
	recovery_tow.call("execute_actions", mecha, [compactor, recovery_tow])
	_assert_true(int(back.get("durability")) == back_durability_before - 1, "Recovery tow BACK yank did not reduce durability")

	var shield_ally := _new_enemy()
	root.add_child(shield_ally)
	shield_ally.set("enemy_name", "엘리트 지원 검증 적")
	shield_ally.set("enemy_max_hp", 20.0)
	shield_ally.set("enemy_max_shield", 20.0)
	shield_ally.set("current_hp", 20.0)
	shield_ally.set("current_shield", 0.0)
	recovery_tow.get("next_actions").clear()
	recovery_tow.get("next_actions").append(recover_shield)
	recovery_tow.call("execute_actions", mecha, [compactor, recovery_tow, shield_ally])
	_assert_true(float(shield_ally.get("current_shield")) > 0.0, "Recovery tow support shield did not protect an ally")

	for node in [mecha, compactor, recovery_tow, shield_ally]:
		_dispose_node(node)
	await process_frame
	print("P0 OK: Junkyard elite compactor and recovery tow")


func _check_collector_protection_and_exposure() -> void:
	_reset_run()
	var mecha := _new_mecha()
	var manager := _new_turn_manager()
	var boss := _collector_from_data()
	var player_arm := _load_part("res://Resources/Parts/arm_r/arm_r_gr21.tres")
	if boss == null or player_arm == null:
		_dispose_node(manager)
		_dispose_node(mecha)
		_dispose_node(boss)
		return
	root.add_child(mecha)
	root.add_child(manager)
	root.add_child(boss)
	_set_equipped_part(SLOT_ARM_R, player_arm)
	manager.call("start_combat_untyped", mecha, [boss])
	await process_frame
	_assert_true(manager.get("enemies").size() == 5, "Collector start should have core + 4 arms")
	_assert_true(boss.get("active_arms").size() == 4, "Collector should start with 4 arms")

	for arm: Node in boss.get("active_arms"):
		arm.set("is_defense_arm", false)
	var normal_protection: float = float(boss.call("get_core_protection_ratio"))
	_assert_true(is_equal_approx(normal_protection, 0.48), "Collector normal arm protection should be 48%")
	boss.set("current_shield", 0.0)
	var protected_hp_before: float = float(boss.get("current_hp"))
	boss.call("take_damage", 100.0)
	_assert_true(is_equal_approx(protected_hp_before - float(boss.get("current_hp")), 52.0), "Collector core damage did not apply arm protection")

	var defense_arm: Node = boss.get("active_arms")[0]
	defense_arm.set("is_defense_arm", true)
	_assert_true(is_equal_approx(float(boss.call("get_core_protection_ratio")), 0.60), "Collector defense arm protection should reach 60% cap")
	var combat_ui: Node = load("res://Scenes/UI/CombatUi.tscn").instantiate()
	root.add_child(combat_ui)
	await process_frame
	combat_ui.call("_rebuild_enemy_bars", manager.get("enemies"))
	var enemy_container: Node = combat_ui.get("enemy_container")
	_assert_true(_has_descendant_label_text(enemy_container, "전열"), "Collector UI missing front lane")
	_assert_true(_has_descendant_label_text(enemy_container, "팔"), "Collector UI missing arm lane")
	_assert_true(_has_descendant_label_text(enemy_container, "코어"), "Collector UI missing core lane")
	var target_buttons: Dictionary = combat_ui.get("_enemy_target_buttons")
	_assert_true(target_buttons.has(boss.get_instance_id()), "Collector core target button missing in formation")
	_dispose_node(combat_ui)
	await process_frame

	var arm_hp_before: float = float(boss.get("current_hp"))
	defense_arm.call("take_damage", 999.0)
	manager.call("_prune_defeated_boss_arms")
	_assert_true(is_equal_approx(arm_hp_before - float(boss.get("current_hp")), 10.0), "Collector arm break did not deal direct core HP damage")
	_assert_true(float(boss.call("get_core_protection_ratio")) < 0.60, "Collector protection did not drop after arm removal")

	boss.call("_apply_arm_theft", mecha)
	await process_frame
	var stolen_found: bool = false
	for arm: Node in boss.get("active_arms"):
		if String(arm.get("enemy_name")).begins_with("강탈된 "):
			stolen_found = true
	_assert_true(stolen_found, "Collector arm theft did not create a stolen protection arm")

	for arm: Node in boss.get("active_arms").duplicate():
		arm.call("take_damage", 999.0)
	manager.call("_prune_defeated_boss_arms")
	_assert_true(bool(boss.call("is_exposed")), "Collector did not expose core after all arms broke")
	_assert_true(boss.get("active_arms").is_empty(), "Collector recollected arms immediately after exposure")
	_assert_true(is_equal_approx(float(boss.call("get_core_protection_ratio")), 0.0), "Exposed Collector core still had arm protection")

	manager.call("start_enemy_turn")
	await process_frame
	_assert_true(boss.get("active_arms").is_empty(), "Collector recollected before the next player turn ended")
	manager.call("start_enemy_turn")
	await process_frame
	_assert_true(boss.get("active_arms").size() == 4, "Collector did not recollect after exposure window")

	boss.set("current_hp", 10.0)
	var last_arm: Node = boss.get("active_arms")[0]
	last_arm.call("take_damage", 999.0)
	manager.call("_prune_defeated_boss_arms")
	_assert_true(bool(manager.call("_check_combat_end")), "Collector core defeat from arm break did not end combat")
	_assert_true(int(manager.get("current_phase")) == 2, "Collector arm-break core defeat did not set combat end")

	var nodes_to_dispose: Array = [manager, mecha, boss]
	for enemy in manager.get("enemies"):
		if enemy not in nodes_to_dispose:
			nodes_to_dispose.append(enemy)
	for node in nodes_to_dispose:
		_dispose_node(node)
	await process_frame
	print("P0 OK: Collector protection, arm break damage, exposure, theft, and recollection")


func _check_multi_target_player_skill() -> void:
	_reset_run()
	var mecha := _new_mecha()
	root.add_child(mecha)
	var missile := (_load_resource("res://Resources/Skills/skill_missile_homing.tres") as SkillData).duplicate(true) as SkillData
	if missile == null:
		_dispose_node(mecha)
		return
	missile.skill_damage = 30.0
	missile.skill_action_cost = 1
	missile.skill_target = SkillData.SkillTarget.ENEMY
	missile.multi_target = true
	missile.hit_count = 1

	var solo := _new_combat_dummy("멀티 단일 검증")
	root.add_child(solo)
	mecha.call("use_multi_target_skill", missile, [solo])
	_assert_true(is_equal_approx(float(solo.get("current_hp")), 70.0), "Multi-target single enemy did not receive full damage")
	_dispose_node(solo)
	await process_frame

	var trio: Array[Node] = [
		_new_combat_dummy("멀티 3-1"),
		_new_combat_dummy("멀티 3-2"),
		_new_combat_dummy("멀티 3-3"),
	]
	for enemy: Node in trio:
		root.add_child(enemy)
	mecha.call("use_multi_target_skill", missile, trio)
	for enemy: Node in trio:
		_assert_true(is_equal_approx(float(enemy.get("current_hp")), 90.0), "Multi-target three enemy split was not damage/3")
		_dispose_node(enemy)
	await process_frame

	var backdoor_part := _load_part("res://Resources/Parts/arm_l/arm_l_ml7.tres")
	if backdoor_part != null:
		var backdoor_skill := (backdoor_part.get("parts_skills")[0] as SkillData).duplicate(true) as SkillData
		backdoor_skill.skill_damage = 40.0
		backdoor_skill.multi_target = true
		var backdoor_affixes: Array[String] = ["backdoor"]
		backdoor_part.set("rolled_affixes", backdoor_affixes)
		backdoor_part.set("durability", 3)
		var backdoor_skills: Array[SkillData] = [backdoor_skill]
		backdoor_part.set("parts_skills", backdoor_skills)
		_set_equipped_part(SLOT_ARM_L, backdoor_part)
		mecha.call("setup")
		var skill_map: Dictionary = {}
		skill_map[backdoor_skill] = backdoor_part
		mecha.set("_skill_to_part", skill_map)
		var debuffed := _new_combat_dummy("디버프 미사일 1")
		var normal := _new_combat_dummy("디버프 미사일 2")
		root.add_child(debuffed)
		root.add_child(normal)
		debuffed.call("_apply_debuff", SkillData.SkillDebuff.ATTACK_DOWN)
		mecha.call("use_multi_target_skill", backdoor_skill, [debuffed, normal])
		_assert_true(is_equal_approx(float(debuffed.get("current_hp")), 75.0), "Backdoor multi-target bonus did not apply to debuffed target")
		_assert_true(is_equal_approx(float(normal.get("current_hp")), 75.0), "Backdoor multi-target bonus did not apply to shared total damage")
		_dispose_node(debuffed)
		_dispose_node(normal)
		await process_frame

	_reset_run()
	var old_basic: SkillData = _game_state().get("active_basic_attack")
	var old_part_ability: SkillData = _game_state().get("active_part_ability")
	_game_state().set("active_basic_attack", missile)
	_game_state().set("active_part_ability", null)
	var manager := _new_turn_manager()
	var max_mecha := _new_mecha()
	var five_targets: Array[Node] = [
		_new_combat_dummy("최대 4-1"),
		_new_combat_dummy("최대 4-2"),
		_new_combat_dummy("최대 4-3"),
		_new_combat_dummy("최대 4-4"),
		_new_combat_dummy("최대 4-5"),
	]
	root.add_child(manager)
	root.add_child(max_mecha)
	for enemy: Node in five_targets:
		root.add_child(enemy)
	manager.call("start_combat_untyped", max_mecha, five_targets)
	manager.call("on_skill_selected", missile, null)
	for i: int in five_targets.size():
		var expected_hp: float = 92.5 if i < SkillData.MULTI_TARGET_MAX_TARGETS else 100.0
		_assert_true(is_equal_approx(float(five_targets[i].get("current_hp")), expected_hp), "Multi-target max 4 selection mismatch")
	_dispose_node(manager)
	_dispose_node(max_mecha)
	for enemy: Node in five_targets:
		_dispose_node(enemy)
	await process_frame

	_game_state().set("active_basic_attack", missile)
	_game_state().set("active_part_ability", null)
	var targetable_manager := _new_turn_manager()
	var targetable_mecha := _new_mecha()
	var valid_a := _new_combat_dummy("타겟 가능 A")
	var hidden := _new_untargetable_dummy("타겟 불가")
	var valid_b := _new_combat_dummy("타겟 가능 B")
	root.add_child(targetable_manager)
	root.add_child(targetable_mecha)
	for enemy: Node in [valid_a, hidden, valid_b]:
		root.add_child(enemy)
	targetable_manager.call("start_combat_untyped", targetable_mecha, [valid_a, hidden, valid_b])
	targetable_manager.call("on_skill_selected", missile, null)
	_assert_true(is_equal_approx(float(valid_a.get("current_hp")), 85.0), "Targetable enemy A did not receive split damage")
	_assert_true(is_equal_approx(float(hidden.get("current_hp")), 100.0), "Untargetable enemy received multi-target damage")
	_assert_true(is_equal_approx(float(valid_b.get("current_hp")), 85.0), "Targetable enemy B did not receive split damage")
	_dispose_node(targetable_manager)
	_dispose_node(targetable_mecha)
	for enemy: Node in [valid_a, hidden, valid_b]:
		_dispose_node(enemy)
	await process_frame

	var combat_ui: Node = load("res://Scenes/UI/CombatUi.tscn").instantiate()
	var ui_target := _new_combat_dummy("UI 멀티 타겟")
	root.add_child(combat_ui)
	root.add_child(ui_target)
	await process_frame
	var emitted: Array = []
	var connect_err: Error = combat_ui.connect("skill_selected", func(selected, target) -> void:
		emitted.append([selected, target])
	)
	_assert_true(connect_err == OK, "Multi-target UI signal connect failed")
	var ui_skills: Array[SkillData] = [missile]
	combat_ui.call("on_player_action_required", ui_skills, [ui_target], 1)
	combat_ui.call("_on_skill_button_pressed", missile)
	_assert_true(emitted.size() == 1, "Multi-target UI did not emit immediately")
	_assert_true(emitted[0][0] == missile and emitted[0][1] == null, "Multi-target UI emitted unexpected target")
	emitted.clear()
	var ui_hidden := _new_untargetable_dummy("UI 타겟 불가")
	root.add_child(ui_hidden)
	combat_ui.call("on_player_action_required", ui_skills, [ui_hidden], 1)
	combat_ui.call("_on_skill_button_pressed", missile)
	_assert_true(emitted.is_empty(), "Multi-target UI emitted with no targetable enemies")
	_dispose_node(combat_ui)
	_dispose_node(ui_target)
	_dispose_node(ui_hidden)
	_dispose_node(mecha)
	_game_state().set("active_basic_attack", old_basic)
	_game_state().set("active_part_ability", old_part_ability)
	await process_frame
	print("P0 OK: player multi-target damage split, targetability, and UI immediate emit")
