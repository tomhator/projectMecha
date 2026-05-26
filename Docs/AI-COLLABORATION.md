---
tags: [project/project-mecha, document/agent-rules]
status: active
version: 1.0
created: 2026-05-26
updated: 2026-05-26
---

# AI 협업 및 하네스 가이드

이 문서는 Cursor, Claude, Codex, VS Code 등 특정 IDE나 AI 도구에 묶이지 않는 프로젝트 공용 규칙이다. 도구별 설정 파일은 이 문서를 참조하는 어댑터로만 유지한다.

## 프로젝트 컨텍스트

- 프로젝트명: PROJECT MECHA(가제)
- 장르: 메카 빌더 턴제 로그라이크
- 엔진: Godot 4.x / GDScript
- 프로젝트 경로: `/Users/yusung/gameDev/projectMecha`
- 핵심 루프: 던전 탐색 -> 부품 획득 -> 메카 조립 -> 턴제 전투
- 전체 구조와 용어는 루트 `ARCHITECTURE.md`를 우선 참조한다.

## 공통 작업 원칙

- 작업 전 `ARCHITECTURE.md`, 관련 `Docs/` 문서, 대상 폴더의 `AGENTS.md`를 먼저 확인한다.
- 2개 이상의 파일을 수정하거나 새 시스템을 도입하면, 구현 전에 변경 파일 목록과 영향 범위를 계획으로 먼저 제시하고 승인을 받는다.
- 문서에 없는 기능은 임의로 구현하지 않고, 필요한 경우 사용자에게 결정 사항을 확인한다.
- 변경은 요청 범위에 집중하고, 사용자나 도구가 만든 기존 워킹트리 변경을 임의로 되돌리지 않는다.
- 설명과 작업 기록은 한국어를 기본으로 작성한다.

## GDScript 규칙

- Godot 4.x 문법만 사용한다. Godot 3 문법(`yield`, `onready var`, `export var`, 구형 `connect`)은 사용하지 않는다.
- 클래스명은 `PascalCase`, 변수와 함수명은 `snake_case`, 상수는 `UPPER_SNAKE_CASE`를 사용한다.
- 변수와 함수 반환값에는 가능한 한 타입을 명시한다.
- 노드 참조는 `@onready`, `$`, `%`의 의도를 구분해서 사용한다.
- 시그널은 `signal my_signal`, `my_signal.emit()` 형태를 우선 사용한다.
- `:=` 추론 선언은 피하고 명시 타입 선언을 선호한다.

## 커밋 전 규칙

- 커밋 메시지는 `feat:`, `fix:`, `design:`, `refactor:`, `chore:` 중 하나로 시작한다.
- 파일 구조가 바뀌면 `ARCHITECTURE.md`를 함께 갱신한다.
- 모든 커밋 전 `Docs/WorkNote/YYYY-MM-DD.md`에 작업 내용을 기록한다.
- 다음 작업이 바뀌면 `Docs/TODO/TODO-NEXT.md`를 갱신한다.

## 세션 컨텍스트 저장

- 긴 작업이나 여러 차례 논의가 이어져 다음 세션 인수인계가 필요하면 `Docs/SESSION_CONTEXT/{주제}.md`에 요약을 저장한다.
- 같은 주제의 과거 기록은 `Docs/SESSION_CONTEXT/old/`에 보관한다.
- 저장 문서는 요약, 변경 파일, 결정 사항, 미완료 항목, 관련 문서 링크를 포함한다.

## 검증 하네스

IDE와 무관한 표준 검증 진입점은 아래 명령이다.

```bash
bash Scripts/Validation/validate.sh
```

Godot 실행 파일이 PATH에 없으면 `GODOT_BIN`으로 명시한다.

```bash
GODOT_BIN="/Users/yusung/Desktop/고도/Godot.app/Contents/MacOS/Godot" bash Scripts/Validation/validate.sh
```

`gdparse`는 설치되어 있으면 GDScript 파서를 추가로 실행하고, 없으면 `SKIP`으로 처리한다. 필수 검증 축은 Godot headless 프로젝트 로드, 리소스 무결성, 주요 씬 스모크, P0 전투 플로우다.

VS Code의 `PROJECT_MECHA_GODOT4` 환경변수는 Godot Tools 확장 편의 설정이다. 하네스 자체는 `GODOT_BIN`, `godot`, `godot4`, 로컬 후보 경로를 순서대로 사용하므로 특정 IDE 설정에 의존하지 않는다.

## 도구별 설정의 역할

- `.cursor/`: Cursor가 이 공용 규칙을 읽게 하는 얇은 래퍼다. 프로젝트 원본 규칙은 이 문서다.
- `.claude/hooks/`: Claude Code 사용 시 자동 검증을 연결하는 보조 훅이다. 수동 검증 기준은 항상 `Scripts/Validation/validate.sh`다.
- `.vscode/settings.json`: VS Code Godot Tools 편의 설정이다. 검증 하네스의 필수 조건이 아니다.
