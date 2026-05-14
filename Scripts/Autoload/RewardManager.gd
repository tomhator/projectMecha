extends Node

const PARTS_DIRS: Array[String] = [
	"res://Resources/Parts/arm_l",
	"res://Resources/Parts/arm_r",
	"res://Resources/Parts/back",
	"res://Resources/Parts/leg",
]

var _all_parts: Array[String] = []
var _all_weights: Array[float] = []


func _ready() -> void:
	_refresh_parts_pool()


func generate_choices(grade: PartsData.PartsGrade, count: int = 3) -> Array[PartsData]:
	if _all_parts.is_empty():
		_refresh_parts_pool()
	if _all_parts.is_empty():
		return []

	var chosen_paths := _weighted_sample(_all_parts, _all_weights, count)
	var result: Array[PartsData] = []
	for path: String in chosen_paths:
		var template: PartsData = load(path) as PartsData
		if template != null:
			result.append(PartsFactory.generate(template, grade))
	return result


func _weighted_sample(paths: Array[String], weights: Array[float], n: int) -> Array[String]:
	var remaining_paths := paths.duplicate()
	var remaining_weights := weights.duplicate()
	var result: Array[String] = []

	for _i in mini(n, remaining_paths.size()):
		var total := 0.0
		for w: float in remaining_weights:
			total += w
		var r := randf() * total
		var cumulative := 0.0
		for j in remaining_paths.size():
			cumulative += remaining_weights[j]
			if r <= cumulative:
				result.append(remaining_paths[j])
				remaining_paths.remove_at(j)
				remaining_weights.remove_at(j)
				break

	return result


func _refresh_parts_pool() -> void:
	_all_parts.clear()
	_all_weights.clear()

	for folder: String in PARTS_DIRS:
		var dir := DirAccess.open(folder)
		if dir == null:
			push_warning("RewardManager: 파츠 폴더를 열 수 없습니다 - %s" % folder)
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path := "%s/%s" % [folder, file_name]
				var template: PartsData = load(full_path) as PartsData
				if template != null:
					_all_parts.append(full_path)
					_all_weights.append(template.drop_weight)
			file_name = dir.get_next()
		dir.list_dir_end()
