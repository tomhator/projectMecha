extends Control

const ASSEMBLY_SCENE: String = "res://Scenes/Assembly/AssemblyScene.tscn"

@onready var choice_container: HBoxContainer = %ChoiceContainer
@onready var assembly_button: Button = %AssemblyButton
@onready var _room_info_body: RichTextLabel = %RoomInfoBody
@onready var _room_enter_button: Button = %RoomEnterButton

var _selected_room: RoomData = null


func _ready() -> void:
	assembly_button.pressed.connect(_on_assembly_pressed)
	_room_enter_button.pressed.connect(_on_enter_pressed)
	_clear_room_panel()
	_rebuild_choice()


func _clear_room_panel() -> void:
	_selected_room = null
	_room_info_body.text = "방 타일을 클릭하면 이곳에 설명이 표시됩니다."
	_room_enter_button.disabled = true


func _on_enter_pressed() -> void:
	if _selected_room == null:
		return
	for child: Node in choice_container.get_children():
		if child is Button:
			(child as Button).disabled = true
	DungeonManager.select_room(_selected_room)


func _rebuild_choice() -> void:
	for child: Node in choice_container.get_children():
		child.queue_free()
	_clear_room_panel()

	var choices: Array = DungeonManager.get_current_choices()
	const TILE: float = 80.0
	for room: RoomData in choices:
		var btn: Button = Button.new()
		btn.text = _room_icon_caption(room.room_type)
		btn.custom_minimum_size = Vector2(TILE, TILE)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.clip_contents = true
		btn.pressed.connect(_on_room_tile_pressed.bind(room))
		choice_container.add_child(btn)


func _room_icon_caption(room_type: RoomData.RoomType) -> String:
	match room_type:
		RoomData.RoomType.BATTLE_NORMAL: return "⚔\n일반"
		RoomData.RoomType.BATTLE_ELITE: return "⚔\n엘리트"
		RoomData.RoomType.CHEST: return "■\n상자"
		RoomData.RoomType.ENCOUNTER: return "?\n조우"
		RoomData.RoomType.WORKSHOP: return "◇\n작업대"
		RoomData.RoomType.BOSS: return "☠\n보스"
		_: return "?"


func _on_room_tile_pressed(room: RoomData) -> void:
	_selected_room = room
	var title: String = _room_type_label(room.room_type)
	var body: String = "[b]%s[/b]\n\n%s" % [title, room.hint]
	_room_info_body.text = body
	_room_enter_button.disabled = false


func _room_type_label(room_type: RoomData.RoomType) -> String:
	match room_type:
		RoomData.RoomType.BATTLE_NORMAL: return "일반 전투"
		RoomData.RoomType.BATTLE_ELITE: return "엘리트 전투"
		RoomData.RoomType.CHEST: return "상자"
		RoomData.RoomType.ENCOUNTER: return "조우 이벤트"
		RoomData.RoomType.WORKSHOP: return "작업대"
		RoomData.RoomType.BOSS: return "보스"
		_: return "?"


func _on_assembly_pressed() -> void:
	get_tree().change_scene_to_file(ASSEMBLY_SCENE)
