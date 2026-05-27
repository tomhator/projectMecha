---
tags: [project/project-mecha, document/todo]
date: 2026-05-21
updated: 2026-05-27
status: active
---

# TODO — NEXT (통합 backlog)

> `TODO/old/`의 날짜별 TODO, `DEV-GUIDE/old/DEV-GUIDE-2026-05-21` 검증 체크리스트, `SESSION_CONTEXT/old/` 미완 항목을 **하나로 통합**한 활성 작업 목록.  
> 완료 시 여기서 체크하고, 필요하면 아카이브 TODO·기획 문서에도 반영.

---

## 다음 착수 추천

- [ ] **거점 UI 플레이테스트** — Hub/Hangar 실제 화면에서 버튼 위치, 카드 텍스트 overflow, 출격 준비 흐름을 수동 확인하고 시각 조정한다.

---

## P0 — 검증 (Godot 플레이테스트, 최우선)

참조: [[DEV-GUIDE/old/DEV-GUIDE-2026-05-21]] §검증 체크리스트

### 일반 전투
- [x] Breaker 일반 병종 등장 → 파츠 공격 예고 슬롯과 실제 타격 슬롯 일치 확인 (2026-05-22 P0 headless 검증)
- [x] 전투 승리 보상: 격파 적 1기당 0~2개 드롭 판정 후 모든 드롭 파츠 자동 인벤토리 추가 (2026-05-22 구현/검증)

### 파괴·Affix
- [x] 파츠 내구도 0 → 해당 스킬 버튼 비활성화 (2026-05-22 표시/사용 가능 목록 분리)
- [x] 파괴 파츠만 남을 때 자동 턴 종료 (2026-05-22 P0 headless 검증)
- [x] 파괴 파츠 Affix 보너스 미적용 (로그 확인) (2026-05-22 P0 headless 검증)

### 저격 (수집가 코어 EMP)
- [x] 코어 등장 시 "등 EMP 충격" 예고 + BACK 슬롯 하이라이트 (2026-05-22 P0 headless 검증)
- [x] 공격 후 BACK 내구도 1 감소 (2026-05-22 P0 headless 검증)
- [x] BACK 빈 슬롯일 때 하이라이트 **안 뜸** (2026-05-22 P0 headless 검증)
- [x] 빈 슬롯 저격: HP 데미지만, 내구도 효과 무효 (2026-05-22 P0 headless 검증)

### 수집가 보스 — 기본
- [x] 시작 시 코어 1 + 팔 4 = 5체 (2026-05-22 P0 headless 검증)
- [x] 팔 각각 독립 행동 (2026-05-22 P0 headless 검증)
- [x] 팔 파괴 → `enemies`에서 제거 (2026-05-22 P0 headless 검증)
- [x] 팔 전멸 → 코어 노출 창 유지 후 재수집 4개 `enemies` 재추가 (2026-05-22 P0 headless 검증)
- [x] **코어 HP 0 → 팔 남아도 승리** (2026-05-22 P0 headless 검증)
- [x] 살아 있는 팔 보호율·방어 팔 추가 보호·팔 파괴 코어 HP 피해 (2026-05-22 P0 headless 검증)

### 수집가 보스 — 팔 탈취
- [x] 팔 1+ 파괴 시 "팔 탈취" 예고 가능 (2026-05-22 P0 headless 검증)
- [x] 탈취 후 플레이어 ARM 슬롯 비움 + 스킬 제거 (2026-05-22 P0 headless 검증)
- [x] "강탈된 [파츠명]" 팔 entity 생성·적 배열 추가 (2026-05-22 P0 headless 검증)
- [x] 강탈 팔이 원래 스킬로 공격 (2026-05-22 P0 headless 검증)
- [x] 탈취 가능 ARM 없을 때 소타격(10)만 (2026-05-22 코드 경로 확인)

### UI·Affix (세션 컨텍스트 이월)
- [x] `undefined_behavior` 적용 경로 보강 + affix 보정 검증 (backdoor / undefined_behavior 등) (2026-05-26 P0 headless 검증)
- [x] `has_any_debuff` API 도입 → backdoor affix +25% 활성화 완료 (2026-05-21)

---

## P1 — 후속 구현

- [x] **HubScene v1** — `Scenes/Base/HubScene.tscn` / `.gd` 추가, 은신처 마당 건물형 버튼, 코어 연구/출격 게이트 연결, 런 종료 복귀 대상 변경 (2026-05-27)
- [x] **거점 영구 상태 구현** — 영구 파츠 창고, 고철, 성공/실패 정산(실패 시 장착 파츠 영구 손실, 런 인벤토리 회수, 재화 50% 회수), ConfigFile 저장/복원 (2026-05-27)
- [x] **격납고 서비스 v1** — 파츠 수리(고철 소모), 파츠 분해(고철 획득), 출격 전 장착/런 인벤토리 구성 (2026-05-27)
- [ ] **거점 수동 QA** — 실제 Godot 실행 화면에서 Hub 배경 버튼 좌표, Hangar 3열 레이아웃, CoreSelect 복귀/초기 탭, RunEnd 정산 문구 확인
- [x] `armor_penetration` 플레이어/적 `take_damage` 반영 (2026-05-21)
- [x] 플로팅 데미지 이펙트 (2026-05-21)
- [x] 카메라 셰이크 (플레이어 피격 시, SHAKE_THRESHOLD=15) (2026-05-21)
- [ ] 카메라 셰이크 — 적 공격 시 외에 추가 트리거 검토
- [ ] 스킬 타입별 파티클 / 색상 깜빡임

---

## P2 — 밸런스·기획 (데모 스코프)

- [x] **어빌리티 트리 재기획** — 5티어 연구/출격 로드아웃, 기본 공격, 파츠 활용 어빌리티 구조로 재설계. 기본 공격이 파손 시 전투 안전판을 맡는다. (2026-05-22) [[Docs/AbilityTreeSystem]]
- [x] **코어 설계 화면 레이아웃 정리** — 연구 노드 셀 정사각형 중심 정렬, 출격 준비 좌우 분할, 선택 외장 기반 코어 프리뷰 구현. (2026-05-22) [[Docs/superpowers/specs/2026-05-22-core-select-layout-preview-design]]
- [x] **어빌리티 트리 5레벨 보너스 밸런싱** — 15개 노드의 5레벨 역할 문구와 누적 수치 기준 확정. 행동력 보너스는 5레벨 도달 시 +1로 보정. (2026-05-26) [[Docs/AbilityTreeSystem]]
- [x] **파츠 조립 화면 인벤토리 재설계** — 선택 상세 패널, 전투 스킬 배치 프리뷰, 16칸 용량 처리 구현. (2026-05-26)
- [x] **거점 시스템 기획** — 외곽 은신처, 건물형 구역, 영구 창고/런 인벤토리 분리, 크레딧+고철, 실패 시 장착 파츠 영구 손실 정산 규칙 확정. (2026-05-27) [[Docs/BaseSystem]]
- [ ] **파츠·스킬·적 실제 아이콘/스프라이트 연결** — placeholder 비주얼을 `PartsData.parts_icon`, `SkillData.skill_icon`, `EnemyData.enemy_sprite` 자산으로 교체
- [x] **역할 기반 적 리소스 재구축** — 매립지 Striker/Breaker/Support/Caller 일반 병종 + 호출 전용 잡졸 v1 구현 (2026-05-22)
- [x] **Caller 소환 정책 확정** — 전투당 1회 호출, 호출 적 승리 조건 포함, 파츠 드롭 카운트 제외 (2026-05-22)
- [x] **매립지 엘리트 역할 병종 복구** — 압축기(Anchor+Striker), 회수 견인기(Breaker+Support) v1 구현 (2026-05-26)
- [x] 수집가: 팔 파괴 시 드롭 여부 — 팔은 `CollectorArmEntity`로 전투 보상 카운트에서 제외. 코어/일반 적만 드롭 기준에 포함. (2026-05-26 확인: `TurnManager._count_new_defeats()`)
- [ ] 수집가: 팔 5종 시각 에셋 방향
- [ ] 수집가: 보스 BGM / 연출

---

## P3 — 인프라 (별도 세션)

- [x] `.claude/hooks/` 검사 스크립트 3종 + `settings.json` (자동 검증 v1, 2026-05-22)
- [x] 자동 검증 v2 — 리소스 무결성 + 주요 씬 스모크 검사 (2026-05-22)
- [ ] 도메인 `CLAUDE.md` 4종 (Combat, Entities, Autoload, Skills)
- [ ] `.claude/commands/` 4종 (new-skill, new-enemy, combat-debug, parts-update)

---

## P4 — 데모 이후

- [ ] 구 도시: 위병 역할 병종 수치·스킬 확정
- [ ] 연구시설: 레플리카 역할 병종 수치·스킬 확정
- [ ] 구 도시 / 연구시설 보스 각각 기획

---

## P2 — CEO Review 도출 (2026-05-21)

- [x] **멀티타겟 스킬 (AoE)** — `multi_target = true` 적 대상 스킬은 타겟 가능한 적 최대 4명에게 총 피해를 균등 분배. (2026-05-26)
- [x] **_affix_bonus_sum 리팩터링** — 정적 보너스 Dictionary와 조건/런타임 보너스 헬퍼로 분리. `MechaEntity.gd:_affix_bonus_sum()`. (2026-05-26)

---

## 완료 참고 (2026-05-21 세션 — 체크 불필요)

Phase A·B 작업 0~9 (저격·파괴 연동 + 수집가 보스). 상세: [[2026-05-21]], [[TODO/old/TODO-2026-05-21]].
