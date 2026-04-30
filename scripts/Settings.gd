extends Control

signal closed

const ACTIONS: Array = [
	{"id": "move_left",  "name": "이동 (왼쪽)"},
	{"id": "move_right", "name": "이동 (오른쪽)"},
	{"id": "jump",       "name": "점프"},
	{"id": "attack",     "name": "공격"},
	{"id": "dash",       "name": "대시"},
	{"id": "pause",      "name": "설정 열기"},
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
	panel.custom_minimum_size = Vector2(720, 520)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	margin.add_child(v)

	var title := Label.new()
	title.text = "설정"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	v.add_child(title)

	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(tabs)

	tabs.add_child(_build_keybind_tab())
	tabs.add_child(_build_av_tab())

	var bottom_hb := HBoxContainer.new()
	bottom_hb.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(bottom_hb)
	var btn_reset := Button.new()
	btn_reset.text = "기본값으로"
	btn_reset.add_theme_font_size_override("font_size", 14)
	btn_reset.pressed.connect(_on_reset_pressed)
	bottom_hb.add_child(btn_reset)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(12, 0)
	bottom_hb.add_child(spacer)
	var btn_close := Button.new()
	btn_close.text = "닫기"
	btn_close.add_theme_font_size_override("font_size", 14)
	btn_close.pressed.connect(_on_close_pressed)
	bottom_hb.add_child(btn_close)

	_refresh_all_keybind_buttons()

func _build_keybind_tab() -> Control:
	var v := VBoxContainer.new()
	v.name = "조작법"
	v.add_theme_constant_override("separation", 8)

	var hint := Label.new()
	hint.text = "키를 변경하려면 버튼을 클릭한 뒤 새 키를 누르세요. (각 액션당 최대 2개)"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)

	for entry in ACTIONS:
		var action_id: String = str(entry["id"])
		var label := Label.new()
		label.text = str(entry["name"])
		label.custom_minimum_size = Vector2(180, 32)
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
		grid.add_child(label)

		var btns: Array = []
		for i in MAX_KEYS_PER_ACTION:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(160, 32)
			btn.add_theme_font_size_override("font_size", 13)
			btn.pressed.connect(_on_key_button_pressed.bind(action_id, i, btn))
			grid.add_child(btn)
			btns.append(btn)
		key_buttons[action_id] = btns
	return v

func _build_av_tab() -> Control:
	var v := VBoxContainer.new()
	v.name = "그래픽/사운드"
	v.add_theme_constant_override("separation", 14)

	var res_label := Label.new()
	res_label.text = "화면 해상도 — 1280×720 (Web Export 기준)"
	res_label.add_theme_font_size_override("font_size", 14)
	res_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	v.add_child(res_label)

	v.add_child(_make_volume_row("마스터 볼륨", "master"))
	v.add_child(_make_volume_row("효과음 볼륨", "sfx"))

	var note := Label.new()
	note.text = "사운드는 추후 추가 예정 — UI는 미리 노출."
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	v.add_child(note)
	return v

func _make_volume_row(label_text: String, kind: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(140, 28)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
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
			if i < events.size() and events[i] is InputEventKey:
				btn.text = _key_label(events[i] as InputEventKey)
			else:
				btn.text = "—"
			btn.disabled = false

func _key_label(ev: InputEventKey) -> String:
	var kc: int = ev.physical_keycode
	if kc == 0:
		kc = ev.keycode
	var name := OS.get_keycode_string(kc)
	if name == "":
		name = "Key %d" % kc
	return name

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
	if not (event is InputEventKey):
		return
	var ke := event as InputEventKey
	if not ke.pressed or ke.echo:
		return
	get_viewport().set_input_as_handled()
	if ke.physical_keycode == KEY_ESCAPE and capturing_action != "pause":
		_cancel_capture()
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
	var new_ev := InputEventKey.new()
	new_ev.physical_keycode = ke.physical_keycode
	new_events[index] = new_ev

	InputMap.action_erase_events(action_id)
	for e in new_events:
		if e is InputEventKey:
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
	var defaults := {
		"move_left":  [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump":       [KEY_SPACE, KEY_W],
		"attack":     [KEY_J],
		"dash":       [KEY_SHIFT, KEY_K],
		"pause":      [KEY_ESCAPE],
	}
	for action_id in defaults.keys():
		if not InputMap.has_action(action_id):
			continue
		InputMap.action_erase_events(action_id)
		for kc in defaults[action_id]:
			var ev := InputEventKey.new()
			ev.physical_keycode = int(kc)
			InputMap.action_add_event(action_id, ev)

func _on_close_pressed() -> void:
	emit_signal("closed")
