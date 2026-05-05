# Session Log Archive

이전 세션 로그 요약. 시간이 지나 안정화된 결정만 남기고 디버깅 노트와 일과성 변경은 제거.

---

## 2026-04-28 — 프로젝트 초기 설정

`EYES_ON_YOU_v2_spec.md` 기반으로 PRD 작성 + Godot 4.6 프로젝트 뼈대 구축.

### 굳어진 결정
- **PRD vs Spec 분리**: 제품 의사결정은 PRD 우선, 구현 디테일은 spec 우선
- **씬 절차적 빌드**: `.tscn`은 노드 트리 + 스크립트만, 게임 객체는 `_ready()`에서 코드로 생성. 루트 태그에 따라 적 구성/배경색이 동적으로 바뀌는 구조에 유리
- **레벨업은 별도 씬이 아닌 오버레이**: `CanvasLayer`로 표시해 스테이지 상태(적 위치, 카메라, 진행도) 보존
- **자식 노드 부착 순서**: `add_child(parent)` → `parent.add_child(visual)` 시 `@onready`가 visual을 못 찾음. 자식 모두 부착 후 트리에 추가하는 패턴으로 통일
- **`Array[T]` 회피**: Dictionary 안의 배열 리터럴은 항상 untyped. 일관되게 `Array`로 선언

### 만들어진 것
- `PRD.md`, `EYES_ON_YOU_v2_spec.md`, `project.godot`
- Title→Briefing→RouteMap→Stage→Death/Ending 풀 흐름
- 14개 스크립트 (GameState, RouteData, VeilDialogue, SkillSystem, EndingResolver, SceneRouter, Player, Enemy, ExpOrb, Main, Title, Briefing, RouteMap, Stage, Death, Ending)

---

## 2026-04-30 — GitHub push + 스프라이트/튜토리얼/설정 1차

### 굳어진 결정
- **Tutorial은 별도 씬, 일회성**: `GameState.tutorial_done`은 `reset()`에서 보존되며 `user://settings.cfg`에 영속화
- **Tutorial에서 dash/double_jump 스킬 임시 부여**: 표지판이 약속한 동작이 실제로 작동하도록. 완료 시 `reset()`으로 정리
- **PauseHelper는 RefCounted 정적 헬퍼**: Stage/Tutorial 두 곳에서 동일 오버레이 사용. 콜백은 `Callable`로 받아 결합도 낮춤
- **Settings는 단일 씬 재사용**: Title/Pause 양쪽에서 `instantiate()`로 자식 추가
- **`pause` 액션을 키바인딩 변경 대상에 포함**: 사용자가 ESC 외 다른 키로 바꿀 수 있음. 단 캡처 중 ESC는 캡처 취소
- **세션 도중 발견된 Web Export 영속화**: `user://` 경로는 브라우저 localStorage에 매핑됨

### 폐기된 접근 (다음 세션에서 갈아엎음)
- ❌ PNG 스프라이트 + `assets/shaders/remove_white.gdshader` (흰배경 알파 마스킹)
- ❌ `Sprite2D + ShaderMaterial` 동적 생성, `PlaceholderTexture2D` fallback
- ❌ scale 0.42 (PNG가 작아서 키워야 했음)

이유: 콜리전 박스(28×56 / 28×40)와 시각이 어긋나 히트박스 vs 시각 혼란. 셰이더로 흰배경 잘라도 외곽선 거침. 정적 그래픽으로는 단순 벡터가 깨끗함. → 다음 세션에 `CharacterArt.gd` 폴리곤 합성 방식으로 교체.

### 만들어진 것
- `README.md`, `.gitignore` (Godot 4 표준)
- GitHub `soomin007/EyesOnYou` 레포 초기 push
- `Tutorial.gd` + `tutorial.tscn` + `TutorialDummy.gd`
- `Settings.gd` + `settings.tscn` (TabContainer 2탭, ConfigFile 영속화)
- `PauseHelper.gd` (CanvasLayer 오버레이 빌더)
- `GameState`에 `tutorial_done`, `master_volume`, `sfx_volume`, `load_settings()`, `save_settings()`
- `pause` 액션(ESC) 추가

---

## 2026-05-01 — 벡터 캐릭터 + 5단 튜토리얼

### 굳어진 결정
- **벡터 합성 vs PNG**: PNG는 콜리전 박스와 시각이 어긋나고 셰이더로 흰배경 잘라도 외곽선이 거침. `CharacterArt.gd` (Polygon2D 합성, RefCounted + static) 채택 — 콜리전 안쪽에서만 그림. 외곽선 없는 단순 톤이 PRD §9 "코드 생성 미니멀 벡터" 방침과 일치.
- **레벨업 오버레이 추출**: 인라인 → `LevelUpOverlay.show()`. Stage/Tutorial 둘 다 같은 UI 보장.
- **레벨업 더미 lazy 스폰**: _ready에서 미리 만들면 사거리 안에서 보이지 않게 처치되는 사고 → `_advance_to(LEVELUP)` 시점에 spawn.
- **Stage 플랫폼은 단일점프 도달 가능**: 이중점프 없이도 모든 레이아웃 클리어 가능. 이중점프는 더 빠른 루트로 보상.
- **PRESET_FULL_RECT + CenterContainer**: PRESET_CENTER 단독은 좌상단 잘림 버그 → CenterContainer로 통일.

---

## 2026-05-02 — 6맵 SILO-7 + Phase B 시스템 + 적 2종 추가

### 굳어진 결정
- **6개 맵 ↔ SILO-7 매핑**: 도시 다양한 장소가 아니라 SILO-7 안의 진입 경로로 재정의 (외곽→옥상→지하→지하철→핵심부→격리 서버실). FULL_STORY 단일 임무 컨셉(OPERATION PALIMPSEST)과 정합.
- **잠긴 문 vs ??? 루트 분리**: 잠긴 문은 시각적 복선만(콜리전 없음). ??? 진입은 루트 선택에서 별개로.
- **VEIL-1/2 표시**: 화면 하단 자막 + 색 구분 (VEIL-1 빨강, VEIL-2 노랑, VEIL 청록).
- **HP 5→3**: 5는 사실상 무한이라 위협 없음. 3으로 줄여 위기감.
- **shield = 죽기 직전 부활**: "2뎀 이상을 1로" 룰은 적이 대부분 1뎀이라 사실상 무의미 → 라이프라인 형태가 직관적.
- **wall_slide → 공중 글라이드**: 게임에 가운데 벽이 없어 "벽타기" 의미 없음. 효과만 변경하고 id 유지.
- **regen on_stage_clear heal 제거**: 매 stage 풀 회복이 의도된 동작이라 중복.
- **자폭병/방패병 추가** (적 5종): take_damage 시그니처에 from_x 정보 전달, shield는 정면 32px 안에서 막힘 + `_show_block_spark` 노란 라인.

---

## 2026-05-03 — 세계 템플릿 4종 + 보스 SENTINEL + 도전방 + 이스터에그

### 굳어진 결정
- **세계 템플릿 4종**: HORIZONTAL / VERTICAL_UP / VERTICAL_DOWN / ARENA. 각 맵이 컨셉에 맞는 템플릿 선택.
- **STAGE_LENGTH/GROUND_Y/PLAYER_START를 var로**: const → var. MapData에서 덮어쓸 수 있게.
- **FIXED 카메라 zoom**: ARENA에서 player follow 대신 고정 + zoom = min(1280/world.x, 720/world.y)로 월드가 viewport에 맞게 자동.
- **ENEMY_CLEAR goal_type**: ARENA에서 spawn 후 group 카운트, 0 도달 시 클리어.
- **vertical 발판 gap 100~170**: 이중점프 한계 ~190px이라 180+는 도달 불가.
- **저격수 발판 mid step**: 지면→step→mid 단계화. step 없으면 폭발물로만 잡을 수 있음.
- **GitHub Pages는 Actions 방식**: 별도 브랜치 안 만들고 Actions API로 직접 배포.
- **보스 별도 스크립트**: `BossSentinel.gd` 분리 — group "enemy" 등록으로 ARENA enemy_clear에 자연 통합.
- **lab 일반 적 제거**: DESIGN §2.10 "보스 챔버" 정체성 강조.
- **이스터에그 in-place 시퀀스**: 별도 방 append 대신 페이드 오버레이 + ArchiveOverlay 재생.
- **블랙아웃 시야**: 정확한 원형 cutout 대신 풀스크린 dim 0.55 + 비네트.

---

## 2026-05-04 — 적 가장자리 감지 + 보스 페이즈 무적 + Pretendard + 이스터에그 풀스크린 문서

### 굳어진 결정
- **적 가장자리 감지는 raycast**: spawn 시 발판 메타 부여 대신 동적 raycast — 모든 맵 적용 가능 + 발판 변화에도 robust.
- **수직 맵 gap 80 표준**: 1단 점프 한계 104px이라 80은 여유, 분기 도약 140은 1단으로 절대 안 감.
- **patrol 발판 폭 240+**: 너무 좁으면 ping-pong하다 텔레그래프 거리 안 나옴.
- **보스 페이즈 무적 1.2s**: 사격 spam 시 freeze 종료 즉시 데미지 들어가 못 인지 → 1.2s + take_damage 무시로 강제 인지.
- **Pretendard 선택**: NotoSansKR ~16MB 너무 큼. Pretendard subset 1.5MB가 부스 환경 로딩에 적합. OFL 라이선스.
- **show-don't-tell 원칙 채택**: 모든 텍스트/연출 의사결정의 상위 기준. `docs/design/show_dont_tell.md` 작성.
- **보스 페이즈 알림 = VEIL**: 큰 영문 배너 대신 VEIL 한 줄 — 캐릭터·메카닉 통합.
- **도감은 "관찰 메모"**: blurb 한 줄 + 키워드 색 강조. 공략 글 제거.
- **자폭 dual-zone**: 단일 반경 2200은 회피 불가 → inner(풀뎀)/outer(1뎀) 거리 보상.
- **미사일 약한 유도**: 1.4s 유도 후 직진. TURN_RATE 80도/s로 직각 회피 가능, 수직 정지엔 위협.
- **barrier vs shield 분리**: 능동(타이밍) / 보험. 별 라인 추가, shield 라인은 유지.
- **풀스크린 문서 vs 패널**: 단말기는 패널, 이스터에그(회의록)는 풀스크린 문서로 분리.
