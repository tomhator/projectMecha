# 전투 화면 정의 (CombatScene / CombatUI)

> 본 문서는 전투 씬의 화면 구성·인터랙션·예상 수치 계산을 정의한다.
> `Docs/UI/HUD.md` §6은 전역 HUD 규칙만 다루므로, **전투 본문 규칙은 모두 이 문서를 기준**으로 한다.

---

## 1. 화면 레이아웃

```
┌────────────────────────────────────────────────────────────┐
│ RunStatusStrip  (층 / HP / 쉴드 / 크레딧 / 설정)            │ ← 0~56px (HUD.md §1)
├────────────────────────────────────────────────────────────┤
│ TurnLabel  (가로 전폭, 중앙 정렬, font 18, 노란빛)          │ ← 60~92px
├────────────────────────────────────────────────────────────┤
│ BattleMargin (좌우 16, 상단 96, 하단 104)                   │
│ ┌──────────────────┬───────────────────────────────────┐   │
│ │ PlayerColumn ≈40%│ EnemyColumn ≈60% (200~500 클램프) │   │
│ │                  │                                   │   │
│ │ [내 메카]        │ [예고 라벨]                       │   │
│ │ 코어 이름        │ [호버 예상 라벨]                  │   │
│ │ [메카 일러스트]  │ HP 바 + 숫자 오버레이             │   │
│ │  (파츠 레이어)   │ 쉴드 바 + 숫자 오버레이           │   │
│ │ ── 예상 회복 ──  │ (적 N개 가로 나열)                │   │
│ │ [클릭 캐처 영역] │                                   │   │
│ └──────────────────┴───────────────────────────────────┘   │
├────────────────────────────────────────────────────────────┤
│ [파츠 상태 HUD]  │  행동력 오브  │  스킬 버튼들  │ Status │ 턴 종료 │
│  (십자형, 좌하단) │               │               │        │  버튼   │
└────────────────────────────────────────────────────────────┘
```

- 좌·우 비율은 `CombatUI._apply_battle_column_split()`로 동적 계산.
  - 가용 폭의 60%를 `EnemyColumn`에, 최소 200 / 최대 500 px로 클램프.
  - 좌측 잔여폭이 64 미만이면 우측을 줄여 좌측을 확보.

---

## 2. 좌측 — PlayerColumn (내 메카)

| 노드 | 역할 |
|------|------|
| `PlayerTitle` | "내 메카" 헤더 |
| `CoreNameLabel` | 현재 코어 이름 |
| **`MechIllustration`** | 파츠 레이어 합성 메카 일러스트 (§2.3 참조) |
| **`_player_preview_label`** (런타임 생성, 주황) | 자기 대상 스킬을 고른 뒤 클릭 캐처에 호버할 때 예상 회복량 표시 |
| **`_player_target_catcher`** (런타임 생성, 투명 Button) | 자기 대상 스킬 발동용 클릭 영역. 평소엔 `MOUSE_FILTER_IGNORE`. |

---

## 2.3 MechIllustration — 메카 일러스트 패널

### 2.3.1 표시 방식: 파츠 레이어 합성

`PlayerColumn` 내 `CoreNameLabel` 바로 아래에 위치.  
파츠 5종을 각각 독립 레이어(`TextureRect`)로 쌓아 한 기체처럼 보이게 합성한다.  
**메카 일러스트 자체에는 손상 tint를 적용하지 않는다** — 손상 상태는 §4의 파츠 상태 HUD가 담당.

#### 레이어 구성 (뒤 → 앞, z-index 순)

| z-index | 슬롯 | 플레이스홀더 색 | 위치 특징 |
|---------|------|---------------|---------|
| 0 | BACK (등) | `Color(0.4, 0.4, 0.5)` 회청 | 코어 뒤쪽 상단 (백팩/부스터) |
| 1 | LEG (다리) | `Color(0.35, 0.35, 0.35)` 다크 회색 | 코어 하단 |
| 2 | CORE (코어) | `Color(0.7, 0.7, 0.75)` 연회색 | 중심 몸통 |
| 3 | ARM_R (오른팔) | `Color(0.3, 0.45, 0.7)` 파랑 | 주력 무장, 아래쪽 앞으로 뻗음 |
| 4 | ARM_L (왼팔) | `Color(0.3, 0.65, 0.65)` 청록 | 보조/방어, 상단 측면 |

- **플레이스홀더 구현**: 각 슬롯을 `ColorRect`로 위치·크기를 잡아두고, 실제 아트 완성 시 `TextureRect`로 교체.
- **빈 슬롯**: 해당 레이어 `visible = false`.
- **컨테이너**: `Control` (고정 크기, `PlayerColumn` 폭에 맞춰 비율 유지).

### 2.3.2 파츠 저격 예고 하이라이트

적이 파츠 저격 계열 스킬 예고 시, **메카 일러스트** 위에서 해당 파츠 레이어를 강조한다.

| 레이어 | modulate | 추가 효과 |
|--------|----------|---------|
| **타겟 파츠** | 1.0 (정상) | 노란 테두리 `StyleBoxFlat` 오버레이 + Tween 깜빡임 (0.6s, 0.7↔1.0 alpha) |
| **비타겟 파츠** | `Color(0.5, 0.5, 0.5)` 어둡게 | 없음 |

- `MechIllustration.set_snipe_target(slot)` / `clear_snipe_target()` 호출로 제어.
- **§4 파츠 상태 HUD의 해당 아이콘도 동시에 강조** (§4.3 참조).
- 예고 해제 조건: 해당 적 격파, 적 턴 종료, 전투 종료.

### 2.3.3 갱신 타이밍

| 이벤트 | 처리 |
|--------|------|
| 전투 진입 (`on_player_action_required` 최초) | 파츠 레이어 전체 재구성 |
| `EventBus.enemy_snipe_preview_changed` | 저격 하이라이트 갱신 |

> 내구도 변화(`part_durability_changed`)는 메카 일러스트에 영향 없음 — §4 HUD만 갱신.

---

## 4. 좌하단 — 파츠 상태 HUD

### 4.1 배치: 십자형 아이콘 레이아웃

하단 행동력/스킬 영역 **좌측**에 고정 위치. 조립 씬 슬롯 배치와 동일한 십자형.

```
      [ 등 ]
[오른팔][코어][왼팔]
      [다리]
```

- 각 아이콘 크기: **32×32px**.
- 코어 칸: 작은 코어 아이콘 또는 빈 칸 (HP/쉴드는 RunStatusStrip 참조이므로 상태 표시 불필요).
- 전체 영역: 약 96×96px.

### 4.2 아이콘 상태 표시

| 상태 | 조건 | 아이콘 표시 |
|------|------|------------|
| 정상 | `durability == max_durability` | 아이콘 불투명 (alpha 1.0) |
| 손상 | `is_worn()` | 아이콘 반투명 (alpha 0.5) + 주황 테두리 |
| 파괴 | `is_broken()` | 아이콘 어둡게 (modulate 0.3) + 빨간 ✕ 오버레이 |
| 빈 슬롯 | `part == null` | 회색 빈 칸 (슬롯 테두리만) |

- **플레이스홀더**: 슬롯 이름 한 글자를 담은 `Panel` (등/R/코/L/다).
- **실제 아트**: 파츠 타입별 아이콘 이미지로 교체.

### 4.3 파츠 저격 예고 연동

`MechIllustration.set_snipe_target(slot)` 호출 시 해당 아이콘도 동시에:
- 노란 테두리 강조
- 비타겟 아이콘은 `modulate Color(0.6, 0.6, 0.6)` 어둡게

### 4.4 갱신 타이밍

| 이벤트 | 처리 |
|--------|------|
| `EventBus.part_durability_changed(part)` | 해당 슬롯 아이콘만 갱신 |
| `on_player_action_required` 진입 | 전체 갱신 |
| `EventBus.enemy_snipe_preview_changed` | 저격 하이라이트 갱신 |

---

### 2.1 자기 대상 스킬(타겟 = SELF) 발동 흐름

1. 사용자가 스킬 버튼 클릭.
2. `_on_skill_button_pressed`가 `_pending_skill` 저장 + `_player_target_catcher.mouse_filter = STOP`.
3. `SelectionStatus`: `「스킬명」 — 내 메카(왼쪽 패널)을 클릭하세요`.
4. 사용자가 `PlayerColumn` 하단 캐처 클릭 → `skill_selected.emit(skill, mecha)` 후 캐처 비활성.
5. 호버 동안 `_player_preview_label`이 예상 회복 표시.

### 2.2 자기 회복 예상 수치 계산

`MechaEntity`에서 다음 헬퍼를 제공한다.

```gdscript
get_preview_effective_hp_heal(skill)     # minf(skill.skill_heal, core_max_hp - current_hp)
get_preview_effective_shield_heal(skill) # minf(skill.skill_defense, core_max_shield - current_shield)
```

표시 형식 (`CombatUI._self_skill_preview_text`):
- 회복 + 방어 모두: `예상 HP +x · 쉴드 +y`
- 한쪽만: `예상 HP +x` 또는 `예상 쉴드 +y`
- 둘 다 없음: `회복·쉴드 수치 없음`

---

## 3. 우측 — EnemyColumn (적)

`EnemyContainer`는 `HBoxContainer`로, 각 적은 `Button` 카드 1개다.

### 3.1 적 카드 구조 (VBox, separation 4)

```
┌─────────────────────────┐
│ [예고 라벨]            │  ← _enemy_forecast_labels[id] (font 11, 주황)
│ [호버 예상 라벨]       │  ← _enemy_hover_preview_labels[id] (font 11, 청록)
│ 적 이름                 │  ← font 13
│ ┌─────────────────────┐ │
│ │ ████░░░░ 42 / 100   │ │  ← HP 바 + 숫자 오버레이 (높이 16)
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ ███░░░░░  5 / 10    │ │  ← 쉴드 바 + 숫자 오버레이 (높이 14, max_shield > 0일 때만)
│ └─────────────────────┘ │
└─────────────────────────┘
```

#### 바 + 숫자 오버레이 규칙

- 행 노드: `Control` (높이 16/14).
- 자식 1: `ProgressBar`, `PRESET_FULL_RECT`, `show_percentage = false`, `mouse_filter = IGNORE`.
- 자식 2: `Label`, `PRESET_FULL_RECT` (좌우 offset −4), `mouse_filter = IGNORE`.
  - `horizontal_alignment = CENTER`, `vertical_alignment = CENTER`.
  - 텍스트: `"%.0f / %.0f"` — **접두어("HP", "쉴드") 없이 숫자만**.
  - `font_outline_color` + `outline_size = 2`로 바 색 위에서도 가독성 확보.
  - HP 폰트 색 `(0.82, 0.86, 0.92)`, 쉴드 폰트 색 `(0.65, 0.82, 0.98)`.

### 3.2 적 대상 스킬 발동 흐름

기존과 동일 (이번 작업에서 변경 없음):

1. 스킬 버튼 클릭 → `_pending_skill` 저장.
2. 살아있는 적들의 카드 `Button`이 `disabled = false` + 푸른 테두리 스타일.
3. 적 카드 호버 시 카드 modulate 1.12~1.25 + **호버 예상 라벨에 예상 피해 표시**.
4. 적 카드 클릭 → `skill_selected.emit(skill, enemy)`.

### 3.3 적 호버 시 예상 수치 (`_damage_preview_text_for_hover`)

들어가는 정보:

- **공격 피해**: `MechaEntity.get_preview_outgoing_damage(skill, enemy)`  
  `= skill.skill_damage × GameState.attack_multiplier × output_mult`
  - `output_mult`는 손상/과부하 패널티 + affix 보정(예: `counter_instinct`, `serious_punch`)을 반영
- **쉴드 / HP 분배**: `EnemyEntity.preview_incoming_damage_split(damage) -> Vector2`  
  - `take_damage`와 동일한 클램프·흡수 규칙
  - `x = 쉴드에 깎일 양`, `y = HP에 깎일 양`
- **자기 회복**: 위 §2.2의 헬퍼 결과

표시 형식 (피해가 있고 회복도 있는 스킬 예시):

```
예상 피해 18 (쉴드 5 · HP 13) · 나 HP +6 · 나 쉴드 +4
```

규칙:

| 스킬 구성 | 표시 |
|----------|-----|
| `damage > 0` | `예상 피해 N (쉴드 A · HP B)` 포함 |
| `skill_heal > 0` | `· 나 HP +x` 추가 |
| `skill_defense > 0` | `· 나 쉴드 +y` 추가 |
| 모두 0 | `예상 수치 없음` |

### 3.4 예고/호버 라벨 우선순위

`_update_enemy_preview()`에서:

1. `enemy.is_defeated()` → 예고/호버 라벨 모두 빈 텍스트.
2. `next_actions`가 있으면 예고 라벨에 `예고: 스킬1 → 스킬2`.
3. `_pending_skill != null && 호버 중인 적`이면 호버 라벨에 §3.3 예상 피해 텍스트.
4. 호버가 아니면 호버 라벨은 빈 텍스트.

---

## 5. 상단 중앙 — TurnLabel

| 속성 | 값 |
|------|----|
| 위치 | `RunStatusStrip` 아래 (y: 60~92px), 가로 전폭 |
| 텍스트 | `"턴 N"` (`N` = 현재 플레이어 턴 번호, 1부터 시작) |
| 폰트 크기 | 18 |
| 정렬 | 중앙 (`horizontal_alignment = CENTER`) |
| 색상 | 옅은 노란빛 (`Color(1.0, 0.96, 0.75)` 권장) |
| 노드 위치 | `CombatUI` 루트 직계 자식 — 전투 전용 위젯이므로 RunStatusStrip과 별도 계층 |

- `TurnManager.start_player_turn()`이 `current_turn += 1` 후 `EventBus.combat_turn_changed.emit(current_turn)` 발행.
- `CombatUI._on_combat_turn_changed(turn)` 핸들러가 `TurnLabel.text = "턴 %d" % turn` 갱신.
- 전투 시작 시 `current_turn = 0`으로 초기화 (첫 플레이어 턴에 1이 됨).

---

## 6. 하단 — 행동력 / 스킬 / 상태

| 요소 | 노드 | 비고 |
|------|------|-----|
| 행동력 오브 | `ActionOrbsRow` (HBox of `ColorRect`) | 남은 액션만큼 초록, 나머지는 회색. 최대치는 `core_action_count`. |
| 스킬 버튼 | `SkillContainer` (HBox of `Button`) | 텍스트: `"스킬명 [AP비용]"`. 대기 중인 스킬은 **시각 강조만** (`_style_skill_button_pending`, normal/hover/pressed 스타일박스에 적용). |
| 상태 메시지 | `SelectionStatus` | `"스킬을 선택하세요."` / `"「X」 — 대상 적을 클릭하세요"` / `"「X」 — 내 메카(왼쪽 패널)을 클릭하세요"` / `"「X」 → 타겟이름"`. |
| 턴 종료 버튼 | `EndTurnButton` | 우측 하단 고정. 플레이어 턴 + 행동력>0일 때 활성. 클릭 시 즉시 적 턴으로 진행. |

### 5.1 펜딩 스킬 흐름 및 자유 교체

모든 스킬 발동은 **「스킬 선택 → 대상 클릭」 2단계**로 통일된다.

```
[1단계] 스킬 버튼 클릭  →  _pending_skill 저장 + 시각 강조
[2단계] 대상 클릭       →  skill_selected.emit  →  캐처/타겟 비활성
```

**자유 교체 규칙**: 2단계 대상 클릭 전까지 모든 스킬 버튼이 항상 활성 상태를 유지한다.  
다른 스킬 버튼을 클릭하면 `_pending_skill`이 교체되며 이전 강조가 제거된다.

| 비활성 사유 | `disabled` 적용 여부 |
|------------|---------------------|
| 타겟 미확정 (펜딩 중) | ❌ 비활성 안 함 (교체 가능) |
| AP 부족 | ✅ `disabled = true`, 툴팁 `AP 부족 (필요/보유)` |
| 파츠 파괴 (`is_broken()`) | ✅ `disabled = true`, 툴팁 `파츠 파괴됨` |

### 5.2 자기 대상 클릭 영역 (`_player_target_catcher`)

자기 대상 스킬(SELF 타겟) 선택 시 `PlayerColumn` 하단에 시각화된 클릭 영역이 나타난다.

| 상태 | `flat` | 텍스트 | 스타일 |
|------|-------|-------|-------|
| 비활성 (평소) | `true` | 없음 | 없음, `mouse_filter = IGNORE` |
| **활성** (SELF 스킬 선택 시) | `false` | **"내 메카 클릭"** | 녹색 점선 박스 (`_style_player_target_catcher_active`) |

- 활성 상태: `_set_player_self_target_pending(true)` → `mouse_filter = STOP` + 녹색 점선 스타일 적용.
- 비활성 상태: `_clear_player_target_catcher_style()` → `flat = true`, `mouse_filter = IGNORE`.
- SELF 타겟팅 중 `PlayerColumn.modulate = Color(0.9, 1.0, 0.92, 1.0)`로 좌측 컬럼 전체를 추가 강조한다.

### 5.3 턴 종료 버튼 (`EndTurnButton`)

`EndTurnButton`은 하단 우측에 고정 배치된다.

| 상태 | 조건 | 동작 |
|------|------|------|
| 활성 | 플레이어 턴이고 `actions_remaining > 0` | 클릭 시 `_pending_skill`/타겟팅 상태를 정리한 뒤 `end_turn_requested` 신호 발행 |
| 비활성 | 적 턴/전투 종료/행동력 0 | 클릭 불가 |

- 용도: 파츠 파손/쿨타임/타겟 부재 등으로 의미 있는 선택지가 없을 때 수동으로 턴을 넘긴다.
- 자동 종료(행동력 0 또는 사용 가능 스킬 없음) 규칙은 기존대로 유지된다.

---

## 6. 신호·이벤트 연동

| 발신 | 수신 | 목적 |
|------|------|-----|
| `CombatUI.skill_selected(skill, target)` | `TurnManager.on_skill_selected` | 스킬 실제 사용 |
| `CombatUI.end_turn_requested()` | `TurnManager.on_end_turn_requested` | 플레이어 턴 수동 종료 |
| `TurnManager.player_action_required(skills, enemies, ap)` | `CombatUI.on_player_action_required` | UI 재구성 |
| `EventBus.hp_changed(entity, new, max)` | `CombatUI._on_hp_changed` | 적 = 카드 갱신, `GameState` = 자기 프리뷰 갱신 |
| `EventBus.shield_changed(...)` | `CombatUI._on_shield_changed` | 동일 |
| `EventBus.skill_used(entity, skill)` | `CombatUI._on_skill_used_global` | 적 예고 라벨 갱신 |

---

## 7. 디자인 결정 요약

- **메카 일러스트에 손상 tint 없음**: 일러스트는 항상 깨끗하게 표시, 손상 상태는 좌하단 파츠 상태 HUD가 전담.
- **파츠 상태 HUD는 십자형**: 조립씬 배치감과 동일하게 등/오른팔·코어·왼팔/다리 십자 구성.
- **모든 스킬이 명시적 타겟팅**: 즉시 발동은 폐기 (광역/패시브가 생기면 별도 분기).
- **스킬 버튼은 타겟 확정 전까지 항상 활성**: 대기 스킬 강조는 시각만, `disabled`는 AP부족·파괴 시만.
- **턴 종료 버튼 제공**: 선택지가 없거나 불리한 교환을 피하고 싶을 때 플레이어가 수동으로 적 턴으로 넘길 수 있다.
- **예고/예상 수치 라벨 분리**: 예고는 상시 유지, 호버 예상은 별도 2번째 라벨에 표시.
- **회복량은 실제 적용량**: 코어 최대치로 클램프 후 값.

---

## 8. 향후 작업

- [x] **`MechIllustration` 구현** — `Control` 컨테이너 + 5개 레이어 플레이스홀더/텍스처 기반 구성.
- [x] **파츠 상태 HUD 구현** — 십자형 32×32px 아이콘 5개. `part_durability_changed` 연동.
- [x] **파츠 저격 예고 연동** — `SkillData.target_slot` + `EventBus.enemy_snipe_preview_changed`로 일러스트·HUD 동시 하이라이트.
- [x] 적 카드 폭이 좁을 때 예고/예상 라벨 줄바꿈(`autowrap_mode`) 적용.
- [x] 예고 / 예상 피해 라벨을 두 줄(VBox)로 분리해 동시에 표시.
- [x] AP 부족·파츠 파괴 비활성 스킬 버튼에 사유 툴팁 표시.
- [x] `Affix`(반격 본능·진심펀치 등) 예상 수치 보정과 실제 적용식 동기화.
- [x] 자기 대상 클릭 시 `PlayerColumn` 전체 하이라이트 적용.

---

## 9. 변경 이력

- 2026-05-18 — 예고/호버 라벨 2줄 분리, 줄바꿈 적용, 비활성 스킬 툴팁 사유화, SELF 타겟팅 시 PlayerColumn 하이라이트, affix(반격 본능·진심펀치) 예상 수치 반영.
- 2026-05-18 — §2.3 MechIllustration(파츠 레이어 합성)·§4 파츠 상태 HUD(십자형 아이콘) 재설계. §5 TurnLabel·§6 펜딩 스킬 흐름 추가. 섹션 번호 재정렬.
- 2026-05-14 — 최초 작성. 적 HP/쉴드 오버레이, 예상 피해/회복, 자기 대상 2단계 클릭 발동.
