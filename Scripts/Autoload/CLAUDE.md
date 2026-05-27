# Autoload Domain Guide

## 역할

`Scripts/Autoload/`는 전역 이벤트, 런/거점 상태, 던전 진행, 파츠 롤링, 보상 생성을 소유한다.

## 먼저 읽을 문서

- `ARCHITECTURE.md`
- `AGENTS.md`
- 상태/거점: `Docs/BaseSystem.md`
- 파츠: `Docs/PartsSystem.md`, `Docs/AffixSystem.md`
- 던전/보상: `Docs/GameDesignDocument.md`
- 전투 연결: `Docs/CombatSpecification.md`

## 주요 파일

- `EventBus.gd`: 전역 신호
- `GameState.gd`: 런 상태, 거점 영구 상태, 저장/복원, 정산
- `DungeonManager.gd`: 던전 진행
- `PartsFactory.gd`: 파츠 템플릿 복제, stat/affix/durability 롤
- `RewardManager.gd`: 보상 생성

## 주의사항

- AutoLoad API 변경은 여러 씬에 전파되므로 호출부를 `rg`로 먼저 확인한다.
- 저장/복원 필드 추가 시 이전 저장 데이터 기본값과 검증을 같이 고려한다.
- 파츠 롤 규칙은 `PartsSystem`과 `AffixSystem` 기준을 따른다.
- 거점 창고/런 인벤토리/장착 파츠 정산은 `BaseSystem` 계약을 유지한다.

## 검증

```bash
bash Scripts/Validation/validate.sh
```
