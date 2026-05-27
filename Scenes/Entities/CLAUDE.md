# Entities Domain Guide

## 역할

`Scenes/Entities/`는 플레이어 메카, 일반 적, 수집가 보스 팔/코어의 런타임 상태와 계산을 소유한다.

## 먼저 읽을 문서

- `ARCHITECTURE.md`
- `AGENTS.md`
- `Scenes/AGENTS.md`
- `Docs/CombatSpecification.md`
- 적 관련: `Docs/EnemySystem.md`
- 파츠/affix 관련: `Docs/PartsSystem.md`, `Docs/AffixSystem.md`

## 주요 파일

- `MechaEntity.gd`: 플레이어 HP, 파츠 슬롯, affix, 스킬 출력, 파츠 탈취/탈착
- `EnemyEntity.gd`: 적 HP, 쉴드, intent, 스킬 선택, 파츠 공격 예고
- `BossCollectorEntity.gd`: 수집가 코어 보호, 노출, 재수집, 팔 탈취
- `CollectorArmEntity.gd`: 수집가 팔 서브 엔티티

## 주의사항

- Entity는 상태와 계산을 맡고, 턴 순서는 `TurnManager`와 맞춘다.
- 적 파츠 공격은 `target_slot` 예고와 실제 손상 슬롯이 일치해야 한다.
- 수집가 보스는 일반 적과 다른 승리/보호 계약이 있으므로 기존 P0 검증을 깨지 않게 확인한다.
- 새 상태값은 저장/복원 대상인지 `GameState`와 함께 판단한다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```
