# 기존 프로젝트 정책 도입 프롬프트

```text
이 기존 저장소에 alclssna33/ai-project-template의 공통 AI 개발 정책을 도입하라.

1. 현재 저장소의 최신 기본 브랜치와 기존 AGENTS.md, CLAUDE.md, CONTRIBUTING.md,
   .claude 설정, PR 템플릿을 먼저 확인하라.
2. 중앙 템플릿의 최신 main에서 다음 원본을 읽어라.
   - AGENTS.md
   - docs/AI_DEVELOPMENT_POLICY.md
   - CLAUDE.md
   - .claude/settings.json
   - .github/pull_request_template.md
   - POLICY_VERSION
3. 기존 파일을 무조건 덮어쓰지 마라. 프로젝트별 규칙과 명령을 보존해 통합하라.
4. 공통 정책과 프로젝트별 설정을 분리하라.
5. 실제 코드·manifest·CI로 확인한 명령만 AGENTS.md와 PROJECT_GUIDE에 기록하라.
6. 기존 지침과 공통 정책의 충돌, 자동화 영향, 보안 위험을 먼저 보고하라.
7. 고유 도입 브랜치와 격리 환경에서 정책 파일만 변경하라.
8. 정책 무결성 검사를 실행하고 전체 diff를 검토하라.
9. Draft PR을 만들고 정책 변경 위험과 기존 규칙 보존 내역을 기록하라.
10. 기본 브랜치에 직접 push하거나 자동 merge하지 마라.
```
