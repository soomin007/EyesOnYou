extends Control

@onready var title_label: Label = $Center/V/Title
@onready var sub_title_label: Label = $Center/V/Subtitle
@onready var text_label: Label = $Center/V/Text
@onready var choice_box: HBoxContainer = $Center/V/Choices
@onready var hint_label: Label = $Center/V/Hint
@onready var stats_label: Label = $Footer/Stats

const TYPE_INTERVAL: float = 0.045

const HOLD_TO_QUIT_DURATION: float = 3.0

var ending_id: String = ""
var lines: Array = []
var line_idx: int = 0
var revealed: int = 0
var t: float = 0.0
var typing_done: bool = false
var waiting_choice: bool = false
var sequence_complete: bool = false
var silent_timer: float = 0.0
var hold_progress: float = 0.0
var hold_hint: Label
var hold_progress_bar: ColorRect

func _ready() -> void:
	ending_id = EndingResolver.resolve(GameState.trust_score, GameState.aggression_score)
	title_label.text = "MISSION COMPLETE"
	sub_title_label.text = "결말  %s — %s" % [ending_id, EndingResolver.get_ending_title(ending_id)]
	stats_label.text = "신뢰  %d   |   공격성  %d   |   사망  %d   |   스코어  %d" % [
		GameState.trust_score, GameState.aggression_score, GameState.death_count, GameState.score
	]
	lines = EndingResolver.get_ending_lines(ending_id)
	choice_box.visible = false
	hint_label.text = ""
	text_label.text = ""
	if ending_id == EndingResolver.ENDING_D:
		title_label.modulate.a = 0.3
		sub_title_label.modulate.a = 0.3
		_setup_ending_d_atmosphere()
	_build_hold_hint()
	_start_line()

func _build_hold_hint() -> void:
	# 우측 하단 안내 — 시퀀스 완료 후에만 표시. SPACE를 3초간 누르고 있어야 타이틀로 이동.
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.position = Vector2(1000, 660)
	box.size = Vector2(260, 50)
	layer.add_child(box)
	hold_hint = Label.new()
	hold_hint.text = "SPACE 길게 — 타이틀로 (3초)"
	hold_hint.add_theme_font_size_override("font_size", 12)
	hold_hint.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	hold_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hold_hint.size = Vector2(260, 16)
	hold_hint.visible = false
	box.add_child(hold_hint)
	# progress bar (배경 + 채우기)
	var bg := ColorRect.new()
	bg.color = Color(0.18, 0.20, 0.24, 0.7)
	bg.custom_minimum_size = Vector2(260, 4)
	bg.size = Vector2(260, 4)
	hold_progress_bar = ColorRect.new()
	hold_progress_bar.color = Color(0.55, 0.85, 0.95)
	hold_progress_bar.size = Vector2(0, 4)
	bg.add_child(hold_progress_bar)
	bg.visible = false
	box.add_child(bg)

func _setup_ending_d_atmosphere() -> void:
	# 미세한 노이즈 레이어 — 정적 느낌
	var noise_layer := CanvasLayer.new()
	noise_layer.layer = 50
	add_child(noise_layer)
	var noise := ColorRect.new()
	noise.color = Color(0.95, 0.95, 0.95, 0.04)
	noise.set_anchors_preset(Control.PRESET_FULL_RECT)
	noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	noise_layer.add_child(noise)
	var noise_tw := noise.create_tween()
	noise_tw.set_loops()
	noise_tw.tween_property(noise, "modulate:a", 0.6, 0.08)
	noise_tw.tween_property(noise, "modulate:a", 1.2, 0.06)
	noise_tw.tween_property(noise, "modulate:a", 0.4, 0.10)
	# 우상단 VEIL: ... 깜빡이다 꺼짐
	var veil_blink := Label.new()
	veil_blink.text = "VEIL: ..."
	veil_blink.add_theme_font_size_override("font_size", 14)
	veil_blink.add_theme_color_override("font_color", Color(0.55, 0.85, 0.95, 0.6))
	veil_blink.position = Vector2(1080, 24)
	veil_blink.size = Vector2(180, 20)
	noise_layer.add_child(veil_blink)
	var blink_tw := veil_blink.create_tween()
	blink_tw.tween_property(veil_blink, "modulate:a", 0.0, 0.5)
	blink_tw.tween_interval(1.2)
	blink_tw.tween_property(veil_blink, "modulate:a", 1.0, 0.5)
	blink_tw.tween_interval(0.8)
	blink_tw.tween_property(veil_blink, "modulate:a", 0.0, 0.5)
	blink_tw.tween_interval(2.0)
	blink_tw.tween_property(veil_blink, "modulate:a", 0.7, 0.3)
	blink_tw.tween_interval(0.4)
	blink_tw.tween_property(veil_blink, "modulate:a", 0.0, 1.5)

func _start_line() -> void:
	if line_idx >= lines.size():
		_on_sequence_done()
		return
	var line: Dictionary = lines[line_idx]
	revealed = 0
	t = 0.0
	typing_done = false
	silent_timer = 0.0
	if line.get("silent", false):
		text_label.text = ""
		typing_done = true
		return
	text_label.text = ""
	_color_for_speaker(str(line.get("speaker", "")))

func _color_for_speaker(sp: String) -> void:
	match sp:
		"VEIL":
			text_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		"SUB":
			text_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		_:
			text_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

func _process(delta: float) -> void:
	# 시퀀스 완료 후엔 SPACE 누른 시간 누적 → 3초 채우면 타이틀로.
	if sequence_complete:
		if Input.is_action_pressed("jump") or Input.is_action_pressed("ui_skip"):
			hold_progress += delta
			if hold_progress_bar != null:
				hold_progress_bar.size.x = 260.0 * clamp(hold_progress / HOLD_TO_QUIT_DURATION, 0.0, 1.0)
			if hold_progress >= HOLD_TO_QUIT_DURATION:
				GameState.reset()
				get_tree().change_scene_to_file(SceneRouter.TITLE)
				return
		else:
			hold_progress = max(0.0, hold_progress - delta * 1.5)  # 손 떼면 빠르게 줄어듦
			if hold_progress_bar != null:
				hold_progress_bar.size.x = 260.0 * clamp(hold_progress / HOLD_TO_QUIT_DURATION, 0.0, 1.0)
		return
	if line_idx >= lines.size():
		return
	var line: Dictionary = lines[line_idx]
	if line.get("silent", false):
		silent_timer += delta
		if silent_timer >= float(line.get("delay", 0.0)):
			line_idx += 1
			_start_line()
		return
	if not typing_done:
		t += delta
		if t >= TYPE_INTERVAL:
			t = 0.0
			revealed += 1
			var full: String = str(line.get("text", ""))
			if revealed >= full.length():
				revealed = full.length()
				typing_done = true
				silent_timer = 0.0
			var prefix: String = ""
			if str(line.get("speaker", "")) == "VEIL":
				prefix = "VEIL  —  "
			text_label.text = prefix + full.substr(0, revealed)
		return
	if line.get("choice", false) and not waiting_choice:
		_show_choice()
		return
	silent_timer += delta
	if silent_timer >= float(line.get("delay", 1.5)):
		line_idx += 1
		_start_line()

func _show_choice() -> void:
	waiting_choice = true
	choice_box.visible = true
	for c in choice_box.get_children():
		c.queue_free()
	var b1 := Button.new()
	b1.text = "있어요"
	b1.add_theme_font_size_override("font_size", 16)
	b1.pressed.connect(_pick_choice.bind(true))
	choice_box.add_child(b1)
	var b2 := Button.new()
	b2.text = "없어요"
	b2.add_theme_font_size_override("font_size", 16)
	b2.pressed.connect(_pick_choice.bind(false))
	choice_box.add_child(b2)
	b1.grab_focus()

func _pick_choice(asked: bool) -> void:
	waiting_choice = false
	choice_box.visible = false
	lines = EndingResolver.get_ending_c_followup(asked)
	line_idx = 0
	_start_line()

func _on_sequence_done() -> void:
	sequence_complete = true
	hint_label.text = ""
	if hold_hint != null:
		hold_hint.visible = true
	if hold_progress_bar != null and hold_progress_bar.get_parent() is Control:
		(hold_progress_bar.get_parent() as Control).visible = true

func _unhandled_input(event: InputEvent) -> void:
	if waiting_choice:
		return
	# 시퀀스 완료 후엔 SPACE 단발은 무시 — 길게 누르기로만 타이틀 이동 (process에서 처리).
	if sequence_complete:
		return
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump"):
		# 한 줄 즉시 완성
		if line_idx < lines.size():
			var line: Dictionary = lines[line_idx]
			if line.get("silent", false):
				return  # 정적은 스킵 불가 (의도된 연출)
			if not typing_done:
				var full: String = str(line.get("text", ""))
				revealed = full.length()
				var prefix: String = "VEIL  —  " if str(line.get("speaker", "")) == "VEIL" else ""
				text_label.text = prefix + full
				typing_done = true
				silent_timer = 0.0
			else:
				silent_timer = 999.0
