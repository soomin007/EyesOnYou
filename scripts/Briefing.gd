extends Control

@onready var stage_label: Label = $Box/Margin/V/Stage
@onready var speaker_label: Label = $Box/Margin/V/Speaker
@onready var text_label: Label = $Box/Margin/V/Text
@onready var hint_label: Label = $Box/Margin/V/Hint

const TYPE_INTERVAL: float = 0.04

var full_text: String = ""
var revealed_chars: int = 0
var type_t: float = 0.0
var done: bool = false

func _ready() -> void:
	stage_label.text = "STAGE %d / %d" % [GameState.current_stage + 1, GameState.TOTAL_STAGES]
	speaker_label.text = "VEIL"
	full_text = VeilDialogue.get_briefing(GameState.current_stage)
	text_label.text = ""
	hint_label.text = ""

func _process(delta: float) -> void:
	if done:
		return
	type_t += delta
	if type_t >= TYPE_INTERVAL:
		type_t = 0.0
		revealed_chars += 1
		if revealed_chars >= full_text.length():
			revealed_chars = full_text.length()
			done = true
			hint_label.text = "[ SPACE — 계속 ]"
		text_label.text = full_text.substr(0, revealed_chars)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump"):
		if not done:
			revealed_chars = full_text.length()
			text_label.text = full_text
			done = true
			hint_label.text = "[ SPACE — 계속 ]"
			return
		_proceed()

func _proceed() -> void:
	get_tree().change_scene_to_file(SceneRouter.ROUTE_MAP)
