# 던전 진행 상태를 관리하는 Autoload. 
extends Node

const DUNGEON_MAP_SCENE: String = "res://Scenes/Dungeon/DungeonMapScene.tscn"
const COMBAT_SCENE: String = "res://Scenes/Combat/CombatScene.tscn"
const CHEST_SCENE: String = "res://Scenes/Dungeon/ChestScene.tscn"
const ENCOUNTER_SCENE: String = "res://Scenes/Dungeon/EncounterScene.tscn"
const WORKSHOP_SCENE: String = "res://Scenes/Dungeon/WorkshopScene.tscn"
const RUN_END_SCENE: String = "res://Scenes/Dungeon/RunEndScene.tscn"

var _floors: Array = [] # 10층 * 각 층의 선택지 목록
var _current_choice: RoomData = null #현재 층에서 플레이어가 선택한 방

func start_dungeon() -> void:
    _floors.clear()
    _generate_floors()
    get_tree().change_scene_to_file(DUNGEON_MAP_SCENE)

func get_current_choices() -> Array:
    var floor_idx: int = GameState.current_floor - 1
    if floor_idx < 0 or floor_idx >= _floors.size():
        return []
    return _floors[floor_idx]

func select_room(room: RoomData) -> void:
    _current_choice = room
    _transition_to_room(room)

func on_room_cleared() -> void:
    GameState.advance_floor()
    if GameState.current_floor > 10:
        get_tree().change_scene_to_file(RUN_END_SCENE)
        return
    else:
        get_tree().change_scene_to_file(DUNGEON_MAP_SCENE)

func get_current_room() -> RoomData:
    return _current_choice

# ----------------------------------

func _generate_floors() -> void:
    for floor_num: int in range(1, 11):
        var choices: Array[RoomData] = []
        match floor_num:
            1, 2, 3:
                choices.append(_make_room(RoomData.RoomType.BATTLE_NORMAL))
                choices.append(_make_room(RoomData.RoomType.BATTLE_NORMAL))
            4, 5:
                var pool: Array = [
                    RoomData.RoomType.BATTLE_NORMAL,
                    RoomData.RoomType.CHEST,
                    RoomData.RoomType.ENCOUNTER,
                    RoomData.RoomType.WORKSHOP
                ]
                pool.shuffle()
                choices.append(_make_room(pool[0]))
                choices.append(_make_room(pool[1]))
            6, 7, 8:
                var types: Array = [
                    RoomData.RoomType.BATTLE_NORMAL,
                    RoomData.RoomType.BATTLE_ELITE
                ]
                types.shuffle()
                choices.append(_make_room(types[0]))
                choices.append(_make_room(types[1]))
            9:
                choices.append(_make_room(RoomData.RoomType.BATTLE_ELITE))
            10:
                choices.append(_make_room(RoomData.RoomType.BOSS))
        _floors.append(choices)

func _make_room(room_type: RoomData.RoomType) -> RoomData:
    var room: RoomData = RoomData.new()
    room.room_type = room_type
    room.hint = _make_hint(room_type)
    return room

func _make_hint(room_type: RoomData.RoomType) -> String:
    match room_type:
        _: return "알 수 없는 방"
        RoomData.RoomType.BATTLE_NORMAL:
            return "일반 전투 - 일반 부품 보상"
        RoomData.RoomType.BATTLE_ELITE:
            return "엘리트 전투 - 희귀/에픽 부품 보상"
        RoomData.RoomType.CHEST:
            return "상자 - 에픽 25% / 희귀 75%"
        RoomData.RoomType.ENCOUNTER:
            return "조우 이벤트 - 보상 + 리스크"
        RoomData.RoomType.WORKSHOP:
            return "작업대 - 크레딧 소모 서비스"
        RoomData.RoomType.BOSS:
            return "보스 전투"

func _transition_to_room(room: RoomData) -> void:
    match room.room_type:
        RoomData.RoomType.BATTLE_NORMAL, RoomData.RoomType.BATTLE_ELITE, RoomData.RoomType.BOSS:
            get_tree().change_scene_to_file(COMBAT_SCENE)
        RoomData.RoomType.CHEST:
            get_tree().change_scene_to_file(CHEST_SCENE)
        RoomData.RoomType.ENCOUNTER:
            get_tree().change_scene_to_file(ENCOUNTER_SCENE)
        RoomData.RoomType.WORKSHOP:
            get_tree().change_scene_to_file(WORKSHOP_SCENE)