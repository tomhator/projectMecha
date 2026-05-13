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

| ID | 이름 | 효과 |
|----|------|------|

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
