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
│ │ 코어 이름        │ 적 이름                            │   │
│ │ [메카 슬롯 패널] │ HP 바 + 숫자 오버레이             │   │
│ │  (십자형 블록)   │ 쉴드 바 + 숫자 오버레이           │   │
│ │ ── 예상 회복 ──  │ (적 N개 가로 나열)                │   │
│ │ [클릭 캐처 영역] │                                   │   │
│ └──────────────────┴───────────────────────────────────┘   │
├────────────────────────────────────────────────────────────┤
│ 행동력 오브  │  스킬 버튼들  │  SelectionStatus 텍스트     │
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
| **`MechStatusPanel`** | 슬롯 블록형 메카 상태 표시 (§2.3 참조) |
| **`_player_preview_label`** (런타임 생성, 주황) | 자기 대상 스킬을 고른 뒤 클릭 캐처에 호버할 때 예상 회복량 표시 |
| **`_player_target_catcher`** (런타임 생성, 투명 Button) | 자기 대상 스킬 발동용 클릭 영역. 평소엔 `MOUSE_FILTER_IGNORE`. |

---

## 2.3 MechStatusPanel — 메카 슬롯 상태 표시

### 2.3.1 표시 방식: 블록형 십자 레이아웃

조립 씬과 동일한 십자형 배치를 전투 화면용 소형으로 재현한다.  
`PlayerColumn` 내 `CoreNameLabel` 바로 아래, `_player_preview_label` 위에 배치.

```
           ┌─────────┐
           │  BACK   │
           │   등    │
           └─────────┘
┌─────────┐┌─────────┐┌─────────┐
│  ARM_R  ││  CORE   ││  ARM_L  │
│ 오른팔  ││ 코어명  ││  왼팔   │
└─────────┘└─────────┘└─────────┘
           ┌─────────┐
           │   LEG   │
           │  다리   │
           └─────────┘
```

- **화면 방향**: ARM_R(메크 오른팔)이 화면 **왼쪽**, ARM_L(메크 왼팔)이 화면 **오른쪽**.  
  (코어가 카메라를 바라보기 때문 — 조립 씬과 동일한 규칙.)
- **각 슬롯 블록 크기**: 최소 52×44px. `PlayerColumn` 폭에 따라 비례 축소 가능.
- **코어 블록**: 공격 대상이 아니므로 이름만 표시. HP/쉴드는 RunStatusStrip 참조.
- **파츠 슬롯 블록 내부**:
  - 줄 1: 슬롯 한국어명 (`오른팔` / `왼팔` / `등` / `다리`, font 10, 회색)
  - 줄 2: 파츠명 (최대 6자 truncate + `…`, font 11, 상태 색)
  - 줄 3: 손상도 블록 `■■□□□` (font 9)
- 기존 `PartsLabels` (텍스트 VBox) 제거 후 `MechStatusPanel`로 단일화.

### 2.3.2 슬롯 상태 색상 코딩

| 상태 | 조건 | 테두리 색 | 파츠명 색 | 배경 추가 처리 |
|------|------|----------|----------|--------------|
| 정상 | `durability == max_durability` | `Color(0.3, 0.8, 0.3)` 초록 | 흰색 | 없음 |
| 손상 | `is_worn()` (0 < dur < max) | `Color(1.0, 0.7, 0.2)` 주황 | 주황 | 없음 |
| 파괴 | `is_broken()` (dur == 0) | `Color(0.9, 0.2, 0.2)` 빨강 | 빨강 | `modulate Color(0.5, 0.5, 0.5)` + "✕" 오버레이 |
| 빈 슬롯 | `part == null` | `Color(0.4, 0.4, 0.4)` 회색 | 회색 | "(없음)" 텍스트 |

> **파괴 슬롯 ✕ 오버레이**: `Control` 레이어를 블록 위에 `PRESET_FULL_RECT`로 덮어씌워  
> 반투명 빨간 배경 `Color(0.8, 0.1, 0.1, 0.35)` + 중앙 "✕" 라벨(font 14, 흰색) 표시.

### 2.3.3 파츠 저격 예고 하이라이트

적이 파츠 저격 계열 스킬(파츠 저격 · 과부하 공격 · EMP 충격)의 예고 액션으로  
특정 슬롯을 타겟할 때, `MechStatusPanel`이 즉각 시각 피드백을 제공한다.

#### 예고 상태 시각 규칙

| 슬롯 | 테두리 | modulate | 추가 표시 |
|------|-------|----------|---------|
| **타겟 슬롯** | `Color(1.0, 0.9, 0.1)` 노란 테두리 | 1.0 (정상) | Tween 깜빡임 (0.6s 주기, 0.8↔1.0 alpha) |
| **비타겟 슬롯** | 기존 상태 색 유지 | `Color(0.6, 0.6, 0.6)` 어둡게 | 없음 |

- `MechStatusPanel._set_snipe_preview(target_slot: CoreData.CoreSlot)` 호출로 하이라이트 적용.
- `MechStatusPanel._clear_snipe_preview()` 호출로 초기화.
- 예고 해제 조건: 해당 적 격파, 적 턴 종료, 전투 종료.

#### 저격 타겟 정보 전달 설계 (미구현)

현재 `SkillData`에는 슬롯 타겟 필드가 없다. 파츠 저격 예고 UI 구현을 위해 추후 필요한 변경:

```gdscript
# SkillData.gd 에 추가 예정
@export var target_slot: CoreData.CoreSlot = CoreData.CoreSlot.NONE  # 0이면 비저격 스킬
```

`EnemyEntity.decide_next_actions()`에서 `target_slot != NONE`인 스킬을 선택하면  
`EventBus.enemy_snipe_preview_changed(enemy, slot)` 시그널로 UI에 알린다.

### 2.3.4 갱신 타이밍

`MechStatusPanel`은 아래 이벤트에서 `_refresh_all()` 호출:

| 이벤트 | 갱신 범위 |
|--------|---------|
| `EventBus.part_durability_changed(part)` | 해당 파츠 슬롯 블록만 갱신 |
| `on_player_action_required` 진입 | 전체 갱신 |
| `EventBus.enemy_snipe_preview_changed` (미구현) | 저격 하이라이트 갱신 |

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
│ [예고 / 예상 피해 라벨] │  ← _enemy_preview_labels[id]  (font 11, 주황)
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
3. 적 카드 호버 시 카드 modulate 1.12~1.25 + **예고 라벨이 예상 피해로 전환**.
4. 적 카드 클릭 → `skill_selected.emit(skill, enemy)`.

### 3.3 적 호버 시 예상 수치 (`_damage_preview_text_for_hover`)

들어가는 정보:

- **공격 피해**: `MechaEntity.get_preview_outgoing_damage(skill)`  
  `= skill.skill_damage × GameState.attack_multiplier × (손상 파츠 0.7, 정상 1.0)`
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

### 3.4 예고 라벨 우선순위

`_update_enemy_preview()`에서:

1. `enemy.is_defeated()` → 빈 텍스트.
2. `_pending_skill != null && 호버 중인 적` → §3.3 예상 피해 텍스트.
3. `next_actions`가 있으면 → `예고: 스킬1 → 스킬2`.
4. 그 외 → 빈 텍스트.

---

## 4. 상단 중앙 — TurnLabel

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

## 5. 하단 — 행동력 / 스킬 / 상태

| 요소 | 노드 | 비고 |
|------|------|-----|
| 행동력 오브 | `ActionOrbsRow` (HBox of `ColorRect`) | 남은 액션만큼 초록, 나머지는 회색. 최대치는 `core_action_count`. |
| 스킬 버튼 | `SkillContainer` (HBox of `Button`) | 텍스트: `"스킬명 [AP비용]"`. 대기 중인 스킬은 **시각 강조만** (`_style_skill_button_pending`, normal/hover/pressed 스타일박스에 적용). |
| 상태 메시지 | `SelectionStatus` | `"스킬을 선택하세요."` / `"「X」 — 대상 적을 클릭하세요"` / `"「X」 — 내 메카(왼쪽 패널)을 클릭하세요"` / `"「X」 → 타겟이름"`. |

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
| AP 부족 | ✅ `disabled = true` |
| 파츠 파괴 (`is_broken()`) | ✅ `disabled = true` |

### 5.2 자기 대상 클릭 영역 (`_player_target_catcher`)

자기 대상 스킬(SELF 타겟) 선택 시 `PlayerColumn` 하단에 시각화된 클릭 영역이 나타난다.

| 상태 | `flat` | 텍스트 | 스타일 |
|------|-------|-------|-------|
| 비활성 (평소) | `true` | 없음 | 없음, `mouse_filter = IGNORE` |
| **활성** (SELF 스킬 선택 시) | `false` | **"내 메카 클릭"** | 녹색 점선 박스 (`_style_player_target_catcher_active`) |

- 활성 상태: `_set_player_self_target_pending(true)` → `mouse_filter = STOP` + 녹색 점선 스타일 적용.
- 비활성 상태: `_clear_player_target_catcher_style()` → `flat = true`, `mouse_filter = IGNORE`.

---

## 6. 신호·이벤트 연동

| 발신 | 수신 | 목적 |
|------|------|-----|
| `CombatUI.skill_selected(skill, target)` | `TurnManager.on_skill_selected` | 스킬 실제 사용 |
| `TurnManager.player_action_required(skills, enemies, ap)` | `CombatUI.on_player_action_required` | UI 재구성 |
| `EventBus.hp_changed(entity, new, max)` | `CombatUI._on_hp_changed` | 적 = 카드 갱신, `GameState` = 자기 프리뷰 갱신 |
| `EventBus.shield_changed(...)` | `CombatUI._on_shield_changed` | 동일 |
| `EventBus.skill_used(entity, skill)` | `CombatUI._on_skill_used_global` | 적 예고 라벨 갱신 |

---

## 7. 디자인 결정 요약

- **모든 스킬이 명시적 타겟팅**: 즉시 발동은 폐기 (광역/패시브가 생기면 별도 분기).
- **스킬 버튼은 타겟 확정 전까지 항상 활성**: 대기 스킬 강조는 시각만, `disabled`는 AP부족·파괴 시만.
- **숫자는 바 위 오버레이**: 행 높이를 절약하면서 가독성은 outline으로 확보.
- **예상 수치는 단일 라벨**: 적 카드 상단의 "예고" 라벨을 호버 시 일시적으로 점령. 둘이 충돌하지 않도록 `_pending_skill` 유무로 분기.
- **회복량은 실제 적용량**: 표시 = 코어 최대치로 클램프 후 값 (사용자가 "오버힐"을 미리 인지).
- **공격 손상 보정**: 손상 파츠 스킬은 표시도 ×0.7 반영해서 실제와 동일.
- **자기 대상 클릭 영역**: 별도 캐처 박스(녹색 점선)로 시각화. 캐릭터 일러스트 추가 시 `PlayerColumn` 전체 테두리 방식으로 재검토.

---

## 8. 향후 작업

- [ ] **`MechStatusPanel` 구현** — 블록형 십자 레이아웃 + 상태 색상 코딩 + 파츠명 truncate.
  - `PartSocketUI`와 별개의 씬으로 분리하거나 `CombatUI.gd` 내 런타임 생성.
  - 기존 `PartsLabels` 텍스트 VBox 제거.
- [ ] **파츠 저격 예고 하이라이트** — `SkillData.target_slot` 필드 추가 및 `EventBus.enemy_snipe_preview_changed` 시그널 구현 후 `MechStatusPanel._set_snipe_preview()` 연결.
- [ ] **파괴 슬롯 ✕ 오버레이** — `is_broken()` 시 반투명 레이어 + "✕" 라벨 표시.
- [ ] 적 카드 폭이 좁을 때 예상 피해 라벨의 줄바꿈(`autowrap_mode`) 적용 검토.
- [ ] 예고 / 예상 피해 라벨을 두 줄(VBox)로 분리해 동시에 보여줄지 검토.
- [ ] AP 부족·손상 등으로 비활성된 스킬 버튼에 사유 툴팁 표시.
- [ ] `Affix`(반격 본능 등) 적용 시 예상 수치 보정.
- [ ] 자기 대상 클릭 영역에 `PlayerColumn` 전체 테두리 강조 검토 (현재는 캐처 박스만).

---

## 9. 변경 이력

- 2026-05-18 — §4 TurnLabel·펜딩 스킬 흐름·자기 대상 캐처 명세 추가. §2.3 MechStatusPanel 추가. 섹션 번호 재정렬.
- 2026-05-14 — 최초 작성. 적 HP/쉴드 오버레이, 예상 피해/회복, 자기 대상 2단계 클릭 발동.
