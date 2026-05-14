---
tags: [project/project-mecha, document/parts-system, status/in-progress]
status: in-progress
version: 0.4
created: 2026-05-11
updated: 2026-05-12
---

# 파츠 시스템 명세 (Parts System Specification)

> [!info] 관련 문서
> - GDD 전체: [[GameDesignDocument]]
> - 고유 파츠 목록: [[PartsCatalog]]
> - Affix 상세: [[AffixSystem]]

---

## 1. 슬롯 체계

메카는 코어(Core)를 중심으로 4개의 파츠 슬롯을 가진다.

| 슬롯 | 코드값 | 위치 | 권장 스킬 성향 | 고유 특징 |
|------|--------|------|-------------|---------|
| **ARM_L** | `PartsType.ARM_L` (0) | 섀시 좌측 | 공격, 방어 | 주력 무장 슬롯 |
| **ARM_R** | `PartsType.ARM_R` (1) | 섀시 우측 | 공격, 방어 | 보조 무장 / 방어 슬롯 |
| **BACK** | `PartsType.BACK` (2) | 섀시 등 | 방어, 회피, 공격 | 지원 / 패시브 슬롯 |
| **LEG** | `PartsType.LEG` (3) | 섀시 하단 | 방어, 버프·디버프, 회복 | 조건 반응형 슬롯 |

> [!note]
> "권장 성향"은 파츠 풀 설계 방향이지 장착 제한이 아니다.

---

## 2. 등급 체계

등급은 파츠 자체의 속성이 아니라 드롭 시 굴린 **affix 개수**로 결정된다.  
같은 "캐논 팔"이라도 affix가 0개면 COMMON, 4개면 EPIC.

| 등급 | affix 개수 | 초기 손상도 | UI 색상 |
|------|-----------|-----------|--------|
| **COMMON** | 0~1 | 3 | 회색 |
| **RARE** | 2~3 | 5 | 파랑 |
| **EPIC** | 4~5 | 7 | 보라 |

---

## 3. 랜덤 롤 시스템

> [!important] 핵심 설계 방향
> 파츠를 루팅할 때마다 수치·affix 개수·affix 종류가 달라진다.  
> **스킬은 파츠에 고정** — 유저가 "어떤 파츠를 노릴지" 방향성을 잡을 수 있다.

파츠 드롭 시 아래 세 가지를 순서대로 굴린다.

```
1. 어떤 파츠? → 파츠별 드롭 가중치로 결정  (→ PartsCatalog)
2. 수치는?    → stat_multiplier 롤          (→ §3.1)
3. affix는?   → 개수 롤 → 종류 롤           (→ §3.2, AffixSystem)
```

### 3.1 수치 롤 — 이름 접두사 결정

stat_multiplier를 ×0.70~1.50 범위에서 균등 롤한다. 구간에 따라 파츠 이름 접두사가 붙는다.

| 접두사 | 범위 | 예시 (base 30) |
|--------|------|--------------|
| 낡은 | ×0.70~0.84 | 21~25 |
| (없음) | ×0.85~0.99 | 25~29 |
| 정밀한 | ×1.00~1.14 | 30~34 |
| 강화된 | ×1.15~1.29 | 34~38 |
| 완벽한 | ×1.30~1.50 | 39~45 |

**이름 조합 예시**

```
낡은 캐논 팔          ← multiplier 0.78, affix 0개 (COMMON)
강화된 레일건 팔       ← multiplier 1.22, affix 1개 (COMMON)
완벽한 레일건 팔       ← multiplier 1.45, affix 3개 (RARE)
정밀한 플라즈마 랜스   ← multiplier 1.05, affix 5개 (EPIC)
```

### 3.2 Affix 롤

Affix 상세 설계는 [[AffixSystem]] 참고. 여기서는 개수 결정 규칙만 명시.

| affix 개수 | 확률 (기본) |
|-----------|-----------|
| 0개 | 20% |
| 1개 | 25% |
| 2개 | 22% |
| 3개 | 18% |
| 4개 | 10% |
| 5개 | 5% |

> [!note]
> 위 확률은 기본값. 획득처(방 종류)에 따라 가중치를 조정할 수 있다.  
> 예: 보스 드롭은 4~5개 확률 상향. 상세는 GDD §2.3 참고.

---

## 4. 파츠 풀

고유 파츠 **34종**. ARM·BACK 슬롯 8종, LEG 슬롯 10종.  
각 파츠의 스킬·수치·affix 풀·드롭 가중치는 [[PartsCatalog]] 참고.

| 슬롯 | 파츠 수 |
|------|--------|
| ARM_L | 8 |
| ARM_R | 8 |
| BACK | 8 |
| LEG | 10 |
| **합계** | **34** |

---

## 5. 무게 & 하중 제한

```
최대 하중 = 코어 기본 하중 + LEG 최대 하중 증가
장착 부품 무게 합계 ≤ 최대 하중
```

ARM·BACK 파츠는 하중에 부담을 준다. 코어와 LEG가 최대 하중을 결정한다.

### 코어 기본 하중

| 코어 | 기본 하중 |
|------|---------|
| 경량 | 75 |
| 범용 | 85 |
| 방어 | 110 |

### LEG 최대 하중 증가

LEG 파츠는 장착 시 최대 하중을 늘려준다. 수치는 [[PartsCatalog]] 참고.

| 타입 | 범위 |
|------|------|
| 무한궤도 | +25~+30 |
| 4각 | +16~+20 |
| 2각 | +10~+14 |
| 역관절 2각 | +5~+12 |

### 코어 + LEG 조합 범위

| 조합 | 최대 하중 |
|------|---------|
| 경량 + 고속 역관절 2각 | 75 + 5 = **80** |
| 경량 + 중장 무한궤도 | 75 + 30 = **105** |
| 범용 + 고속 역관절 2각 | 85 + 5 = **90** |
| 범용 + 중장 무한궤도 | 85 + 30 = **115** |
| 방어 + 고속 역관절 2각 | 110 + 5 = **115** |
| 방어 + 중장 무한궤도 | 110 + 30 = **140** |

> 하중 초과 시 UI 경고 표시. 전투 중 이동 계열 스킬 효과 -30%.

---

## 6. 손상도 (Durability)

### 6.1 기본 규칙

파츠는 `durability: int`를 가진다. 스킬을 사용할 때마다 해당 파츠의 손상도가 **-1** 감소한다.  
손상도가 0이 되면 파츠가 **파괴**되어 스킬 사용 불가 + Affix 비활성화.

```
스킬 사용 → 해당 파츠 durability -= 1 → durability == 0 이면 파괴 처리
```

초기 손상도는 등급에 따라 결정된다 (§2 참고).

### 6.2 파괴 상태

| 항목 | 내용 |
|------|------|
| 스킬 | 사용 불가 (UI 잠금 표시) |
| Affix | 모두 비활성화 |
| 무게 | 여전히 하중에 포함 |
| 적용 시점 | 전투 중 파괴 시 해당 턴 즉시 적용 |

### 6.3 손상도 감소 트리거

| 트리거 | 감소량 |
|--------|--------|
| 내 스킬 사용 | -1 (해당 파츠) |
| 적의 **파츠 저격** 스킬 | -1 (플레이어 지정 슬롯) |
| 적의 **과부하 공격** 스킬 | -2 (피격 슬롯) |
| 적의 **EMP 충격** 스킬 | -1 (장착된 모든 파츠) |
| 조우 이벤트 결과 B | -1 (획득한 파츠) |

#### 적 전용 스킬 — 손상도 파괴 계열

| 스킬명 | 설명 | 등장 티어 |
|--------|------|---------|
| **파츠 저격** | 지정 슬롯 손상도 -1. 다음 턴 행동 예고로 미리 공개. | 엘리트 |
| **과부하 공격** | 일반 공격 + 피격 슬롯 손상도 -2. 대미지 낮음. | 엘리트, 보스 |
| **EMP 충격** | 대미지 없음. 장착된 모든 파츠 손상도 -1. | 보스 |

> [!note]
> 파츠 저격은 다음 턴 예고 시스템으로 대상 슬롯을 미리 공개.  
> → 해당 슬롯 스킬을 아끼거나 다른 슬롯으로 전환하는 판단이 생김.

### 6.4 수리

| 수단 | 효과 |
|------|------|
| 현장 수리 키트 | 선택 파츠 1개 손상도 max 복구 |
| 작업대 | 크레딧 소모 → 선택 파츠 손상도 max 복구 |
| 조우 이벤트 | 이벤트에 따라 손상도 +1~max 복구 |

---

## 7. 구현 가이드

### 7.1 PartsData 필드 추가

```gdscript
# Resources/PartsData.gd 추가 예정
@export var drop_weight: float = 1.0             # 드롭 가중치 (PartsCatalog 기준)
@export var affix_pool: Array[String] = []       # 이 파츠의 affix 후보 ID 목록 (균등 확률)

@export var stat_multiplier: float = 1.0         # 롤 결과 계수 (런타임)
@export var rolled_affixes: Array[String] = []   # 실제 붙은 affix 목록 (런타임)
@export var max_durability: int = 3              # 등급 확정 후 설정 (런타임)
var durability: int                              # 런타임 전용, .tres 저장 안 함

func grade() -> PartsGrade:
    match rolled_affixes.size():
        0, 1: return PartsGrade.COMMON
        2, 3: return PartsGrade.RARE
        _:    return PartsGrade.EPIC

func is_broken() -> bool:
    return durability <= 0
```

### 7.2 파츠 생성 흐름

```
PartsFactory.generate(template: PartsData) -> PartsData:
    1. template.duplicate()
    2. stat_multiplier = randf_range(0.70, 1.50)
    3. affix 개수 롤 (§3.2 확률표)
    4. affix 종류 롤 (template.affix_pool에서 균등 확률)  → AffixSystem
    5. max_durability = [3, 3, 5, 5, 7, 7][affix 개수]  (COMMON/RARE/EPIC)
    6. durability = max_durability
    7. 반환
```

### 7.3 .tres 파일 역할

`.tres`는 **드롭 템플릿** 역할만 한다.
- 보유: 파츠 ID, 이름, 스킬 참조, base_weight, drop_weight, affix_pool
- 런타임에서 결정: stat_multiplier, rolled_affixes, durability

> [!todo]
> - [ ] `PartsData.gd` 필드 추가 (drop_weight, affix_pool, stat_multiplier, rolled_affixes, max_durability, durability)
> - [ ] `PartsFactory` autoload 설계
> - [ ] affix 개수 확률표 구현 (방 종류별 가중치 조정 포함)
> - [ ] affix 종류 롤 — 파츠별 가중치 풀 적용
> - [ ] 스킬 사용 후 `durability -= 1` (CombatManager)
> - [ ] 파츠 파괴 처리 — 스킬 잠금 + Affix 비활성화
> - [ ] 적 스킬 파괴 계열 3종 구현
> - [ ] PartCardUI — 이름 접두사, 손상도 게이지, affix 아이콘 표시
> - [ ] 기존 24개 .tres → 30개로 재설계 (PartsCatalog 확정 후)

---

## 8. 변경 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 0.1 | 2026-04-28 | 초안 (GDD §4 기반) |
| 0.2 | 2026-05-11 | 랜덤 롤 시스템 도입, 파츠 24종 설계, Affix 풀 설계 |
| 0.3 | 2026-05-11 | 손상도 시스템 — bool → int, 스킬 사용마다 -1, 적 파괴 스킬 3종 |
| 0.4 | 2026-05-12 | 등급 체계 전면 개편 (affix 개수 기반), 이름 접두사 도입, 파츠 30종으로 확대, PartsCatalog·AffixSystem 분리 |
