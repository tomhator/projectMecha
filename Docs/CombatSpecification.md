---
tags: [project/project-mecha, document/specification]
status: in-progress
version: 0.1
created: 2026-05-27
updated: 2026-05-27
---

# 전투 시스템 명세 (Combat Specification)

> [!info] 관련 문서
> - 전체 구조: [[GameDesignDocument]]
> - 파츠/슬롯: [[PartsSystem]]
> - Affix 상세: [[AffixSystem]]
> - 파츠 카탈로그: [[PartsCatalog]]
> - 전투 UI: [[UI/CombatScreen]]

---

## 1. 데모 전투 기준

- 전투는 플레이어 턴과 적 턴이 교대한다.
- 플레이어 AP는 `코어 기본 AP + 장착 파츠 ap_contribution`으로 시작한다.
- 파츠 스킬은 모두 플레이어 턴에 직접 선택하는 액티브 스킬이다.
- `SkillData.SkillType.PASSIVE` 값은 저장 호환을 위해 유지하지만, 플레이어 파츠 스킬에서는 **유틸** 타입으로 표시하고 액티브처럼 사용한다.
- 기본 공격과 파츠 활용 어빌리티는 파츠 파괴와 무관하게 전투 안전판으로 남는다.

### 1.1 스킬 표시 순서

```
기본 공격 → 파츠 어빌리티 → ARM_L → ARM_R → EXTRA_ARM → BACK → LEG
```

`EXTRA_ARM`은 `evolution_lord` 조건을 만족할 때만 열린다.

---

## 2. 슬롯과 파츠 파괴

### 2.1 기본 슬롯

| 슬롯 | 코드값 | 허용 파츠 |
|------|--------|----------|
| ARM_L | `CoreSlot.ARM_L` / `TargetSlot.ARM_L` = 0 | ARM_L |
| ARM_R | `CoreSlot.ARM_R` / `TargetSlot.ARM_R` = 1 | ARM_R |
| BACK | `CoreSlot.BACK` / `TargetSlot.BACK` = 2 | BACK |
| LEG | `CoreSlot.LEG` / `TargetSlot.LEG` = 3 | LEG |
| EXTRA_ARM | `CoreSlot.EXTRA_ARM` / `TargetSlot.EXTRA_ARM` = 4 | ARM_L 또는 ARM_R |

### 2.2 EXTRA_ARM

- `evolution_lord`가 붙은 정상 BACK/ARM 파츠가 장착되어 있으면 열린다.
- 추가 슬롯 제공 파츠가 파괴/탈착/강탈되면 EXTRA_ARM 파츠는 즉시 탈착된다.
- 런 중 탈착 시 인벤토리에 공간이 있으면 이동한다.
- 런 중 인벤토리에 공간이 없으면 파손 처리 후 유실 로그를 남긴다.
- 거점에서는 창고 용량 제한이 없으므로 탈착 파츠를 창고로 돌린다.
- EXTRA_ARM 파츠에 `evolution_lord`가 있어도 슬롯은 중첩 확장되지 않는다.

---

## 3. 스킬 효과 처리

### 3.1 AP와 손상도

- 스킬 사용 시 해당 파츠 `durability -= 1`.
- `overload` affix가 있으면 총 `durability -= 2`.
- `productive`, `momentum`, `kernel_panic`, `grants_next_free_skill`은 스킬 사용 직전 동적 AP 비용에 반영한다.
- `grants_next_free_skill`로 무료화된 다음 스킬은 AP와 손상도를 소모하지 않는다.

### 3.2 구현 필드

`SkillData`는 아래 효과 필드를 전투 로직에서 읽는다.

| 필드 | 용도 |
|------|------|
| `buff_value` / `debuff_value` | 비율형 버프·디버프 수치 |
| `heal_from_damage_ratio` | 실제 피해량 기반 HP 회복 |
| `repairs_all_parts` | 장착 파츠 전체 내구도 +2 |
| `repairs_selected_part` | 선택 장착 파츠 내구도 최대 복구 |
| `extends_buffs` | 활성 버프 지속 턴 연장 |
| `grants_action` | 현재 턴 AP 증가 |
| `grants_next_free_skill` | 다음 1회 스킬 AP/손상도 무료 |
| `single_use_per_combat` | 전투당 1회 사용 제한 |

### 3.3 주요 스킬 계약

| 스킬 | 효과 |
|------|------|
| 방어형 `skill_defense` | 즉시 방어는 쉴드, 버프형 방어는 받는 피해 flat 감소 |
| 방어막 전개 | 3턴간 플레이어 턴 시작 시 쉴드 +12 |
| 나노 수복 | 3턴간 플레이어 턴 시작 시 HP +10 |
| 출력 증폭 | 3턴간 전 슬롯 스킬 수치 +15% |
| 중계 강화 | 활성 버프 전체 지속 +2턴 |
| 부스터 점화 | AP 0, 현재 턴 AP +1, 사용 파츠 손상도 -1 |
| 선제 도약 | 다음 1회 스킬 AP/손상도 소모 면제 |
| 현장 수리 | 전투 UI 파츠 HUD/메카 파츠를 클릭해 선택 파츠 완전 수리 |
| 드론 정비 | 장착된 모든 파츠 내구도 +2, 최대 내구도 초과 없음 |
| 외골격 강화 | 이번 런 동안 코어 최대 HP +35 및 HP +35 |
| 시즈모드 | 토글. ON 중 출력 +35%, 턴 AP -1, 다음 턴부터 매 턴 손상도 -1 |
| 회피/차단/반격 | 버프 상태로 저장하고 다음 피격 시 소모 |

---

## 4. 디버프

| 디버프 | 효과 |
|--------|------|
| BURN | 적 턴 시작 시 5 피해 |
| ATTACK_DOWN | 지속 중 적 공격력 -20% |
| AP_DOWN | 다음 적 행동 실행 시 AP -1 후 소모 |

`backdoor` 판정에서 위 상태는 모두 디버프로 인정한다.

---

## 5. Affix 구현 기준

기존 구현 유지:

- `meticulous`, `greedy`, `undefined_behavior`, `backdoor`, `counter_instinct`

구현된 신규/보강 효과:

- `productive`: 해당 파츠 스킬 AP -1.
- `overload`: 스킬 수치 +25%, 사용 시 손상도 총 -2.
- `gambler`: 실제 사용 시 0~+50% 랜덤 보정.
- `lifedrain`: 실제 피해량의 15% HP 회복.
- `momentum`: 같은 턴 정확히 두 번째 스킬 AP -1.
- `mindless`: 출력 -10%, 공격 hit 수 +3, 각 hit 타겟 랜덤.
- `serious_punch`: 해당 affix 파츠 사용 후 다음 파츠 스킬 +100%, 파츠별 전투 1회.
- `zombie_process`: 파츠 파괴 후 다음 플레이어 턴에 1회만 사용 가능, 미사용 시 턴 종료에 만료.
- `kernel_panic`: HP 30% 이하에서 출력 +30%, AP -1.
- `evolution_lord`: EXTRA_ARM 슬롯 제공.

---

## 6. 검증 기준

표준 검증:

```bash
bash Scripts/Validation/validate.sh
```

핵심 계약은 `Scripts/Validation/check_p0_combat_flows.gd`와 `Scripts/Validation/check_resource_integrity.gd`에서 검증한다.
