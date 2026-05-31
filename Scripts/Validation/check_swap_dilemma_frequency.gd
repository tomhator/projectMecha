extends SceneTree

# V5 검증: 한 런에서 교체 딜레마 "기회"가 평균 3회 이상 발생하는지 측정한다.
# 가정(문서화된 단순화):
#  - 모든 슬롯이 채워진 후반 로드아웃에서는 매 드롭이 딜레마 기회다
#    (ARM_L/ARM_R/BACK/LEG 각 소켓이 점유 상태 → 같은 타입 드롭 = 강제 교체).
#  - 따라서 딜레마 기회 수 ≈ 런 전체 전투 드롭 수.
#  - 대표 전투 경로의 층별 격파 적 수를 고정해 드롭 볼륨을 잰다.
# V1(수락률)은 사람 판단 영역이라 측정 대상이 아니다 — 설계 문서 §1 참고.

const SIM_RUNS: int = 200
const MIN_AVG_DILEMMAS: float = 3.0
# 대표 전투 경로: 1~3층 일반(적2), 6~8층 일반/엘리트(적1~2), 9층 엘리트(적1), 10층 보스(적1).
# 4~5층은 비전투 선택 가능성이 있어 보수적으로 제외.
# 6~8층은 일반/엘리트라 적 1~2마리지만 보수적 상한으로 2를 쓴다.
const DEFEATED_PER_COMBAT_FLOOR: Array[int] = [2, 2, 2, 2, 2, 1, 1, 1]

var _failed: bool = false


func _initialize() -> void:
	seed(20260531)
	var reward_manager: Node = root.get_node_or_null("RewardManager")
	if reward_manager == null:
		push_error("Missing RewardManager autoload")
		quit(1)
		return
	var total_dilemmas: int = 0
	# 진단 전용 — PASS/FAIL 기준 아님 (드롭 0개 런이 몇 번인지 참고 출력용)
	var runs_below_one: int = 0
	for _r: int in range(SIM_RUNS):
		var run_dilemmas: int = 0
		for defeated: int in DEFEATED_PER_COMBAT_FLOOR:
			var drops: Array = reward_manager.call("generate_combat_drops", PartsData.PartsGrade.COMMON, defeated)
			run_dilemmas += drops.size()
		total_dilemmas += run_dilemmas
		if run_dilemmas < 1:
			runs_below_one += 1
	var avg: float = float(total_dilemmas) / float(SIM_RUNS)
	print("V5 측정: 평균 딜레마 기회/런 = %.2f (목표 ≥ %.1f), 0회 런 = %d/%d" % [avg, MIN_AVG_DILEMMAS, runs_below_one, SIM_RUNS])
	if avg < MIN_AVG_DILEMMAS:
		push_error("V5 FAIL: 평균 딜레마 기회 %.2f < %.1f" % [avg, MIN_AVG_DILEMMAS])
		_failed = true
	if _failed:
		print("Swap dilemma frequency: FAIL")
		quit(1)
	else:
		print("Swap dilemma frequency: PASS")
		quit(0)
