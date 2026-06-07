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
		"veil_comment": "여기로 가요. 경비도 약하고, 길도 단순해요.",
		"entry_comment": "외곽으로 들어왔어요. 차분히 살펴봐요.",
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
		"veil_comment": "옥상으로 갈래요? 시야는 트이지만 그만큼 노출돼요.",
		"entry_comment": "옥상이 출구예요. 멈추면 저격에 잡혀요. 계속 움직여요.",
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
		"veil_comment": "지하로 빠지는 길이에요. 함정만 조심하면 빠르고 보상도 커요.",
		"entry_comment": "아래로 내려가요. 통로 끝에 출구가 있어요. 발 밑 봐요.",
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
		"veil_comment": "옛 지하철이에요. 좁고 어두워요. 대시 써서 함정 넘어가세요.",
		"entry_comment": "지하철 통로예요. 좁아요. 한 번에 멀리 가요.",
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
		"veil_comment": "냉각 파이프 위로 올라가는 길이에요. 드론이 위에서 떨어져요.",
		"entry_comment": "냉각 파이프 위쪽이 출구예요. 우측 외곽에 뭔가 따로 있는 것 같기도 해요.",
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
		"veil_comment": "감시탑은 위험해요. 저격이 많아요. 엄폐 짧게, 이동은 빠르게.",
		"entry_comment": "관제 구역이에요. 시야 안에 들어가는 순간 쏴와요.",
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
		"veil_comment": "격리 병동이에요. 도면이랑 다르게 생겼을 거예요.",
		"entry_comment": "격리 병동에 들어왔어요. 안쪽이 어둡고 좁아요.",
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
		"veil_comment": "데이터 센터예요. 드론·저격 동시에 와요. 한 번에 정리해야 빠져요.",
		"entry_comment": "서버 랙이에요. 위에서 드론, 같은 층에서 저격.",
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
		"veil_comment": "비상 탈출로예요. 빨리 빠지면 그만큼 안전해요.",
		"entry_comment": "조용한 길이에요. 멈추지 말고 빠지면 돼요.",
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
		"veil_comment": "핵심부예요. 정면 돌파, 드론 상시 순찰. 보상은 큽니다.",
		"entry_comment": "핵심부에 들어왔어요. 거리 잘 잡아요.",
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
		"veil_comment": "[도전] 교신이 끊겨요. 안에선 저도 못 도와드려요. 한 번에 빠져나오셔야 해요.",
		"entry_comment": "여기서부터 교신 끊겨요. 30초 안에 빠져나오세요.",
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
		"veil_comment": "...저도 모르겠어요. 들어가실래요?",
		"entry_comment": "...뭐가 있는 거지.",
		"stage_color": Color(0.06, 0.06, 0.08),
	},
]

# 스토리 모드 — 5스테이지 고정 스케줄. 드론·도전·??? 맵 모두 빼고 핵심 동선만.
# Stage 3 lab 보스 → Stage 4 escape (보스 처치 후 빠져나오는 탈출로).
# 사용자 의도: 비상탈출로는 보스 잡고 나가는 길.
const STORY_SCHEDULE: Dictionary = {
	0: ["route_back_alley", "route_rooftops"],
	1: ["route_subway", "route_watchtower"],
	2: ["route_ward", "route_sewers"],
	3: ["route_lab"],
	4: ["route_escape"],
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
				out.append(_apply_story_overrides(route))
				break
	return out

# 스토리 모드에서 명칭/설명/멘트가 일반 모드와 의미가 다른 경우 override.
# 사용자 피드백: "비상 탈출로"가 보스 후 stage라 임무 시작 단계에서 어색했음.
const STORY_OVERRIDES: Dictionary = {
	"route_escape": {
		"name": "최종 탈출",
		"description": "임무를 마치고 시설 밖으로 빠져나가는 길. 마지막 한 걸음.",
		"veil_comment": "조용히 빠져요. 거의 다 왔어요.",
	},
}

static func _apply_story_overrides(route: Dictionary) -> Dictionary:
	var rid: String = str(route.get("id", ""))
	if not STORY_OVERRIDES.has(rid):
		return route
	var copy: Dictionary = route.duplicate()
	var override: Dictionary = STORY_OVERRIDES[rid]
	for k in override.keys():
		copy[k] = override[k]
	return copy

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

# VEIL 추천. 컨텍스트(HP/레벨)에 반응해 직관적인 결정을 내림:
#   - HP가 절반 이하 → 안전 우선 (가장 낮은 risk).
#   - 레벨 3 이상 → 보상 우선 (가장 높은 reward).
#   - 그 외 → 균형 (reward * 2 - risk 가장 큰 것).
# 동점이면 risk 낮은 쪽이 우선. hidden / challenge 루트는 항상 제외.
# 호출자가 reasoning 라벨을 표시할 수 있도록 choose_veil_recommendation_with_reason도 제공.
static func choose_veil_recommendation(pool: Array) -> String:
	var pair: Dictionary = choose_veil_recommendation_with_reason(pool)
	return str(pair.get("id", ""))

static func choose_veil_recommendation_with_reason(pool: Array) -> Dictionary:
	var candidates: Array = []
	for r in pool:
		var route: Dictionary = r
		if route.get("hidden", false):
			continue
		if route.get("challenge", false):
			continue
		candidates.append(route)
	if candidates.is_empty():
		if pool.size() > 0:
			return {"id": pool[0].get("id", ""), "reason": ""}
		return {"id": "", "reason": ""}
	var hp: int = GameState.player_hp
	var max_hp: int = GameState.player_max_hp
	var level: int = GameState.player_level
	var hurt: bool = (max_hp > 0 and float(hp) / float(max_hp) <= 0.5)
	var strong: bool = (level >= 3)
	var best: Dictionary = candidates[0]
	var best_score: float = -INF
	var reason: String = ""
	if hurt:
		reason = "지금은 안전이 우선"
		for c in candidates:
			# 낮은 risk 우선, 동점이면 reward 큰 쪽.
			var s: float = -float(c.get("risk", 0)) * 2.0 + float(c.get("reward", 0)) * 0.5
			if s > best_score:
				best_score = s
				best = c
	elif strong:
		reason = "지금은 보상 챙길 만해요"
		for c in candidates:
			# 높은 reward 우선, 동점이면 risk 낮은 쪽.
			var s: float = float(c.get("reward", 0)) * 2.0 - float(c.get("risk", 0)) * 0.5
			if s > best_score:
				best_score = s
				best = c
	else:
		reason = "위험 대비 보상 균형"
		for c in candidates:
			var s: float = float(c.get("reward", 0)) * 2.0 - float(c.get("risk", 0))
			if s > best_score:
				best_score = s
				best = c
	return {"id": best.get("id", ""), "reason": reason}

# id로 ALL_ROUTES에서 맵 정보를 찾는다. 진행 시각화(RouteMap 노드맵)에서 지나온 경로 표시에 사용.
static func get_route_by_id(rid: String) -> Dictionary:
	for r in ALL_ROUTES:
		var route: Dictionary = r
		if str(route.get("id", "")) == rid:
			return route
	return {}

# id → 표시용 맵 이름. 스토리 모드면 override 명칭(예: route_escape="최종 탈출")을 반영한다.
static func name_for_id(rid: String) -> String:
	var route: Dictionary = get_route_by_id(rid)
	if route.is_empty():
		return "?"
	if GameState.story_mode:
		route = _apply_story_overrides(route)
	return str(route.get("name", "?"))
