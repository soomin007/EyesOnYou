extends Control

@onready var title_label: Label = $Center/V/Title
@onready var hint_label: Label = $Center/V/Hint

var blink_t: float = 0.0

func _ready() -> void:
	GameState.reset()
	title_label.text = "EYES ON YOU"
	hint_label.text = "[ 시작하려면 SPACE ]"

func _process(delta: float) -> void:
	blink_t += delta
	hint_label.modulate.a = 0.5 + 0.5 * sin(blink_t * 3.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		get_tree().change_scene_to_file(SceneRouter.BRIEFING)
