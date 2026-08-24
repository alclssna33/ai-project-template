# 신규 프로젝트 초기화 프롬프트

아래 문장을 Codex, Claude Code 또는 ChatGPT GitHub 작업에 그대로 사용한다.

```text
이 저장소는 alclssna33/ai-project-template에서 생성된 신규 프로젝트다.
애플리케이션 기능 개발은 시작하지 말고 프로젝트 초기화만 진행하라.

1. 최신 기본 브랜치의 AGENTS.md와 공통 정책을 읽어라.
2. 저장소 identity, 기본 브랜치 SHA, 열린 작업, 고유 브랜치, 격리 환경을 확인하라.
3. 실제 저장소 기준으로 initialize-project.ps1 입력값을 확정하라.
4. initialize-project.ps1을 -WhatIf로 실행하고 파일이 바뀌지 않았음을 확인하라.
5. dry-run 계획이 맞을 때만 initialize-project.ps1을 -WhatIf 없이 실행하라.
6. AGENTS.md, PROJECT_GUIDE.md, README.md와 삭제된 template README를 검토하라.
7. template-placeholder 옵션 없이 check-policy.ps1과 check-policy.sh를 모두 실행하라.
8. 초기화 파일만 commit하고 Draft PR을 열어라. 기본 브랜치에 직접 push하거나 merge하지 마라.
```
