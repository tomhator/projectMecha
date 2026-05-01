extends Resource

class_name PartsData

enum PartsType { ARM_L, ARM_R, BACK, LEG }
enum PartsGrade { COMMON, RARE, EPIC }

# 부품 기본 정보
@export var parts_id: int = 0
@export var parts_name: String = ""
@export var parts_type: PartsType = PartsType.ARM_L
@export var parts_grade: PartsGrade = PartsGrade.COMMON
@export var parts_description: String = ""

# 부품 능력치 정보
@export var parts_weight: float = 0.0

# 부품 스킬 정보
@export var parts_skills: Array[SkillData] = []