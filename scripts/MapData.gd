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
# 도달성 보장: 각 발판 사이 gap ≤170px (이중점프로 도달 가능 ~190).
# 대부분 100~140 (단일 점프), 일부 160~170 (이중점프 요구).
static func _rooftops() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 저층 합류점(2440) — 6 발판, 각 100~120 gap
			{"pos": Vector2(560, 3000), "w": 200.0},  # gap 80 from ground
			{"pos": Vector2(640, 2880), "w": 200.0},  # 120
			{"pos": Vector2(560, 2760), "w": 180.0},  # 120
			{"pos": Vector2(640, 2640), "w": 180.0},
			{"pos": Vector2(540, 2520), "w": 180.0},
			{"pos": Vector2(640, 2440), "w": 200.0},  # 저층 메인
			# 저층 → 중층 (좌측 우회로) — 5 발판
			{"pos": Vector2(380, 2320), "w": 180.0},  # 120
			{"pos": Vector2(220, 2200), "w": 180.0},
			{"pos": Vector2(180, 2080), "w": 180.0},
			{"pos": Vector2(320, 1960), "w": 180.0},
			{"pos": Vector2(540, 1840), "w": 200.0},  # 중층 합류점
			# 중층 → 고층 우측 (노출/보상) — 5 발판
			{"pos": Vector2(760, 1720), "w": 160.0},  # gap 120
			{"pos": Vector2(900, 1600), "w": 160.0},
			{"pos": Vector2(960, 1480), "w": 160.0},
			{"pos": Vector2(900, 1360), "w": 160.0},
			{"pos": Vector2(1000, 1240), "w": 180.0}, # 고층 우측 (XP 보상)
			# 중층 → 고층 좌측 (안전 우회) — 5 발판 (1840→1240)
			{"pos": Vector2(360, 1720), "w": 180.0},
			{"pos": Vector2(220, 1600), "w": 180.0},
			{"pos": Vector2(160, 1480), "w": 180.0},
			{"pos": Vector2(260, 1360), "w": 180.0},
			{"pos": Vector2(180, 1240), "w": 200.0},  # 고층 좌측 (HP 보상)
			# 고층 → 정상 (단일 경로 합류) — 9 발판 (1240→200)
			{"pos": Vector2(540, 1120), "w": 200.0},
			{"pos": Vector2(640, 1000), "w": 180.0},
			{"pos": Vector2(540, 880),  "w": 180.0},
			{"pos": Vector2(640, 760),  "w": 180.0},
			{"pos": Vector2(540, 640),  "w": 180.0},
			{"pos": Vector2(640, 520),  "w": 180.0},
			{"pos": Vector2(540, 400),  "w": 180.0},
			{"pos": Vector2(640, 280),  "w": 220.0},  # 골 직전
		],
		"enemies": {
			# 적도 발판 위에 배치 (y는 발판 top 위 30px = patrol 발 위치)
			"patrol": [Vector2(640, 2410.0), Vector2(540, 1810.0), Vector2(640, 1090.0)],
			"sniper": [Vector2(1000, 1210.0), Vector2(180, 1210.0)],
			"drone":  [Vector2(640, 380.0)],  # 정상 직전
			"bomber": [], "shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(1000, 1210.0), Vector2(1040, 1210.0)],
			"hp_pickups": [Vector2(180, 1210.0)],
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
# 각 발판 사이 gap ≤170. 지그재그 상승은 발판이 좌우 번갈아 — 가로 점프(140) + 수직 100~140.
static func _cooling() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 지그재그 상승, 각 ~120 gap
			{"pos": Vector2(640, 2980), "w": 220.0},  # gap 100 from ground
			{"pos": Vector2(420, 2860), "w": 200.0},
			{"pos": Vector2(820, 2740), "w": 200.0},
			{"pos": Vector2(360, 2620), "w": 200.0},
			{"pos": Vector2(880, 2500), "w": 200.0},
			{"pos": Vector2(320, 2380), "w": 200.0},
			{"pos": Vector2(880, 2260), "w": 200.0},
			{"pos": Vector2(280, 2140), "w": 200.0},
			{"pos": Vector2(880, 2020), "w": 200.0},
			{"pos": Vector2(280, 1900), "w": 200.0},
			{"pos": Vector2(880, 1780), "w": 200.0},
			{"pos": Vector2(280, 1660), "w": 200.0},  # 분기점
			# 분기: 우측 파이프 (빠름, 드론 perch)
			{"pos": Vector2(900, 1540), "w": 120.0},
			{"pos": Vector2(960, 1400), "w": 120.0},
			{"pos": Vector2(900, 1260), "w": 120.0},
			{"pos": Vector2(960, 1120), "w": 120.0},
			{"pos": Vector2(900, 980),  "w": 120.0},
			{"pos": Vector2(960, 840),  "w": 140.0},  # 우측 끝 (XP 보상)
			# 분기: 좌측 계단 (안전, HP)
			{"pos": Vector2(280, 1540), "w": 180.0},
			{"pos": Vector2(180, 1400), "w": 180.0},
			{"pos": Vector2(260, 1260), "w": 180.0},
			{"pos": Vector2(160, 1120), "w": 180.0},
			{"pos": Vector2(260, 980),  "w": 180.0},
			{"pos": Vector2(180, 840),  "w": 200.0},  # 좌측 끝 (HP 보상)
			# 합류 후 단일 경로 → 정상
			{"pos": Vector2(540, 720),  "w": 220.0},
			{"pos": Vector2(640, 580),  "w": 200.0},
			{"pos": Vector2(540, 440),  "w": 200.0},
			{"pos": Vector2(640, 300),  "w": 200.0},
			{"pos": Vector2(640, 220),  "w": 240.0},  # 골 직전
		],
		"enemies": {
			"patrol": [Vector2(420, 2830.0), Vector2(880, 2230.0), Vector2(280, 1630.0)],
			"sniper": [Vector2(180, 810.0)],
			"drone":  [Vector2(960, 1380.0), Vector2(900, 1240.0)],  # 우측 파이프 perch (2마리)
			"bomber": [], "shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(960, 820.0), Vector2(1000, 820.0)],
			"hp_pickups": [Vector2(180, 820.0)],
		},
		"spikes": [],
	}

# ─── 6. 감시탑 (VERTICAL_UP, 3-tier) ──────────────────────────
# 각 발판 gap ≤140. 외부 노출 / 내부 계단 / 지하 통로 3분기.
static func _watchtower() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 분기점 1 — 6 발판
			{"pos": Vector2(560, 3000), "w": 200.0},  # 80
			{"pos": Vector2(640, 2880), "w": 200.0},
			{"pos": Vector2(560, 2760), "w": 200.0},
			{"pos": Vector2(640, 2640), "w": 200.0},
			{"pos": Vector2(560, 2520), "w": 200.0},
			{"pos": Vector2(640, 2400), "w": 220.0},  # 분기점 1
			# 외부 노출 루트 (좌측, sniper 노출 — XP 보상)
			{"pos": Vector2(380, 2280), "w": 180.0},
			{"pos": Vector2(220, 2160), "w": 180.0},
			{"pos": Vector2(120, 2040), "w": 180.0},
			{"pos": Vector2(120, 1920), "w": 180.0},
			{"pos": Vector2(120, 1800), "w": 180.0},
			{"pos": Vector2(120, 1680), "w": 180.0},
			{"pos": Vector2(180, 1560), "w": 200.0},  # 외부 끝 (XP 보상)
			# 내부 계단 루트 (중앙, 표준)
			{"pos": Vector2(540, 2280), "w": 200.0},
			{"pos": Vector2(640, 2160), "w": 200.0},
			{"pos": Vector2(540, 2040), "w": 200.0},
			{"pos": Vector2(640, 1920), "w": 200.0},
			{"pos": Vector2(540, 1800), "w": 200.0},
			{"pos": Vector2(640, 1680), "w": 200.0},
			{"pos": Vector2(540, 1560), "w": 200.0},  # 중앙 합류점
			# 합류 → 상단 (단일 경로)
			{"pos": Vector2(640, 1440), "w": 200.0},
			{"pos": Vector2(540, 1320), "w": 200.0},
			{"pos": Vector2(640, 1200), "w": 200.0},
			{"pos": Vector2(540, 1080), "w": 200.0},
			{"pos": Vector2(640, 960),  "w": 200.0},
			{"pos": Vector2(540, 840),  "w": 200.0},
			{"pos": Vector2(640, 720),  "w": 200.0},
			{"pos": Vector2(540, 600),  "w": 200.0},
			{"pos": Vector2(640, 480),  "w": 200.0},
			{"pos": Vector2(540, 360),  "w": 200.0},
			{"pos": Vector2(640, 240),  "w": 240.0},  # 골 직전
		],
		"enemies": {
			"patrol": [Vector2(640, 2370.0), Vector2(540, 2010.0), Vector2(640, 1650.0), Vector2(540, 1290.0)],
			"sniper": [Vector2(120, 2010.0), Vector2(120, 1770.0)],
			"drone":  [Vector2(640, 690.0), Vector2(540, 570.0)],
			"bomber": [],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(180, 1540.0), Vector2(220, 1540.0)],
			"hp_pickups": [Vector2(640, 1410.0)],  # 합류 후
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
		"enemies": {
			"patrol": [Vector2(400, 790.0), Vector2(1200, 790.0), Vector2(1700, 790.0)],
			"sniper": [Vector2(200, 550.0), Vector2(1700, 550.0)],  # 서버 랙 위
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
# 저격수 발판은 지면에서 mid step → 발판 도달 가능 (gap 모두 ≤170).
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
			# Mid 발판 (사격/저격 라인) — step에서 100~140 gap
			{"pos": Vector2(220, 580),  "w": 200.0},  # 좌 sniper 발판
			{"pos": Vector2(620, 560),  "w": 180.0},
			{"pos": Vector2(960, 580),  "w": 200.0},
			{"pos": Vector2(1300, 560), "w": 180.0},
			{"pos": Vector2(1700, 580), "w": 200.0}, # 우 sniper 발판
			# 상단 보상 발판 (mid에서 또 한번 점프)
			{"pos": Vector2(620, 420),  "w": 140.0},
			{"pos": Vector2(960, 380),  "w": 200.0},  # 중앙 상단 (XP 보상)
			{"pos": Vector2(1300, 420), "w": 140.0},
			# 지면 잔해 (시각적 cover)
			{"pos": Vector2(500, 820),  "w": 120.0},
			{"pos": Vector2(1100, 820), "w": 120.0},
			{"pos": Vector2(1500, 820), "w": 120.0},
		],
		"enemies": {
			# 지면 (ground 위) — patrol 2, shield 1 중앙
			"patrol": [Vector2(400, 790.0), Vector2(1500, 790.0)],
			"shield": [Vector2(960, 790.0)],
			# Mid 발판 위 — sniper 양쪽
			"sniper": [Vector2(220, 550.0), Vector2(1700, 550.0)],
			# 상단 — drone
			"drone":  [Vector2(960, 200.0)],
			"bomber": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(960, 360.0), Vector2(1000, 360.0)],
			"hp_pickups": [],
		},
		"spikes": [],
		"arena_clear_xp": 6,
		"is_boss_room":   true,
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
