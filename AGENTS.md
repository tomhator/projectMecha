# PROJECT MECHA(가제) — Project Agent Guide

## 프로젝트 개요

**장르:** 메카 빌더 턴제 로그라이크
**엔진:** Godot 4.x (GDScript)
**목표:** 2026년 내 데모 완성

핵심 루프: 던전 탐색 → 부품 획득 → 메카 조립 → 턴제 전투

---


## 파일 구조 참조

프로젝트의 전체 파일 및 폴더 구조는 **`ARCHITECTURE.md`** 를 참조할 것.
새 파일을 추가하거나 구조를 파악할 때 반드시 이 파일을 먼저 확인한다.

---

## 작업 전 필수 체크리스트

> **모든 작업 시작 전 아래 순서를 반드시 따를 것.**

1. **`ARCHITECTURE.md` 확인** — 현재 프로젝트 파일 구조를 파악한다.
2. **Docs 폴더 확인** — 구현할 기능과 관련된 기획 문서를 먼저 읽는다.
3. **Scenes 폴더 구조 확인** — 기존 파일과 충돌하지 않도록 파악한다.
4. **AGENTS.md 확인** — 해당 폴더의 규칙을 숙지한다.
5. **구현** — 기획 문서 기반으로 코드 작성.
6. **커밋 시 WorkNote 및 TODO 작성** — `Docs/WorkNote/YYYY-MM-DD.md`에 작업 일지 기록 및 다음 작업을 위한 `TODO-YYYY-MM-DD.md` 작성.

---

## 코드 규칙 (GDScript)

- Godot **4.x** 문법만 사용할 것. Godot 3 문법 절대 혼용 금지.
- 클래스명: `PascalCase`
- 변수/함수명: `snake_case`
- 상수: `UPPER_SNAKE_CASE`
- 모든 변수에 타입 명시 권장: `var hp: int = 100`
- 파일 상단에 `class_name` 선언 권장

### Godot 3 vs 4 주요 차이 (혼동 주의)

| Godot 3 | Godot 4 |
|---------|---------|
| `onready var` | `@onready var` |
| `export var` | `@export var` |
| `yield()` | `await` |
| `connect("signal", obj, "method")` | `signal.connect(method)` |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` |

---

## 커밋 규칙

```
[태그] 작업 내용 요약

태그 종류:
feat    - 새 기능 추가
fix     - 버그 수정
design  - 기획/문서 변경
refactor- 코드 리팩토링
chore   - 기타 잡무
```

예시: `feat: 부품 장착 드래그앤드롭 구현`

커밋 시 반드시 `Docs/WorkNote/YYYY-MM-DD.md` 작성 또는 업데이트.
또한, 다음 작업을 명확히 하기 위해 반드시 `Docs/WorkNote/TODO-YYYY-MM-DD.md` (또는 `TODO-NEXT.md`) 파일을 생성하거나 업데이트하여 다음 할 일을 기록해야 합니다.

---

## 핵심 게임 상수 (참고용)

```gdscript
# 코어 타입
enum CoreType { STANDARD, LIGHT, DEFENSE }

# 부품 등급
enum PieceGrade { COMMON, RARE, EPIC }

# 부품 부위
enum PiecePart { ARM_L, ARM_R, BACK, LEG }

# 스킬 종류
enum SkillType { ATTACK, DEFENSE, HEAL, PASSIVE }
```

---

## AI 협업 워크플로우

모든 AI 어시스턴트(Claude, Cursor, Gemini 등)가 공통으로 따르는 협업 규칙이다.

### 1. 스펙 리뷰 — 코드 작성 전 계획 검토

2개 이상의 파일을 수정하거나 새 시스템을 도입하는 경우, 코드를 작성하기 **전에** 반드시 아래 순서를 따른다:

1. 작업 계획을 텍스트로 먼저 작성한다 (변경 파일 목록, 변경 이유, 영향 범위)
2. 사용자에게 계획을 제시하고 승인을 받는다
3. 승인 후 구현한다

단순 1줄 버그픽스는 이 절차를 생략할 수 있다.

---

### 2. 스킬 기반 리팩토링 — 반복 작업 패턴

자주 반복되는 작업은 아래 커스텀 커맨드 가이드를 따른다.
가이드 파일은 `.claude/commands/` 에 있다.

| 작업 | 커맨드 파일 |
|------|------------|
| 새 스킬 리소스 생성 | `.claude/commands/new-skill.md` |
| 새 적 추가 | `.claude/commands/new-enemy.md` |
| 전투 버그 조사 | `.claude/commands/combat-debug.md` |
| 파츠 시스템 수정 | `.claude/commands/parts-update.md` |

새 반복 패턴이 생기면 `.claude/commands/` 에 커맨드 파일을 추가한다.

---

### 3. 도메인 단위 코드 관리

파일 종류가 아닌 **도메인** 단위로 작업 범위를 제한한다.
각 도메인 디렉토리에는 전용 컨텍스트 파일이 있다.

| 도메인 | 경로 | 컨텍스트 파일 |
|--------|------|--------------|
| 턴제 전투 | `Scenes/Combat/` | `Scenes/Combat/CLAUDE.md` |
| 메카·적 엔티티 | `Scenes/Entities/` | `Scenes/Entities/CLAUDE.md` |
| 전역 싱글톤 | `Scripts/Autoload/` | `Scripts/Autoload/CLAUDE.md` |
| 스킬 리소스 | `Resources/Skills/` | `Resources/Skills/CLAUDE.md` |

해당 도메인 작업 시 반드시 도메인 컨텍스트 파일을 먼저 읽는다.
한 번에 두 개 이상의 도메인을 수정해야 하면 스펙 리뷰(위 1번)를 먼저 거친다.

---

### 4. 자동 검사 시스템

코드 수정 후 아래 항목을 반드시 확인한다.

| 검사 항목 | 시점 | 방법 |
|----------|------|------|
| GDScript 문법 오류 | 파일 수정 후 | `gdparse <파일>.gd` (gdtoolkit 설치 시) |
| TODO 파일 존재 | 커밋 전 | `Docs/WorkNote/TODO-YYYY-MM-DD.md` 확인 |
| 계획 문서 존재 | 대규모 수정 전 | 스펙 리뷰 절차 준수 |

Claude Code 사용 시 위 검사는 `.claude/hooks/` 훅으로 자동화되어 있다.
다른 도구 사용 시 수동으로 위 체크리스트를 따른다.

---

## 관련 문서

- `ARCHITECTURE.md` — 전체 파일 구조 및 기술 아키텍처
- `Docs/GameDesignDocument.md` — 전체 게임 설계
- `Docs/PartsSystem.md` — 부품 시스템 상세
- `Docs/WorkNote/` — 작업 일지 및 TODO