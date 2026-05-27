# 새 적 추가

## 필수 확인

1. `ARCHITECTURE.md`
2. `AGENTS.md`
3. `Docs/EnemySystem.md`
4. `Docs/CombatSpecification.md`
5. `Resources/EnemyData.gd`
6. 새 스킬이 필요하면 `.claude/commands/new-skill.md`

## 설계 기준

적은 파일 구조보다 역할로 먼저 정의한다.

- `Striker`: HP 압박
- `Breaker`: 파츠 슬롯 예고와 손상
- `Support`: 회복, 쉴드, 강화
- `Caller`: 제한된 증원
- `Controller`: 플레이어 선택지 제한
- `Anchor`: 방어 압박

예고와 실제 실행은 일치해야 한다. 파츠 공격은 반드시 `target_slot`을 설정한다.

## 절차

1. 기존 `enemy_id`, 티어, 역할, 수치를 검색한다.
2. 필요한 `SkillData` 리소스를 먼저 준비한다.
3. `Resources/Enemies/*.tres`에 `EnemyData`를 작성한다.
4. 호출 전용 적은 기본적으로 `counts_for_combat_rewards = false`로 둔다.
5. 새 지역/역할/보스 규칙은 `Docs/EnemySystem.md`에 반영한다.
6. 전투 코드가 필요한 규칙은 `EnemyEntity`, `TurnManager`, 보스 전용 Entity, `CombatUI` 중 실제 소유 위치에 구현한다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```

증원, 보상 카운트, 파츠 타겟팅, 보스 승리 조건이 바뀌면 검증 계약을 추가한다.
