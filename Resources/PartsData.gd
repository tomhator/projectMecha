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
@export var parts_icon: Texture2D = null

# 부품 능력치 정보
@export var parts_weight: float = 0.0
@export var ap_contribution: int = 1  # 매 턴 기여 AP. 경량 컨셉 = 2, 일반 = 1, LEG = 0
@export var max_load_bonus: int = 0   # LEG 전용: 최대 하중 증가량

# 드롭·롤 (템플릿 .tres + 런타임)
@export var drop_weight: float = 1.0
@export var affix_pool: Array[String] = []
@export var template_path: String = ""
@export var stat_multiplier: float = 1.0
@export var rolled_affixes: Array[String] = []

# 손상도 — bool is_damaged 제거, 정수만 사용 (조우 B·전투 등 §PartsSystem 6)
@export var max_durability: int = 3
@export var durability: int = 3

# 부품 스킬 정보
@export var parts_skills: Array[SkillData] = []

const PREFIX_TABLE: Array[Array] = [
	[0.70, 0.84, "낡은"],
	[0.85, 0.99, ""],
	[1.00, 1.14, "정밀한"],
	[1.15, 1.29, "강화된"],
	[1.30, 1.50, "완벽한"],
]

const AFFIX_NAMES: Dictionary = {
	"evolution_lord": "진화 군주",
	"mindless": "무지성",
	"greedy": "과한 욕심",
	"productive": "생산성 향상",
	"meticulous": "꼼꼼한 설계",
	"overload": "과부하 모드",
	"counter_instinct": "반격 본능",
	"gambler": "도박사",
	"lifedrain": "흡수 코팅",
	"momentum": "탄력",
	"serious_punch": "진심펀치",
	"zombie_process": "좀비 프로세스",
	"kernel_panic": "커널 패닉",
	"undefined_behavior": "개발자도 모름",
	"backdoor": "백도어",
}


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


func display_name() -> String:
	var prefix := ""
	for entry: Array in PREFIX_TABLE:
		if stat_multiplier >= entry[0] and stat_multiplier <= entry[1]:
			prefix = entry[2]
			break
	return (prefix + " " + parts_name).strip_edges()


func assembly_tooltip_text() -> String:
	var lines: Array[String] = [
		display_name(),
		"%s | %s" % [_part_type_display_name(), PartsGrade.keys()[parts_grade]],
	]
	if not parts_description.is_empty():
		lines.append(parts_description)

	lines.append("하중 %.0f" % parts_weight)
	if parts_type == PartsType.LEG:
		lines.append("최대 하중 +%d" % max_load_bonus)
	else:
		lines.append("행동력 +%d" % ap_contribution)

	var condition := ""
	if is_broken():
		condition = " (파손)"
	elif is_worn():
		condition = " (손상)"
	lines.append("손상도 %d / %d%s" % [durability, max_durability, condition])

	if not rolled_affixes.is_empty():
		var names: Array[String] = []
		for affix_id: String in rolled_affixes:
			names.append(AFFIX_NAMES.get(affix_id, affix_id))
		lines.append("Affix: %s" % ", ".join(names))
	if rolled_affixes.has("evolution_lord"):
		lines.append("「진화 군주」 — 장착 시 추가 팔 슬롯 개방")
	return "\n".join(lines)


func icon_texture(size_px: int = 64) -> Texture2D:
	if parts_icon != null:
		return parts_icon

	var side: int = maxi(size_px, 16)
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	var edge := maxi(int(side * 0.08), 2)
	var color := _fallback_icon_color()
	var shadow := color.darkened(0.42)
	image.fill_rect(Rect2i(edge, edge, side - edge * 2, side - edge * 2), shadow)

	match parts_type:
		PartsType.ARM_L:
			_draw_arm_icon(image, color, true)
		PartsType.ARM_R:
			_draw_arm_icon(image, color, false)
		PartsType.BACK:
			_draw_back_icon(image, color)
		PartsType.LEG:
			_draw_leg_icon(image, color)

	return ImageTexture.create_from_image(image)


func _part_type_display_name() -> String:
	match parts_type:
		PartsType.ARM_L: return "왼팔"
		PartsType.ARM_R: return "오른팔"
		PartsType.BACK: return "등"
		PartsType.LEG: return "다리"
	return "파츠"


func _fallback_icon_color() -> Color:
	match parts_type:
		PartsType.ARM_L: return Color(0.22, 0.78, 0.78, 1.0)
		PartsType.ARM_R: return Color(0.32, 0.56, 0.96, 1.0)
		PartsType.BACK: return Color(0.75, 0.52, 0.92, 1.0)
		PartsType.LEG: return Color(0.42, 0.82, 0.46, 1.0)
	return Color(0.75, 0.75, 0.78, 1.0)


func _draw_arm_icon(image: Image, color: Color, left: bool) -> void:
	var side: int = image.get_width()
	var shoulder_x: int = int(side * (0.18 if left else 0.50))
	var barrel_x: int = int(side * (0.48 if left else 0.18))
	image.fill_rect(Rect2i(shoulder_x, int(side * 0.18), int(side * 0.32), int(side * 0.22)), color)
	image.fill_rect(Rect2i(int(side * 0.38), int(side * 0.34), int(side * 0.24), int(side * 0.42)), color.lightened(0.08))
	image.fill_rect(Rect2i(barrel_x, int(side * 0.64), int(side * 0.34), int(side * 0.16)), color)


func _draw_back_icon(image: Image, color: Color) -> void:
	var side: int = image.get_width()
	image.fill_rect(Rect2i(int(side * 0.20), int(side * 0.18), int(side * 0.60), int(side * 0.24)), color)
	image.fill_rect(Rect2i(int(side * 0.28), int(side * 0.36), int(side * 0.44), int(side * 0.40)), color.lightened(0.08))
	image.fill_rect(Rect2i(int(side * 0.10), int(side * 0.46), int(side * 0.80), int(side * 0.12)), color.darkened(0.10))


func _draw_leg_icon(image: Image, color: Color) -> void:
	var side: int = image.get_width()
	image.fill_rect(Rect2i(int(side * 0.24), int(side * 0.16), int(side * 0.52), int(side * 0.20)), color)
	image.fill_rect(Rect2i(int(side * 0.22), int(side * 0.34), int(side * 0.18), int(side * 0.36)), color.lightened(0.08))
	image.fill_rect(Rect2i(int(side * 0.60), int(side * 0.34), int(side * 0.18), int(side * 0.36)), color.lightened(0.08))
	image.fill_rect(Rect2i(int(side * 0.14), int(side * 0.68), int(side * 0.30), int(side * 0.12)), color)
	image.fill_rect(Rect2i(int(side * 0.56), int(side * 0.68), int(side * 0.30), int(side * 0.12)), color)
