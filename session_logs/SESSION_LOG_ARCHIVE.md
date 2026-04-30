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
