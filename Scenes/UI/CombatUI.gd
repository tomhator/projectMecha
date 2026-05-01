extends Control

class_name CombatUI

signal skill_selected(skill: SkillData, target: Node)

@onready var skill_container: HBoxContainer = $SkillContainer
@onready var player_hp_bar: ProgressBar = $PlayerHPBar
@onready var player_shield_bar: ProgressBar = $PlayerShieldBar
@onready var enemy_action_label: Label = $EnemyActionLabel
@onready var enemy_container: VBoxContainer = $EnemyContainer

var _current_enemies: Array[EnemyEntity] = []
var _enemy_hp_bars: Dictionary = {}
var _enemy_shield_bars: Dictionary = {}

func _ready() -> void:
	EventBus.hp_changed.connect(_on_hp_changed)
	EventBus.shield_changed.connect(_on_shield_changed)

func on_player_action_required(
	available_skills: Array[SkillData],
	enemies: Array[EnemyEntity]) -> void:

	_current_enemies = enemies
	_rebuild_skill_buttons(available_skills)
	_rebuild_enemy_bars(enemies)
	_update_enemy_preview()

func _rebuild_skill_buttons(available_skills: Array[SkillData]) -> void:
	for child: Node in skill_container.get_children():
		child.queue_free()
	for skill: SkillData in available_skills:
		var btn: Button = Button.new()
		btn.text = skill.skill_name
		btn.pressed.connect(_on_skill_button_pressed.bind(skill))
		skill_container.add_child(btn)

func _on_skill_button_pressed(skill: SkillData) -> void:
	_set_buttons_disabled(true)
	var target: Node = _pick_default_target(skill)
	if target != null:
		skill_selected.emit(skill, target)
	else:
		_set_buttons_disabled(false)  # 타겟 없으면 버튼 복원

func _pick_default_target(skill: SkillData) -> Node:
	match skill.skill_target:
		SkillData.SkillTarget.ENEMY:
			for enemy: EnemyEntity in _current_enemies:
				if not enemy.is_defeated():
					return enemy
		SkillData.SkillTarget.SELF:
			# MechaEntity 노드에 "player" 그룹 추가 필요
			return get_tree().get_first_node_in_group("player")
	return null

func _update_enemy_preview() -> void:
	var lines: Array[String] = []
	for enemy: EnemyEntity in _current_enemies:
		if not enemy.is_defeated() and enemy.next_action != null:
			lines.append("[%s] 예고: %s" % [enemy.enemy_name, enemy.next_action.skill_name])
	enemy_action_label.text = "\n".join(lines)

func _set_buttons_disabled(disabled: bool) -> void:
	for child: Node in skill_container.get_children():
		if child is Button:
			(child as Button).disabled = disabled

func _rebuild_enemy_bars(enemies: Array[EnemyEntity]) -> void:
	# 이미 생성된 경우 재생성 안 함
	if not _enemy_hp_bars.is_empty():
		return
	for child: Node in enemy_container.get_children():
		child.queue_free()
	_enemy_hp_bars.clear()
	_enemy_shield_bars.clear()

	for enemy: EnemyEntity in enemies:
		var vbox: VBoxContainer = VBoxContainer.new()

		var name_label: Label = Label.new()
		name_label.text = enemy.enemy_name
		vbox.add_child(name_label)

		var hp_bar: ProgressBar = ProgressBar.new()
		hp_bar.max_value = enemy.enemy_max_hp
		hp_bar.value = enemy.current_hp
		hp_bar.custom_minimum_size = Vector2(150, 16)
		vbox.add_child(hp_bar)
		_enemy_hp_bars[enemy] = hp_bar

		if enemy.enemy_max_shield > 0.0:
			var shield_bar: ProgressBar = ProgressBar.new()
			shield_bar.max_value = enemy.enemy_max_shield
			shield_bar.value = enemy.current_shield
			shield_bar.custom_minimum_size = Vector2(150, 16)
			vbox.add_child(shield_bar)
			_enemy_shield_bars[enemy] = shield_bar

		enemy_container.add_child(vbox)

func _on_hp_changed(entity: Node, new_hp: float, max_hp: float) -> void:
	if entity is EnemyEntity:
		if _enemy_hp_bars.has(entity):
			_enemy_hp_bars[entity].value = new_hp
		return
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = new_hp

func _on_shield_changed(entity: Node, new_shield: float, max_shield: float) -> void:
	if entity is EnemyEntity:
		if _enemy_shield_bars.has(entity):
			_enemy_shield_bars[entity].value = new_shield
		return
	player_shield_bar.max_value = max_shield
	player_shield_bar.value = new_shield
