class_name RouteData
extends RefCounted

const ALL_ROUTES: Array = [
	{
		"id": "route_back_alley",
		"name": "외곽 진입로",
		"description": "SILO-7 외벽을 따라 난 좁은 통로. 가로등이 끊기는 구간이 있다.",
		"risk": 1,
		"reward": 1,
		"hidden": false,
		"tags": ["우회", "어두운_환경"],
		"veil_comment": "조용한 루트예요. 경비가 적어요.",
		"stage_color": Color(0.12, 0.12, 0.14),
		"available_stages": [0, 1],
	},
	{
		"id": "route_rooftops",
		"name": "외벽 옥상",
		"description": "시설 외벽을 타고 오르는 루트. 탁 트여 있고, 그만큼 노출된다.",
		"risk": 1,
		"reward": 2,
		"hidden": false,
		"tags": ["원거리", "노출", "이동"],
		"veil_comment": "저격 노출이 있어요. 엄폐 포인트 챙겨요.",
		"stage_color": Color(0.10, 0.13, 0.20),
		"available_stages": [0, 1, 2],
	},
	{
		"id": "route_sewers",
		"name": "지하 배수로",
		"description": "시설 아래로 연결된 옛날 배수 통로. 보안 카메라가 없는 대신 함정이 있다.",
		"risk": 2,
		"reward": 3,
		"hidden": false,
		"tags": ["근접전", "어두운_환경", "함정", "전투"],
		"veil_comment": "함정이 깔려 있어요. 발 밑 봐요.",
		"stage_color": Color(0.18, 0.22, 0.20),
		"available_stages": [1, 2, 3],
	},
	{
		"id": "route_subway",
		"name": "지하철 연결로",
		"description": "SILO-7이 지어지기 전 폐쇄된 지하철 구간. 좁고 어둡고 길다.",
		"risk": 2,
		"reward": 2,
		"hidden": false,
		"tags": ["근접전", "함정", "전투"],
		"veil_comment": "좁아요. 대시 써서 함정 넘어가요.",
		"stage_color": Color(0.08, 0.10, 0.14),
		"available_stages": [2, 3, 4],
	},
	{
		"id": "route_lab",
		"name": "핵심부",
		"description": "서버실이 있는 시설 중심부. 드론이 상시 순찰한다.",
		"risk": 3,
		"reward": 3,
		"hidden": false,
		"tags": ["전투", "드론", "밝은_환경"],
		"veil_comment": "드론이 위에서 와요. 보상은 그만큼 커요.",
		"stage_color": Color(0.22, 0.18, 0.18),
		"available_stages": [3, 4],
	},
	{
		"id": "route_hidden",
		"name": "???",
		"description": "도면에 없는 구역. 정보 없음.",
		"risk": 2,
		"reward": 3,
		"hidden": true,
		"tags": ["우회", "정보"],
		"veil_comment": "저도 모르겠어요. 미안해요.",
		"stage_color": Color(0.06, 0.06, 0.08),
		"available_stages": [4],
	},
]

static func get_route_pool_for_stage(stage_index: int) -> Array:
	# 1) 해당 스테이지에 등장 가능한 루트만 추림.
	#    available_stages 미지정인 루트는 모든 스테이지에서 등장 (안전 폴백).
	var available: Array = []
	for r in ALL_ROUTES:
		var route: Dictionary = r
		var stages: Array = route.get("available_stages", [])
		if stages.is_empty() or stage_index in stages:
			available.append(route)
	# 2) 무작위 셔플 후 픽 (stage 0은 2장, 그 이후는 3장)
	available.shuffle()
	var pick_count: int = min(available.size(), 3 if stage_index >= 1 else 2)
	var pool: Array = []
	for i in pick_count:
		pool.append(available[i])
	return pool

static func choose_veil_recommendation(pool: Array) -> String:
	var best_id: String = ""
	var best_score: float = -INF
	for r in pool:
		var route: Dictionary = r
		if route.get("hidden", false):
			continue
		var s: float = float(route.get("reward", 0)) - 0.4 * float(route.get("risk", 0))
		if s > best_score:
			best_score = s
			best_id = route.get("id", "")
	if best_id == "" and pool.size() > 0:
		var fallback: Dictionary = pool[0]
		best_id = fallback.get("id", "")
	return best_id
