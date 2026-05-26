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

## 2. PartCardUI — 인벤토리 아이콘 셀

조립 씬 인벤토리는 텍스트 카드가 아니라 **아이콘 중심 정사각 셀**로 표시한다. 상세 수치와 affix는 선택 상세 패널 및 hover 툴팁으로 이동한다.

| 항목 | 규칙 |
|------|------|
| 크기 | 조립 화면 기준 `92×92` 정사각 래퍼. 내부 `PartCardUI`는 `72×72` 이상. |
| 아이콘 | `PartsData.parts_icon`이 있으면 사용, 없으면 `PartsData.icon_texture()` fallback. |
| 등급 | 테두리 색상: COMMON 회색 / RARE 파랑 / EPIC 보라. |
| 상태 | `is_worn()` 주황 마커, `is_broken()` 적색 마커. |
| 선택 | 선택된 셀은 노란 테두리. |
| 드래그 | 정상/손상 파츠만 드래그 가능. 파손 파츠는 장착 불가. |
| 상세 | `PartsData.assembly_tooltip_text()`를 hover와 선택 상세 패널에서 사용. |

---

## 3. 메카 조립 (AssemblyScene)

- 본문 `HBox`: 좌 **6** : 우 **4** (`size_flags_stretch_ratio`).
- 좌측: 메카 코어와 4개 장착 슬롯을 십자형으로 표시한다. 슬롯 클릭 시 상세 패널에서 해제/상태 확인.
- 우측: 인벤토리 `GridContainer` **4열 × 4행**(16칸), 빈 칸은 빈 슬롯 스타일. 코어 업그레이드 시 24→28칸으로 확장.
- 우측 하단: 선택 상세 패널. 인벤토리 파츠/장착 슬롯/스킬 프리뷰 선택에 따라 이름, 수치, 내구도, affix, 교체 시 파손 비용을 표시한다.
- 하단 중앙: **전투 스킬 배치 프리뷰**. 실제 전투 UI와 같은 순서를 사용한다.
  - 순서: `기본 공격 → 파츠 활용 어빌리티 → ARM_L → ARM_R → BACK → LEG`
  - 각 슬롯은 아이콘, AP 배지, 출처 배지를 표시한다.
  - 파손 파츠 스킬은 비활성/경고 상태로 표시한다.
- 장착 액션: 드래그앤드롭 유지 + 선택 상세 패널의 `장착/교체/해제` 버튼 지원.
- 파손 비용: 던전 중 장착 파츠를 해제하거나 교체하면 기존 파츠 `durability = 0`으로 인벤토리에 돌아간다.
- 용량: `GameState.get_inventory_capacity()` 기준. 기본 16칸을 초과하는 획득은 실패/유실 처리한다.
- 상단 Run HUD + 본문 상단 여백(스트립 높이 + 16px 권장).

---

## 4. 코어 설계 (CoreSelectScene)

- 기존 단일 진입 씬 안에서 **코어 연구**와 **출격 준비** 보기를 분리한다.
- 코어 연구: 거점 크레딧, 5티어 노드 연구·레벨업, 잠긴 노드 효과 축을 표시한다.
- 출격 준비: 던전 특성 요약 → 기본 공격 택 1 → 티어별 연구 노드 최대 1개 → 파츠 활용 어빌리티 택 1 → 외장/스탯 미리보기.
- **플로우**: 출격 준비에서 **출격** → `GameState.start_run` + 선택 노드 적용 + `DungeonManager.start_dungeon()`.

---

## 5. 던전 맵 (DungeonMapScene)

- 레이아웃: **좌** 맵(제목·방 타일·조립 버튼), **우** 고정 **방 정보 패널**(너비 약 300px).
- 방 선택: **아이콘 버튼**은 왼쪽 영역에 배치.
- **클릭** 시에만 우측 패널에 방 설명 갱신 + **「진입하기」** 활성화 → `DungeonManager.select_room(room)`.

---

## 6. 전투 (CombatScene / CombatUI)

> 전투 화면의 레이아웃·인터랙션·예상 수치 계산 전체 규칙은 **[[Docs/UI/CombatScreen]]** 참조.

요점 요약:
- 상단: RunStatusStrip → TurnLabel → BattleMargin.
- 좌(≈40%): 플레이어 메카 — 코어명 + MechStatusPanel(슬롯 블록) + 자기 대상 캐처.
- 우(≈60%, 너비 200~500px 클램프): 적 카드 가로 나열, HP/쉴드 바 숫자 오버레이.
- 하단: 행동력 오브 + 스킬 버튼 + SelectionStatus.
- 플레이어 HP/쉴드 바는 RunStatusStrip에만 표시 (전투 UI 내 중복 제거).

---

## 7. 인카운터 (EncounterScene)

- **좌**: 이미지(`TextureRect` 플레이스홀더).
- **우**: 상단 본문, 하단 **선택지 가로**(진행 / 건너뛰기 등).
- 결과 단계: 우측 본문·선택지 숨김 후 결과만 표시 + 계속.

---

## 8. 보상 (RewardScene)

- 전투 보상: 격파 수, 드롭 개수, 크레딧 획득량 표시.
- 전투에서 드롭된 파츠는 보상 화면 진입 시 모두 인벤토리에 자동 추가.
- 드롭 파츠는 읽기 전용 카드로 표시하고, **「계속」** → `DungeonManager.continue_after_reward()`.
- 상자 보상은 기존 선택형 카드 플로우를 유지.

---

## 9. 런 종료 (RunEndScene)

- 중앙 결과 텍스트 + 버튼 **「은신처로 복귀」** → 코어 설계 씬.

---

## 10. 기타 씬

- **WorkshopScene**: Run HUD + 서비스 목록; 기존 좌상단 HP/쉴드 라벨은 제거(스트립으로 통일).
- **ChestScene**: 보상 플로우와 맞출지 별도 검토.

---

## 11. 신호 / 상태

- `EventBus.floor_changed(new_floor: int)` — `GameState.start_run`, `advance_floor`에서 emit.
- 설정 모달 시 `get_tree().paused` 여부는 추후 옵션으로 문서화.
