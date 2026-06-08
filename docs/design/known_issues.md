# 알려진 오류 / 재발 방지

> 세션 중 발견한 버그·설계 함정·작업 실수와 그 방지책. 같은 걸 두 번 겪지 않기 위해 남긴다.
> 매 세션 시작 시 이 파일을 먼저 본다(CLAUDE.md 세션 시작 루틴). 발견 즉시 "증상 → 원인 → 방지책"으로 추가.
> 런타임 freeze 패턴의 상세는 자동 메모리 `project-runtime-safety`에도 있음.

---

## 작업 프로세스

- **project.godot이 `M`으로 떠도 대개 줄바꿈(CRLF/LF) 차이뿐.**
  → `git diff project.godot`로 내용 변경 없음을 확인되면 커밋에서 제외. 습관적으로 add 하지 말 것.

- **새 `.gd` 커밋 시 `.gd.uid`도 함께 add.**
  Godot 4.x은 스크립트마다 `.uid`를 자동 생성한다. 함께 `git add` 안 하면 추적 누락.
  (2026-06-07 `VeilSight.gd.uid`가 직전 커밋에서 빠져 별도 정리 커밋 필요했음.)

- **AskUserQuestion 호출 시 `questions` 배열을 반드시 채울 것.**
  누락하면 `InputValidationError: The required parameter questions is missing`로 반복 실패.
  (2026-06-08 여러 번 빈 호출로 실패함.)

- **GDScript: untyped Array/Dictionary 인덱싱 시 명시 타입 선언.** `var x := arr[i]` 대신 `var x: Dictionary = arr[i]`.
  `Array[T]`에 untyped Array(사전 리터럴 값, `Dictionary.get` 결과) 직접 대입 금지(런타임 에러).

---

## 게임 설계 함정

- **연출 시스템 ↔ 맵 형태 정합.**
  마커/위협 표시 기반 연출은 잡몹이 있는 맵에서만 의미가 있다. ARENA/보스 맵(단일 보스)에선 마킹할
  대상이 없어 무의미 → 시야 역전 같은 비트는 잡몹 맵에서 실연해야 한다.
  (2026-06-08: 스토리 ACT3 시야 역전이 보스전(lab, ARENA)에서 발동해 마커 degradation이 안 보였음.
  → stage2(ward/sewers)부터 시작하도록 변경.)

- **서사 HUD엔 "작가성"이 필요.**
  "VEIL이 본다" 같은 서사 시스템을 순수 기능 표시(기하학 마커)로만 만들면 플레이어에겐 "레이더"로 읽힌다.
  누가/왜 보여주는지 — 말걸기·고유색·등장 연출·화면효과 — 가 있어야 서사로 읽힌다.
  (2026-06-08: VeilSight 마커가 레이더로 읽힘 → 페이드인·말걸기·테두리 시안/시야 축소 화면효과 추가.)

- **스킬 가치는 맵이 받쳐줘야 한다.**
  회피/기동 스킬(글라이드)은 그것을 강제하는 지형(고지대·갭·긴 낙하) 없이는 안 쓰인다. 저격병이 평지
  한가운데 서 있으면 회피 스킬은 영영 무의미 → 스킬 효과 변경만으론 부족하고 맵 디자인이 함께 가야 한다.
  (2026-06-08: 글라이드를 T1부터 매력적으로 재설계해도 맵이 안 받쳐 안 쓰임. "글라이드 유리한 맵" 백로그.)

- **AoE 몰살 주의.**
  폭발물 등 광역기가 반경 내 전체를 치면 뭉친 적이 한 방에 몰살된다 → 최대 타격 수 또는 거리 감쇠를 고려.
  (2026-06-08: 감시탑 발판에서 폭발 한 번에 전멸 → 거리순 최대 3체로 제한.)

- **"라벨 ≠ 실제 공식" 함정 — 점수식과 표시 문구를 같이 검증.**
  추천 점수식이 표시 라벨과 다른 의미면 플레이어가 혼란. VEIL "위험 대비 보상 균형"이 실제론
  `reward*2 - risk`라 보상에 2배 가중 → 위험2보상2(점수2) < 위험3보상3(점수3)로 고위험을 밀었음.
  → 진짜 균형은 순가치 `reward - risk` 최대 + 동점 시 저위험. 점수식 만들 때 양 끝 케이스를 손으로
  넣어 라벨과 일치하는지 확인할 것. (2026-06-08 사용자 지적으로 발견 → 실력 기반으로 재설계.)

- **적응형 지표 추적 경계는 "재시도에도 안 깨지는 지점"에 둘 것.**
  스테이지 실력 추적의 baseline을 Stage._ready에 두면 죽음 재시도마다 리셋돼 고전 신호가 사라진다.
  → `record_route_choice`(스테이지 진입 직전, 재시도엔 재호출 안 됨)를 baseline, `on_stage_clear`를
  마감으로 잡으면 재시도의 피격·죽음이 한 창에 누적돼 자연히 "고전"으로 읽힌다. (2026-06-08 VEIL 적응형.)

- **AskUserQuestion `questions` 누락이 또 재발(2026-06-08 세션 4).** 빈 호출로 1회 실패 — 위 작업
  프로세스 항목 재확인. 호출 직전 `questions` 배열 채웠는지 항상 점검.

- **기본 입력 보강은 `load_settings()` *뒤에* 둘 것.**
  project.godot 기본 attack에 마우스 좌클릭이 없어 Main이 런타임에 `_ensure_mouse_event`로 추가한다.
  이 보강을 load_settings보다 *먼저* 호출하면, load_settings가 `action_erase_events`+재로드로 attack을
  cfg값(마우스 빠진 상태)으로 덮어써 좌클릭 사격이 사라진다. 게다가 한 번 마우스 빠진 cfg가 저장되면
  계속 전파됨(자기 영속). → 순서: load_settings → _bind_default_mouse_inputs/_bind_wasd_to_ui.
  좌=사격/우=스킬은 핵심 조작이라 cfg가 잃어도 항상 보강되게. (2026-06-08 사용자 보고 → fix 27852ae.)

---

## 렌더링 / 레이아웃

- **CanvasLayer의 Control 자식은 anchor로 화면 크기를 못 받는다.**
  CanvasLayer는 Control이 아니라 자식에게 rect를 전파하지 않는다. 그 아래 Control에 `PRESET_FULL_RECT`를
  걸어도 self.size=0이 된다. full-rect로 깐 손자 노드(예: 비네트 TextureRect, STRETCH_SCALE)는 늘어날
  대상이 없어 **텍스처 native 크기로 좌상단(0,0)에만** 그려진다.
  → CanvasLayer 자식 Control은 `size = get_viewport_rect().size`로 직접 맞추고 `get_viewport().size_changed`에
  연결해 해상도 변경에도 갱신. (2026-06-08: VeilSight 시안 테두리 비네트가 좌상단 320×200 blob으로만
  떴던 버그 — 이 패턴이 원인. `VeilSight._fit_to_viewport`로 해결.)

- **"해상도 흐릿함"은 엔진 stretch가 아니라 에디터 임베드/OS 스케일링.**
  `window/stretch/mode="canvas_items"`는 Godot 4에서 **창의 네이티브 해상도로 2D를 렌더**한다(폰트도
  그 해상도로 래스터 → 선명). standalone `--windowed --resolution 1920x1080` 렌더의 뷰포트 텍스처가
  1886×1061(=창 크기)로 나오고 한글 텍스트가 또렷함을 확인. 따라서 "작은 화면을 디지털 줌한 듯 흐릿"은
  ① 에디터가 게임을 **임베드/플로팅 창**으로 띄워 스케일하거나 ② **Windows HiDPI(125/150%) OS 업스케일**
  때문. → 진짜 환경은 **내보낸 빌드**로 확인. `allow_hidpi`는 4.x 기본 true라 명시 불필요.
  체감 선명도는 **텍스트 검정 아웃라인**(outline_size)으로 더 끌어올림(faux-bold보다 가볍고 또렷).
  (2026-06-08 플레이테스트.)

## 런타임 (상세: 메모리 project-runtime-safety)

- **paused / Engine.time_scale carry로 인한 freeze.**
  `get_tree().paused`는 SceneTree 전역이라 scene 전환에 carry된다. overlay/도전방 등에서 paused 해제
  누락 시 다음 scene이 freeze. 새 overlay/scene 추가 시 paused 해제 안전판을 같은 패턴으로 둘 것.
