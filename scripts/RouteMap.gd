extends Control

@onready var stage_label: Label = $Header/Stage
@onready var subtitle_label: Label = $Header/Subtitle
@onready var nodes_container: HBoxContainer = $Center/Nodes
@onready var veil_box: PanelContainer = $VeilBox
@onready var veil_text: Label = $VeilBox/Margin/V/Text
@onready var hint_label: Label = $Footer/Hint

var pool: Array = []
var recommended_id: String = ""
var hovered_idx: int = 0
var buttons: Array = []

func _ready() -> void:
	stage_label.text = "STAGE %d / %d  —  루트 선택" % [GameState.current_stage + 1, GameState.effective_total_stages()]
	subtitle_label.text = "● 위험도 / 보상   —   ? 미상"
	pool = RouteData.get_route_pool_for_stage(GameState.current_stage, GameState.route_history)
	recommended_id = RouteData.choose_veil_recommendation(pool)
	# VEIL 멘트 — 신뢰도 톤(색)을 _ready에서 한 번만 적용. 폰트는 22로 키워
	# 선택 화면에서 분명히 눈에 들어오게 (이전 15는 카드에 묻혀 안 보였음).
	veil_text.add_theme_font_size_override("font_size", 22)
	veil_text.add_theme_color_override("font_color", GameState.veil_tone_color())
	# 긴 description이 박스 밖으로 빠져나가던 문제 — 자동 줄바꿈.
	veil_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	veil_text.custom_minimum_size = Vector2(560, 0)
	_setup_trust_gauge()
	_build_node_buttons()
	_update_veil_comment()
	_refresh_hint()
	GameState.input_kind_changed.connect(_on_input_kind_changed)

func _on_input_kind_changed(_kind: String) -> void:
	_refresh_hint()

func _refresh_hint() -> void:
	hint_label.text = GameState.hint(
		"[ ←/→ : 선택 이동   ENTER : 결정 ]",
		"[ D-Pad/스틱 : 선택 이동   A : 결정 ]")

func _setup_trust_gauge() -> void:
	# 상단 Header에 신뢰도 게이지 추가. (이전엔 VeilBox 안에 있어서 하단 Footer
	# 조작 안내와 시각적으로 겹쳤음 — 사용자 피드백 2026-05-05.)
	var header: Node = stage_label.get_parent()
	if header == null:
		return
	var gauge := Label.new()
	gauge.name = "TrustGauge"
	var net: int = GameState.trust_score - GameState.aggression_score
	var dots: String = ""
	for i in 5:
		var th: int = -4 + i * 2
		if net >= th:
			dots += "●"
		else:
			dots += "○"
	gauge.text = "VEIL 신뢰   " + dots
	gauge.add_theme_font_size_override("font_size", 14)
	gauge.add_theme_color_override("font_color", GameState.veil_tone_color())
	header.add_child(gauge)

func _build_node_buttons() -> void:
	for child in nodes_container.get_children():
		child.queue_free()
	buttons.clear()
	for i in pool.size():
		var route: Dictionary = pool[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 160)
		b.toggle_mode = false
		b.text = _format_button_text(route, route.get("id", "") == recommended_id)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_button_pressed.bind(i))
		b.focus_entered.connect(_on_focus.bind(i))
		b.mouse_entered.connect(_on_focus.bind(i))
		nodes_container.add_child(b)
		buttons.append(b)
	if buttons.size() > 0:
		# 점프/A를 누르던 입력이 떨어질 때까지 포커스 보류 — 자동 활성화 방지.
		GameState.arm_focus_after_release(self, buttons[0], PackedStringArray(["ui_accept", "jump", "ui_skip"]))

func _format_button_text(route: Dictionary, recommended: bool) -> String:
	var route_name: String = route.get("name", "?")
	var hidden: bool = route.get("hidden", false)
	var challenge: bool = route.get("challenge", false)
	var risk_str: String = "?" if hidden else _dots(route.get("risk", 0))
	var reward_str: String = "?" if hidden else _dots(route.get("reward", 0))
	var prefix: String = "[도전]\n" if challenge else ""
	var rec: String = "  ★" if recommended else ""
	return "%s%s%s\n\n위험  %s\n보상  %s" % [prefix, route_name, rec, risk_str, reward_str]

func _dots(n: int) -> String:
	var s: String = ""
	for i in n:
		s += "●"
	for i in (3 - n):
		s += "○"
	return s

func _on_focus(idx: int) -> void:
	hovered_idx = idx
	_update_veil_comment()

func _update_veil_comment() -> void:
	if hovered_idx < 0 or hovered_idx >= pool.size():
		return
	var route: Dictionary = pool[hovered_idx]
	var msg: String = ""
	var desc: String = str(route.get("description", ""))
	if desc != "":
		msg += desc + "\n\n"
	# prefix 시스템 폐지 — 짧은 prefix가 뒷 문장과 부자연스러움. 신뢰도는 색으로.
	msg += "VEIL  —  " + str(route.get("veil_comment", ""))
	# 위험도가 보이는 루트(hidden 아님)에서만 명시 경고
	if not route.get("hidden", false):
		var risk: int = int(route.get("risk", 0))
		if risk >= 3:
			msg += "\n[고위험] 적 수가 더 많고 반응 속도도 빨라요."
		var reward: int = int(route.get("reward", 0))
		if reward >= 3:
			msg += "\n[고보상] 클리어 보너스 경험치가 큽니다."
	veil_text.text = msg

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump"):
		_on_button_pressed(hovered_idx)

func _on_button_pressed(idx: int) -> void:
	if idx < 0 or idx >= pool.size():
		return
	var route: Dictionary = pool[idx]
	GameState.record_route_choice(route, recommended_id)
	get_tree().change_scene_to_file(SceneRouter.STAGE)
