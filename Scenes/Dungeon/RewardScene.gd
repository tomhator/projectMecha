extends Control

@onready var title_label: Label = $TitleLabel
@onready var reward_container: HBoxContainer = $RewardContainer

func _ready() -> void:
	var room: RoomData = DungeonManager.get_current_room()
	var grade: PartsData.PartsGrade = _determine_grade(room)
	title_label.text = "부품 획득 - %s 등급" % PartsData.PartsGrade.keys()[grade]

	var choices: Array[PartsData] =  RewardManager.generate_choices(grade)
	for part: PartsData in choices:
		var btn: Button = Button.new()
		btn.text = "[%s] %s\n%s" % [
			PartsData.PartsType.keys()[part.parts_type],
			part.parts_name,
			part.parts_description,
		]
		btn.custom_minimum_size = Vector2(180, 100)
		btn.pressed.connect(_on_part_selected.bind(part))
		reward_container.add_child(btn)

func _on_part_selected(part: PartsData) -> void:
	_set_buttons_disabled(true)
	GameState.add_to_inventory(part)
	DungeonManager.continue_after_reward()

func _set_buttons_disabled(disabled: bool) -> void:
	for child: Node in reward_container.get_children():
		if child is Button:
			(child as Button).disabled = disabled

func _determine_grade(room: RoomData) -> PartsData.PartsGrade:
	if room == null:
		return PartsData.PartsGrade.COMMON
	match room.room_type:
		RoomData.RoomType.BATTLE_ELITE: return PartsData.PartsGrade.RARE
		RoomData.RoomType.BOSS: return PartsData.PartsGrade.EPIC
		RoomData.RoomType.CHEST:
			return PartsData.PartsGrade.EPIC if randf() < 0.25 else PartsData.PartsGrade.RARE
		_: return PartsData.PartsGrade.COMMON
