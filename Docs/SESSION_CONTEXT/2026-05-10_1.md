# Project Mecha — 세션 인수인계 문서

> 새 세션 시작 시 이 파일을 먼저 읽을 것.
> 마지막 업데이트: 2026-05-10 (Phase 12 완료)

---

## 프로젝트 개요

- **장르:** 메카 빌더 턴제 로그라이크
- **엔진:** Godot 4.x (GDScript)
- **핵심 루프:** 코어 선택 → 던전 탐색(10층) → 전투 → 부품 획득 → 메카 조립 → 반복 → 보스 클리어

---

## 현재 구현 완료 상태 (Phase 1~11)

### Phase 1 — 데이터 레이어
- `Resources/CoreData.gd` — 코어 타입(VANGUARD/STRIKER/BULWARK), HP, 쉴드, 공격배율, 행동횟수, 슬롯
- `Resources/PartsData.gd` — 부품 타입(ARM_L/ARM_R/BACK/LEG), 등급(COMMON/RARE/EPIC), 무게, 스킬
- `Resources/SkillData.gd` — 스킬 타입(ATTACK/DEFENSE/HEAL/PASSIVE), 데미지, 쿨다운, 타겟, 버프/디버프
- `Resources/EnemyData.gd` — 적 티어(NORMAL/ELITE/BOSS), HP, 쉴드, 공격배율, 스킬
- `Resources/RoomData.gd` — 방 타입(BATTLE_NORMAL/BATTLE_ELITE/CHEST/ENCOUNTER/WORKSHOP/BOSS), 힌트, 보상등급

### Phase 2 — Autoload (Singletons)
- `Scripts/Autoload/EventBus.gd` — 전역 시그널 허브. `class_name` 없음 (Autoload 충돌 방지)
- `Scripts/Autoload/GameState.gd` — 런 상태 관리 (HP, 쉴드, 인벤토리, 크레딧, 장착파츠, 공격배율)
- `Scripts/Autoload/DungeonManager.gd` — 10층 던전 생성, 방 선택, 씬 전환, 보상 분기
- `Scripts/Autoload/RewardManager.gd` — 등급별 파츠 풀, 선택지 3개 생성

### Phase 3 — 엔티티
- `Scenes/Entities/MechaEntity.gd` — 플레이어 전투 엔티티. 스킬/쿨다운 관리, 데미지는 GameState 위임
- `Scenes/Entities/EnemyEntity.gd` — 적 전투 엔티티. 자체 HP/쉴드, 랜덤 행동 결정, 다음 행동 예고

### Phase 4 — 전투 시스템
- `Scenes/Combat/TurnManager.gd` — 턴 진행 오케스트레이터 (플레이어턴/적턴/전투종료)
- `Scenes/Combat/CombatScene.gd` — 전투 씬 루트. EnemyEntity 동적 생성, 시그널 연결
- `Scenes/UI/CombatUi.gd` — 스킬 버튼, 플레이어/적 HP 바, 적 행동 예고 라벨

### Phase 5 — 던전 구조
- `Scenes/CoreSelect/CoreSelectScene.gd` + `.tscn` — 코어 3종 선택 → `GameState.start_run()` → `DungeonManager.start_dungeon()`
- `Scenes/Dungeon/DungeonMapScene.gd` + `.tscn` — 층/HP/크레딧 표시, 방 선택 버튼, 조립 버튼
- `Scenes/Dungeon/RunEndScene.gd` + `.tscn` — 런 클리어/종료 메시지, 재시작 버튼
- 플레이스홀더 씬: `ChestScene`, `EncounterScene`, `WorkshopScene` (모두 실제 구현됨)

### Phase 6 — 부품 보상 시스템
- `Scenes/Dungeon/RewardScene.gd` + `.tscn` — 파츠 3선택 UI, 크레딧 지급
- 방 타입별 보상 등급 결정: NORMAL→COMMON, ELITE→RARE, BOSS→EPIC, CHEST→RARE/EPIC(25%)
- `DungeonManager.on_room_cleared()` → 보상 있는 방이면 RewardScene 경유 → `continue_after_reward()` → 다음 층

### Phase 7 — 메카 조립 UI
- `Scenes/Assembly/AssemblyScene.gd` + `.tscn` — 슬롯 4개 + 인벤토리 목록, 장착/해제 버튼
- `DungeonMapScene`에서 "조립" 버튼으로 진입

### Phase 8 — 적 데이터 연동
- `EnemyEntity.setup_from_data(data: EnemyData)` 메서드 추가
- `DungeonManager.get_enemies_for_current_room()` — 방 타입별 적 풀에서 동적 생성
- `CombatScene.tscn`에서 하드코딩 EnemyEntity 제거, 코드로 동적 생성

### Phase 9 — 크레딧 + 작업대
- `RewardScene`에서 전투 보상 시 크레딧 지급 (일반 20~40, 엘리트 50~80, 보스 80~100)
- `DungeonMapScene`에 크레딧 표시
- `WorkshopScene.gd` — SERVICES 딕셔너리 기반 서비스 3종 (HP 50회복/쉴드 완전/HP 완전), 크레딧 소모

### Phase 10 — 조우 이벤트
- `EncounterScene.gd` — 이벤트 텍스트 5종, "한다/지나간다" 선택, 결과 A~E
- `GameState.attack_multiplier` 추가 (조우 이벤트 D/E에서 변동)
- `MechaEntity.use_skill()` ATTACK에 `* GameState.attack_multiplier` 적용

### Phase 12 — 데모 스코프 완성 (완료)
- **COMMON 파츠 12개 달성** — `part_arm_l_burst`, `part_arm_r_barrier`, `part_back_coolant`, `part_back_relay`, `part_leg_dampener`, `part_leg_sprint` 추가
- **적 6종 달성** — `enemy_rusher`(NORMAL), `enemy_fortress`(ELITE), `enemy_colossus`(BOSS tier=2) 추가
- **신규 스킬 3종** — `skill_railgun_shot`(RARE용), `skill_nano_repair`(EPIC BACK용), `skill_colossus_strike`(보스 전용)
- **조우이벤트 B 완성** — `PartsData.is_damaged` 필드 추가, 손상 파츠 스킬 데미지 ×0.7, 조립 씬에 ⚠ 표시
- **작업대 부품 업그레이드** — "부품 스킬 강화 (+20%)" 서비스 추가 (60 크레딧), UpgradePanel UI 추가
- `MechaEntity.gd` — `_skill_to_part` 매핑으로 손상 파츠 판별

### Phase 11 — 버그 정리 + 밸런싱 (완료)
- `CombatUi.gd` null 체크 수정 (`current_hp != null` → `current_core != null`)
- `MechaEntity.gd` 공격 로그에 실제 데미지(attack_multiplier 반영) 출력
- `TurnManager.player_action_required` 시그널에 `skill_cooldowns: Dictionary` 추가
- `CombatUi._rebuild_skill_buttons()` — 쿨다운 중인 스킬 비활성 버튼 + "(N턴)" 표시
- `TurnManager` ternary 타입 경고 수정 (`str(target.name)`)

---

## 프로젝트 파일 구조 (현재)

```
ProjectMecha/
├─ Resources/
│  ├─ CoreData.gd, PartsData.gd, SkillData.gd, EnemyData.gd, RoomData.gd
│  ├─ Cores/         core_vanguard.tres, core_striker.tres, core_bulwark.tres
│  ├─ Parts/
│  │  ├─ common/     arm_l_cannon, arm_l_gatling, arm_l_burst (3종)
│  │  │              arm_r_scatter, arm_r_shield, arm_r_barrier (3종)
│  │  │              back_repair, back_coolant, back_relay (3종)
│  │  │              leg_anchor, leg_dampener, leg_sprint (3종) = 12개
│  │  ├─ rare/       arm_l_piercer, arm_l_railgun (레일건샷 스킬)
│  │  │              arm_r_interceptor, arm_r_rupture
│  │  │              back_emergency_patch, back_overclock
│  │  │              leg_reactive_plating, leg_thruster = 8개
│  │  └─ epic/       arm_l_plasma_lance, arm_r_aegis_breaker
│  │                 back_nano_forge (나노수복 스킬), leg_quantum_anchor = 4개
│  ├─ Skills/        skill_cannon_shot, skill_heavy_punch, skill_iron_shield,
│  │                 skill_rapid_fire, skill_repair, skill_scatter_shot,
│  │                 skill_railgun_shot(RARE), skill_nano_repair(EPIC),
│  │                 skill_colossus_strike(BOSS)
│  ├─ Enemies/       enemy_scrapper(N), enemy_guard_unit(N), enemy_rusher(N)
│  │                 enemy_warlord(E), enemy_fortress(E)
│  │                 enemy_colossus(BOSS)
│  └─ Test/          test_core.tres, test_parts_arm_l.tres, test_skill_attack.tres, test_skill_heal.tres
├─ Scripts/Autoload/
│  ├─ EventBus.gd       (Autoload 1순위)
│  ├─ GameState.gd      (Autoload 2순위)
│  ├─ DungeonManager.gd (Autoload 3순위)
│  └─ RewardManager.gd  (Autoload 4순위)
├─ Scenes/
│  ├─ CoreSelect/    CoreSelectScene.tscn + .gd
│  ├─ Dungeon/       DungeonMapScene, RewardScene, RunEndScene,
│  │                 ChestScene, EncounterScene, WorkshopScene
│  ├─ Combat/        CombatScene.tscn + .gd, TurnManager.gd
│  ├─ Assembly/      AssemblyScene.tscn + .gd
│  ├─ Entities/      MechaEntity.gd, EnemyEntity.gd
│  └─ UI/            CombatUi.tscn + .gd
└─ Docs/
   ├─ GameDesignDocument.md
   ├─ WorkNote/
   └─ SESSION_CONTEXT.md  ← 이 파일
```

---

## 핵심 코드 구조 요약

### GameState 주요 변수
```gdscript
var is_run_active: bool
var current_floor: int
var current_core: CoreData
var current_hp: float
var current_shield: float
var current_payload: float
var current_action_count: int
var equipped_parts: Dictionary  # CoreData.CoreSlot → PartsData (null=빈슬롯)
var inventory: Array[PartsData]
var credits: int
var attack_multiplier: float    # 조우이벤트 D/E에서 변동, 기본값 1.0
```

### 씬 전환 흐름
```
CoreSelectScene
  → GameState.start_run(core) + DungeonManager.start_dungeon()
  → DungeonMapScene
    → [방 선택] DungeonManager.select_room(room)
      → CombatScene / ChestScene / EncounterScene / WorkshopScene
        → DungeonManager.on_room_cleared()
          → [보상있는방] RewardScene → DungeonManager.continue_after_reward()
          → [floor > 10] RunEndScene
          → [otherwise] DungeonMapScene
    → [조립버튼] AssemblyScene → DungeonMapScene
  → [패배] DungeonManager.on_run_failed() → GameState.end_run() → RunEndScene
```

### DungeonManager 핵심 함수
```gdscript
start_dungeon()               # 10층 생성 후 DungeonMapScene으로
get_current_choices() → Array # 현재 층 선택지
select_room(room)             # 방 선택 → 씬 전환
on_room_cleared()             # 보상 분기 후 다음 층
on_run_failed()               # 패배 처리 → RunEndScene
continue_after_reward()       # 보상 선택 후 층 전진
get_current_room() → RoomData # 현재 방 정보
get_enemies_for_current_room() → Array[EnemyData]
```

### TurnManager 시그널
```gdscript
signal phase_changed(phase: TurnPhase)
signal player_action_required(available_skills: Array[SkillData], skill_cooldowns: Dictionary, enemies: Array[EnemyEntity])
signal combat_ended(player_won: bool)
```

### EventBus 주요 시그널
```gdscript
signal combat_started
signal combat_ended(player_win: bool)
signal hp_changed(entity: Node, new_hp: float, max_hp: float)
signal shield_changed(entity: Node, new_shield: float, max_shield: float)
signal payload_changed(entity: Node, new_payload: float, max_payload: float)
signal credits_changed(new_amount: int)
signal inventory_changed(inventory: Array[PartsData])
signal parts_equipped(parts: PartsData, slot: CoreData.CoreSlot)
signal parts_unequipped(parts: PartsData, slot: CoreData.CoreSlot)
signal skill_used(entity: Node, skill: SkillData)
signal skill_cooldown_changed(entity: Node, skill: SkillData, new_cooldown: int)
```

---

## 알려진 미완성 항목

1. **코어별 스탯 수치 미검증** — `core_vanguard.tres`, `core_striker.tres`, `core_bulwark.tres` Inspector 값이 GDD §3.1 기준으로 올바르게 설정되어 있는지 플레이테스트 필요.
   - VANGUARD: 평균 스탯, 행동 1회
   - STRIKER: 공격력 x0.6, 행동 2회, 하중제한↓
   - BULWARK: HP↑↑, 공격력↓, 행동 1회

2. **전체 플레이 테스트 미완** — 10층 완주, 패배 재시작, 조우 이벤트 결과 A~E 각각 확인

---

## 다음 세션에서 할 일 (우선순위)

1. **코어 3종 스탯 검증 및 밸런싱** — GDD §3.1 기준으로 Inspector 값 확인
2. **전체 플레이 테스트 + 버그 수집** — 10층 완주, 패배 재시작, 조우이벤트 A~E
3. **ARCHITECTURE.md 파일 구조 업데이트** — Phase 12에서 추가된 파일 반영

---

## Godot 4 주요 규칙 (이 프로젝트)

- Autoload 스크립트에 `class_name` 선언 금지 (전역 이름 충돌)
- 씬 전환: `get_tree().change_scene_to_file("res://...")`
- 신호 연결: `signal.connect(method)` (Godot 3 문법 혼용 금지)
- `@onready var` 사용, `export var` 대신 `@export var`
- 모든 변수 타입 명시 권장
