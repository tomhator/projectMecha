# 프로젝트 메카 아키텍처 (Project Mecha Architecture)

이 문서는 Godot 4.x 엔진으로 개발되는 **프로젝트 메카**의 설계 원칙과 프로젝트 구조를 설명합니다.

## 1. 설계 원칙 (Architectural Principles)

### 1.1 상속보다는 조합 (Composition over Inheritance)
- 깊은 상속 계층 구조 대신 작고 재사용 가능한 컴포넌트(Node)를 지향합니다.
- 동작(Behavior)을 정의하기 위해 **컴포넌트**(예: `HealthComponent`, `WeaponComponent`, `MovementComponent`)를 사용합니다.

### 1.2 데이터 중심 설계 (Data-Driven Design)
- 설정, 스탯 및 데이터 저장을 위해 **Resource (`.tres`)**를 적극 활용합니다.
- 메카의 부품(무기, 다리, 몸체 등)은 Resource로 정의하여 쉽게 교체하고 커스텀할 수 있도록 합니다.

### 1.3 통신 방식 (Signals & Events)
- **Call Down, Signal Up:** 부모 노드는 자식의 메서드를 호출하고, 자식은 신호(Signal)를 통해 부모나 전역 이벤트 버스에 알립니다.
- 시스템 간 통신(예: UI 업데이트, 게임 상태 변경)을 위해 전역 **EventBus** (Autoload)를 사용합니다.

### 1.4 유한 상태 머신 (Finite State Machines, FSM)
- 메카나 AI와 같이 복잡한 엔티티는 상태 관리(예: `Idle`, `Moving`, `Boosting`, `Attacking`)를 위해 FSM을 사용합니다.

---

## 2. 디렉토리 구조 (Directory Structure)

- `Asset/`: 원본 및 임포트된 에셋 (모델, 텍스처, 오디오).
- `Docs/`: 기획서 및 기술 문서.
- `Resources/`: 데이터 전용 리소스(`.tres`) 및 커스텀 리소스 스크립트(`.gd`).
    - `Parts/`: 메카 부품 데이터.
    - `Stats/`: 밸런싱 및 설정 데이터.
- `Scenes/`: Godot 씬(`.tscn`)과 해당 씬의 스크립트(`.gd`).
    - `Core/`: 전역 시스템 (카메라, UI, 게임 매니저).
    - `Entities/`: 메카, 파일럿, 적 유닛.
    - `Levels/`: 게임 레벨 및 환경.
    - `UI/`: HUD, 메뉴, 커스터마이징 화면.
- `Scripts/`: 전역 스크립트, 유틸리티 및 정적 클래스.
    - `Autoload/`: 싱글톤 (EventBus, GameState, SaveSystem).

---

## 3. 핵심 시스템 (Core Systems)

### 3.1 메카 컨트롤러 (Mecha Controller)
메카는 게임의 핵심 엔티티이며 다음으로 구성됩니다:
- **MechaBase:** 물리, 입력 처리 및 상태 관리를 담당합니다.
- **MechaParts:** 베이스에 부착되는 시각적/기능적 노드들입니다.
- **WeaponSystem:** 발사 로직과 탄약 관리를 담당합니다.

### 3.2 커스터마이징 시스템 (Customization System)
`MechaPart` 리소스를 교체하는 시스템입니다. 각 부품은 다음 정보를 포함합니다:
- 시각적 메쉬 (Visual Mesh).
- 스탯 보정치 (무게, 에너지, 방어력 등).
- 부착 지점 (Hardpoints).

### 3.3 물리 및 상호작용 (Physics & Interaction)
- 견고한 3D 충돌 및 상호작용을 위해 **Jolt Physics**를 사용합니다.
- 레이어 구성:
    - `1`: 환경 (Environment)
    - `2`: 플레이어 (Player)
    - `3`: 적 (Enemies)
    - `4`: 투사체 (Projectiles)

---

## 4. 코딩 표준 (Coding Standards)

- **정적 타이핑:** GDScript 사용 시 항상 정적 타이핑을 적용합니다 (`var x: int = 5`).
- **명명 규칙:** 클래스 명은 **PascalCase**, 변수 및 함수 명은 **snake_case**를 사용합니다.
- **문서화:** 공개 함수나 복잡한 로직에는 독스트링(docstrings)을 작성합니다.
