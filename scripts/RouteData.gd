class_name RouteData
extends RefCounted

const ALL_ROUTES: Array = [
	{
		"id": "route_sewers",
		"name": "하수도",
		"risk": 2,
		"reward": 3,
		"hidden": false,
		"tags": ["근접전", "어두운_환경", "함정", "전투"],
		"veil_comment": "적이 많지만 보상이 있어요, 요원.",
		"stage_color": Color(0.18, 0.22, 0.20),
	},
	{
		"id": "route_rooftops",
		"name": "옥상",
		"risk": 1,
		"reward": 2,
		"hidden": false,
		"tags": ["원거리", "노출", "이동"],
		"veil_comment": "탁 트인 곳이에요. 저격 조심해요.",
		"stage_color": Color(0.10, 0.13, 0.20),
	},
	{
		"id": "route_lab",
		"name": "연구실",
		"risk": 3,
		"reward": 3,
		"hidden": false,
		"tags": ["전투", "드론", "밝은_환경"],
		"veil_comment": "위험하지만 — 답이 있을 거예요.",
		"stage_color": Color(0.22, 0.18, 0.18),
	},
	{
		"id": "route_back_alley",
		"name": "뒷골목",
		"risk": 1,
		"reward": 1,
		"hidden": false,
		"tags": ["우회", "어두운_환경"],
		"veil_comment": "조용한 길이에요. 지루할 수도 있고요.",
		"stage_color": Color(0.12, 0.12, 0.14),
	},
	{
		"id": "route_subway",
		"name": "지하철",
		"risk": 2,
		"reward": 2,
		"hidden": false,
		"tags": ["근접전", "함정", "전투"],
		"veil_comment": "좁은 통로엔 함정이 있을 수 있어요.",
		"stage_color": Color(0.08, 0.10, 0.14),
	},
	{
		"id": "route_hidden",
		"name": "???",
		"risk": 2,
		"reward": 3,
		"hidden": true,
		"tags": ["우회", "정보"],
		"veil_comment": "이 경로 — 저도 잘 몰라요. 미안해요.",
		"stage_color": Color(0.06, 0.06, 0.08),
	},
]

static func get_route_pool_for_stage(stage_index: int) -> Array:
	var seed_value: int = stage_index * 17 + 3
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool: Array = []
	var indices: Array = []
	for i in ALL_ROUTES.size():
		indices.append(i)
	indices.shuffle()
	var pick_count: int = 3 if stage_index >= 1 else 2
	for i in pick_count:
		var route: Dictionary = ALL_ROUTES[indices[i]]
		pool.append(route)
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
