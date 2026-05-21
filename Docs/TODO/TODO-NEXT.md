---
tags: [project/project-mecha, document/todo]
date: 2026-05-21
updated: 2026-05-22
status: active
---

# TODO — NEXT (통합 backlog)

> `TODO/old/`의 날짜별 TODO, `DEV-GUIDE/old/DEV-GUIDE-2026-05-21` 검증 체크리스트, `SESSION_CONTEXT/old/` 미완 항목을 **하나로 통합**한 활성 작업 목록.  
> 완료 시 여기서 체크하고, 필요하면 아카이브 TODO·기획 문서에도 반영.

---

## P0 — 검증 (Godot 플레이테스트, 최우선)

참조: [[DEV-GUIDE/old/DEV-GUIDE-2026-05-21]] §검증 체크리스트

### 일반 전투
- [ ] 스크래퍼/러셔 등장 → 예고 UI에 저격 하이라이트 **없음**

### 파괴·Affix
- [ ] 파츠 내구도 0 → 해당 스킬 버튼 비활성화
- [ ] 파괴 파츠만 남을 때 자동 턴 종료
- [ ] 파괴 파츠 Affix 보너스 미적용 (로그 확인)

### 저격 (수집가 코어 EMP)
- [ ] 코어 등장 시 "등 EMP 충격" 예고 + BACK 슬롯 하이라이트
- [ ] 공격 후 BACK 내구도 1 감소
- [ ] BACK 빈 슬롯일 때 하이라이트 **안 뜸**
- [ ] 빈 슬롯 저격: HP 데미지만, 내구도 효과 무효

### 수집가 보스 — 기본
- [ ] 시작 시 코어 1 + 팔 4 = 5체
- [ ] 팔 각각 독립 행동
- [ ] 팔 파괴 → `enemies`에서 제거
- [ ] 팔 전멸 → 재수집(3~4개) 후 `enemies` 재추가
- [ ] **코어 HP 0 → 팔 남아도 승리**

### 수집가 보스 — 팔 탈취
- [ ] 팔 1+ 파괴 시 "팔 탈취" 예고 가능
- [ ] 탈취 후 플레이어 ARM 슬롯 비움 + 스킬 제거
- [ ] "강탈된 [파츠명]" 팔 entity 생성·적 배열 추가
- [ ] 강탈 팔이 원래 스킬로 공격
- [ ] 탈취 가능 ARM 없을 때 소타격(10)만

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

- [ ] **어빌리티 트리 재기획** — 기동 분기 '선제 도약' 등 패시브 스킬이 전투 스킬 목록에서 필터링되어 스킬 없는 상태 발생. 각 분기 최소 1개 이상의 액티브 코어 스킬 언락 구조로 재설계 필요. [[Docs/AbilityTreeSystem]]
- [ ] **파츠 조립 화면 인벤토리 재설계** — 인벤토리 구조·UX 전반 재검토 필요
- [ ] **매립지 병종 재기획** — 스크래퍼 / 러셔 / 가드 스킬·수치·행동 패턴 전면 재설계
- [ ] 수집가: 팔 파괴 시 드롭 여부 ([[EnemySystem]] §미결)
- [ ] 수집가: 팔 5종 시각 에셋 방향
- [ ] 수집가: 보스 BGM / 연출

---

## P3 — 인프라 (별도 세션)

- [x] `.claude/hooks/` 검사 스크립트 3종 + `settings.json` (자동 검증 v1, 2026-05-22)
- [ ] 도메인 `CLAUDE.md` 4종 (Combat, Entities, Autoload, Skills)
- [ ] `.claude/commands/` 4종 (new-skill, new-enemy, combat-debug, parts-update)

---

## P4 — 데모 이후

- [ ] 구 도시: 위병 순찰대·포진 수치·스킬 확정
- [ ] 연구시설: 레플리카-공형·방형 수치·스킬 확정
- [ ] 구 도시 / 연구시설 보스 각각 기획

---

## P2 — CEO Review 도출 (2026-05-21)

- [ ] **스킬 쿨다운 시스템** — TurnManager 턴마다 쿨다운 감소, get_available_skills 쿨다운 필터. SkillData.buff_turns 필드·EventBus 신호 이미 준비됨. 공수: S.
- [ ] **멀티타겟 스킬 (AoE)** — SkillData.multi_target 필드 존재. TurnManager.on_skill_selected에서 적 전체를 target으로 전달하는 로직 필요. 공수: M.
- [ ] **_affix_bonus_sum 리팩터링** — affix 10개 이상 도달 시 if-else 체인 → Dictionary/Callable 기반 매핑. `MechaEntity.gd:_affix_bonus_sum()`. 공수: S.

---

## 완료 참고 (2026-05-21 세션 — 체크 불필요)

Phase A·B 작업 0~9 (저격·파괴 연동 + 수집가 보스). 상세: [[2026-05-21]], [[TODO/old/TODO-2026-05-21]].
