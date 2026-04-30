extends Node

const TOTAL_STAGES: int = 5
const SCORE_THRESHOLD: int = 3

var current_stage: int = 0
var death_count: int = 0
var score: int = 0

var trust_score: int = 0
var aggression_score: int = 0
var route_history: Array = []
var last_veil_recommended_route: String = ""
var followed_veil_last_choice: bool = false

var skills: Array = []
var current_route_tags: Array = []

var player_max_hp: int = 5
var player_hp: int = 5
var player_xp: int = 0
var player_level: int = 1
const XP_PER_LEVEL: int = 5

func reset() -> void:
	current_stage = 0
	death_count = 0
	score = 0
	trust_score = 0
	aggression_score = 0
	route_history = []
	last_veil_recommended_route = ""
	followed_veil_last_choice = false
	skills = []
	current_route_tags = []
	player_max_hp = 5
	player_hp = 5
	player_xp = 0
	player_level = 1

func record_route_choice(route: Dictionary, recommended_id: String) -> void:
	var rid: String = route.get("id", "")
	route_history.append(rid)
	current_route_tags = route.get("tags", [])
	followed_veil_last_choice = (rid == recommended_id)
	if followed_veil_last_choice:
		trust_score += 1
	if "전투" in current_route_tags or "근접전" in current_route_tags:
		aggression_score += 1

func add_xp(amount: int) -> bool:
	player_xp += amount
	if player_xp >= XP_PER_LEVEL:
		player_xp -= XP_PER_LEVEL
		player_level += 1
		return true
	return false

func has_skill(id: String) -> bool:
	return id in skills

func add_skill(id: String) -> void:
	if not has_skill(id):
		skills.append(id)
		match id:
			"regen":
				player_max_hp += 1
				player_hp = min(player_hp + 1, player_max_hp)

func damage_player(amount: int) -> void:
	player_hp = max(0, player_hp - amount)

func heal_player(amount: int) -> void:
	player_hp = min(player_max_hp, player_hp + amount)

func is_dead() -> bool:
	return player_hp <= 0

func register_death() -> void:
	death_count += 1

func on_stage_clear() -> void:
	current_stage += 1
	score += 100 * current_stage
	if has_skill("regen"):
		heal_player(1)

func is_final_stage_done() -> bool:
	return current_stage >= TOTAL_STAGES
