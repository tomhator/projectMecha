# 전투 화면 정의 (CombatScene / CombatUI)

> 본 문서는 전투 씬의 화면 구성·인터랙션·예상 수치 계산을 정의한다.
> `Docs/UI/HUD.md` §6은 전역 HUD 규칙만 다루므로, **전투 본문 규칙은 모두 이 문서를 기준**으로 한다.

---

## 1. 화면 레이아웃

```
┌────────────────────────────────────────────────────────────┐
│ RunStatusStrip  (층 / HP / 쉴드 / 크레딧 / 설정)            │ ← HUD.md §1
├────────────────────────────────────────────────────────────┤
│ BattleMargin (좌우 16, 상단 64, 하단 104)                  │
│ ┌──────────────────┬───────────────────────────────────┐   │
│ │ PlayerColumn ≈40%│ EnemyColumn ≈60% (200~500 클램프) │   │
│ │                  │                                   │   │
│ │ [내 메카]        │ [예고 라벨]                       │   │
│ │ 코어 이름        │ 적 이름                            │   │
│ │ 파츠 목록(VBox)  │ HP 바 + 숫자 오버레이             │   │
│ │ ── 예상 회복 ──  │ 쉴드 바 + 숫자 오버레이           │   │
│ │ [클릭 캐처 영역] │ (적 N개 가로 나열)                │   │
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
| `PartsLabels` | 슬롯별 장착 파츠 라벨 (VBox) |
| **`_player_preview_label`** (런타임 생성, 주황) | 자기 대상 스킬을 고른 뒤 클릭 캐처에 호버할 때 예상 회복량 표시 |
| **`_player_target_catcher`** (런타임 생성, 투명 Button) | 자기 대상 스킬 발동용 클릭 영역. 평소엔 `MOUSE_FILTER_IGNORE`. |

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

## 4. 하단 — 행동력 / 스킬 / 상태

| 요소 | 노드 | 비고 |
|------|------|-----|
| 행동력 오브 | `ActionOrbsRow` (HBox of `ColorRect`) | 남은 액션만큼 초록, 나머지는 회색. 최대치는 `core_action_count`. |
| 스킬 버튼 | `SkillContainer` (HBox of `Button`) | 텍스트: `"스킬명 [AP비용]"`. 대기 중인 스킬은 disabled + 녹색 강조 스타일(`_style_skill_button_pending`). |
| 상태 메시지 | `SelectionStatus` | `"스킬을 선택하세요."` / `"「X」 — 대상 적을 클릭하세요"` / `"「X」 — 내 메카(왼쪽 패널)을 클릭하세요"` / `"「X」 → 타겟이름"`. |

---

## 5. 신호·이벤트 연동

| 발신 | 수신 | 목적 |
|------|------|-----|
| `CombatUI.skill_selected(skill, target)` | `TurnManager.on_skill_selected` | 스킬 실제 사용 |
| `TurnManager.player_action_required(skills, enemies, ap)` | `CombatUI.on_player_action_required` | UI 재구성 |
| `EventBus.hp_changed(entity, new, max)` | `CombatUI._on_hp_changed` | 적 = 카드 갱신, `GameState` = 자기 프리뷰 갱신 |
| `EventBus.shield_changed(...)` | `CombatUI._on_shield_changed` | 동일 |
| `EventBus.skill_used(entity, skill)` | `CombatUI._on_skill_used_global` | 적 예고 라벨 갱신 |

---

## 6. 디자인 결정 요약

- **모든 스킬이 명시적 타겟팅**: 즉시 발동은 폐기 (광역/패시브가 생기면 별도 분기).
- **숫자는 바 위 오버레이**: 행 높이를 절약하면서 가독성은 outline으로 확보.
- **예상 수치는 단일 라벨**: 적 카드 상단의 "예고" 라벨을 호버 시 일시적으로 점령. 둘이 충돌하지 않도록 `_pending_skill` 유무로 분기.
- **회복량은 실제 적용량**: 표시 = 코어 최대치로 클램프 후 값 (사용자가 "오버힐"을 미리 인지).
- **공격 손상 보정**: 손상 파츠 스킬은 표시도 ×0.7 반영해서 실제와 동일.

---

## 7. 향후 작업

- [ ] 자기 대상 클릭 영역에 호버 시 테두리/배경 강조 (현재는 modulate만 가능).
- [ ] 적 카드 폭이 좁을 때 예상 피해 라벨의 줄바꿈(`autowrap_mode`) 적용 검토.
- [ ] 예고 / 예상 피해 라벨을 두 줄(VBox)로 분리해 동시에 보여줄지 검토.
- [ ] AP 부족·손상 등으로 비활성된 스킬 버튼에 사유 툴팁 표시.
- [ ] `Affix`(반격 본능 등) 적용 시 예상 수치 보정.

---

## 8. 변경 이력

- 2026-05-14 — 최초 작성. 적 HP/쉴드 오버레이, 예상 피해/회복, 자기 대상 2단계 클릭 발동.
