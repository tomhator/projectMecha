extends Resource

class_name CoreData

# 코어 타입: 범용: VANGUARD, 경량: STRIKER, 방어: BULWARK
enum CoreType { VANGUARD, STRIKER, BULWARK }
enum CoreSlot { ARM_L, ARM_R, BACK, LEG }

# 코어 기본 정보
@export var core_id: int = 0
@export var core_name: String = ""
@export var core_type: CoreType = CoreType.VANGUARD
@export var core_description: String = ""

# 코어 슬롯
@export var core_slots: Array[CoreSlot] = []

# 코어 스킬 정보: 코어 타입에 따라 스킬 정보가 다름, 부품이 없을 때 코어 스킬 사용
@export var core_skills: Array[SkillData] = []

# 코어 능력치 정보
@export var core_hp: float = 0.0
@export var core_shield: float = 0.0

@export var core_attack: float = 0.0 # 코어 공격력: 부품이 없을 떄 공격력

@export var core_attack_multiplier: float = 1.0 # 공격력 배율 (경량: 0.6)
@export var core_max_payload: float = 0.0 # 코어 최대 중량
@export var core_action_count: int = 0 # 코어 턴당 행동력 총량