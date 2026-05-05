extends Control

# 다단계 메인 메뉴 — 키보드/마우스/패드 모두 동일한 흐름.
#   STATE_MAIN  : 게임 시작 / 설정 / 게임 종료
#   STATE_MODE  : 일반 모드 / 스토리 모드 / 뒤로
#   STATE_TUTOR : 튜토리얼부터 시작? 예 / 아니오 / 뒤로
# 각 단계는 Buttons VBox를 비우고 다시 빌드. ESC/패드 B는 한 단계 뒤로.

enum { STATE_MAIN, STATE_MODE, STATE_TUTOR }

@onready var hint_label: Label = $Center/V/Hint
@onready var buttons_box: VBoxContainer = $Center/V/Buttons
@onready var center_node: CenterContainer = $Center

var blink_t: float = 0.0
var settings_overlay: Control = null
var state: int = STATE_MAIN
# 모드 선택 단계에서 결정 — TUTOR 단계에서 사용.
var picked_story: bool = false
# STATE_MODE 전용 설명 패널 (오른쪽 회색 박스).
var description_panel: PanelContainer = null
var description_title_label: Label = null
var description_text_label: Label = null
var description_icon: ColorRect = null

func _ready() -> void:
	GameState.reset()
	# 부스/QR 환경 가정 — 매 타이틀 진입은 새 플레이어 세션. 도감을 비워서 첫 조우 카드가
	# 다시 뜨도록.
	GameState.seen_enemies.clear()
	GameState.save_settings()
	GameState.input_kind_changed.connect(_on_input_kind_changed)
	_build_description_panel()
	_set_state(STATE_MAIN)

func _build_description_panel() -> void:
	# STATE_MODE에서만 보이는 우측 회색 설명 박스. 포커스에 따라 동적 갱신.
	description_panel = PanelContainer.new()
	description_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	description_panel.anchor_left = 0.55
	description_panel.anchor_top = 0.36
	description_panel.anchor_right = 0.92
	description_panel.anchor_bottom = 0.78
	description_panel.visible = false
	description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.14, 0.17, 0.92)
	sb.border_color = Color(0.45, 0.5, 0.6, 0.55)
	sb.set_border_width_all(1)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	description_panel.add_theme_stylebox_override("panel", sb)
	add_child(description_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	description_panel.add_child(v)
	# 간단한 도형 아이콘 — 모드별 색깔 다름. 작은 사각형 + 외곽선 느낌.
	description_icon = ColorRect.new()
	description_icon.color = Color(0.62, 0.78, 0.92)
	description_icon.custom_minimum_size = Vector2(56, 56)
	description_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(description_icon)
	description_title_label = Label.new()
	description_title_label.add_theme_font_size_override("font_size", 22)
	description_title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	description_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(description_title_label)
	description_text_label = Label.new()
	description_text_label.add_theme_font_size_override("font_size", 14)
	description_text_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.88))
	description_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(description_text_label)

func _on_input_kind_changed(_kind: String) -> void:
	_refresh_hint()

func _refresh_hint() -> void:
	if hint_label == null:
		return
	match state:
		STATE_MAIN:
			hint_label.text = GameState.hint("[ ↑↓ 이동   Enter 선택 ]", "[ ↑↓ D-Pad   A 선택 ]")
			hint_label.add_theme_font_size_override("font_size", 16)
			hint_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		STATE_MODE:
			hint_label.text = "어느 모드로 시작할까요?"
			hint_label.add_theme_font_size_override("font_size", 22)
			hint_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		STATE_TUTOR:
			hint_label.text = "튜토리얼부터 진행할까요?"
			hint_label.add_theme_font_size_override("font_size", 22)
			hint_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))

func _process(delta: float) -> void:
	blink_t += delta
	if hint_label != null:
		# 메인 메뉴에서만 가벼운 깜빡임. 질문 단계(MODE/TUTOR)는 또렷하게 고정.
		if state == STATE_MAIN:
			hint_label.modulate.a = 0.5 + 0.5 * sin(blink_t * 3.0)
		else:
			hint_label.modulate.a = 1.0

func _set_state(new_state: int) -> void:
	state = new_state
	for c in buttons_box.get_children():
		c.queue_free()
	# 모드 선택일 때만 우측 설명 패널 + 좌측 정렬. 그 외엔 가운데 정렬·패널 숨김.
	if description_panel != null:
		description_panel.visible = (new_state == STATE_MODE)
	if center_node != null:
		center_node.anchor_right = 0.55 if new_state == STATE_MODE else 1.0
	match state:
		STATE_MAIN:
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
			var b_normal := _make_button("일반 모드")
			b_normal.pressed.connect(_on_mode_pressed.bind(false))
			b_normal.focus_entered.connect(_on_mode_focused.bind("normal"))
			b_normal.mouse_entered.connect(_on_mode_focused.bind("normal"))
			buttons_box.add_child(b_normal)
			var b_story := _make_button("스토리 모드")
			b_story.pressed.connect(_on_mode_pressed.bind(true))
			b_story.focus_entered.connect(_on_mode_focused.bind("story"))
			b_story.mouse_entered.connect(_on_mode_focused.bind("story"))
			buttons_box.add_child(b_story)
			var b_back := _make_button("뒤로")
			b_back.pressed.connect(_on_back_pressed)
			b_back.focus_entered.connect(_on_mode_focused.bind("back"))
			b_back.mouse_entered.connect(_on_mode_focused.bind("back"))
			buttons_box.add_child(b_back)
			_on_mode_focused("normal")  # 초기 표시
			b_normal.grab_focus.call_deferred()
		STATE_TUTOR:
			var b_yes := _make_button("튜토리얼부터")
			b_yes.pressed.connect(_on_tutor_pressed.bind(true))
			buttons_box.add_child(b_yes)
			var b_no := _make_button("바로 시작")
			b_no.pressed.connect(_on_tutor_pressed.bind(false))
			buttons_box.add_child(b_no)
			var b_back := _make_button("뒤로")
			b_back.pressed.connect(_on_back_pressed)
			buttons_box.add_child(b_back)
			b_yes.grab_focus.call_deferred()
	_refresh_hint()

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

func _on_mode_focused(which: String) -> void:
	if description_title_label == null or description_text_label == null or description_icon == null:
		return
	match which:
		"normal":
			description_icon.color = Color(0.95, 0.55, 0.45)  # 주황 — 도전적
			description_title_label.text = "일반 모드"
			description_text_label.text = "전투와 회피가 중심.\n\n· HP 3\n· 7 스테이지\n· 보스 3페이즈\n· 드론·저격수 등 모든 적"
		"story":
			description_icon.color = Color(0.55, 0.85, 0.95)  # 푸름 — 부드러움
			description_title_label.text = "스토리 모드"
			description_text_label.text = "쉽게 따라오는 흐름.\n\n· HP 무제한\n· 5 스테이지\n· 보스 단순화\n· 드론 없음"
		"back":
			description_icon.color = Color(0.55, 0.6, 0.7)
			description_title_label.text = "뒤로"
			description_text_label.text = "메인 메뉴로 돌아가요."

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
	# 설정 닫힌 뒤 포커스가 사라져 키/패드 입력이 먹히지 않던 버그 — 첫 버튼에 다시 포커스.
	if buttons_box.get_child_count() > 0:
		var first := buttons_box.get_child(0) as Button
		if first != null:
			first.grab_focus.call_deferred()

func _on_quit_pressed() -> void:
	get_tree().quit()
