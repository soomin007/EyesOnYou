class_name SkillSystem
extends RefCounted

const ALL_SKILLS: Array = [
	{"id": "dash",         "name": "대시",        "desc": "짧은 무적 이동",          "tag": "이동"},
	{"id": "double_jump",  "name": "이중점프",    "desc": "공중에서 한 번 더 점프",   "tag": "이동"},
	{"id": "wall_slide",   "name": "벽타기",      "desc": "벽에 붙어 천천히 낙하",    "tag": "이동"},
	{"id": "roll",         "name": "구르기",      "desc": "구르기로 피격 회피",       "tag": "이동"},
	{"id": "ranged",       "name": "원거리",      "desc": "원거리 투사체 공격",       "tag": "전투"},
	{"id": "melee_boost",  "name": "근접 강화",   "desc": "근접 데미지 +50%",         "tag": "전투"},
	{"id": "explosive",    "name": "폭발물",      "desc": "쿨다운 있는 광역 공격",    "tag": "전투"},
	{"id": "stealth",      "name": "은폐",        "desc": "3초간 적 인식 차단",       "tag": "전투"},
	{"id": "regen",        "name": "회복",        "desc": "스테이지 클리어 시 HP +1", "tag": "생존"},
	{"id": "shield",       "name": "방어막",      "desc": "치명타 1회 무효화",        "tag": "생존"},
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
	return {}
