# 새 게임 스킬 리소스 생성

> Project Mecha의 `SkillData` 게임 스킬을 추가하거나 수정할 때 사용한다. Codex/Claude의 AI 스킬이 아니라 `Resources/Skills/*.tres` 리소스를 뜻한다.

## 필수 확인

1. `ARCHITECTURE.md`
2. `AGENTS.md`
3. `Resources/Skills/CLAUDE.md`
4. `Resources/SkillData.gd`
5. `Docs/CombatSpecification.md`
6. 파츠 스킬이면 `Docs/PartsSystem.md`, 적 스킬이면 `Docs/EnemySystem.md`

## 절차

1. `Resources/Skills/*.tres`에서 기존 `skill_id`, 이름, 비슷한 효과를 검색한다.
2. 기존 `SkillData` 필드로 표현 가능한지 먼저 확인한다.
3. 새 런타임 효과가 필요하면 `TurnManager`, `MechaEntity`, `EnemyEntity`, `CombatUI` 중 실제 실행 경로와 검증을 같은 작업에 포함한다.
4. 스킬 소유 리소스에 연결한다.
   - 파츠: `Resources/Parts/**.tres`의 `parts_skills`
   - 적: `Resources/Enemies/*.tres`의 `skills`
   - 코어/어빌리티: 기존 코어·어빌리티 트리 참조 흐름
5. 새 파일이나 구조 변경이 있으면 `ARCHITECTURE.md`를 갱신한다.
6. 동작 기준이 바뀌면 관련 `Docs/` 문서를 갱신한다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```

최소 `check_resource_integrity.gd`가 통과해야 한다. 새 효과가 전투 동작을 바꾸면 `check_p0_combat_flows.gd` 또는 `check_current_work_contracts.gd`에 계약을 추가한다.
