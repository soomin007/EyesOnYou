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

---

## 런타임 (상세: 메모리 project-runtime-safety)

- **paused / Engine.time_scale carry로 인한 freeze.**
  `get_tree().paused`는 SceneTree 전역이라 scene 전환에 carry된다. overlay/도전방 등에서 paused 해제
  누락 시 다음 scene이 freeze. 새 overlay/scene 추가 시 paused 해제 안전판을 같은 패턴으로 둘 것.
