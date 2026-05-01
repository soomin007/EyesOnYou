extends Control

signal closed

const ACTIONS: Array = [
	{"id": "move_left",  "name": "이동 (왼쪽)"},
	{"id": "move_right", "name": "이동 (오른쪽)"},
	{"id": "jump",       "name": "점프"},
	{"id": "attack",     "name": "사격"},
	{"id": "dash",       "name": "대시"},
	{"id": "skill",      "name": "액티브 스킬 (폭발물 등)"},
	{"id": "pause",      "name": "일시정지 / 메뉴"},
]

const MAX_KEYS_PER_ACTION: int = 2

var capturing_action: String = ""
var capturing_index: int = -1
var capturing_button: Button = null

var key_buttons: Dictionary = {}  # action_id -> Array[Button]

var dim: ColorRect
var panel: PanelContainer
var tabs: TabContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 580)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.08, 0.10, 0.98)
	panel_style.border_color = Color(0.55, 0.62, 0.78, 0.55)
	panel_style.set_border_width_all(1)
	panel_style.content_margin_left = 36
	panel_style.content_margin_right = 36
	panel_style.content_margin_top = 32
	panel_style.content_margin_bottom = 32
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)

	var title := Label.new()
	title.text = "설정"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	v.add_child(title)

	var divider := ColorRect.new()
	divider.color = Color(0.55, 0.62, 0.78, 0.30)
	divider.custom_minimum_size = Vector2(0, 1)
	v.add_child(divider)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0, 380)
	v.add_child(tabs)

	tabs.add_child(_build_keybind_tab())
	tabs.add_child(_build_av_tab())
	tabs.add_child(_build_debug_tab())

	var divider2 := ColorRect.new()
	divider2.color = Color(0.55, 0.62, 0.78, 0.30)
	divider2.custom_minimum_size = Vector2(0, 1)
	v.add_child(divider2)

	var bottom_hb := HBoxContainer.new()
	bottom_hb.alignment = BoxContainer.ALIGNMENT_END
	bottom_hb.add_theme_constant_override("separation", 12)
	v.add_child(bottom_hb)
	var btn_reset := _make_secondary_button("기본값으로")
	btn_reset.pressed.connect(_on_reset_pressed)
	bottom_hb.add_child(btn_reset)
	var btn_close := _make_primary_button("닫기")
	btn_close.pressed.connect(_on_close_pressed)
	bottom_hb.add_child(btn_close)

	_refresh_all_keybind_buttons()

func _build_keybind_tab() -> Control:
	var outer := MarginContainer.new()
	outer.name = "조작법"
	outer.add_theme_constant_override("margin_left", 16)
	outer.add_theme_constant_override("margin_right", 16)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 18)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	outer.add_child(v)

	var hint := Label.new()
	hint.text = "키 또는 마우스 버튼을 변경하려면 슬롯을 클릭한 뒤 새 입력을 누르세요. 각 액션당 최대 2개까지 등록할 수 있어요."
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)

	for entry in ACTIONS:
		var action_id: String = str(entry["id"])
		var label := Label.new()
		label.text = str(entry["name"])
		label.custom_minimum_size = Vector2(180, 36)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		grid.add_child(label)

		var btns: Array = []
		for i in MAX_KEYS_PER_ACTION:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(160, 36)
			btn.add_theme_font_size_override("font_size", 13)
			btn.pressed.connect(_on_key_button_pressed.bind(action_id, i, btn))
			grid.add_child(btn)
			btns.append(btn)
		key_buttons[action_id] = btns
	return outer

func _build_debug_tab() -> Control:
	var outer := MarginContainer.new()
	outer.name = "디버그"
	outer.add_theme_constant_override("margin_left", 16)
	outer.add_theme_constant_override("margin_right", 16)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 18)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	outer.add_child(v)

	v.add_child(_make_section_header("연습장"))

	var note := Label.new()
	note.text = "스테이지/루트/난이도를 자유롭게 바꿔가며 테스트할 수 있어요. HUD에 토글 패널이 떠 있어 그 자리에서 설정을 바꾸면 맵이 즉시 다시 생성됩니다. 일반 진행 데이터에는 영향 없음."
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)

	var enter_btn := Button.new()
	enter_btn.text = "연습장으로 진입"
	enter_btn.custom_minimum_size = Vector2(220, 40)
	enter_btn.add_theme_font_size_override("font_size", 14)
	enter_btn.pressed.connect(_on_playground_pressed)
	v.add_child(enter_btn)

	return outer

func _on_playground_pressed() -> void:
	GameState.playground_active = true
	GameState.current_stage = 0
	GameState.current_route_id = "route_lab"
	GameState.current_route_tags = ["전투", "드론", "밝은_환경"]
	GameState.current_route_risk = 2
	GameState.current_route_reward = 2
	GameState.player_hp = GameState.player_max_hp
	GameState.player_xp = 0
	GameState.player_level = 1
	# pause 메뉴에서 진입한 경우 paused 해제 후 scene 전환
	get_tree().paused = false
	get_tree().change_scene_to_file(SceneRouter.STAGE)

func _build_av_tab() -> Control:
	var outer := MarginContainer.new()
	outer.name = "그래픽 / 사운드"
	outer.add_theme_constant_override("margin_left", 16)
	outer.add_theme_constant_override("margin_right", 16)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 18)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	outer.add_child(v)

	var section_a := _make_section("화면", "1280 × 720 고정 — Web Export 기준")
	v.add_child(section_a)

	var section_b := VBoxContainer.new()
	section_b.add_theme_constant_override("separation", 10)
	v.add_child(section_b)
	section_b.add_child(_make_section_header("사운드"))
	section_b.add_child(_make_volume_row("마스터 볼륨", "master"))
	section_b.add_child(_make_volume_row("효과음 볼륨", "sfx"))
	var note := Label.new()
	note.text = "사운드는 추후 추가 예정 — 슬라이더는 미리 노출."
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	section_b.add_child(note)
	return outer

func _make_section_header(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	return l

func _make_section(header: String, body: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(_make_section_header(header))
	var b := Label.new()
	b.text = body
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color(0.78, 0.80, 0.84))
	v.add_child(b)
	return v

func _make_volume_row(label_text: String, kind: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(140, 28)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(280, 28)
	slider.value = GameState.master_volume if kind == "master" else GameState.sfx_volume
	slider.value_changed.connect(_on_volume_changed.bind(kind))
	hb.add_child(slider)
	return hb

func _make_primary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 36)
	b.add_theme_font_size_override("font_size", 14)
	return b

func _make_secondary_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(140, 36)
	b.add_theme_font_size_override("font_size", 13)
	return b

func _on_volume_changed(value: float, kind: String) -> void:
	if kind == "master":
		GameState.master_volume = value
	else:
		GameState.sfx_volume = value
	GameState.save_settings()

func _refresh_all_keybind_buttons() -> void:
	for entry in ACTIONS:
		var action_id: String = str(entry["id"])
		var btns: Array = key_buttons.get(action_id, [])
		var events: Array = []
		if InputMap.has_action(action_id):
			events = InputMap.action_get_events(action_id)
		for i in btns.size():
			var btn: Button = btns[i]
			if i < events.size():
				btn.text = _event_label(events[i])
			else:
				btn.text = "—"
			btn.disabled = false

func _event_label(ev: InputEvent) -> String:
	if ev is InputEventKey:
		var ke := ev as InputEventKey
		var kc: int = ke.physical_keycode
		if kc == 0:
			kc = ke.keycode
		var n := OS.get_keycode_string(kc)
		if n == "":
			n = "Key %d" % kc
		return n
	elif ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:   return "마우스 왼쪽"
			MOUSE_BUTTON_RIGHT:  return "마우스 오른쪽"
			MOUSE_BUTTON_MIDDLE: return "마우스 가운데"
			MOUSE_BUTTON_XBUTTON1: return "마우스 X1"
			MOUSE_BUTTON_XBUTTON2: return "마우스 X2"
			_: return "마우스 버튼 %d" % mb.button_index
	return "—"

func _on_key_button_pressed(action_id: String, index: int, btn: Button) -> void:
	if capturing_action != "":
		return
	capturing_action = action_id
	capturing_index = index
	capturing_button = btn
	btn.text = "새 키를 누르세요..."
	_set_all_buttons_disabled(true)
	btn.disabled = true

func _set_all_buttons_disabled(value: bool) -> void:
	for action_id in key_buttons.keys():
		for b in key_buttons[action_id]:
			(b as Button).disabled = value

func _input(event: InputEvent) -> void:
	if capturing_action == "":
		return
	var new_ev: InputEvent = null
	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		get_viewport().set_input_as_handled()
		if ke.physical_keycode == KEY_ESCAPE and capturing_action != "pause":
			_cancel_capture()
			return
		var key_ev := InputEventKey.new()
		key_ev.physical_keycode = ke.physical_keycode
		new_ev = key_ev
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.canceled:
			return
		# 휠/드래그는 무시
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_LEFT or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			return
		get_viewport().set_input_as_handled()
		var mouse_ev := InputEventMouseButton.new()
		mouse_ev.button_index = mb.button_index
		new_ev = mouse_ev
	else:
		return

	var action_id: String = capturing_action
	var index: int = capturing_index
	var current_events: Array = []
	if InputMap.has_action(action_id):
		current_events = InputMap.action_get_events(action_id)
	var new_events: Array = []
	for e in current_events:
		new_events.append(e)
	while new_events.size() <= index:
		new_events.append(null)
	new_events[index] = new_ev

	InputMap.action_erase_events(action_id)
	for e in new_events:
		if e is InputEventKey or e is InputEventMouseButton:
			InputMap.action_add_event(action_id, e)

	capturing_action = ""
	capturing_index = -1
	capturing_button = null
	_set_all_buttons_disabled(false)
	_refresh_all_keybind_buttons()
	GameState.save_settings()

func _cancel_capture() -> void:
	capturing_action = ""
	capturing_index = -1
	capturing_button = null
	_set_all_buttons_disabled(false)
	_refresh_all_keybind_buttons()

func _on_reset_pressed() -> void:
	_apply_default_keybindings()
	_refresh_all_keybind_buttons()
	GameState.save_settings()

func _apply_default_keybindings() -> void:
	# 각 entry는 ["key", keycode] 또는 ["mouse", button_index]
	var defaults := {
		"move_left":  [["key", KEY_A], ["key", KEY_LEFT]],
		"move_right": [["key", KEY_D], ["key", KEY_RIGHT]],
		"jump":       [["key", KEY_W], ["key", KEY_SPACE]],
		"attack":     [["mouse", MOUSE_BUTTON_LEFT], ["key", KEY_J]],
		"dash":       [["key", KEY_SHIFT], ["key", KEY_K]],
		"skill":      [["mouse", MOUSE_BUTTON_RIGHT], ["key", KEY_Q]],
		"pause":      [["key", KEY_ESCAPE]],
	}
	for action_id in defaults.keys():
		if not InputMap.has_action(action_id):
			continue
		InputMap.action_erase_events(action_id)
		for entry in defaults[action_id]:
			var t: String = str(entry[0])
			var code: int = int(entry[1])
			if t == "key":
				var ev := InputEventKey.new()
				ev.physical_keycode = code
				InputMap.action_add_event(action_id, ev)
			elif t == "mouse":
				var mev := InputEventMouseButton.new()
				mev.button_index = code
				InputMap.action_add_event(action_id, mev)

func _on_close_pressed() -> void:
	emit_signal("closed")
