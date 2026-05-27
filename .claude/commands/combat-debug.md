# 전투 버그 조사

## 필수 확인

1. `ARCHITECTURE.md`
2. `AGENTS.md`
3. `Docs/CombatSpecification.md`
4. 필요 시 `Docs/PartsSystem.md`, `Docs/AffixSystem.md`, `Docs/EnemySystem.md`
5. `Scenes/Combat/CLAUDE.md`
6. Entity 동작이면 `Scenes/Entities/CLAUDE.md`

## 조사 순서

1. 버그가 상태, 리소스, 턴 순서, UI 표시 중 어디에 가까운지 분류한다.
2. 데이터 원본을 먼저 확인한다: `SkillData`, `PartsData`, `EnemyData`, `GameState`.
3. 실행 흐름은 `TurnManager`에서 추적한 뒤 `CombatUI`를 본다.
4. 엔티티 계산은 `MechaEntity`, `EnemyEntity`, 수집가 전용 Entity에서 확인한다.
5. 기존 검증 스크립트에 같은 계약이 있는지 먼저 검색한다.

## 보존할 전투 계약

- 스킬 표시 순서: 기본 공격, 파츠 어빌리티, `ARM_L`, `ARM_R`, `EXTRA_ARM`, `BACK`, `LEG`
- `EXTRA_ARM`은 정상 ARM/BACK의 `evolution_lord`로만 열린다.
- 제공 파츠가 파괴·탈착·강탈되면 추가 팔 파츠는 즉시 탈착된다.
- 빈 슬롯 파츠 공격은 HP 피해만 적용하고 손상은 무효다.
- 수집가 코어 HP가 0이면 팔이 남아도 승리다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```

주요 파일은 `check_p0_combat_flows.gd`, `check_current_work_contracts.gd`, `check_resource_integrity.gd`, `check_scene_smoke.gd`다.
