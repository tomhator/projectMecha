---
tags: [project/project-mecha, document/parts-system, status/in-progress]
status: in-progress
version: 0.2
created: 2026-05-11
updated: 2026-05-11
---

# 파츠 시스템 명세 (Parts System Specification)

> [!info] 관련 문서
> - GDD 전체: [[GameDesignDocument]]
> - 스킬 목록: [[SkillData]] (Resources/Skills/)

---

## 1. 슬롯 체계

메카는 코어(Core)를 중심으로 4개의 파츠 슬롯을 가진다. 슬롯 간 스킬 타입 제한은 없다.

| 슬롯 | 코드값 | 위치 | 권장 스킬 성향 | 고유 특징 |
|------|--------|------|-------------|---------|
| **ARM_L** | `PartsType.ARM_L` (0) | 섀시 좌측 | 공격, 방어 | 주력 무장 슬롯 |
| **ARM_R** | `PartsType.ARM_R` (1) | 섀시 우측 | 공격, 방어 | 보조 무장 / 방어 슬롯 |
| **BACK** | `PartsType.BACK` (2) | 섀시 등 | 방어, 회피, 공격 | 지원 / 패시브 슬롯 |
| **LEG** | `PartsType.LEG` (3) | 섀시 하단 | 방어, 버프·디버프, 회복 | 조건 반응형 슬롯 |

> [!note]
> "권장 성향"은 파츠 풀 설계 방향이지 장착 제한이 아니다. 어떤 슬롯에든 어떤 파츠도 장착 가능.

---

## 2. 등급 체계

### 2.1 등급 정의

| 등급 | 코드값 | 수량 | 획득처 | 특징 |
|------|--------|------|-------|------|
| **COMMON** | `PartsGrade.COMMON` (0) | 12개 | 일반 전투 보상 | 기본 스킬, affix 0~1개 |
| **RARE** | `PartsGrade.RARE` (1) | 6개 | 엘리트 전투, 상자 | 고급 스킬, affix 1~2개 |
| **EPIC** | `PartsGrade.EPIC` (2) | 6개 | 보스/엘리트, 상자 | 전용 스킬, affix 2~3개 |

### 2.2 슬롯별 등급 배분

| 슬롯 | COMMON | RARE | EPIC | 합계 |
|------|--------|------|------|------|
| ARM_L | 3 | 2 | 1 | 6 |
| ARM_R | 3 | 2 | 1 | 6 |
| BACK | 3 | 1 | 2 | 6 |
| LEG | 3 | 1 | 2 | 6 |
| **합계** | **12** | **6** | **6** | **24** |

> ARM은 RARE가 많아 전투 선택지가 풍부하고, BACK/LEG는 EPIC이 많아 빌드 핵심 파츠로 기능한다.

---

## 3. 랜덤 롤 시스템

> [!important] 핵심 설계 방향
> 파츠를 루팅할 때마다 수치와 affix가 달라진다. 같은 이름의 파츠라도 성능이 다르다.  
> 스킬 종류는 파츠에 고정 — 유저가 "어떤 파츠를 노릴지" 방향성을 잡을 수 있다.

### 3.1 수치 랜덤 범위

파츠를 생성할 때, 기준 수치(base) 대비 아래 범위에서 랜덤 롤한다.

| 등급 | 수치 범위 | 예시 (base 30) |
|------|----------|--------------|
| COMMON | base × 0.80~1.00 | 24~30 |
| RARE | base × 0.90~1.20 | 27~36 |
| EPIC | base × 1.10~1.50 | 33~45 |

```
# 구현 예시 (GDScript)
func roll_stat(base: float, grade: PartsGrade) -> float:
    var ranges = {
        PartsGrade.COMMON: [0.80, 1.00],
        PartsGrade.RARE:   [0.90, 1.20],
        PartsGrade.EPIC:   [1.10, 1.50],
    }
    var r = ranges[grade]
    return base * randf_range(r[0], r[1])
```

### 3.2 Affix 시스템

Affix는 파츠 생성 시 무작위로 추가되는 보너스 속성이다.

#### Affix 개수 (생성 시 랜덤)

| 등급 | Affix 개수 |
|------|-----------|
| COMMON | 0 또는 1 (50/50) |
| RARE | 1 또는 2 (50/50) |
| EPIC | 2 또는 3 (50/50) |

#### Affix 풀

등급에 따라 뽑을 수 있는 Affix가 다르다. 상위 등급은 하위 등급 Affix도 포함.

**COMMON 이상 (기본 Affix)**

| ID | 이름 | 효과 |
|----|------|------|
| `affix_dmg_up` | 전투 집중 | 스킬 수치(damage/defense/heal) +15% |
| `affix_weight_light` | 경량화 | 무게 -3, 행동력 비용 -1 |
| `affix_weight_heavy` | 중장갑화 | 무게 +5, 스킬 수치 +10% |

**RARE 이상 (고급 Affix)**

| ID | 이름 | 효과 |
|----|------|------|
| `affix_multi_target` | 다중 타겟 | 스킬이 적 2명에게 60% 효과로 분산 |
| `affix_debuff` | 약화 부가 | 스킬 적중 시 적 공격력↓ 1턴 |
| `affix_buff` | 강화 부가 | 스킬 사용 시 내 방어력↑ 1턴 |
| `affix_chain` | 연계 발화 | 같은 턴 다른 슬롯 스킬 먼저 사용 시 이 스킬 효과 +30% |
| `affix_cond_dmg` | 조건 발화: 피해 | 이번 턴 피해를 받은 경우 효과 +40% |
| `affix_cond_hp` | 조건 발화: HP | HP 50% 이하 시 효과 +50% |

**EPIC 이상 (전용 Affix)**

| ID | 이름 | 효과 |
|----|------|------|
| `affix_passive_regen` | 패시브: 재생 | 매 턴 시작 시 코어 HP +5 회복 |
| `affix_passive_shield` | 패시브: 쉴드 | 매 턴 시작 시 쉴드 +8 부여 |
| `affix_core_atk` | 코어 강화: 공격 | 코어 공격력 계수 +5% |
| `affix_core_def` | 코어 강화: 방어 | 코어 방어력 계수 +5% |
| `affix_ap_refund` | 행동력 환급 | 스킬 사용 후 50% 확률로 행동력 1 환급 |
| `affix_lethal_resist` | 치명 내성 | 치명타 대미지 30% 감소 (수동 트리거 불요) |

> [!note] Affix 중복 방지
> 같은 파츠에 동일 Affix가 두 번 뽑히면 재롤. 최대 3회 재롤 후 다른 Affix로 교체.

---

## 4. 파츠 목록

### 수치 표기 규칙

- `base` 열은 기준 수치 (실제 값은 등급별 범위 내 랜덤)
- `affix` 열은 추가 가능한 Affix 풀 (실제 장착 Affix는 랜덤)
- ARM_L/ARM_R 가용 Affix 풀: COMMON/RARE/EPIC 각 등급 전체

---

### 4.1 COMMON 파츠 (12개)

#### ARM_L — 좌팔 (3개)

| 파일명 | 이름 | 스킬 | base damage | base weight | 가용 Affix |
|--------|------|------|------------|------------|-----------|
| `part_arm_l_cannon` | 캐논 팔 (좌) | 캐논 포격 | 30 | 25 | COMMON |
| `part_arm_l_gatling` | 개틀링 포 (좌) | 연사 | 12×3 | 15 | COMMON |
| `part_arm_l_burst` | 버스트 포 (좌) | 버스트 샷 | 20 | 18 | COMMON |

#### ARM_R — 우팔 (3개)

| 파일명 | 이름 | 스킬 | base defense | base weight | 가용 Affix |
|--------|------|------|-------------|------------|-----------|
| `part_arm_r_shield` | 방패 팔 (우) | 아이언 실드 | 25 | 20 | COMMON |
| `part_arm_r_barrier` | 배리어 팔 (우) | 에너지 배리어 | 20 | 20 | COMMON |
| `part_arm_r_scatter` | 산탄 팔 (우) | 산탄 공격 | 10×4 | 18 | COMMON |

#### BACK — 등 (3개)

| 파일명 | 이름 | 스킬 | base heal | base weight | 가용 Affix |
|--------|------|------|----------|------------|-----------|
| `part_back_repair` | 수리팩 | 수리 | 20 | 10 | COMMON |
| `part_back_relay` | 중계 모듈 | 릴레이 (버프 연장) | — | 12 | COMMON |
| `part_back_coolant` | 냉각 팩 | 냉각 (행동력 회복) | — | 8 | COMMON |

#### LEG — 다리 (3개)

| 파일명 | 이름 | 스킬 | 효과 | base weight | 가용 Affix |
|--------|------|------|-----|------------|-----------|
| `part_leg_sprint` | 스프린트 다리 | 스프린트 (회피율↑) | 회피 +20% | 14 | COMMON |
| `part_leg_anchor` | 앵커 다리 | 앵커 (피격 시 방어↑) | defense +15 | 20 | COMMON |
| `part_leg_dampener` | 충격 흡수 다리 | 댐프닝 (피해 감소) | damage -20% | 22 | COMMON |

---

### 4.2 RARE 파츠 (6개)

#### ARM_L — 좌팔 (2개)

| 파일명 | 이름 | 스킬 | base damage | base weight | 가용 Affix |
|--------|------|------|------------|------------|-----------|
| `part_arm_l_railgun` | 레일건 팔 (좌) | 레일건 발사 (방어 관통) | 45 | 24 | COMMON + RARE |
| `part_arm_l_piercer` | 파일벙커 팔 (좌) | 파일벙커 (단발 최고화력) | 60 | 22 | COMMON + RARE |

> 레일건은 방어력 30% 무시. 파일벙커는 행동력 비용 2.

#### ARM_R — 우팔 (2개)

| 파일명 | 이름 | 스킬 | 효과 | base weight | 가용 Affix |
|--------|------|------|-----|------------|-----------|
| `part_arm_r_interceptor` | 인터셉터 팔 (우) | 인터셉트 (다음 적 공격 차단) | defense 40, 요격 | 19 | COMMON + RARE |
| `part_arm_r_rupture` | 러처 팔 (우) | 파열 공격 (공격+공격력 디버프) | damage 25, ATTACK_DOWN | 17 | COMMON + RARE |

#### BACK — 등 (1개)

| 파일명 | 이름 | 스킬 | base heal | base weight | 가용 Affix |
|--------|------|------|----------|------------|-----------|
| `part_back_emergency_patch` | 응급 수리 모듈 | 응급 수리 (HP 30% 이하 시 자동 발동) | 35 | 12 | COMMON + RARE |

#### LEG — 다리 (1개)

| 파일명 | 이름 | 스킬 | 효과 | base weight | 가용 Affix |
|--------|------|------|-----|------------|-----------|
| `part_leg_reactive_plating` | 리액티브 장갑 다리 | 반응 장갑 (피격 시 defense↑ 1턴) | defense +20 | 21 | COMMON + RARE |

---

### 4.3 EPIC 파츠 (6개)

#### ARM_L — 좌팔 (1개)

| 파일명 | 이름 | 스킬 | 효과 | base weight | 가용 Affix |
|--------|------|------|-----|------------|-----------|
| `part_arm_l_plasma_lance` | 플라즈마 랜스 (좌) | 플라즈마 사출 (광역 + 화상) | damage 55, BURN 2턴 | 27 | COMMON + RARE + EPIC |

#### ARM_R — 우팔 (1개)

| 파일명 | 이름 | 스킬 | 효과 | base weight | 가용 Affix |
|--------|------|------|-----|------------|-----------|
| `part_arm_r_aegis_breaker` | 이지스 브레이커 (우) | 방어막 파괴 + 역공 | 적 방어 무력화 + damage 35 | 23 | COMMON + RARE + EPIC |

#### BACK — 등 (2개)

| 파일명 | 이름 | 스킬 | 효과 | base weight | 가용 Affix |
|--------|------|------|-----|------------|-----------|
| `part_back_nano_forge` | 나노 포지 백팩 | 나노 복구 (대량 회복 + 파츠 손상도 복구) | heal 50, 선택 파츠 손상도 max 복구 | 14 | COMMON + RARE + EPIC |
| `part_back_phase_deflector` ⭐NEW | 위상 편향막 | 위상 편향 (패시브: 매 턴 회피율 +20%) | 회피율 +20% 패시브 | 11 | COMMON + RARE + EPIC |

#### LEG — 다리 (2개)

| 파일명 | 이름 | 스킬 | 효과 | base weight | 가용 Affix |
|--------|------|------|-----|------------|-----------|
| `part_leg_quantum_anchor` | 퀀텀 앵커 다리 | 중력 앵커 (이동 불가 + 피해 대폭 감소) | 이동 잠금, damage -50% | 22 | COMMON + RARE + EPIC |
| `part_leg_em_shock` ⭐NEW | EM 충격 다리 | EM 방출 (패시브: 피격 시 적 속도↓ + 공격력↓) | SPEED_DOWN + ATTACK_DOWN 패시브 | 20 | COMMON + RARE + EPIC |

---

## 5. 무게 & 하중 제한

```
장착 부품 무게 합계 ≤ 코어 하중 제한
```

| 코어 | 하중 제한 |
|------|---------|
| 범용 | 80 |
| 경량 | 60 |
| 방어 | 100 |

> 하중 초과 상태에서도 출격 가능하나 UI에서 경고 표시. 전투 중 이동 계열 스킬 효과 -30%.

---

## 6. 손상도 (Durability)

### 6.1 기본 규칙

파츠는 `durability: int`를 가진다. 스킬을 사용할 때마다 해당 파츠의 손상도가 **-1** 감소한다.  
손상도가 0이 되면 파츠가 **파괴**되어 스킬 사용 불가 + Affix 비활성화.

```
스킬 사용 → 해당 파츠 durability -= 1 → durability == 0 이면 파괴 처리
```

### 6.2 등급별 초기 손상도

등급이 높을수록 내구성이 높아 더 오래 운용할 수 있다.

| 등급 | 초기 손상도 |
|------|-----------|
| COMMON | 3 |
| RARE | 5 |
| EPIC | 7 |

### 6.3 손상도 0 — 파괴 상태

| 항목 | 내용 |
|------|------|
| 스킬 | 사용 불가 (UI에서 잠금 표시) |
| Affix | 모두 비활성화 |
| 무게 | 여전히 하중에 포함 (비활성화해도 탈착 필요) |
| 비고 | 전투 중 파괴 시 해당 턴 즉시 적용 |

### 6.4 손상도 감소 트리거

스킬 사용 외에 다음 상황에서도 손상도가 감소한다.

| 트리거 | 감소량 |
|--------|--------|
| 내 스킬 사용 | -1 (해당 파츠) |
| 적의 **파츠 저격** 스킬 | -1 (플레이어가 선택한 슬롯) |
| 적의 **과부하 공격** 스킬 | -2 (피격 슬롯) |
| 적의 **EMP 충격** 스킬 | -1 (장착된 모든 파츠) |
| 조우 이벤트 결과 B | -1 (획득한 파츠) |

#### 적 전용 스킬 — 손상도 파괴 계열

| 스킬명 | 설명 | 적 티어 |
|--------|------|--------|
| **파츠 저격** | 플레이어의 특정 슬롯을 노려 손상도 -1. 다음 턴 행동 예고로 미리 공개. | 엘리트 |
| **과부하 공격** | 일반 공격 + 피격 슬롯 손상도 -2. 대미지는 낮음. | 엘리트, 보스 |
| **EMP 충격** | 대미지 없음. 장착된 모든 파츠 손상도 -1. | 보스 |

> [!note]
> 플레이어는 "다음 턴 행동 예고" 시스템으로 파츠 저격 대상 슬롯을 미리 확인할 수 있다.  
> → 해당 슬롯 스킬을 아끼거나 다른 슬롯으로 전환하는 판단이 생김.

### 6.5 수리

| 수리 수단 | 효과 |
|----------|------|
| **나노 포지 백팩** 스킬 | 장착 파츠 중 선택 1개 → 손상도 max 복구 |
| **작업대** | 크레딧 소모 → 선택한 파츠 손상도 max 복구 |
| **조우 이벤트** | 이벤트에 따라 손상도 +1~max 복구 |

---

## 7. 구현 가이드

### 7.1 PartsData 변경 사항

현재 `parts_skills: Array[SkillData]`는 유지. 아래 필드 추가 필요:

```gdscript
# Resources/PartsData.gd 추가 예정
@export var rolled_affixes: Array[String] = []  # affix ID 목록
@export var stat_multiplier: float = 1.0         # 랜덤 롤 결과 계수
@export var max_durability: int = 3              # 등급별 기본값: COMMON 3 / RARE 5 / EPIC 7
var durability: int                              # 런타임 상태, .tres에 저장 안 함

# 파츠 파괴 여부
func is_broken() -> bool:
    return durability <= 0
```

### 7.2 파츠 생성 흐름

```
PartsFactory.generate(part_template: PartsData, grade: PartsGrade) -> PartsData:
    1. template.duplicate() → 인스턴스 복사
    2. roll_stat() → stat_multiplier 설정
    3. roll_affixes(grade) → rolled_affixes 배열 채움
    4. durability = max_durability (등급별 초기값 적용)
    5. 반환
```

### 7.3 .tres 파일 역할 변경

기존 `.tres` 파일은 **템플릿** 역할만 한다.
- 파츠 ID, 이름, 스킬 참조, base weight를 보유
- 실제 수치는 런타임에서 롤

> [!todo]
> - [ ] `PartsData.gd`에 `stat_multiplier`, `rolled_affixes`, `max_durability`, `durability` 필드 추가
> - [ ] `PartsFactory` 싱글톤 또는 autoload 설계
> - [ ] Affix 효과 처리 로직 (CombatManager 또는 별도 AffixHandler)
> - [ ] 스킬 사용 후 `durability -= 1` 처리 (CombatManager)
> - [ ] 적 스킬 — 파츠 저격 / 과부하 공격 / EMP 충격 구현
> - [ ] 파츠 파괴 시 스킬 잠금 + Affix 비활성화 처리
> - [ ] `part_back_phase_deflector.tres` 신규 생성
> - [ ] `part_leg_em_shock.tres` 신규 생성
> - [ ] `part_back_overclock.tres` / `part_leg_thruster.tres` 제거 또는 미사용 처리
> - [ ] PartCardUI에 손상도 게이지 / rolled affix 표시
> - [ ] 파괴 파츠 UI — 잠금 오버레이 + 손상도 0 표시

---

## 8. 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 0.1 | 2026-04-28 | 초안 (GDD §4 기반) |
| 0.2 | 2026-05-11 | 랜덤 롤 시스템 도입, RARE 8→6, EPIC 4→6, Affix 풀 설계, 신규 EPIC 2종 추가 |
| 0.3 | 2026-05-11 | 손상도 시스템 재설계 — bool → int, 스킬 사용마다 -1, 적 파츠 파괴 스킬 3종 추가 |
