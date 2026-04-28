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
6. **커밋 시 WorkNote 작성** — `Docs/WorkNote/YYYY-MM-DD.md`에 작업 일지 기록.

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

## 관련 문서

- [[Docs/GameDesignDocument]] — 전체 게임 설계