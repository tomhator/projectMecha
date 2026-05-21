---
tags: [project/project-mecha, document/session-context, type/impl-prompt]
created: 2026-05-14
status: pending
topic: 파츠·Affix 시스템 코드 구현 (PartsData·PartsFactory·PartCardUI·.tres)
---

# 파츠·Affix 시스템 구현 프롬프트

> **작업 전 필독 문서**
> - `Docs/PartsSystem.md` — 전체 시스템 명세 (특히 §1.1, §3, §5, §7.2)
> - `Docs/AffixSystem.md` — affix 트리거·적층 규칙 (§3)
> - `Docs/PartsCatalog.md` — 파츠 34종 수치·affix 풀·AP기여
> - `Docs/UI/HUD.md` — PartCardUI 레이아웃 명세 (§2)

---

## 작업 1 — `PartsData.gd`: `ap_contribution` 필드 추가

**파일**: `Resources/PartsData.gd`

기존 `parts_weight` 아래에 다음 필드를 추가한다.

```gdscript
@export var ap_contribution: int = 1  # 매 턴 기여 AP. 경량 컨셉 파츠 = 2, 나머지 = 1, LEG = 0
```

LEG 파츠는 AP를 기여하지 않는다. LEG의 기본값 0은 .tres에서 직접 지정한다.

---

## 작업 2 — `PartsFactory.gd`: 두 가지 수정

**파일**: `Scripts/Autoload/PartsFactory.gd`

### 2-A. `_roll_affix_count_for` — 확률 테이블 반영

현재 `randi_range` 균등 확률을 아래 가중치 테이블로 교체한다.
(`PartsSystem §3.2` 기준)

```gdscript
func _roll_affix_count_for(drop_grade: PartsData.PartsGrade) -> int:
    var r := randf()
    match drop_grade:
        PartsData.PartsGrade.COMMON:
            return 0 if r < 0.45 else 1          # 45% / 55%
        PartsData.PartsGrade.RARE:
            return 2 if r < 0.55 else 3          # 55% / 45%
        _:  # EPIC
            return 4 if r < 0.65 else 5          # 65% / 35%
```

### 2-B. `generate()` — on_equip affix 후처리 추가

`max_durability` 설정 직후, `durability` 할당 전에 아래 함수를 호출한다.
(`PartsSystem §7.2` 6번 단계)

```gdscript
func generate(template: PartsData, drop_grade: PartsData.PartsGrade) -> PartsData:
    # ... 기존 코드 ...
    var idx: int = mini(p.rolled_affixes.size(), MAX_DURABILITY_BY_AFFIX_COUNT.size() - 1)
    p.max_durability = MAX_DURABILITY_BY_AFFIX_COUNT[idx]
    _apply_on_equip_affixes(p)          # ← 이 줄 추가
    p.durability = p.max_durability
    p.parts_grade = p.grade()
    p._normalize_durability()
    return p


func _apply_on_equip_affixes(p: PartsData) -> void:
    for affix_id: String in p.rolled_affixes:
        match affix_id:
            "meticulous":
                p.max_durability = roundi(p.max_durability * 1.10)
            "greedy":
                p.parts_weight = maxf(p.parts_weight + 5.0, 1.0)
            "productive":
                p.parts_weight = maxf(p.parts_weight - 3.0, 1.0)
```

---

## 작업 3 — `PartCardUI.gd`: 전면 업데이트

**파일**: `Scenes/Assembly/PartCardUI.gd`
**명세**: `Docs/UI/HUD.md §2`

### 3-A. 레이아웃 변경

`custom_minimum_size` → `Vector2(220, 110)`

`_build_ui()` 를 아래 VBox 5줄 구조로 재작성한다.

```
줄 1: _part_name_label     (font 13, 등급 색)
줄 2: _type_label          (font 10, 초록)
줄 3: _skill_label         (font 10, 파랑, autowrap)
줄 4: HBoxContainer
        └ _weight_label    (font 10, 회색, EXPAND_FILL)
        └ _durability_label(font 10, 색상 조건부, SHRINK_END)
줄 5: _affix_label         (font 9, 연보라, autowrap, 없으면 visible=false)
```

### 3-B. 상수 추가

```gdscript
const COLOR_WARN: Color    = Color(1.0, 0.6, 0.1)   # ⚠ 주황
const COLOR_BROKEN: Color  = Color(0.9, 0.2, 0.2)   # 💀 빨강
const COLOR_DUR_OK: Color  = Color(0.3, 0.85, 0.4)  # 손상도 정상 초록
const COLOR_AFFIX: Color   = Color(0.85, 0.75, 1.0) # affix 연보라

const PREFIX_TABLE: Array[Array] = [
    [0.70, 0.84, "낡은"],
    [0.85, 0.99, ""],
    [1.00, 1.14, "정밀한"],
    [1.15, 1.29, "강화된"],
    [1.30, 1.50, "완벽한"],
]

const AFFIX_NAMES: Dictionary = {
    "evolution_lord":    "진화 군주",
    "mindless":          "무지성",
    "greedy":            "과한 욕심",
    "productive":        "생산성 향상",
    "meticulous":        "꼼꼼한 설계",
    "overload":          "과부하 모드",
    "counter_instinct":  "반격 본능",
    "gambler":           "도박사",
    "lifedrain":         "흡수 코팅",
    "momentum":          "탄력",
    "serious_punch":     "진심펀치",
    "zombie_process":    "좀비 프로세스",
    "kernel_panic":      "커널 패닉",
    "undefined_behavior":"개발자도 모름",
    "backdoor":          "백도어",
}
```

### 3-C. `_refresh_display()` 재작성

```
# 줄 1: 이름
prefix = PREFIX_TABLE에서 stat_multiplier 범위 매칭
tag = "💀" if is_broken else ("⚠" if is_worn else "")
_part_name_label.text = (prefix + " " + parts_name).strip_edges() + (" " + tag if tag else "")
tag 색상: 💀 → COLOR_BROKEN, ⚠ → COLOR_WARN (add_theme_color_override)

# 줄 4: 손상도 블록
filled = "■" * durability
empty  = "□" * (max_durability - durability)
_durability_label.text = filled + empty
색상: durability == max_durability → COLOR_DUR_OK / is_worn → COLOR_WARN / is_broken → COLOR_BROKEN

# 줄 5: affix 목록
names = rolled_affixes.map(fn(id) → AFFIX_NAMES.get(id, id))
if names.is_empty():
    _affix_label.visible = false
else:
    _affix_label.text = "  ".join(names)
    _affix_label.visible = true
```

---

## 작업 4 — `.tres` 파일 전면 재설계

**현황**: `Resources/Parts/` 아래 구 버전 24개 파일 (common/rare/epic 폴더 구분).  
rarity가 드롭 시 결정되므로 폴더 분류는 의미 없음.

**목표**: PartsCatalog 기준 34개 파일로 교체. 폴더 구조 `Resources/Parts/{슬롯}/` 으로 변경.

```
Resources/Parts/
  arm_l/   (8개)
  arm_r/   (8개)
  back/    (8개)
  leg/     (10개)
```

### 각 .tres 파일에 설정할 필드 (PartsData 기준)

| 필드 | 값 출처 |
|------|--------|
| `parts_name` | PartsCatalog 이름 (좌/우 포함) |
| `parts_type` | ARM_L / ARM_R / BACK / LEG |
| `parts_description` | PartsCatalog 스킬 설명 |
| `parts_weight` | PartsCatalog base weight |
| `drop_weight` | PartsCatalog 드롭 가중치 |
| `affix_pool` | PartsCatalog affix 풀 목록 |
| `ap_contribution` | PartsCatalog AP기여 값 (LEG=0, 일반=1, 경량=2) |
| `parts_skills` | 해당 SkillData .tres 참조 |
| `stat_multiplier` | 1.0 (템플릿 기본값) |
| `rolled_affixes` | [] (런타임에서 결정) |
| `max_durability` | 3 (런타임에서 결정, 기본값만) |
| `durability` | 3 |

### 파일명 규칙

PartsCatalog `파일명` 컬럼 기준으로 통일.
예: `arm_l_m88.tres`, `arm_r_vhf9.tres`, `back_sd7.tres`, `leg_rampart8.tres`

### 기존 파일 처리

구 버전 파일은 삭제하고 신규 34개로 대체.  
삭제 전 기존 파일을 참조하는 씬/스크립트 경로 업데이트 필요 (`AssemblyScene`, `RewardManager` 등).

---

## 작업 순서 권장

1. **작업 1** (PartsData 필드) → 가장 먼저. 이후 작업들이 이 필드에 의존.
2. **작업 2** (PartsFactory 수정) → 독립적, 즉시 가능.
3. **작업 3** (PartCardUI) → 독립적, 즉시 가능.
4. **작업 4** (.tres 재설계) → 가장 오래 걸림. SkillData .tres가 먼저 확정되어야 `parts_skills` 참조 가능.

> 작업 4의 SkillData .tres 현황은 별도 확인 필요.
