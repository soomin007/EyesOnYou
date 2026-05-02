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
static func _rooftops() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상 → 저층
			{"pos": Vector2(560, 2800), "w": 160.0},
			{"pos": Vector2(640, 2600), "w": 160.0},
			{"pos": Vector2(560, 2400), "w": 200.0},
			# 저층 → 중층
			{"pos": Vector2(200, 2200), "w": 160.0},
			{"pos": Vector2(400, 2000), "w": 180.0},
			{"pos": Vector2(640, 1700), "w": 200.0},
			# 중층 → 고층 우측 직등 (노출/보상)
			{"pos": Vector2(900, 1500), "w": 120.0},
			{"pos": Vector2(960, 1300), "w": 120.0},
			{"pos": Vector2(900, 1100), "w": 160.0},
			{"pos": Vector2(960, 1000), "w": 180.0},
			# 중층 → 고층 좌측 우회 (안전)
			{"pos": Vector2(200, 1500), "w": 140.0},
			{"pos": Vector2(160, 1300), "w": 140.0},
			{"pos": Vector2(240, 1100), "w": 160.0},
			{"pos": Vector2(200, 1000), "w": 180.0},
			# 고층 → 정상
			{"pos": Vector2(560, 800), "w": 160.0},
			{"pos": Vector2(640, 600), "w": 160.0},
			{"pos": Vector2(560, 400), "w": 160.0},
			{"pos": Vector2(640, 280), "w": 200.0},
		],
		"enemies": {
			"patrol": [Vector2(640, 3000.0), Vector2(500, 2380.0), Vector2(640, 1680.0)],
			"sniper": [Vector2(960, 980.0), Vector2(300, 980.0)],
			"drone":  [Vector2(640, 260.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(960, 960.0), Vector2(1000, 960.0)],
			"hp_pickups": [Vector2(200, 960.0)],
		},
		"spikes": [],
	}

# ─── 3. 지하 인입로 (VERTICAL_DOWN) ───────────────────────────
static func _sewers() -> Dictionary:
	return {
		"world_type":   "VERTICAL_DOWN",
		"world_size":   Vector2(1280.0, 2400.0),
		"player_start": Vector2(640.0, 160.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 2250.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 진입 → 상층
			{"pos": Vector2(560, 200), "w": 160.0},
			{"pos": Vector2(560, 400), "w": 120.0},
			{"pos": Vector2(480, 600), "w": 200.0},
			# 좌측 — 넓은 통로 (적 많음, XP 보상)
			{"pos": Vector2(200, 900),  "w": 220.0},
			{"pos": Vector2(160, 1100), "w": 200.0},
			{"pos": Vector2(200, 1200), "w": 240.0},
			# 우측 — 좁은 파이프 (함정, HP 회복)
			{"pos": Vector2(960, 800),   "w": 80.0},
			{"pos": Vector2(1000, 950),  "w": 80.0},
			{"pos": Vector2(960, 1100),  "w": 80.0},
			{"pos": Vector2(1000, 1200), "w": 80.0},
			# 합류 → 하층
			{"pos": Vector2(560, 1400), "w": 160.0},
			{"pos": Vector2(480, 1600), "w": 200.0},
			{"pos": Vector2(560, 1800), "w": 240.0},
			# 하층 → 바닥
			{"pos": Vector2(480, 2000), "w": 200.0},
			{"pos": Vector2(560, 2100), "w": 240.0},
		],
		"enemies": {
			"patrol": [Vector2(200, 880.0), Vector2(160, 1080.0)],
			"sniper": [],
			"drone":  [],
			"bomber": [Vector2(480, 1780.0), Vector2(640, 1780.0)],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(200, 1160.0), Vector2(240, 1160.0)],
			"hp_pickups": [Vector2(1000, 1160.0)],
		},
		"spikes": [
			{"x": 960, "y": 880.0 - 6.0},
			{"x": 1000, "y": 1020.0 - 6.0},
			{"x": 960, "y": 1160.0 - 6.0},
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
static func _cooling() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(560.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지그재그 상승 (좌우 번갈아)
			{"pos": Vector2(800, 2800), "w": 200.0},
			{"pos": Vector2(320, 2500), "w": 200.0},
			{"pos": Vector2(880, 2200), "w": 180.0},
			{"pos": Vector2(260, 1900), "w": 180.0},
			{"pos": Vector2(860, 1600), "w": 180.0},
			{"pos": Vector2(280, 1300), "w": 180.0},
			# 분기: 우측 파이프 (빠름, 드론 밀집)
			{"pos": Vector2(900, 1100), "w": 80.0},
			{"pos": Vector2(960, 900),  "w": 80.0},
			{"pos": Vector2(900, 700),  "w": 80.0},
			{"pos": Vector2(960, 500),  "w": 80.0},
			{"pos": Vector2(900, 300),  "w": 100.0},
			# 분기: 좌측 계단 (느림, 안전)
			{"pos": Vector2(200, 1100), "w": 160.0},
			{"pos": Vector2(160, 900),  "w": 160.0},
			{"pos": Vector2(240, 700),  "w": 160.0},
			{"pos": Vector2(200, 500),  "w": 160.0},
			{"pos": Vector2(160, 300),  "w": 160.0},
			# 합류 (골 직전)
			{"pos": Vector2(560, 200), "w": 200.0},
		],
		"enemies": {
			"patrol": [Vector2(800, 2780.0), Vector2(260, 1880.0), Vector2(280, 1280.0)],
			"sniper": [Vector2(200, 480.0)],
			"drone":  [Vector2(960, 860.0), Vector2(900, 660.0), Vector2(960, 460.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(900, 680.0), Vector2(940, 680.0)],
			"hp_pickups": [Vector2(200, 480.0)],
		},
		"spikes": [],
	}

# ─── 6. 감시탑 (VERTICAL_UP, 3-tier) ──────────────────────────
static func _watchtower() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 240.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 시작 → 분기점 1
			{"pos": Vector2(560, 2800), "w": 200.0},
			{"pos": Vector2(640, 2600), "w": 160.0},
			{"pos": Vector2(560, 2400), "w": 200.0},
			# 외부 노출 루트 (좌측)
			{"pos": Vector2(100, 2200), "w": 140.0},
			{"pos": Vector2(80, 2000),  "w": 140.0},
			{"pos": Vector2(100, 1800), "w": 140.0},
			{"pos": Vector2(80, 1600),  "w": 140.0},
			# 내부 계단 루트 (중앙)
			{"pos": Vector2(520, 2200), "w": 200.0},
			{"pos": Vector2(560, 2000), "w": 180.0},
			{"pos": Vector2(520, 1800), "w": 200.0},
			{"pos": Vector2(560, 1600), "w": 180.0},
			# 지하 통로 (단일 평면)
			{"pos": Vector2(640, 2900), "w": 880.0},
			# 합류 → 상단
			{"pos": Vector2(560, 1400), "w": 200.0},
			{"pos": Vector2(520, 1200), "w": 200.0},
			{"pos": Vector2(560, 1000), "w": 180.0},
			{"pos": Vector2(520, 800),  "w": 200.0},
			# 단일 경로 (분기점 3 이후)
			{"pos": Vector2(560, 600),  "w": 180.0},
			{"pos": Vector2(520, 400),  "w": 200.0},
			{"pos": Vector2(560, 240),  "w": 160.0},
		],
		"enemies": {
			"patrol": [Vector2(540, 1980.0), Vector2(560, 1580.0), Vector2(540, 1180.0)],
			"sniper": [Vector2(80, 1960.0), Vector2(100, 1560.0)],
			"drone":  [Vector2(560, 760.0), Vector2(520, 560.0)],
			"bomber": [Vector2(500, 2880.0), Vector2(700, 2880.0)],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(80, 1540.0), Vector2(120, 1540.0)],
			"hp_pickups": [Vector2(640, 2880.0)],
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
			# 서버 랙 (y=560)
			{"pos": Vector2(200, 560),  "w": 280.0},
			{"pos": Vector2(600, 560),  "w": 280.0},
			{"pos": Vector2(1000, 560), "w": 280.0},
			{"pos": Vector2(1400, 560), "w": 280.0},
			# 상층 접근 발판
			{"pos": Vector2(400, 360),  "w": 120.0},
			{"pos": Vector2(800, 360),  "w": 120.0},
			{"pos": Vector2(1200, 360), "w": 120.0},
			# 지면 장애물
			{"pos": Vector2(500, 820),  "w": 100.0},
			{"pos": Vector2(1100, 820), "w": 100.0},
		],
		# ARENA: 모든 적을 한 번에 spawn (P0). 웨이브 시스템은 P1.
		"enemies": {
			"patrol": [Vector2(400, 840.0), Vector2(1200, 840.0), Vector2(1700, 840.0)],
			"sniper": [Vector2(200, 540.0), Vector2(1700, 540.0)],
			"drone":  [Vector2(960, 100.0)],
			"bomber": [Vector2(600, 840.0), Vector2(1400, 840.0)],
			"shield": [Vector2(960, 840.0)],
		},
		"rewards": {
			"xp_orbs":    [],  # 클리어 보너스로 별도 지급
			"hp_pickups": [],
		},
		"spikes": [],
		"arena_clear_xp": 4,  # 클리어 시 보너스 XP
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

# ─── 10. 핵심부 (ARENA, 보스 SENTINEL) ────────────────────────
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
			# 피난처 발판
			{"pos": Vector2(200, 560),  "w": 200.0},
			{"pos": Vector2(600, 400),  "w": 160.0},
			{"pos": Vector2(960, 560),  "w": 200.0},
			{"pos": Vector2(1360, 400), "w": 160.0},
			{"pos": Vector2(1720, 560), "w": 200.0},
			# 중앙 높은 발판 (보스와 같은 높이)
			{"pos": Vector2(760, 260),  "w": 400.0},
			# 지면 잔해
			{"pos": Vector2(500, 820),  "w": 120.0},
			{"pos": Vector2(1100, 820), "w": 120.0},
			{"pos": Vector2(1500, 820), "w": 120.0},
		],
		"enemies": {
			# P0 단계: 보스 미구현 — 일반 적 강화 조합으로 대체.
			# P1에서 SENTINEL 보스로 교체 예정.
			"patrol": [Vector2(400, 840.0), Vector2(1500, 840.0)],
			"sniper": [Vector2(200, 540.0), Vector2(1700, 540.0)],
			"drone":  [Vector2(960, 100.0)],
			"bomber": [],
			"shield": [Vector2(960, 840.0)],
		},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		"spikes": [],
		"arena_clear_xp": 6,  # 보스급이라 보너스 ↑
		"is_boss_room":   true,  # P1 SENTINEL 도입 시 사용 예정
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
