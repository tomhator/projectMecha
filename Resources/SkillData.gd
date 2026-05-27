extends Resource

class_name SkillData

enum SkillType { ATTACK, DEFENSE, HEAL, PASSIVE }
enum SkillTarget { SELF, ENEMY, ALLY }
enum TargetSlot { NONE = -1, ARM_L = 0, ARM_R = 1, BACK = 2, LEG = 3, EXTRA_ARM = 4 }
enum CoreSkillRole { NONE, BASIC_ATTACK, PART_ABILITY }
enum PartAbilityKind { NONE, EMERGENCY_SWAP, BROKEN_THROW, SCRAP_PATCH }

const MULTI_TARGET_MAX_TARGETS: int = 4

enum SkillBuff { ATTACK_UP, DEFENSE_UP, HEAL_UP, SPEED_UP, SHIELD_REGEN, DAMAGE_BOOST, DAMAGE_REDUCTION, EVASION_UP }
enum SkillDebuff { ATTACK_DOWN, DEFENSE_DOWN, HEAL_DOWN, SPEED_DOWN, BURN, AP_DOWN }

# 스킬 기본 정보
@export var skill_id: int = 0
@export var skill_name: String = ""
@export var skill_type: SkillType = SkillType.ATTACK
@export var skill_description: String = ""
@export var skill_icon: Texture2D = null
@export var core_skill_role: CoreSkillRole = CoreSkillRole.NONE
@export var part_ability_kind: PartAbilityKind = PartAbilityKind.NONE

# 스킬 능력치 정보
@export var skill_damage: float = 0.0
@export var skill_defense: float = 0.0
@export var skill_heal: float = 0.0

# 스킬 행동력 비용
@export var skill_action_cost: int = 1

# 스킬 부가 효과: 버프/디버프
@export var has_buff: bool = false
@export var buff_type: SkillBuff = SkillBuff.ATTACK_UP
@export var buff_value: float = 0.0
@export var has_debuff: bool = false
@export var debuff_type: SkillDebuff = SkillDebuff.ATTACK_DOWN
@export var debuff_value: float = 0.0

# 스킬 타겟 정보
@export var skill_target: SkillTarget = SkillTarget.SELF
# 특정 파츠 저격 스킬인 경우 대상 슬롯 (NONE이면 코어/일반 타겟으로 처리)
@export var target_slot: TargetSlot = TargetSlot.NONE

# 타격 관련
@export var hit_count: int = 1
@export var armor_penetration: float = 0.0
@export var multi_target: bool = false

# 방어/보호
@export var shield_amount: float = 0.0
@export var invincible_hit_count: int = 0
@export var has_counter_attack: bool = false

# 버프/디버프 지속
@export var buff_turns: int = 0

# 특수 동작
@export var is_toggle: bool = false
@export var is_free_action: bool = false
@export var permanent_max_hp: float = 0.0
@export var heal_from_damage_ratio: float = 0.0
@export var repairs_all_parts: bool = false
@export var repairs_selected_part: bool = false
@export var extends_buffs: bool = false
@export var grants_action: int = 0
@export var grants_next_free_skill: bool = false
@export var single_use_per_combat: bool = false
@export var summon_enemy: EnemyData = null
@export var summon_limit_per_combat: int = 0


func is_multi_target_enemy_skill() -> bool:
	return multi_target and skill_target == SkillTarget.ENEMY


func combat_tooltip_text(disable_reason: String = "") -> String:
	var lines: Array[String] = [
		skill_name,
		skill_description,
		"AP %d | %s" % [skill_action_cost, _skill_type_display_name()],
	]

	var values: Array[String] = []
	if skill_damage > 0.0:
		values.append("피해 %.0f" % skill_damage)
	if is_multi_target_enemy_skill():
		values.append("최대 %d명 균등 분배" % MULTI_TARGET_MAX_TARGETS)
	if hit_count > 1:
		values.append("%d회 타격" % hit_count)
	if skill_defense > 0.0:
		values.append(("피해감소 %.0f" if has_buff else "쉴드 %.0f") % skill_defense)
	if shield_amount > 0.0:
		values.append("쉴드 %.0f" % shield_amount)
	if skill_heal > 0.0:
		values.append(("회복 %.0f/턴" if has_buff else "회복 %.0f") % skill_heal)
	if heal_from_damage_ratio > 0.0:
		values.append("피해흡수 %.0f%%" % (heal_from_damage_ratio * 100.0))
	if armor_penetration > 0.0:
		values.append("관통 %.0f%%" % (armor_penetration * 100.0))
	if repairs_all_parts:
		values.append("전 파츠 수리")
	if repairs_selected_part:
		values.append("선택 파츠 완전 수리")
	if grants_action > 0:
		values.append("현재 턴 AP +%d" % grants_action)
	if grants_next_free_skill:
		values.append("다음 스킬 무료")
	if extends_buffs:
		values.append("버프 +%d턴" % buff_turns)
	if has_buff and buff_value > 0.0:
		values.append("버프 %.0f%%" % (buff_value * 100.0))
	if not values.is_empty():
		lines.append(" | ".join(values))
	if not disable_reason.is_empty():
		lines.append("사용 불가: %s" % disable_reason)
	return "\n".join(lines)


func icon_texture(size_px: int = 64) -> Texture2D:
	if skill_icon != null:
		return skill_icon

	var side: int = maxi(size_px, 16)
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var edge: int = maxi(int(side * 0.10), 2)
	var color := _skill_type_color()
	image.fill_rect(Rect2i(edge, edge, side - edge * 2, side - edge * 2), color.darkened(0.45))
	match skill_type:
		SkillType.ATTACK:
			_draw_attack_icon(image, color)
		SkillType.DEFENSE:
			_draw_defense_icon(image, color)
		SkillType.HEAL:
			_draw_heal_icon(image, color)
		SkillType.PASSIVE:
			_draw_passive_icon(image, color)
	return ImageTexture.create_from_image(image)


func _skill_type_display_name() -> String:
	match skill_type:
		SkillType.ATTACK: return "공격"
		SkillType.DEFENSE: return "방어"
		SkillType.HEAL: return "회복"
		SkillType.PASSIVE: return "유틸"
	return "스킬"


func _skill_type_color() -> Color:
	match skill_type:
		SkillType.ATTACK: return Color(0.96, 0.38, 0.28, 1.0)
		SkillType.DEFENSE: return Color(0.30, 0.62, 0.96, 1.0)
		SkillType.HEAL: return Color(0.34, 0.88, 0.50, 1.0)
		SkillType.PASSIVE: return Color(0.92, 0.72, 0.28, 1.0)
	return Color(0.78, 0.78, 0.80, 1.0)


func _draw_attack_icon(image: Image, color: Color) -> void:
	var side: int = image.get_width()
	image.fill_rect(Rect2i(int(side * 0.22), int(side * 0.42), int(side * 0.50), int(side * 0.14)), color)
	image.fill_rect(Rect2i(int(side * 0.58), int(side * 0.28), int(side * 0.14), int(side * 0.42)), color)
	image.fill_rect(Rect2i(int(side * 0.28), int(side * 0.30), int(side * 0.16), int(side * 0.38)), color.lightened(0.12))


func _draw_defense_icon(image: Image, color: Color) -> void:
	var side: int = image.get_width()
	image.fill_rect(Rect2i(int(side * 0.24), int(side * 0.22), int(side * 0.52), int(side * 0.16)), color)
	image.fill_rect(Rect2i(int(side * 0.28), int(side * 0.34), int(side * 0.44), int(side * 0.30)), color.lightened(0.10))
	image.fill_rect(Rect2i(int(side * 0.38), int(side * 0.62), int(side * 0.24), int(side * 0.14)), color)


func _draw_heal_icon(image: Image, color: Color) -> void:
	var side: int = image.get_width()
	image.fill_rect(Rect2i(int(side * 0.40), int(side * 0.22), int(side * 0.20), int(side * 0.56)), color)
	image.fill_rect(Rect2i(int(side * 0.22), int(side * 0.40), int(side * 0.56), int(side * 0.20)), color.lightened(0.10))


func _draw_passive_icon(image: Image, color: Color) -> void:
	var side: int = image.get_width()
	image.fill_rect(Rect2i(int(side * 0.26), int(side * 0.26), int(side * 0.48), int(side * 0.48)), color)
	image.fill_rect(Rect2i(int(side * 0.38), int(side * 0.12), int(side * 0.24), int(side * 0.76)), color.lightened(0.14))
