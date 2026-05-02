class_name PlaygroundOverlay
extends Node

# 디버그 연습장 패널 — Stage._ready에서 playground_active일 때만 부착.
# 토글 버튼은 항상 떠 있고, 패널은 클릭 시 펼쳐짐.
# 항목을 누르면 GameState 값을 갱신하고 scene을 reload.

const ROUTE_OPTIONS: Array = [
	{"id": "route_back_alley", "label": "외곽"},
	{"id": "route_rooftops",   "label": "옥상"},
	{"id": "route_sewers",     "label": "배수로"},
	{"id": "route_subway",     "label": "지하철"},
	{"id": "route_cooling",    "label": "냉각"},
	{"id": "route_watchtower", "label": "감시탑"},
	{"id": "route_ward",       "label": "병동"},
	{"id": "route_datacenter", "label": "데이터"},
	{"id": "route_escape",     "label": "탈출로"},
	{"id": "route_lab",        "label": "핵심부"},
	{"id": "route_hidden",     "label": "???"},
]

var layer: CanvasLayer
var toggle_button: Button
var panel: PanelContainer
var open: bool = false

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)

	toggle_button = Button.new()
	toggle_button.text = "▼ 연습장"
	toggle_button.add_theme_font_size_override("font_size", 13)
	toggle_button.position = Vector2(20, 56)
	toggle_button.custom_minimum_size = Vector2(110, 28)
	toggle_button.pressed.connect(_toggle_panel)
	layer.add_child(toggle_button)

func _toggle_panel() -> void:
	if open:
		_close_panel()
	else:
		_open_panel()

func _open_panel() -> void:
	open = true
	toggle_button.text = "▲ 연습장"
	panel = PanelContainer.new()
	panel.position = Vector2(20, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.10, 0.95)
	style.border_color = Color(0.55, 0.62, 0.78, 0.55)
	style.set_border_width_all(1)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	v.add_child(_build_stage_row())
	v.add_child(_build_route_row())
	v.add_child(_build_int_row("Risk", "current_route_risk", _on_risk_pressed))
	v.add_child(_build_int_row("Reward", "current_route_reward", _on_reward_pressed))

	var sep := HSeparator.new()
	v.add_child(sep)
	var exit_btn := Button.new()
	exit_btn.text = "연습장 종료 (타이틀로)"
	exit_btn.add_theme_font_size_override("font_size", 13)
	exit_btn.pressed.connect(_on_exit)
	v.add_child(exit_btn)

func _close_panel() -> void:
	open = false
	toggle_button.text = "▼ 연습장"
	if panel != null and is_instance_valid(panel):
		panel.queue_free()
	panel = null

# ─── 행 빌더 ────────────────────────────────────────────────

func _build_stage_row() -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(_make_row_label("스테이지"))
	for i in GameState.TOTAL_STAGES:
		var b := Button.new()
		b.text = "%d" % (i + 1)
		b.custom_minimum_size = Vector2(36, 28)
		b.add_theme_font_size_override("font_size", 13)
		if GameState.current_stage == i:
			b.disabled = true
		b.pressed.connect(_on_stage_pressed.bind(i))
		hb.add_child(b)
	return hb

func _build_route_row() -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(_make_row_label("루트"))
	for opt in ROUTE_OPTIONS:
		var d: Dictionary = opt
		var rid: String = str(d.get("id", ""))
		var b := Button.new()
		b.text = str(d.get("label", rid))
		b.custom_minimum_size = Vector2(70, 28)
		b.add_theme_font_size_override("font_size", 13)
		if GameState.current_route_id == rid:
			b.disabled = true
		b.pressed.connect(_on_route_pressed.bind(rid))
		hb.add_child(b)
	return hb

func _build_int_row(label_text: String, prop_name: String, cb: Callable) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(_make_row_label(label_text))
	for n in [1, 2, 3]:
		var b := Button.new()
		b.text = "%d" % n
		b.custom_minimum_size = Vector2(36, 28)
		b.add_theme_font_size_override("font_size", 13)
		if int(GameState.get(prop_name)) == n:
			b.disabled = true
		b.pressed.connect(cb.bind(n))
		hb.add_child(b)
	return hb

func _make_row_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(70, 28)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.78, 0.85, 0.95))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

# ─── 버튼 핸들러 ────────────────────────────────────────────

func _on_stage_pressed(idx: int) -> void:
	GameState.current_stage = idx
	_reload()

func _on_route_pressed(rid: String) -> void:
	GameState.current_route_id = rid
	# RouteData에서 같은 id의 tags/risk/reward는 그대로 가져옴.
	# 단, risk/reward는 패널의 별도 행에서 사용자가 따로 지정한 값 우선 → 덮어쓰지 않음.
	for r in RouteData.ALL_ROUTES:
		var route: Dictionary = r
		if route.get("id", "") == rid:
			GameState.current_route_tags = route.get("tags", [])
			break
	_reload()

func _on_risk_pressed(n: int) -> void:
	GameState.current_route_risk = n
	_reload()

func _on_reward_pressed(n: int) -> void:
	GameState.current_route_reward = n
	_reload()

func _on_exit() -> void:
	GameState.playground_active = false
	GameState.reset()
	get_tree().change_scene_to_file(SceneRouter.TITLE)

func _reload() -> void:
	# Stage scene을 다시 로드 — _ready에서 새 GameState 값으로 빌드.
	# playground_active가 true이므로 패널도 다시 부착됨.
	get_tree().reload_current_scene()
