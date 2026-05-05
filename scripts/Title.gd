extends Control

@onready var title_label: Label = $Center/V/Title
@onready var hint_label: Label = $Center/V/Hint
@onready var story_button: Button = $Center/V/Buttons/StoryButton
@onready var tutorial_button: Button = $Center/V/Buttons/TutorialButton
@onready var settings_button: Button = $Center/V/Buttons/SettingsButton

var blink_t: float = 0.0
var settings_overlay: Control = null
# 첫 방향 입력 들어오면 버튼에 포커스를 잡는다. 그 전엔 SPACE/A가 그냥 normal-mode 시작.
# 이렇게 분기해야 마우스/키보드 사용자 흐름(누르면 시작)과 패드 네비 흐름이 충돌하지 않는다.
var focus_initialized: bool = false

func _ready() -> void:
	GameState.reset()
	# 부스/QR 환경 가정 — 매 타이틀 진입은 새 플레이어 세션. 도감을 비워서 첫 조우 카드가
	# 다시 뜨도록. (같은 사람이 연속 플레이해도 카드는 짧고 빠르게 dismissable이라 부담 작음.)
	GameState.seen_enemies.clear()
	GameState.save_settings()
	title_label.text = "EYES ON YOU"
	hint_label.text = "[ 시작 — SPACE 또는 패드 A ]"
	story_button.pressed.connect(_on_story_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _process(delta: float) -> void:
	blink_t += delta
	hint_label.modulate.a = 0.5 + 0.5 * sin(blink_t * 3.0)

func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay != null:
		return
	# 첫 방향 입력 — 버튼 포커스 시작. 이후엔 패드 D-Pad/스틱으로 버튼 사이를 이동하고
	# A/Space로 활성화한다. 포커스 잡힌 뒤 implicit-start은 ui_accept이 버튼을 누름.
	if not focus_initialized:
		var is_dir: bool = event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") \
			or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") \
			or event.is_action_pressed("move_left") or event.is_action_pressed("move_right") \
			or event.is_action_pressed("move_down")
		if is_dir:
			focus_initialized = true
			if story_button != null:
				story_button.grab_focus()
			return
		if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
			SceneRouter.start_after_title(get_tree())

func _on_tutorial_pressed() -> void:
	# 튜토리얼은 언제든 다시 진입 가능
	get_tree().change_scene_to_file(SceneRouter.TUTORIAL)

func _on_story_pressed() -> void:
	# 간략화된 스토리 — 체력 무제한, 드론 없음, 보스 단일 페이즈, 5스테이지.
	# 튜토리얼 건너뛰고 바로 첫 브리핑으로.
	GameState.story_mode = true
	get_tree().change_scene_to_file(SceneRouter.BRIEFING)

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
