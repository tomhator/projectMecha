extends Resource

class_name CoreData

enum CoreSlot { ARM_L = 0, ARM_R = 1, BACK = 2, LEG = 3, EXTRA_ARM = 4 }

# 코어 기본 정보
@export var core_id: int = 0
@export var core_name: String = ""
@export var core_description: String = ""

# 코어 슬롯
@export var core_slots: Array[CoreSlot] = []

# 코어 능력치
@export var core_hp: float = 0.0
@export var core_shield: float = 0.0
@export var core_attack_multiplier: float = 1.0
@export var core_max_payload: float = 0.0
@export var core_action_count: int = 0
