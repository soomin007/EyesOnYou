extends Node

const TOTAL_STAGES: int = 5
const SCORE_THRESHOLD: int = 3
const SETTINGS_PATH: String = "user://settings.cfg"
const KEYBIND_ACTIONS: Array[String] = ["move_left", "move_right", "jump", "attack", "dash", "skill", "pause"]
# 모든 플레이어가 기본 보유하는 베이스라인 스킬
const STARTING_SKILLS: Array = ["dash", "double_jump"]

var current_stage: int = 0
var death_count: int = 0
var score: int = 0

var trust_score: int = 0
var aggression_score: int = 0
var route_history: Array = []
var last_veil_recommended_route: String = ""
var followed_veil_last_choice: bool = false

var skills: Array = []
var current_route_id: String = ""
var current_route_tags: Array = []
var current_route_risk: int = 1   # 1~3, 적 수 배율 + 행동 강화에 사용
var current_route_reward: int = 1  # 1~3, 클리어 시 보너스 XP에 사용

var player_max_hp: int = 3
var player_hp: int = 3
var player_xp: int = 0
var player_level: int = 1
const XP_PER_LEVEL: int = 5

var tutorial_done: bool = false
var master_volume: float = 1.0
var sfx_volume: float = 1.0

# 디버그 연습장 모드 — Settings에서 진입. 영속화하지 않음.
var playground_active: bool = false

# ??? 맵 진행 중 Player 입력 제한 (이동/점프만 허용, 공격/대시/스킬 비활성)
var restrict_combat_input: bool = false

# 도감 — 첫 조우 시 카드 한 번만 띄우기 위한 영속 플래그.
# 게임 reset()에서는 비우지 않음 (한 번 본 적은 다음 런에서도 본 거).
var seen_enemies: Array = []

func reset() -> void:
	current_stage = 0
	death_count = 0
	score = 0
	trust_score = 0
	aggression_score = 0
	route_history = []
	last_veil_recommended_route = ""
	followed_veil_last_choice = false
	skills = STARTING_SKILLS.duplicate()
	current_route_id = ""
	current_route_tags = []
	current_route_risk = 1
	current_route_reward = 1
	player_max_hp = 3
	player_hp = 3
	player_xp = 0
	player_level = 1

# 튜토리얼 종료 후 본편 시작 시 호출. 진행 상태는 초기화하되
# 튜토리얼에서 고른 스킬은 그대로 들고감.
func start_main_game() -> void:
	current_stage = 0
	death_count = 0
	score = 0
	trust_score = 0
	aggression_score = 0
	route_history = []
	last_veil_recommended_route = ""
	followed_veil_last_choice = false
	current_route_id = ""
	current_route_tags = []
	current_route_risk = 1
	current_route_reward = 1
	player_hp = player_max_hp
	player_xp = 0
	player_level = 1
	# skills 보존

func record_route_choice(route: Dictionary, recommended_id: String) -> void:
	var rid: String = route.get("id", "")
	route_history.append(rid)
	current_route_id = rid
	current_route_tags = route.get("tags", [])
	current_route_risk = int(route.get("risk", 1))
	current_route_reward = int(route.get("reward", 1))
	followed_veil_last_choice = (rid == recommended_id)
	if followed_veil_last_choice:
		trust_score += 1
	if "전투" in current_route_tags or "근접전" in current_route_tags:
		aggression_score += 1

func is_high_risk() -> bool:
	return current_route_risk >= 3

func is_high_reward() -> bool:
	return current_route_reward >= 3

func enemy_count_multiplier() -> float:
	# 부스 환경에서 너무 빡세지 않게 살짝만 ↑.
	# 1=0.8 (기존 0.7), 2=1.1 (기존 1.0), 3=1.5 (기존 1.4)
	match current_route_risk:
		1: return 0.8
		3: return 1.5
	return 1.1

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

func on_stage_clear() -> bool:
	# 반환: 보너스 XP로 인한 레벨업이 발생했는지. 호출자가 LevelUpOverlay를
	# 띄울지 판단할 수 있게 해 보너스 레벨업이 누락되지 않도록.
	current_stage += 1
	score += 100 * current_stage
	var leveled: bool = false
	if current_route_reward > 0:
		if add_xp(current_route_reward):
			leveled = true
	# regen은 획득 시점에 max_hp +1 효과만 — 매 stage HP 풀 회복이라 heal_player 불필요
	return leveled

func is_final_stage_done() -> bool:
	return current_stage >= TOTAL_STAGES

func mark_enemy_seen(id: String) -> bool:
	if id == "" or id in seen_enemies:
		return false
	seen_enemies.append(id)
	save_settings()
	return true

# --- 설정 영속화 ---
# v1 (구): input.<action> = [physical_keycode, ...]  — 키보드 전용
# v2 (현): input.<action> = [{type, code/button}, ...]  — 키보드+마우스
# v1 cfg 로드 시 input 섹션은 무시(스키마 호환 안 됨), 다음 저장에서 v2로 전환

const SETTINGS_VERSION: int = 2

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	var version: int = int(cf.get_value("meta", "version", 1))
	tutorial_done = bool(cf.get_value("flags", "tutorial_done", false))
	master_volume = float(cf.get_value("audio", "master", 1.0))
	sfx_volume = float(cf.get_value("audio", "sfx", 1.0))
	seen_enemies = []
	for v in cf.get_value("flags", "seen_enemies", []):
		seen_enemies.append(str(v))
	if version < SETTINGS_VERSION:
		# 구 스키마 — 키바인드 폐기, project.godot + Main.gd 기본값 유지
		return
	for action in KEYBIND_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var stored: Array = cf.get_value("input", action, [])
		if stored.size() == 0:
			continue
		InputMap.action_erase_events(action)
		for entry in stored:
			if not (entry is Dictionary):
				continue
			var d: Dictionary = entry
			var t: String = str(d.get("type", ""))
			if t == "key":
				var ev := InputEventKey.new()
				ev.physical_keycode = int(d.get("code", 0))
				InputMap.action_add_event(action, ev)
			elif t == "mouse":
				var ev2 := InputEventMouseButton.new()
				ev2.button_index = int(d.get("button", 0))
				InputMap.action_add_event(action, ev2)

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("meta", "version", SETTINGS_VERSION)
	cf.set_value("flags", "tutorial_done", tutorial_done)
	cf.set_value("flags", "seen_enemies", seen_enemies)
	cf.set_value("audio", "master", master_volume)
	cf.set_value("audio", "sfx", sfx_volume)
	for action in KEYBIND_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var entries: Array = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var k := ev as InputEventKey
				entries.append({"type": "key", "code": int(k.physical_keycode)})
			elif ev is InputEventMouseButton:
				var m := ev as InputEventMouseButton
				entries.append({"type": "mouse", "button": int(m.button_index)})
		cf.set_value("input", action, entries)
	cf.save(SETTINGS_PATH)
