class_name SkillSystem
extends RefCounted

# 레벨업 시 다음 티어 후보를 굴린다. 각 라인에서 보유 티어 +1이 다음 후보.
# 이미 T3까지 찍은 라인은 후보에서 제외. 베이스라인은 트리 외라 후보에 안 뜸.

# owned: GameState.skills (Dictionary[String, int] — line_id → 보유 티어 0~3).
static func roll_choices(owned: Dictionary, count: int = 3) -> Array:
	var available: Array = []
	for line in SkillTreeData.LINES:
		var line_dict: Dictionary = line
		var line_id: String = line_dict.get("id", "")
		var current_tier: int = int(owned.get(line_id, 0))
		var next_tier: int = current_tier + 1
		if next_tier > SkillTreeData.TIER_MAX:
			continue
		var card: Dictionary = SkillTreeData.make_card(line_id, next_tier)
		if not card.is_empty():
			available.append(card)
	available.shuffle()
	var picks: Array = []
	for i in min(count, available.size()):
		var p: Dictionary = available[i]
		picks.append(p)
	return picks

# 단일 스킬(라인) 정보 조회. tier 미지정 시 1티어 정보.
# 베이스라인(dash, double_jump)은 트리 외라 BASELINE 정보 반환.
static func find_by_id(id: String, tier: int = 1) -> Dictionary:
	return SkillTreeData.make_card(id, tier)
