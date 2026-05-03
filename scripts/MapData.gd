class_name MapData
extends RefCounted

# 11개 맵의 세계 형태 + platform/적 spawn/보상/함정 통합 명세.
# DESIGN_world_layout.md (외부 클로드 v2 답변) 기반.
#
# 각 layout 반환 구조:
#   "world_type":   String  ("HORIZONTAL" / "VERTICAL_UP" / "VERTICAL_DOWN" / "ARENA")
#   "world_size":   Vector2
#   "player_start": Vector2
#   "goal_type":    String  ("POSITION" / "ENEMY_CLEAR" / "SEQUENCE")
#   "goal_pos":     Vector2 (goal_type == POSITION일 때만 의미)
#   "camera_mode":  String  ("HORIZONTAL" / "VERTICAL" / "FIXED")
#   "platforms":    Array of {"pos": Vector2, "w": float}
#   "enemies":      Dictionary of {kind: Array of Vector2}
#   "rewards":      Dictionary of {"xp_orbs": Array of Vector2, "hp_pickups": Array of Vector2}
#   "spikes":       Array of {"x": float, "y": float}  (y 생략 가능)
#   "waves":        Array of wave configs (ARENA 전용, 선택)
#   "boss":         Dictionary (lab 전용 — boss 행동 명세, 선택)
#   "easter_egg":   Dictionary (ward 전용 — 잠긴 문 트리거)

const GROUND_Y_DEFAULT: float = 600.0

static func get_layout(route_id: String) -> Dictionary:
	match route_id:
		"route_back_alley": return _back_alley()
		"route_rooftops":   return _rooftops()
		"route_sewers":     return _sewers()
		"route_subway":     return _subway()
		"route_cooling":    return _cooling()
		"route_watchtower": return _watchtower()
		"route_ward":       return _ward()
		"route_datacenter": return _datacenter()
		"route_escape":     return _escape()
		"route_lab":        return _lab()
		"route_hidden":     return _hidden()
		"route_blackout":   return _blackout()
	return {}

# ─── 1. 외곽 진입로 (HORIZONTAL, 짧음) ─────────────────────────
static func _back_alley() -> Dictionary:
	return {
		"world_type":   "HORIZONTAL",
		"world_size":   Vector2(2800.0, 720.0),
		"player_start": Vector2(140.0, 540.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(2680.0, 540.0),
		"camera_mode":  "HORIZONTAL",
		"platforms": [
			{"pos": Vector2(400, 520),  "w": 160.0},
			{"pos": Vector2(700, 460),  "w": 160.0},
			{"pos": Vector2(1100, 520), "w": 180.0},
			{"pos": Vector2(1500, 460), "w": 160.0},
			{"pos": Vector2(1900, 520), "w": 180.0},
			{"pos": Vector2(2300, 460), "w": 160.0},
		],
		"enemies": {
			"patrol": [Vector2(600, 600.0), Vector2(1300, 600.0), Vector2(2100, 600.0)],
			"sniper": [], "drone": [], "bomber": [], "shield": [],
		},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		"spikes": [],
	}

# ─── 2. 외벽 옥상 (VERTICAL_UP) ───────────────────────────────
# 점프 파라미터 (Player.gd): JUMP_VEL -540, GRAVITY 1400 → 1단 ~104px / 2단 ~190px.
# 설계: 일반 발판 gap = 80 (1단 여유), 분기 도약 = 140 (의도적 2단 강제).
# 패트롤 발판은 가급적 넓게 (≥200) — 가장자리 감지 + 적이 떨어지지 않게.
static func _rooftops() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 저층 합류점(2440) — gap 80, 좌우 살짝 흔들기
			{"pos": Vector2(560, 3000), "w": 240.0},  # 80
			{"pos": Vector2(640, 2920), "w": 240.0},
			{"pos": Vector2(560, 2840), "w": 240.0},
			{"pos": Vector2(640, 2760), "w": 240.0},
			{"pos": Vector2(560, 2680), "w": 240.0},
			{"pos": Vector2(640, 2600), "w": 240.0},
			{"pos": Vector2(560, 2520), "w": 240.0},
			{"pos": Vector2(640, 2440), "w": 280.0},  # 저층 메인 (patrol 자리, 넓게)
			# 저층 → 중층 (단일 경로, gap 80)
			{"pos": Vector2(540, 2360), "w": 240.0},
			{"pos": Vector2(440, 2280), "w": 240.0},
			{"pos": Vector2(360, 2200), "w": 240.0},
			{"pos": Vector2(280, 2120), "w": 240.0},
			{"pos": Vector2(360, 2040), "w": 240.0},
			{"pos": Vector2(440, 1960), "w": 240.0},
			{"pos": Vector2(540, 1880), "w": 280.0},  # 중층 합류 (patrol 자리)
			# 분기 도약 — 중층(1880) → 고층 진입 (gap 140, 의도적 2단 강제)
			# 우측 노출 (XP 보상): 1880 → 1740 (140 gap)
			{"pos": Vector2(900, 1740), "w": 200.0},
			{"pos": Vector2(960, 1660), "w": 200.0},
			{"pos": Vector2(900, 1580), "w": 200.0},
			{"pos": Vector2(1020, 1500), "w": 220.0},
			{"pos": Vector2(960, 1420), "w": 220.0},  # 고층 우측 끝 (XP 보상)
			# 좌측 안전 (HP 보상): 1880 → 1740 (140 gap)
			{"pos": Vector2(220, 1740), "w": 200.0},
			{"pos": Vector2(160, 1660), "w": 200.0},
			{"pos": Vector2(220, 1580), "w": 200.0},
			{"pos": Vector2(140, 1500), "w": 220.0},
			{"pos": Vector2(220, 1420), "w": 220.0},  # 고층 좌측 끝 (HP 보상)
			# 합류 도약 — 고층 끝(1420) → 단일 경로 (gap 100, 1단으로 빠듯하지만 가능)
			{"pos": Vector2(540, 1320), "w": 280.0},
			# 정상 단일 경로 (gap 80)
			{"pos": Vector2(640, 1240), "w": 280.0},
			{"pos": Vector2(560, 1160), "w": 240.0},
			{"pos": Vector2(640, 1080), "w": 240.0},
			{"pos": Vector2(560, 1000), "w": 240.0},
			{"pos": Vector2(640, 920),  "w": 240.0},
			{"pos": Vector2(560, 840),  "w": 240.0},
			{"pos": Vector2(640, 760),  "w": 240.0},
			{"pos": Vector2(560, 680),  "w": 240.0},
			{"pos": Vector2(640, 600),  "w": 240.0},
			{"pos": Vector2(560, 520),  "w": 240.0},
			{"pos": Vector2(640, 440),  "w": 240.0},
			{"pos": Vector2(560, 360),  "w": 240.0},
			{"pos": Vector2(640, 280),  "w": 280.0},  # 골 직전
		],
		"enemies": {
			# 발판 위에 정확히 (y = 발판 top - 30 = 발 위치)
			"patrol": [Vector2(640, 2410.0), Vector2(540, 1850.0), Vector2(640, 1210.0)],
			"sniper": [Vector2(960, 1390.0), Vector2(220, 1390.0)],
			"drone":  [Vector2(640, 460.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(960, 1390.0), Vector2(1000, 1390.0)],
			"hp_pickups": [Vector2(220, 1390.0)],
		},
		"spikes": [],
	}

# ─── 3. 지하 인입로 (VERTICAL_DOWN) ───────────────────────────
# 위에서 아래로 내려감 — 분기 좌(적 많음/XP) vs 우(가시 함정/HP)
# 가시는 우측 통로의 다른 y에 분산 배치 (이전엔 spike y 버그로 모두 GROUND_Y에 겹침)
static func _sewers() -> Dictionary:
	return {
		"world_type":   "VERTICAL_DOWN",
		"world_size":   Vector2(1280.0, 2400.0),
		"player_start": Vector2(640.0, 160.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 2250.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 진입 → 상층 (낙하)
			{"pos": Vector2(560, 280), "w": 200.0},
			{"pos": Vector2(560, 460), "w": 160.0},
			{"pos": Vector2(480, 640), "w": 240.0},  # 분기점
			# 좌측 — 넓은 통로 (적 + XP)
			{"pos": Vector2(280, 800),  "w": 220.0},
			{"pos": Vector2(200, 960),  "w": 220.0},
			{"pos": Vector2(260, 1120), "w": 220.0},
			{"pos": Vector2(200, 1280), "w": 240.0},
			# 우측 — 좁은 파이프 (가시 + HP)
			{"pos": Vector2(960, 800),  "w": 100.0},
			{"pos": Vector2(960, 960),  "w": 100.0},
			{"pos": Vector2(960, 1120), "w": 100.0},
			{"pos": Vector2(960, 1280), "w": 120.0},
			# 합류
			{"pos": Vector2(580, 1440), "w": 240.0},
			{"pos": Vector2(480, 1620), "w": 220.0},
			{"pos": Vector2(580, 1800), "w": 240.0},  # 하층 - bomber 자리
			# 하층 → 바닥
			{"pos": Vector2(480, 1980), "w": 220.0},
			{"pos": Vector2(580, 2160), "w": 280.0},  # 골 직전
		],
		"enemies": {
			# 좌측 통로 patrol — 발판 위 (y = platform y - 30 ≈ 발판 위 서있는 위치)
			"patrol": [Vector2(280, 770.0), Vector2(200, 930.0), Vector2(260, 1090.0)],
			"sniper": [],
			"drone":  [],
			# bomber: 합류점 직후 좁은 통로 압박
			"bomber": [Vector2(480, 1410.0), Vector2(580, 1770.0), Vector2(480, 1950.0)],
			"shield": [],
		},
		"rewards": {
			# 좌측 끝 — XP 보상
			"xp_orbs":    [Vector2(200, 1240.0), Vector2(240, 1240.0)],
			# 우측 통과 보상 — HP
			"hp_pickups": [Vector2(960, 1240.0)],
		},
		# 우측 파이프 가시 — 발판 사이 빈 공간에 (y는 가시 끝 위치)
		"spikes": [
			{"x": 960, "y": 880.0},   # 800↔960 사이
			{"x": 1000, "y": 1040.0}, # 960↔1120 사이, 살짝 우로
			{"x": 960, "y": 1200.0},  # 1120↔1280 사이
		],
	}

# ─── 4. 폐쇄 지하철 (HORIZONTAL, 매우 긴 가로 + 낮은 천장) ─────
static func _subway() -> Dictionary:
	return {
		"world_type":   "HORIZONTAL",
		"world_size":   Vector2(5600.0, 480.0),
		"player_start": Vector2(140.0, 380.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(5480.0, 380.0),
		"camera_mode":  "HORIZONTAL",
		"ground_y":     420.0,  # 지면 높이 커스텀 (천장 낮음 강조)
		"platforms": [
			# 열차 지붕
			{"pos": Vector2(600, 220),  "w": 700.0},
			{"pos": Vector2(1600, 220), "w": 700.0},
			{"pos": Vector2(2700, 220), "w": 700.0},
			{"pos": Vector2(3800, 220), "w": 700.0},
			{"pos": Vector2(4900, 220), "w": 500.0},
			# 지붕 진입 발판 (객차 측면)
			{"pos": Vector2(560, 320),  "w": 60.0},
			{"pos": Vector2(1560, 320), "w": 60.0},
			{"pos": Vector2(2660, 320), "w": 60.0},
			{"pos": Vector2(3760, 320), "w": 60.0},
			# 지면 잔해
			{"pos": Vector2(1380, 380), "w": 100.0},
			{"pos": Vector2(2480, 380), "w": 100.0},
			{"pos": Vector2(3580, 380), "w": 100.0},
			{"pos": Vector2(4680, 380), "w": 100.0},
		],
		"enemies": {
			"patrol": [Vector2(800, 420.0), Vector2(2000, 420.0), Vector2(3200, 420.0), Vector2(4400, 420.0)],
			"sniper": [Vector2(900, 200.0), Vector2(2900, 200.0)],
			"drone":  [],
			"bomber": [],
			"shield": [Vector2(1500, 420.0), Vector2(3500, 420.0)],
		},
		"rewards": {
			"xp_orbs":    [Vector2(2000, 200.0), Vector2(2050, 200.0)],
			"hp_pickups": [],
		},
		"spikes": [],
	}

# ─── 5. 냉각 시설 (VERTICAL_UP, 지그재그 파이프) ──────────────
# 지그재그 — 일반 gap 80 (1단), 분기 진입 = 140 (2단 강제). 패트롤 발판 ≥240.
static func _cooling() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 지그재그 상승 (gap 80, 좌우 번갈아 흔들림)
			{"pos": Vector2(640, 3000), "w": 280.0},  # 80
			{"pos": Vector2(540, 2920), "w": 280.0},
			{"pos": Vector2(640, 2840), "w": 280.0},
			{"pos": Vector2(540, 2760), "w": 280.0},
			{"pos": Vector2(640, 2680), "w": 280.0},  # patrol 자리
			{"pos": Vector2(540, 2600), "w": 280.0},
			{"pos": Vector2(640, 2520), "w": 280.0},
			{"pos": Vector2(540, 2440), "w": 280.0},
			{"pos": Vector2(640, 2360), "w": 280.0},
			{"pos": Vector2(540, 2280), "w": 280.0},
			{"pos": Vector2(640, 2200), "w": 280.0},  # patrol 자리
			{"pos": Vector2(540, 2120), "w": 280.0},
			{"pos": Vector2(640, 2040), "w": 280.0},
			{"pos": Vector2(540, 1960), "w": 280.0},
			{"pos": Vector2(640, 1880), "w": 280.0},  # 분기점 — patrol 자리
			# 분기 도약 (gap 140 — 2단 강제, 좌/우 갈림)
			# 우측 파이프 — 빠르지만 드론 perch + 좁음 (XP 보상)
			{"pos": Vector2(960, 1740), "w": 180.0},
			{"pos": Vector2(900, 1660), "w": 180.0},
			{"pos": Vector2(960, 1580), "w": 180.0},
			{"pos": Vector2(900, 1500), "w": 180.0},
			{"pos": Vector2(960, 1420), "w": 180.0},
			{"pos": Vector2(900, 1340), "w": 180.0},
			{"pos": Vector2(960, 1260), "w": 180.0},
			{"pos": Vector2(900, 1180), "w": 180.0},
			{"pos": Vector2(1000, 1100), "w": 200.0},  # 우측 끝 (XP)
			# 좌측 계단 — 안전 (HP 보상)
			{"pos": Vector2(220, 1740), "w": 200.0},
			{"pos": Vector2(160, 1660), "w": 200.0},
			{"pos": Vector2(220, 1580), "w": 200.0},
			{"pos": Vector2(160, 1500), "w": 200.0},
			{"pos": Vector2(220, 1420), "w": 200.0},
			{"pos": Vector2(160, 1340), "w": 200.0},
			{"pos": Vector2(220, 1260), "w": 200.0},
			{"pos": Vector2(160, 1180), "w": 200.0},
			{"pos": Vector2(220, 1100), "w": 220.0},  # 좌측 끝 (HP)
			# 합류 도약 (gap 100, 1단 빠듯하지만 가능)
			{"pos": Vector2(540, 1000), "w": 280.0},
			# 정상 단일 경로 (gap 80)
			{"pos": Vector2(640, 920),  "w": 240.0},
			{"pos": Vector2(540, 840),  "w": 240.0},
			{"pos": Vector2(640, 760),  "w": 240.0},
			{"pos": Vector2(540, 680),  "w": 240.0},
			{"pos": Vector2(640, 600),  "w": 240.0},
			{"pos": Vector2(540, 520),  "w": 240.0},
			{"pos": Vector2(640, 440),  "w": 240.0},
			{"pos": Vector2(540, 360),  "w": 240.0},
			{"pos": Vector2(640, 280),  "w": 280.0},  # 골 직전
		],
		"enemies": {
			"patrol": [Vector2(640, 2650.0), Vector2(640, 2170.0), Vector2(640, 1850.0)],
			"sniper": [Vector2(220, 1070.0)],
			"drone":  [Vector2(960, 1280.0), Vector2(900, 1160.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(1000, 1080.0), Vector2(1040, 1080.0)],
			"hp_pickups": [Vector2(220, 1080.0)],
		},
		"spikes": [],
	}

# ─── 6. 감시탑 (VERTICAL_UP, 3-tier) ──────────────────────────
# 외부 노출(저격 노출, XP) / 내부 계단(표준) 분기. 일반 gap 80, 분기 진입 140.
static func _watchtower() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 분기점 1 (gap 80)
			{"pos": Vector2(560, 3000), "w": 240.0},
			{"pos": Vector2(640, 2920), "w": 240.0},
			{"pos": Vector2(560, 2840), "w": 240.0},
			{"pos": Vector2(640, 2760), "w": 240.0},
			{"pos": Vector2(560, 2680), "w": 240.0},  # patrol 자리
			{"pos": Vector2(640, 2600), "w": 240.0},
			{"pos": Vector2(560, 2520), "w": 240.0},
			{"pos": Vector2(640, 2440), "w": 280.0},  # 분기점 1 — 넓게 (patrol)
			# 분기 도약 (gap 140 — 2단 강제)
			# 외부 노출 (좌측, sniper 노출 → XP 보상)
			{"pos": Vector2(180, 2300), "w": 200.0},
			{"pos": Vector2(120, 2220), "w": 200.0},
			{"pos": Vector2(180, 2140), "w": 200.0},
			{"pos": Vector2(120, 2060), "w": 200.0},
			{"pos": Vector2(180, 1980), "w": 200.0},  # patrol 자리
			{"pos": Vector2(120, 1900), "w": 200.0},
			{"pos": Vector2(180, 1820), "w": 200.0},
			{"pos": Vector2(140, 1740), "w": 200.0},
			{"pos": Vector2(180, 1660), "w": 220.0},  # 외부 끝 (XP 보상)
			# 내부 계단 (중앙)
			{"pos": Vector2(540, 2300), "w": 240.0},
			{"pos": Vector2(640, 2220), "w": 240.0},
			{"pos": Vector2(540, 2140), "w": 240.0},
			{"pos": Vector2(640, 2060), "w": 240.0},
			{"pos": Vector2(540, 1980), "w": 240.0},  # patrol 자리
			{"pos": Vector2(640, 1900), "w": 240.0},
			{"pos": Vector2(540, 1820), "w": 240.0},
			{"pos": Vector2(640, 1740), "w": 240.0},
			{"pos": Vector2(540, 1660), "w": 280.0},  # 중앙 합류 (HP 보상)
			# 합류 도약 (gap 100, 1단 빠듯하지만 가능) → 상단 단일 경로
			{"pos": Vector2(640, 1560), "w": 280.0},
			{"pos": Vector2(560, 1480), "w": 240.0},
			{"pos": Vector2(640, 1400), "w": 240.0},
			{"pos": Vector2(560, 1320), "w": 240.0},
			{"pos": Vector2(640, 1240), "w": 240.0},
			{"pos": Vector2(560, 1160), "w": 240.0},
			{"pos": Vector2(640, 1080), "w": 240.0},
			{"pos": Vector2(560, 1000), "w": 240.0},
			{"pos": Vector2(640, 920),  "w": 240.0},
			{"pos": Vector2(560, 840),  "w": 240.0},
			{"pos": Vector2(640, 760),  "w": 240.0},
			{"pos": Vector2(560, 680),  "w": 240.0},
			{"pos": Vector2(640, 600),  "w": 240.0},
			{"pos": Vector2(560, 520),  "w": 240.0},
			{"pos": Vector2(640, 440),  "w": 240.0},
			{"pos": Vector2(560, 360),  "w": 240.0},
			{"pos": Vector2(640, 280),  "w": 280.0},  # 골 직전
		],
		"enemies": {
			"patrol": [Vector2(560, 2650.0), Vector2(640, 2410.0), Vector2(180, 1950.0), Vector2(540, 1950.0)],
			"sniper": [Vector2(180, 1630.0)],
			"drone":  [Vector2(640, 510.0)],
			"bomber": [],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(180, 1630.0), Vector2(220, 1630.0)],
			"hp_pickups": [Vector2(540, 1630.0)],
		},
		"spikes": [],
	}

# ─── 7. 격리 병동 (HORIZONTAL + 이스터에그 트리거) ──────────────
static func _ward() -> Dictionary:
	return {
		"world_type":   "HORIZONTAL",
		"world_size":   Vector2(4400.0, 720.0),
		"player_start": Vector2(140.0, 540.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(4320.0, 540.0),
		"camera_mode":  "HORIZONTAL",
		"platforms": [
			# 환기구 우회 (y=420)
			{"pos": Vector2(800, 460),  "w": 80.0},
			{"pos": Vector2(860, 420),  "w": 80.0},
			{"pos": Vector2(1000, 420), "w": 280.0},
			{"pos": Vector2(1380, 420), "w": 280.0},
			{"pos": Vector2(1760, 420), "w": 280.0},
			{"pos": Vector2(2140, 420), "w": 280.0},
			{"pos": Vector2(2520, 420), "w": 280.0},
			{"pos": Vector2(2900, 420), "w": 200.0},
			{"pos": Vector2(2960, 440), "w": 80.0},
			{"pos": Vector2(3020, 480), "w": 80.0},
			# 주 통로 장애물
			{"pos": Vector2(1200, 560), "w": 120.0},
			{"pos": Vector2(2000, 560), "w": 120.0},
			{"pos": Vector2(2800, 560), "w": 120.0},
		],
		"enemies": {
			"patrol": [Vector2(1800, 600.0), Vector2(2800, 600.0)],
			"sniper": [],
			"drone":  [],
			"bomber": [Vector2(3100, 600.0)],
			"shield": [Vector2(1300, 600.0), Vector2(2100, 600.0)],
		},
		"rewards": {
			"xp_orbs":    [],
			"hp_pickups": [Vector2(1800, 400.0)],
		},
		"spikes": [],
		# 잠긴 문 5초 체류 → 이스터에그 방 진입
		"easter_egg": {
			"trigger_x": 2000.0,
			"hold_seconds": 5.0,
			"veil_line": "그쪽은 임무 범위 밖이에요.",
		},
	}

# ─── 8. 데이터 센터 (ARENA, 웨이브) ───────────────────────────
# 지면 → step → mid(서버 랙) → step → 상층(드론) 단계화로 도달성 보장.
# waves 필드가 있으면 Stage._spawn_enemies가 웨이브 모드로 동작 (enemies는 폴백용).
# 웨이브 트리거: w2=w1 절반 처치 후, w3=w2 전원 처치 후. 모두 처치 시 ENEMY_CLEAR.
static func _datacenter() -> Dictionary:
	return {
		"world_type":   "ARENA",
		"world_size":   Vector2(1920.0, 900.0),
		"player_start": Vector2(200.0, 760.0),
		"goal_type":    "ENEMY_CLEAR",
		"goal_pos":     Vector2.ZERO,
		"camera_mode":  "FIXED",
		"ground_y":     820.0,
		"platforms": [
			# Step 발판 (지면 820 → mid 580 도약용, gap 100)
			{"pos": Vector2(150, 720),  "w": 100.0},
			{"pos": Vector2(450, 720),  "w": 100.0},
			{"pos": Vector2(750, 720),  "w": 100.0},
			{"pos": Vector2(1050, 720), "w": 100.0},
			{"pos": Vector2(1350, 720), "w": 100.0},
			{"pos": Vector2(1650, 720), "w": 100.0},
			# 서버 랙 (mid, y=580 — sniper 자리)
			{"pos": Vector2(200, 580),  "w": 280.0},
			{"pos": Vector2(600, 580),  "w": 280.0},
			{"pos": Vector2(1000, 580), "w": 280.0},
			{"pos": Vector2(1400, 580), "w": 280.0},
			# Step (mid → top, gap 120)
			{"pos": Vector2(400, 460),  "w": 100.0},
			{"pos": Vector2(800, 460),  "w": 100.0},
			{"pos": Vector2(1200, 460), "w": 100.0},
			# 상층 (drone 영역, gap 120)
			{"pos": Vector2(400, 340),  "w": 140.0},
			{"pos": Vector2(800, 340),  "w": 140.0},
			{"pos": Vector2(1200, 340), "w": 140.0},
			# 지면 잔해 (시각적 cover)
			{"pos": Vector2(500, 820),  "w": 100.0},
			{"pos": Vector2(1100, 820), "w": 100.0},
		],
		# waves: 트리거 조건과 함께 웨이브 단위 spawn.
		"waves": [
			{
				"trigger": "immediate",  # 진입 즉시
				"banner":  "WAVE 1",
				"enemies": {
					"patrol": [Vector2(400, 790.0), Vector2(1200, 790.0), Vector2(1700, 790.0)],
				},
			},
			{
				"trigger": "prev_half",  # 직전 웨이브 절반 처치 시
				"banner":  "WAVE 2",
				"enemies": {
					"sniper": [Vector2(200, 550.0), Vector2(1700, 550.0)],
					"drone":  [Vector2(960, 200.0)],
				},
			},
			{
				"trigger": "prev_clear",  # 직전 웨이브 전원 처치 시
				"banner":  "FINAL WAVE",
				"enemies": {
					"bomber": [Vector2(600, 790.0), Vector2(1400, 790.0)],
					"shield": [Vector2(960, 790.0)],
				},
			},
		],
		# 폴백 enemies (waves 미인식 환경에서도 비슷한 도전이 되도록 합집합 유지)
		"enemies": {
			"patrol": [Vector2(400, 790.0), Vector2(1200, 790.0), Vector2(1700, 790.0)],
			"sniper": [Vector2(200, 550.0), Vector2(1700, 550.0)],
			"drone":  [Vector2(960, 200.0)],
			"bomber": [Vector2(600, 790.0), Vector2(1400, 790.0)],
			"shield": [Vector2(960, 790.0)],
		},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		"spikes": [],
		"arena_clear_xp": 4,
	}

# ─── 9. 비상 탈출로 (HORIZONTAL, 짧음) ─────────────────────────
static func _escape() -> Dictionary:
	return {
		"world_type":   "HORIZONTAL",
		"world_size":   Vector2(3000.0, 720.0),
		"player_start": Vector2(140.0, 540.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(2880.0, 540.0),
		"camera_mode":  "HORIZONTAL",
		"platforms": [
			{"pos": Vector2(400, 520),  "w": 240.0},
			{"pos": Vector2(800, 480),  "w": 240.0},
			{"pos": Vector2(1200, 520), "w": 240.0},
			{"pos": Vector2(1600, 480), "w": 240.0},
			{"pos": Vector2(2000, 520), "w": 240.0},
			{"pos": Vector2(2400, 480), "w": 200.0},
		],
		"enemies": {
			"patrol": [Vector2(600, 600.0), Vector2(1400, 600.0), Vector2(2200, 600.0)],
			"sniper": [],
			"drone":  [Vector2(1600, 100.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		"spikes": [],
	}

# ─── 10. 핵심부 (ARENA, 보스 챔버) ────────────────────────────
# ground 820. 점프 단계화 — 지면 → mid step → 상단 보상.
# 보스 SENTINEL 단독 챔버 (DESIGN_world_layout §2.10). 일반 적은 spawn하지 않음 — 3페이즈 보스가 전부.
static func _lab() -> Dictionary:
	return {
		"world_type":   "ARENA",
		"world_size":   Vector2(1920.0, 900.0),
		"player_start": Vector2(200.0, 760.0),
		"goal_type":    "ENEMY_CLEAR",
		"goal_pos":     Vector2.ZERO,
		"camera_mode":  "FIXED",
		"ground_y":     820.0,
		"platforms": [
			# Step 발판 (지면 → mid 도약용)
			{"pos": Vector2(120, 700),  "w": 100.0},
			{"pos": Vector2(420, 700),  "w": 100.0},
			{"pos": Vector2(720, 700),  "w": 100.0},
			{"pos": Vector2(1080, 700), "w": 100.0},
			{"pos": Vector2(1380, 700), "w": 100.0},
			{"pos": Vector2(1700, 700), "w": 100.0},
			# Mid 발판 (피난처 — 폭격 회피용)
			{"pos": Vector2(220, 580),  "w": 200.0},
			{"pos": Vector2(620, 560),  "w": 180.0},
			{"pos": Vector2(960, 580),  "w": 200.0},
			{"pos": Vector2(1300, 560), "w": 180.0},
			{"pos": Vector2(1700, 580), "w": 200.0},
			# 상단 발판 — 보스와 같은 높이 사격용
			{"pos": Vector2(620, 420),  "w": 140.0},
			{"pos": Vector2(960, 380),  "w": 200.0},
			{"pos": Vector2(1300, 420), "w": 140.0},
			# 지면 잔해 (시각적 cover)
			{"pos": Vector2(500, 820),  "w": 120.0},
			{"pos": Vector2(1100, 820), "w": 120.0},
			{"pos": Vector2(1500, 820), "w": 120.0},
		],
		"enemies": {
			# 보스 챔버 — 일반 적 없음
			"patrol": [], "shield": [], "sniper": [], "drone": [], "bomber": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(960, 360.0), Vector2(1000, 360.0)],
			"hp_pickups": [],
		},
		"spikes": [],
		"arena_clear_xp": 6,
		"is_boss_room":   true,
		# 보스 메타 — Stage._spawn_boss가 인식해 BossSentinel을 spawn.
		"boss": {
			"type":  "sentinel",
			"spawn": Vector2(960.0, 280.0),  # 호버 라인 중앙 (BossSentinel.HOVER_Y와 일치)
		},
	}

# ─── 12. 도전 방 — 블랙아웃 런 (HORIZONTAL, 짧음, 노 데미지 30s) ──
# DESIGN_world_layout §3.2. Stage 4 분기 의도적 선택지.
# 강화: 좁은 발판(60~120px) + 가시 함정 + drone/bomber 압박 + 직선상 patrol 5.
# 1 hit fail이라 어떤 데미지도 즉시 실패 — "긴장감"은 정밀 이동 + 시야 제한에서 나옴.
static func _blackout() -> Dictionary:
	return {
		"world_type":   "HORIZONTAL",
		"world_size":   Vector2(2400.0, 720.0),
		"player_start": Vector2(140.0, 540.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(2280.0, 540.0),
		"camera_mode":  "HORIZONTAL",
		"platforms": [
			# 짧은 발판 7개 — 폭 줄여 정밀 점프 강제. gap 80~95.
			{"pos": Vector2(320, 540),  "w": 120.0},
			{"pos": Vector2(560, 480),  "w": 80.0},   # 매우 좁음 (정밀)
			{"pos": Vector2(820, 520),  "w": 100.0},
			{"pos": Vector2(1080, 460), "w": 80.0},   # 매우 좁음
			{"pos": Vector2(1340, 520), "w": 100.0},
			{"pos": Vector2(1620, 480), "w": 100.0},
			{"pos": Vector2(1900, 540), "w": 140.0},
			{"pos": Vector2(2160, 520), "w": 140.0},
		],
		"enemies": {
			# 지면 patrol 5 + bomber 1 압박 + 천장 drone 2 (폭탄 투하)
			"patrol": [
				Vector2(400, 600), Vector2(750, 600), Vector2(1100, 600),
				Vector2(1500, 600), Vector2(1850, 600),
			],
			"bomber": [Vector2(1300, 600)],
			"drone":  [Vector2(700, 100), Vector2(1700, 100)],
			"sniper": [], "shield": [],
		},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		# 발판 사이 갭 + 지면에 가시 (어두워서 잘 안 보임 → 시야 압박)
		"spikes": [
			{"x": 480.0, "y": 660.0},   # 지면 1
			{"x": 950.0, "y": 660.0},   # 지면 2
			{"x": 1450.0, "y": 660.0},  # 지면 3
			{"x": 1750.0, "y": 660.0},  # 지면 4
		],
		# Stage가 인식해 블랙아웃 + 30s 타이머 + 1 hit fail 적용.
		"challenge":          true,
		"challenge_time":     30.0,
		"challenge_xp_clear": 5,
	}

# ─── 11. ??? (HORIZONTAL, hidden archive 유지) ────────────────
static func _hidden() -> Dictionary:
	return {
		"world_type":   "HORIZONTAL",
		"world_size":   Vector2(4400.0, 720.0),
		"player_start": Vector2(140.0, 540.0),
		"goal_type":    "SEQUENCE",
		"goal_pos":     Vector2.ZERO,
		"camera_mode":  "HORIZONTAL",
		# hidden archive는 _build_hidden_archive가 별도로 처리. platforms/enemies 무시됨.
		"platforms": [],
		"enemies": {"patrol": [], "sniper": [], "drone": [], "bomber": [], "shield": []},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		"spikes": [],
	}
