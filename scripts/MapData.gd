class_name MapData
extends RefCounted

# 11개 맵의 platform/적 spawn/보상/함정 명세.
# DESIGN_map_layout.md 기반 (외부 클로드 답변 통합).
#
# 각 layout은 다음 구조의 Dictionary 반환:
#   "platforms": Array of {"pos": Vector2, "w": float}
#   "enemies":   Dictionary of {kind: Array of Vector2}  -- kind ∈ patrol/sniper/drone/bomber/shield
#   "rewards":   Dictionary of {"xp_orbs": Array of Vector2, "hp_pickups": Array of Vector2}
#   "spikes":    Array of {"x": float, "y": float}  -- y 생략 시 GROUND_Y - 6.0
#
# 좌표는 world space. y는 상단(천장)이 작고 GROUND_Y(=600)가 지면.

const GROUND_Y: float = 600.0
const STAGE_LENGTH: float = 4400.0

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
	return {}

# ─── 1. 외곽 진입로 (back_alley) ───────────────────────────────
# 튜토리얼급 단순 직선. 분기 없음.
static func _back_alley() -> Dictionary:
	return {
		"platforms": [
			{"pos": Vector2(400, 520),  "w": 160.0},
			{"pos": Vector2(700, 460),  "w": 160.0},
			{"pos": Vector2(1100, 520), "w": 200.0},
			{"pos": Vector2(1500, 460), "w": 160.0},
			{"pos": Vector2(1900, 520), "w": 200.0},
			{"pos": Vector2(2300, 460), "w": 160.0},
			{"pos": Vector2(2700, 520), "w": 200.0},
			{"pos": Vector2(3100, 460), "w": 160.0},
			{"pos": Vector2(3500, 520), "w": 160.0},
		],
		"enemies": {
			"patrol": [Vector2(900, GROUND_Y - 30.0), Vector2(1600, GROUND_Y - 30.0), Vector2(2400, GROUND_Y - 30.0)],
			"sniper": [], "drone": [], "bomber": [], "shield": [],
		},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		"spikes": [],
	}

# ─── 2. 외벽 옥상 (rooftops) ──────────────────────────────────
# 3층 수직 구조. 위로 갈수록 위험·보상 ↑. 내려가면 못 돌아옴.
static func _rooftops() -> Dictionary:
	return {
		"platforms": [
			# 1층 (안전)
			{"pos": Vector2(500, 540),  "w": 200.0},
			{"pos": Vector2(900, 540),  "w": 200.0},
			{"pos": Vector2(1400, 540), "w": 200.0},
			{"pos": Vector2(2000, 540), "w": 200.0},
			{"pos": Vector2(2600, 540), "w": 200.0},
			{"pos": Vector2(3200, 540), "w": 200.0},
			# 2층 (표준)
			{"pos": Vector2(600, 380),  "w": 200.0},
			{"pos": Vector2(1100, 380), "w": 180.0},
			{"pos": Vector2(1600, 380), "w": 200.0},
			{"pos": Vector2(2200, 380), "w": 200.0},
			{"pos": Vector2(2800, 380), "w": 200.0},
			{"pos": Vector2(3300, 380), "w": 200.0},
			# 3층 (노출/보상)
			{"pos": Vector2(800, 220),  "w": 160.0},
			{"pos": Vector2(1300, 220), "w": 140.0},
			{"pos": Vector2(1800, 220), "w": 160.0},
			{"pos": Vector2(2400, 220), "w": 140.0},
			{"pos": Vector2(3000, 220), "w": 160.0},
			# 2→3층 중간 발판
			{"pos": Vector2(720, 300),  "w": 60.0},
			{"pos": Vector2(1220, 300), "w": 60.0},
			{"pos": Vector2(1920, 300), "w": 60.0},
		],
		"enemies": {
			"patrol": [Vector2(800, GROUND_Y - 30.0), Vector2(1700, GROUND_Y - 30.0), Vector2(2700, GROUND_Y - 30.0)],
			"sniper": [Vector2(1000, 200.0), Vector2(2200, 200.0)],
			"drone":  [Vector2(1500, 140.0), Vector2(2500, 140.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(1800, 200.0), Vector2(1830, 200.0)],
			"hp_pickups": [],
		},
		"spikes": [],
	}

# ─── 3. 지하 인입로 (sewers) ─────────────────────────────────
# 깊이 하강. 상단=좁고 빠름, 하단=넓지만 함정/보상.
static func _sewers() -> Dictionary:
	return {
		"platforms": [
			# 분기 진입 발판
			{"pos": Vector2(600, 460),  "w": 80.0},
			{"pos": Vector2(650, 420),  "w": 80.0},
			# 상단 루트 (빠른 우회)
			{"pos": Vector2(700, 420),  "w": 300.0},
			{"pos": Vector2(1100, 420), "w": 200.0},
			{"pos": Vector2(1400, 380), "w": 120.0},
			{"pos": Vector2(1600, 420), "w": 200.0},
			{"pos": Vector2(1900, 400), "w": 120.0},
			{"pos": Vector2(2100, 420), "w": 300.0},
			{"pos": Vector2(2500, 420), "w": 200.0},
			{"pos": Vector2(2800, 440), "w": 300.0},
			{"pos": Vector2(3200, 420), "w": 200.0},
			# 합류 발판 (상→골)
			{"pos": Vector2(3300, 460), "w": 160.0},
			{"pos": Vector2(3400, 520), "w": 200.0},
		],
		"enemies": {
			"patrol": [Vector2(1000, 400.0), Vector2(1700, 400.0), Vector2(1400, GROUND_Y - 30.0), Vector2(2000, GROUND_Y - 30.0), Vector2(2600, GROUND_Y - 30.0)],
			"sniper": [],
			"drone":  [],
			"bomber": [Vector2(1600, GROUND_Y - 30.0), Vector2(2200, GROUND_Y - 30.0)],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(2750, GROUND_Y - 40.0), Vector2(2810, GROUND_Y - 40.0)],
			"hp_pickups": [Vector2(2000, 400.0)],
		},
		"spikes": [
			{"x": 1200, "y": GROUND_Y - 6.0},
			{"x": 1800, "y": GROUND_Y - 6.0},
			{"x": 2400, "y": GROUND_Y - 6.0},
		],
	}

# ─── 4. 폐쇄 지하철 (subway) ─────────────────────────────────
# 열차 지붕 vs 지면. 천장 낮음.
static func _subway() -> Dictionary:
	return {
		"platforms": [
			# 객차 지붕
			{"pos": Vector2(800, 380),  "w": 600.0},
			{"pos": Vector2(1800, 380), "w": 600.0},
			{"pos": Vector2(2800, 380), "w": 400.0},
			# 지붕 진입 발판 (객차 측면)
			{"pos": Vector2(750, 480),  "w": 60.0},
			{"pos": Vector2(780, 420),  "w": 60.0},
			{"pos": Vector2(1750, 480), "w": 60.0},
			{"pos": Vector2(1780, 420), "w": 60.0},
			# 지면 잔해
			{"pos": Vector2(500, 560),  "w": 120.0},
			{"pos": Vector2(1500, 540), "w": 100.0},
			{"pos": Vector2(2500, 560), "w": 100.0},
			{"pos": Vector2(3300, 560), "w": 120.0},
		],
		"enemies": {
			"patrol": [Vector2(1000, GROUND_Y - 30.0), Vector2(2000, GROUND_Y - 30.0), Vector2(3000, GROUND_Y - 30.0)],
			"sniper": [Vector2(1200, 360.0), Vector2(2000, 360.0)],
			"drone":  [],
			"bomber": [],
			"shield": [Vector2(1600, GROUND_Y - 30.0), Vector2(2600, GROUND_Y - 30.0)],
		},
		"rewards": {
			"xp_orbs":    [Vector2(2000, 360.0), Vector2(2030, 360.0)],
			"hp_pickups": [],
		},
		"spikes": [],
	}

# ─── 5. 냉각 시설 (cooling) ──────────────────────────────────
# 수직 상승 — 좌측 파이프(빠름/위험) vs 우측 계단(넓고 안전).
static func _cooling() -> Dictionary:
	return {
		"platforms": [
			# 분기 전 공통 발판
			{"pos": Vector2(600, 520),  "w": 100.0},
			# 우측 계단 루트 (안전, 차근차근 상승)
			{"pos": Vector2(700, 520),  "w": 200.0},
			{"pos": Vector2(1000, 460), "w": 200.0},
			{"pos": Vector2(1300, 400), "w": 200.0},
			{"pos": Vector2(1600, 340), "w": 200.0},
			{"pos": Vector2(1900, 280), "w": 200.0},
			{"pos": Vector2(2200, 220), "w": 200.0},
			{"pos": Vector2(2600, 200), "w": 200.0},
			{"pos": Vector2(3000, 200), "w": 200.0},
			{"pos": Vector2(3300, 200), "w": 200.0},
			# 좌측 파이프 루트 (좁은 발판 빠른 상승)
			{"pos": Vector2(600, 480),  "w": 80.0},
			{"pos": Vector2(680, 400),  "w": 80.0},
			{"pos": Vector2(760, 320),  "w": 80.0},
			{"pos": Vector2(840, 240),  "w": 80.0},
			{"pos": Vector2(920, 180),  "w": 80.0},
		],
		"enemies": {
			"patrol": [Vector2(1200, 380.0), Vector2(1800, 260.0), Vector2(2400, 200.0)],
			"sniper": [Vector2(2000, 200.0)],
			"drone":  [Vector2(900, 160.0), Vector2(1100, 140.0), Vector2(2000, 160.0), Vector2(2800, 160.0)],
			"bomber": [],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(900, 160.0), Vector2(940, 160.0)],
			"hp_pickups": [Vector2(3100, 180.0)],
		},
		"spikes": [],
	}

# ─── 6. 감시탑 (watchtower) ──────────────────────────────────
# 3-tier 데드셀 전형. 상=노출/보상, 중=표준, 하=빠른 통과/HP.
static func _watchtower() -> Dictionary:
	return {
		"platforms": [
			# 상단 (y=180)
			{"pos": Vector2(700, 180),  "w": 180.0},
			{"pos": Vector2(1000, 160), "w": 160.0},
			{"pos": Vector2(1300, 180), "w": 180.0},
			{"pos": Vector2(1700, 160), "w": 160.0},
			{"pos": Vector2(2100, 180), "w": 180.0},
			{"pos": Vector2(2500, 160), "w": 160.0},
			{"pos": Vector2(2900, 180), "w": 180.0},
			{"pos": Vector2(3200, 180), "w": 200.0},
			# 중단 (y=380)
			{"pos": Vector2(700, 380),  "w": 220.0},
			{"pos": Vector2(1100, 360), "w": 200.0},
			{"pos": Vector2(1500, 380), "w": 220.0},
			{"pos": Vector2(1900, 360), "w": 200.0},
			{"pos": Vector2(2300, 380), "w": 220.0},
			{"pos": Vector2(2700, 360), "w": 200.0},
			{"pos": Vector2(3100, 380), "w": 220.0},
			# 하단 (지면 위 낮은 발판)
			{"pos": Vector2(600, 560),  "w": 200.0},
			{"pos": Vector2(1000, 560), "w": 200.0},
			{"pos": Vector2(1500, 560), "w": 200.0},
			{"pos": Vector2(2000, 560), "w": 200.0},
			{"pos": Vector2(2500, 560), "w": 200.0},
			{"pos": Vector2(3000, 560), "w": 200.0},
			# 중→상 진입 발판
			{"pos": Vector2(640, 280),  "w": 60.0},
			{"pos": Vector2(680, 220),  "w": 60.0},
		],
		"enemies": {
			"patrol": [Vector2(1200, 340.0), Vector2(2000, 340.0), Vector2(2800, 340.0), Vector2(1000, GROUND_Y - 30.0), Vector2(2000, GROUND_Y - 30.0), Vector2(3000, GROUND_Y - 30.0)],
			"sniper": [Vector2(1000, 140.0), Vector2(2300, 140.0)],
			"drone":  [Vector2(1500, 100.0), Vector2(2500, 100.0)],
			"bomber": [],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(2100, 140.0), Vector2(2150, 140.0)],
			"hp_pickups": [Vector2(2000, 540.0)],
		},
		"spikes": [],
	}

# ─── 7. 격리 병동 (ward) ─────────────────────────────────────
# 수평 미로형. 주통로(방패병) vs 환기구 우회(은폐/HP). ??? 복선.
static func _ward() -> Dictionary:
	return {
		"platforms": [
			# 주 통로 (낮은 발판 — 좁은 복도 느낌)
			{"pos": Vector2(400, 560),  "w": 200.0},
			{"pos": Vector2(700, 560),  "w": 180.0},
			# 환기구 진입
			{"pos": Vector2(800, 460),  "w": 80.0},
			{"pos": Vector2(860, 420),  "w": 80.0},
			# 환기구 내부
			{"pos": Vector2(1000, 420), "w": 300.0},
			{"pos": Vector2(1400, 420), "w": 300.0},
			{"pos": Vector2(1800, 420), "w": 300.0},
			{"pos": Vector2(2200, 420), "w": 300.0},
			{"pos": Vector2(2600, 420), "w": 200.0},
			# 환기구 탈출
			{"pos": Vector2(2900, 440), "w": 80.0},
			{"pos": Vector2(2960, 480), "w": 80.0},
			# 주 통로 후반
			{"pos": Vector2(3100, 560), "w": 200.0},
			{"pos": Vector2(3400, 560), "w": 200.0},
		],
		"enemies": {
			"patrol": [Vector2(1800, GROUND_Y - 30.0), Vector2(2800, GROUND_Y - 30.0)],
			"sniper": [],
			"drone":  [],
			"bomber": [Vector2(3000, GROUND_Y - 30.0)],
			"shield": [Vector2(1300, GROUND_Y - 30.0), Vector2(2100, GROUND_Y - 30.0)],
		},
		"rewards": {
			"xp_orbs":    [],
			"hp_pickups": [Vector2(1800, 400.0)],
		},
		"spikes": [],
	}

# ─── 8. 데이터 센터 (datacenter) ─────────────────────────────
# 3층 격자 — 지면(좁은 통로)/중층(서버 랙)/상층(드론 영역).
static func _datacenter() -> Dictionary:
	return {
		"platforms": [
			# 중층 (서버 랙 위) — 80px 갭 유지
			{"pos": Vector2(600, 400),  "w": 280.0},
			{"pos": Vector2(1000, 400), "w": 280.0},
			{"pos": Vector2(1400, 400), "w": 280.0},
			{"pos": Vector2(1800, 400), "w": 280.0},
			{"pos": Vector2(2200, 400), "w": 280.0},
			{"pos": Vector2(2600, 400), "w": 280.0},
			{"pos": Vector2(3000, 400), "w": 280.0},
			{"pos": Vector2(3300, 400), "w": 200.0},
			# 상층 (드론 영역)
			{"pos": Vector2(900, 220),  "w": 120.0},
			{"pos": Vector2(1600, 220), "w": 120.0},
			{"pos": Vector2(2300, 220), "w": 120.0},
			{"pos": Vector2(3000, 220), "w": 120.0},
			# 중→상 연결
			{"pos": Vector2(880, 320),  "w": 60.0},
			{"pos": Vector2(1580, 320), "w": 60.0},
			# 지면 발판 (낮은 장애물)
			{"pos": Vector2(500, 560),  "w": 100.0},
			{"pos": Vector2(1200, 560), "w": 100.0},
			{"pos": Vector2(2000, 560), "w": 100.0},
			{"pos": Vector2(2800, 560), "w": 100.0},
		],
		"enemies": {
			"patrol": [Vector2(800, GROUND_Y - 30.0), Vector2(1600, GROUND_Y - 30.0), Vector2(2400, GROUND_Y - 30.0), Vector2(3000, GROUND_Y - 30.0)],
			"sniper": [Vector2(1200, 380.0), Vector2(2400, 380.0)],
			"drone":  [Vector2(1000, 140.0), Vector2(1800, 140.0), Vector2(2600, 140.0)],
			"bomber": [Vector2(1400, GROUND_Y - 30.0), Vector2(2200, GROUND_Y - 30.0)],
			"shield": [],
		},
		"rewards": {
			"xp_orbs":    [Vector2(1800, 200.0), Vector2(1840, 200.0)],
			"hp_pickups": [Vector2(2600, GROUND_Y - 40.0)],
		},
		"spikes": [],
	}

# ─── 9. 비상 탈출로 (escape) ─────────────────────────────────
# 의도된 단순함 — ACT 3 숨 고르기. 분기 없음.
static func _escape() -> Dictionary:
	return {
		"platforms": [
			{"pos": Vector2(500, 520),  "w": 240.0},
			{"pos": Vector2(900, 480),  "w": 240.0},
			{"pos": Vector2(1400, 520), "w": 240.0},
			{"pos": Vector2(1900, 480), "w": 240.0},
			{"pos": Vector2(2400, 520), "w": 240.0},
			{"pos": Vector2(2900, 480), "w": 240.0},
			{"pos": Vector2(3300, 520), "w": 200.0},
		],
		"enemies": {
			"patrol": [Vector2(1000, GROUND_Y - 30.0), Vector2(2000, GROUND_Y - 30.0), Vector2(3000, GROUND_Y - 30.0)],
			"sniper": [],
			"drone":  [Vector2(2200, 140.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {"xp_orbs": [], "hp_pickups": []},
		"spikes": [],
	}

# ─── 10. 핵심부 (lab) ────────────────────────────────────────
# 보스 챔버. 다층(메인+상단 숨은 길) + 지면 함정.
static func _lab() -> Dictionary:
	return {
		"platforms": [
			# 메인 전장 (y=420)
			{"pos": Vector2(600, 420),  "w": 280.0},
			{"pos": Vector2(1000, 400), "w": 240.0},
			{"pos": Vector2(1400, 420), "w": 280.0},
			{"pos": Vector2(1800, 400), "w": 240.0},
			{"pos": Vector2(2200, 420), "w": 280.0},
			{"pos": Vector2(2600, 400), "w": 240.0},
			{"pos": Vector2(3000, 420), "w": 280.0},
			{"pos": Vector2(3300, 420), "w": 200.0},
			# 상단 통로
			{"pos": Vector2(800, 240),  "w": 160.0},
			{"pos": Vector2(1200, 220), "w": 120.0},
			{"pos": Vector2(1600, 240), "w": 160.0},
			{"pos": Vector2(2000, 220), "w": 120.0},
			{"pos": Vector2(2400, 240), "w": 160.0},
			{"pos": Vector2(2800, 220), "w": 120.0},
			{"pos": Vector2(3100, 240), "w": 160.0},
			# 메인→상단 진입 발판
			{"pos": Vector2(740, 340),  "w": 60.0},
			{"pos": Vector2(780, 280),  "w": 60.0},
		],
		"enemies": {
			"patrol": [Vector2(1600, 380.0), Vector2(2200, 380.0), Vector2(2800, 380.0), Vector2(1000, GROUND_Y - 30.0), Vector2(2000, GROUND_Y - 30.0)],
			"sniper": [Vector2(1200, 380.0), Vector2(2400, 380.0), Vector2(1600, 220.0)],
			"drone":  [Vector2(1000, 160.0), Vector2(2000, 160.0), Vector2(3000, 160.0)],
			"bomber": [Vector2(2000, GROUND_Y - 30.0)],
			"shield": [Vector2(3000, 380.0)],
		},
		"rewards": {
			"xp_orbs":    [Vector2(2000, 200.0), Vector2(2050, 200.0)],
			"hp_pickups": [],
		},
		"spikes": [
			{"x": 1600, "y": GROUND_Y - 6.0},
			{"x": 2400, "y": GROUND_Y - 6.0},
		],
	}
