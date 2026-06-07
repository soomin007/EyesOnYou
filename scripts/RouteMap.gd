extends Control

@onready var stage_label: Label = $Header/Stage
@onready var subtitle_label: Label = $Header/Subtitle
@onready var nodes_container: HBoxContainer = $Center/Nodes
@onready var veil_box: PanelContainer = $VeilBox
@onready var veil_text: Label = $VeilBox/Margin/V/Text
@onready var hint_label: Label = $Footer/Hint

var pool: Array = []
var recommended_id: String = ""
var recommended_reason: String = ""
var hovered_idx: int = 0
var buttons: Array = []
# 고위험/고보상 별도 패널 (사용자 피드백: 본 멘트에 겹치면 너무 많아짐).
var risk_reward_panel: PanelContainer = null
var risk_reward_label: Label = null

func _ready() -> void:
	# 안전망: 이전 scene에서 paused가 carry되어 메뉴가 freeze되는 패턴 차단.
	get_tree().paused = false
	stage_label.text = "STAGE %d / %d  —  루트 선택" % [GameState.current_stage + 1, GameState.effective_total_stages()]
	subtitle_label.text = "● 위험도 / 보상   —   ? 미상"
	pool = RouteData.get_route_pool_for_stage(GameState.current_stage, GameState.route_history)
	var rec: Dictionary = RouteData.choose_veil_recommendation_with_reason(pool)
	recommended_id = str(rec.get("id", ""))
	recommended_reason = str(rec.get("reason", ""))
	# VEIL 멘트 — 신뢰도 톤(색)을 _ready에서 한 번만 적용. 폰트는 22로 키워
	# 선택 화면에서 분명히 눈에 들어오게 (이전 15는 카드에 묻혀 안 보였음).
	veil_text.add_theme_font_size_override("font_size", 22)
	veil_text.add_theme_color_override("font_color", GameState.veil_tone_color())
	# 긴 description이 박스 밖으로 빠져나가던 문제 — 자동 줄바꿈.
	veil_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	veil_text.custom_minimum_size = Vector2(560, 0)
	_setup_trust_gauge()
	_build_progress_strip()
	_build_risk_reward_panel()
	_build_node_buttons()
	_update_veil_comment()
	_refresh_hint()
	GameState.input_kind_changed.connect(_on_input_kind_changed)

func _build_risk_reward_panel() -> void:
	# VeilBox 우측에 작은 패널 — 고위험/고보상 경고를 본 멘트와 분리해서 표시.
	risk_reward_panel = PanelContainer.new()
	risk_reward_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	risk_reward_panel.anchor_left = 0.78
	# VeilBox가 0.68로 위로 올라간 데 맞춰 risk 패널도 같이 이동 (사용자 보고:
	# VeilBox와 Footer 키 안내 겹침 — VeilBox top 0.76→0.68 변경).
	risk_reward_panel.anchor_top = 0.54
	risk_reward_panel.anchor_right = 0.97
	risk_reward_panel.anchor_bottom = 0.66
	risk_reward_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.10, 0.08, 0.88)
	sb.border_color = Color(0.85, 0.55, 0.35, 0.55)
	sb.set_border_width_all(1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	risk_reward_panel.add_theme_stylebox_override("panel", sb)
	risk_reward_panel.visible = false
	add_child(risk_reward_panel)
	risk_reward_label = Label.new()
	risk_reward_label.add_theme_font_size_override("font_size", 13)
	risk_reward_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.65))
	risk_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	risk_reward_panel.add_child(risk_reward_label)

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

# 진행 노드맵 — 헤더와 루트 카드 사이 가로 띠로 "지나온 경로 / 지금 / 남은 단계"를 표시.
# 데이터는 이미 존재(route_history·current_stage·effective_total_stages) — 시각화만 추가.
# 불변식: RouteMap이 뜬 시점에 route_history.size() == current_stage (i단계 선택 = history[i]).
const PROG_DONE_DOT: Color = Color(0.45, 0.80, 0.62)    # 클리어한 단계 (차분한 초록)
const PROG_DONE_TEXT: Color = Color(0.58, 0.66, 0.62)
const PROG_DONE_LINE: Color = Color(0.34, 0.50, 0.44)
const PROG_FUTURE: Color = Color(0.40, 0.43, 0.50)      # 미상 단계 (흐릿)
const PROG_FUTURE_LINE: Color = Color(0.24, 0.26, 0.32)

func _build_progress_strip() -> void:
	var total: int = GameState.effective_total_stages()
	var cur: int = GameState.current_stage
	var strip := CenterContainer.new()
	strip.name = "ProgressStrip"
	strip.anchor_left = 0.0
	strip.anchor_top = 0.175
	strip.anchor_right = 1.0
	strip.anchor_bottom = 0.245
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(row)
	for i in total:
		if i > 0:
			# i단계로 들어가는 연결선 — 그 단계에 도달했으면(i <= cur) "지나온" 색.
			row.add_child(_make_progress_connector(i <= cur))
		row.add_child(_make_progress_node(i, cur))

func _make_progress_node(i: int, cur: int) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(88, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := Label.new()
	dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot.add_theme_font_size_override("font_size", 16)
	var name_l := Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 11)
	name_l.clip_text = true
	if i < cur:
		# 지나온 단계 — 선택했던 맵 이름 표시.
		var rid: String = str(GameState.route_history[i]) if i < GameState.route_history.size() else ""
		dot.text = "●"
		dot.add_theme_color_override("font_color", PROG_DONE_DOT)
		name_l.text = RouteData.name_for_id(rid)
		name_l.add_theme_color_override("font_color", PROG_DONE_TEXT)
	elif i == cur:
		# 지금 고르는 단계 — VEIL 신뢰 톤색으로 강조.
		var tone: Color = GameState.veil_tone_color()
		dot.text = "◆"
		dot.add_theme_color_override("font_color", tone)
		name_l.text = "지금"
		name_l.add_theme_color_override("font_color", tone)
	else:
		# 아직 모르는 앞 단계.
		dot.text = "○"
		dot.add_theme_color_override("font_color", PROG_FUTURE)
		name_l.text = "?"
		name_l.add_theme_color_override("font_color", PROG_FUTURE)
	box.add_child(dot)
	box.add_child(name_l)
	return box

func _make_progress_connector(done: bool) -> Control:
	# 노드와 같은 2단 구조(선 / 빈칸)로 만들어 점·이름 행 높이를 맞춘다.
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(24, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := Label.new()
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", 16)
	line.text = "──"
	line.add_theme_color_override("font_color", PROG_DONE_LINE if done else PROG_FUTURE_LINE)
	var spacer := Label.new()
	spacer.add_theme_font_size_override("font_size", 11)
	spacer.text = " "
	box.add_child(line)
	box.add_child(spacer)
	return box

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
		# 메뉴 등장 직후 1초 동안 포커스 보류 — 점프 연타로 자동 활성화되는 사고 방지.
		GameState.arm_focus_with_delay(self, buttons[0])

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
	# description은 카드에서 제거 — veil_comment와 같은 위협을 중복 서술해 군더더기였음
	# (사용자 피드백 2026-06-06: "설명 부분과 밑 VEIL 코멘트가 너무 겹친다").
	# VEIL이 직접 안내하는 한 목소리만 남긴다.
	# 추천 맵: ★ 옆엔 "베일 추천"만, 추천 사유는 라벨이 아니라 VEIL이 직접 말로(멘트 자리에).
	# 비추천 맵: 그 맵 고유 veil_comment.
	var is_recommended: bool = (route.get("id", "") == recommended_id and recommended_reason != "")
	if is_recommended:
		msg += "★ 베일 추천\n"
		msg += "VEIL  —  " + recommended_reason
	else:
		msg += "VEIL  —  " + str(route.get("veil_comment", ""))
	veil_text.text = msg
	# 고위험/고보상 경고는 별도 우측 패널로 — 본 멘트와 시각 분리.
	_update_risk_reward_panel(route)

func _update_risk_reward_panel(route: Dictionary) -> void:
	if risk_reward_panel == null or risk_reward_label == null:
		return
	if route.get("hidden", false):
		risk_reward_panel.visible = false
		return
	var lines: Array = []
	var risk: int = int(route.get("risk", 0))
	if risk >= 3:
		lines.append("[고위험]\n적 수와 반응 속도가 강해요.")
	var reward: int = int(route.get("reward", 0))
	if reward >= 3:
		lines.append("[고보상]\n클리어 보너스 경험치가 큽니다.")
	if lines.is_empty():
		risk_reward_panel.visible = false
		return
	risk_reward_label.text = "\n\n".join(lines)
	risk_reward_panel.visible = true

func _input(event: InputEvent) -> void:
	# 스페이스(점프 키)로는 맵 확정 금지 — 플레이 중 점프 습관 탓에 맵이 뜨자마자 의도치 않게
	# 카드가 선택돼버리는 것 방지(사용자). _input은 GUI·_unhandled_input보다 먼저 처리되므로
	# 여기서 소비하면 버튼 ui_accept와 아래 jump 분기 양쪽 다 막힌다. Enter·W·클릭으로는 정상 확정.
	if event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump"):
		_on_button_pressed(hovered_idx)

func _on_button_pressed(idx: int) -> void:
	if idx < 0 or idx >= pool.size():
		return
	var route: Dictionary = pool[idx]
	GameState.record_route_choice(route, recommended_id)
	get_tree().change_scene_to_file(SceneRouter.STAGE)
