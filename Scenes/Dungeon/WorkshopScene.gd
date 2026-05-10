extends Control

@onready var credits_label: Label = $CreditsLabel
@onready var exit_button: Button = $ExitButton
@onready var hp_label: Label = $HPLabel
@onready var shield_label: Label = $ShieldLabel

const SERVICES: Array[Dictionary] = [
	{ "label": "HP 50 회복",	 "cost": 30,  "type": "heal_hp",	 "amount": 50.0  },
	{ "label": "쉴드 완전 회복", "cost": 40,  "type": "heal_shield", "amount": -1.0  },
	{ "label": "HP 완전 회복",   "cost": 80,  "type": "heal_hp",	 "amount": -1.0  },
]

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	EventBus.credits_changed.connect(_update_credits_label)
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.shield_changed.connect(_on_shield_changed)
	_update_credits_label(GameState.credits)
	_update_hp_shield()
	_build_services()

func _build_services() -> void:
	var container: VBoxContainer = $ServiceContainer
	for service: Dictionary in SERVICES:
		var btn: Button = Button.new()
		btn.text = "%s  -  %d 크레딧" % [service["label"], service["cost"]]
		btn.pressed.connect(_on_service_pressed.bind(service))
		container.add_child(btn)

func _on_service_pressed(service: Dictionary) -> void:
	if not GameState.spend_credits(service["cost"]):
		return
	match service["type"]:
		"heal_hp":
			var amount: float = service["amount"]
			if amount < 0:  # -1 = 완전 회복
				amount = GameState.current_core.core_hp
			GameState.heal_hp(amount)
		"heal_shield":
			var amount: float = service["amount"]
			if amount < 0:
				amount = GameState.current_core.core_shield
			GameState.heal_shield(amount)

func _update_credits_label(new_credits: int) -> void:
	credits_label.text = "크레딧: %d" % new_credits

func _on_exit_pressed() -> void:
	DungeonManager.on_room_cleared()

func _update_hp_shield() -> void:
	hp_label.text = "HP: %.0f / %.0f" % [GameState.current_hp, GameState.current_core.core_hp]
	shield_label.text = "쉴드: %.0f / %.0f" % [GameState.current_shield, GameState.current_core.core_shield]

func _on_hp_changed(_entity: Node, _new_hp: float, _max_hp: float) -> void:
	_update_hp_shield()

func _on_shield_changed(_entity: Node, _new_shield: float, _max_shield: float) -> void:
	_update_hp_shield()
