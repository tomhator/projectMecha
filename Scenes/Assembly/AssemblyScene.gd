extends Control

const DUNGEON_MAP_SCENE: String = "res://Scenes/Dungeon/DungeonMapScene.tscn"

@onready var slot_panel: VBoxContainer = $HBoxContainer/SlotPanel
@onready var inventory_panel: VBoxContainer = $HBoxContainer/InventoryPanel
@onready var payload_label: Label = $PayloadLabel
@onready var close_button: Button = $CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_rebuild_all()

func _rebuild_all() -> void:
	_rebuild_slots()
	_rebuild_inventory()
	_update_payload()

func _rebuild_slots() -> void:
	for child: Node in slot_panel.get_children():
		child.queue_free()

	for slot: CoreData.CoreSlot in GameState.equipped_parts:
		var hbox := HBoxContainer.new()

		var slot_label := Label.new()
		slot_label.text =CoreData.CoreSlot.keys()[slot] + ": "
		slot_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(slot_label)

		var part: PartsData = GameState.equipped_parts[slot]
		var btn := Button.new()
		if part != null:
			btn.text = part.parts_name + " [해제]"
			btn.pressed.connect(_on_unequip_pressed.bind(slot))
		else:
			btn.text = "빈 슬롯"
			btn.disabled = true
		hbox.add_child(btn)
		slot_panel.add_child(hbox)

func _rebuild_inventory() -> void:
	for child: Node in inventory_panel.get_children():
		child.queue_free()

	if GameState.inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "인벤토리가 비었습니다."
		inventory_panel.add_child(empty_label)
		return
	
	for part: PartsData in GameState.inventory:
		var btn := Button.new()
		btn.text = "[%s] %s\n%s" % [
			PartsData.PartsType.keys()[part.parts_type],
			part.parts_name,
			part.parts_description,
		]
		btn.tooltip_text = part.parts_description
		btn.pressed.connect(_on_equip_pressed.bind(part))
		inventory_panel.add_child(btn)

func _on_equip_pressed(part: PartsData) -> void:
	var slot: CoreData.CoreSlot = _type_to_slot(part.parts_type)
	# 기존 슬롯 파츠를 인벤토리로 반환
	var existing: PartsData = GameState.equipped_parts[slot]
	if existing != null:
		GameState.inventory.append(existing)
	GameState.inventory.erase(part)
	GameState.equip_part(part, slot)
	EventBus.inventory_changed.emit(GameState.inventory)
	_rebuild_all()

func _on_unequip_pressed(slot: CoreData.CoreSlot) -> void:
	var part: PartsData = GameState.equipped_parts[slot]
	if part != null:
		GameState.unequip_part(slot)
		GameState.inventory.append(part)
		EventBus.inventory_changed.emit(GameState.inventory)
	_rebuild_all()

func _update_payload() -> void:
	payload_label.text = "하중: %.0f / %.0f" % [
		GameState.current_payload,
		GameState.current_core.core_max_payload
	]

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file(DUNGEON_MAP_SCENE)

func _type_to_slot(parts_type: PartsData.PartsType) -> CoreData.CoreSlot:
	match parts_type:
		PartsData.PartsType.ARM_L: return CoreData.CoreSlot.ARM_L
		PartsData.PartsType.ARM_R: return CoreData.CoreSlot.ARM_R
		PartsData.PartsType.BACK: return CoreData.CoreSlot.BACK
		PartsData.PartsType.LEG: return CoreData.CoreSlot.LEG
		_: return CoreData.CoreSlot.ARM_L
