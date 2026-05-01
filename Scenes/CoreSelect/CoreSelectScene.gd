extends Control

const CORE_VANGUARD_PATH := "res://Resources/Cores/Core_Vanguard.tres"
const CORE_STRIKER_PATH := "res://Resources/Cores/Core_Striker.tres"
const CORE_BULWARK_PATH := "res://Resources/Cores/Core_Bulwark.tres"

@onready var vanguard_button: Button = $CoreContainer/VanguardPanel/VanguardButton
@onready var striker_button: Button = $CoreContainer/StrikerPanel/StrikerButton
@onready var bulwark_button: Button = $CoreContainer/BulwarkPanel/BulwarkButton
@onready var selected_label: Label = $SelectedLabel

func _ready() -> void:
	vanguard_button.pressed.connect(_on_core_selected.bind(CORE_VANGUARD_PATH))
	striker_button.pressed.connect(_on_core_selected.bind(CORE_STRIKER_PATH))
	bulwark_button.pressed.connect(_on_core_selected.bind(CORE_BULWARK_PATH))

	vanguard_button.text = "범용 코어\nVanguard"
	striker_button.text = "경량 코어\nStriker"
	bulwark_button.text = "방어 코어\nBulwark"

	$CoreContainer/VanguardPanel/VanguardDesc.text = "평균적인 스탯\n제약 없음"
	$CoreContainer/StrikerPanel/StrikerDesc.text = "공격력 x0.6 / 매 턴 스킬 2회 선택 / 하중 제한↓"
	$CoreContainer/BulwarkPanel/BulwarkDesc.text = "체력↑↑ / 공격력↓ / 공격횟수↓"

func _on_core_selected(core_path: String) -> void:
	var core: CoreData = load(core_path)
	if core == null:
		push_error("코어 데이터를 찾을 수 없습니다: " + core_path)
		return
	GameState.start_run(core)
	DungeonManager.start_dungeon()
