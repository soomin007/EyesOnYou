# Eyes on You — 문서 인덱스

외부 협업자/Claude 인계용 한 페이지 안내. 깊이 있는 내용은 각 문서 본문.

## 어디서 시작할까

| 만약... | 이 문서를 먼저 |
|---|---|
| 게임이 뭔지부터 알고 싶다 | [`../README.md`](../README.md) |
| 제품 결정·우선순위가 궁금하다 | [`../PRD.md`](../PRD.md) |
| 코드/씬 구조부터 보고 싶다 | [`SPEC.md`](SPEC.md) |
| 스토리 캐논·인게임 텍스트 | [`STORY.md`](STORY.md) |
| 스킬 트리·성장 시스템 | [`design/growth_system.md`](design/growth_system.md) |
| 맵 형태·보스·이스터에그 메커닉 | [`design/world_layout.md`](design/world_layout.md) |
| 텍스트 톤·"체험으로 체득" 원칙 | [`design/show_dont_tell.md`](design/show_dont_tell.md) |
| 배포·Pages 셋업 | [`../DEPLOY.md`](../DEPLOY.md) |
| 최근 작업 흐름 | [`../session_logs/`](../session_logs/) (날짜별) |

## 단일 진실의 원칙

- **PRD vs SPEC**: 제품 의사결정은 PRD 우선, 구현 디테일은 SPEC 우선.
- **STORY**: 모든 인게임 텍스트와 스토리 캐논의 단일 진실. 코드의 대사 풀(VeilDialogue 등)이 STORY와 어긋나면 STORY를 따른다.
- **design/world_layout**: 맵 좌표·보스·웨이브 메커닉의 단일 진실. MapData.gd / Stage.gd / BossSentinel.gd 가 이 문서를 참조해 동작.
- **design/show_dont_tell**: 모든 텍스트/연출 의사결정의 상위 기준 (글로 명시 < 체험으로 체득).

## 외부 작업자 인계 시

- 의뢰서·답변 형태(BRIEF_*/DESIGN_*)는 작업 완료 후 본 문서들로 통합·정리하고 의뢰 문서는 폐기한다.
- 새 디자인 문서는 `docs/design/<topic>.md`로. 파일명은 `snake_case`.
- 큰 변경은 commit 단위로 끊고 `session_logs/YYYY-MM-DD.md`에 기록.
