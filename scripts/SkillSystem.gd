class_name SkillSystem
extends RefCounted

# 베이스라인: 모든 플레이어가 시작부터 보유 (GameState.STARTING_SKILLS)
#   dash         — Shift 키, 0.18s 무적 이동
#   double_jump  — 공중에서 한 번 더 점프 (자동)
#
# 레벨업 풀: 본편 진행 중 처치 → 경험치 → 레벨업 시 3개 중 1개 선택.
# active=true 인 스킬만 키 입력 필요. 나머지는 자동 적용.

const ALL_SKILLS: Array = [
	{"id": "melee_boost", "name": "사격 강화", "desc": "사격 데미지 +1",                    "tag": "전투", "active": false},
	{"id": "ranged",      "name": "장거리 사격", "desc": "총알 속도/사거리 +50%, 쿨다운 -25%", "tag": "전투", "active": false},
	{"id": "piercing",    "name": "관통탄",     "desc": "총알이 모든 적을 관통",            "tag": "전투", "active": false},
	{"id": "multishot",   "name": "삼연사",     "desc": "한 번에 위/중/아래 3발 발사",       "tag": "전투", "active": false},
	{"id": "explosive",   "name": "폭발물",     "desc": "주위 적을 광역 처치 (3s 쿨다운)",    "tag": "전투", "active": true,  "key": "skill"},
	{"id": "glide",       "name": "공중 글라이드", "desc": "공중에서 점프 키 누르고 있으면 천천히 낙하", "tag": "이동", "active": false},
	{"id": "regen",       "name": "최대 체력 +1", "desc": "최대 체력 영구 +1 (즉시 1 회복)",         "tag": "생존", "active": false},
	{"id": "shield",      "name": "비상 방어막",   "desc": "쓰러질 때 1회만 살아남기 (HP 1로 부활)",  "tag": "생존", "active": false},
]

static func roll_choices(owned: Array, count: int = 3) -> Array:
	var available: Array = []
	for s in ALL_SKILLS:
		var skill: Dictionary = s
		var sid: String = skill.get("id", "")
		if not (sid in owned):
			available.append(skill)
	available.shuffle()
	var picks: Array = []
	for i in min(count, available.size()):
		var p: Dictionary = available[i]
		picks.append(p)
	return picks

static func find_by_id(id: String) -> Dictionary:
	for s in ALL_SKILLS:
		var skill: Dictionary = s
		if skill.get("id", "") == id:
			return skill
	# 베이스라인 스킬 메타데이터 (풀에는 없지만 정보 조회 가능)
	if id == "dash":
		return {"id": "dash", "name": "대시", "desc": "짧은 무적 이동", "tag": "이동", "active": true, "key": "dash"}
	if id == "double_jump":
		return {"id": "double_jump", "name": "이중점프", "desc": "공중에서 한 번 더 점프", "tag": "이동", "active": false}
	return {}
