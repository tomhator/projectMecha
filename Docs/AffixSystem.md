---
tags: [project/project-mecha, document/affix-system, status/todo]
status: todo
created: 2026-05-12
updated: 2026-05-12
---

# Affix 시스템 (Affix System)

> [!info] 관련 문서
> - 시스템 명세: [[PartsSystem]]
> - 파츠별 affix 풀: [[PartsCatalog]]

> [!warning] 작업 전 읽기
> 이 문서는 두 가지를 다룬다.
> 1. **전체 Affix 목록** — ID·이름·효과·등급 요건
> 2. **파츠별 Affix 가중치** — 어떤 파츠에 어떤 affix가 잘 붙는지

---

## 설계 방향

- 각 파츠는 전체 affix 풀의 **부분집합**을 affix 후보로 가진다.
- 후보 내에서도 가중치가 달라 파츠마다 "잘 붙는 affix 경향"이 있다.
- 같은 affix라도 수치가 있는 경우(예: 수치+X%) stat_multiplier와 무관하게 별도 고정값.
- affix 중복 방지: 동일 ID 재롤 시 최대 3회 재시도 후 다른 ID로 교체.

---

## 1. 전체 Affix 목록

> 아래는 초안. PartsCatalog 설계와 병행해서 확정.

### 1.1 공통 Affix (모든 파츠에 등장 가능)

| ID | 이름 | 효과 |
|----|------|------|
| `atk_up` | 전투 집중 | 스킬 수치 +15% |
| `weight_light` | 경량화 | 무게 -3, 행동력 비용 -1 |
| `weight_heavy` | 중장갑화 | 무게 +5, 스킬 수치 +10% |
| `durability_up` | 견고 | 초기 손상도 +2 |

### 1.2 중급 Affix (파츠별 풀에 포함된 경우만 등장)

| ID | 이름 | 효과 |
|----|------|------|
| `multi_target` | 다중 타겟 | 스킬 효과를 적 2명에게 60%씩 분산 |
| `debuff_atk` | 약화 부가 | 스킬 적중 시 적 공격력↓ 1턴 |
| `buff_def` | 강화 부가 | 스킬 사용 시 내 방어력↑ 1턴 |
| `chain` | 연계 발화 | 같은 턴 다른 슬롯 스킬 먼저 사용 시 이 스킬 효과 +30% |
| `cond_dmg_taken` | 조건: 피해 후 | 이번 턴 피해를 받은 경우 효과 +40% |
| `cond_low_hp` | 조건: 저 HP | 코어 HP 50% 이하 시 효과 +50% |
| `ap_refund` | 행동력 환급 | 스킬 사용 후 50% 확률로 행동력 1 환급 |

### 1.3 고급 Affix (강력한 파츠에만 등장)

| ID | 이름 | 효과 |
|----|------|------|
| `passive_regen` | 패시브: 재생 | 매 턴 시작 시 코어 HP +5 |
| `passive_shield` | 패시브: 쉴드 | 매 턴 시작 시 쉴드 +8 |
| `core_atk_up` | 코어 강화: 공격 | 코어 공격력 계수 +5% |
| `core_def_up` | 코어 강화: 방어 | 코어 방어력 계수 +5% |
| `lethal_resist` | 치명 내성 | 치명타 대미지 30% 감소 |

---

## 2. 파츠별 Affix 가중치 테이블

<!-- TODO: PartsCatalog 30종 확정 후 작성 -->
<!-- 
각 파츠마다 아래 형식으로 작성:

### 캐논 팔
| affix ID | 가중치 |
|----------|--------|
| atk_up | 30 |
| multi_target | 20 |
| chain | 15 |
| weight_heavy | 10 |
| cond_low_hp | 10 |
| ap_refund | 15 |
-->
