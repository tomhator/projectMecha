# Scenes — Agent Guide

## 폴더 역할

Godot 씬 파일(`.tscn`)과 스크립트 파일(`.gd`)을 관리하는 폴더.
모든 게임 로직과 UI는 이 폴더 안에 위치한다.

---


## 작업 전 필수 확인

> 새 씬이나 스크립트를 만들기 전에 아래를 확인할 것.

1. **기존 파일 구조 파악** — 이미 존재하는 `.gd`, `.tscn` 파일을 먼저 확인한다.
2. **Docs 폴더 확인** — 구현 전 반드시 관련 기획 문서를 읽는다.
   - 전투 관련 → `Docs/CombatSpecification.md`
   - 부품 관련 → `Docs/PieceSystem.md`
   - 적 관련 → `Docs/EnemySystem.md`
3. **기존 씬과의 연결 방식 확인** — 노드 경로, 시그널 구조 파악 후 작업.

---

## 파일 네이밍 규칙

| 종류 | 규칙 | 예시 |
|------|------|------|
| 씬 파일 | `PascalCase.tscn` | `CombatScene.tscn` |
| 스크립트 | `PascalCase.gd` | `TurnManager.gd` |
| 데이터 클래스 | `이름Data.gd` | `EnemyData.gd` |
| UI 컴포넌트 | `이름Screen.tscn` | `EventScreen.tscn` |

---

## 씬 구성 규칙

- 씬 하나에 **하나의 책임**만 부여한다.
- 씬 간 통신은 **시그널(Signal)** 을 우선으로 사용한다.
- 전역 상태는 **AutoLoad(싱글톤)** 로 관리한다.

### 권장 AutoLoad 목록

```
GameState   - 런 전체 상태 (현재 층, 크레딧, 코어 정보)
PieceDB     - 부품 데이터 테이블
EnemyDB     - 적 데이터 테이블
```

---

## 코드 작성 규칙

### 기본 스크립트 템플릿

```gdscript
class_name ClassName
extends Node

# ── 시그널 ──────────────────────────────
signal something_happened

# ── 익스포트 변수 ────────────────────────
@export var value: int = 0

# ── 내부 변수 ────────────────────────────
var _internal: String = ""

# ── 노드 레퍼런스 ────────────────────────
@onready var _label: Label = $Label

# ── 초기화 ──────────────────────────────
func _ready() -> void:
    pass

# ── 퍼블릭 메서드 ────────────────────────
func do_something() -> void:
    pass

# ── 프라이빗 메서드 ──────────────────────
func _helper() -> void:
    pass
```

### 주의사항

- `@onready` 없이 `$Node` 접근 금지 (null 참조 위험)
- 씬 간 직접 변수 참조 금지 → 시그널 또는 AutoLoad 사용
- Godot 3 문법 혼용 금지 (루트 AGENTS.md 참고)