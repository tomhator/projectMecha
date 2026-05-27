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
	var scrap_amount: int = _determine_scrap(room)

	title_label.text = "부품 획득 — %s 등급  |  크레딧 +%d  |  고철 +%d" % [
		PartsData.PartsGrade.keys()[grade], credit_amount, scrap_amount
	]
	GameState.add_credits(credit_amount)
	GameState.add_scrap(scrap_amount)

	if _is_combat_room(room):
		_show_combat_rewards(grade, credit_amount, scrap_amount)
		return

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


func _show_combat_rewards(grade: PartsData.PartsGrade, credit_amount: int, scrap_amount: int) -> void:
	var defeated_count: int = DungeonManager.get_last_combat_defeated_enemy_count()
	var drops: Array[PartsData] = RewardManager.generate_combat_drops(grade, defeated_count)
	var acquired_count: int = 0
	var lost_count: int = 0
	title_label.text = "전투 보상 — 격파 %d기  |  드롭 %d개  |  크레딧 +%d  |  고철 +%d" % [
		defeated_count,
		drops.size(),
		credit_amount,
		scrap_amount
	]
	for part: PartsData in drops:
		var acquired: bool = GameState.add_to_inventory(part)
		if acquired:
			acquired_count += 1
		else:
			lost_count += 1
		var btn: Button = Button.new()
		btn.text = "%s\n%s" % [_short_card_title(part), "획득" if acquired else "유실"]
		btn.custom_minimum_size = CARD_SIZE
		btn.disabled = true
		reward_container.add_child(btn)
	if lost_count > 0:
		title_label.text = "전투 보상 — 격파 %d기  |  획득 %d개  |  유실 %d개  |  크레딧 +%d  |  고철 +%d" % [
			defeated_count,
			acquired_count,
			lost_count,
			credit_amount,
			scrap_amount
		]
	if drops.is_empty():
		var label := Label.new()
		label.text = "드롭 파츠 없음"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_container.add_child(label)
	var continue_btn := Button.new()
	continue_btn.text = "계속"
	continue_btn.custom_minimum_size = Vector2(120.0, 44.0)
	continue_btn.pressed.connect(DungeonManager.continue_after_reward)
	reward_container.add_child(continue_btn)


func _on_reward_card_pressed(part: PartsData) -> void:
	_pending_part = part
	_popup.dialog_text = "%s\n\n%s" % [part.parts_name, part.parts_description]
	_popup.popup_centered()


func _on_popup_close() -> void:
	_pending_part = null


func _on_take_reward() -> void:
	if _pending_part == null:
		return
	var acquired: bool = GameState.add_to_inventory(_pending_part)
	if not acquired:
		title_label.text = "인벤토리가 가득 차서 보상을 획득하지 못했습니다."
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


func _is_combat_room(room: RoomData) -> bool:
	if room == null:
		return false
	match room.room_type:
		RoomData.RoomType.BATTLE_NORMAL, \
		RoomData.RoomType.BATTLE_ELITE, \
		RoomData.RoomType.BOSS:
			return true
		_:
			return false


func _determine_credits(room: RoomData) -> int:
	if room == null:
		return 0
	match room.room_type:
		RoomData.RoomType.BATTLE_NORMAL: return randi_range(20, 40)
		RoomData.RoomType.BATTLE_ELITE: return randi_range(50, 80)
		RoomData.RoomType.BOSS: return randi_range(80, 100)
		_: return 0


func _determine_scrap(room: RoomData) -> int:
	if room == null:
		return 0
	match room.room_type:
		RoomData.RoomType.BATTLE_NORMAL: return randi_range(3, 6)
		RoomData.RoomType.BATTLE_ELITE: return randi_range(8, 14)
		RoomData.RoomType.BOSS: return randi_range(20, 30)
		_: return 0
