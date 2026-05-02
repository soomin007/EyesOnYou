# Eyes on You

> **"AI 파트너 VEIL과 함께 5개 임무를 해치우는 횡스크롤 로그라이트. 마지막에 VEIL이 누구였는지가 드러난다."**

근미래 민간 보안기업의 현장 요원이 되어, 상황실 AI 파트너 **VEIL**의 조언을 들으며(혹은 무시하며) 5개의 짧은 횡스크롤 스테이지를 클리어한다. 누적된 선택(VEIL 조언 수용 여부 × 전투/우회 비율)이 4종 결말 중 하나를 결정한다.

- **엔진**: Godot 4.6 (GL Compatibility, physics interpolation 활성)
- **장르**: 횡스크롤 액션 어드벤처 + 로그라이트
- **플레이 시간**: 8~15분 / 1회
- **배포 목표**: itch.io Web Export (QR 접근)
- **외부 의존성**: 없음 (API/서버/계정 없음, 모든 텍스트 하드코딩)

---

## 게임 루프

```
[타이틀]
   ↓ (첫 플레이)        ↓ (튜토리얼 완료 후)
[튜토리얼]              [브리핑]
                         ↓
                    [루트 선택] ─→ [횡스크롤 스테이지] ─→ [레벨업(스킬 3중 1)]
                         ↑              ↓ 클리어    ↓ 사망
                         └─ 다음 루트 ─┘     [데스 브리핑] → 재시작
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
| W / Space | 점프 (베이스라인 이중 점프) |
| S / ↓ | 플랫폼 위에서 아래로 내려가기 |
| 마우스 좌클릭 / J | 사격 (원거리 베이스) |
| Shift / K | 대시 (베이스라인) |
| 마우스 우클릭 / Q | 액티브 스킬 (폭발물 등, 스킬 획득 시) |
| ESC | 일시정지 / 메뉴 |
| Space / Enter | UI 진행·스킵 |

키바인드는 설정 메뉴에서 변경 가능 (마우스 버튼 포함).

---

## 6개 맵 + 진행 흐름 (Dead Cells 스타일)

각 맵마다 등장 가능 스테이지가 다름.

| 루트 | id | available_stages | risk | reward | 태그 |
|---|---|---|---|---|---|
| 외곽 진입로 | route_back_alley | 0~1 | 1 | 1 | 우회, 어두운_환경 |
| 외벽 옥상 | route_rooftops | 0~2 | 1 | 2 | 원거리, 노출, 이동 |
| 지하 배수로 | route_sewers | 1~3 | 2 | 3 | 근접전, 함정, 어두운_환경 |
| 지하철 연결로 | route_subway | 2~4 | 2 | 2 | 근접전, 함정 |
| 핵심부 | route_lab | 3~4 | 3 | 3 | 전투, 드론, 밝은_환경 |
| ??? | route_hidden | 4 | 2 | 3 | 우회, 정보 (hidden=true) |

- **Risk**: 1=적 수 ×0.8 / 2=×1.1 / 3=×1.5 + 적 행동 강화
- **Reward**: 클리어 시 보너스 XP (1=+1, 2=+2, 3=+3)
- 함정 태그(지하 배수로/지하철 연결로)에는 가시 자동 배치
- 각 맵마다 다른 플랫폼 layout + 환경 효과
- ??? 루트는 Stage 4 풀에 무작위 등장, hidden=true (VEIL 추천에서 제외) — 메타 서사 + trust +1 보너스

---

## 적 (5종) — 도감 자동 트리거

첫 조우 시 도감 카드가 떠서 행동/공략을 알려줌.

| 적 | 핵심 행동 | 공략 |
|---|---|---|
| 정찰병 (Patrol) | 좌우 순찰, 근접 시 텔레그래프 후 돌진 | 깜빡일 때 옆으로 회피 → 회복 중 사격 |
| 저격수 (Sniper) | 정지, 조준선 노출 후 발사 | 플랫폼/벽으로 시야 차단 시 발사 취소 |
| 공습 드론 (Strike Drone) | 머리 위 호버링 후 폭탄 투하 | 그림자 들어오면 옆 회피, 호버 중 사격 |
| 자폭병 (Bomber) | 순찰 → 감지 시 추격 → 90px 안에서 점멸 → 광역 폭발 | 멀리서 정리 / 점멸 시작하면 즉시 거리 벌리기 (HP 1) |
| 방패병 (Shield) | 정면 32px 무효, 같은 높이대 안에서 플레이어 방향 고정 | 정면 사격 막힘 → dash/점프로 측면 잡고 사격 (HP 3) |

---

## 프로젝트 구조

```
EoY/
├── project.godot                Godot 4.6 프로젝트 설정 (AutoLoad: GameState)
├── PRD.md                       제품 요구사항 (의사결정·우선순위·성공 기준)
├── EYES_ON_YOU_v2_spec.md       구현 사양 (씬 구조·대사 풀·결말 연출)
├── STORY.md                    스토리 캐논 + 게임 텍스트 인벤토리 (단일 진실)
├── DESIGN_growth_system.md     성장 시스템 확정 설계 + 구현 계획 (Phase B/C)
├── icon.svg
├── assets/                      (배경 이미지·폰트 — P2)
├── scenes/
│   ├── main.tscn                부트 — Settings 로드 후 Title 전환
│   ├── title.tscn
│   ├── tutorial.tscn            5단계 튜토리얼 (이동→점프→사격→레벨업→대시)
│   ├── briefing.tscn            VEIL 첫 교신
│   ├── route_map.tscn           루트 선택 (Slay the Spire 스타일)
│   ├── stage.tscn               횡스크롤 스테이지 (절차적 빌드)
│   ├── death.tscn               VEIL 데스 브리핑
│   ├── ending.tscn              4종 결말 분기
│   └── settings.tscn            키바인드 / 사운드 / 디버그(연습장)
├── scripts/
│   ├── GameState.gd             AutoLoad — 진행도/점수/스킬/루트/도감 영속
│   ├── SceneRouter.gd           씬 전환 헬퍼
│   ├── RouteData.gd             루트 풀 (id/risk/reward/tags/available_stages)
│   ├── VeilDialogue.gd          4상황별 대사 풀
│   ├── SkillSystem.gd           8종 스킬 풀 + 레벨업 3중 1 (베이스라인 dash/double_jump)
│   ├── EndingResolver.gd        두 축 점수 → 결말 결정
│   ├── Player.gd                이동/점프/대시/사격/플랫폼 드롭/액티브 스킬
│   ├── Enemy.gd                 5종 — 정찰병/저격수/드론/자폭병/방패병
│   ├── Bullet.gd                플레이어 사격
│   ├── Bomb.gd                  드론 투하 폭탄 (광역)
│   ├── ExpOrb.gd                경험치 오브
│   ├── CharacterArt.gd          벡터 캐릭터 빌더 (코드 생성)
│   ├── BestiaryData.gd          적 도감 텍스트 데이터
│   ├── BestiaryOverlay.gd       첫 조우 시 도감 카드
│   ├── ArchiveOverlay.gd        ??? 맵 단말기 자막 시퀀스 (타자기 + 발화자 색)
│   ├── LevelUpOverlay.gd        스킬 3중 1 카드
│   ├── PlaygroundOverlay.gd     디버그 연습장 패널 (HUD에 토글)
│   ├── PauseHelper.gd           ESC 일시정지 메뉴
│   ├── Tutorial.gd / TutorialDummy.gd
│   ├── Settings.gd              키바인드 + 디버그 탭 (연습장 진입)
│   └── Main.gd / Title.gd / Briefing.gd / RouteMap.gd / Stage.gd / Death.gd / Ending.gd
└── session_logs/                일자별 작업 로그
```

### 주요 설계 결정

- **씬 절차적 빌드**: `.tscn`은 노드 트리 최소만 담고, 플랫폼·적·플레이어·HUD는 `Stage.gd._ready()`에서 코드로 생성. 루트 id별 layout, 태그별 가시, route 별 환경 효과가 동적으로 적용된다.
- **레벨업은 별도 씬이 아닌 오버레이**: `CanvasLayer`로 표시해 스테이지 상태를 보존. 스테이지 클리어 시 보너스 XP로 레벨업해도 다음 scene 전환 전에 띄움.
- **Physics interpolation**: 60Hz 물리 + 고주사율 모니터에서 떨림 없도록 활성화.
- **VEIL은 가끔 틀린다**: 조언을 늘 따르는 게 정답이 되지 않도록 의도적으로 빗나간 조언을 풀에 넣음. `trust`와 `aggression`이 직교하도록 설계됨.
- **도감 트리거**: 적 첫 조우 시 자동으로 카드 표시. seen_enemies는 settings.cfg에 영속화돼서 다음 런에선 안 뜸.
- **디버그 연습장**: 설정 메뉴 → 디버그 탭 → 연습장 진입. HUD에 토글 패널이 떠서 그 자리에서 stage/route/risk/reward를 바꾸고 즉시 reload.

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
- ✅ **P1 (VEIL 연출)** — VeilDialogue 풀, 4상황 발화, EndingResolver, 4종 결말 연출
- ✅ **P2-α (적/난이도 시스템 보강)**
  - 적 3종 행동 보강 (정찰병 돌진, 저격수 LOS, 드론 폭탄)
  - 도감 시스템 (첫 조우 카드, 영속화)
  - 6개 맵 정체성 (루트별 layout + 환경 효과)
  - 가시 기믹 (함정 태그 자동 배치)
  - Stage 분배 (Dead Cells 스타일 진행)
  - Risk/Reward 게임플레이 반영
- ✅ **디버그 도구** — 연습장 모드 (스테이지/루트/난이도 즉시 전환)
- ✅ **튜토리얼** — 5단계 점진 학습
- ✅ **P2-β (스토리/콘텐츠)** — SILO-7 컨텍스트 6개 맵, ACT별 VEIL 대사 풀, ??? 단말기 시퀀스, 결말 4종 갱신
- ✅ **P2-γ (적 확장)** — 자폭병/방패병 추가 (총 5종), 기본 HP 3 정책, 적 수 미세 상향
- 📋 **P2-δ (성장 시스템 + 7스테이지 확장)** — 설계 확정, 구현 진입 직전. [`DESIGN_growth_system.md`](DESIGN_growth_system.md) 참조
- 🚧 **P3 (마무리)** — 한글 폰트 번들, 배경 이미지, SFX, Web Export, itch.io 업로드

상세 우선순위는 [`PRD.md`](PRD.md) §6, 구현 디테일은 [`EYES_ON_YOU_v2_spec.md`](EYES_ON_YOU_v2_spec.md), 스토리 캐논과 인게임 텍스트는 [`STORY.md`](STORY.md) 참조.

---

## 라이선스

미정 (개인 프로젝트, 부스/전시 데모용).
