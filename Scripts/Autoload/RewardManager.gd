extends Node

const PARTS_COMMON_DIR: String = "res://Resources/Parts/common"
const PARTS_RARE_DIR: String = "res://Resources/Parts/rare"
const PARTS_EPIC_DIR: String = "res://Resources/Parts/epic"

var parts_common: Array[String] = []
var parts_rare: Array[String] = []
var parts_epic: Array[String] = []

func _ready() -> void:
	_refresh_parts_pools()

func generate_choices(grade: PartsData.PartsGrade) -> Array[PartsData]:
	if parts_common.is_empty() and parts_rare.is_empty() and parts_epic.is_empty():
		_refresh_parts_pools()

	var pool: Array[String] = _get_pool(grade)
	if pool.is_empty():
		pool = parts_common.duplicate() # 풀이 비면 COMMON으로 폴백

	pool.shuffle()
	var result: Array[PartsData] = []
	for i in mini(3, pool.size()):
		result.append(load(pool[i]) as PartsData)
	return result

func _get_pool(grade: PartsData.PartsGrade) -> Array[String]:
	match grade:
		PartsData.PartsGrade.RARE:
			return parts_rare.duplicate()
		PartsData.PartsGrade.EPIC:
			return parts_epic.duplicate()
		_:
			return parts_common.duplicate()

func _refresh_parts_pools() -> void:
	parts_common = _collect_tres_paths(PARTS_COMMON_DIR)
	parts_rare = _collect_tres_paths(PARTS_RARE_DIR)
	parts_epic = _collect_tres_paths(PARTS_EPIC_DIR)

func _collect_tres_paths(folder_path: String) -> Array[String]:
	var collected: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder_path)
	if dir == null:
		push_warning("RewardManager: 파츠 폴더를 열 수 없습니다 - %s" % folder_path)
		return collected

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			collected.append("%s/%s" % [folder_path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()

	collected.sort()
	return collected
