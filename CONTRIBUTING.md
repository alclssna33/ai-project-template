# 기여 가이드

이 저장소의 전체 개발·Git 정책은 `AGENTS.md`와 `docs/AI_DEVELOPMENT_POLICY.md`를 기준으로 합니다.

## 기본 흐름

1. 최신 기본 브랜치에서 고유 feature branch를 만듭니다.
2. 병렬 작업이면 Issue 또는 Draft PR에 작업 범위와 예정 파일을 먼저 기록합니다.
3. 필요한 검증을 실행하고 전체 diff를 확인합니다.
4. feature branch를 push하고 Pull Request를 만듭니다.
5. 검토와 checks가 완료된 뒤 squash merge합니다.

## 금지 사항

- 기본 브랜치 직접 수정·push
- force push
- 다른 작성자의 변경을 임의로 삭제·stash·restore
- secret·운영 데이터 commit
- 테스트나 보안 검사를 우회해 성공으로 보고

## Pull Request

PR 템플릿의 항목을 채우고 미실행 검증, 위험, 의존 PR을 명시합니다.
