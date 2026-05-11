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

## 2. 메카 조립 (AssemblyScene)

- 본문 `HBox`: 좌 **6** : 우 **4** (`size_flags_stretch_ratio`).
- 인벤: `GridContainer` **5열 × 6행**(30칸), 빈 칸은 빈 슬롯 스타일.
- 상단 Run HUD + 본문 상단 여백(스트립 높이 + 16px 권장).

---

## 3. 코어 선택 (CoreSelectScene)

- 코어 카드 **고정 크기**(예: 200×240), 화면·카드 간 **Margin**.
- **플로우**: 카드로 코어 선택 → **출격** → `GameState.start_run` + `DungeonManager.start_dungeon()`.

---

## 4. 던전 맵 (DungeonMapScene)

- 레이아웃: **좌** 맵(제목·방 타일·조립 버튼), **우** 고정 **방 정보 패널**(너비 약 300px).
- 방 선택: **아이콘 버튼**은 왼쪽 영역에 배치.
- **클릭** 시에만 우측 패널에 방 설명 갱신 + **「진입하기」** 활성화 → `DungeonManager.select_room(room)`.

---

## 5. 전투 (CombatScene / CombatUI)

- **좌(≈40%)**: 플레이어 코어 요약 + **4슬롯** 장착 여부(텍스트/아이콘).
- **우(≈60%, 너비 200~500px 클램프)**: 적 **가로** 나열(HP/쉴드 바). **적 2명 이상**이고 스킬 대상이 단일 적이면: 스킬 클릭 후 **적 카드 클릭**으로 타겟 확정.
- **적 예고**: 각 적 **상단** 라벨.
- **하단 중앙**: 스킬 버튼.
- **하단 좌측**: **행동력**(남은 액션 수) — Slay the Spire 스타일 블록 표시.
- 상단 Run HUD. **플레이어 HP/쉴드 바는 스트립만**(전투 UI 하단 중복 HP 바 제거).

---

## 6. 인카운터 (EncounterScene)

- **좌**: 이미지(`TextureRect` 플레이스홀더).
- **우**: 상단 본문, 하단 **선택지 가로**(진행 / 건너뛰기 등).
- 결과 단계: 우측 본문·선택지 숨김 후 결과만 표시 + 계속.

---

## 7. 보상 (RewardScene)

- 보상 카드 **가로 고정 크기**.
- **플로우**: 카드 클릭 → 설명 팝업 → **「가져가기」** → `DungeonManager.continue_after_reward()`.

---

## 8. 런 종료 (RunEndScene)

- 중앙 결과 텍스트 + 버튼 **「은신처로 복귀」** → 코어 선택 씬.

---

## 9. 기타 씬

- **WorkshopScene**: Run HUD + 서비스 목록; 기존 좌상단 HP/쉴드 라벨은 제거(스트립으로 통일).
- **ChestScene**: 보상 플로우와 맞출지 별도 검토.

---

## 10. 신호 / 상태

- `EventBus.floor_changed(new_floor: int)` — `GameState.start_run`, `advance_floor`에서 emit.
- 설정 모달 시 `get_tree().paused` 여부는 추후 옵션으로 문서화.
