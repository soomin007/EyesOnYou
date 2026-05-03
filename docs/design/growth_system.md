# 성장 시스템 설계 — 확정안 + 구현 계획

> 이전 `PROPOSAL_growth_system.md` (초안 제안) + `REPLY_growth_system_v2.md` (사용자 결정) 통합본.
> 본 문서가 단일 진실. 충돌 시 코드보다 본 문서 우선 (구현 진행 중에는 제외).

---

## 1. 결정 요약 (사용자 확정)

| 결정 | 값 |
|---|---|
| 시스템 형태 | **A안 — 티어형 스킬 트리** |
| 스테이지 수 | **5 → 7** |
| 맵 수 | **6 → 11** |
| `XP_PER_LEVEL` | **5 → 8** |
| trust/aggression 임계값 | **3 → 4** |
| 계열 분류 | **전투 / 이동 / 생존** 3계열 × 3티어 |
| trust/aggression 결합 강도 | **약 — VEIL 추천 표시만** (잠금 없음) |
| 튜토리얼 처리 | **튜토리얼 픽은 항상 T1**, 풀도 T1만 |
| `GameState.skills` 자료형 | `Array[String]` → `Dictionary[String, int]` (id → tier) |
| 도감(`seen_enemies`) | 별개 유지 |

**목표**: 7스테이지 × 평균 1.5레벨업 ≈ 10~11레벨업/런. T3 한 계열 특화는 가능, 전체 풀 소진은 불가.

---

## 2. 스킬 트리

### 전투 계열
```
T1 사격 강화         (+1 dmg)
T2 사격 강화+        (+2 dmg, 사격 시 잠깐 가속)
T3 관통              (1체 추가 관통)

T1 삼연사            (3발 부채꼴)
T2 오연사            (5발)
T3 오연사+추적        (5발 + 약한 추적)

T1 폭발물            (3s 쿨다운)
T2 폭발물+           (반경 +30%, 쿨다운 2.5s)
T3 이중 충전          (2회 충전)
```

### 이동 계열
```
T1 글라이드          (천천히 낙하)
T2 글라이드+         (낙하 중 가속)
T3 공중 사격 패널티 제거

T1 대시 강화         (쿨다운 -20%)
T2 대시 거리+        (+30%)
T3 대시 후 0.3s 무적
```

### 생존 계열
```
T1 HP +1
T2 HP +2 + 피격 후 1s 무적
T3 피격 시 짧은 슬로모

T1 방어막            (1회 부활)
T2 방어막 회복 강화   (회복량 1→2)
T3 방어막 재충전형    (30s 후 재무장)
```

### 진행 규칙
- 같은 라인의 T2는 해당 T1 보유 시에만 후보 등장.
- 같은 라인의 T3는 해당 T2 보유 시에만 후보 등장.
- `roll_choices` 결과는 픽 가능한 후보 ≥ 픽 수면 후보 셔플 후 N개, 부족하면 가능한 만큼만 (기존 `min(count, available.size())` 패턴 유지).

---

## 3. 맵 — 11개 확정

| ID | 이름 | 위치 | ACT | risk | reward | 특징 |
|----|------|------|-----|------|--------|------|
| back_alley | 외곽 진입로 | 시설 외벽 접근 | 1 | 1 | 1 | 기본 루트. 경비 적음 |
| rooftops | 외벽 옥상 | 시설 외부 상단 | 1 | 2 | 2 | 저격 노출. 기동성 요구 |
| sewers | 지하 인입로 | 외부→내부 하수도 | 1 | 2 | 3 | 함정 많음. 보상 큼 |
| subway | 폐쇄 지하철 | 지하 연결로 | 1~2 | 2 | 2 | 좁고 어두움. 근접전 |
| cooling | 냉각 시설 | 내부 기계실 | 2 | 2 | 3 | 드론 첫 등장. 수직 구조 |
| watchtower | 감시탑 | 내부 중층 | 2 | 3 | 3 | 저격수 밀집. 원거리 유리 |
| **ward** | **격리 병동** | **내부 중층** | **2** | **2** | **3** | **좁은 복도. 은폐 유리. ??? 맵 복선¹** |
| datacenter | 데이터 센터 | 핵심부 인접 | 2~3 | 3 | 3 | 드론+저격 혼합. 고난도 |
| escape | 비상 탈출로 | 핵심부 우회 | 3 | 1 | 2 | ACT 3 유일 저위험 루트 |
| lab | 핵심부 | 서버실 직전 | 3 | 3 | 3 | 최고 난도 |
| hidden | ??? | 격리 서버실 | 3 | ? | ? | 특수. 전투 없음. unique |

> ¹ **격리 병동 노출 보장**: VEIL이 통과 중 짧게 멈추고 "...이 구역은 오래됐어요." → ??? 맵 복선. 이 흐름이 자연스러우려면 격리 병동은 Stage 3~4 선택지에 **반드시 포함**되어야 함 (강제 선택 아님, 후보로는 항상 등장).

### RouteData 신규 필드
```gdscript
{
  "min_stage": 0,    # 이 스테이지 이상에서만 등장
  "max_stage": 2,    # 이 스테이지 이하에서만 등장
  "unique": false,   # true면 1회 등장 후 풀 영구 제거 (??? 전용)
}
```

### 스테이지별 후보 풀

| 스테이지 | ACT | 픽 수 | 등장 가능 맵 |
|---------|-----|------|------------|
| Stage 0 | 1 | 2 | 외곽 진입로, 외벽 옥상 |
| Stage 1 | 1 | 2~3 | 외벽 옥상, 지하 인입로, 폐쇄 지하철 |
| Stage 2 | 1→2 | 3 | 지하 인입로, 폐쇄 지하철, 냉각 시설, 감시탑 |
| Stage 3 | 2 | 3 | 냉각 시설, 감시탑, **격리 병동** |
| Stage 4 | 2 | 3 | 감시탑, **격리 병동**, 데이터 센터 |
| Stage 5 | 2→3 | 3 | 데이터 센터, 비상 탈출로, 핵심부, ??? |
| Stage 6 | 3 | 2~3 | 비상 탈출로, 핵심부, ??? (Stage 5 미방문 시) |

**중복 방문 금지**: 한 번 선택한 맵은 `route_history`에 기록되어 이후 풀에서 제외 (전 맵 보편 규칙).
**Pick count 동적**: 후보 < 픽 수일 때 가능한 만큼만 (스킬 풀과 동일한 클램프 패턴).

---

## 4. trust/aggression 결합

- **trust 높음** → 레벨업 화면에서 이동/생존 계열 항목에 `VEIL 추천` 뱃지
- **aggression 높음** → 전투 계열 항목에 `VEIL 추천` 뱃지
- 잠금 없음. 추천 무시 가능.
- 임계값: 7스테이지 기준 4 (5스테이지의 3에서 비례 상향)

---

## 5. XP 곡선

- `XP_PER_LEVEL = 8`
- 적 처치 XP는 현행 유지
- 스테이지 클리어 보너스: reward 그대로 (1=+1, 2=+2, 3=+3)
- **신규**: high-risk(risk=3) 루트에서 적 처치 XP **+50%** 보너스
- 평균 1.5렙업/스테이지 → 7스테이지 합계 10~11렙업
- 레벨 캡 없음. 스테이지 수에 자연 수렴.

---

## 6. 튜토리얼

- 튜토리얼 스킬 풀 = 각 계열 T1 항목만 (전투/이동/생존 T1 1개씩 후보).
- 튜토리얼 픽은 항상 T1 등록.
- 본편 진입 시 T1 1개 보유 상태.
- `Tutorial._finish_tutorial`은 그대로 `GameState.start_main_game()` 사용 (스킬 보존, 레벨/XP 리셋).

---

## 7. 사전 메모 (잊지 말 것)

### 7.1 풀 크기 동적 클램프 — 이미 구현됨
- `SkillSystem.roll_choices`: `for i in min(count, available.size())` (line 31)
- `RouteData.get_route_pool_for_stage`: `var pick_count: int = min(available.size(), 3 if stage_index >= 1 else 2)` (line 90)

→ 새 시스템에서도 같은 패턴 유지. unique=true + 중복 방문 금지로 후반에 풀 부족 시 자동 축소.

### 7.2 격리 병동 노출 보장
- 표 그대로 Stage 3 후보(3개) 픽 3, Stage 4 후보(3개) 픽 3 → 항상 노출.
- 코드 보강 권장: `RouteData`에 `guaranteed_in_stages` 같은 필드를 두거나, Stage 3/4 풀 빌드 시 격리 병동을 셔플 전 fix-slot으로 박기. 미래에 후보 맵 추가될 때 보호.

### 7.3 변주 맵 옵션 (후속)
- 후보 부족 시 같은 맵의 시각/배치 변주 버전(예: `subway-1`, `subway-2`)을 두는 것도 가능.
- 현재 우선순위 아님. 11개로 일단 가고, 후반 풀 부족이 실제로 문제될 때 도입.

### 7.4 `Callable.bind` 파라미터 순서
- Godot 4 `Callable.bind`는 인자를 **뒤에** 추가. 신호가 emit하는 인자가 항상 앞.
- 새 Area2D 트리거 추가 시 핸들러 시그니처는 `(body, area)` 순.
- 이미 코드에서 한 번 버그 났음(2026-05-02 세션 3) — 같은 실수 반복 금지.

---

## 8. 구현 계획 (작업 순서)

### Phase B — 성장 시스템 (스토리/맵과 독립)

**B-1 데이터 정의** ✅ 완료 (commit 64dcbd1)
- [x] `scripts/SkillTreeData.gd` 신규 — 계열/티어 데이터 + lookup 헬퍼
- [x] `scripts/GameState.gd` — `skills: Array` → `skills: Dictionary` 마이그레이션
- [x] `scripts/SkillSystem.gd` — `roll_choices` 티어 prereq, `find_by_id` 위임

**B-2 효과 + UI** ✅ 완료 (commit ec368b2)
- [x] `scripts/Player.gd` — 각 라인 효과 티어 분기 (T1/T2/T3)
- [x] `scripts/LevelUpOverlay.gd` — 카드 [family · T#] 헤더 + VEIL 추천 표시
- [x] `scripts/GameState.gd` — high-risk 루트 적 처치 XP +50%, XP_PER_LEVEL 8

### Phase C — 맵 + 스테이지 확장

**C-1 데이터/규칙** ✅ 완료 (commit da74ea4)
- [x] `scripts/RouteData.gd` — min/max_stage/unique/guaranteed_in_stages, 11개 맵
- [x] `scripts/RouteMap.gd` — route_history 필터
- [x] `scripts/GameState.gd` — TOTAL_STAGES=7, SCORE_THRESHOLD=4
- [x] 신규 5개 맵 ambience 임시 매핑

**C-2 신규 맵 layout** ✅ 완료
- [x] `scripts/Stage.gd` — 5개 맵 platform layout
- [x] `scripts/Stage.gd` — 5개 맵 ambience (cooling/watchtower/ward/datacenter/escape)

**C-3 내러티브** ✅ 완료
- [x] `scripts/VeilDialogue.gd` — Stage 5/6 브리핑 풀 추가, ACT 매핑 재정렬
- [x] `scripts/Stage.gd` — 격리 병동 복선 트리거 (route_ward 진입 시)
- [x] `scripts/Stage.gd` — 잠긴 문 톤 보강 (크기 ↑, LED 펄스, ACCESS DENIED 라벨, 후광, 추가 대사)

### 인게임 검증 / 후속 polish 항목
- [ ] 새 빌드 평균 레벨업 횟수 측정 (XP_PER_LEVEL=8이 너무 빡빡한지)
- [ ] 7스테이지 완주 시간이 8~15분 안에 들어오는지
- [ ] 격리 병동 복선 → ??? 맵 발견 흐름이 "아, 그거였구나" 연결되는지
- [ ] explosive T3 (2회 충전), glide T3 (사격 패널티 제거), shield T3 (재충전), hp T3 (슬로모) 미구현분
- [ ] multishot T3 추적 미구현

---

## 9. 비목표

- 스킬 신규 추가 (기존 풀 재구성만)
- 무기/장비 슬롯 등 별도 축
- 런 간 영구 강화 (메타 진보)
