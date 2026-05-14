extends Resource

class_name SkillData

enum SkillType { ATTACK, DEFENSE, HEAL, PASSIVE }
enum SkillTarget { SELF, ENEMY }

enum SkillBuff { ATTACK_UP, DEFENSE_UP, HEAL_UP, SPEED_UP, SHIELD_REGEN, DAMAGE_BOOST, DAMAGE_REDUCTION, EVASION_UP }
enum SkillDebuff { ATTACK_DOWN, DEFENSE_DOWN, HEAL_DOWN, SPEED_DOWN, BURN, AP_DOWN }

# 스킬 기본 정보
@export var skill_id: int = 0
@export var skill_name: String = ""
@export var skill_type: SkillType = SkillType.ATTACK
@export var skill_description: String = ""

# 스킬 능력치 정보
@export var skill_damage: float = 0.0
@export var skill_defense: float = 0.0
@export var skill_heal: float = 0.0

# 스킬 행동력 비용
@export var skill_action_cost: int = 1

# 스킬 부가 효과: 버프/디버프
@export var has_buff: bool = false
@export var buff_type: SkillBuff = SkillBuff.ATTACK_UP
@export var has_debuff: bool = false
@export var debuff_type: SkillDebuff = SkillDebuff.ATTACK_DOWN

# 스킬 타겟 정보
@export var skill_target: SkillTarget = SkillTarget.SELF

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
