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
| 환경 퍼즐(레버·발판) 현황 | [`design/puzzle_ideas.md`](design/puzzle_ideas.md) |
| 효과음 작업 목록 | [`design/sfx_list.md`](design/sfx_list.md) |
| 효과음 ElevenLabs 프롬프트 | [`design/sfx_elevenlabs_prompts.md`](design/sfx_elevenlabs_prompts.md) |
| 효과음 trim/후처리 가이드 | [`design/sfx_trim_guide.md`](design/sfx_trim_guide.md) |
| 배포·Pages 셋업 | [`../DEPLOY.md`](../DEPLOY.md) |
| 최근 작업 흐름 | [`../session_logs/`](../session_logs/) (날짜별) |

## 최근 시스템 (한눈에)

- **VeilSight 시야 마킹**: VEIL이 위협을 HUD로 짚어준다 — 화면 안은 은은한 시안 표식,
  화면 밖 새 위협은 VEIL이 *말로* 방향을 짚는다. ACT3 진입에 마커가 일제히 무너지고 일부는
  영영 꺼진다 = "시야=신뢰"의 역전을 플레이로 실연. (`scripts/VeilSight.gd`)
- **스킬-적 상성**: 적별 약점 스킬(shield→폭발물 / sniper→활강 / drone→다중사격 / bomber→사격강화).
  현재 맵에 등장하는 적 중 카운터를 아직 안 가진 스킬을 레벨업 추천·출현 가중으로 가르친다.
  단일 진실은 `SkillTreeData.MATCHUP`, 맵별 정리는 `design/world_layout.md` §2.12.
- **글라이드 라인 재설계·폭발물 너프**: 활강을 공중 제압축으로 재설계(저격 카운터),
  폭발물은 광역 답답함 해소를 위해 너프. (글라이드 특화 신규/개조 맵은 설계 협의 중 — 미확정)
- **UI 시각화(텍스트→그래픽)**: 맵 진행 노드맵(`RouteMap`), 전체 스킬 트리 오버레이(`SkillTreeOverlay`,
  라인별 스킬 아이콘), 레벨업 카드 스킬 아이콘(`SkillIcon.gd`), 오프닝 VEIL 감시 눈(`BriefingVisual.gd`)
  + 미션 목표물 아이콘(`MissionObjective.gd`). 설정에 해상도/창모드. 텍스트 검정 아웃라인으로 선명도.
- **VEIL 적응형 추천**: 최근 스테이지 피격/죽음으로 실력 판정(`GameState.competence_tier`) → 맵을
  안전/가성비/고보상으로 추천, 사유를 VEIL 대사로(`RouteData`). 시야 붕괴(degradation)는 맵 간 지속.

## 단일 진실의 원칙

- **PRD vs SPEC**: 제품 의사결정은 PRD 우선, 구현 디테일은 SPEC 우선.
- **STORY**: 모든 인게임 텍스트와 스토리 캐논의 단일 진실. 코드의 대사 풀(VeilDialogue 등)이 STORY와 어긋나면 STORY를 따른다.
- **design/world_layout**: 맵 좌표·보스·웨이브 메커닉의 단일 진실. MapData.gd / Stage.gd / BossSentinel.gd 가 이 문서를 참조해 동작.
- **design/show_dont_tell**: 모든 텍스트/연출 의사결정의 상위 기준 (글로 명시 < 체험으로 체득).

## 외부 작업자 인계 시

- 의뢰서·답변 형태(BRIEF_*/DESIGN_*)는 작업 완료 후 본 문서들로 통합·정리하고 의뢰 문서는 폐기한다.
  - 통합 후에도 설계 흐름을 남길 가치가 있으면 폐기 대신 [`archive/`](archive/)로 이동(이력 보존, 참조 금지).
- 새 디자인 문서는 `docs/design/<topic>.md`로. 파일명은 `snake_case`.
- 큰 변경은 commit 단위로 끊고 `session_logs/YYYY-MM-DD.md`에 기록.
