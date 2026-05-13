---
tags: [project/project-mecha, document/session-context, phase/16]
status: completed
created: 2026-05-13
updated: 2026-05-13
topic: Affix 시스템 기획 완성 + 파츠 전면 개편 (이름·패시브 제거)
---

# ProjectMecha — Phase 16 세션 컨텍스트

> [!important]
> 새 세션 시작 시 이 파일을 먼저 읽을 것.
> 마지막 업데이트: 2026-05-13 (Phase 16 완료)

---

## 이번 세션에서 한 일

1. **AffixSystem 기획 완성** — affix 15종 확정, 파츠별 pool(B안) 도입
2. **기획 오류 7건 수정** — GDD·PartsSystem 문서 동기화
3. **패시브 스킬 전면 제거** — BACK 5종·LEG 6종 → 전원 액티브로 전환
4. **파츠 이름 전면 개편** — 코드명 제거, 직관형 명칭, LEG 타입 도입
5. **PR #3 생성** — `claude/review-context-next-task-5E5op` → `main`

---

## 핵심 설계 변경 사항

### Affix 시스템 (AffixSystem.md)

- **등급 구분 폐기**: 공통·중급·고급 tier 제거. affix는 단순 목록.
- **확정 affix 15종**:

| ID | 이름 | 효과 |
|----|------|------|
| `evolution_lord` | 진화 군주 | 팔 슬롯 +1 (BACK·ARM 전용) |
| `mindless` | 무지성 | 수치 -10%, 횟수 +3, 타겟 랜덤 |
| `greedy` | 과한 욕심 | 무게 +5, 수치 +10% |
| `productive` | 생산성 향상 | 무게 -3, AP 비용 -1 |
| `meticulous` | 꼼꼼한 설계 | 최대 손상도 +10% |
| `overload` | 과부하 모드 | 수치 +25%, 손상도 -2 |
| `counter_instinct` | 반격 본능 | 피격 후 다음 스킬 +20% (1턴) |
| `gambler` | 도박사 | 수치 0~+50% 랜덤 |
| `lifedrain` | 흡수 코팅 | 피해의 15% HP 회복 |
| `momentum` | 탄력 | 같은 턴 두 번째 스킬 AP -1 |
| `serious_punch` | 진심펀치 | 1회용, 다음 스킬 +100% |
| `zombie_process` | 좀비 프로세스 | 파괴 후 1턴 더 작동 |
| `kernel_panic` | 커널 패닉 | HP 30% 이하 시 수치 +30%, AP -1 |
| `undefined_behavior` | 개발자도 모름 | 매 턴 수치 랜덤 (-20%~+60%) |
| `backdoor` | 백도어 | 적 디버프 시 수치 +25% |

- **등장 방식**: 파츠별 `affix_pool` 목록에서 균등 랜덤 (가중치 없음)
- **예외 제약**: `evolution_lord` → BACK·ARM 전용. 팔 슬롯 추가 종류는 자유 선택.

### 기획 오류 수정

| 항목 | 수정 전 | 수정 후 |
|------|--------|--------|
| GDD 파츠 수량 | 24개 | 32종 |
| GDD RARE affix 개수 | 1~2개 | 2~3개 |
| GDD EPIC affix 개수 | 2~3개 | 4~5개 |
| GDD 이벤트 결과 B | 능력치↓ | 손상도 -1 |
| PartsSystem 수리 수단 | 나노 포지 백팩 스킬 | 현장 수리 키트 |
| PartsData 필드 | affix_pool + affix_weights | affix_pool만 (균등) |

### 패시브 스킬 제거 — BACK·LEG 전원 액티브화

슬더스 파워카드 방식으로 전환: **버프형(유한)** + **파워카드형(영구/즉시)** 두 종류.

**BACK (5종 변경)**
| 파츠 | 전 (패시브) | 후 (액티브) |
|------|-----------|-----------|
| 방어막 발생기 | 매 턴 쉴드 +10 자동 | 3턴간 쉴드 +12/턴 버프 (AP 1) |
| 강화 외골격 팩 | 장착 시 max HP +35 영구 | 즉시 max HP +35 + HP +35 (AP 1) |
| 나노 수복기 | 매 턴 HP +6 자동 | 3턴간 HP +10/턴 버프 (AP 1) |
| 출력 증폭기 | 항상 스킬 수치 +12% | 3턴간 전 슬롯 +15% 버프 (AP 1) |
| 정비 드론 팩 | 매 턴 최저 파츠 손상도 +1 | 전 파츠 손상도 +2 즉시 (AP 1) |

**LEG (6종 변경)**
| 파츠 | 전 (패시브) | 후 (액티브) |
|------|-----------|-----------|
| 중장 무한궤도 | 항상 방어 +20 | 이번 전투 방어 +20 영구 (AP 1, 1회) |
| 중형 4각 | 항상 하중 +25 | 2턴간 피해 -10%, 하중 패널티 무효 (AP 1) |
| 반동 역관절 2각 | 피격 시 40% 반격 | 다음 피격 확정 반격 (AP 0) |
| 강습 역관절 2각 | 전투 시작 선제 1회 | 즉시 무료 스킬 1회 추가 (AP 0) |
| 완충 4각 | 항상 피해 감소 18% | 3턴간 피해 감소 20% 버프 (AP 1) |
| 경량 역관절 2각 | 항상 회피율 +15% | 3턴간 회피율 +20% 버프 (AP 1) |

### 파츠 이름 개편

- 코드명(M-88, GR-21, RAMPART-8 등) 전면 제거
- 직관형 명칭 도입 (디아블로 스타일)
- LEG: 다리 타입 명시 (무한궤도·4각·역관절 2각)

| 주요 변경 | 전 | 후 |
|---------|----|----|
| 총기류 | M-88 캐논 / GR-21 기관포 | 대구경 반자동 캐논 / 자동 기관포 |
| 미사일 | ML-7 유도 미사일 | 다연장 유도 미사일 시스템 |
| GD형 흡수팔 | 흡취 침지팔 | 기계식 나노 재구성 촉수 |
| LEG | RAMPART-8 / PORTEUR-4 등 | 중장 무한궤도 / 중형 4각 등 |

---

## 보류된 이슈

- PartsSystem §4 "30종" 텍스트 오류 (합계 표는 32로 맞음, 텍스트만 틀림)
- GDD §4.2 패시브 스킬 타입 항목 제거 (패시브 스킬 없어졌으므로)

---

## 다음 작업

### 우선순위 높음 — 구현

- [ ] **PartsData.gd 필드 추가**
  - `drop_weight`, `affix_pool`
  - `stat_multiplier`, `rolled_affixes`, `max_durability`, `durability`
  - `grade()`, `is_broken()` 함수
- [ ] **PartsFactory autoload 설계·구현**
  - 드롭 가중치 기반 파츠 선택
  - stat_multiplier 롤 (×0.70~1.50)
  - affix 개수 롤 (확률표 기반)
  - affix 종류 롤 (affix_pool 균등)
  - durability 초기화
- [ ] **기존 .tres 24개 → 32개 재설계** (PartsCatalog 확정 기준)
- [ ] **손상도 시스템 구현**
  - 스킬 사용 후 `durability -= 1` (CombatManager)
  - 파츠 파괴 처리 (스킬 잠금 + Affix 비활성화)
  - 적 파괴 스킬 3종 (파츠 저격 / 과부하 공격 / EMP 충격)
- [ ] **PartCardUI 업데이트**
  - 이름 접두사 표시
  - 손상도 게이지
  - affix 아이콘 목록

---

## 관련 문서

- [[Docs/AffixSystem]]
- [[Docs/PartsCatalog]]
- [[Docs/PartsSystem]]
- [[Docs/GameDesignDocument]]
- [[SESSION_CONTEXT/Phase15-파츠시스템-기획-완료]]
