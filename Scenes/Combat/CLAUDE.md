# Combat Domain Guide

## 역할

`Scenes/Combat/`는 전투 씬과 턴 진행을 소유한다. 전투 계산 자체는 `TurnManager`, 플레이어/적 상태 계산은 Entity, 표시와 입력은 `CombatUI`가 담당한다.

## 먼저 읽을 문서

- `ARCHITECTURE.md`
- `AGENTS.md`
- `Scenes/AGENTS.md`
- `Docs/CombatSpecification.md`
- 파츠/affix 관련: `Docs/PartsSystem.md`, `Docs/AffixSystem.md`
- 적 행동 관련: `Docs/EnemySystem.md`

## 주요 파일

- `CombatScene.gd`: 전투 씬 연결과 시작 흐름
- `TurnManager.gd`: 턴, AP, 스킬 실행, 적 행동, 승패, 보상 흐름
- `CombatScene.tscn`: 전투 씬 구성
- `Scenes/UI/CombatUI.gd`: 전투 UI 표시와 선택 입력

## 주의사항

- 스킬 실행 규칙은 `Docs/CombatSpecification.md`를 기준으로 한다.
- `CombatUI`에 전투 판정을 넣지 말고, 표시/선택을 넘기는 역할로 유지한다.
- `EXTRA_ARM`, 파츠 파괴, affix, 버프/디버프는 UI와 턴 로직 양쪽 계약을 확인한다.
- 새 전투 규칙은 `Scripts/Validation/check_p0_combat_flows.gd` 또는 `check_current_work_contracts.gd`에 검증을 추가한다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```
