---
tags: [project/project-mecha, document/session-context, phase/14]
status: completed
created: 2026-05-12
updated: 2026-05-12
topic: 코어/스킬/적 스탯 수치 확정 및 행동력 시스템 개편
---

# ProjectMecha — Phase 14 세션 컨텍스트

> [!important]
> 새 세션 시작 시 이 파일을 먼저 읽을 것.
> 마지막 업데이트: 2026-05-12 (Phase 14 완료)

---

## 이번 세션에서 한 일

1. **드래그앤드롭 구현 완료** (Phase 13 이후 완료된 것 확인)
2. **코어 스탯 수치 확정**
3. **행동력(AP) 시스템 개편** — 쿨다운 제거, 행동력 비용으로 대체
4. **적 행동력 시스템 추가** — 내부 AP 기반 복수 행동
5. **스킬 수치 전체 조정**
6. **초반 난이도 조정** — 코어 고유 스킬 실효 데미지 상향, 일반 적 HP/AP 대폭 하향

---

## 확정 코어 스탯

| 코어 | HP | 쉴드(최대) | Payload | 행동력/턴 | 공격 배율 |
|------|-----|---------|---------|---------|---------|
| Vanguard (범용) | 100 | 20 | 100 | 2 | ×1.0 |
| Striker (경량) | 70 | 10 | 80 | 4 | ×0.6 |
| Bulwark (방어) | 150 | 40 | 120 | 2 | ×0.7 |

## 코어 고유 스킬 (파츠 없을 때 사용)

attack_multiplier 적용 후 실효 데미지 ~8 기준으로 설정.

| 코어 | 스킬 | skill_damage | 실효 데미지 | 쉴드 | 행동력 비용 |
|------|------|-------------|-----------|------|---------|
| Vanguard | 단발 사격 | 8 | 8.0 | — | 2 |
| Striker | 입자 광선 | 13 | 7.8 (×0.6) | — | 4 |
| Bulwark | 간이 방벽 | 11 | 7.7 (×0.7) | +5 | 2 |

---

## 행동력(AP) 시스템 설계

**슬레이 더 스파이어 스타일 에너지 시스템.**

- 매 플레이어 턴 시작 시 행동력 풀 초기화 (`core_action_count`)
- 스킬 사용 시 `skill_action_cost` 차감
- 행동력 소진 or 사용 가능 스킬 없으면 자동으로 적 턴으로 전환
- **쿨다운 제거** — 행동력 비용이 유일한 제약

**적 행동력 시스템 (내부):**
- 적도 턴당 AP 풀 보유 (`enemy_action_count`)
- AP 소진까지 랜덤으로 스킬 선택
- 선택된 스킬 목록이 "예고"로 플레이어에게 표시
- AP 수치 자체는 플레이어에게 비공개

---

## 확정 스킬 수치

| 스킬 | 데미지/효과 | 행동력 비용 | 사용처 |
|------|-----------|-----------|------|
| 연사 | 10 | 1 | 적(스크래퍼/러셔), 플레이어 파츠 |
| 헤비 펀치 | 14 | 2 | 적(스크래퍼/러셔/가드유닛), 플레이어 파츠 |
| 캐논 샷 | 16 | 2 | 적(워로드/포트리스/콜로서스), 플레이어 파츠 |
| 산탄 | 12 + 공격력↓ | 2 | 적(워로드/콜로서스), 플레이어 파츠 |
| 거인의 강타 | 28 | 4 | 적(콜로서스), 플레이어 파츠 |
| 철갑 방어 | 쉴드 +15 | 2 | 적(가드유닛/워로드/포트리스/콜로서스), 플레이어 파츠 |
| 레일건 사격 | 22 | 3 | 플레이어 파츠 전용 |
| 수리 | HP +20 | 2 | 플레이어 파츠 전용 |
| 나노 수복 | HP +30 | 4 | 플레이어 파츠 전용 |

---

## 확정 적 수치

초반 적(일반)은 파츠 없이도 클리어 가능한 수준으로 설계.
- 코어 스킬 2회면 처치 가능 HP
- 플레이어가 10턴 이상 버틸 수 있는 데미지 (AP=1 → 연사 10/턴)

| 적 | 티어 | HP | 쉴드 | 공격 배율 | 행동력 | 스킬 |
|----|------|----|------|---------|------|------|
| 스크래퍼 | 일반 | **15** | 0 | ×1.0 | **1** | 연사, 헤비펀치 |
| 러셔 | 일반 | **12** | 0 | ×1.1 | **1** | 연사, 헤비펀치 |
| 가드 유닛 | 일반 | **18** | **5** | ×1.0 | 2 | 헤비펀치, 철갑방어 |
| 워로드 | 엘리트 | 150 | 40 | ×1.2 | 4 | 캐논, 철갑방어, 산탄 |
| 포트리스 | 엘리트 | 180 | 60 | ×1.1 | 4 | 캐논, 철갑방어 |
| 콜로서스 | 보스 | 350 | 80 | ×1.3 | 6 | 거인강타, 캐논, 철갑방어, 산탄 |

> 스크래퍼/러셔는 AP=1이라 실질적으로 연사(10)만 사용 → 패턴 단순, 첫 전투 튜토리얼 역할
> 가드 유닛은 AP=2로 헤비펀치/철갑방어 랜덤 → 초반 전략 요소 첫 도입

---

## 변경된 파일

### 코드 (.gd)
| 파일 | 변경 내용 |
|------|---------|
| `Resources/SkillData.gd` | `skill_action_cost` 추가, `skill_cooldown` 제거 |
| `Resources/CoreData.gd` | `core_attack_multiplier` 추가 |
| `Resources/EnemyData.gd` | `enemy_action_count` 추가 |
| `Scenes/Entities/MechaEntity.gd` | 쿨다운 시스템 제거, use_skill 다중 효과 처리 |
| `Scenes/Entities/EnemyEntity.gd` | `next_actions: Array`, `decide_next_actions()`, `execute_actions()` 로 교체 |
| `Scenes/Combat/TurnManager.gd` | 시그널 개편, tick_cooldowns 제거, action_cost 기반 전환 |
| `Scenes/UI/CombatUI.gd` | 시그널 파라미터 정리, 복수 예고 표시, 행동력 버튼 표시 |
| `Scripts/Autoload/GameState.gd` | 런 시작 시 `attack_multiplier` 코어에서 자동 설정 |

### 리소스 (.tres)
- `Resources/Cores/core_vanguard.tres` — 스탯 확정, 고유 스킬 연결
- `Resources/Cores/core_striker.tres` — 스탯 확정, 고유 스킬 연결
- `Resources/Cores/core_bulwark.tres` — 스탯 확정, 고유 스킬 연결
- `Resources/Skills/skill_*.tres` (9개) — 쿨다운 제거, action_cost 추가, 수치 조정
- `Resources/Skills/skill_core_single_shot.tres` — 신규
- `Resources/Skills/skill_core_particle_beam.tres` — 신규
- `Resources/Skills/skill_core_makeshift_barrier.tres` — 신규
- `Resources/Enemies/enemy_*.tres` (6개) — `enemy_action_count` 추가

---

## 미결 사항 (다음 세션 이후)

- [ ] 크레딧 획득량 및 작업대 비용 밸런싱
- [ ] 조우 이벤트 텍스트 작성
- [ ] **부품 24개 스킬 상세 설계** — action_cost 포함
- [ ] **적 6종 패턴 설계** (상세 AI 행동 패턴)
- [ ] 보스 전투 특수 메커니즘 여부 결정
- [ ] Patch 시스템 게임플레이 설계

---

## 관련 문서

- [[Docs/GameDesignDocument]]
- [[SESSION_CONTEXT/Phase13-세계관-스케치-확정]]
