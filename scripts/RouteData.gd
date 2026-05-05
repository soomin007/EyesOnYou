class_name RouteData
extends RefCounted

# 11개 맵 — Dead Cells 스타일로 stage_index 별 후보 풀이 다름.
#   min_stage / max_stage : 등장 가능 stage 범위 (양 끝 포함)
#   available_stages       : 명시적 리스트 (있으면 우선, 없으면 min/max 사용)
#   guaranteed_in_stages   : 해당 stage 풀 빌드 시 항상 포함되는 맵 (셔플 전 fix-slot)
#   unique                 : true면 한 번 선택 후 다시 등장 안 함 (현재는 route_history 필터로 보편 규칙)
#   hidden                 : VEIL 추천 대상에서 제외 (??? 전용)

const ALL_ROUTES: Array = [
	{
		"id": "route_back_alley",
		"name": "외곽 진입로",
		"description": "SILO-7 외벽을 따라 난 좁은 통로. 가로등이 끊기는 구간이 있다.",
		"risk": 1,
		"reward": 1,
		"hidden": false,
		"unique": false,
		"min_stage": 0, "max_stage": 1,
		"tags": ["우회", "어두운_환경"],
		"veil_comment": "조용한 루트예요. 경비가 적어요.",
		"stage_color": Color(0.12, 0.12, 0.14),
	},
	{
		"id": "route_rooftops",
		"name": "외벽 옥상",
		"description": "시설 외벽을 타고 오르는 루트. 탁 트여 있고, 그만큼 노출된다.",
		"risk": 2,
		"reward": 2,
		"hidden": false,
		"unique": false,
		"min_stage": 0, "max_stage": 1,
		"tags": ["원거리", "노출", "이동"],
		"veil_comment": "저격 노출이 있어요. 엄폐 포인트 챙겨요.",
		"stage_color": Color(0.10, 0.13, 0.20),
	},
	{
		"id": "route_sewers",
		"name": "지하 인입로",
		"description": "시설 아래로 연결된 옛날 배수 통로. 보안 카메라가 없는 대신 함정이 있다.",
		"risk": 2,
		"reward": 3,
		"hidden": false,
		"unique": false,
		# 지상(rooftops) 직후 깊은 지하로 가는 게 어색해 stage 2 이후로 한정.
		"min_stage": 2, "max_stage": 3,
		"tags": ["근접전", "어두운_환경", "함정", "전투"],
		"veil_comment": "함정이 깔려 있어요. 발 밑 봐요.",
		"stage_color": Color(0.18, 0.22, 0.20),
	},
	{
		"id": "route_subway",
		"name": "폐쇄 지하철",
		"description": "SILO-7이 지어지기 전 폐쇄된 지하철 구간. 좁고 어둡고 길다.",
		"risk": 2,
		"reward": 2,
		"hidden": false,
		"unique": false,
		# 외부→시설 진입 brigde — stage 1~3에 등장해 외벽 단계와 내부 단계를 잇는다.
		"min_stage": 1, "max_stage": 3,
		"tags": ["근접전", "함정", "전투"],
		"veil_comment": "좁아요. 대시 써서 함정 넘어가요.",
		"stage_color": Color(0.08, 0.10, 0.14),
	},
	{
		"id": "route_cooling",
		"name": "냉각 시설",
		"description": "내부 기계실. 차가운 공기와 수직 파이프, 위에서 떨어지는 드론.",
		"risk": 2,
		"reward": 3,
		"hidden": false,
		"unique": false,
		# 드론 첫 등장 맵 — 사용자 피드백상 후반에 등장하는 게 더 자연스러워 stage 3~4로 이동.
		"min_stage": 3, "max_stage": 4,
		"tags": ["전투", "드론", "수직"],
		"veil_comment": "수직 구조예요. 위에서 와요.",
		"stage_color": Color(0.10, 0.16, 0.20),
	},
	{
		"id": "route_watchtower",
		"name": "감시탑",
		"description": "내부 중층의 관제 구역. 멀리서 노려보는 저격수가 많다.",
		"risk": 3,
		"reward": 3,
		"hidden": false,
		"unique": false,
		# stage 1부터 등장 가능 — 외벽 옥상 직후 감시탑(둘 다 노출+높이)이 자연스럽게 이어짐.
		"min_stage": 1, "max_stage": 4,
		"tags": ["원거리", "전투", "노출"],
		"veil_comment": "저격이 많아요. 엄폐 짧게 쓰고 빠르게.",
		"stage_color": Color(0.18, 0.16, 0.22),
	},
	{
		"id": "route_ward",
		"name": "격리 병동",
		"description": "내부 중층, 오래 봉인된 구역. 좁은 복도에 흐릿한 비상등.",
		"risk": 2,
		"reward": 3,
		"hidden": false,
		"unique": false,
		"min_stage": 3, "max_stage": 4,
		# 격리 병동은 ??? 맵 복선 트리거가 있어 Stage 3~4 풀에 항상 포함되어야 함.
		"guaranteed_in_stages": [3, 4],
		"tags": ["우회", "어두운_환경", "은폐"],
		"veil_comment": "이 구역은 오래됐어요. 조심해요.",
		"stage_color": Color(0.12, 0.10, 0.14),
	},
	{
		"id": "route_datacenter",
		"name": "데이터 센터",
		"description": "핵심부 인접. 서버 랙과 푸른 LED, 그리고 드론과 저격이 동시에.",
		"risk": 3,
		"reward": 3,
		"hidden": false,
		"unique": false,
		"min_stage": 4, "max_stage": 5,
		"tags": ["전투", "드론", "원거리"],
		"veil_comment": "드론과 저격이 동시에 와요. 어렵겠어요.",
		"stage_color": Color(0.14, 0.18, 0.24),
	},
	{
		"id": "route_escape",
		"name": "비상 탈출로",
		"description": "핵심부를 우회하는 비좁은 통로. 위험은 낮지만 보상도 적다.",
		"risk": 1,
		"reward": 2,
		"hidden": false,
		"unique": false,
		"min_stage": 5, "max_stage": 6,
		"tags": ["우회", "은폐"],
		"veil_comment": "조용한 길이에요. 빠르게 빠져요.",
		"stage_color": Color(0.10, 0.12, 0.14),
	},
	{
		"id": "route_lab",
		"name": "핵심부",
		"description": "서버실이 있는 시설 중심부. 드론이 상시 순찰한다.",
		"risk": 3,
		"reward": 3,
		"hidden": false,
		"unique": false,
		"min_stage": 5, "max_stage": 6,
		"tags": ["전투", "드론", "밝은_환경"],
		"veil_comment": "드론이 위에서 와요. 보상은 그만큼 커요.",
		"stage_color": Color(0.22, 0.18, 0.18),
	},
	{
		"id": "route_blackout",
		"name": "블랙아웃 런",
		"description": "교신이 차단된 짧은 구역. 어둡고, 한 대 맞으면 끝.",
		"risk": 2,
		"reward": 3,
		"hidden": false,
		"unique": true,
		"challenge": true,
		"available_stages": [4],
		"guaranteed_in_stages": [4],
		"tags": ["도전", "어두운_환경"],
		"veil_comment": "[도전] 교신이 차단된 구역이에요. 혼자 가야 해요.",
		"stage_color": Color(0.02, 0.02, 0.04),
	},
	{
		"id": "route_hidden",
		"name": "???",
		"description": "도면에 없는 구역. 정보 없음.",
		"risk": 2,
		"reward": 3,
		"hidden": true,
		"unique": true,
		"min_stage": 5, "max_stage": 6,
		"tags": ["우회", "정보"],
		"veil_comment": "저도 모르겠어요. 미안해요.",
		"stage_color": Color(0.06, 0.06, 0.08),
	},
]

# 스토리 모드 — 5스테이지 고정 스케줄. 드론·도전·??? 맵 모두 빼고 핵심 동선만.
# Stage 4는 lab 보스 (final). 각 스테이지마다 1~2개의 단순한 선택지.
const STORY_SCHEDULE: Dictionary = {
	0: ["route_back_alley", "route_rooftops"],
	1: ["route_subway", "route_watchtower"],
	2: ["route_ward", "route_sewers"],
	3: ["route_escape"],
	4: ["route_lab"],
}

# 해당 stage에 등장 가능한 맵 풀을 만든다.
# visited: 이미 선택한 route id 목록 (중복 방문 금지). 비워두면 필터 안 함.
# guaranteed_in_stages가 있는 맵은 셔플 전 우선 포함된다.
static func get_route_pool_for_stage(stage_index: int, visited: Array = []) -> Array:
	if GameState.story_mode:
		return _get_story_route_pool(stage_index)
	var guaranteed: Array = []
	var others: Array = []
	for r in ALL_ROUTES:
		var route: Dictionary = r
		var rid: String = str(route.get("id", ""))
		if rid in visited:
			continue
		if not _stage_in_range(route, stage_index):
			continue
		var g: Array = route.get("guaranteed_in_stages", [])
		if stage_index in g:
			guaranteed.append(route)
		else:
			others.append(route)
	others.shuffle()
	var pick_count: int = 3 if stage_index >= 1 else 2
	var pool: Array = []
	for r in guaranteed:
		pool.append(r)
		if pool.size() >= pick_count:
			return pool
	for r in others:
		pool.append(r)
		if pool.size() >= pick_count:
			break
	return pool

static func _get_story_route_pool(stage_index: int) -> Array:
	var ids: Array = STORY_SCHEDULE.get(stage_index, [])
	var out: Array = []
	for rid in ids:
		for r in ALL_ROUTES:
			var route: Dictionary = r
			if route.get("id", "") == rid:
				out.append(route)
				break
	return out

static func _stage_in_range(route: Dictionary, stage_index: int) -> bool:
	# 명시적 available_stages가 있으면 우선 (디버그/특수 용도).
	# 없으면 min_stage/max_stage 범위 사용.
	if route.has("available_stages"):
		var stages: Array = route.get("available_stages", [])
		if not stages.is_empty():
			return stage_index in stages
	if route.has("min_stage") and route.has("max_stage"):
		return stage_index >= int(route["min_stage"]) and stage_index <= int(route["max_stage"])
	# 둘 다 없으면 모든 stage 등장 (안전 폴백).
	return true

static func choose_veil_recommendation(pool: Array) -> String:
	var best_id: String = ""
	var best_score: float = -INF
	for r in pool:
		var route: Dictionary = r
		if route.get("hidden", false):
			continue
		# 도전 루트는 의도적 선택 — VEIL 추천에서 제외 (교신 차단 컨셉)
		if route.get("challenge", false):
			continue
		var s: float = float(route.get("reward", 0)) - 0.4 * float(route.get("risk", 0))
		if s > best_score:
			best_score = s
			best_id = route.get("id", "")
	if best_id == "" and pool.size() > 0:
		var fallback: Dictionary = pool[0]
		best_id = fallback.get("id", "")
	return best_id
