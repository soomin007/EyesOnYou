extends Node

# 입력 모드 — 마지막으로 들어온 이벤트가 키보드/마우스인지 패드인지 추적.
# UI hint 라벨/키캡 표지가 이 값에 따라 실시간 swap된다.
# 변경 시 input_kind_changed 시그널 → 각 UI가 _refresh_hints 갱신.
signal input_kind_changed(kind: String)
const PAD_AXIS_DEADZONE: float = 0.4
var last_input_kind: String = "kb"  # "kb" | "pad"

const TOTAL_STAGES: int = 7
const SCORE_THRESHOLD: int = 4
const SETTINGS_PATH: String = "user://settings.cfg"
const KEYBIND_ACTIONS: Array[String] = ["move_left", "move_right", "jump", "attack", "dash", "skill", "pause"]
# 모든 플레이어가 기본 보유하는 베이스라인 스킬 (트리 외)
# 자료형: Dictionary[String, int] — line_id → 보유 티어 (베이스라인은 항상 1).
const STARTING_SKILLS: Dictionary = {"dash": 1, "double_jump": 1}

var current_stage: int = 0
var death_count: int = 0
var score: int = 0

var trust_score: int = 0
var aggression_score: int = 0
var route_history: Array = []
var last_veil_recommended_route: String = ""
var followed_veil_last_choice: bool = false

var skills: Dictionary = {}
var current_route_id: String = ""
var current_route_tags: Array = []
var current_route_risk: int = 1   # 1~3, 적 수 배율 + 행동 강화에 사용
var current_route_reward: int = 1  # 1~3, 클리어 시 보너스 XP에 사용

var player_max_hp: int = 3
var player_hp: int = 3
var player_xp: int = 0
var player_level: int = 1
const XP_PER_LEVEL: int = 8

var tutorial_done: bool = false
var master_volume: float = 1.0
var sfx_volume: float = 1.0

# 스토리 모드 — 키보드/패드 조작이 어려운 사람을 위한 간략화 모드.
# 체력 무제한 / 드론 배제 / 보스 P1만 / 스테이지·맵 수 축소.
# Title의 "스토리 모드" 버튼으로만 켜지고, ending에서 reset() 시 꺼진다.
var story_mode: bool = false
const STORY_TOTAL_STAGES: int = 5

# 디버그 연습장 모드 — Settings에서 진입. 영속화하지 않음.
var playground_active: bool = false

# ??? 맵 진행 중 Player 입력 제한 (이동/점프만 허용, 공격/대시/스킬 비활성)
var restrict_combat_input: bool = false

# 도감 — 첫 조우 시 카드 한 번만 띄우기 위한 영속 플래그.
# 게임 reset()에서는 비우지 않음 (한 번 본 적은 다음 런에서도 본 거).
var seen_enemies: Array = []

# ??? 맵 누적 방문 횟수 — settings.cfg에 영속.
# 첫 방문(0): 기존 VEIL-1/VEIL-2/VEIL 고백 고정.
# 이후 방문(>=1): 추가 풀에서 1개 랜덤 교체 (VEIL-1 단말기 자리).
var hidden_visit_count: int = 0
# 이스터에그 방(ARCTURUS 아카이브) 방문 여부 — 1회만 트리거되도록 영속.
var visited_arcturus: bool = false

func _input(event: InputEvent) -> void:
	# 입력 모드 자동 감지. autoload Node여서 모든 InputEvent를 받는다.
	# 패드 motion은 데드존 이상만 인정 (스틱 미세 떨림 무시).
	var kind: String = ""
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		kind = "kb"
	elif event is InputEventJoypadButton:
		kind = "pad"
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) < PAD_AXIS_DEADZONE:
			return
		kind = "pad"
	if kind == "" or kind == last_input_kind:
		return
	last_input_kind = kind
	emit_signal("input_kind_changed", kind)

func is_pad_mode() -> bool:
	return last_input_kind == "pad"

# 입력 무장 — 인게임에서 점프/A를 누르고 있던 사람이 메뉴 등장 직후 첫 버튼을
# 자동 활성화시키는 사고 방지. 액션이 모두 떨어진 뒤(또는 처음부터 떨어져 있으면
# 즉시) first_btn에 grab_focus. 호스트(layer/scene)가 free되면 timer도 함께.
func arm_focus_after_release(host: Node, first_btn: Button, actions: PackedStringArray) -> void:
	if first_btn == null:
		return
	if not _any_action_pressed(actions):
		first_btn.grab_focus.call_deferred()
		return
	var timer := Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	host.add_child(timer)
	var btn_ref: WeakRef = weakref(first_btn)
	timer.timeout.connect(func() -> void:
		if _any_action_pressed(actions):
			return
		if is_instance_valid(timer):
			timer.queue_free()
		var b := btn_ref.get_ref() as Button
		if b != null and is_instance_valid(b):
			b.grab_focus()
	)

func _any_action_pressed(actions: PackedStringArray) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false

# 짧은 헬퍼 — 입력 모드에 따라 둘 중 하나를 반환. UI 라벨에서 사용.
func hint(kb_text: String, pad_text: String) -> String:
	return pad_text if last_input_kind == "pad" else kb_text

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
	story_mode = false

# 튜토리얼 종료 후 본편 시작 시 호출. 진행/스킬/XP 모두 초기화 — 튜토리얼은
# 연습용이라 본편에 영향 없음. VEIL이 "잠깐 빌려드려요" 멘트로 명시.
# (이전엔 튜토리얼에서 고른 스킬을 본편에 들고갔지만, 사용자 피드백으로 분리)
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
	player_max_hp = 3
	player_hp = player_max_hp
	player_xp = 0
	player_level = 1
	skills = STARTING_SKILLS.duplicate()

func record_route_choice(route: Dictionary, recommended_id: String) -> void:
	var rid: String = route.get("id", "")
	route_history.append(rid)
	current_route_id = rid
	current_route_tags = route.get("tags", [])
	current_route_risk = int(route.get("risk", 1))
	current_route_reward = int(route.get("reward", 1))
	followed_veil_last_choice = (rid == recommended_id and recommended_id != "")
	# 신뢰도 — 추천 따랐으면 +1, 무시했으면 -1. 도전/숨김 루트는 추가 페널티(자율성↑).
	if followed_veil_last_choice:
		trust_score += 1
	elif recommended_id != "":
		trust_score -= 1
	if "전투" in current_route_tags or "근접전" in current_route_tags:
		aggression_score += 1
	if route.get("challenge", false):
		trust_score -= 1
		aggression_score += 1
	if route.get("hidden", false):
		trust_score -= 1

# 신뢰도 단계 — UI 톤/멘트 prefix 결정.
# trust - aggression 기준. 양수면 VEIL을 따르는 플레이어, 음수면 거리감.
func veil_trust_tier() -> String:
	var net: int = trust_score - aggression_score
	if net >= 4:
		return "high"
	if net >= 1:
		return "warm"
	if net >= -1:
		return "neutral"
	if net >= -3:
		return "cool"
	return "broken"

func veil_tone_color() -> Color:
	match veil_trust_tier():
		"high":
			return Color(0.55, 0.95, 0.85)
		"warm":
			return Color(0.55, 0.85, 0.95)
		"neutral":
			return Color(0.85, 0.85, 0.85)
		"cool":
			return Color(0.95, 0.78, 0.50)
		"broken":
			return Color(0.95, 0.55, 0.55)
	return Color(0.55, 0.85, 0.95)

# 신뢰도 단계별 prefix 풀. 매 호출 random 선택 — 단조롭지 않게.
# neutral의 "그럼, "은 뒷 문장과 어색하게 붙어 제거 (사용자 피드백). 대신 정보형 톤.
const TONE_PREFIXES: Dictionary = {
	"high":    ["당신이라면, ", "역시 당신이에요. ", "맞춰가볼게요. ", "믿어요. "],
	"warm":    ["", "들어봐요, ", "", "제 의견은요, "],
	"neutral": ["", "", "참고로, ", "보세요, "],
	"cool":    ["음… ", "글쎄요. ", "흠… ", "잘 모르겠지만, "],
	"broken":  ["마음대로 하세요. ", "원하는 대로요. ", "당신 결정이에요. ", "더는 안 말려요. "],
}

# 신뢰도에 따라 멘트 앞에 붙는 톤 변화. 같은 단계에서도 풀에서 랜덤 — 호출마다 다양.
func veil_tone_prefix() -> String:
	var tier: String = veil_trust_tier()
	var arr: Array = TONE_PREFIXES.get(tier, [""])
	if arr.is_empty():
		return ""
	return str(arr[randi() % arr.size()])

# 신뢰도 게이지 — UI 표시용 (-1.0 ~ +1.0 정규화).
func veil_trust_normalized() -> float:
	var net: float = float(trust_score - aggression_score)
	return clamp(net / 6.0, -1.0, 1.0)

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

func add_xp(amount: int, apply_risk_bonus: bool = true) -> bool:
	# high-risk 루트(risk=3)에서 적 처치 XP +50% (스테이지 클리어 보상은 apply_risk_bonus=false로 호출).
	var gain: int = amount
	if apply_risk_bonus and current_route_risk >= 3:
		gain = int(round(float(amount) * 1.5))
	player_xp += gain
	if player_xp >= XP_PER_LEVEL:
		player_xp -= XP_PER_LEVEL
		player_level += 1
		return true
	return false

func has_skill(id: String) -> bool:
	return int(skills.get(id, 0)) >= 1

# 해당 라인의 보유 티어 반환 (0=미보유, 1~3=보유).
func get_skill_tier(id: String) -> int:
	return int(skills.get(id, 0))

# 라인을 한 단계 업그레이드. 이미 T3면 무시.
# 즉시 효과(예: hp 라인의 max_hp 증가)는 여기서 처리.
func add_skill(id: String) -> void:
	var current: int = int(skills.get(id, 0))
	if current >= 3:
		return
	var new_tier: int = current + 1
	skills[id] = new_tier
	# 라인별 즉시 효과 — 티어 업 시점에 적용.
	# B-1 단계: hp 라인만 처리(기존 regen 동작 보존). 나머지 효과는 B-2에서 Player.gd가 티어를 읽어 분기.
	match id:
		"hp":
			# T1: max_hp +1, T2: 추가 +1 (총 +2), T3: max_hp 변화 없음 (슬로모만)
			if new_tier == 1 or new_tier == 2:
				player_max_hp += 1
				player_hp = min(player_hp + 1, player_max_hp)

func damage_player(amount: int) -> void:
	# 스토리 모드는 체력 무제한 — 피격 자체를 무시. (Player.take_hit의 invuln 등은 그대로 동작)
	if story_mode:
		return
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
		if add_xp(current_route_reward, false):
			leveled = true
	# regen은 획득 시점에 max_hp +1 효과만 — 매 stage HP 풀 회복이라 heal_player 불필요
	return leveled

func effective_total_stages() -> int:
	return STORY_TOTAL_STAGES if story_mode else TOTAL_STAGES

func is_final_stage_done() -> bool:
	return current_stage >= effective_total_stages()

func mark_enemy_seen(id: String) -> bool:
	if id == "" or id in seen_enemies:
		return false
	seen_enemies.append(id)
	save_settings()
	return true

# --- 설정 영속화 ---
# v1: input.<action> = [physical_keycode, ...]  — 키보드 전용
# v2: input.<action> = [{type, code/button}, ...]  — 키보드+마우스
# v3 (현): v2 + joy_button/joy_motion 타입 — 게임패드 매핑 보존
# 구 버전 cfg 로드 시 input 섹션은 무시 (project.godot 기본값 유지), 다음 저장에서 v3로 전환

const SETTINGS_VERSION: int = 3

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
	hidden_visit_count = int(cf.get_value("flags", "hidden_visit_count", 0))
	visited_arcturus = bool(cf.get_value("flags", "visited_arcturus", false))
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
			elif t == "joy_button":
				var ev3 := InputEventJoypadButton.new()
				ev3.button_index = int(d.get("button", 0))
				InputMap.action_add_event(action, ev3)
			elif t == "joy_motion":
				var ev4 := InputEventJoypadMotion.new()
				ev4.axis = int(d.get("axis", 0))
				ev4.axis_value = float(d.get("value", 1.0))
				InputMap.action_add_event(action, ev4)

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("meta", "version", SETTINGS_VERSION)
	cf.set_value("flags", "tutorial_done", tutorial_done)
	cf.set_value("flags", "seen_enemies", seen_enemies)
	cf.set_value("flags", "hidden_visit_count", hidden_visit_count)
	cf.set_value("flags", "visited_arcturus", visited_arcturus)
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
			elif ev is InputEventJoypadButton:
				var jb := ev as InputEventJoypadButton
				entries.append({"type": "joy_button", "button": int(jb.button_index)})
			elif ev is InputEventJoypadMotion:
				var jm := ev as InputEventJoypadMotion
				entries.append({"type": "joy_motion", "axis": int(jm.axis), "value": float(jm.axis_value)})
		cf.set_value("input", action, entries)
	cf.save(SETTINGS_PATH)
