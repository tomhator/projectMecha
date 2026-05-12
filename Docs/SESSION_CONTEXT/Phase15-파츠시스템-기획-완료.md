---
tags: [project/project-mecha, document/session-context, phase/15]
status: completed
created: 2026-05-12
updated: 2026-05-12
topic: 파츠 시스템 전면 재설계 + PartsCatalog 32종 기획 완료
---

# ProjectMecha — Phase 15 세션 컨텍스트

> [!important]
> 새 세션 시작 시 이 파일을 먼저 읽을 것.
> 마지막 업데이트: 2026-05-12 (Phase 15 완료)

---

## 이번 세션에서 한 일

1. **파츠 시스템 전면 재설계** — PartsSystem.md v0.4
2. **이름 접두사 시스템 도입** — stat_multiplier 구간별 이름 결정
3. **손상도 시스템 재설계** — bool → int, 스킬 사용마다 -1
4. **PartsCatalog.md 32종 기획 완료** — ARM 16 + BACK 8 + LEG 8
5. **AffixSystem.md stub 생성** — 상세 내용은 추후 작업

---

## 핵심 설계 변경 사항

### 등급 체계 (구 → 신)

| 구 시스템 | 신 시스템 |
|---------|---------|
| 파츠 정체성에 등급 고정 (COMMON 12 / RARE 6 / EPIC 6) | 드롭 시 affix 개수로 등급 결정 |
| 슬롯별 배분 고정 | 파츠별 드롭 가중치로 희귀도 조정 |

| 등급 | affix 개수 | 초기 손상도 | UI 색상 |
|------|-----------|-----------|--------|
| COMMON | 0~1 | 3 | 회색 |
| RARE | 2~3 | 5 | 파랑 |
| EPIC | 4~5 | 7 | 보라 |

### 이름 구조

```
[수치 접두사] + [파츠 고유명]
예) 완벽한 RAMPART-8 / 낡은 M-88 캐논
```

| 접두사 | 범위 |
|--------|------|
| 낡은 | ×0.70~0.84 |
| (없음) | ×0.85~0.99 |
| 정밀한 | ×1.00~1.14 |
| 강화된 | ×1.15~1.29 |
| 완벽한 | ×1.30~1.50 |

### affix 표시 방식
- 이름에 포함 **안 함**
- 파츠 카드 UI에 **아이콘**으로 표시

### 손상도 시스템
- 스킬 사용 시 해당 파츠 `durability -= 1`
- 0이 되면 파괴 (스킬 잠금 + Affix 비활성화)
- 적 전용 파괴 스킬 3종: 파츠 저격(-1) / 과부하 공격(-2) / EMP 충격(전체 -1)

---

## PartsCatalog 32종 요약

### ARM_L (8종) — 주력 공격 슬롯
**총기류 4종 (좌우 공용):** M-88 캐논 / GR-21 기관포 / LG-40 레일건 / ML-7 유도 미사일

**근접무기 4종 (ARM_L 전용):**
- VHF-9 고진동 발열 블레이드 — 공격 + BURN
- EW-4 고전압 충격 와이어 — 공격 + 적 AP -1
- YB-20 유압 파쇄기 — 극단발 최고화력 (AP 2 소모)
- RD-9 회전 굴삭기 — 3연속 관통

### ARM_R (8종) — 보조 무장 / 방어 슬롯
**총기류 4종 (좌우 공용):** ARM_L과 동일 스킬

**방어·반응 4종 (ARM_R 전용):**
- CP-40 복합 방호판 — 방어 + 피해 감소 1턴
- EMF-3 전자기 배리어 — 쉴드 생성 (다음 공격 완전 차단)
- 포식 집게팔 — 요격 + 즉시 반격 (GD형 — 기계신 모방)
- 흡취 침지팔 — 공격 + 피해량 40% HP 회복 (GD형 — 기계신 모방)

### BACK (8종) — 백팩 지원 슬롯
패시브 6종 + 액티브 2종

| 파츠 | 핵심 효과 |
|------|---------|
| SD-7 방어막 발생기 | 매 턴 쉴드 +10 (패시브) |
| EX-9 강화 외골격 팩 | 최대 HP +35 (패시브) |
| TB-3 전술 부스터 팩 | 이번 턴 AP +1 (액티브, AP 0 소모) |
| NR-5 나노 수복기 | 매 턴 HP +6 (패시브) |
| PA-6 출력 증폭기 | 전 슬롯 스킬 수치 +12% (패시브) |
| MD-2 정비 드론 팩 | 매 턴 최저 손상도 파츠 +1 복구 (패시브) |
| TR-4 전술 중계기 | 활성 버프 지속 +2턴 (액티브) |
| FR-1 현장 수리 키트 | 선택 파츠 손상도 즉시 max 복구 (액티브) |

### LEG (8종) — 아머드코어 스타일 이름
패시브 5종 + 액티브 3종

| 파츠 | 핵심 효과 |
|------|---------|
| RAMPART-8 | 방어 +20 영구 (패시브) |
| PORTEUR-4 | 하중 제한 +25 (패시브) |
| BASTION-1 | 시즈모드 — 공격력 +35%, 매 턴 AP -1 (액티브 토글) |
| SPRINGER-6 | 피격 시 40% 확률 즉시 반격 (패시브) |
| SPEARHEAD-2 | 전투 시작 선제 공격 1회 무료 (패시브) |
| DAMPFER-5 | 피해 감소 18% (패시브) |
| HARRIER-7 | 회피율 +15%, 하중 +5 (패시브) |
| JUKE-3 | 적 예고 공격 1회 완전 회피 (액티브) |

> [!note] 코어 이름 충돌 주의
> 코어 3종: **Vanguard**, **Striker**, **Bulwark**
> 파츠 이름 설계 시 위 세 단어 사용 금지.

---

## 변경된 문서

| 파일 | 변경 내용 |
|------|---------|
| `Docs/PartsSystem.md` | v0.4 전면 개편 — 등급·이름·손상도·파츠 풀 재설계 |
| `Docs/PartsCatalog.md` | 신규 — 32종 전체 기획 완료 |
| `Docs/AffixSystem.md` | 신규 stub — affix 목록 초안 + 가중치 테이블 틀 |
| `Docs/GameDesignDocument.md` | §4.3 파츠 수량·등급 설명 업데이트 |

---

## 다음 작업

### 우선순위 높음 — 기획 완성

- [ ] **AffixSystem.md 작업**
  - PartsCatalog 각 파츠의 affix 후보 취합
  - 전체 affix 목록 확정 (ID·이름·효과)
  - 파츠별 affix 가중치 테이블 작성

### 우선순위 높음 — 구현

- [ ] **PartsData.gd 필드 추가**
  - `drop_weight`, `affix_pool`, `affix_weights`
  - `stat_multiplier`, `rolled_affixes`, `max_durability`, `durability`
  - `grade()`, `is_broken()` 함수
- [ ] **PartsFactory autoload 설계**
  - 드롭 가중치 기반 파츠 선택
  - stat_multiplier 롤
  - affix 개수·종류 롤
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

- [[Docs/PartsSystem]]
- [[Docs/PartsCatalog]]
- [[Docs/AffixSystem]]
- [[Docs/GameDesignDocument]]
- [[SESSION_CONTEXT/Phase14-스탯-밸런싱-완료]]
