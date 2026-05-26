extends SceneTree

var _failed: bool = false
var _seen_skill_ids: Dictionary = {}
var _seen_parts_ids: Dictionary = {}
var _seen_enemy_ids: Dictionary = {}
var _ability_node_ids: Dictionary = {}
var _ability_tier_counts: Dictionary = {}
var _allowed_ability_visual_slots: Dictionary = {
	"sensor_mast": true,
	"cockpit_shell": true,
	"shoulder_frame": true,
	"rear_pack": true,
	"front_plating": true,
}


func _initialize() -> void:
	_check_skills()
	_check_parts()
	_check_enemies()
	_check_ability_tree()
	if _failed:
		print("Resource integrity: FAIL")
		quit(1)
	else:
		print("Resource integrity: PASS")
		quit(0)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)


func _resource_paths(root_path: String, recursive: bool = true) -> Array[String]:
	var out: Array[String] = []
	_collect_resource_paths(root_path, recursive, out)
	out.sort()
	return out


func _collect_resource_paths(root_path: String, recursive: bool, out: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		_fail("Missing resource directory: %s" % root_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if recursive and not file_name.begins_with("."):
				_collect_resource_paths("%s/%s" % [root_path, file_name], recursive, out)
		elif file_name.ends_with(".tres"):
			out.append("%s/%s" % [root_path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()


func _check_duplicate_id(bucket: Dictionary, kind: String, id_value: int, path: String) -> void:
	if id_value <= 0:
		_fail("%s has invalid id %d: %s" % [kind, id_value, path])
		return
	if bucket.has(id_value):
		_fail("%s id duplicated (%d): %s and %s" % [kind, id_value, bucket[id_value], path])
		return
	bucket[id_value] = path


func _check_skills() -> void:
	for path: String in _resource_paths("res://Resources/Skills", false):
		var skill := load(path) as SkillData
		if skill == null:
			_fail("Skill load/type failed: %s" % path)
			continue
		_check_duplicate_id(_seen_skill_ids, "Skill", skill.skill_id, path)
		if skill.skill_name.strip_edges().is_empty():
			_fail("Skill has empty name: %s" % path)
		if skill.skill_action_cost < 0:
			_fail("Skill has negative action cost: %s" % path)
		if skill.skill_damage < 0.0 or skill.skill_defense < 0.0 or skill.skill_heal < 0.0:
			_fail("Skill has negative value: %s" % path)


func _check_parts() -> void:
	for path: String in _resource_paths("res://Resources/Parts", true):
		var part := load(path) as PartsData
		if part == null:
			_fail("Part load/type failed: %s" % path)
			continue
		_check_duplicate_id(_seen_parts_ids, "Part", part.parts_id, path)
		if part.parts_name.strip_edges().is_empty():
			_fail("Part has empty name: %s" % path)
		if part.parts_weight < 0.0:
			_fail("Part has negative weight: %s" % path)
		if part.drop_weight < 0.0:
			_fail("Part has negative drop weight: %s" % path)
		if part.max_durability < 1:
			_fail("Part has invalid max durability: %s" % path)
		if part.durability < 0 or part.durability > part.max_durability:
			_fail("Part durability out of range: %s" % path)
		if part.parts_skills.is_empty():
			_fail("Part has no skills: %s" % path)
		for skill: SkillData in part.parts_skills:
			if skill == null:
				_fail("Part references null skill: %s" % path)


func _check_enemies() -> void:
	for path: String in _resource_paths("res://Resources/Enemies", false):
		var enemy := load(path) as EnemyData
		if enemy == null:
			_fail("Enemy load/type failed: %s" % path)
			continue
		_check_duplicate_id(_seen_enemy_ids, "Enemy", enemy.enemy_id, path)
		if enemy.enemy_name.strip_edges().is_empty():
			_fail("Enemy has empty name: %s" % path)
		if enemy.enemy_max_hp <= 0.0:
			_fail("Enemy has non-positive max HP: %s" % path)
		if enemy.enemy_max_shield < 0.0:
			_fail("Enemy has negative max shield: %s" % path)
		if enemy.enemy_action_count <= 0:
			_fail("Enemy has non-positive action count: %s" % path)
		if enemy.skills.is_empty():
			_fail("Enemy has no skills: %s" % path)
		for skill: SkillData in enemy.skills:
			if skill == null:
				_fail("Enemy references null skill: %s" % path)


func _check_ability_tree() -> void:
	for path: String in _resource_paths("res://Resources/AbilityTree", false):
		var node := load(path) as AbilityTreeNode
		if node == null:
			_fail("Ability node load/type failed: %s" % path)
			continue
		if node.node_id.strip_edges().is_empty():
			_fail("Ability node has empty node_id: %s" % path)
			continue
		if _ability_node_ids.has(node.node_id):
			_fail("Ability node_id duplicated (%s): %s and %s" % [node.node_id, _ability_node_ids[node.node_id], path])
		_ability_node_ids[node.node_id] = path
		if node.tier < 1 or node.tier > 5:
			_fail("Ability node tier out of range: %s" % path)
		if node.research_cost <= 0 or node.level_cost_step < 0:
			_fail("Ability node has invalid research cost: %s" % path)
		if node.visual_slot.strip_edges().is_empty() or node.visual_variant.strip_edges().is_empty():
			_fail("Ability node missing visual metadata: %s" % path)
		if not _allowed_ability_visual_slots.has(node.visual_slot):
			_fail("Ability node has unknown visual slot '%s': %s" % [node.visual_slot, path])
		if node.level_five_bonus_text.strip_edges().is_empty():
			_fail("Ability node missing level five bonus text: %s" % path)
		if node.level_five_bonus_text.contains("예정"):
			_fail("Ability node still has placeholder level five bonus text: %s" % path)
		_ability_tier_counts[node.tier] = int(_ability_tier_counts.get(node.tier, 0)) + 1

	for tier: int in range(1, 6):
		if int(_ability_tier_counts.get(tier, 0)) != 3:
			_fail("Ability tier %d must contain 3 nodes" % tier)
