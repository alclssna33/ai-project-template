# AGENTS.md — {{PROJECT_NAME}}

> 이 파일은 이 저장소에서 작업하는 AI 에이전트와 사람 작업자의 **프로젝트별 진입점**이다. 공통 개발·Git 안전 규칙은 `{{POLICY_PATH}}`를 단일 기준으로 삼는다.

## 0. 템플릿 및 초기화 상태

- 중앙 원본 저장소 `alclssna33/ai-project-template`에서는 중괄호 형식의 자리표시자가 의도된 템플릿 값이다.
- 이 템플릿으로 생성한 다른 저장소에서 자리표시자가 남아 있으면 **bootstrap 미완료 상태**다.
- bootstrap 미완료 상태에서는 애플리케이션 기능 개발을 시작하지 않는다. 고유 초기화 브랜치에서 `scripts/initialize-project.ps1`을 실행하고 프로젝트별 값을 검토한 뒤 PR로 반영한다.
- bootstrap 작업도 `main` 직접 수정·push 없이 진행한다.

## 1. 프로젝트 식별 정보

- Project: `{{PROJECT_NAME}}`
- Repository: `{{REPOSITORY_FULL_NAME}}`
- Primary remote: `{{PRIMARY_REMOTE}}`
- Default branch: `{{DEFAULT_BRANCH}}`
- Merge method: `{{MERGE_METHOD}}`
- Policy version: `{{POLICY_VERSION}}`
- Common policy: `{{POLICY_PATH}}`
- Project guide: `{{PROJECT_GUIDE_PATH}}`
- Issue tracker: `{{ISSUE_TRACKER}}`

## 2. 필수 읽기 순서

저장소 작업 전에 다음 순서로 확인한다.

1. 플랫폼·시스템 지침과 사용자의 현재 명시적 요청
2. 이 저장소의 루트 `AGENTS.md`
3. `{{POLICY_PATH}}`
4. 수정 대상 경로까지의 상위 디렉터리에 있는 더 구체적인 `AGENTS.md`
5. `{{PROJECT_GUIDE_PATH}}`와 작업 관련 설계·운영 문서

- 더 가까운 경로의 `AGENTS.md`가 해당 경로에서 더 구체적인 규칙으로 우선한다.
- 필수 문서를 읽을 수 없거나 서로 충돌하면 추측하지 말고 쓰기 작업을 중단·보고한다.
- 추적되는 `AGENTS.override.md`는 만들지 않는다. 발견되면 쓰기를 중단하고 경로만 보고한다.
- 공통 정책을 이 파일에 중복 복사하지 않는다. 프로젝트별 값·명령·예외만 기록한다.

## 3. 프로젝트별 명령

존재하지 않는 명령을 추측하지 않는다. 미구성 항목은 그대로 유지하고 완료 보고에 명시한다.

```text
Setup:      미구성
Run:        미구성
Test:       미구성
Lint:       미구성
Typecheck:  미구성
Build:      미구성
Format:     미구성
Smoke:      미구성
Migration:  해당 없음 또는 미구성
```

## 4. 프로젝트 구조

```text
Application entrypoint: 미정
Frontend:               해당 없음 또는 미정
Backend/API:            해당 없음 또는 미정
Database/schema:        해당 없음 또는 미정
Tests:                  미정
Generated files:        해당 없음 또는 미정
Infrastructure/CI:      해당 없음 또는 미정
Deployment:             해당 없음 또는 미정
Documentation:          docs/
```

### 별도 승인 대상

프로젝트에 맞게 아래 항목을 구체적인 경로로 교체한다.

- 운영 환경 설정
- DB schema·migration
- 인증·결제·권한 코드
- 자동 생성 파일·vendor 코드
- 배포·인프라·GitHub Actions

위 항목을 변경해야 하면 범위, 위험, 검증, rollback 계획을 먼저 보고하고 명시적 승인을 받는다.

## 5. 브랜치·worktree 기본값

```text
Branch prefix: ai
With issue:    ai/<agent>/<issue>-<task-slug>[-<session-id>]
Without issue: ai/<agent>/<YYYYMMDD-HHMMSS>-<task-slug>-<session-id>
```

- `{{DEFAULT_BRANCH}}`에서는 관리 작업만 수행하고 애플리케이션 파일을 수정하지 않는다.
- 저장소 콘텐츠를 수정하는 작업은 고유 브랜치와 격리된 worktree 또는 동등한 격리 환경에서 수행한다.
- 동일 브랜치 또는 worktree에는 활성 작성자를 한 명만 둔다.
- 병렬 작업 전 Issue·Draft PR 등 원격 조정 기록에 담당자, 범위, 예정 파일, 기준 기본 브랜치 SHA를 남긴다.

## 6. 프로젝트별 개발 규칙

```text
Language/runtime: 미정
Package manager: 미정
Formatting:      미정
Naming:          미정
Error handling:  미정
Logging:         미정
```

### 테스트

- 새 기능: 프로젝트에 구성된 자동 테스트와 필요한 수동 검증을 수행한다.
- 버그 수정: 가능하면 재현 테스트를 먼저 추가하거나 재현 절차를 기록한다.
- 자동 검증이 미구성이면 가능한 수동 검증과 한계를 명시한다.
- 실행 코드 PR은 검증 체계가 미구성인 경우 사용자 재승인 없이 AI가 merge하지 않는다.

### 데이터·보안

- `.env`, API key, token, cookie, 인증서, 개인키, 운영 데이터는 commit하거나 출력하지 않는다.
- 개인정보·민감정보 처리 원칙은 프로젝트 가이드에 기록한다.
- 운영 DB·migration·secret·권한·배포 변경은 고위험 작업으로 분류한다.

## 7. 완료 조건

쓰기 작업은 다음이 모두 충족되어야 완료다.

- 최신 `{{PRIMARY_REMOTE}}/{{DEFAULT_BRANCH}}` 반영
- working tree와 index clean
- 전체 diff 검토
- 가능한 test/lint/typecheck/build 실행
- 미실행 검증과 수동 검증 한계 기록
- 고유 feature branch push
- PR 생성 또는 기존 PR 갱신
- 위험, 의존 작업, 다음 조치 보고

완료 보고 형식:

```text
Mode: write | read-only | metadata | admin | high-risk
Repository:
Branch:
Base branch SHA:
Head SHA:
PR/Issue:
Changed files:
Tests passed:
Tests not run:
Base synchronized:
Known risks:
Next action:
```

## 8. 프로젝트별 예외

공통 정책과 다른 예외가 있다면 아래에만 기록한다. 예외는 안전 규칙을 약화하지 않아야 하며 근거와 승인 정보를 포함한다.

```text
예외: 없음
근거: 해당 없음
승인자/승인일: 해당 없음
만료 또는 재검토일: 해당 없음
```
