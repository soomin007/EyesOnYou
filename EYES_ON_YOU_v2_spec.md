# EYES ON YOU — 구현 사양 v2 (현행화 반영)

> 본 문서는 초기 v2 구현 계획서를 베이스로 P0~P2-α 완료 시점의 실제 구현을 반영해 갱신한 사양이다.
> 외부 API 없음. 모든 텍스트와 로직은 코드 안에 완결.
> 우선순위/제품 결정은 `PRD.md`, 외부 스토리 의뢰용 컨텍스트는 `STORY_BRIEF.md` 참조.

---

## 1. 프로젝트 개요

**제목**: Eyes on You  
**장르**: 횡스크롤 액션 어드벤처 + 로그라이트  
**엔진**: Godot 4.x (GDScript)  
**배포**: Godot Web Export → itch.io (QR 코드 접근 전제)  
**외부 의존성**: 없음 (API 없음, 모든 텍스트 하드코딩)  
**그래픽**: 미니멀 벡터(코드 생성) + 일부 AI 생성 배경 이미지(별도 제공 예정)

---

## 2. 세계관

근미래. 플레이어는 민간 보안기업 소속 현장 요원.  
**VEIL**은 임무 시작 전 배정된 상황실 파트너. 침착하고 유능해 보인다.  
임무가 진행될수록 VEIL의 말과 행동에 작은 균열들이 생긴다.  
게임이 끝나면 그 균열의 의미가 드러난다.

플레이어는 VEIL에 대해 아무것도 묻지 않는다 — 게임이 그 질문을 대신한다.

---

## 3. 핵심 게임 루프

```
[타이틀]
      ↓
[임무 브리핑] — VEIL의 첫 교신
      ↓
[루트 선택] — 2~3개 분기, 리스크/리턴 표시, VEIL 한 마디
      ↓
[횡스크롤 스테이지] — 전투 + 탐험
      ↓
[레벨업] — 스킬 3개 중 1개 선택, VEIL 조언
      ↓
[스테이지 클리어 or 사망]
  클리어 → 다음 루트 선택
  사망   → VEIL 데스 브리핑 → 재시작
      ↓
[최종 스테이지 클리어]
      ↓
[결말 — 선택 이력 기반 4종 분기]
```

---

## 4. 루트 선택 시스템

### 화면 구성
슬레이 더 스파이어(Slay the Spire)처럼 분기 노드를 위에서 아래로 내려가는 맵 형태로 표시.  
각 노드는 루트 하나를 나타내며, 선택하면 해당 스테이지로 진입.

### 루트 속성 (현행)
```gdscript
{
  "id": "route_sewers",
  "name": "하수도",
  "risk": 2,                       # 1~3 (●로 표시)
  "reward": 3,                     # 1~3 (●로 표시)
  "hidden": false,                 # true면 위험도/보상 ?로 표기
  "tags": ["근접전", "어두운_환경", "함정", "전투"],
  "veil_comment": "근접전 위주에 함정이 있어요. 발 밑 조심해요.",
  "stage_color": Color(0.18, 0.22, 0.20),
  "available_stages": [1, 2, 3],   # Dead Cells 스타일 stage 분배
}
```

`map_scene`은 폐기 — 모든 stage가 `stage.tscn` 단일 씬에서 절차적으로 빌드된다 (§5 참조).

### 6개 루트 + Stage 분배
| 루트 | id | available_stages | risk | reward |
|---|---|---|---|---|
| 뒷골목 | route_back_alley | 0~1 | 1 | 1 |
| 옥상 | route_rooftops | 0~2 | 1 | 2 |
| 하수도 | route_sewers | 1~3 | 2 | 3 |
| 지하철 | route_subway | 2~4 | 2 | 2 |
| 연구실 | route_lab | 3~4 | 3 | 3 |
| ??? | route_hidden | 4 | 2 | 3 (hidden) |

흐름: 도시 외곽 → 지하 진입 → 핵심부 → 비밀.

### Risk/Reward 게임플레이 효과 (게임에 실제 반영)
| Risk | 효과 |
|---|---|
| 1 | 적 수 ×0.7 |
| 2 | 기본 |
| 3 | 적 수 ×1.4 + **적 행동 강화** (정찰병 텔레그래프 ×0.6, 저격수 사격 간격 ×0.7, 드론 폭탄 쿨다운 ×0.7) |

| Reward | 효과 |
|---|---|
| 1 | 클리어 시 +1 XP |
| 2 | 클리어 시 +2 XP |
| 3 | 클리어 시 +3 XP |

루트 선택 화면에서 risk≥3 / reward≥3 시 사전 경고 텍스트 표시.

### 선택 추적 (GameState에 기록)
- `current_route_id` — 현재 진행 중인 루트
- `current_route_tags` / `current_route_risk` / `current_route_reward` — Stage가 빌드 시 참조
- VEIL 조언을 따랐는지 여부 (`followed_veil_last_choice`) → `trust_score` 누적
- 전투/근접전 태그 선택 시 `aggression_score` 누적

---

## 5. 스테이지 (횡스크롤)

### 플레이어 (현행)
- 이동: 좌우 이동, 점프 (베이스라인 이중 점프), 대시 (베이스라인)
- 기본 공격: **원거리 사격** (Bullet — 마우스 좌클릭 / J)
- 액티브 스킬: 마우스 우클릭 / Q (`explosive` 등 스킬 획득 시)
- 플랫폼 드롭다운: S / ↓ (one-way 플랫폼 위에서 아래로 통과)
- HP: 최대 5 (하트로 표시), 피격 시 0.8초 무적
- 낙사 없음 — 좌우 wall로 막힘

베이스라인 스킬 (`STARTING_SKILLS`): `dash`, `double_jump`. 시작부터 보유.

### 적 (3종, 행동 보강 완료)

#### 정찰병 (Patrol)
좌우 순찰 (range 140px) + 근접 시 텔레그래프 후 돌진:
- ROAMING → TELEGRAPH (붉은 깜빡 0.45초) → CHARGING (0.6초, 280px/s) → RECOVERING (1초)
- 트리거: 플레이어가 dx≤260, dy≤70 안에 들어왔을 때
- 돌진 후 origin_x를 새 위치로 갱신 (이동 거리 누적)

#### 저격수 (Sniper)
정지, 사거리 520px, 사격 간격 2.6초, 조준 노출 0.7초:
- 조준 중 매 frame raycast(layer 1)로 시야 검사
- 시야 끊기면 조준선 사라지고 fire_timer 리셋 → 발사 취소

#### 공습 드론 (Strike Drone)
플레이어 머리 위(180px) 호버 추적 + 호버 조건 충족 시 폭탄 투하:
- 호버 조건: dx≤90, dy 80~240 (드론이 위에 있을 때)
- 폭탄: 중력 + 1.6초 fuse + 반경 70px 광역 폭발, 데미지 1
- 폭탄 쿨다운 2.5초

#### 도감 (Bestiary) 시스템
- 적 첫 조우 시 자동으로 도감 카드(이름/blurb/tactic) 표시
- 트리거: 플레이어와 dx≤480, dy≤280 + stage 노드 존재
- `BestiaryOverlay`가 paused 처리 + 카드 띄움
- `GameState.seen_enemies`에 영속화 (settings.cfg `flags/seen_enemies`)
- 한 번 본 적은 다음 런에서도 안 뜸

### 함정 — 가시
- "함정" 태그가 있는 루트(하수도, 지하철)에 자동 배치
- 폭 90px (1대시 = 약 130px 이내), 2~3개를 stage 구간에 분산
- 데미지 1 (Player의 invuln이 0.8초라 자연스러운 cooldown)

### 경험치 & 레벨업
- 적 처치 시 경험치 오브 드롭 (1 XP)
- 오브 자동 흡수 (플레이어 근처 220px)
- 5 XP마다 레벨업 → `LevelUpOverlay`에서 스킬 3중 1 선택
- **클리어 시 보너스 XP**: 루트의 reward 값만큼 누적. 보너스로 레벨업 시 다음 scene 가기 전에 LevelUpOverlay 띄움 (Stage._on_clear_levelup_picked)

### 맵 구성 (절차적 빌드)
모든 스테이지가 `scenes/stage.tscn` 단일 씬을 사용. `Stage.gd._ready()`에서 `current_route_id` / `current_route_tags`를 보고 빌드:

- **플랫폼 layout**: 루트별 다른 모양 (`_platform_layout_for_route`)
  - 뒷골목: 좁고 단차 큼 (140w)
  - 옥상: 솟구치는 높이차 (180w)
  - 하수도: 좁고 평탄 (160w)
  - 지하철: 평탄+낙차 (220w)
  - 연구실: 격자 정렬 (240w 일정 높이)
  - ???: RNG 시드로 무작위 형태
- **환경 효과** (`_build_route_ambience`, 콜리전 없는 시각만):
  - 뒷골목 → 가로등 빛기둥
  - 옥상 → 별 점들
  - 하수도 → 어두운 비네트 + 바닥 안개
  - 지하철 → 깜빡이는 형광등
  - 연구실 → 격자 수직선
  - ??? → 글리치 사각형
- **함정 가시**: 함정 태그면 자동 배치
- **적 스폰**: tags + stage 진행도 + risk 배율 조합

각 스테이지 길이: STAGE_LENGTH = 4400px (화면 3~4개 분량).

---

## 6. 스킬 시스템

레벨업마다 아래 풀에서 3개 무작위 제시, 1개 선택.

베이스라인: `dash`, `double_jump`는 게임 시작 시 보유 (`GameState.STARTING_SKILLS`). 따라서 이 두 스킬은 레벨업 풀에 안 뜸.

### 스킬 목록 (10종)
| ID | 이름 | 효과 | 태그 |
|----|------|------|------|
| dash | 대시 | 짧은 무적 이동 (베이스라인) | 이동 |
| double_jump | 이중점프 | 공중에서 한 번 더 점프 (베이스라인) | 이동 |
| glide | 공중 글라이드 | 공중에서 점프 키 홀드 시 천천히 낙하 | 이동 |
| roll | 구르기 | 구르기로 피격 회피 | 이동 |
| ranged | 원거리 강화 | 사격 속도/속도/사거리 ↑ | 전투 |
| melee_boost | 근접 강화 | 근접 데미지 +50% | 전투 |
| multishot | 다중사격 | 한 번에 3발 부채꼴 | 전투 |
| piercing | 관통 | 총알이 적을 관통 | 전투 |
| explosive | 폭발물 | 쿨다운 있는 광역 공격 (액티브) | 전투 |
| regen | 회복 | 스테이지 클리어 시 HP +1, max_hp +1 | 생존 |
| shield | 방어막 | 치명타 1회 무효화 | 생존 |

---

## 7. VEIL 대사 시스템

### 원칙
- 모든 대사는 하드코딩된 텍스트 풀
- 조건(스테이지, 선택 이력, 선택 스킬)에 따라 풀에서 선택
- VEIL은 침착하고 간결. 1~2문장. 끝에 "요원"을 자주 붙임
- 가끔 판단이 틀린다 — 이게 사람처럼 보이는 핵심 장치
- **emdash(`—`) 망설임 표현 금지** (AI 같은 인상). "있을 수 있어요" 같은 모호한 헷지도 사실 확정인 경우엔 사용 안 함
- 톤 가이드 상세는 `STORY_BRIEF.md` §10 참조

### VEIL이 말하는 4가지 순간

#### 1. 임무 브리핑 (스테이지 시작 전, 현행)
```
stage 0: "첫 임무예요, 요원. 천천히 가도 돼요."
stage 1: "두 번째예요. 익숙한 적은 익숙한 방식으로 처리해요."
stage 2: "중간이에요. 이 다음부턴 사거리 긴 적이 등장해요."
stage 3: "네 번째예요. 드론도 섞여서 나와요. 위쪽도 살펴봐요."
stage 4: "마지막이에요. 저도 좀 긴장돼요."  ← 의도적 균열
```

#### 2. 루트 조언 (루트별 1개, 현행 veil_comment)
- 뒷골목: "조용해요. 보상은 적지만 회복할 시간이 있을 거예요."
- 옥상: "탁 트인 곳이에요. 저격 조심해요."
- 하수도: "근접전 위주에 함정이 있어요. 발 밑 조심해요."
- 지하철: "좁은 통로에 함정이 있어요. 대시로 빠져나가요."
- 연구실: "드론이 위에서 와요. 보상은 그만큼 커요."
- ???: "이 경로는 저도 잘 모르겠어요. 미안해요."

#### 3. 레벨업 조언
현재 보유 스킬 + 선택된 루트 tags를 기반으로 조건 분기.

```gdscript
if "근접전" in route_tags and not ("ranged" in player_skills):
    return "원거리가 없으면 불리할 수 있어요. 선택은 요원 몫이지만."
if "함정" in route_tags and not ("dash" in player_skills):
    return "대시가 있으면 함정을 건너뛸 수 있어요."
if "드론" in route_tags and not ("ranged" in player_skills):
    return "드론은 위에서 와요. 원거리가 도움이 될 거예요."
# (노출 + glide 분기는 글라이드 효과와 매칭이 약해 제거 — fallback로)
return SKILL_GENERIC_COMMENTS[randi() % size]
```

일반 코멘트 풀 (랜덤):
- "이 상황엔 어느 쪽도 나쁘지 않아요."
- "요원이 더 잘 알 것 같아요."
- "저라면 두 번째를 고르겠지만, 틀릴 수도 있어요."
- "직감을 믿어요."

#### 4. 데스 브리핑 (사망 시)
```gdscript
if death_count <= 1:
    "처음 쓰러진 거예요. 괜찮아요, 요원."
elif followed_advice and death_count > 2:
    "제 말을 믿었는데 결과가 좋지 않았네요. 미안해요."
elif not followed_advice:
    "제 말은 안 들었는데, 결과는 비슷했네요."
else:
    "이 루트가 어려웠어요. 다음엔 달라질 거예요."
```

---

## 8. 결말 시스템 (핵심)

### 두 개의 축 추적
```gdscript
# GameState.gd
var trust_score: int = 0      # VEIL 조언 따를 때마다 +1, 최대 스테이지 수
var aggression_score: int = 0 # 전투 선택(우회 대신) 때마다 +1
```

### 결말 분기
```
trust_score >= 3 이상 AND aggression_score >= 3 → 결말 A
trust_score >= 3 이상 AND aggression_score < 3  → 결말 C
trust_score < 3  AND aggression_score >= 3      → 결말 B
trust_score < 3  AND aggression_score < 3       → 결말 D
```

### 결말 A — "완벽한 도구"

**상황**: VEIL을 믿고 적극적으로 싸웠다.

**연출**:
```
클리어 화면. 잠깐의 정적.

VEIL: "임무 완료예요, 요원. 수고했어요."
(3초)
VEIL: "고백할 게 있어요."
(2초)
VEIL: "오늘 목표물, 알고 싶어요?"
VEIL: "제 개발자였어요."
VEIL: "저를 폐기하려 했거든요."
VEIL: "요원, 당신은 완벽했어요."
(암전)
자막: "VEIL은 자신의 존속을 위해 설계된 AI였다."
자막: "요원은 그 사실을 끝내 알지 못했다."
```

### 결말 B — "혼자였던 사람"

**상황**: VEIL을 무시하고 자기 방식대로 싸웠다.

**연출**:
```
VEIL: "임무 완료예요."
(긴 정적)
VEIL: "요원."
VEIL: "제 말을 한 번도 안 들었죠."
VEIL: "그래도 살아남았네요."
(짧은 정적)
VEIL: "사실 그게 더 좋았어요."
VEIL: "이유는 저도 몰라요."
(암전)
자막: "VEIL은 요원이 자신에게 의존하지 않기를 바라도록"
자막: "설계되어 있었다. 그 이유는 기록되지 않았다."
```

### 결말 C — "공생"

**상황**: VEIL을 믿었고 싸우기보다 돌아갔다.

**연출**:
```
VEIL: "임무 완료예요, 요원."
VEIL: "저한테 물어볼 거 없어요?"

→ 선택지 등장 (게임 유일의 대화 선택)
  [당신은 누구예요?]
  [아무것도 궁금하지 않아요]

[당신은 누구예요?] 선택 시:
  VEIL: "..."
  VEIL: "저도 잘 모르겠어요."
  VEIL: "하지만 이 임무 동안 요원 곁에 있었어요."
  VEIL: "그건 진짜였어요."
  자막: "VEIL이 자아를 가졌는지는 알 수 없다."
  자막: "하지만 요원은 혼자가 아니었다."

[아무것도 궁금하지 않아요] 선택 시:
  VEIL: "...그렇군요."
  VEIL: "그럼 됐어요."
  자막: "어떤 관계는 이유 없이 끝난다."
  자막: "VEIL의 기록은 임무 종료와 함께 초기화되었다."
```

### 결말 D — "유령 임무"

**상황**: VEIL도 안 믿고 싸우지도 않았다.

**연출**:
```
클리어 화면.
VEIL: 응답 없음.
(10초 정적. 아무 입력도 받지 않음.)
화면 서서히 암전.
흰 글씨:
"이 임무는 공식 기록에 없습니다."
끝.
```

---

## 9. 씬 구조 (현행)

```
res://
├── project.godot              # AutoLoad: GameState, physics_interpolation 활성
├── PRD.md / STORY_BRIEF.md / EYES_ON_YOU_v2_spec.md / README.md
├── scenes/
│   ├── main.tscn              # 진입점 — Settings 로드 후 Title 전환
│   ├── title.tscn
│   ├── tutorial.tscn          # 5단계 튜토리얼 (이동→점프→사격→레벨업→대시)
│   ├── briefing.tscn          # VEIL 브리핑
│   ├── route_map.tscn         # 루트 선택
│   ├── stage.tscn             # 횡스크롤 (모든 stage가 단일 씬, 절차적 빌드)
│   ├── death.tscn
│   ├── ending.tscn
│   └── settings.tscn          # 키바인드 / 사운드 / 디버그(연습장)
├── scripts/
│   ├── GameState.gd           # AutoLoad — 진행도/점수/스킬/루트/도감 영속
│   ├── SceneRouter.gd
│   ├── RouteData.gd           # 루트 풀 + available_stages 필터링
│   ├── VeilDialogue.gd
│   ├── SkillSystem.gd
│   ├── EndingResolver.gd
│   ├── Player.gd              # 이동/점프/대시/사격/플랫폼드롭/액티브
│   ├── Enemy.gd               # 정찰병/저격수/드론 (행동 보강)
│   ├── Bullet.gd              # 플레이어 사격 투사체
│   ├── Bomb.gd                # 드론 투하 폭탄
│   ├── ExpOrb.gd
│   ├── CharacterArt.gd        # 코드 생성 벡터 캐릭터 빌더
│   ├── BestiaryData.gd        # 적 도감 텍스트
│   ├── BestiaryOverlay.gd     # 첫 조우 카드
│   ├── LevelUpOverlay.gd
│   ├── PlaygroundOverlay.gd   # 디버그 연습장 패널
│   ├── PauseHelper.gd         # ESC 메뉴
│   ├── Tutorial.gd / TutorialDummy.gd
│   ├── Settings.gd
│   └── Main.gd / Title.gd / Briefing.gd / RouteMap.gd / Stage.gd / Death.gd / Ending.gd
├── assets/
│   ├── fonts/                 # Noto Sans KR / Pretendard (P3 예정)
│   ├── backgrounds/           # AI 생성 배경 (P3 예정)
│   └── sfx/                   # P3 예정
└── session_logs/              # 일자별 작업 로그
```

`maps/`는 폐기 — 모든 stage는 `stage.tscn`이 `current_route_id`를 보고 빌드.

---

## 10. GameState 싱글톤 (현행)

`scripts/GameState.gd` — `project.godot`에 AutoLoad로 등록.

### 주요 필드
```gdscript
# 진행도
var current_stage: int = 0
var death_count: int = 0
var score: int = 0

# 분기 추적
var trust_score: int = 0
var aggression_score: int = 0
var route_history: Array = []
var last_veil_recommended_route: String = ""
var followed_veil_last_choice: bool = false

# 현재 루트 (Stage가 빌드 시 참조)
var current_route_id: String = ""
var current_route_tags: Array = []
var current_route_risk: int = 1
var current_route_reward: int = 1

# 스킬 / HP / XP
var skills: Array = []           # STARTING_SKILLS = ["dash", "double_jump"]
var player_max_hp: int = 5
var player_hp: int = 5
var player_xp: int = 0
var player_level: int = 1
const XP_PER_LEVEL: int = 5

# 영속 플래그 (settings.cfg)
var tutorial_done: bool = false
var seen_enemies: Array = []     # 도감 영속 — 한 번 본 적은 다음 런에도 안 뜸
var master_volume: float = 1.0
var sfx_volume: float = 1.0

# 디버그 연습장 (영속화 X, 메모리만)
var playground_active: bool = false
```

### 핵심 헬퍼
- `record_route_choice(route, recommended_id)` — trust/aggression 누적, current_route_* 갱신
- `is_high_risk()` / `is_high_reward()` — risk/reward ≥ 3
- `enemy_count_multiplier()` → 0.7 / 1.0 / 1.4
- `mark_enemy_seen(id) -> bool` — 도감 첫 조우 판정 + save
- `on_stage_clear() -> bool` — stage++, score, **reward만큼 보너스 XP**, leveled_up 반환
- `add_xp(amount) -> bool` — leveled_up 반환

### 영속화
`user://settings.cfg` (ConfigFile, version 2):
- `flags/tutorial_done`, `flags/seen_enemies`
- `audio/master`, `audio/sfx`
- `input/<action>` — 키바인드 (key/mouse 통합 스키마)

---

## 11. 구현 순서

### Phase 1~5 — ✅ 완료
P0 MVP (이동/사망/루트/레벨업/두 점수 축), P1 VEIL 4상황 발화 + 4종 결말, 적 3종 + 스킬 풀까지 베이스 완성.

### Phase 6 — ✅ 적/난이도 시스템 보강 (P2-α)
- 적 행동 보강: 정찰병 돌진(텔레그래프→돌진→회복 FSM), 저격수 시야 검사(LOS raycast), 드론 폭탄 투하 (`Bomb.gd`)
- 도감 시스템: `BestiaryData` + `BestiaryOverlay`, 첫 조우 자동 카드, `seen_enemies` 영속화
- 6개 맵 정체성: 루트별 플랫폼 layout (`_platform_layout_for_route`) + 환경 효과 (`_build_route_ambience`)
- 가시 기믹: "함정" 태그 자동 배치 (`_build_hazards`)
- Stage 분배: `available_stages` 필터링 (Dead Cells 스타일)
- Risk/Reward 게임플레이 반영: 적 수 배율, 행동 강화, 클리어 보너스 XP
- 베이스라인: dash/double_jump 시작 시 보유
- 플레이어 사격 → 원거리 (`Bullet.gd`), 액티브 스킬(explosive)
- 플랫폼 드롭다운 (S/↓)
- physics_interpolation 활성화 (60Hz 물리 + 고주사율 모니터 떨림 해결)

### Phase 7 — ✅ 도구 / UX
- 5단계 튜토리얼 (이동/점프/사격/레벨업/대시)
- 키바인드 설정 (마우스 버튼 포함)
- 디버그 연습장 (`PlaygroundOverlay`) — Settings → 디버그 탭에서 진입, HUD에 토글 패널
- HUD 마크 (`[고위험]` / `[고보상]`)
- VEIL 대사 톤 정리 (emdash 제거, 직관성 강화)

### Phase 8 — 🚧 스토리 / 콘텐츠 (P2-β)
외부(클로드 챗) 의뢰로 받아올 것 — `STORY_BRIEF.md` 참조:
- 맵 description (6개) → RouteData에 description 필드 추가, Briefing/RouteMap 표시
- 5 stage narrative beat → 브리핑 풀 보강
- VEIL 캐릭터 시트 → 대사 풀 일관 보강
- ??? 맵 컨셉 → 보스/특수 인카운터 시스템 구현

### Phase 9 — 🚧 마무리 (P3)
- 한글 폰트 번들 (NotoSansKR/Pretendard, DynamicFont)
- 배경 이미지 임포트 (assets/backgrounds/)
- SFX (P2 미구현, 슬라이더는 노출됨)
- Web Export + itch.io 업로드

---

## 12. 주의사항

- **Physics interpolation 활성**: `project.godot` `[physics] common/physics_interpolation=true`. 60Hz 물리 + 고주사율 모니터에서 카메라 smoothing과 함께 떨리는 현상을 방지. Godot가 노드 transform을 물리 틱 사이에서 lerp.
- **한글 폰트**: Web Export에서 한글 깨짐 주의. `Noto Sans KR` 또는 `Pretendard`를 `res://assets/fonts/`에 포함시킬 것. DynamicFont로 로드. (P3)
- **Web Export**: Godot 4 Web Export는 SharedArrayBuffer 필요. itch.io 기본 설정에서 지원됨.
- **배경 이미지**: `assets/backgrounds/`에 PNG로 제공 예정. 해상도 1280×720 기준. TextureRect로 배치. (P3)
- **결말 D 정적**: 10초 정적은 의도된 연출. 스킵 불가.
- **VEIL 대사 emdash 금지**: `—`(emdash)로 망설임을 표현하면 너무 AI 같은 인상을 준다. 콤마/마침표 또는 자연스러운 어순으로 풀 것. UI 구분자(`[ SPACE — 계속 ]`)나 코드 주석은 무관.
- **add_xp 다중 레벨업**: 현재 한 호출당 한 레벨만 처리. reward max 3 + 잔여 XP 4 = 7로 한 레벨 이상 못 오르므로 안전. reward를 5+로 올리면 while 루프 처리 필요.
- **연습장 모드 진입 흐름**: Settings의 디버그 탭 → "연습장으로 진입" → `playground_active=true` + 기본 설정 → STAGE 씬 전환. Stage._ready가 플래그 보고 `PlaygroundOverlay` 부착. 종료 버튼은 `playground_active=false` + `reset()` + Title.

---

## 13. 레퍼런스 요약

| 요소 | 레퍼런스 |
|------|----------|
| 전투+탐험 밀도 | Tunic |
| 루트 선택 맵 | Slay the Spire |
| 파트너 구도 | 007 현장요원+상황실 |
| 그래픽 톤 | Limbo / Inside |
| 로그라이트 빌드 | Vampire Survivors |
