extends Control
class_name RunStatusStrip

const STRIP_HEIGHT: int = 56
const INNER_PAD_H: int = 12
const INNER_PAD_V: int = 8

@onready var _floor_label: Label = %FloorLabel
@onready var _hp_bar: ProgressBar = %HPBar
@onready var _hp_value: Label = %HPValue
@onready var _shield_bar: ProgressBar = %ShieldBar
@onready var _shield_value: Label = %ShieldValue
@onready var _credits_label: Label = %CreditsLabel
@onready var _settings_button: Button = %SettingsButton
@onready var _settings_dialog: AcceptDialog = %SettingsDialog


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, float(STRIP_HEIGHT))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_settings_button.pressed.connect(_on_settings_pressed)
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.floor_changed.connect(_on_floor_changed)
	_refresh_all()


func _exit_tree() -> void:
	if EventBus.hp_changed.is_connected(_on_hp_changed):
		EventBus.hp_changed.disconnect(_on_hp_changed)
	if EventBus.shield_changed.is_connected(_on_shield_changed):
		EventBus.shield_changed.disconnect(_on_shield_changed)
	if EventBus.credits_changed.is_connected(_on_credits_changed):
		EventBus.credits_changed.disconnect(_on_credits_changed)
	if EventBus.floor_changed.is_connected(_on_floor_changed):
		EventBus.floor_changed.disconnect(_on_floor_changed)


func _on_settings_pressed() -> void:
	_settings_dialog.popup_centered()


func _on_floor_changed(_f: int) -> void:
	_refresh_floor()


func _on_credits_changed(amount: int) -> void:
	_credits_label.text = "크레딧: %d" % amount


func _on_hp_changed(entity: Node, new_hp: float, max_hp: float) -> void:
	if entity is EnemyEntity:
		return
	_hp_bar.max_value = maxf(max_hp, 1.0)
	_hp_bar.value = new_hp
	_hp_value.text = "%.0f / %.0f" % [new_hp, max_hp]


func _on_shield_changed(entity: Node, new_shield: float, max_shield: float) -> void:
	if entity is EnemyEntity:
		return
	_shield_bar.max_value = maxf(max_shield, 1.0)
	_shield_bar.value = new_shield
	_shield_value.text = "%.0f / %.0f" % [new_shield, max_shield]


func _refresh_floor() -> void:
	if not GameState.is_run_active:
		_floor_label.text = "층: —"
	else:
		_floor_label.text = "층: %d" % GameState.current_floor


func _refresh_all() -> void:
	_refresh_floor()
	_on_credits_changed(GameState.credits)
	if GameState.current_core != null:
		_hp_bar.max_value = GameState.current_core.core_hp
		_hp_bar.value = GameState.current_hp
		_shield_bar.max_value = GameState.current_core.core_shield
		_shield_bar.value = GameState.current_shield
		_hp_value.text = "%.0f / %.0f" % [GameState.current_hp, GameState.current_core.core_hp]
		_shield_value.text = "%.0f / %.0f" % [GameState.current_shield, GameState.current_core.core_shield]
	else:
		_hp_bar.max_value = 1.0
		_hp_bar.value = 0.0
		_shield_bar.max_value = 1.0
		_shield_bar.value = 0.0
		_hp_value.text = "—"
		_shield_value.text = "—"
