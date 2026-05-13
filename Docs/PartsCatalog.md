---
tags: [project/project-mecha, document/parts-catalog, status/in-progress]
status: in-progress
created: 2026-05-12
updated: 2026-05-13
---

# 파츠 카탈로그 (Parts Catalog)

> [!info] 관련 문서
> - 시스템 명세: [[PartsSystem]]
> - Affix 상세: [[AffixSystem]]

> [!note] 작성 기준
> - **base 수치**: stat_multiplier 적용 전 기준값
> - **드롭 가중치**: 상대값. 높을수록 자주 등장 (15+ 흔함 / 8~14 보통 / 3~7 드묾 / 1~2 매우 드묾)
> - **affix 풀**: 이 파츠에 등장 가능한 affix 목록. 풀 내 균등 확률. 상세는 [[AffixSystem]] 참고
> - 총기류는 좌우 공용 (ARM_L·ARM_R 동일 스킬, 별도 .tres 파일)

---

## ARM_L — 좌팔 (8종)

> 주력 공격 슬롯. 총기류 4종(공용) + 근접무기 4종(ARM_L 전용).

### 총기류 (좌)

| 파일명 | 이름 | 스킬 | base damage | base weight | 드롭 가중치 |
|--------|------|------|------------|------------|-----------|
| `arm_l_m88` | M-88 캐논 (좌) | M-88 포격 | 38 | 25 | 15 |
| `arm_l_gr21` | GR-21 기관포 (좌) | 기관포 연사 | 9×5 | 18 | 14 |
| `arm_l_lg40` | LG-40 레일건 (좌) | LG 관통 포격 | 42 | 22 | 8 |
| `arm_l_ml7` | ML-7 유도 미사일 (좌) | ML 유도 공격 | 18×3 | 20 | 10 |

**스킬 상세**

| 이름 | 행동력 | 설명 |
|------|--------|------|
| M-88 포격 | 1 | 단일 타겟 고화력 단발 공격 |
| 기관포 연사 | 1 | 단일 타겟 5연발. 1발 수치 낮음, 총합 높음 |
| LG 관통 포격 | 2 | 단일 타겟 공격. 방어력 30% 무시 |
| ML 유도 공격 | 1 | 적 1~3명에게 피해 분산. 타겟이 1명이면 전체 집중 |

**affix 풀**

| 파츠 | affix 풀 |
|------|---------|
| M-88 캐논 | `overload` `serious_punch` `greedy` `kernel_panic` `meticulous` `lifedrain` `backdoor` |
| GR-21 기관포 | `mindless` `lifedrain` `momentum` `gambler` `productive` `undefined_behavior` |
| LG-40 레일건 | `overload` `greedy` `meticulous` `serious_punch` `kernel_panic` `backdoor` |
| ML-7 미사일 | `mindless` `lifedrain` `backdoor` `counter_instinct` `gambler` `momentum` |

---

### 근접무기 (ARM_L 전용)

| 파일명 | 이름 | 스킬 | base damage | base weight | 드롭 가중치 |
|--------|------|------|------------|------------|-----------|
| `arm_l_vhf9` | VHF-9 고진동 발열 블레이드 (좌) | 발열 참격 | 30 | 16 | 9 |
| `arm_l_ew4` | EW-4 고전압 충격 와이어 (좌) | 전격 포박 | 22 | 12 | 8 |
| `arm_l_yb20` | YB-20 유압 파쇄기 (좌) | 유압 파쇄 | 58 | 30 | 4 |
| `arm_l_rd9` | RD-9 회전 굴삭기 (좌) | 회전 굴삭 | 16×3 | 26 | 6 |

**스킬 상세**

| 이름 | 행동력 | 설명 |
|------|--------|------|
| 발열 참격 | 1 | 근접 공격 + 화상(BURN) 1턴 부여. 화상은 적 턴 시작 시 추가 피해 |
| 전격 포박 | 1 | 전격 공격 + 적 행동력 -1 (다음 턴 스킬 1회 사용 불가) |
| 유압 파쇄 | 2 | 극단발 최고화력. 방어력 20% 무시. 충격 시 섀시 흔들림(선딜 있음) |
| 회전 굴삭 | 1 | 3연속 관통 공격. 연속 명중 시 손상도 추가 -1 |

**affix 풀**

| 파츠 | affix 풀 |
|------|---------|
| VHF-9 발열 블레이드 | `overload` `backdoor` `kernel_panic` `lifedrain` `greedy` `zombie_process` |
| EW-4 충격 와이어 | `backdoor` `counter_instinct` `productive` `zombie_process` `meticulous` `momentum` |
| YB-20 유압 파쇄기 | `overload` `serious_punch` `greedy` `kernel_panic` `meticulous` `gambler` |
| RD-9 회전 굴삭기 | `mindless` `momentum` `lifedrain` `gambler` `overload` `zombie_process` |

---

## ARM_R — 우팔 (8종)

> 보조 무장 / 방어 슬롯. 총기류 4종(공용) + 방어·반응 4종(ARM_R 전용).

### 총기류 (우)

총기류 4종은 ARM_L과 스킬·수치 동일. 슬롯만 다름.

| 파일명 | 이름 | 스킬 | base damage | base weight | 드롭 가중치 |
|--------|------|------|------------|------------|-----------|
| `arm_r_m88` | M-88 캐논 (우) | M-88 포격 | 38 | 25 | 15 |
| `arm_r_gr21` | GR-21 기관포 (우) | 기관포 연사 | 9×5 | 18 | 14 |
| `arm_r_lg40` | LG-40 레일건 (우) | LG 관통 포격 | 42 | 22 | 8 |
| `arm_r_ml7` | ML-7 유도 미사일 (우) | ML 유도 공격 | 18×3 | 20 | 10 |

> affix 풀은 ARM_L 총기류와 동일.

---

### 방어·반응 (ARM_R 전용)

| 파일명 | 이름 | 스킬 | base 수치 | base weight | 드롭 가중치 |
|--------|------|------|----------|------------|-----------|
| `arm_r_cp40` | CP-40 복합 방호판 (우) | 중장갑 전개 | defense 42 | 28 | 12 |
| `arm_r_emf3` | EMF-3 전자기 배리어 (우) | EMF 배리어 | shield 35 | 16 | 11 |
| `arm_r_gdclaw` | 포식 집게팔 (우) | 요격 | defense 26, counter | 18 | 6 |
| `arm_r_gdtendril` | 흡취 침지팔 (우) | 에너지 흡취 | damage 22, heal 40% | 15 | 5 |

**스킬 상세**

| 이름 | 행동력 | 설명 |
|------|--------|------|
| 중장갑 전개 | 1 | 1턴 간 피해 감소 + 방어 수치 부여. 가장 단순하고 가장 두꺼운 방어 |
| EMF 배리어 | 1 | 쉴드 생성. 다음으로 받는 공격 1회를 완전 차단 후 쉴드 소멸 |
| 요격 | 1 | 다음 적 공격 1회를 집게로 낚아채 차단 + 즉시 반격 (반격 피해 = defense 수치) |
| 에너지 흡취 | 1 | 기계신 모방 침지로 적 코어를 찌름. 피해를 주고 피해량의 40%를 코어 HP로 회복 |

> [!note] 포식 집게팔 / 흡취 침지팔
> 기계신의 포획·흡수 기관을 역설계해 복제한 파츠. 일반 병기와 다른 원리로 작동.
> 스캐빈저들 사이에서 "GD형 팔"로 불림.

**affix 풀**

| 파츠 | affix 풀 |
|------|---------|
| CP-40 복합 방호판 | `meticulous` `greedy` `counter_instinct` `zombie_process` `evolution_lord` `kernel_panic` |
| EMF-3 전자기 배리어 | `meticulous` `counter_instinct` `productive` `evolution_lord` `zombie_process` `backdoor` |
| 포식 집게팔 | `counter_instinct` `overload` `backdoor` `kernel_panic` `gambler` `zombie_process` |
| 흡취 침지팔 | `lifedrain` `overload` `kernel_panic` `greedy` `gambler` `serious_punch` |

---

## BACK — 등 (8종)

> 백팩 슬롯. 전원 액티브 스킬. 버프 부여 또는 즉시 회복 효과 위주.

| 파일명 | 이름 | 스킬 | 유형 | base 수치 | base weight | 드롭 가중치 |
|--------|------|------|------|----------|------------|-----------|
| `back_sd7` | SD-7 방어막 발생기 | 방어막 전개 | 액티브 | 쉴드 버프 3턴 (+12/턴) | 14 | 13 |
| `back_ex9` | EX-9 강화 외골격 팩 | 외골격 강화 | 액티브 | max HP +35·즉시 HP +35 | 20 | 12 |
| `back_tb3` | TB-3 전술 부스터 팩 | 부스터 점화 | 액티브 | AP +1 (1턴) | 12 | 10 |
| `back_nr5` | NR-5 나노 수복기 | 나노 수복 | 액티브 | HP 회복 버프 3턴 (+10/턴) | 10 | 13 |
| `back_pa6` | PA-6 출력 증폭기 | 출력 증폭 | 액티브 | 스킬 수치 버프 3턴 (+15%) | 16 | 8 |
| `back_md2` | MD-2 정비 드론 팩 | 드론 정비 | 액티브 | 전 파츠 손상도 +2 즉시 | 11 | 9 |
| `back_tr4` | TR-4 전술 중계기 | 중계 강화 | 액티브 | 버프 지속 +2턴 | 13 | 7 |
| `back_fr1` | FR-1 현장 수리 키트 | 현장 수리 | 액티브 | 손상도 max 복구 | 9 | 8 |

**스킬 상세**

| 이름 | 행동력 | 설명 |
|------|--------|------|
| 방어막 전개 | 1 | 3턴간 매 턴 시작 시 쉴드 +12 자동 생성 (버프) |
| 외골격 강화 | 1 | 코어 최대 HP +35 즉시 증가, HP +35 회복 (이번 런 지속) |
| 부스터 점화 | 0 | 이번 턴 행동력 +1. 행동력 소모 없이 사용 |
| 나노 수복 | 1 | 3턴간 매 턴 시작 시 코어 HP +10 자동 회복 (버프) |
| 출력 증폭 | 1 | 3턴간 전 슬롯 스킬 수치 +15% (버프) |
| 드론 정비 | 1 | 장착된 모든 파츠 손상도 즉시 +2 회복 |
| 중계 강화 | 1 | 내 메카에 활성화된 버프 전체 남은 지속 턴 +2 연장 |
| 현장 수리 | 1 | 선택 파츠 손상도 즉시 max 완전 복구 |

> [!note]
> **MD-2 vs FR-1**: 드론 정비는 전 파츠 +2 분산 복구 (여러 파츠가 조금씩 닳은 경우 유리), 현장 수리는 선택 파츠 완전 복구 (중요 파츠 집중 수리). 상황에 따라 선택.
>
> **부스터 점화**: 행동력 0 소모로 사용 가능하지만 손상도는 -1 차감됨.

**affix 풀**

| 파츠 | affix 풀 |
|------|---------|
| SD-7 방어막 발생기 | `meticulous` `gambler` `greedy` `counter_instinct` `zombie_process` `undefined_behavior` |
| EX-9 강화 외골격 팩 | `meticulous` `greedy` `serious_punch` `kernel_panic` `lifedrain` `evolution_lord` |
| TB-3 전술 부스터 팩 | `productive` `momentum` `evolution_lord` `meticulous` `gambler` `undefined_behavior` |
| NR-5 나노 수복기 | `meticulous` `greedy` `serious_punch` `gambler` `backdoor` `counter_instinct` |
| PA-6 출력 증폭기 | `greedy` `overload` `backdoor` `evolution_lord` `momentum` `gambler` |
| MD-2 정비 드론 팩 | `meticulous` `productive` `zombie_process` `greedy` `undefined_behavior` `evolution_lord` |
| TR-4 전술 중계기 | `evolution_lord` `meticulous` `momentum` `greedy` `backdoor` `productive` |
| FR-1 현장 수리 키트 | `meticulous` `evolution_lord` `zombie_process` `greedy` `productive` `kernel_panic` |

---

## LEG — 다리 (8종)

> 다리 슬롯. 전원 액티브 스킬. 방어·반격·기동 버프 위주.

| 파일명 | 이름 | 스킬 | 유형 | base 수치 | base weight | 드롭 가중치 |
|--------|------|------|------|----------|------------|-----------|
| `leg_rampart8` | RAMPART-8 | 중장갑 전개 | 액티브 | 이번 전투 방어력 +20 (지속) | 28 | 13 |
| `leg_porteur4` | PORTEUR-4 | 중심 잡기 | 액티브 | 2턴간 피해 감소 10%, 하중 패널티 무효 | 18 | 11 |
| `leg_bastion1` | BASTION-1 | 시즈모드 돌입 | 액티브 | 공격력 +35%, AP -1/턴 | 22 | 7 |
| `leg_springer6` | SPRINGER-6 | 반격 준비 | 액티브 | 다음 피격 1회 확정 반격 (방어 수치 40%) | 20 | 9 |
| `leg_spearhead2` | SPEARHEAD-2 | 선제 도약 | 액티브 | 즉시 무료 스킬 1회 추가 사용 | 16 | 6 |
| `leg_dampfer5` | DAMPFER-5 | 충격 완충 | 액티브 | 3턴간 받는 피해 20% 감소 (버프) | 24 | 12 |
| `leg_harrier7` | HARRIER-7 | 고기동 | 액티브 | 3턴간 회피율 +20% (버프) | 14 | 10 |
| `leg_juke3` | JUKE-3 | 반응 회피 | 액티브 | 다음 적 공격 1회 완전 회피 | 15 | 8 |

**스킬 상세**

| 이름 | 행동력 | 설명 |
|------|--------|------|
| 중장갑 전개 | 1 | 이번 전투 방어력 +20 영구 증가. 사용 후 재사용 불가 |
| 중심 잡기 | 1 | 2턴간 받는 피해 -10%, 하중 초과 패널티 무효 |
| 시즈모드 돌입 | 0 | 시즈모드 ON/OFF 전환. ON 시 공격력 +35%, 매 턴 행동력 -1. 손상도 -1 소모 |
| 반격 준비 | 0 | 다음 피격 1회에 즉시 확정 반격. 반격 피해 = 방어 수치 × 40% |
| 선제 도약 | 0 | 즉시 스킬 1회 무료 추가 사용. 지정한 스킬은 행동력·손상도 소모 없이 발동 |
| 충격 완충 | 1 | 3턴간 받는 피해 20% 감소 (버프) |
| 고기동 | 1 | 3턴간 회피율 +20% (버프) |
| 반응 회피 | 1 | 다음으로 받는 적 공격 1회를 완전 회피. 적 예고 행동을 보고 판단 |

> [!note] 시즈모드 전략
> BASTION-1 시즈모드 ON 상태에서 매 턴 행동력 -1이 누적되므로 장기전보다 단기 화력 집중에 적합.
> 행동력이 0이 되면 스킬 사용 불가 — 켜는 타이밍과 끄는 타이밍이 핵심 판단.
>
> **RAMPART-8**: 이번 전투 방어력 +20 영구 적용. 일찍 쓸수록 이득이 크다.
>
> **SPRINGER-6 vs JUKE-3**: 반격 준비는 확정 반격, JUKE-3는 완전 회피. 전투 예상 피해에 따라 선택.
>
> **HARRIER-7 vs JUKE-3**: 고기동(확률 회피 버프)은 여러 턴에 걸쳐 작동하지만 불확실. 반응 회피(확정 1회 완전 회피)는 확실하지만 행동력 소모.

**affix 풀**

| 파츠 | affix 풀 |
|------|---------|
| RAMPART-8 | `meticulous` `greedy` `overload` `serious_punch` `zombie_process` `counter_instinct` |
| PORTEUR-4 | `meticulous` `productive` `counter_instinct` `gambler` `backdoor` `zombie_process` |
| BASTION-1 | `overload` `greedy` `kernel_panic` `mindless` `gambler` `serious_punch` |
| SPRINGER-6 | `counter_instinct` `overload` `gambler` `zombie_process` `backdoor` `kernel_panic` |
| SPEARHEAD-2 | `serious_punch` `overload` `momentum` `gambler` `kernel_panic` `lifedrain` |
| DAMPFER-5 | `meticulous` `greedy` `counter_instinct` `zombie_process` `backdoor` `kernel_panic` |
| HARRIER-7 | `productive` `counter_instinct` `gambler` `zombie_process` `meticulous` `backdoor` |
| JUKE-3 | `counter_instinct` `meticulous` `productive` `backdoor` `momentum` `zombie_process` |
