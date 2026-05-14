extends Node

## 템플릿 PartsData를 복제해 롤 결과를 채운 인스턴스를 만든다. [[PartsSystem]] §7.2

const MAX_DURABILITY_BY_AFFIX_COUNT: Array[int] = [3, 3, 5, 5, 7, 7]

const EVOLUTION_LORD_ID: String = "evolution_lord"


func generate(template: PartsData, drop_grade: PartsData.PartsGrade) -> PartsData:
	var p: PartsData = template.duplicate(true) as PartsData
	if p == null:
		push_error("PartsFactory.generate: duplicate failed")
		return template

	p.stat_multiplier = randf_range(0.70, 1.50)

	var count: int = _roll_affix_count_for(drop_grade)
	var pool: PackedStringArray = _filtered_affix_pool(p)
	p.rolled_affixes.clear()

	for _i in count:
		if pool.is_empty():
			break
		var chosen: String = _pick_unique_affix(pool, p.rolled_affixes)
		if chosen.is_empty():
			break
		p.rolled_affixes.append(chosen)

	var idx: int = mini(p.rolled_affixes.size(), MAX_DURABILITY_BY_AFFIX_COUNT.size() - 1)
	p.max_durability = MAX_DURABILITY_BY_AFFIX_COUNT[idx]
	_apply_on_equip_affixes(p)
	p.durability = p.max_durability
	p.parts_grade = p.grade()
	p._normalize_durability()
	return p


func _roll_affix_count_for(drop_grade: PartsData.PartsGrade) -> int:
	var r := randf()
	match drop_grade:
		PartsData.PartsGrade.COMMON:
			return 0 if r < 0.45 else 1
		PartsData.PartsGrade.RARE:
			return 2 if r < 0.55 else 3
		_:  # EPIC
			return 4 if r < 0.65 else 5


func _apply_on_equip_affixes(p: PartsData) -> void:
	for affix_id: String in p.rolled_affixes:
		match affix_id:
			"meticulous":
				p.max_durability = roundi(p.max_durability * 1.10)
			"greedy":
				p.parts_weight = maxf(p.parts_weight + 5.0, 1.0)
			"productive":
				p.parts_weight = maxf(p.parts_weight - 3.0, 1.0)


func _filtered_affix_pool(p: PartsData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for id: String in p.affix_pool:
		if id == EVOLUTION_LORD_ID:
			if p.parts_type != PartsData.PartsType.BACK and p.parts_type != PartsData.PartsType.ARM_L and p.parts_type != PartsData.PartsType.ARM_R:
				continue
		out.append(id)
	return out


func _pick_unique_affix(pool: PackedStringArray, already: Array[String]) -> String:
	var candidates: Array[String] = []
	for id: String in pool:
		if not already.has(id):
			candidates.append(id)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]
