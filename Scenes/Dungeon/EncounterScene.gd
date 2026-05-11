extends Control

const EVENTS: Array[Dictionary] = [
	{
		"text": "폐허에서 고철 무더기를 발견했다.\n뒤지면 쓸만한 부품이 나올 수도 있지만,\n불안정한 구조물이다.",
		"result": "A"
	},
	{
		"text": "손상된 메카 잔해가 있다.\n부품을 회수할 수 있지만,\n무리하게 뜯다가 손상될 수 있다.",
		"result": "B"
	},
	{
		"text": "정체불명의 에너지 잔재물을 발견했다.\n흡수를 시도했지만 결과가 좋지 않다.",
		"result": "C"
	},
	{
		"text": "전장의 의료 드론을 발견했다.\n수리를 받을 수 있지만,\n일부 무장을 반납해야 한다.",
		"result": "D"
	},
	{
		"text": "불법 개조 시설을 발견했다.\n성능을 올릴 수 있지만,\n코어에 부담이 간다.",
		"result": "E"
	},
]

@onready var left_image: TextureRect = $MarginRoot/MainHBox/LeftImage
@onready var event_label: Label = %EventLabel
@onready var choices_row: HBoxContainer = %ChoicesRow
@onready var result_block: VBoxContainer = %ResultBlock
@onready var result_label: Label = %ResultLabel
@onready var continue_button: Button = %ContinueButton

var _current_event: Dictionary = {}
var _action_button: Button
var _skip_button: Button


func _ready() -> void:
	var img: Image = Image.create(320, 360, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.2, 0.26, 1.0))
	left_image.texture = ImageTexture.create_from_image(img)

	_current_event = EVENTS[randi() % EVENTS.size()]
	event_label.text = _current_event["text"]
	result_block.visible = false

	_action_button = Button.new()
	_action_button.text = "진행한다"
	_action_button.pressed.connect(_on_action_pressed)
	choices_row.add_child(_action_button)

	_skip_button = Button.new()
	_skip_button.text = "지나간다"
	_skip_button.pressed.connect(_on_skip_pressed)
	choices_row.add_child(_skip_button)

	continue_button.pressed.connect(func() -> void: DungeonManager.on_room_cleared())


func _on_action_pressed() -> void:
	_action_button.disabled = true
	_skip_button.disabled = true
	_apply_result(_current_event["result"] as String)
	event_label.visible = false
	choices_row.visible = false
	result_block.visible = true


func _on_skip_pressed() -> void:
	DungeonManager.on_room_cleared()


func _apply_result(result: String) -> void:
	var max_hp: float = GameState.current_core.core_hp
	match result:
		"A":
			var part: PartsData = RewardManager.generate_choices(PartsData.PartsGrade.COMMON)[0]
			GameState.add_to_inventory(part)
			GameState.take_damage(max_hp * 0.1)
			result_label.text = "부품 [%s]을 획득했지만, 코어가 손상됐다. (HP -10%%)" % part.parts_name
		"B":
			var part2: PartsData = RewardManager.generate_choices(PartsData.PartsGrade.COMMON)[0]
			part2.is_damaged = true
			GameState.add_to_inventory(part2)
			result_label.text = "손상된 부품 [%s]을 회수했다. 스킬 위력 -30%%" % part2.parts_name
		"C":
			GameState.take_damage(max_hp * 0.15)
			result_label.text = "아무것도 얻지 못하고 코어가 손상됐다. (HP -15%)"
		"D":
			GameState.heal_hp(max_hp * 0.2)
			GameState.attack_multiplier = maxf(0.5, GameState.attack_multiplier - 0.2)
			result_label.text = "코어를 수리했지만, 공격력이 저하됐다. (HP +20%, 공격력 -20%)"
		"E":
			GameState.take_damage(max_hp * 0.2)
			GameState.attack_multiplier = minf(2.0, GameState.attack_multiplier + 0.3)
			result_label.text = "성능이 강화됐지만, 코어에 부담이 생겼다. (HP -20%, 공격력 +30%)"
		_:
			result_label.text = "결과 없음"
