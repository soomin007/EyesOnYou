extends Control

# 다단계 메인 메뉴 — 키보드/마우스/패드 모두 동일한 흐름.
#   STATE_MAIN  : 게임 시작 / 설정 / 게임 종료
#   STATE_MODE  : 일반 모드 / 스토리 모드 / 뒤로
#   STATE_TUTOR : 튜토리얼부터 시작? 예 / 아니오 / 뒤로
# 각 단계는 Buttons VBox를 비우고 다시 빌드. ESC/패드 B는 한 단계 뒤로.

enum { STATE_MAIN, STATE_MODE, STATE_TUTOR }

@onready var hint_label: Label = $Center/V/Hint
@onready var buttons_box: VBoxContainer = $Center/V/Buttons

var blink_t: float = 0.0
var settings_overlay: Control = null
var state: int = STATE_MAIN
# 모드 선택 단계에서 결정 — TUTOR 단계에서 사용.
var picked_story: bool = false

func _ready() -> void:
	GameState.reset()
	# 부스/QR 환경 가정 — 매 타이틀 진입은 새 플레이어 세션. 도감을 비워서 첫 조우 카드가
	# 다시 뜨도록.
	GameState.seen_enemies.clear()
	GameState.save_settings()
	_set_state(STATE_MAIN)

func _process(delta: float) -> void:
	blink_t += delta
	if hint_label != null:
		hint_label.modulate.a = 0.5 + 0.5 * sin(blink_t * 3.0)

func _set_state(new_state: int) -> void:
	state = new_state
	for c in buttons_box.get_children():
		c.queue_free()
	match state:
		STATE_MAIN:
			hint_label.text = "[ ↑↓ 이동   A/Enter 선택 ]"
			var b_start := _make_button("게임 시작")
			b_start.pressed.connect(_on_start_pressed)
			buttons_box.add_child(b_start)
			var b_settings := _make_button("설정")
			b_settings.pressed.connect(_on_settings_pressed)
			buttons_box.add_child(b_settings)
			var b_quit := _make_button("게임 종료")
			b_quit.pressed.connect(_on_quit_pressed)
			buttons_box.add_child(b_quit)
			b_start.grab_focus.call_deferred()
		STATE_MODE:
			hint_label.text = "[ 모드 선택   ESC/B 뒤로 ]"
			var b_normal := _make_button("일반 모드")
			b_normal.pressed.connect(_on_mode_pressed.bind(false))
			buttons_box.add_child(b_normal)
			var b_story := _make_button("스토리 모드  (체력 무제한 · 단순)")
			b_story.pressed.connect(_on_mode_pressed.bind(true))
			buttons_box.add_child(b_story)
			var b_back := _make_button("뒤로")
			b_back.pressed.connect(_on_back_pressed)
			buttons_box.add_child(b_back)
			b_normal.grab_focus.call_deferred()
		STATE_TUTOR:
			hint_label.text = "[ 튜토리얼부터 진행할까요? ]"
			var b_yes := _make_button("예 — 튜토리얼부터")
			b_yes.pressed.connect(_on_tutor_pressed.bind(true))
			buttons_box.add_child(b_yes)
			var b_no := _make_button("아니오 — 바로 시작")
			b_no.pressed.connect(_on_tutor_pressed.bind(false))
			buttons_box.add_child(b_no)
			var b_back := _make_button("뒤로")
			b_back.pressed.connect(_on_back_pressed)
			buttons_box.add_child(b_back)
			b_yes.grab_focus.call_deferred()

func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 44)
	b.add_theme_font_size_override("font_size", 18)
	return b

func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay != null:
		return
	# 한 단계 뒤로 — ESC, 패드 B (둘 다 ui_cancel에 매핑).
	if event.is_action_pressed("ui_cancel"):
		if state != STATE_MAIN:
			_on_back_pressed()
			get_viewport().set_input_as_handled()

func _on_start_pressed() -> void:
	_set_state(STATE_MODE)

func _on_mode_pressed(story: bool) -> void:
	picked_story = story
	GameState.story_mode = story
	_set_state(STATE_TUTOR)

func _on_tutor_pressed(want_tutorial: bool) -> void:
	# 모드(story_mode)는 모드 선택에서 이미 GameState에 박혔다. 여기선 튜토리얼 분기만.
	if want_tutorial:
		get_tree().change_scene_to_file(SceneRouter.TUTORIAL)
	else:
		get_tree().change_scene_to_file(SceneRouter.BRIEFING)

func _on_back_pressed() -> void:
	match state:
		STATE_TUTOR:
			# 모드 선택으로 — story_mode 다시 끄고 돌아감
			GameState.story_mode = false
			_set_state(STATE_MODE)
		STATE_MODE:
			_set_state(STATE_MAIN)

func _on_settings_pressed() -> void:
	if settings_overlay != null:
		return
	var packed := load(SceneRouter.SETTINGS) as PackedScene
	if packed == null:
		return
	settings_overlay = packed.instantiate()
	add_child(settings_overlay)
	if settings_overlay.has_signal("closed"):
		settings_overlay.closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	if settings_overlay != null:
		settings_overlay.queue_free()
		settings_overlay = null

func _on_quit_pressed() -> void:
	get_tree().quit()
