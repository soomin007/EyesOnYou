extends Node

func _ready() -> void:
	_bind_default_mouse_inputs()
	_bind_wasd_to_ui()
	GameState.load_settings()
	GameState.reset()
	get_tree().change_scene_to_file(SceneRouter.TITLE)

# 마우스 좌/우 클릭을 attack/skill의 기본 이벤트로 추가.
# 사용자가 Settings에서 명시적으로 제거하면(v2 cfg) load_settings에서 덮어쓰므로 무시됨.
func _bind_default_mouse_inputs() -> void:
	_ensure_mouse_event("attack", MOUSE_BUTTON_LEFT)
	_ensure_mouse_event("skill", MOUSE_BUTTON_RIGHT)

func _ensure_mouse_event(action: String, btn: int) -> void:
	if not InputMap.has_action(action):
		return
	for e in InputMap.action_get_events(action):
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == btn:
			return
	var ev := InputEventMouseButton.new()
	ev.button_index = btn
	# 마우스 이벤트를 첫 번째 슬롯으로 (primary)
	var existing: Array = []
	for e in InputMap.action_get_events(action):
		existing.append(e)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, ev)
	for e in existing:
		InputMap.action_add_event(action, e)

# WASD를 ui_left/right/up/down에 추가 → 메뉴/스킬 선택을 WASD로 이동 가능
func _bind_wasd_to_ui() -> void:
	_ensure_key_event("ui_up", KEY_W)
	_ensure_key_event("ui_down", KEY_S)
	_ensure_key_event("ui_left", KEY_A)
	_ensure_key_event("ui_right", KEY_D)

func _ensure_key_event(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)
