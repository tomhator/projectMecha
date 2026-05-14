# UI / Run HUD 마스터 스펙

런 중 공통 상단 **RunStatusStrip**과 씬별 본문 레이아웃 규칙을 정의한다.

---

## 0. 전역 원칙

| 구분 | 규칙 |
|------|------|
| Run HUD | 화면 **상단 풀블리드** (`top/left/right = 0`). 높이 기본 **56px** (조정 시 본 문서 수정). |
| 화면 여백 | 스트립 **내부** 좌우 패딩(기본 12px) + 스트립 **아래** 본문 `MarginContainer`로 가장자리 여백(기본 16px). |
| 수치 | 그리드·카드 크기는 구현과 맞춰 여기에 주석으로 유지한다. |

---

## 1. RunStatusStrip (좌 → 우)

1. **층**: 런 비활성 시 `층: —`, 런 중 `층: N`.
2. **HP**: `ProgressBar` + 바 **아래** 라벨 — **현재 HP 숫자만** (최대는 `max_value`).
3. **쉴드**: 동일, **현재 쉴드만**.
4. **크레딧**: `크레딧: N`.
5. **설정**: 우측 버튼 → 1차 `AcceptDialog` 스텁(제목 "설정 (준비 중)").

데이터: `EventBus` — `hp_changed`, `shield_changed`, `credits_changed`, `floor_changed`.  
엔티티 필터: `hp_changed` / `shield_changed`에서 **`EnemyEntity`는 무시**하고 `GameState`만 반영.

---

## 2. PartCardUI — 파츠 카드 표시 명세

파츠 카드는 조립 씬 인벤토리·보상 씬 등 여러 곳에서 공통으로 사용한다.
최소 크기 **220 × 110** (기존 80 → 110으로 확장).

### 2.1 레이아웃 (VBox, separation 2)

```
┌──────────────────────────────────┐
│ [접두사] 파츠이름         ⚠  💀  │  ← 줄 1: 이름 + 상태 태그
│ [타입]                           │  ← 줄 2: 타입 라벨
│ 스킬 설명 (autowrap)             │  ← 줄 3: 스킬 라벨
│ 하중 25        ■■■□□            │  ← 줄 4: 하중 + 손상도 (HBox)
│ 과부하 모드  반격 본능            │  ← 줄 5: affix 목록 (없으면 숨김)
└──────────────────────────────────┘
```

### 2.2 줄별 규칙

**줄 1 — 이름 + 접두사 + 상태 태그**

- 접두사는 `stat_multiplier` 범위에 따라 이름 앞에 붙임 (PartsSystem §3.1 기준):

| 접두사 | 범위 | 표시 예 |
|--------|------|---------|
| `낡은` | ×0.70~0.84 | 낡은 캐논 팔 |
| (없음) | ×0.85~0.99 | 캐논 팔 |
| `정밀한` | ×1.00~1.14 | 정밀한 캐논 팔 |
| `강화된` | ×1.15~1.29 | 강화된 캐논 팔 |
| `완벽한` | ×1.30~1.50 | 완벽한 캐논 팔 |

- 상태 태그: 이름 뒤에 스페이스로 구분.
  - `is_worn()` → `⚠` (주황 `Color(1.0, 0.6, 0.1)`)
  - `is_broken()` → `💀` (적색 `Color(0.9, 0.2, 0.2)`)
  - 정상 → 태그 없음
- 폰트 색상: 등급 색 (COMMON 회색 / RARE 파랑 / EPIC 보라)

**줄 2 — 타입**

- `[ARM_L]` 형식, 폰트 10, 초록 `Color(0.6, 0.8, 0.6)`
- 변경 없음

**줄 3 — 스킬 설명**

- 폰트 10, 파랑 `Color(0.75, 0.85, 0.95)`, autowrap
- 변경 없음

**줄 4 — 하중 + 손상도 (HBox)**

- 좌: `하중 25` (기존 weight_label, `EXPAND_FILL`)
- 우: 손상도 블록 `■■■□□` (`SHRINK_END`)
  - 블록 수 = `max_durability` (3·5·7)
  - 채워진 블록(■) = 남은 `durability`, 빈 블록(□) = 소진량
  - 색상:
    - 전원 정상(`durability == max_durability`) → 초록 `Color(0.3, 0.85, 0.4)`
    - `is_worn()` → 주황 `Color(1.0, 0.6, 0.1)`
    - `is_broken()` → 적색 `Color(0.9, 0.2, 0.2)`
  - 구현 방법: `Label`에 `■` × durability + `□` × (max - durability) 문자열, 색 override

**줄 5 — affix 목록**

- `rolled_affixes`가 비어 있으면 노드를 숨김(`visible = false`)
- 있으면 affix 이름(한국어)을 공백으로 구분해 한 줄 표시
  - 예: `과부하 모드  반격 본능  흡수 코팅`
- 폰트 9, 색상 `Color(0.85, 0.75, 1.0)` (연보라)
- `autowrap_mode = AUTOWRAP_WORD_SMART`, `custom_minimum_size.x = 200`
- affix 이름 매핑은 AffixSystem.md의 ID → 이름 테이블 기준

### 2.3 affix ID → 표시 이름 매핑 (PartCardUI 내 상수)

| ID | 표시 이름 |
|----|----------|
| `evolution_lord` | 진화 군주 |
| `mindless` | 무지성 |
| `greedy` | 과한 욕심 |
| `productive` | 생산성 향상 |
| `meticulous` | 꼼꼼한 설계 |
| `overload` | 과부하 모드 |
| `counter_instinct` | 반격 본능 |
| `gambler` | 도박사 |
| `lifedrain` | 흡수 코팅 |
| `momentum` | 탄력 |
| `serious_punch` | 진심펀치 |
| `zombie_process` | 좀비 프로세스 |
| `kernel_panic` | 커널 패닉 |
| `undefined_behavior` | 개발자도 모름 |
| `backdoor` | 백도어 |

### 2.4 최소 크기 및 그리드 영향

- 카드 `custom_minimum_size`: `Vector2(220, 110)`
- 조립 씬 인벤 그리드(5열 × 6행): 카드 높이 증가에 따라 `GridContainer` 세로 여백 재확인 필요
- affix 없는 COMMON 카드는 줄 5가 숨김 → 실제 높이 약 90px로 수축 가능 (ShrinkCenter)

---

## 3. 메카 조립 (AssemblyScene)

- 본문 `HBox`: 좌 **6** : 우 **4** (`size_flags_stretch_ratio`).
- 인벤: `GridContainer` **5열 × 6행**(30칸), 빈 칸은 빈 슬롯 스타일.
- 상단 Run HUD + 본문 상단 여백(스트립 높이 + 16px 권장).

---

## 4. 코어 선택 (CoreSelectScene)

- 코어 카드 **고정 크기**(예: 200×240), 화면·카드 간 **Margin**.
- **플로우**: 카드로 코어 선택 → **출격** → `GameState.start_run` + `DungeonManager.start_dungeon()`.

---

## 5. 던전 맵 (DungeonMapScene)

- 레이아웃: **좌** 맵(제목·방 타일·조립 버튼), **우** 고정 **방 정보 패널**(너비 약 300px).
- 방 선택: **아이콘 버튼**은 왼쪽 영역에 배치.
- **클릭** 시에만 우측 패널에 방 설명 갱신 + **「진입하기」** 활성화 → `DungeonManager.select_room(room)`.

---

## 6. 전투 (CombatScene / CombatUI)

- **좌(≈40%)**: 플레이어 코어 요약 + **4슬롯** 장착 여부(텍스트/아이콘).
- **우(≈60%, 너비 200~500px 클램프)**: 적 **가로** 나열(HP/쉴드 바). **적 2명 이상**이고 스킬 대상이 단일 적이면: 스킬 클릭 후 **적 카드 클릭**으로 타겟 확정.
- **적 예고**: 각 적 **상단** 라벨.
- **하단 중앙**: 스킬 버튼.
- **하단 좌측**: **행동력**(남은 액션 수) — Slay the Spire 스타일 블록 표시.
- 상단 Run HUD. **플레이어 HP/쉴드 바는 스트립만**(전투 UI 하단 중복 HP 바 제거).

---

## 7. 인카운터 (EncounterScene)

- **좌**: 이미지(`TextureRect` 플레이스홀더).
- **우**: 상단 본문, 하단 **선택지 가로**(진행 / 건너뛰기 등).
- 결과 단계: 우측 본문·선택지 숨김 후 결과만 표시 + 계속.

---

## 8. 보상 (RewardScene)

- 보상 카드 **가로 고정 크기**.
- **플로우**: 카드 클릭 → 설명 팝업 → **「가져가기」** → `DungeonManager.continue_after_reward()`.

---

## 9. 런 종료 (RunEndScene)

- 중앙 결과 텍스트 + 버튼 **「은신처로 복귀」** → 코어 선택 씬.

---

## 10. 기타 씬

- **WorkshopScene**: Run HUD + 서비스 목록; 기존 좌상단 HP/쉴드 라벨은 제거(스트립으로 통일).
- **ChestScene**: 보상 플로우와 맞출지 별도 검토.

---

## 11. 신호 / 상태

- `EventBus.floor_changed(new_floor: int)` — `GameState.start_run`, `advance_floor`에서 emit.
- 설정 모달 시 `get_tree().paused` 여부는 추후 옵션으로 문서화.
