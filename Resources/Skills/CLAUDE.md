# Skills Resource Domain Guide

## 역할

`Resources/Skills/`는 Project Mecha의 게임 스킬 리소스(`SkillData`)를 보관한다.

## 먼저 읽을 문서

- `ARCHITECTURE.md`
- `AGENTS.md`
- `Resources/SkillData.gd`
- `Docs/CombatSpecification.md`
- 파츠 스킬: `Docs/PartsSystem.md`, `Docs/AffixSystem.md`, `Docs/PartsCatalog.md`
- 적 스킬: `Docs/EnemySystem.md`

## 작성 규칙

- `skill_id`는 전체 `Resources/Skills/*.tres`에서 유일해야 한다.
- `skill_name`과 설명은 비워 두지 않는다.
- AP 비용은 음수가 될 수 없다.
- 플레이어 파츠 스킬은 실제 런타임 효과 필드를 가져야 한다.
- 새 효과는 리소스 필드만 추가하지 말고 전투 실행 코드와 검증까지 연결한다.
- `SkillData.SkillType.PASSIVE`는 저장 호환용이며 UI에서는 유틸로 표시된다.

## 연결 규칙

- 파츠 스킬은 `Resources/Parts/**.tres`의 `parts_skills`에서 참조한다.
- 적 스킬은 `Resources/Enemies/*.tres`의 `skills`에서 참조한다.
- 소환 스킬은 `summon_enemy`와 `summon_limit_per_combat` 계약을 확인한다.
- 파츠 저격 스킬은 `target_slot`을 명시한다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```

최소 `Scripts/Validation/check_resource_integrity.gd`가 통과해야 한다.
