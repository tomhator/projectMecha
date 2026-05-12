# Docs — Agent Guide

## 폴더 역할

PROJECT MECHA(가제)의 모든 기획 문서를 관리하는 폴더.
AI 에이전트는 **기능 구현 전 반드시 이 폴더를 확인**해야 한다.
문서 없이 임의로 기능을 구현하는 것을 금지한다.

---


## 문서 확인 규칙 (필수)

> **어떤 기능을 구현하기 전에 아래 순서를 반드시 따를 것.**

1. `GameDesignDocument.md` — 전체 구조와 스코프 확인
2. 구현 기능에 해당하는 상세 명세 문서 확인
3. 문서에 명시되지 않은 내용은 **임의로 구현하지 말고 질문할 것**
4. 문서와 다르게 구현해야 할 이유가 있다면 **WorkNote에 사유를 기록**할 것

### 기능별 참조 문서

| 구현 기능 | 참조 문서 |
|----------|----------|
| 런 구조, 던전, 방 종류 | `GameDesignDocument.md` |
| 코어, 부품 슬롯, 부품 등급 | `PartsSystem.md` |
| 턴 구조, 스킬 선택, 적 행동 | `CombatSpecification.md` |
| 적 티어, 적 패턴 | `EnemySystem.md` |
| 이벤트, 작업대, 상자 | `GameDesignDocument.md` |

---

## 문서 수정 규칙

- 기획 변경 시 **해당 문서를 즉시 업데이트**한다.
- 문서 수정 시 파일 상단 프론트매터의 `updated` 날짜를 갱신한다.
- 기존 내용을 삭제할 때는 이유를 WorkNote에 기록한다.
- 문서 간 링크는 `[[파일명]]` 형식으로 유지한다 (Obsidian 호환).

### 프론트매터 필수 항목

```yaml
---
tags: [project/project-mecha, document/specification]
status: in-progress | done | deprecated
version: 버전번호
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

---

## ARCHITECTURE.md 업데이트 규칙

커밋할 때마다 프로젝트 파일 변경점을 추적하여 **루트의 `ARCHITECTURE.md`** 에 반영한다.

**반영 대상 변경점:**
- 새 파일 또는 폴더 추가
- 파일 또는 폴더 삭제
- 파일 이동 또는 이름 변경

**반영 방법:**
1. 커밋 전 변경된 파일 목록을 확인한다.
2. `ARCHITECTURE.md`의 해당 항목을 추가/수정/삭제한다.
3. `ARCHITECTURE.md` 수정도 같은 커밋에 포함한다.

> **주의:** `ARCHITECTURE.md` 업데이트 없이 파일 구조를 변경하는 커밋은 허용하지 않는다.

---

## WorkNote 작성 규칙

커밋할 때마다 `WorkNote/YYYY-MM-DD.md` 파일에 작업 일지를 작성한다.
같은 날 여러 커밋이 있으면 하나의 파일에 이어서 기록한다.

### WorkNote 템플릿

```markdown
---
tags: [project/project-mecha, document/worknote]
date: YYYY-MM-DD
---

# 작업 일지 — YYYY-MM-DD

## 작업 내용

### [커밋 태그] 작업 제목
- 구현한 내용 요약
- 참조한 문서: [[문서명]]
- 변경된 파일: `Scenes/폴더/파일.gd`

## 특이사항 / 결정 사항

- 기획 문서와 다르게 구현한 경우 사유 기록
- 미결 사항이나 다음 작업에서 이어갈 내용 기록

## 다음 작업 예정

- [ ] 다음에 할 작업 1
- [ ] 다음에 할 작업 2
```

### WorkNote 예시

```markdown
---
tags: [project/project-mecha, document/worknote]
date: 2026-04-28
---

# 작업 일지 — 2026-04-28

## 작업 내용

### [feat] 부품 장착 드래그앤드롭 구현
- Piece.gd에 부품 데이터 클래스 정의
- PieceSlot.tscn에 드래그앤드롭 로직 추가
- 참조한 문서: [[PartsSystem]]
- 변경된 파일: `Scenes/Mech/Piece.gd`, `Scenes/Mech/PieceSlot.tscn`

## 특이사항 / 결정 사항

- 경량 코어 공격력 수치 x0.6 → 플레이테스트 후 재조정 예정

## 다음 작업 예정

- [ ] 전투 턴 매니저 구현
- [ ] 스킬 선택 UI 연동
```

---

## 문서 목록 및 상태

| 문서 | 상태 | 최종 수정 |
|------|------|----------|
| GameDesignDocument.md | in-progress | 2026-04-28 |