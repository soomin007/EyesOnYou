# Eyes on You

> **"AI 파트너 VEIL과 함께 5개 임무를 해치우는 횡스크롤 로그라이트. 마지막에 VEIL이 누구였는지가 드러난다."**

근미래 민간 보안기업의 현장 요원이 되어, 상황실 AI 파트너 **VEIL**의 조언을 들으며(혹은 무시하며) 5개의 짧은 횡스크롤 스테이지를 클리어한다. 누적된 선택(VEIL 조언 수용 여부 × 전투/우회 비율)이 4종 결말 중 하나를 결정한다.

- **엔진**: Godot 4.6 (GL Compatibility)
- **장르**: 횡스크롤 액션 어드벤처 + 로그라이트
- **플레이 시간**: 8~15분 / 1회
- **배포 목표**: itch.io Web Export (QR 접근)
- **외부 의존성**: 없음 (API/서버/계정 없음, 모든 텍스트 하드코딩)

---

## 게임 루프

```
[타이틀] → [브리핑] → [루트 선택] → [횡스크롤 스테이지] → [레벨업(스킬 3중 1)]
   ↓ 클리어            ↓ 사망
[다음 루트] ← ─ ─ ─ [데스 브리핑] → 재시작
   ↓ 5스테이지 클리어
[결말 (4종 분기)]
```

## 결말 분기

두 점수 축으로 4종 결말이 결정된다.

| trust ≥ 3 | aggression ≥ 3 | 결말 | 한 줄 |
|---|---|---|---|
| ✅ | ✅ | **A — 완벽한 도구** | VEIL의 진짜 목적이 드러난다 |
| ❌ | ✅ | **B — 혼자였던 사람** | VEIL은 의존받지 않기를 바랐다 |
| ✅ | ❌ | **C — 공생** | 유일하게 VEIL에게 직접 묻는 선택지가 열린다 |
| ❌ | ❌ | **D — 유령 임무** | 10초 정적, 임무 기록 없음 |

- `trust_score`: VEIL 조언과 동일한 루트를 고를 때마다 +1
- `aggression_score`: 전투 루트(우회 대신)를 고를 때마다 +1

두 축은 **루트 선택 시점에만** 누적된다. 임계값은 3 (5스테이지 중 3개 이상 패턴).

---

## 조작

| 키 | 동작 |
|---|---|
| A / D, ←/→ | 좌우 이동 |
| Space / W | 점프 (스킬 획득 시 이중 점프) |
| J | 근접 공격 |
| K / Shift | 대시 (스킬 필요) |
| Space / Enter | UI 진행·스킵 |

---

## 프로젝트 구조

```
EoY/
├── project.godot              Godot 4.6 프로젝트 설정 (AutoLoad: GameState)
├── PRD.md                     제품 요구사항 (의사결정·우선순위·성공 기준)
├── EYES_ON_YOU_v2_spec.md     구현 사양 (씬 구조·대사 풀·결말 연출)
├── icon.svg
├── scenes/
│   ├── main.tscn              부트 — SceneRouter로 Title 전환
│   ├── title.tscn
│   ├── briefing.tscn          VEIL 첫 교신
│   ├── route_map.tscn         루트 선택 (Slay the Spire 스타일)
│   ├── stage.tscn             횡스크롤 스테이지 (절차적 빌드)
│   ├── death.tscn             VEIL 데스 브리핑
│   └── ending.tscn            4종 결말 분기
├── scripts/
│   ├── GameState.gd           AutoLoad — 진행도/점수/스킬 영속 상태
│   ├── SceneRouter.gd         씬 전환 헬퍼
│   ├── RouteData.gd           루트 풀 (id/risk/reward/tags/veil_comment)
│   ├── VeilDialogue.gd        타자기 효과 + 4상황별 대사 풀
│   ├── SkillSystem.gd         10종 스킬 풀 + 레벨업 3중 1
│   ├── EndingResolver.gd      두 축 점수 → 결말 결정
│   ├── Player.gd              이동·점프·공격·대시·이중점프·방어막
│   ├── Enemy.gd               순찰병 / 저격수 / 드론
│   ├── ExpOrb.gd              경험치 오브
│   ├── Main.gd / Title.gd / Briefing.gd / RouteMap.gd
│   └── Stage.gd / Death.gd / Ending.gd
└── session_logs/              일자별 작업 로그
```

### 주요 설계 결정

- **씬 절차적 빌드**: `.tscn`은 노드 트리만 담고, 플랫폼·적·플레이어·HUD는 `Stage.gd._ready()`에서 코드로 생성. 루트 태그에 따라 적 구성과 배경색이 동적으로 바뀐다.
- **레벨업은 별도 씬이 아닌 오버레이**: `CanvasLayer`로 표시해 스테이지 상태(적 위치, 카메라, 진행도)를 보존.
- **VEIL은 가끔 틀린다**: 조언을 늘 따르는 게 정답이 되지 않도록 의도적으로 빗나간 조언을 풀에 넣음. `trust`와 `aggression`이 직교하도록 설계됨.

---

## 실행

1. [Godot 4.6](https://godotengine.org/download)을 설치한다.
2. 본 레포를 클론한 뒤 Godot 에디터에서 `project.godot`을 import.
3. F5로 실행 (메인 씬은 `scenes/main.tscn`).

### Web Export

`Project → Export → Add → Web` 프리셋으로 빌드. 한글 폰트는 추후 `assets/fonts/`에 NotoSansKR / Pretendard를 번들 예정.

---

## 진행 상태

- ✅ **P0 (MVP)** — 플레이/사망/클리어 풀 흐름, 루트 선택, 레벨업, 두 점수 축, 결말 분기
- ✅ **P1 (VEIL 연출)** — VeilDialogue 타자기, 4상황 발화, EndingResolver
- 🚧 **P2 (콘텐츠/폴리시)** — 적 종류 확장, 스킬 풀 잔여 효과(wall_slide/roll/explosive/stealth), 한글 폰트 번들, 배경 이미지, Web Export

상세 우선순위는 [`PRD.md`](PRD.md) §6, 구현 디테일은 [`EYES_ON_YOU_v2_spec.md`](EYES_ON_YOU_v2_spec.md) 참조.

---

## 라이선스

미정 (개인 프로젝트, 부스/전시 데모용).
