# 프로젝트 메카 아키텍처 (Project Mecha Architecture)

이 문서는 Godot 4.x 엔진으로 개발되는 **프로젝트 메카**의 설계 원칙과 프로젝트 구조를 설명합니다.

## 1. 설계 원칙 (Architectural Principles)

### 1.1 데이터 중심 설계 (Data-Driven Design)
- 모든 게임 데이터는 **Resource (`.gd` 상속 스크립트 및 `.tres`)**로 정의합니다.
- 메카의 코어, 부품, 스킬 정보는 코드가 아닌 데이터로 관리하여 확장성을 확보합니다.

### 1.2 상속보다는 조합 (Composition over Inheritance)
- 복잡한 상속 계층 대신 작고 명확한 책임을 가진 컴포넌트를 사용합니다.
- 메카는 코어(Core)를 중심으로 기본 4개 부품 슬롯(팔 2, 등 1, 다리 1)과 `evolution_lord` 조건부 추가 팔 슬롯이 조합되는 구조입니다.

### 1.3 신호 기반 통신 (Signals & Events)
- 시스템 간 결합도를 낮추기 위해 Godot의 신호(Signal)와 전역 `EventBus`를 활용합니다.
- UI 업데이트, 전투 로그 처리 등 전역적인 알림은 `EventBus`를 통해 수행합니다.

---

## 2. 디렉토리 구조 (Directory Structure)

- `Asset/`: 모델, 텍스처, 오디오 등 리소스 파일.
    - `UI/hub_outer_hideout.png`: 외곽 은신처 HubScene 배경용 AI 생성 bitmap.
- `Docs/`: 기획서 및 기술 문서.
    - `AI-COLLABORATION.md`: IDE/AI 도구 독립 협업 규칙 및 검증 하네스 사용법.
    - `BaseSystem.md`: 외곽 은신처 거점 시스템, 건물형 구역, 영구 파츠 창고/런 인벤토리 분리, 크레딧+고철 경제, 성공/실패 정산 규칙.
    - `CombatSpecification.md`: 현재 전투 구조, 데모 기준, 스킬/Affix 처리 규칙의 단일 기준 문서.
    - `UI/`: UI 마스터 스펙 (`HUD.md` 등).
    - `WorkNote/`: 작업 일지 (`YYYY-MM-DD.md`).
    - `TODO/`: 활성 backlog (`TODO-NEXT.md`). 완료·이월 목록은 `TODO/old/`.
    - `DEV-GUIDE/`: 구현 가이드 아카이브 (`DEV-GUIDE/old/`).
    - `SESSION_CONTEXT/`: 세션 인수인계·백업. 현재 세션은 루트, 과거 기록은 `SESSION_CONTEXT/old/`.
- `.cursor/`: Cursor AI 에이전트 관련 설정 및 규칙.
    - `rules/`: AI 에이전트 동작 및 커밋 규칙 (`.mdc`).
- `.claude/`: Claude Code 에이전트 훅 및 설정.
    - `commands/`: 반복 작업 커맨드 가이드 (`new-skill`, `new-enemy`, `combat-debug`, `parts-update`).
    - `hooks/`: gstack 확인 및 프로젝트 검증 훅.
- `Resources/`: 데이터 모델 스크립트(`.gd`) 및 인스턴스(`.tres`).
    - `Cores/`: 코어 데이터 리소스 (`.tres`). 단일 코어 `core_base.tres`만 사용.
    - `AbilityTree/`: 어빌리티 트리 노드 리소스 (`.tres`). 5티어×공격/방어/유틸 3선택.
    - `Parts/`: 부품 데이터 리소스 (`.tres`).
    - `Enemies/`: 적 데이터 리소스 (`.tres`). 매립지 일반 역할 병종 4종, 매립지 엘리트 2종, Caller 호출 전용 고철 잡졸, 수집가 보스 포함.
    - `Skills/`: 스킬 데이터 리소스 (`.tres`). 기본 코어 공격·파츠 활용 어빌리티·매립지 일반/엘리트 병종·저격·수집가 전용 스킬 포함. `CLAUDE.md`에 스킬 리소스 도메인 작업 규칙 정리.
    - `Test/`: 개발용 테스트 리소스.
- `Scenes/`: 게임의 각 화면 및 시스템 씬.
    - `Assembly/`: 메카 조립 씬.
        - `AssemblyScene.tscn` / `AssemblyScene.gd`: 조립 씬 루트. 좌6:우4 레이아웃, 인벤 4×4 그리드, 선택 상세 패널, 전투 스킬 배치 프리뷰, 소켓/카드 동적 생성 및 하중 표시.
        - `PartSocketUI.gd`: 파츠 드롭 수신 소켓 컴포넌트. 호환/비호환 시각 피드백 포함.
        - `PartCardUI.gd`: 인벤토리 파츠 카드 컴포넌트. 드래그 발신 및 등급별 색상 표시.
    - `Base/`: 런 사이 외곽 은신처 거점 씬.
        - `HubScene.tscn` / `HubScene.gd`: 프로젝트 메인 씬. 거점 재화/최근 런 요약, 건물형 버튼 5개(격납고·코어 연구대·작전 단말·출격 게이트·시스템 콘솔), 기록/옵션 스텁.
        - `HangarScene.tscn` / `HangarScene.gd`: 영구 파츠 창고, 출격 장착 슬롯 4개+조건부 추가 팔 슬롯, 런 인벤토리 16칸, 수리/분해/되돌리기 서비스.
    - `Combat/`: 전투 씬 및 턴 매니저. `CLAUDE.md`에 전투 도메인 작업 규칙 정리.
    - `CoreSelect/`: 어빌리티 트리 씬 (런 시작 전 트리 노드 선택 UI).
    - `Dungeon/`: 던전 맵, 보상, 런 종료 씬.
    - `Entities/`: 메카 및 적 엔티티 관련 스크립트. `CLAUDE.md`에 Entity 도메인 작업 규칙 정리.
        - `MechaEntity.gd`: 플레이어 스킬·affix·`get_part_at_slot`·`steal_part_at_slot`.
        - `EnemyEntity.gd`: 적 행동·저격 내구도·예고 슬롯 발행.
        - `CollectorArmEntity.gd`: 수집가 보스 팔 서브 엔티티(방어 팔 보호 역할 포함).
        - `BossCollectorEntity.gd`: 수집가 코어(팔 보호·노출·재수집·팔 탈취).
    - `UI/`: 공용 UI 컴포넌트.
        - `RunStatusStrip.tscn` / `RunStatusStrip.gd`: 런 상단 HUD(층·HP/쉴드 바+현재값·크레딧·설정 스텁). 주요 런 씬에 인스턴스.
        - `CombatUi.tscn` / `CombatUI.gd`: 전투 UI(좌 플레이어/우 적·행동력·스킬·다중 적 타겟팅·수집가 formation).
- `Scripts/`: 전역 유틸리티, 검증 스크립트 및 싱글톤(AutoLoad).
    - `Autoload/`: `EventBus`, `GameState`, `DungeonManager`, `PartsFactory`, `RewardManager` 등 전역 시스템. `CLAUDE.md`에 AutoLoad 도메인 작업 규칙 정리.
    - `Validation/`: Godot 4 문법 패턴, 프로젝트 문서, `gdparse`, Godot headless 로드, 리소스 무결성, 주요 씬 스모크, 거점 상태 계약, 최근 작업 회귀 계약 검사 스크립트.

---

## 3. 핵심 시스템 (Core Systems)

### 3.1 메카 조립 시스템 (Mecha Assembly)
메카는 하나의 **코어(CoreData)**와 기본 4개의 **부품(PartsData)** 슬롯, 조건부 `EXTRA_ARM` 슬롯으로 구성됩니다.
- **슬롯 구성:** 팔(Arm) 2개, 등(Back) 1개, 다리(Leg) 1개. `evolution_lord`가 붙은 정상 ARM/BACK 파츠가 있으면 추가 팔 슬롯 1개가 열린다.
- **능력치 합산:** 장착된 부품의 무게, 공격력, 방어력 등의 스탯이 코어의 기본 스탯에 합산되어 메카의 최종 성능을 결정합니다.
- **드래그앤드롭 UI:** `PartCardUI`(인벤토리 카드)를 `PartSocketUI`(소켓)에 드롭하여 장착. Godot 4의 `_get_drag_data` / `_can_drop_data` / `_drop_data` 사용. 소켓 클릭으로 해제.

### 3.1.1 어빌리티 트리 시스템 (Ability Tree)
코어는 `core_base.tres` 1개로 고정. 거점에서 노드를 영구 연구·강화하고, 던전 시작 전 던전 특성을 읽어 출격 빌드를 구성한다.
- **전투 선택:** 기본 공격 1개 + 파츠 활용 어빌리티 1개.
- **트리 선택:** 연구한 노드 중 5개 티어에서 각 1개까지 장착. 공격/방어/유틸 15노드.
- **외형:** 이번 출격에 장착한 티어별 노드가 코어 전용 외장 슬롯을 바꾼다.
- **상세:** [[AbilityTreeSystem]]

### 3.2 턴제 전투 시스템 (Turn-based Combat)
- **교대식 턴제:** 플레이어 턴과 적 턴이 번갈아 진행됩니다.
- **스킬 기반 행동:** 부품에 할당된 **SkillData**, 선택한 기본 코어 공격, 조건부 파츠 활용 어빌리티를 사용하여 전투합니다.
- **행동 횟수:** 코어 기본값(2) + 트리 기동 분기 노드 + 부품 기여로 결정됩니다.

### 3.3 전역 시스템 (Global Systems)
- **EventBus:** 게임 내 전역 이벤트를 중개합니다 (전투 시작/종료, 부품 장착, 스탯 변경 등).
- **GameState:** 현재 런의 상태(층수, 크레딧, 고철, 메카 HP 및 장착 부품)와 거점 영구 상태(메타 크레딧/고철, 영구 창고, 출격 장착/인벤토리, 최근 런 정산)를 유지하고 관리합니다.
- **PartsFactory:** `PartsData` 템플릿을 복제해 `stat_multiplier`·affix 개수(드롭 등급별)·`affix_pool` 롤 및 `durability` 초기화를 수행합니다.

### 3.4 데이터 모델 (Data Models)
현재 프로젝트에서 사용 중인 핵심 데이터 구조는 다음과 같습니다:
- **CoreData:** 메카의 기본 HP, 하중 제한, 행동 횟수 등을 정의.
- **PartsData:** 슬롯 타입·템플릿 등급·`drop_weight`/`affix_pool`·저장 복원용 `template_path`·롤 결과(`stat_multiplier`, `rolled_affixes`)·`max_durability`/`durability`·`is_worn()`/`is_broken()`/`grade()` 및 스킬 참조.
- **SkillData:** 피해량, AP 비용, 대상 지정(자기/적/선택 파츠), 부가 효과(버프/디버프), 수리·무료 스킬·AP 부여 같은 특수 동작을 정의.
- **EnemyData:** 적의 HP, 쉴드, 공격 배율, 티어, 스킬 목록을 정의.

---

## 4. 코딩 표준 (Coding Standards)

- **정적 타이핑:** 모든 GDScript 변수 및 함수 리턴 타입에 정적 타이핑을 적용합니다.
- **명명 규칙:** 클래스는 **PascalCase**, 변수 및 함수는 **snake_case**를 사용합니다.
- **리소스 활용:** 반복되는 상수나 테이블 형태의 데이터는 스크립트 내 하드코딩 대신 `.tres` 리소스를 활용합니다.
