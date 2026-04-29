extends Resource

class_name SkillData

enum SkillType { ATTACK, DEFENSE, HEAL, PASSIVE }
enum SkillTarget { SELF, ENEMY }

enum SkillBuff { ATTACK_UP, DEFENSE_UP, HEAL_UP, SPEED_UP }
enum SkillDebuff { ATTACK_DOWN, DEFENSE_DOWN, HEAL_DOWN, SPEED_DOWN }

# 스킬 기본 정보
@export var skill_id: int = 0
@export var skill_name: String = ""
@export var skill_type: SkillType = SkillType.ATTACK
@export var skill_description: String = ""

# 스킬 능력치 정보
@export var skill_damage: float = 0.0
@export var skill_defense: float = 0.0
@export var skill_heal: float = 0.0

# 스킬 쿨다운 정보
@export var skill_cooldown: int = 0

# 스킬 부가 효과: 버프/디버프
@export var has_buff: bool = false
@export var buff_type: SkillBuff = SkillBuff.ATTACK_UP
@export var has_debuff: bool = false
@export var debuff_type: SkillDebuff = SkillDebuff.ATTACK_DOWN

# 스킬 타겟 정보
@export var skill_target: SkillTarget = SkillTarget.SELF
