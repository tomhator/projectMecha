---
tags: [project/project-mecha, document/specification]
status: in-progress
version: 1.0
created: 2026-05-21
updated: 2026-05-21
---

# 어빌리티 트리 시스템

> [!info] 관련 문서
> - 전체 게임 구조: [[GameDesignDocument]]
> - 전투 시스템: [[CombatSpecification]]

---

## 개요

코어 선택을 단일 코어로 고정하고, 대신 **거점(런 시작 전 화면)에서 어빌리티 트리 노드를 찍어 빌드를 구성**한다.
특정 분기의 끝 노드에 도달하면 해당 분기의 **코어 스킬**이 언락된다.

- 코어는 `core_base.tres` 1개로 고정 (HP 100, 쉴드 20, 행동력 2, 공격배율 1.0)
- 런마다 **3 포인트** 지급
- 포인트를 소비해 원하는 노드를 선택
- 전투에서 사용할 수 있는 코어 스킬은 선택한 분기에 따라 결정

---

## 트리 구조

```
           [기본 코어]
          /    |    \
   [공격]   [방어]  [기동]
      |         |       |
   [화력]   [실드]  [부스터]
      |         |       |
  [코어스킬] [코어스킬] [코어스킬]
```

### 공격 분기

| 노드 ID | 이름 | 비용 | 선행 | 효과 |
|---------|------|------|------|------|
| node_attack_1 | 공격 강화 | 1pt | 없음 | 공격배율 +15% |
| node_attack_2 | 화력 과부하 | 1pt | node_attack_1 | 공격배율 +15% |
| node_attack_core | 관통 포격 [코어 스킬] | 1pt | node_attack_2 | 스킬 언락: `skill_railgun_pierce` |

### 방어 분기

| 노드 ID | 이름 | 비용 | 선행 | 효과 |
|---------|------|------|------|------|
| node_defense_1 | 장갑 보강 | 1pt | 없음 | 최대 HP +40 |
| node_defense_2 | 실드 발생기 | 1pt | node_defense_1 | 최대 쉴드 +30 |
| node_defense_core | 철갑 방어 [코어 스킬] | 1pt | node_defense_2 | 스킬 언락: `skill_iron_shield` |

### 기동 분기

| 노드 ID | 이름 | 비용 | 선행 | 효과 |
|---------|------|------|------|------|
| node_mobility_1 | 기동 향상 | 1pt | 없음 | 행동력 +1 |
| node_mobility_2 | 가속 부스터 | 1pt | node_mobility_1 | 행동력 +1 |
| node_mobility_core | 선제 도약 [코어 스킬] | 1pt | node_mobility_2 | 스킬 언락: `skill_assault_leap` |

---

## 포인트 규칙

- 런 시작 시 **3포인트** 고정 지급
- 분기 완주(코어 스킬 언락)에는 **3포인트 전부** 필요
- 3포인트를 여러 분기에 분산하면 스탯 강화만 얻고 코어 스킬은 없는 채로 출격
- 노드 **해제(환불)** 가능: 해당 노드를 요구하는 상위 노드가 없는 경우에만

---

## 구현 파일

| 역할 | 파일 |
|------|------|
| 노드 데이터 클래스 | `Resources/AbilityTreeNode.gd` |
| 노드 리소스 (9개) | `Resources/AbilityTree/*.tres` |
| 단일 코어 리소스 | `Resources/Cores/core_base.tres` |
| 트리 UI 씬 | `Scenes/CoreSelect/CoreSelectScene.gd` |
| 런 상태 관리 | `Scripts/Autoload/GameState.gd` |
| 코어 스킬 적용 | `Scenes/Entities/MechaEntity.gd` |

---

## GameState API

```gdscript
# 런 시작 (core_base 자동 로드)
GameState.start_run()

# 선택된 노드 스탯/스킬 적용 (출격 시 호출)
GameState.apply_tree_node(node: AbilityTreeNode)

# 언락된 코어 스킬 (null이면 코어스킬 없음)
GameState.active_core_skill: SkillData
```
