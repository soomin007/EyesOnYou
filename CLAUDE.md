# Eyes on You — 프로젝트 운영 규칙

## Git push 루틴

큰 작업 단위가 끝나면 **즉시 commit + push origin main**까지 진행한다. 사용자가 별도 지시 안 해도 자동.

- 매 세션 시작 시 `git status` + `git log --oneline -5`로 누적된 변경 확인. 있으면 우선 정리 제안
- 의미 있는 작업 단위(기능 추가, 시스템 변경, 텍스트 대량 갱신, 세션 로그 기록 등)가 끝나면 끊어서 commit
- commit 메시지: 한국어, `prefix(scope): 설명` 형식 (feat/fix/refactor/docs 등). 이모지 없음. 본문은 변경 항목 bullet
- main 직접 push (이 프로젝트는 branch/PR 흐름 안 씀)
- destructive 작업(force push, reset --hard 등)은 별도 확인

이 루틴이 안 지켜져서 한 세션에 31개 파일이 한 번에 누적된 적 있음(2026-05-02). 이후엔 작은 단위로 끊어서 자주 push.
