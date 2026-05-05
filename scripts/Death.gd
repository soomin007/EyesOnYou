extends Control

@onready var title_label: Label = $Center/V/Title
@onready var speaker_label: Label = $Center/V/Speaker
@onready var text_label: Label = $Center/V/Text
@onready var hint_label: Label = $Center/V/Hint
@onready var stats_label: Label = $Center/V/Stats

const TYPE_INTERVAL: float = 0.05

var full_text: String = ""
var revealed: int = 0
var t: float = 0.0
var done: bool = false

func _ready() -> void:
	title_label.text = "MISSION FAILED"
	speaker_label.text = "VEIL"
	full_text = VeilDialogue.get_death_briefing(GameState.death_count, GameState.followed_veil_last_choice)
	stats_label.text = "사망 횟수  %d  /  도달 스테이지  %d" % [GameState.death_count, GameState.current_stage + 1]
	text_label.text = ""
	hint_label.text = ""
	GameState.input_kind_changed.connect(_on_input_kind_changed)

func _on_input_kind_changed(_kind: String) -> void:
	if done:
		hint_label.text = _done_hint()

func _done_hint() -> String:
	return GameState.hint(
		"[ SPACE — 다시 시도 ]   [ ESC — 타이틀 ]",
		"[ A — 다시 시도 ]   [ B — 타이틀 ]")

func _process(delta: float) -> void:
	if done:
		return
	t += delta
	if t >= TYPE_INTERVAL:
		t = 0.0
		revealed += 1
		if revealed >= full_text.length():
			revealed = full_text.length()
			done = true
			hint_label.text = _done_hint()
		text_label.text = full_text.substr(0, revealed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameState.reset()
		get_tree().change_scene_to_file(SceneRouter.TITLE)
		return
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump"):
		if not done:
			revealed = full_text.length()
			text_label.text = full_text
			done = true
			hint_label.text = _done_hint()
			return
		_restart_stage()

func _restart_stage() -> void:
	GameState.player_hp = GameState.player_max_hp
	get_tree().change_scene_to_file(SceneRouter.STAGE)
