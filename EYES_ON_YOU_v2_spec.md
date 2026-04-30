# EYES ON YOU — Claude Code 구현 계획서 v2

> Claude Code에게: 이 문서를 처음부터 끝까지 읽고 구현하세요.
> 외부 API 없음. 모든 텍스트와 로직은 코드 안에 완결됩니다.

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

### 루트 속성
```gdscript
{
  "id": "route_sewers",
  "name": "하수도",
  "risk": 2,        # 1~3 (●로 표시)
  "reward": 3,      # 1~3 (●로 표시)
  "hidden": false,  # true면 위험도/보상 ?로 표기
  "tags": ["근접전", "어두운_환경", "함정"],
  "veil_comment": "적이 많지만 보상이 있어요, 요원.",
  "map_scene": "res://maps/sewers.tscn"
}
```

### 밸런스 원칙
| 위험도 | 보상 | 비고 |
|--------|------|------|
| 1 | 1~2 | 안전 루트 |
| 2 | 2~3 | 일반 루트 |
| 3 | 3 | 고위험 루트 |
| ? | ? | 숨겨진 루트 (실제 위험도 2, 보상 3) |

### 선택 추적 (GameState에 기록)
- 선택한 루트의 tags 누적
- VEIL 조언을 따랐는지 여부 (조언한 루트 == 선택한 루트)
- 전투 선택 vs 우회 선택 횟수

---

## 5. 스테이지 (횡스크롤)

### 플레이어
- 이동: 좌우 이동, 점프, 이중점프(스킬)
- 기본 공격: 근접 (짧은 사거리)
- HP: 최대 5 (하트로 표시)
- 낙사 없음 — 바닥에 닿으면 HP 1 감소 후 리스폰

### 적
- **순찰병**: 좌우 순찰, 근접 공격
- **저격수**: 고정 위치, 원거리 공격
- **드론**: 플레이어 추적, 접촉 데미지

### 경험치 & 레벨업
- 적 처치 시 경험치 오브 드롭
- 오브 자동 흡수 (플레이어 근처)
- 경험치 바 가득 차면 레벨업 → 스킬 선택 화면

### 맵 구성 (스테이지별 씬 파일)
- 배경: AI 생성 이미지 (별도 제공)
- 전경(플랫폼, 벽): 코드로 생성된 미니멀 벡터
- 각 스테이지 길이: 화면 3~4개 분량의 수평 스크롤

---

## 6. 스킬 시스템

레벨업마다 아래 풀에서 3개 무작위 제시, 1개 선택.

### 스킬 목록 (10종)
| ID | 이름 | 효과 | 태그 |
|----|------|------|------|
| dash | 대시 | 짧은 무적 이동 | 이동 |
| double_jump | 이중점프 | 공중에서 한 번 더 점프 | 이동 |
| wall_slide | 벽타기 | 벽에 붙어 천천히 낙하 | 이동 |
| roll | 구르기 | 구르기로 피격 회피 | 이동 |
| ranged | 원거리 | 원거리 투사체 공격 | 전투 |
| melee_boost | 근접 강화 | 근접 데미지 +50% | 전투 |
| explosive | 폭발물 | 쿨다운 있는 광역 공격 | 전투 |
| stealth | 은폐 | 3초간 적 인식 차단 | 전투 |
| regen | 회복 | 스테이지 클리어 시 HP +1 | 생존 |
| shield | 방어막 | 치명타 1회 무효화 | 생존 |

---

## 7. VEIL 대사 시스템

### 원칙
- 모든 대사는 하드코딩된 텍스트 풀
- 조건(스테이지, 선택 이력, 선택 스킬)에 따라 풀에서 선택
- VEIL은 침착하고 간결. 1~2문장. 끝에 "요원"을 자주 붙임
- 가끔 판단이 틀린다 — 이게 사람처럼 보이는 핵심 장치

### VEIL이 말하는 4가지 순간

#### 1. 임무 브리핑 (스테이지 시작 전)
스테이지별로 고정 텍스트 1개.

```
스테이지 1: "첫 임무예요, 요원. 천천히 가도 돼요."
스테이지 2: "이전 루트 덕분에 정보가 생겼어요. 활용해봐요."
스테이지 3: "중간 지점이에요. 여기서부터 달라져요."
스테이지 4: "거의 다 왔어요. 조심해요, 요원."
스테이지 5: "마지막이에요. 저도 긴장되네요."  ← 의도적 균열
```

#### 2. 루트 조언 (루트별 1개)
`RouteData.gd`에 루트마다 `veil_comment` 필드로 정의.

#### 3. 레벨업 조언
현재 보유 스킬 + 선택된 루트 tags를 기반으로 조건 분기.

```gdscript
# 예시 로직
if "근접전" in current_route.tags and not "ranged" in player_skills:
    return "원거리가 없으면 불리할 수 있어요. 선택은 요원 몫이지만."
elif "함정" in current_route.tags:
    return "대시가 있으면 함정을 건너뛸 수 있어요."
else:
    return skill_generic_comments[randi() % skill_generic_comments.size()]
```

일반 코멘트 풀 (랜덤):
```
"이 상황엔 어느 쪽도 나쁘지 않아요."
"요원이 더 잘 알 것 같아요."
"저라면 두 번째를 고르겠지만 — 틀릴 수도 있어요."
"직감을 믿어요."
```

#### 4. 데스 브리핑 (사망 시)
선택 이력 조합으로 고정 텍스트 선택.

```gdscript
# 조건 예시
if death_count == 0:  # 첫 사망
    "처음 쓰러진 거예요. 괜찮아요, 요원."
elif followed_veil_advice and death_count > 2:
    "제 말을 믿었는데 결과가 좋지 않았네요. 미안해요."
elif not followed_veil_advice:
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
VEIL: "오늘 목표물 — 알고 싶어요?"
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
VEIL: "사실 — 그게 더 좋았어요."
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
VEIL: "저한테 물어볼 게 없어요?"

→ 선택지 등장 (게임 유일의 대화 선택)
  [당신은 누구예요?]
  [아무것도 궁금하지 않아요]

[당신은 누구예요?] 선택 시:
  VEIL: "..."
  VEIL: "저도 잘 모르겠어요."
  VEIL: "하지만 — 이 임무 동안, 요원 곁에 있었어요."
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

## 9. 씬 구조

```
res://
├── project.godot
├── main.tscn                  # 진입점, 씬 전환 관리
├── scenes/
│   ├── title.tscn
│   ├── briefing.tscn          # VEIL 브리핑 텍스트 출력
│   ├── route_map.tscn         # 루트 선택 (맵 형태)
│   ├── stage.tscn             # 횡스크롤 메인 (맵 씬 로드)
│   ├── levelup.tscn           # 스킬 선택
│   ├── death.tscn             # 사망 + VEIL 브리핑
│   └── ending.tscn            # 결말 (4종 분기)
├── maps/
│   ├── stage_01.tscn
│   ├── stage_02.tscn
│   ├── stage_03.tscn
│   ├── stage_04.tscn
│   └── stage_05.tscn
├── scripts/
│   ├── GameState.gd           # AutoLoad 싱글톤
│   ├── Player.gd
│   ├── Enemy.gd
│   ├── RouteData.gd           # 루트 정의 (데이터)
│   ├── VeilDialogue.gd        # 대사 풀 + 선택 로직
│   ├── SkillSystem.gd
│   └── EndingResolver.gd      # trust/aggression → 결말 분기
└── assets/
    ├── fonts/                 # Noto Sans KR (한글)
    ├── backgrounds/           # AI 생성 배경 이미지 (추후 제공)
    └── sfx/
```

---

## 10. GameState 싱글톤

```gdscript
# GameState.gd — project.godot에 AutoLoad로 등록
extends Node

# 플레이 데이터
var current_stage: int = 0
var death_count: int = 0
var score: int = 0

# 분기 추적
var trust_score: int = 0       # VEIL 조언을 따른 횟수
var aggression_score: int = 0  # 전투 선택 횟수
var route_history: Array = []  # 선택한 루트 id 목록

# 스킬
var skills: Array = []

# 리셋
func reset() -> void:
    current_stage = 0
    death_count = 0
    score = 0
    trust_score = 0
    aggression_score = 0
    route_history = []
    skills = []
```

---

## 11. 구현 순서

### Phase 1 — 뼈대 (플레이 가능한 최소 상태)
1. Godot 프로젝트 생성 + 씬 구조 세팅
2. GameState AutoLoad 등록
3. 타이틀 씬 → 브리핑 씬 → 스테이지 씬 전환
4. Player.gd: 이동, 점프, 기본 공격
5. Enemy.gd: 순찰병 1종
6. 사망/클리어 판정 + 씬 전환

### Phase 2 — 루프 완성
7. 경험치 오브 + 레벨업 판정
8. 레벨업 화면 + 스킬 선택 (3종)
9. 스킬 효과 구현 (대시, 이중점프, 원거리 우선)
10. 루트 선택 화면 (RouteData 기반)
11. trust_score / aggression_score 기록

### Phase 3 — VEIL 대사
12. VeilDialogue.gd 구현 (전체 대사 풀)
13. 브리핑 씬에 타자기 효과 출력
14. 레벨업 조언 삽입
15. 데스 브리핑 구현

### Phase 4 — 콘텐츠
16. 스테이지 3→5개로 확장
17. 적 2종 추가 (저격수, 드론)
18. 스킬 나머지 구현
19. 루트 분기 밸런스 조정

### Phase 5 — 결말 + 마무리
20. EndingResolver.gd: 분기 계산
21. 결말 4종 연출 구현
22. 공유 텍스트 클립보드 복사
23. 배경 이미지 임포트 (별도 제공)
24. Web Export 빌드 + itch.io 업로드

---

## 12. 주의사항

- **한글 폰트**: Web Export에서 한글 깨짐 주의. `Noto Sans KR` 또는 `Pretendard`를 `res://assets/fonts/`에 포함시킬 것. DynamicFont로 로드.
- **Web Export**: Godot 4 Web Export는 SharedArrayBuffer 필요. itch.io 기본 설정에서 지원됨.
- **배경 이미지**: `assets/backgrounds/`에 PNG로 제공 예정. 해상도 1280×720 기준. TextureRect로 배치.
- **Mock 적**: Phase 1에서 적이 단순해도 됨. 핵심은 루프가 돌아가는 것.
- **결말 D 정적**: 10초 정적은 의도된 연출. 스킵 불가.

---

## 13. 레퍼런스 요약

| 요소 | 레퍼런스 |
|------|----------|
| 전투+탐험 밀도 | Tunic |
| 루트 선택 맵 | Slay the Spire |
| 파트너 구도 | 007 현장요원+상황실 |
| 그래픽 톤 | Limbo / Inside |
| 로그라이트 빌드 | Vampire Survivors |
