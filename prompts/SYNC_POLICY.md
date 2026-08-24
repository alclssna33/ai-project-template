# 공통 정책 동기화 프롬프트

```text
현재 프로젝트의 AI 개발 정책을 중앙 템플릿과 비교하고 필요하면 동기화 PR을 만들어라.

중앙 원본: alclssna33/ai-project-template의 최신 main
현재 버전: 현재 저장소의 POLICY_VERSION
중앙 버전: 중앙 저장소의 POLICY_VERSION

1. 양쪽 AGENTS.md, AI_DEVELOPMENT_POLICY.md, CLAUDE.md, .claude/settings.json,
   PR 템플릿과 정책 검사 스크립트를 읽어라.
2. 중앙 버전이 같거나 낮으면 파일을 수정하지 말고 비교 결과만 보고하라.
3. 중앙 버전이 높으면 전체 정책 diff와 현재 프로젝트 예외에 미치는 영향을 분석하라.
4. 현재 프로젝트 AGENTS.md의 프로젝트 식별 정보, 명령, 경로, 예외는 보존하라.
5. 공통 정책·검사 파일만 필요한 범위로 갱신하라.
6. 고유 정책 동기화 브랜치에서 작업하고 무결성 검사를 실행하라.
7. 정책 변경은 일반 문서 PR로 취급하지 말고 Draft PR에 위험을 기록하라.
8. 자동 merge하지 마라.
```
