# 파츠 시스템 수정

## 필수 확인

1. `ARCHITECTURE.md`
2. `AGENTS.md`
3. `Docs/PartsSystem.md`
4. `Docs/AffixSystem.md`
5. `Docs/PartsCatalog.md`
6. 전투 효과면 `Docs/CombatSpecification.md`
7. 거점 보관/수리/분해면 `Docs/BaseSystem.md`

## 핵심 계약

- 파츠 템플릿은 `Resources/Parts/`에 두고 `PartsFactory`가 드롭 롤을 담당한다.
- 등급은 템플릿 고정값이 아니라 rolled affix 개수에서 결정된다.
- `stat_multiplier`는 출력 수치에만 적용된다.
- 파츠는 `durability <= 0`이면 파괴 상태다.
- LEG는 `max_load_bonus`로 하중 한도를 늘리고, 비-LEG 파츠가 하중을 소비한다.
- `EXTRA_ARM`은 ARM_L/ARM_R만 허용하며 중첩 확장되지 않는다.

## 절차

1. 변경이 템플릿 데이터, 롤링, 런타임 전투, UI/저장 흐름 중 어디인지 먼저 나눈다.
2. 새 affix는 `PartsData.AFFIX_NAMES`, `Docs/AffixSystem.md`, `Docs/PartsCatalog.md`, 런타임 적용 코드, 검증을 함께 맞춘다.
3. 슬롯/손상도 변경은 Assembly, Hangar, Combat UI, GameState 저장/복원, 검증까지 같이 본다.
4. 새 파일이나 폴더가 생기면 `ARCHITECTURE.md`를 갱신한다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```

관련 검증은 리소스 무결성, 거점 상태 계약, 현재 작업 계약, 씬 스모크, P0 전투 플로우다.
