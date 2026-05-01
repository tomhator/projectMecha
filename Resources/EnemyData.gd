extends Resource

class_name EnemyData

enum EnemyTier { NORMAL, ELITE, BOSS }

# 적 기본 정보
@export var enemy_id: int = 0
@export var enemy_name: String = ""
@export var enemy_tier: EnemyTier = EnemyTier.NORMAL
@export var enemy_description: String = ""

# 적 능력치
@export var enemy_max_hp: float = 0.0
@export var enemy_max_shield: float = 0.0
@export var attack_multiplier: float = 1.0

# 적 스킬 목록 — EnemyEntity.decide_next_action()에서 랜덤 선택
@export var skills: Array[SkillData] = []
