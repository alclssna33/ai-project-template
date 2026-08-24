# AI_DEVELOPMENT_POLICY.md — 공통 AI 개발·Git 안전 정책

- Policy version: `1.0.0`
- Status: `Active`
- Applies to: 이 정책을 참조하는 모든 소프트웨어 프로젝트
- Project-specific source: 각 저장소 루트의 `AGENTS.md`

## 0. 목적

이 정책의 목적은 Codex, ChatGPT, Claude Code, 기타 AI 에이전트와 사람이 여러 프로젝트와 여러 작업을 동시에 진행하더라도 다음을 보장하는 것이다.

- 공식 코드인 기본 브랜치를 직접 훼손하지 않는다.
- 각 작업의 코드·브랜치·폴더·소유자를 분리한다.
- 다른 작업자의 미완성 변경을 덮어쓰거나 삭제하지 않는다.
- 최신 기본 브랜치와 검증된 diff를 기준으로 Pull Request를 병합한다.
- 비밀정보, 운영 데이터, 권한, 배포와 같은 고위험 변경을 별도로 통제한다.
- 모든 작업에 재현 가능한 기록과 handoff 정보를 남긴다.

이 문서는 행동 지침이다. 실제 강제는 GitHub branch protection/ruleset, CI, 권한 정책, hooks와 저장소 설정으로 보완한다.

## 1. 프로젝트별 값의 출처

다음 값은 각 저장소의 `AGENTS.md`에서 읽는다.

```text
PROJECT_NAME
REPOSITORY_FULL_NAME
PRIMARY_REMOTE
DEFAULT_BRANCH
MERGE_METHOD
POLICY_VERSION
PROJECT_GUIDE
SETUP/TEST/LINT/TYPECHECK/BUILD/RUN 명령
고위험 경로와 프로젝트별 예외
```

- 값이 없거나 모순되면 추측하지 않는다.
- 저장소 작업 전에 루트 `AGENTS.md`, 이 정책, 대상 경로의 하위 `AGENTS.md`를 읽는다.
- 하위 지침은 해당 경로에 한해 더 구체적인 규칙으로 우선한다.
- 지침 파일이 예상 밖으로 변경됐거나 읽을 수 없으면 쓰기를 중단한다.

## 2. 절대 원칙

1. 공식 기준본은 검증된 원격 저장소의 `DEFAULT_BRANCH`다.
2. 기본 브랜치에서는 관리 작업 외의 파일 수정·commit·직접 push를 하지 않는다.
3. 기본 개발 흐름은 `feature branch → Pull Request → 검토 → squash merge`다.
4. **작업 1개 = 고유 브랜치 1개 = 격리 환경 1개 = 활성 작성자 1명**이다.
5. 동일 브랜치나 worktree를 둘 이상의 작성자가 동시에 수정하지 않는다.
6. 독립 작업만 병렬 처리한다. 같은 파일, 공용 타입, schema, migration, lockfile, CI는 기본적으로 순차 처리한다.
7. 예상하지 못한 변경, 원격 commit, 지침 충돌, 권한 불명확성이 있으면 쓰지 않는다.
8. 설명되지 않은 변경을 자동으로 stash, restore, reset, clean, 삭제하거나 덮어쓰지 않는다.
9. AI는 현재 PR 번호와 동작이 포함된 명시적 지시 없이는 merge하지 않는다.
10. 정책·검증·권한을 우회해 작업을 완료한 것처럼 보고하지 않는다.

## 3. 작업 유형

### 3.1 읽기 전용

파일·ref·GitHub 상태를 바꾸지 않는 조회, 분석, 리뷰, 원인 조사다.

- 별도 브랜치·worktree·선점은 불필요하다.
- 저장소, ref, 검토 SHA와 적용 지침은 확인한다.
- 검증된 원격의 `fetch --prune`은 사용자가 상태 불변을 요구하지 않은 경우에만 metadata sync 예외로 허용한다.

### 3.2 GitHub 조정 메타데이터 쓰기

Issue·PR 댓글, label, assignee, reviewer, Draft 상태, 리뷰 요청 등이다.

- 별도 브랜치·worktree는 불필요하다.
- 정확한 저장소, Issue/PR 번호, 대상 SHA, 현재 상태, 중복 동작 여부와 권한을 확인한다.

### 3.3 저장소 콘텐츠·작업 ref 쓰기

파일 수정, commit, feature branch 생성, push, PR 생성·갱신이다.

- 고유 브랜치와 worktree 또는 동등한 격리 환경이 필요하다.
- 이 정책의 시작 gate, 작업 선점, 검증 및 push 절차를 모두 적용한다.

### 3.4 관리용 Git 쓰기

검증된 clean 기본 브랜치의 fast-forward, fetch/prune, 병합 완료 브랜치·worktree 정리 등이다.

- feature branch는 불필요하다.
- 정확한 경로·ref, clean 상태, 활성 작성자 부재, merge 또는 복구 근거를 확인한다.
- 사용자 소유 변경을 건드리지 않는다.

### 3.5 고위험 쓰기

PR merge, branch protection·저장소 설정, 배포, 운영 DB·migration, secret·권한·인프라 변경이다.

- 현재 대상과 동작을 구체적으로 포함한 별도 사용자 승인이 필요하다.
- 실행 직전 대상 SHA·상태·권한을 다시 확인한다.
- 영향 범위, 검증, rollback 계획과 미확인 사항을 기록한다.

작업 유형이 애매하면 더 엄격한 유형을 적용한다. 읽기 전용 작업이 쓰기로 바뀌면 즉시 중단하고 해당 gate를 처음부터 수행한다.

## 4. 지침 파일과 정책 무결성

- 추적되는 `AGENTS.override.md`는 사용하지 않는다. 발견되면 쓰기를 중단하고 경로만 보고한다.
- 적용 경로의 미추적·ignored `AGENTS*.md`, `CLAUDE*.md`, `.claude/rules/**`, `.claude/settings*.json`이 있으면 내용을 출력하지 말고 경로만 보고한 뒤 쓰지 않는다.
- 정책 파일을 수정하는 작업은 전용 브랜치와 PR로 분리한다.
- 제안 중인 새 정책으로 현재 작업의 승인·검증 절차를 완화하지 않는다.
- upstream에서 정책·지침 파일이 바뀌면 최신 기본 브랜치를 반영하고 새 run/session에서 다시 읽은 뒤 작업을 재개한다.

### Claude Code

- 저장소 루트 `CLAUDE.md`는 가능한 한 `@AGENTS.md`를 단일 진입점으로 사용한다.
- 세션 시작 시 `/memory`에서 현재 로드된 `CLAUDE.md`, imported files와 rules를 확인한다.
- 같은 저장소의 여러 worktree에서 Claude Code를 병렬로 사용할 때는 auto memory를 비활성화하거나 브랜치별 미완성 정보를 기록하지 않도록 통제한다.
- 엄격한 감사가 필요하면 `InstructionsLoaded` hook 등 관찰 수단으로 실제 로드 경로를 기록한다.

## 5. 저장소 및 원격 검증

### 5.1 로컬 Git 에이전트

어떤 네트워크 명령보다 먼저 저장소 루트와 원격 fetch/push URL을 확인한다.

- 원격 URL은 `AGENTS.md`의 `REPOSITORY_FULL_NAME`과 일치해야 한다.
- HTTPS·SSH 표기와 선택적 `.git` 접미사를 정규화해 비교한다.
- URL의 userinfo, username, password, token, query, fragment는 제거한다.
- 원본 credential 포함 URL을 채팅, Issue, PR, 로그에 출력하지 않는다.
- 불일치하거나 안전하게 판정할 수 없으면 `fetch`, `pull`, `push` 전에 중단한다.

기본 점검 예시:

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --short --branch
git worktree list
git fetch <primary-remote> --prune
git rev-parse <primary-remote>/<default-branch>
git rev-list --left-right --count HEAD...<primary-remote>/<default-branch>
```

upstream이 있으면 현재 branch와 `@{upstream}`의 ahead·behind도 확인한다.

- remote-ahead 또는 diverged: 쓰기 중단
- local-ahead만 존재: 모든 commit이 현재 작업·작성자 소유일 때만 허용
- upstream 부재: 원격 선점 전의 새 고유 branch에서만 허용

### 5.2 GitHub 직접 연결·클라우드 에이전트

플랫폼이 요구하는 connector discovery, 함수 스키마 조회, 인증 상태 확인은 저장소 콘텐츠 읽기보다 먼저 수행할 수 있다.

그 이후 첫 저장소 콘텐츠 읽기는 다음을 명시해 루트 `AGENTS.md`를 조회한다.

```text
owner/repository: 사용자가 지정한 대상 저장소
ref: DEFAULT_BRANCH
path: AGENTS.md
```

이후 다음을 확인한다.

- `repository_full_name`, owner, 기본 브랜치, 최신 기본 브랜치 SHA
- 열린 Issue·PR·원격 브랜치와 중복 작업
- 대상 파일 경로에 적용되는 하위 지침
- 업데이트하려는 파일의 최신 blob SHA

409, non-fast-forward, 예상 밖 SHA 변경이 발생하면 자동 재시도·덮어쓰기를 하지 않는다.

## 6. 작업 시작 gate

저장소 콘텐츠·ref 쓰기 전에 다음을 모두 통과해야 한다.

- 저장소와 원격이 `AGENTS.md`의 프로젝트 식별 정보와 일치한다.
- 최신 원격 기본 브랜치를 확인했다.
- 현재 작업용 고유 branch와 격리 환경이다.
- working tree와 index가 clean하다.
- 다른 작성자가 같은 branch·worktree를 사용하지 않는다.
- merge, rebase, cherry-pick가 진행 중이지 않다.
- branch 목적과 사용자 요청이 일치한다.
- 원격 branch에 예상 밖 commit이 없다.
- 적용 가능한 모든 지침을 읽었다.
- 기존 test/lint/typecheck/build 설정과 실행법을 확인했다.
- 열린 Issue·PR·branch의 작업 범위와 수정 예정 파일이 겹치지 않는다.

실패하면 삭제·restore·stash·덮어쓰기·자동 재시도하지 않고 상태와 다음 조치를 보고한다.

## 7. 브랜치·worktree·작업 선점

기본 브랜치 이름:

```text
ai/<agent>/<issue>-<task-slug>[-<session-id>]
ai/<agent>/<YYYYMMDD-HHMMSS>-<task-slug>-<session-id>
```

- 최신 원격 기본 브랜치에서 branch를 만든다.
- 로컬 병렬 작업은 각각 별도 worktree를 사용한다.
- 관리용 기본 브랜치 worktree에서는 애플리케이션 파일을 수정하지 않는다.
- 병렬 가능성이 있는 작업은 수정 전에 Issue 또는 원격 조정 기록에 담당자, 범위, 예정 파일, 기준 기본 브랜치 SHA를 남긴다.
- clean branch를 원격에 먼저 공개하고, 첫 실제 commit 후 가능한 즉시 Draft PR을 연다.
- 원격 선점을 할 수 없으면 다른 에이전트와 병렬 실행하지 않는다.
- 동일 파일, manifest/lockfile, 공용 설정·타입, schema/migration, CI/CD, 생성 파일, 대규모 포맷팅은 동시에 수정하지 않는다.
- 의존 작업은 선행 PR merge 후 최신 기본 브랜치에서 시작한다. stacked PR은 명시적으로 승인된 경우에만 사용한다.

### Codex 관리 worktree의 detached HEAD

Codex가 만든 detached HEAD는 다음 조건에서만 임시 수정·검증 환경으로 허용한다.

- 실제 linked worktree이며 submodule이 아니다.
- 시작 SHA가 지정된 최신 기본 브랜치 SHA와 같다.
- 현재 작업·대화 하나만 사용하고 clean 상태다.
- 기존 작성자의 branch·commit이나 진행 중인 merge/rebase/cherry-pick가 없다.

Detached HEAD에서는 commit·push하지 않는다. commit 전에 고유 branch를 만들거나 Local로 handoff한다.

## 8. 수정과 commit

- 요청을 충족하는 최소 범위만 변경한다.
- 관련 없는 리팩터링, 이름 변경, 파일 이동, 전체 포맷팅을 섞지 않는다.
- 동작을 변경·삭제하기 전에 호출부, 테스트, 문서와 설정을 검색한다.
- 새 dependency는 필요성과 대안을 설명하고 승인 없이 추가하지 않는다.
- dependency가 바뀌지 않았다면 lockfile을 재생성하지 않는다.
- migration 이름은 열린 작업과 중복되지 않게 한다.
- 생성 파일은 공식 생성 명령으로만 갱신한다.
- `.env`, API key, token, cookie, 인증서, 개인키, 운영 데이터를 commit하거나 출력하지 않는다.
- 기존 테스트를 삭제·skip·완화하거나 오류를 숨겨 통과시키지 않는다.
- commit은 작은 독립 단위로 만들고 Conventional Commit 형식을 사용한다.

commit 전:

```bash
git status --short
git diff
git add <명시적-파일-경로>
git diff --cached
git diff --cached --check
```

`git add .` 또는 `git add -A`를 습관적으로 사용하지 않는다. 이미 push한 commit의 amend·기록 재작성은 하지 않는다.

## 9. 최신 기본 브랜치 반영과 충돌

feature branch에서 `git pull`을 맹목적으로 실행하지 않는다.

1. `fetch --prune`
2. 현재 branch에 없는 기본 브랜치 commit·diff 확인
3. 기본적으로 `git merge --no-edit <remote>/<default-branch>` 사용
4. merge 후 모든 검증 재실행

- push·공유 branch는 rebase하지 않는다.
- rebase는 미push·단독 소유 branch에서 사용자 승인 시에만 허용한다.
- 충돌은 파일별 목적을 분석해 양쪽 의도를 보존한다.
- 파일 전체에 `ours` 또는 `theirs`를 일괄 적용하지 않는다.
- 확신이 없으면 `git merge --abort` 후 보고한다.
- 해결 후 conflict marker를 검색하고 관련 검증을 다시 실행한다.

## 10. Push 전 검증

모든 의도된 변경을 commit한 clean 상태에서 시작한다.

1. test/lint/typecheck/build 실행
2. 각 검증 직후 `git status --short`가 비어 있는지 확인
3. 원격 기본 브랜치 fetch
4. 정책·지침 파일 변경 여부 확인
5. 최신 기본 브랜치 merge
6. merge 후 검증 전체 재실행
7. 전체 PR diff와 commit 목록 검토
8. push 직전 다시 fetch하여 검증 기준 SHA가 그대로인지 확인
9. working tree, index, 검토한 head/upstream SHA가 그대로일 때만 push

정책·지침 파일 변경 감지 범위:

```text
**/AGENTS*.md
**/CLAUDE*.md
**/.claude/rules/**
**/.claude/settings*.json
```

upstream에서 위 파일이 변경됐다면 최신 기본 브랜치를 반영한 뒤 현재 세션의 추가 수정·검증·push를 중단한다. 새 run/session에서 지침을 다시 읽고 검증을 처음부터 반복한다.

최종 diff 검토 예시:

```bash
git diff --check <remote>/<default-branch>...HEAD
git diff --name-status <remote>/<default-branch>...HEAD
git diff --stat <remote>/<default-branch>...HEAD
git diff <remote>/<default-branch>...HEAD
git log --oneline <remote>/<default-branch>..HEAD
```

다음을 확인한다.

- 요청 밖 파일 없음
- 예상 밖 삭제·대량 변경·바이너리 없음
- 비밀정보 없음
- dependency, migration, CI, 권한, 배포 영향 기록
- 미구성·미실행 검증과 수동 검증을 명확히 구분

non-fast-forward면 force push하지 않는다.

## 11. Pull Request와 merge

- PR base는 `DEFAULT_BRANCH`, head는 현재 고유 feature branch다.
- PR에는 Issue, 담당 에이전트·세션, 기준 기본 브랜치 SHA, 변경 요약, 주요 파일, 테스트, 미실행 검증, 위험, 의존 PR을 기록한다.
- 진행 중이면 Draft PR을 사용한다.
- CI 실패와 리뷰 대화를 해결하고 `Files changed` 전체를 검토한다.
- merge 직전 기본 브랜치가 바뀌면 반영·검증·리뷰를 반복한다.
- 기본 merge 방식은 squash다.
- merge 후 해당 feature branch에는 추가 push하지 않는다.

### 조건부 AI merge

AI가 merge하려면 사용자가 현재 PR 번호와 조건을 명시해야 한다.

예:

```text
PR #123의 최신 diff와 checks를 다시 확인하고, 문제가 없으면 squash merge해.
```

AI는 다음을 확인한다.

1. base와 head branch
2. 최신 기본 브랜치 SHA와 PR head SHA
3. 작성자, commit, 중복 PR
4. 전체 diff와 요청 범위
5. 삭제, 대량 변경, 비밀정보, 보안·호환성 위험
6. conflict, required checks, 리뷰와 대화 해결
7. 프로젝트 test/lint/typecheck/build
8. merge 직전 head SHA와 checks 재조회
9. 가능하면 expected head SHA 조건 전달
10. merge 결과가 원격 기본 브랜치에 포함됐는지 검증

SHA 변경, 실패, 충돌, 미확인 또는 권한 부족이 있으면 merge하지 않는다. 위임은 지정된 PR 한 건에만 유효하며 blanket auto-merge나 조건 변경 후 자동 재시도에는 적용되지 않는다.

### 추가 승인 또는 사람 리뷰가 필요한 변경

- `AGENTS*.md`, `CLAUDE*.md`, `.claude/rules/**`, `.claude/settings*.json`
- 인증, 결제, 권한, 보안 정책
- 운영 DB, migration, 데이터 변경
- 배포, secret, 인프라/IaC
- dependency manifest, lockfile, 신규 외부 패키지
- CI/CD, GitHub Actions 권한, hooks

위 변경은 일반 문서 예외로 보지 않는다. 전체 diff와 기존 안전 규칙 약화 여부를 검토하고, 위험을 인지한 사용자 재승인 또는 사람 리뷰가 있어야 AI가 merge할 수 있다.

추적된 `CLAUDE.local.md` 또는 `.claude/settings.local.json`은 로컬 설정 유출로 간주하고 merge하지 않는다.

실행 코드인데 test/build/CI가 모두 미구성이면 수동 검증과 한계를 보고하고 해당 PR에 대한 사용자 재승인 전에는 merge하지 않는다.

## 12. 금지 명령과 행동

구체적인 사용자 승인과 복구 계획 없이 다음을 실행하지 않는다.

```bash
git push <remote> <default-branch>
git push --force
git push --force-with-lease
git reset --hard
git clean -fd
git clean -fdx
git checkout -- .
git restore .
git branch -D
git commit --amend
git rebase <shared-or-pushed-branch>
```

또한 다음을 금지한다.

- 임의 PR merge
- branch protection·ruleset 우회 또는 해제
- 다른 작성자의 branch·worktree 삭제
- 운영 배포·DB·데이터 수정
- secret 생성·회전·노출
- 테스트·보안 검사 우회
- 검증하지 않은 상태를 성공으로 보고

## 13. Handoff와 완료

handoff에는 다음을 남긴다.

```text
Mode:
Repository:
Branch:
Environment/worktree:
Base branch SHA:
Head SHA:
PR/Issue:
Changed files:
Completed:
Tests passed:
Tests not run:
Remaining work:
Known risks:
Clean status:
Next action:
```

- 다음 작성자는 fetch 후 전달된 SHA를 확인한다.
- handoff 완료 전에는 동일 branch·worktree를 동시에 수정하지 않는다.
- 읽기 전용 작업은 검토 ref·SHA, 근거, 발견 사항, 한계와 다음 조치를 보고하면 완료다.
- 쓰기 작업은 최신 기본 브랜치 반영, 전체 diff·검증, clean commit, feature branch push, PR·위험 보고까지 끝나야 완료다.

## 14. GitHub 강제 설정 권장값

문서 규칙만으로 안전을 보장하지 않는다. 기본 브랜치에 branch protection 또는 ruleset을 적용한다.

권장값:

```text
Require a pull request before merging: ON
Require conversation resolution: ON
Block force pushes: ON
Block branch deletion: ON
Do not allow bypassing: ON 또는 최소화
Allow squash merging: ON
Allow merge commits: OFF
Allow rebase merging: OFF
Automatically delete head branches: ON
```

CI가 구성되면 추가한다.

```text
Require status checks to pass: ON
Require branches to be up to date: ON
```

## 15. 정책 유지보수

- 공통 정책 변경은 별도 PR로 수행한다.
- 프로젝트별 예외는 각 저장소 `AGENTS.md`에 근거, 승인자, 승인일, 재검토일과 함께 기록한다.
- 긴 예제와 장애 대응은 별도 workflow·skill로 분리하되 핵심 gate는 제거하지 않는다.
- 정책 파일은 간결하게 유지하고 실제 사고·충돌·운영 실패에서 확인된 문제만 반영한다.
- 정책 버전 변경 시 영향을 받는 저장소와 AI 세션에서 새 지침을 다시 로드한다.
