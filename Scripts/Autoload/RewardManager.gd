extends Node

const PARTS_COMMON: Array[String] = [
	"res://Resources/Parts/part_arm_l_cannon.tres",
	"res://Resources/Parts/part_arm_l_gatling.tres",
	"res://Resources/Parts/part_arm_r_shield.tres",
	"res://Resources/Parts/part_arm_r_scatter.tres",
	"res://Resources/Parts/part_back_repair.tres",
	"res://Resources/Parts/part_leg_anchor.tres",
]
const PARTS_RARE: Array[String] = [] # 희귀 파츠 .tres 추가 시 채울 것
const PARTS_EPIC: Array[String] = [] # 에픽 파츠 .tres 추가 시 채울 것

func generate_choices(grade: PartsData.PartsGrade) -> Array[PartsData]:
    var pool: Array[String] = _get_pool(grade)
    if pool.is_empty():
        pool = PARTS_COMMON.duplicate() # 풀이 비면 COMMON으로 폴백
    pool.shuffle()
    var result: Array[PartsData] = []
    for i in mini(3, pool.size()):
        result.append(load(pool[i]) as PartsData)
    return result

func _get_pool(grade: PartsData.PartsGrade) -> Array[String]:
    match grade:
        PartsData.PartsGrade.RARE: return PARTS_RARE.duplicate()
        PartsData.PartsGrade.EPIC: return PARTS_EPIC.duplicate()
        _:                         return PARTS_COMMON.duplicate()
