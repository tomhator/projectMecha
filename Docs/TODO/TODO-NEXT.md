---
tags: [project/project-mecha, document/todo]
date: 2026-05-21
updated: 2026-05-26
status: active
---

# TODO — NEXT (통합 backlog)

> `TODO/old/`의 날짜별 TODO, `DEV-GUIDE/old/DEV-GUIDE-2026-05-21` 검증 체크리스트, `SESSION_CONTEXT/old/` 미완 항목을 **하나로 통합**한 활성 작업 목록.  
> 완료 시 여기서 체크하고, 필요하면 아카이브 TODO·기획 문서에도 반영.

---

## 다음 착수 추천

- [ ] **멀티타겟 스킬 스펙 리뷰 → 구현** — `SkillData.multi_target` 필드와 `TurnManager.on_skill_selected`의 타겟 전달 방식을 연결하고, 전투 UI 타겟팅 표시까지 함께 정리한다. 전투/UI 2개 도메인에 걸치므로 구현 전 변경 파일·영향 범위 계획을 먼저 확정한다.

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
- [ ] affix 보정 체감 검증 (backdoor / undefined_behavior 등)
- [x] `has_any_debuff` API 도입 → backdoor affix +25% 활성화 완료 (2026-05-21)

---

## P1 — 후속 구현

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
- [ ] **파츠 조립 화면 인벤토리 재설계** — 인벤토리 구조·UX 전반 재검토 필요
- [ ] **파츠·스킬·적 실제 아이콘/스프라이트 연결** — placeholder 비주얼을 `PartsData.parts_icon`, `SkillData.skill_icon`, `EnemyData.enemy_sprite` 자산으로 교체
- [x] **역할 기반 적 리소스 재구축** — 매립지 Striker/Breaker/Support/Caller 일반 병종 + 호출 전용 잡졸 v1 구현 (2026-05-22)
- [x] **Caller 소환 정책 확정** — 전투당 1회 호출, 호출 적 승리 조건 포함, 파츠 드롭 카운트 제외 (2026-05-22)
- [ ] **매립지 엘리트 역할 병종 복구** — 압축기(Anchor+Striker), 회수 견인기(Breaker+Support) v1 구현
- [ ] 수집가: 팔 파괴 시 드롭 여부 ([[EnemySystem]] §미결)
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

- [ ] **멀티타겟 스킬 (AoE)** — SkillData.multi_target 필드 존재. TurnManager.on_skill_selected에서 적 전체를 target으로 전달하는 로직 필요. 공수: M.
- [ ] **_affix_bonus_sum 리팩터링** — affix 10개 이상 도달 시 if-else 체인 → Dictionary/Callable 기반 매핑. `MechaEntity.gd:_affix_bonus_sum()`. 공수: S.

---

## 완료 참고 (2026-05-21 세션 — 체크 불필요)

Phase A·B 작업 0~9 (저격·파괴 연동 + 수집가 보스). 상세: [[2026-05-21]], [[TODO/old/TODO-2026-05-21]].
