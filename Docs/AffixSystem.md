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
