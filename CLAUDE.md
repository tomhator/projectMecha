You must answer in Korean.

## 공통 규칙 참조

프로젝트 공통 규칙(작업 체크리스트, 코드 규칙, 커밋 규칙, AI 협업 워크플로우)은
**`AGENTS.md`** 를 먼저 읽고 따른다. 이 파일은 Claude 전용 추가 설정만 담는다.

---

## PR 생성 절차 (필수 — 매번 반복)

PR을 생성하기 전에 반드시 아래 절차를 수행한다.

```bash
# 1. main 최신화
git fetch origin main

# 2. 현재 브랜치에 rebase
git rebase origin/main

# 3. 충돌 발생 시 해결 후 계속
git rebase --continue   # 충돌 해결 후

# 4. 강제 푸시 (rebase 후 필요)
git push -u origin <branch-name> --force-with-lease

# 5. PR 생성
```

**규칙:**
- PR 생성 전 rebase를 건너뛰지 않는다.
- 충돌이 발생하면 해결 후 진행한다. 충돌을 무시하거나 merge로 대체하지 않는다.
- rebase 완료 후 push는 반드시 `--force-with-lease` 옵션을 사용한다.

---

## gstack (REQUIRED — Claude Code 전용)

**작업 시작 전 gstack 설치 여부를 확인한다:**

```bash
test -d ~/.claude/skills/gstack/bin && echo "GSTACK_OK" || echo "GSTACK_MISSING"
```

GSTACK_MISSING 이면 즉시 중단하고 사용자에게 아래를 안내한다:

> gstack이 설치되어 있지 않습니다. 아래 명령으로 설치하세요:
> ```bash
> git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
> cd ~/.claude/skills/gstack && ./setup --team
> ```
> 설치 후 Claude Code를 재시작하세요.

gstack 오류를 무시하거나 우회하지 않는다.
gstack 파일 경로: `~/.claude/skills/gstack/`
웹 브라우징은 `/browse` 를 사용한다.

---

## 스킬 라우팅 (Claude Code + gstack 전용)

사용자 요청이 아래 스킬과 일치하면 즉시 해당 스킬을 호출한다.

| 요청 유형 | 스킬 |
|----------|------|
| 제품 아이디어/브레인스토밍 | `/office-hours` |
| 전략/범위 결정 | `/plan-ceo-review` |
| 아키텍처 설계 | `/plan-eng-review` |
| 디자인 시스템/계획 검토 | `/design-consultation` 또는 `/plan-design-review` |
| 전체 리뷰 파이프라인 | `/autoplan` |
| 버그/오류 | `/investigate` |
| QA/사이트 동작 테스트 | `/qa` 또는 `/qa-only` |
| 코드 리뷰/diff 확인 | `/review` |
| 시각적 개선 | `/design-review` |
| 배포/PR | `/ship` 또는 `/land-and-deploy` |
| 진행 저장 | `/context-save` |
| 컨텍스트 복원 | `/context-restore` |
