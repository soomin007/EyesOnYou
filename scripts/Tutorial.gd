extends Node2D

const STAGE_LENGTH: float = 2400.0
const GROUND_Y: float = 600.0
const PLAYER_START: Vector2 = Vector2(120.0, 480.0)

const MOVE_TRIGGER_X: float = 600.0
const PLATFORM_X: float = 900.0
const PLATFORM_Y: float = GROUND_Y - 160.0
const PLATFORM_W: float = 220.0
const PICKUP_POS: Vector2 = Vector2(900.0, GROUND_Y - 220.0)
const DUMMY_POS: Vector2 = Vector2(1400.0, GROUND_Y - 30.0)
const SIGN_DASH_X: float = 1700.0
const SPIKE_X_START: float = 1850.0
const SPIKE_X_END: float = 2100.0
const BARRIER_X: float = 2120.0
const GOAL_X: float = 2300.0

enum Step { MOVE, JUMP, ATTACK, DASH, DONE }

var step: int = Step.MOVE
var player: CharacterBody2D
var camera: Camera2D
var hud_label: Label
var hint_label: Label
var sign_move: Label
var sign_jump: Label
var sign_attack: Label
var sign_dash: Label
var jump_pickup: Area2D
var dummy: Node2D
var spike_zone: Area2D
var barrier: StaticBody2D
var barrier_visual: ColorRect
var goal: Area2D
var goal_reached: bool = false

var pause_overlay: CanvasLayer
var settings_overlay: Control

func _ready() -> void:
	add_to_group("stage")
	GameState.player_hp = GameState.player_max_hp
	if not GameState.has_skill("dash"):
		GameState.skills.append("dash")
	if not GameState.has_skill("double_jump"):
		GameState.skills.append("double_jump")
	_build_world()
	_build_player()
	_build_camera()
	_build_signs()
	_build_jump_pickup()
	_build_dummy()
	_build_spike_zone()
	_build_barrier()
	_build_goal()
	_build_hud()
	_refresh_hud()

func _build_world() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.position = Vector2(-200, -200)
	bg.size = Vector2(STAGE_LENGTH + 400.0, 1100.0)
	bg.z_index = -10
	add_child(bg)

	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	add_child(ground)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(STAGE_LENGTH + 400.0, 200.0)
	col.shape = shape
	col.position = Vector2(STAGE_LENGTH * 0.5, GROUND_Y + 100.0)
	ground.add_child(col)
	var ground_visual := ColorRect.new()
	ground_visual.color = Color(0.05, 0.05, 0.07)
	ground_visual.position = Vector2(-200, GROUND_Y)
	ground_visual.size = Vector2(STAGE_LENGTH + 400.0, 300.0)
	add_child(ground_visual)

	_build_platform(PLATFORM_X, PLATFORM_Y, PLATFORM_W)
	_build_wall(-50.0)
	_build_wall(STAGE_LENGTH + 50.0)

func _build_platform(x: float, y: float, w: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, 24.0)
	col.shape = shape
	col.position = Vector2(x, y)
	body.add_child(col)
	var visual := ColorRect.new()
	visual.color = Color(0.18, 0.18, 0.22)
	visual.position = Vector2(x - w * 0.5, y - 12.0)
	visual.size = Vector2(w, 24.0)
	add_child(visual)

func _build_wall(x: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60.0, 1400.0)
	col.shape = shape
	col.position = Vector2(x, GROUND_Y - 400.0)
	body.add_child(col)

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/Player.gd"))
	player.collision_layer = 2
	player.collision_mask = 1
	var col := CollisionShape2D.new()
	col.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28.0, 56.0)
	col.shape = shape
	col.position = Vector2(0, -28.0)
	player.add_child(col)
	add_child(player)
	player.global_position = PLAYER_START

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2(1.0, 1.0)
	camera.limit_left = 0
	camera.limit_right = int(STAGE_LENGTH)
	camera.limit_top = -200
	camera.limit_bottom = int(GROUND_Y + 200.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	player.add_child(camera)
	camera.make_current()

func _build_signs() -> void:
	sign_move = _make_sign("← → 또는 A D 키로 이동", Vector2(200.0, GROUND_Y - 220.0))
	sign_jump = _make_sign("SPACE 점프\n공중에서 한 번 더 점프 가능", Vector2(750.0, GROUND_Y - 320.0))
	sign_attack = _make_sign("J 공격\n전방 적을 베어요", Vector2(1200.0, GROUND_Y - 220.0))
	sign_dash = _make_sign("SHIFT 대시\n가시 구간을 무적으로 통과", Vector2(SIGN_DASH_X, GROUND_Y - 220.0))
	sign_jump.visible = false
	sign_attack.visible = false
	sign_dash.visible = false

func _make_sign(text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos - Vector2(140, 30)
	l.size = Vector2(280, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l

func _build_jump_pickup() -> void:
	jump_pickup = Area2D.new()
	jump_pickup.collision_layer = 0
	jump_pickup.collision_mask = 2
	jump_pickup.position = PICKUP_POS
	add_child(jump_pickup)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	col.shape = shape
	jump_pickup.add_child(col)
	var visual := ColorRect.new()
	visual.color = Color(0.4, 0.95, 0.6, 0.9)
	visual.position = Vector2(-12.0, -12.0)
	visual.size = Vector2(24.0, 24.0)
	jump_pickup.add_child(visual)
	jump_pickup.body_entered.connect(_on_pickup_taken)

func _on_pickup_taken(body: Node) -> void:
	if step != Step.JUMP:
		return
	if not (body is CharacterBody2D and body == player):
		return
	jump_pickup.queue_free()
	jump_pickup = null
	_advance_to(Step.ATTACK)

func _build_dummy() -> void:
	dummy = Node2D.new()
	dummy.set_script(load("res://scripts/TutorialDummy.gd"))
	add_child(dummy)
	dummy.global_position = DUMMY_POS
	dummy.connect("killed", _on_dummy_killed)

func _on_dummy_killed() -> void:
	if step != Step.ATTACK:
		return
	_advance_to(Step.DASH)

func _build_spike_zone() -> void:
	var visual := ColorRect.new()
	visual.color = Color(0.85, 0.20, 0.25, 0.55)
	visual.position = Vector2(SPIKE_X_START, GROUND_Y - 30.0)
	visual.size = Vector2(SPIKE_X_END - SPIKE_X_START, 30.0)
	add_child(visual)
	for x in range(int(SPIKE_X_START) + 12, int(SPIKE_X_END), 24):
		var spike := ColorRect.new()
		spike.color = Color(0.95, 0.30, 0.30)
		spike.position = Vector2(float(x), GROUND_Y - 18.0)
		spike.size = Vector2(12.0, 18.0)
		add_child(spike)

	spike_zone = Area2D.new()
	spike_zone.collision_layer = 0
	spike_zone.collision_mask = 2
	spike_zone.position = Vector2((SPIKE_X_START + SPIKE_X_END) * 0.5, GROUND_Y - 18.0)
	add_child(spike_zone)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SPIKE_X_END - SPIKE_X_START, 36.0)
	col.shape = shape
	spike_zone.add_child(col)

func _build_barrier() -> void:
	barrier = StaticBody2D.new()
	barrier.collision_layer = 1
	add_child(barrier)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20.0, 200.0)
	col.shape = shape
	col.position = Vector2(BARRIER_X, GROUND_Y - 100.0)
	barrier.add_child(col)
	barrier_visual = ColorRect.new()
	barrier_visual.color = Color(0.7, 0.55, 0.95, 0.55)
	barrier_visual.position = Vector2(BARRIER_X - 10.0, GROUND_Y - 200.0)
	barrier_visual.size = Vector2(20.0, 200.0)
	add_child(barrier_visual)

func _build_goal() -> void:
	goal = Area2D.new()
	goal.collision_layer = 0
	goal.collision_mask = 2
	goal.position = Vector2(GOAL_X, GROUND_Y - 60.0)
	add_child(goal)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60.0, 200.0)
	col.shape = shape
	goal.add_child(col)
	var visual := ColorRect.new()
	visual.color = Color(0.95, 0.85, 0.3, 0.45)
	visual.position = Vector2(-30.0, -100.0)
	visual.size = Vector2(60.0, 200.0)
	goal.add_child(visual)
	goal.body_entered.connect(_on_goal_reached)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", 24)
	top.add_theme_constant_override("margin_top", 16)
	top.add_theme_constant_override("margin_right", 24)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.add_child(top)
	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	top.add_child(hud_label)

	var bottom := MarginContainer.new()
	bottom.add_theme_constant_override("margin_left", 24)
	bottom.add_theme_constant_override("margin_bottom", 16)
	bottom.add_theme_constant_override("margin_right", 24)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud.add_child(bottom)
	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	hint_label.text = "ESC 일시정지"
	bottom.add_child(hint_label)

func _refresh_hud() -> void:
	var step_name := ""
	match step:
		Step.MOVE:   step_name = "1/4 — 이동"
		Step.JUMP:   step_name = "2/4 — 점프"
		Step.ATTACK: step_name = "3/4 — 공격"
		Step.DASH:   step_name = "4/4 — 대시"
		Step.DONE:   step_name = "튜토리얼 완료"
	hud_label.text = "TUTORIAL  %s" % step_name

func _advance_to(next: int) -> void:
	step = next
	match step:
		Step.JUMP:
			sign_jump.visible = true
		Step.ATTACK:
			sign_attack.visible = true
		Step.DASH:
			sign_dash.visible = true
		Step.DONE:
			if barrier != null:
				barrier.queue_free()
				barrier = null
			if barrier_visual != null:
				barrier_visual.queue_free()
				barrier_visual = null
	_refresh_hud()

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	if step == Step.MOVE and player.global_position.x >= MOVE_TRIGGER_X:
		_advance_to(Step.JUMP)
	if step == Step.DASH and spike_zone != null:
		var p: Vector2 = player.global_position
		var in_zone: bool = p.x >= SPIKE_X_START and p.x <= SPIKE_X_END
		var dt: float = float(player.get("dash_timer"))
		if in_zone and dt > 0.0:
			_advance_to(Step.DONE)

func _on_goal_reached(body: Node) -> void:
	if goal_reached:
		return
	if step != Step.DONE:
		return
	if not (body is CharacterBody2D and body == player):
		return
	goal_reached = true
	_finish_tutorial()

func _finish_tutorial() -> void:
	GameState.tutorial_done = true
	GameState.save_settings()
	GameState.reset()
	get_tree().change_scene_to_file(SceneRouter.BRIEFING)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if pause_overlay == null:
			_show_pause()
		else:
			_hide_pause()

func _show_pause() -> void:
	get_tree().paused = true
	pause_overlay = PauseHelper.build(self, _on_pause_resume, _on_pause_settings, _on_pause_to_title)
	add_child(pause_overlay)

func _hide_pause() -> void:
	if pause_overlay != null:
		pause_overlay.queue_free()
		pause_overlay = null
	get_tree().paused = false

func _on_pause_resume() -> void:
	_hide_pause()

func _on_pause_settings() -> void:
	if settings_overlay != null:
		return
	var packed := load(SceneRouter.SETTINGS) as PackedScene
	if packed == null:
		return
	settings_overlay = packed.instantiate()
	settings_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_overlay != null:
		pause_overlay.add_child(settings_overlay)
	else:
		add_child(settings_overlay)
	if settings_overlay.has_signal("closed"):
		settings_overlay.closed.connect(_on_settings_closed)

func _on_settings_closed() -> void:
	if settings_overlay != null:
		settings_overlay.queue_free()
		settings_overlay = null

func _on_pause_to_title() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().change_scene_to_file(SceneRouter.TITLE)
