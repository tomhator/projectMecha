extends Control

const CARD_SIZE := Vector2(168.0, 120.0)

@onready var title_label: Label = $MarginRoot/VBox/TitleLabel
@onready var reward_container: HBoxContainer = $MarginRoot/VBox/RewardContainer

var _popup: ConfirmationDialog
var _pending_part: PartsData = null


func _ready() -> void:
	_build_popup()
	var room: RoomData = DungeonManager.get_current_room()
	var grade: PartsData.PartsGrade = _determine_grade(room)
	var credit_amount: int = _determine_credits(room)

	title_label.text = "부품 획득 — %s 등급  |  크레딧 +%d" % [
		PartsData.PartsGrade.keys()[grade], credit_amount
	]
	GameState.add_credits(credit_amount)

	var choices: Array[PartsData] = RewardManager.generate_choices(grade)
	for part: PartsData in choices:
		var btn: Button = Button.new()
		btn.text = _short_card_title(part)
		btn.custom_minimum_size = CARD_SIZE
		btn.pressed.connect(_on_reward_card_pressed.bind(part))
		reward_container.add_child(btn)


func _build_popup() -> void:
	_popup = ConfirmationDialog.new()
	_popup.title = "보상 확인"
	_popup.ok_button_text = "가져가기"
	_popup.cancel_button_text = "닫기"
	add_child(_popup)
	_popup.confirmed.connect(_on_take_reward)
	_popup.ready.connect(_connect_cancel_button)


func _connect_cancel_button() -> void:
	var cb: Button = _popup.get_cancel_button()
	if cb != null and not cb.pressed.is_connected(_on_popup_close):
		cb.pressed.connect(_on_popup_close)


func _short_card_title(part: PartsData) -> String:
	return "[%s]\n%s" % [
		PartsData.PartsType.keys()[part.parts_type],
		part.parts_name
	]


func _on_reward_card_pressed(part: PartsData) -> void:
	_pending_part = part
	_popup.dialog_text = "%s\n\n%s" % [part.parts_name, part.parts_description]
	_popup.popup_centered()


func _on_popup_close() -> void:
	_pending_part = null


func _on_take_reward() -> void:
	if _pending_part == null:
		return
	GameState.add_to_inventory(_pending_part)
	_pending_part = null
	_popup.hide()
	_set_buttons_disabled(true)
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


func _determine_credits(room: RoomData) -> int:
	if room == null:
		return 0
	match room.room_type:
		RoomData.RoomType.BATTLE_NORMAL: return randi_range(20, 40)
		RoomData.RoomType.BATTLE_ELITE: return randi_range(50, 80)
		RoomData.RoomType.BOSS: return randi_range(80, 100)
		_: return 0
