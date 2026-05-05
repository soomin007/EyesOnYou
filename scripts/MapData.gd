class_name MapData
extends RefCounted

# 11개 맵의 세계 형태 + platform/적 spawn/보상/함정 통합 명세.
# 명세: docs/design/world_layout.md
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

# ─── 2. 외벽 옥상 (VERTICAL_UP) — 옥상답게 + 비밀 통로 ────────
# 점프 파라미터: 1단 ~104px / 2단 ~190px.
# "옥상답게" — 좁은 발판 zigzag 사다리 → 넓은 옥상 슬랩(roof slab) + 그 사이를 잇는
# 비상사다리/HVAC/안테나 형태의 좁은 step. 발판 종류로 옥상 구조 모사.
# 사용자 피드백: "외벽 옥상도 점프 노가다 심함, 드론은 초반이라 부담스럽다"
# → 발판 25 → 22로 줄이고, 비밀 통로 추가, 드론 제거.
static func _rooftops() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 저층 옥상(2680) — 비상사다리 2 step + 옥상 1
			{"pos": Vector2(560, 2960), "w": 220.0},  # 120 (1 빠듯) 비상사다리
			{"pos": Vector2(740, 2840), "w": 220.0},  # 120 (1 빠듯) 비상사다리
			{"pos": Vector2(640, 2680), "w": 480.0},  # 160 (2) — ROOF 1 (저층 옥상, patrol)

			# 저층 → 중층 옥상(2360) — HVAC 2 step + 옥상 1
			{"pos": Vector2(420, 2540), "w": 180.0},  # 140 (2) HVAC 박스
			{"pos": Vector2(700, 2440), "w": 180.0},  # 100 (1) AC 유니트
			{"pos": Vector2(560, 2360), "w": 440.0},  # 80 (1) — ROOF 2 (중층 옥상)

			# 중층 → 분기 옥상(2040) — 스카이라이트 2 step + 옥상 1
			{"pos": Vector2(820, 2240), "w": 180.0},  # 120 (1 빠듯) 스카이라이트
			{"pos": Vector2(540, 2120), "w": 180.0},  # 120 (1 빠듯)
			{"pos": Vector2(640, 2040), "w": 520.0},  # 80 (1) — ROOF 3 (분기점, patrol)

			# 비밀 통로 — ROOF 3에서 우측 멀리 더블점프 → 안테나 발판 → 비밀 옥상.
			# 시야 밖(우측 외곽)이라 호기심 있는 사람만 발견. XP 2 + HP 1 보너스.
			{"pos": Vector2(1130, 2160), "w": 100.0}, # 안테나 발판
			{"pos": Vector2(1180, 2280), "w": 140.0}, # 비밀 옥상 끝 — XP 2 + HP 1

			# 분기 우측(XP) — 노출된 옥상 가장자리. 짧음(2 발판).
			{"pos": Vector2(960, 1900), "w": 200.0},  # 140 (2)
			{"pos": Vector2(1080, 1820), "w": 180.0}, # 80 (1) — XP 끝

			# 분기 좌측(HP) — 안전한 안쪽. 짧음(2 발판).
			{"pos": Vector2(320, 1900), "w": 200.0},  # 140 (2)
			{"pos": Vector2(200, 1820), "w": 180.0},  # 80 (1) — HP 끝

			# 합류 — 양쪽 끝(1820)에서 1700 (120, 빠듯) → ROOF 4
			{"pos": Vector2(560, 1700), "w": 440.0},  # ROOF 4 합류

			# 정상 → 골 — ROOF 5 + 6 step (간격 140-160 (2) 위주, 옥상 단조 회피)
			{"pos": Vector2(720, 1540), "w": 240.0},  # 160 (2)
			{"pos": Vector2(520, 1380), "w": 240.0},  # 160 (2)
			{"pos": Vector2(700, 1220), "w": 240.0},  # 160 (2)
			{"pos": Vector2(560, 1060), "w": 440.0},  # 160 (2) — ROOF 5 (중간 옥상 슬랩)
			{"pos": Vector2(680, 900),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(520, 740),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(640, 580),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(520, 420),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(620, 280),  "w": 320.0},  # 140 (2) — 골 직전
		],
		"enemies": {
			# stage 0~1 등장 맵 — 초반이라 적 강도 낮춤. 드론은 사용자 피드백으로 제거.
			# patrol 3마리 + 분기 끝 sniper 2 (xp/hp 보호). bomber/shield 없음.
			"patrol": [Vector2(640, 2650.0), Vector2(640, 2010.0), Vector2(560, 1670.0)],
			"sniper": [Vector2(1080, 1790.0), Vector2(200, 1790.0)],
			"drone":  [],  # ← 드론 제거 (이전엔 (640, 360))
			"bomber": [], "shield": [],
		},
		"rewards": {
			# 일반 분기 — 우측 끝 XP 2, 좌측 끝 HP 1
			# 비밀 옥상 — XP 2 + HP 1 보너스 (메인 보상보다 약간 큼)
			"xp_orbs":    [
				Vector2(1060, 1790.0), Vector2(1100, 1790.0),
				Vector2(1160, 2250.0), Vector2(1200, 2250.0),
			],
			"hp_pickups": [
				Vector2(200, 1790.0),
				Vector2(1180, 2250.0),
			],
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
			# 우측 — 좁은 파이프 (가시 + HP). 발판 폭 80으로 좁힘 — 가시
			# 사이 통과를 빠듯하게 만들어 위협을 의미있게.
			{"pos": Vector2(960, 800),  "w": 80.0},
			{"pos": Vector2(960, 960),  "w": 80.0},
			{"pos": Vector2(960, 1120), "w": 80.0},
			{"pos": Vector2(960, 1280), "w": 120.0},  # 끝 — 안전
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
			# 좌측 (patrol+XP 통로) — XP 2개. patrol 처치 XP가 추가로 붙음.
			"xp_orbs": [
				Vector2(200, 1240.0), Vector2(240, 1240.0),
				# 우측 (가시+위험) 끝 — XP 3개 + HP. 가시 dmg 2를 감수한 만큼
				# patrol 통로보다 의미있게 큰 보상.
				Vector2(940, 1240.0), Vector2(980, 1240.0), Vector2(1020, 1240.0),
			],
			"hp_pickups": [Vector2(960, 1240.0)],
		},
		# 가시 — sewers는 함정 맵이라는 정체성을 살리려 메인/양 분기 모두에 분산.
		# 사용자 피드백: "맞을 일 자체가 거의 없어 존재 의미가 없다"
		"spikes": [
			# 메인 진입 — 280→460 사이 가운데. 첫 낙하부터 위협.
			{"x": 560.0, "y": 380.0, "w": 80.0},
			# 분기점 위 — 460→640 사이. 분기 결정 전 한 번 부딪힘.
			{"x": 540.0, "y": 560.0, "w": 80.0},
			# 좌측 patrol 통로 — 800↔960, 960↔1120 사이 가운데. patrol과 함께 위협.
			{"x": 240.0, "y": 880.0, "w": 80.0},
			{"x": 230.0, "y": 1040.0, "w": 80.0},
			# 우측 파이프 가시 — dmg 2(강조 함정). 좌측 대비 위험 누적.
			{"x": 910.0, "y": 880.0, "w": 70.0, "dmg": 2},
			{"x": 1010.0, "y": 880.0, "w": 70.0, "dmg": 2},
			{"x": 960.0, "y": 920.0, "w": 30.0, "dmg": 2},
			{"x": 910.0, "y": 1040.0, "w": 70.0, "dmg": 2},
			{"x": 1010.0, "y": 1040.0, "w": 70.0, "dmg": 2},
			{"x": 960.0, "y": 1080.0, "w": 30.0, "dmg": 2},
			{"x": 910.0, "y": 1200.0, "w": 70.0, "dmg": 2},
			{"x": 1010.0, "y": 1200.0, "w": 70.0, "dmg": 2},
			{"x": 960.0, "y": 1240.0, "w": 30.0, "dmg": 2},
			# 합류부 — 1280↔1440 사이. 좌/우 어느 쪽으로 와도 마지막 위협.
			{"x": 480.0, "y": 1380.0, "w": 90.0, "dmg": 2},
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

# ─── 5. 냉각 시설 (VERTICAL_UP, 지그재그 파이프 + 비밀 스팟) ──
# 단조로운 100px 일정 점프 → 80/100/120/140 섞기. 메인 spine 짧게 줄이고
# 우측 외곽에 "비밀 통로" 추가 — 메인 발판에서 더블점프로 도달, XP 3개 보상.
# 사용자 피드백: "수직 맵 점프 노가다 너무 심함, 탐험할 동기 없음"
static func _cooling() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 진입 → 분기점 — 80/100/120/140 섞기. 발판 수 줄임 (12 → 9).
			{"pos": Vector2(640, 3000), "w": 280.0},  # 120 from ground (1 빠듯)
			{"pos": Vector2(540, 2900), "w": 280.0},  # 100 (1)
			{"pos": Vector2(640, 2780), "w": 280.0},  # 120 (1 빠듯) — patrol 자리
			{"pos": Vector2(540, 2700), "w": 280.0},  # 80 (1)
			{"pos": Vector2(640, 2580), "w": 280.0},  # 120 (1 빠듯) — patrol 자리
			{"pos": Vector2(540, 2480), "w": 280.0},  # 100 (1)
			{"pos": Vector2(640, 2340), "w": 280.0},  # 140 (2)
			{"pos": Vector2(540, 2220), "w": 280.0},  # 120 (1 빠듯)
			{"pos": Vector2(640, 2060), "w": 280.0},  # 160 (2)
			{"pos": Vector2(540, 1920), "w": 320.0},  # 140 (2) — 분기점, patrol 자리

			# 비밀 통로 — 메인 spine에서 우측으로 더블점프. 발판 폭 좁고(120) 외곽
			# 이라 시야에서 살짝 비껴 있음. 끝에 XP 3 + HP 1 — 일반 분기보다 큼.
			# 진입: (540, 2700)에서 더블점프 우측 → (940, 2620). 시각적으로 "왜 저기에
			# 발판이?" 호기심을 유도, 모르는 사람은 그냥 위로 진행.
			{"pos": Vector2(940, 2620), "w": 120.0},  # 진입 발판
			{"pos": Vector2(1100, 2480), "w": 140.0}, # 비밀 끝 — XP 3 + HP 1

			# 분기 우 — 짧게 줄임 (6 → 4 발판), 100 일정. 일반 보상 (XP 2).
			{"pos": Vector2(900, 1780), "w": 220.0},  # 120 (1 빠듯)
			{"pos": Vector2(960, 1680), "w": 200.0},  # 100 (1)
			{"pos": Vector2(900, 1540), "w": 220.0},  # 140 (2)
			{"pos": Vector2(960, 1440), "w": 240.0},  # 100 (1) — 우측 끝 (XP)

			# 분기 좌 — 짧게 줄임 (6 → 4 발판). HP 보상 + sniper 노출.
			{"pos": Vector2(220, 1780), "w": 220.0},
			{"pos": Vector2(160, 1680), "w": 200.0},
			{"pos": Vector2(220, 1540), "w": 220.0},
			{"pos": Vector2(180, 1440), "w": 240.0},  # 좌측 끝 (HP)

			# 합류 — 양쪽 끝(1440)에서 1300 (140, 빠듯) → 단일 경로
			{"pos": Vector2(540, 1300), "w": 320.0},

			# 정상 → 골 — 8 → 6 발판으로 단축. 140-160 (2칸) 위주 — 100 일정 단조로움 회피.
			{"pos": Vector2(640, 1160), "w": 240.0},  # 140 (2)
			{"pos": Vector2(540, 1000), "w": 240.0},  # 160 (2)
			{"pos": Vector2(640, 840),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(540, 680),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(620, 520),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(560, 380),  "w": 280.0},  # 140 (2)
			{"pos": Vector2(620, 280),  "w": 320.0},  # 100 (1) — 골 직전
		],
		"enemies": {
			"patrol": [Vector2(540, 2750.0), Vector2(640, 2550.0), Vector2(540, 1890.0)],
			"sniper": [Vector2(180, 1410.0)],
			# 드론 — 분기 위쪽 빈 공간 (우측 1440 위 / 합류 1300 위)
			"drone":  [Vector2(960, 1320.0), Vector2(540, 1180.0)],
			"bomber": [], "shield": [],
		},
		"rewards": {
			# 일반 분기 — 우측 끝 XP 2, 좌측 끝 HP 1
			# 비밀 통로 — XP 3 + HP 1 (메인 spine 단축으로 줄어든 진행감을
			# "찾는 재미"로 보상. 발판 폭 좁고 외곽이라 못 보고 지나가기 쉬움)
			"xp_orbs":    [
				Vector2(960, 1410.0), Vector2(1000, 1410.0),
				Vector2(1080, 2450.0), Vector2(1100, 2450.0), Vector2(1120, 2450.0),
			],
			"hp_pickups": [
				Vector2(180, 1410.0),
				Vector2(1100, 2450.0),
			],
		},
		"spikes": [],
	}

# ─── 6. 감시탑 (VERTICAL_UP, 외부/내부 분기 + 비밀 통로) ───────
# 점프 파라미터: 1단 ~104px / 2단 ~190px. 발판 32 → 23으로 단축.
# 외부(저격 노출+XP) / 내부(안전+HP) 분기 + 후방 비밀 통로(보너스). 옥상보다 위협 ↑.
static func _watchtower() -> Dictionary:
	return {
		"world_type":   "VERTICAL_UP",
		"world_size":   Vector2(1280.0, 3200.0),
		"player_start": Vector2(640.0, 3050.0),
		"goal_type":    "POSITION",
		"goal_pos":     Vector2(640.0, 200.0),
		"camera_mode":  "VERTICAL",
		"platforms": [
			# 지상(3080) → 분기점(2440) — gap 100/120/140 섞기 (6 → 5 발판)
			{"pos": Vector2(560, 2960), "w": 280.0},  # 120 (1 빠듯)
			{"pos": Vector2(700, 2840), "w": 240.0},  # 120 (1 빠듯) — patrol 자리
			{"pos": Vector2(540, 2700), "w": 240.0},  # 140 (2)
			{"pos": Vector2(660, 2580), "w": 240.0},  # 120 (1 빠듯)
			{"pos": Vector2(640, 2440), "w": 360.0},  # 140 (2) — 분기점, patrol 자리

			# 비밀 통로 — 분기점에서 좌측 멀리 더블점프. 시야 외곽 발판.
			# 보안 통로 측면 사다리 컨셉. XP 2 + HP 1 보너스.
			{"pos": Vector2(120, 2540), "w": 100.0},  # 사다리 진입
			{"pos": Vector2(80, 2660), "w": 140.0},   # 비밀 끝 — XP 2 + HP 1

			# 분기 — 외부 노출 (좌측, sniper 노출 + XP). 6 → 4 발판.
			{"pos": Vector2(280, 2280), "w": 220.0},  # 160 (2 진입)
			{"pos": Vector2(160, 2140), "w": 200.0},  # 140 (2)
			{"pos": Vector2(280, 1980), "w": 220.0},  # 160 (2) — patrol 자리
			{"pos": Vector2(180, 1820), "w": 220.0},  # 160 (2) — 외부 끝 (XP)

			# 분기 — 내부 계단 (중앙). 6 → 4 발판.
			{"pos": Vector2(540, 2280), "w": 240.0},  # 160 (2 진입)
			{"pos": Vector2(660, 2140), "w": 240.0},  # 140 (2)
			{"pos": Vector2(540, 1980), "w": 240.0},  # 160 (2) — patrol 자리
			{"pos": Vector2(640, 1820), "w": 280.0},  # 160 (2) — 내부 끝 (HP)

			# 합류 — 두 끝(1820)에서 1680 (140) → 단일 경로
			{"pos": Vector2(560, 1680), "w": 320.0},

			# 정상 — gap 140-160 (2칸) 위주 섞기 (13 → 8 발판)
			{"pos": Vector2(720, 1520), "w": 240.0},  # 160 (2)
			{"pos": Vector2(540, 1380), "w": 240.0},  # 140 (2)
			{"pos": Vector2(660, 1220), "w": 240.0},  # 160 (2)
			{"pos": Vector2(540, 1060), "w": 240.0},  # 160 (2)
			{"pos": Vector2(640, 900),  "w": 360.0},  # 160 (2) — 중간 광폭 (정찰 단)
			{"pos": Vector2(540, 740),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(660, 580),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(540, 420),  "w": 240.0},  # 160 (2)
			{"pos": Vector2(620, 280),  "w": 320.0},  # 140 (2) — 골 직전
		],
		"enemies": {
			# patrol 4 → 3 (발판 줄임에 맞춰). sniper 위치 외부 분기 끝(XP) 가까이.
			# 드론 제거 — 감시탑은 sniper 컨셉. 정상 1마리만 위협 유지.
			"patrol": [Vector2(700, 2810.0), Vector2(280, 1950.0), Vector2(540, 1950.0)],
			"sniper": [Vector2(180, 1790.0)],
			"drone":  [Vector2(640, 500.0)],
			"bomber": [],
			"shield": [],
		},
		"rewards": {
			# 외부 끝 XP 2, 내부 끝 HP 1, 비밀 사다리 끝 XP 2 + HP 1
			"xp_orbs":    [
				Vector2(160, 1790.0), Vector2(200, 1790.0),
				Vector2(60, 2630.0), Vector2(100, 2630.0),
			],
			"hp_pickups": [
				Vector2(640, 1790.0),
				Vector2(80, 2630.0),
			],
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
			# 방패병 — 통로 장애물(1200/2000/2800)과 이스터에그 문(2000) 사이의
			# 빈 공간에 배치. 플랫폼/문 뒤에 가려지면 사격이 막혀 매우 불쾌.
			"shield": [Vector2(1500, 600.0), Vector2(2400, 600.0)],
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
# 보스 SENTINEL 단독 챔버 (world_layout §2.10). 일반 적은 spawn하지 않음 — 3페이즈 보스가 전부.
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
# world_layout §3.2. Stage 4 분기 의도적 선택지.
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
