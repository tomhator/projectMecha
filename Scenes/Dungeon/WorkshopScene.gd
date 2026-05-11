extends Control

@onready var exit_button: Button = $MarginRoot/VBox/ExitButton
@onready var upgrade_panel: VBoxContainer = $MarginRoot/VBox/UpgradePanel
@onready var upgrade_part_container: VBoxContainer = $MarginRoot/VBox/UpgradePanel/UpgradePartContainer

const SERVICES: Array[Dictionary] = [
	{ "label": "HP 50 회복", "cost": 30, "type": "heal_hp", "amount": 50.0 },
	{ "label": "쉴드 완전 회복", "cost": 40, "type": "heal_shield", "amount": -1.0 },
	{ "label": "HP 완전 회복", "cost": 80, "type": "heal_hp", "amount": -1.0 },
	{ "label": "부품 스킬 강화 (+20%)", "cost": 60, "type": "upgrade_part", "amount": 0.0 },
]


func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	_build_services()


func _build_services() -> void:
	var container: VBoxContainer = $MarginRoot/VBox/ServiceContainer
	for service: Dictionary in SERVICES:
		var btn: Button = Button.new()
		btn.text = "%s  —  %d 크레딧" % [service["label"], service["cost"]]
		btn.pressed.connect(_on_service_pressed.bind(service))
		container.add_child(btn)


func _on_service_pressed(service: Dictionary) -> void:
	if service["type"] == "upgrade_part":
		_show_upgrade_panel()
		return
	if not GameState.spend_credits(service["cost"]):
		return
	match service["type"]:
		"heal_hp":
			var amount: float = service["amount"]
			if amount < 0:
				amount = GameState.current_core.core_hp
			GameState.heal_hp(amount)
		"heal_shield":
			var amount2: float = service["amount"]
			if amount2 < 0:
				amount2 = GameState.current_core.core_shield
			GameState.heal_shield(amount2)


func _show_upgrade_panel() -> void:
	for child: Node in upgrade_part_container.get_children():
		child.queue_free()

	var has_equipped: bool = false
	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var part: PartsData = GameState.equipped_parts[slot]
		if part == null or part.parts_skills.is_empty():
			continue
		has_equipped = true
		var btn: Button = Button.new()
		btn.text = "[%s] %s" % [CoreData.CoreSlot.keys()[slot], part.parts_name]
		btn.pressed.connect(_on_upgrade_part_selected.bind(part))
		upgrade_part_container.add_child(btn)

	if not has_equipped:
		var label: Label = Label.new()
		label.text = "장착된 부품이 없습니다."
		upgrade_part_container.add_child(label)

	upgrade_panel.visible = true


func _on_upgrade_part_selected(part: PartsData) -> void:
	if not GameState.spend_credits(60):
		upgrade_panel.visible = false
		return
	for skill: SkillData in part.parts_skills:
		if skill.skill_damage > 0.0:
			skill.skill_damage *= 1.2
		if skill.skill_defense > 0.0:
			skill.skill_defense *= 1.2
		if skill.skill_heal > 0.0:
			skill.skill_heal *= 1.2
	upgrade_panel.visible = false
	print("[작업대] 부품 업그레이드: %s 스킬 수치 +20%%" % part.parts_name)


func _on_exit_pressed() -> void:
	DungeonManager.on_room_cleared()
