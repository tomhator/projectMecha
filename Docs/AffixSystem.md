---
tags: [project/project-mecha, document/affix-system, status/in-progress]
status: in-progress
created: 2026-05-12
updated: 2026-05-14
---

# Affix 시스템 (Affix System)

> [!info] 관련 문서
> - 시스템 명세: [[PartsSystem]]
> - 파츠별 affix 풀: [[PartsCatalog]]

> [!warning] 작업 전 읽기
> 이 문서는 두 가지를 다룬다.
> 1. **전체 Affix 목록** — ID·이름·효과
> 2. **파츠별 Affix 가중치** — 어떤 파츠에 어떤 affix가 잘 붙는지

---

## 설계 방향

- 각 파츠는 전체 affix 풀의 **부분집합**을 affix 후보(`affix_pool`)로 가진다.
- 후보 내 affix는 **균등 확률** — 가중치 구분 없음.
- affix 수치(예: +25%)는 `stat_multiplier`와 무관한 **고정값**.
- affix 중복 방지: 이미 붙은 ID를 후보 목록에서 제거 후 나머지에서 선택.
- 후보 외 affix는 등장하지 않는다.

---

## 1. 전체 Affix 목록

| ID | 이름 | 효과 | 비고 |
|----|------|------|------|
| `evolution_lord` | 진화 군주 | 팔 슬롯 +1 | BACK·ARM 전용 |
| `mindless` | 무지성 | 스킬 수치 -10%, 공격 횟수 +3, 공격마다 타겟 랜덤 | |
| `greedy` | 과한 욕심 | 무게 +5, 스킬 수치 +10% | |
| `productive` | 생산성 향상 | 무게 -3, 행동력 비용 -1 | |
| `meticulous` | 꼼꼼한 설계 | 최대 손상도 +10% | |
| `overload` | 과부하 모드 | 스킬 수치 +25%, 스킬 사용 시 손상도 -2 | |
| `counter_instinct` | 반격 본능 | 피격 후 다음 스킬 수치 +20% (1턴) | |
| `gambler` | 도박사 | 스킬 수치 0~+50% 랜덤 | |
| `lifedrain` | 흡수 코팅 | 스킬로 준 피해의 15% HP 회복 | |
| `momentum` | 탄력 | 같은 턴 두 번째 스킬 사용 시 행동력 비용 -1 | |
| `serious_punch` | 진심펀치 | 1회용. 사용 시 다음 스킬 수치 +100% | |
| `zombie_process` | 좀비 프로세스 | 파츠 파괴되어도 1턴 더 작동 후 소멸 | |
| `kernel_panic` | 커널 패닉 | 코어 HP 30% 이하 시 스킬 수치 +30%, 행동력 비용 -1 | |
| `undefined_behavior` | 개발자도 모름 | 매 턴 시작 시 스킬 수치 랜덤 (-20% ~ +60%) | |
| `backdoor` | 백도어 | 적이 디버프 상태일 때 이 파츠 스킬 수치 +25% | |

---

## 2. Affix 등장 규칙

모든 파츠는 드롭 시 자신의 **affix_pool**에서 균등 랜덤으로 롤한다.
affix_pool은 파츠마다 다르게 정의되며, [[PartsCatalog]]의 각 파츠 항목에 명시된다.
pool 내에서 가중치 차이는 없다 — 후보에 있으면 동등한 확률로 등장.

### 예외 제약

| affix | 제약 |
|-------|------|
| `evolution_lord` (진화 군주) | BACK·ARM 슬롯 파츠에만 등장. 추가되는 팔 슬롯 종류는 자유 선택 |

---

## 3. Affix 적용 트리거

각 affix가 **언제, 어떻게** 발동하는지를 정의한다. CombatManager 구현 기준점.

### 트리거 유형

| 유형 | 발동 시점 |
|------|---------|
| `on_equip` | 파츠 장착 시 1회 (조립 씬 → 런 시작) |
| `modify_skill` | 해당 파츠 스킬 사용 직전, 출력 수치 보정 |
| `on_skill_hit` | 스킬이 적에게 피해를 줬을 때 |
| `on_hit_received` | 내가 적의 공격을 받았을 때 |
| `on_turn_start` | 내 턴 시작 시 (행동 전) |
| `conditional` | 조건 충족 여부를 매 스킬 사용 전 체크 |
| `post_broken` | 파츠가 파괴(`is_broken()`)된 직후 특수 처리 |

### 3.1 affix별 트리거 상세

| ID | 트리거 | 적용 로직 |
|----|--------|---------|
| `evolution_lord` | `on_equip` | 팔 슬롯 추가. **데모 미구현 (TODO)** |
| `mindless` | `modify_skill` | `bonus_sum += -0.10` + 공격 횟수 +3 + 타겟 강제 랜덤 |
| `greedy` | `on_equip` + `modify_skill` | PartsFactory에서 `parts_weight += 5` 직접 수정 / `bonus_sum += +0.10` |
| `productive` | `on_equip` | PartsFactory에서 `parts_weight -= 3` 직접 수정 (최소 1). 이 파츠 스킬 AP 비용 -1 (최소 0) |
| `meticulous` | `on_equip` | 이 파츠 `max_durability` × 1.10, 반올림 (COMMON 3→3, RARE 5→6, EPIC 7→8). PartsFactory에서 affix 롤 후 적용 |
| `overload` | `modify_skill` | `bonus_sum += +0.25` + 스킬 사용 후 `durability` 추가 -1 |
| `counter_instinct` | `on_hit_received` | `counter_instinct_active = true` 설정. **이 파츠의** 다음 스킬 발동 시에만 `bonus_sum += +0.20` 적용 후 초기화. 다른 파츠 스킬에는 영향 없음 |
| `gambler` | `modify_skill` | `bonus_sum += randf_range(0.0, 0.5)` |
| `lifedrain` | `on_skill_hit` | `GameState.hp += dealt_damage × 0.15` (반올림, 코어 HP 최대치 초과 불가) |
| `momentum` | `conditional` | 같은 턴 **정확히 두 번째** 스킬 사용 시에만 AP 비용 -1 (최소 0). 세 번째 이후엔 미적용. 턴 시작 시 카운터 초기화 |
| `serious_punch` | `modify_skill` + 소진 | 사용 시 `serious_punch_pending = true` 설정. **다음으로 사용하는 어느 파츠 스킬이든** 해당 파츠의 `bonus_sum += +1.00` 적용 후 소진 (`serious_punch_pending = false`). 1회만 발동 |
| `zombie_process` | `post_broken` | `durability` 가 0이 되는 순간(원인 무관) `zombie_active = true`. **다음 플레이어 턴에 1회만** 스킬 사용 가능. 사용하면 즉시 `zombie_active = false`(영구 비활성화). 그 턴 안에 사용하지 않아도 턴 종료 시 비활성화 |
| `kernel_panic` | `conditional` | `GameState.hp / GameState.max_hp ≤ 0.3` 이면 `bonus_sum += +0.30` + AP -1 |
| `undefined_behavior` | `on_turn_start` | 이 파츠 전용 `turn_modifier = randf_range(-0.20, 0.60)`. 해당 턴 `modify_skill` 시 `bonus_sum += turn_modifier` |
| `backdoor` | `conditional` | 현재 타겟 적에게 **디버프**가 1개 이상 있으면 `bonus_sum += +0.25`. 디버프 = BURN(화상), 행동력 감소, 그 외 추가 확정된 상태이상 |

### 3.2 수치 보정 적층 규칙

같은 파츠에 보정 요소가 여러 개일 경우 **덧셈 적층**:

```
bonus_sum = Σ(각 affix의 수치 보정값)   # 음수 포함
final = round(base × stat_multiplier × max(1.0 + bonus_sum, 0.1))

# 하중 초과 패널티는 위 계산 후 별도 후처리 (LEG 파츠 스킬에만 적용)
if is_overloaded() and part.parts_type == LEG:
    final = round(final × 0.8)
```

**예시**

| 구성 | 계산 | 결과 |
|------|------|------|
| `mindless` (-10%) + `overload` (+25%) | 1.0 + (-0.10 + 0.25) = 1.15 | base × stat × 1.15 |
| `greedy` (+10%) + `kernel_panic` (+30%) + `backdoor` (+25%) | 1.0 + 0.65 = 1.65 | base × stat × 1.65 |
| `undefined_behavior` 최악 (-20%) + `mindless` (-10%) | 1.0 - 0.30 = 0.70 | base × stat × 0.70 |

- `undefined_behavior`의 `turn_modifier`도 동일하게 `bonus_sum`에 합산.
- `counter_instinct`·`serious_punch`의 **임시 버프**도 해당 스킬 발동 시 `bonus_sum`에 추가 후 발동 종료 시 제거.
- AP 비용 보정(예: `productive` -1)은 수치 보정과 무관하게 **별도 정수 합산** 후 최소 0으로 클램프.
- 최종 수치 최소 클램프: 1 (0이 되면 공격 무의미).

### 3.3 구현 노트

- **런타임 상태 플래그 필요 목록** (CombatManager 딕셔너리 또는 PartsData 필드로 관리):
  - `counter_instinct_active: bool` — 파츠별
  - `serious_punch_pending: bool` — 전역 (어느 파츠 스킬에든 적용)
  - `zombie_active: bool` — 파츠별
  - `undefined_behavior_modifier: float` — 파츠별, 매 턴 갱신
- `mindless`의 "공격 횟수 +3": 다중 히트 스킬은 히트 수 +3, 단발 스킬은 동일 수치로 3회 추가 랜덤 타겟 공격. 모든 공격에 동일한 `final` 수치 적용 (bonus_sum에 -0.10 포함).
- `meticulous` ×1.10 반올림: PartsFactory에서 affix 롤 완료 후 해당 affix가 있으면 `max_durability = roundi(max_durability * 1.10)` 적용.
- `greedy`/`productive` 무게 보정: PartsFactory에서 affix 롤 완료 후 `parts_weight` 직접 수정. 최솟값 1.
- `productive` AP -1은 이 파츠 스킬에만 적용 (전역 AP 감소 아님).
