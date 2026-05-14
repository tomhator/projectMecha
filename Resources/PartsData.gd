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
@export var ap_contribution: int = 1  # 매 턴 기여 AP. 경량 컨셉 = 2, 일반 = 1, LEG = 0
@export var max_load_bonus: int = 0   # LEG 전용: 최대 하중 증가량

# 드롭·롤 (템플릿 .tres + 런타임)
@export var drop_weight: float = 1.0
@export var affix_pool: Array[String] = []
@export var stat_multiplier: float = 1.0
@export var rolled_affixes: Array[String] = []

# 손상도 — bool is_damaged 제거, 정수만 사용 (조우 B·전투 등 §PartsSystem 6)
@export var max_durability: int = 3
@export var durability: int = 3

# 부품 스킬 정보
@export var parts_skills: Array[SkillData] = []


func _init() -> void:
	_normalize_durability()


func _normalize_durability() -> void:
	if max_durability < 1:
		max_durability = 3
	if durability > max_durability:
		durability = max_durability
	if durability < 0:
		durability = 0


## `max` 미만이면 이벤트 손상·전투 중 경고 UI 등 (스킬 위력 ×0.7)
func is_worn() -> bool:
	return durability < max_durability


func is_broken() -> bool:
	return durability <= 0


func grade() -> PartsGrade:
	var n: int = rolled_affixes.size()
	if n <= 1:
		return PartsGrade.COMMON
	if n <= 3:
		return PartsGrade.RARE
	return PartsGrade.EPIC
