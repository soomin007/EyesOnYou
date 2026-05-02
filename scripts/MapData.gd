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
# 진짜 수직 — 시작에서 한 번 올라가고, 상단 통로를 traversal, 마지막에 계단으로 하강.
# 한 번 위로 올라가지 못하면 망하던 구조 → 중간에 다시 올라갈 수 있는 mid climb 1개 추가.
# 드론은 상단 perch에서. 지면도 통과 가능 (단 드론 폭격 압박).
static func _cooling() -> Dictionary:
	return {
		"platforms": [
			# 첫 climb (x=550~650 vertical stack) — 부드러운 단차
			{"pos": Vector2(580, 540),  "w": 140.0},
			{"pos": Vector2(580, 460),  "w": 120.0},
			{"pos": Vector2(580, 380),  "w": 120.0},
			{"pos": Vector2(580, 300),  "w": 120.0},
			{"pos": Vector2(580, 220),  "w": 140.0},
			# 상단 horizontal 통로 (y=220 일직선) — drone perch 위치
			{"pos": Vector2(820, 220),  "w": 200.0},
			{"pos": Vector2(1100, 220), "w": 200.0},
			{"pos": Vector2(1400, 220), "w": 200.0},
			{"pos": Vector2(1700, 220), "w": 200.0},
			{"pos": Vector2(2000, 220), "w": 200.0},
			{"pos": Vector2(2300, 220), "w": 200.0},
			{"pos": Vector2(2600, 220), "w": 200.0},
			# 중간 climb (x=2000) — 떨어졌다가 다시 올라올 수 있게. 좁고 짧음.
			{"pos": Vector2(2000, 540), "w": 120.0},
			{"pos": Vector2(2000, 440), "w": 100.0},
			{"pos": Vector2(2000, 340), "w": 100.0},
			# 하강 stairs (상단 → ground)
			{"pos": Vector2(2900, 300), "w": 200.0},
			{"pos": Vector2(3200, 380), "w": 200.0},
			{"pos": Vector2(3500, 460), "w": 200.0},
			{"pos": Vector2(3800, 540), "w": 200.0},
			# ground 통로 발판 (드론 폭격 회피용 안전 지대)
			{"pos": Vector2(1100, 560), "w": 200.0},
			{"pos": Vector2(1500, 560), "w": 200.0},
			{"pos": Vector2(2400, 560), "w": 200.0},
			{"pos": Vector2(2800, 560), "w": 200.0},
		],
		"enemies": {
			# 상단 perch에 patrol — 플레이어가 올라가서 처치
			"patrol": [Vector2(1200, 200.0), Vector2(2400, 200.0)],
			# 저격수 1마리 — 상단 한쪽
			"sniper": [Vector2(2700, 200.0)],
			# 드론 2마리만 (이전 4 → 2). 상단 천장에 perch.
			"drone":  [Vector2(1500, 140.0), Vector2(2200, 140.0)],
			"bomber": [],
			"shield": [],
		},
		"rewards": {
			# 상단 끝부분에 XP — 위로 끝까지 traverse한 보상
			"xp_orbs":    [Vector2(2600, 200.0), Vector2(2640, 200.0)],
			# 중간 climb 위에 HP — 떨어졌다 다시 올라가는 사람 보상
			"hp_pickups": [Vector2(2000, 320.0)],
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
# 좁고 어두운 단일 복도. 평탄한 진행 — 사격 라인을 막는 천장 발판 없음.
# 분기는 짧은 우회 발판 1개로 단순화 (HP 보상). 스토리 톤이 핵심 — 복선 트리거를 일찍.
static func _ward() -> Dictionary:
	return {
		"platforms": [
			# 단일 ground 복도 — 낮은 발판으로 조명/구획 표시
			{"pos": Vector2(400, 560),  "w": 240.0},
			{"pos": Vector2(800, 560),  "w": 240.0},
			{"pos": Vector2(1200, 560), "w": 240.0},
			{"pos": Vector2(1600, 560), "w": 240.0},
			{"pos": Vector2(2000, 560), "w": 240.0},
			{"pos": Vector2(2400, 560), "w": 240.0},
			{"pos": Vector2(2800, 560), "w": 240.0},
			{"pos": Vector2(3200, 560), "w": 240.0},
			{"pos": Vector2(3600, 560), "w": 200.0},
			# 짧은 우회 발판 (HP 보상) — 메인 복도에서 살짝 위로
			{"pos": Vector2(2400, 460), "w": 200.0},
		],
		"enemies": {
			"patrol": [Vector2(1500, GROUND_Y - 30.0), Vector2(3000, GROUND_Y - 30.0)],
			"sniper": [],
			"drone":  [],
			"bomber": [Vector2(2700, GROUND_Y - 30.0)],
			# 방패병 2마리 — 좁은 복도에서 정면 차단
			"shield": [Vector2(1800, GROUND_Y - 30.0), Vector2(2400, GROUND_Y - 30.0)],
		},
		"rewards": {
			"xp_orbs":    [],
			"hp_pickups": [Vector2(2400, 440.0)],
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
# 보스 챔버 — 넓은 ground 아레나가 메인. 사격 라인 막는 천장 발판 최소.
# 측면 우회 mid platform 몇 개 + 끝부분 상단 보상 발판. 함정은 입구 부근에만.
static func _lab() -> Dictionary:
	return {
		"platforms": [
			# Ground 발판 (메인 전장 — 넓고 평탄)
			{"pos": Vector2(500, 540),  "w": 280.0},
			{"pos": Vector2(900, 540),  "w": 280.0},
			{"pos": Vector2(1400, 540), "w": 280.0},
			{"pos": Vector2(1900, 540), "w": 280.0},
			{"pos": Vector2(2400, 540), "w": 280.0},
			{"pos": Vector2(2900, 540), "w": 280.0},
			{"pos": Vector2(3400, 540), "w": 280.0},
			# Mid platform — 측면 사격 라인 (3개만, sparse)
			{"pos": Vector2(1200, 400), "w": 200.0},
			{"pos": Vector2(2100, 400), "w": 200.0},
			{"pos": Vector2(3000, 400), "w": 200.0},
			# 상단 보상 발판 — 챔버 후반에 단 1개. 진입 발판 1단계
			{"pos": Vector2(2900, 280), "w": 180.0},
			{"pos": Vector2(2900, 360), "w": 100.0},  # mid → top 진입 발판
		],
		"enemies": {
			# Ground 메인 전장 (drone은 후반 등장 컨셉이라 1마리만)
			"patrol": [Vector2(1100, GROUND_Y - 30.0), Vector2(1700, GROUND_Y - 30.0), Vector2(2400, GROUND_Y - 30.0)],
			"sniper": [Vector2(1200, 380.0), Vector2(2100, 380.0)],
			"drone":  [Vector2(2200, 160.0)],
			"bomber": [Vector2(2700, GROUND_Y - 30.0)],
			# 마지막 관문 — 합류 직전 ground 평지에 방패병
			"shield": [Vector2(3300, GROUND_Y - 30.0)],
		},
		"rewards": {
			"xp_orbs":    [Vector2(2900, 260.0), Vector2(2950, 260.0)],
			"hp_pickups": [],
		},
		"spikes": [
			{"x": 1500, "y": GROUND_Y - 6.0},
			{"x": 2300, "y": GROUND_Y - 6.0},
		],
	}
