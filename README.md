# AI Project Template

Codex, ChatGPT, Claude Code와 사람이 여러 작업을 동시에 진행할 때 브랜치·worktree·Pull Request를 안전하게 운영하기 위한 중앙 프로젝트 템플릿입니다.

이 저장소는 GitHub의 **Template repository**로 설정되어 있으며 신규 프로젝트 생성에 사용합니다. 신규 저장소는 템플릿의 파일 구조를 복사하지만 이후에는 독립된 저장소가 되므로, 공통 정책 변경은 각 프로젝트에 별도 동기화 PR로 반영합니다.

## 포함된 구성

| 경로 | 역할 |
| --- | --- |
| `AGENTS.md` | AI가 자동으로 읽는 프로젝트별 진입점과 값 템플릿 |
| `docs/AI_DEVELOPMENT_POLICY.md` | 모든 프로젝트에 공통 적용할 개발·Git 안전 정책 |
| `docs/PROJECT_GUIDE.md` | 기술 스택, 실행, 검증, 배포를 기록하는 프로젝트 가이드 |
| `CLAUDE.md` | Claude Code가 `AGENTS.md`를 읽도록 연결하는 진입점 |
| `.claude/settings.json` | 병렬 worktree 간 auto memory 혼선을 막기 위한 기본 설정 |
| `.github/pull_request_template.md` | 검증·위험·복구 정보를 강제하는 PR 양식 |
| `.github/workflows/policy-check.yml` | 필수 정책 파일과 자리표시자·로컬 설정 유출을 검사하는 CI |
| `scripts/initialize-project.ps1` | 신규 프로젝트의 자리표시자와 README를 초기화하는 Windows 스크립트 |
| `scripts/check-policy.ps1` | Windows용 정책 무결성 검사 |
| `scripts/check-policy.sh` | GitHub Actions·Linux/macOS용 정책 무결성 검사 |
| `prompts/` | 신규 프로젝트, 기존 프로젝트 도입, 정책 동기화, 일반 작업 시작 프롬프트 |
| `POLICY_VERSION` | 중앙 정책 버전 |

## 1. 중앙 템플릿 저장소 상태

`alclssna33/ai-project-template`는 현재 GitHub **Template repository**로 설정되어 있습니다.

```text
Template repository: ON
```

저장소 상단의 **Use this template** 버튼으로 신규 프로젝트를 생성합니다. 이 설정은 중앙 템플릿 저장소에만 적용하며, 템플릿으로 생성한 downstream 프로젝트에 자동으로 요구하지 않습니다.

## 2. 신규 프로젝트 생성

### GitHub 화면

```text
1. ai-project-template 저장소에서 Use this template 클릭
2. Create a new repository 선택
3. 새 저장소 이름과 공개 범위 지정
4. Create repository from template 클릭
```

### GitHub CLI

```powershell
gh repo create alclssna33/<새-프로젝트명> --private --template alclssna33/ai-project-template --clone
```

템플릿으로 생성한 저장소는 중앙 템플릿과 별도 Git 이력을 갖습니다.

## 3. 신규 프로젝트 초기화

새 저장소를 clone한 뒤 기능 개발보다 먼저 초기화 PR을 만듭니다.

```powershell
cd <새-프로젝트명>
git switch -c ai/setup/project-bootstrap-<session-id>

pwsh ./scripts/initialize-project.ps1 `
  -ProjectName "<프로젝트명>" `
  -RepositoryFullName "alclssna33/<새-프로젝트명>" `
  -DefaultBranch "main" `
  -WhatIf

pwsh ./scripts/initialize-project.ps1 `
  -ProjectName "<프로젝트명>" `
  -RepositoryFullName "alclssna33/<새-프로젝트명>" `
  -DefaultBranch "main"
```

첫 명령은 dry-run입니다. 출력된 대상과 값이 맞고 `git status --short`가 비어 있음을 확인한 뒤 두 번째 명령을 실행합니다.

스크립트는 쓰기 전에 다음 상태를 거부합니다.

- 기본 브랜치 또는 detached HEAD
- clean하지 않은 working tree 또는 index
- merge, rebase, cherry-pick, revert 진행 상태
- fetch/push 원격과 `RepositoryFullName` 불일치
- 필수 정책·prompt·script·workflow 파일 누락
- `POLICY_VERSION`과 공통 정책 파일의 버전 불일치

`-Force` 우회 옵션은 없습니다. 안전 gate를 통과하지 못하면 수정하지 않고 중단해야 합니다.

스크립트는 gate 통과 후 다음을 수행합니다.

- `AGENTS.md`의 핵심 자리표시자 교체
- `docs/PROJECT_GUIDE.md`의 프로젝트명·저장소 교체
- 템플릿용 README를 프로젝트 README로 교체
- 미해결 핵심 자리표시자 검사

그다음 실제 프로젝트에 맞게 `미정`·`미구성` 항목을 채우고 검사합니다.

```powershell
pwsh ./scripts/check-policy.ps1
git diff
git add AGENTS.md README.md docs/PROJECT_GUIDE.md
git add -u -- templates/PROJECT_README.md
git commit -m "chore: initialize project policy"
git push -u origin HEAD
gh pr create --draft --base main --title "chore: initialize project policy"
```

전체 변경을 반드시 먼저 검토하고, 삭제 파일도 명시적으로 stage합니다.

AI에 초기화를 맡길 때는 [`prompts/NEW_PROJECT_BOOTSTRAP.md`](prompts/NEW_PROJECT_BOOTSTRAP.md)를 사용합니다.

## 4. 기존 프로젝트에 도입

기존 저장소를 다시 만들지 않습니다. 별도 정책 도입 브랜치에서 중앙 템플릿 파일을 읽고 기존 규칙과 통합합니다.

권장 대상:

```text
AGENTS.md
docs/AI_DEVELOPMENT_POLICY.md
docs/PROJECT_GUIDE.md
CLAUDE.md
.claude/settings.json
.github/pull_request_template.md
.github/workflows/policy-check.yml
scripts/check-policy.*
POLICY_VERSION
```

기존 `AGENTS.md`, `CLAUDE.md`, PR 템플릿, Claude 설정을 무조건 덮어쓰면 안 됩니다. [`prompts/ADOPT_EXISTING_PROJECT.md`](prompts/ADOPT_EXISTING_PROJECT.md)를 사용해 프로젝트별 규칙과 명령을 보존한 Draft PR을 만듭니다.

## 5. 일반 개발 작업 시작

각 작업은 다음 원칙을 따릅니다.

```text
작업 1개 = 고유 브랜치 1개 = 격리된 worktree/환경 1개 = 활성 작성자 1명
```

- 기본 브랜치에서 직접 개발하지 않습니다.
- 병렬 작업은 수정 전에 Issue 또는 Draft PR에 범위와 예정 파일을 기록합니다.
- 최신 기본 브랜치를 반영한 뒤 테스트와 전체 diff를 다시 검토합니다.
- AI는 사용자가 현재 PR 번호를 지정해 조건부 merge를 요청하기 전에는 merge하지 않습니다.

공통 시작 명령은 [`prompts/START_WORK.md`](prompts/START_WORK.md)를 사용합니다.

## 6. 정책 업데이트와 기존 프로젝트 동기화

중앙 정책을 바꿀 때:

```text
1. 이 저장소에서 전용 정책 브랜치와 PR 생성
2. docs/AI_DEVELOPMENT_POLICY.md 수정
3. POLICY_VERSION 증가
4. 검사 통과 후 main에 merge
5. 각 프로젝트에서 별도 정책 동기화 PR 생성
```

템플릿에서 생성된 저장소에는 중앙 변경이 자동 반영되지 않습니다. 각 프로젝트에서 [`prompts/SYNC_POLICY.md`](prompts/SYNC_POLICY.md)를 사용해 현재 버전과 중앙 버전을 비교하고 정책 파일만 동기화합니다.

## 7. Codex와 Claude Code 전역 진입 규칙

저장소 내부 파일이 실제 기준입니다. 전역 설정은 프로젝트의 `AGENTS.md`를 확인하도록 유도하는 짧은 진입 규칙만 둡니다.

### Codex — Windows

```text
%USERPROFILE%\.codex\AGENTS.md
```

권장 내용:

```markdown
모든 Git 저장소에서 작업 전에 루트 AGENTS.md를 확인한다.
AGENTS.md가 없으면 코드 수정을 시작하지 않고 중앙 템플릿 적용 필요성을 보고한다.
기본 브랜치 직접 수정·push, force push, 파괴적 정리는 임의로 수행하지 않는다.
```

### Claude Code — Windows

```text
%USERPROFILE%\.claude\CLAUDE.md
```

권장 내용:

```markdown
Git 저장소에서 작업할 때 프로젝트 CLAUDE.md와 루트 AGENTS.md를 먼저 확인한다.
필수 지침이 없으면 쓰기 작업을 시작하지 않는다.
동일 저장소의 병렬 세션은 branch와 worktree를 분리한다.
```

## 8. GitHub 저장소 설정

중앙 템플릿 저장소 `alclssna33/ai-project-template`는 다음 상태로 운영합니다.

```text
Template repository: ON
Allow squash merging: ON
Allow merge commits: OFF
Allow rebase merging: OFF
Automatically delete head branches: ON
```

템플릿으로 생성한 downstream 프로젝트에는 `Template repository: ON`을 요구하지 않습니다. 각 프로젝트에는 기본 브랜치 보호를 적용합니다.

```text
Default branch protection/ruleset:
- Require a pull request before merging
- Require conversation resolution
- Block force pushes
- Block branch deletion
- Do not allow bypassing 또는 최소화
```

버전 1.1이 `main`에 merge되고 새 workflow가 `main`에서 통과한 뒤 required status checks와 최신 기본 브랜치 반영 조건을 추가합니다. required check 이름은 정확히 `Policy integrity / Ubuntu`, `Policy integrity / Windows`입니다.

## 9. 검사

중앙 템플릿 저장소에서 자리표시자를 허용해 검사:

```powershell
pwsh ./scripts/check-policy.ps1 -AllowTemplatePlaceholders
bash ./scripts/check-policy.sh --allow-template-placeholders
```

초기화가 끝난 일반 프로젝트에서 검사:

```powershell
pwsh ./scripts/check-policy.ps1
bash ./scripts/check-policy.sh
```

GitHub Actions는 `Policy integrity / Ubuntu`와 `Policy integrity / Windows` 두 job을 실행합니다. 중앙 템플릿 저장소에서는 명시적 template-placeholder 옵션을 전달하고, 템플릿으로 생성된 다른 저장소에서는 미해결 자리표시자를 실패 처리합니다.

## 10. 정책 운영 원칙

- 공통 정책은 중앙 저장소에서만 설계하고 버전을 올립니다.
- 프로젝트별 명령·경로·예외는 각 프로젝트의 `AGENTS.md`에 둡니다.
- 정책 파일 변경은 일반 문서 PR이 아니라 에이전트 권한·행동 정책 변경으로 검토합니다.
- 실제 사고·충돌·운영 실패로 확인된 문제만 공통 정책에 추가합니다.
- 긴 절차는 별도 workflow나 prompt로 분리하고 루트 지침을 과도하게 키우지 않습니다.
