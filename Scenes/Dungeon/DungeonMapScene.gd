extends Control

@onready var floor_label: Label = $FloorLabel
@onready var hp_label: Label = $HPLabel
@onready var choice_container: HBoxContainer = $ChoiceContainer
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	_update_status()
	_rebuild_choice()

func _update_status() -> void:
	floor_label.text = "%d층 / 10" % GameState.current_floor
	hp_label.text = "HP: %.0f / %.0f" % [GameState.current_hp, GameState.current_core.core_hp]

func _rebuild_choice() -> void:
	for child: Node in choice_container.get_children():
		child.queue_free()
	
	var choices: Array = DungeonManager.get_current_choices()
	for room: RoomData in choices:
		var btn: Button = Button.new()
		btn.text = _room_type_label(room.room_type) + "\n" + room.hint
		btn.custom_minimum_size = Vector2(160, 80)
		btn.pressed.connect(_on_room_selected.bind(room))

		# 호버 시 힌트 표시
		btn.mouse_entered.connect(func() -> void: hint_label.text = room.hint)
		btn.mouse_exited.connect(func() -> void: hint_label.text = "")
		choice_container.add_child(btn)

func _on_room_selected(room: RoomData) -> void:
	# 중복 클릭 방지
	for child: Node in choice_container.get_children():
		if child is Button:
			(child as Button).disabled = true
	DungeonManager.select_room(room)

func _room_type_label(room_type: RoomData.RoomType) -> String:
	match room_type:
		RoomData.RoomType.BATTLE_NORMAL:  return "일반 전투"
		RoomData.RoomType.BATTLE_ELITE:   return "엘리트 전투"
		RoomData.RoomType.CHEST:          return "상자"
		RoomData.RoomType.ENCOUNTER:      return "조우 이벤트"
		RoomData.RoomType.WORKSHOP:       return "작업대"
		RoomData.RoomType.BOSS:           return "보스"
		_:                                return "?"
