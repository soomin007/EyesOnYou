extends Control

@onready var title_label: Label = $Center/V/Title
@onready var hint_label: Label = $Center/V/Hint
@onready var tutorial_button: Button = $Center/V/Buttons/TutorialButton
@onready var settings_button: Button = $Center/V/Buttons/SettingsButton

var blink_t: float = 0.0
var settings_overlay: Control = null

func _ready() -> void:
	GameState.reset()
	title_label.text = "EYES ON YOU"
	hint_label.text = "[ 시작하려면 SPACE ]"
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _process(delta: float) -> void:
	blink_t += delta
	hint_label.modulate.a = 0.5 + 0.5 * sin(blink_t * 3.0)

func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay != null:
		return
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		SceneRouter.start_after_title(get_tree())

func _on_tutorial_pressed() -> void:
	# 튜토리얼은 언제든 다시 진입 가능
	get_tree().change_scene_to_file(SceneRouter.TUTORIAL)

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
