extends SceneTree

const SCENE_PATHS: Array[String] = [
	"res://Scenes/Base/HubScene.tscn",
	"res://Scenes/Base/HangarScene.tscn",
	"res://Scenes/CoreSelect/CoreSelectScene.tscn",
	"res://Scenes/Dungeon/DungeonMapScene.tscn",
	"res://Scenes/Assembly/AssemblyScene.tscn",
	"res://Scenes/Dungeon/RewardScene.tscn",
	"res://Scenes/Dungeon/ChestScene.tscn",
	"res://Scenes/Dungeon/EncounterScene.tscn",
	"res://Scenes/Dungeon/WorkshopScene.tscn",
	"res://Scenes/Dungeon/RunEndScene.tscn",
	"res://Scenes/Combat/CombatScene.tscn",
]
const RUN_END_SCENE_PATH: String = "res://Scenes/Dungeon/RunEndScene.tscn"

var _failed: bool = false


func _initialize() -> void:
	_prepare_run_state()
	for path: String in SCENE_PATHS:
		await _smoke_scene(path)
	if _failed:
		print("Scene smoke: FAIL")
		quit(1)
	else:
		print("Scene smoke: PASS")
		quit(0)


func _prepare_run_state(path: String = "") -> void:
	var game_state := root.get_node_or_null("GameState")
	var dungeon_manager := root.get_node_or_null("DungeonManager")
	if game_state == null:
		_fail("Missing GameState autoload")
		return
	if dungeon_manager == null:
		_fail("Missing DungeonManager autoload")
		return

	game_state.call("start_run")
	if path == RUN_END_SCENE_PATH:
		game_state.set("is_run_active", false)
		game_state.set("current_floor", 11)
		game_state.set("last_run_summary", {
			"success": true,
			"reached_floor": 11,
			"run_credits": 0,
			"recovered_credits": 0,
			"run_scrap": 0,
			"recovered_scrap": 0,
			"recovered_part_count": 0,
			"lost_part_count": 0,
			"recovered_part_names": [],
			"lost_part_names": [],
		})
	var room := RoomData.new()
	room.room_type = RoomData.RoomType.BATTLE_NORMAL
	room.hint = "validation smoke room"
	dungeon_manager.set("_current_choice", room)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)


func _smoke_scene(path: String) -> void:
	_prepare_run_state(path)
	var packed := load(path) as PackedScene
	if packed == null:
		_fail("Scene load failed: %s" % path)
		return

	var instance := packed.instantiate()
	if instance == null:
		_fail("Scene instantiate failed: %s" % path)
		return

	root.add_child(instance)
	await process_frame
	instance.queue_free()
	await process_frame
	print("Scene smoke OK: %s" % path)
