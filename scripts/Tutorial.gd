extends Node2D

# 튜토리얼 맵 디자인 (좌→우 진행)
#
#   x=0   200       900    1500       2200       2800   3300  3600
#   |  시작  |  이동  |  점프  |  공격  |  레벨업  |  대시  |  탈출 |
#
# 단계: MOVE → JUMP → ATTACK → LEVELUP → DASH → DONE

const STAGE_LENGTH: float = 3600.0
const GROUND_Y: float = 600.0
const PLAYER_START: Vector2 = Vector2(160.0, 540.0)

const MOVE_TRIGGER_X: float = 700.0

# 점프 구간: 3단 계단
# 단일점프 상승 ≈ 104px → P1은 단일점프, P2는 이중점프 필수, P3는 P2에서 단일점프로 도달
const JUMP_PLATFORM_1: Vector2 = Vector2(1050.0, 510.0)
const JUMP_PLATFORM_2: Vector2 = Vector2(1300.0, 400.0)
const JUMP_PLATFORM_3: Vector2 = Vector2(1500.0, 310.0)
const JUMP_PICKUP: Vector2 = Vector2(1500.0, 270.0)

# 공격 구간: 1마리 더미
const ATTACK_DUMMY: Vector2 = Vector2(1850.0, GROUND_Y - 30.0)

# 레벨업 구간: 2마리 더미 → 오브 → 자동 레벨업
const LEVELUP_DUMMY_A: Vector2 = Vector2(2350.0, GROUND_Y - 30.0)
const LEVELUP_DUMMY_B: Vector2 = Vector2(2550.0, GROUND_Y - 30.0)
const LEVELUP_TRIGGER_X: float = 2200.0

# 대시 구간: 가시 + 보라색 배리어
const SPIKE_X_START: float = 2900.0
const SPIKE_X_END: float = 3200.0
const BARRIER_X: float = 3220.0

# 골
const GOAL_X: float = 3500.0

enum Step { MOVE, JUMP, ATTACK, LEVELUP, DASH, DONE }

var step: int = Step.MOVE
var player: CharacterBody2D
var camera: Camera2D
var hud_label: Label
var hint_label: Label

var sign_move: Label
var sign_jump: Label
var sign_attack: Label
var sign_levelup: Label
var sign_dash: Label

var jump_pickup: Area2D
var attack_dummy: Node2D
var levelup_dummies: Array = []
var levelup_kills: int = 0
var levelup_triggered: bool = false
var levelup_overlay: CanvasLayer

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
	# 튜토리얼 동안만 임시로 부여하는 스킬
	if not GameState.has_skill("dash"):
		GameState.skills.append("dash")
	if not GameState.has_skill("double_jump"):
		GameState.skills.append("double_jump")
	# 레벨업이 첫 처치 직후 트리거되도록 XP 직전치까지 채워둠
	GameState.player_xp = GameState.XP_PER_LEVEL - 2

	_build_background()
	_build_ground()
	_build_jump_section()
	_build_attack_section()
	_build_levelup_section()
	_build_dash_section()
	_build_walls()
	_build_player()
	_build_camera()
	_build_signs()
	_build_jump_pickup()
	_build_attack_dummy()
	_build_spike_zone()
	_build_barrier()
	_build_goal()
	_build_hud()
	_refresh_hud()

# ─── 배경 / 지면 ───────────────────────────────────────────────

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.position = Vector2(-200, -300)
	bg.size = Vector2(STAGE_LENGTH + 400.0, 1200.0)
	bg.z_index = -20
	add_child(bg)

	var top_grad := ColorRect.new()
	top_grad.color = Color(0, 0, 0, 0.55)
	top_grad.position = Vector2(-200, -300)
	top_grad.size = Vector2(STAGE_LENGTH + 400.0, 320.0)
	top_grad.z_index = -19
	add_child(top_grad)

	# 멀리 있는 실루엣 기둥
	var pillars: Array = [120, 380, 720, 1180, 1620, 2050, 2480, 2920, 3350]
	for px in pillars:
		var w: float = 60.0
		var h: float = 240.0 + float(int(px) % 7) * 18.0
		var pillar := ColorRect.new()
		pillar.color = Color(0.02, 0.025, 0.035, 0.85)
		pillar.position = Vector2(float(px) - w * 0.5, GROUND_Y - h)
		pillar.size = Vector2(w, h + 20.0)
		pillar.z_index = -15
		add_child(pillar)

	# 천장 빛기둥 (구간 입구마다)
	var beams: Array = [180, 950, 1850, 2450, 3050, 3500]
	for bx in beams:
		var beam := ColorRect.new()
		beam.color = Color(0.95, 0.88, 0.55, 0.06)
		beam.position = Vector2(float(bx) - 35.0, -200.0)
		beam.size = Vector2(70.0, 720.0)
		beam.z_index = -8
		add_child(beam)

func _build_ground() -> void:
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	add_child(ground)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(STAGE_LENGTH + 400.0, 200.0)
	col.shape = shape
	col.position = Vector2(STAGE_LENGTH * 0.5, GROUND_Y + 100.0)
	ground.add_child(col)

	var floor_visual := ColorRect.new()
	floor_visual.color = Color(0.04, 0.045, 0.06)
	floor_visual.position = Vector2(-200, GROUND_Y)
	floor_visual.size = Vector2(STAGE_LENGTH + 400.0, 300.0)
	add_child(floor_visual)

	var line := ColorRect.new()
	line.color = Color(0.55, 0.62, 0.78, 0.35)
	line.position = Vector2(-200, GROUND_Y - 1.0)
	line.size = Vector2(STAGE_LENGTH + 400.0, 1.0)
	add_child(line)

func _build_walls() -> void:
	_make_wall(-50.0)
	_make_wall(STAGE_LENGTH + 50.0)

func _make_wall(x: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60.0, 1400.0)
	col.shape = shape
	col.position = Vector2(x, GROUND_Y - 400.0)
	body.add_child(col)

# ─── 구간별 플랫폼 ─────────────────────────────────────────────

func _build_jump_section() -> void:
	_make_platform(JUMP_PLATFORM_1.x, JUMP_PLATFORM_1.y, 180.0)
	_make_platform(JUMP_PLATFORM_2.x, JUMP_PLATFORM_2.y, 160.0)
	_make_platform(JUMP_PLATFORM_3.x, JUMP_PLATFORM_3.y, 160.0)

func _build_attack_section() -> void:
	# 살짝 낮춰진 아레나 느낌의 가는 라이트 라인
	var arena := ColorRect.new()
	arena.color = Color(0.85, 0.30, 0.30, 0.10)
	arena.position = Vector2(1700.0, GROUND_Y - 80.0)
	arena.size = Vector2(360.0, 80.0)
	arena.z_index = -5
	add_child(arena)

func _build_levelup_section() -> void:
	# 푸른 톤의 레벨업 아레나
	var arena := ColorRect.new()
	arena.color = Color(0.30, 0.55, 0.85, 0.10)
	arena.position = Vector2(2200.0, GROUND_Y - 80.0)
	arena.size = Vector2(560.0, 80.0)
	arena.z_index = -5
	add_child(arena)
	# 양쪽 가드레일 (장식)
	for gx in [2210.0, 2780.0]:
		var rail := ColorRect.new()
		rail.color = Color(0.55, 0.62, 0.78, 0.6)
		rail.position = Vector2(float(gx), GROUND_Y - 60.0)
		rail.size = Vector2(2.0, 60.0)
		add_child(rail)

func _build_dash_section() -> void:
	var arena := ColorRect.new()
	arena.color = Color(0.85, 0.20, 0.25, 0.08)
	arena.position = Vector2(SPIKE_X_START - 50.0, GROUND_Y - 80.0)
	arena.size = Vector2(SPIKE_X_END - SPIKE_X_START + 100.0, 80.0)
	arena.z_index = -5
	add_child(arena)

func _make_platform(x: float, y: float, w: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var col := CollisionShape2D.new()
	col.one_way_collision = true
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, 24.0)
	col.shape = shape
	col.position = Vector2(x, y)
	body.add_child(col)

	var visual := ColorRect.new()
	visual.color = Color(0.16, 0.18, 0.22)
	visual.position = Vector2(x - w * 0.5, y - 12.0)
	visual.size = Vector2(w, 24.0)
	add_child(visual)
	var top := ColorRect.new()
	top.color = Color(0.55, 0.62, 0.78, 0.55)
	top.position = Vector2(x - w * 0.5, y - 12.0)
	top.size = Vector2(w, 1.0)
	add_child(top)

# ─── 표지판 / HUD ──────────────────────────────────────────────

func _build_signs() -> void:
	sign_move = _make_sign("←  →  또는  A  D 키로 이동", Vector2(280.0, GROUND_Y - 200.0))
	sign_jump = _make_sign("SPACE 점프\n공중에서 한 번 더 누르면 이중 점프", Vector2(950.0, GROUND_Y - 280.0))
	sign_attack = _make_sign("J — 사격\n전방의 적을 처치", Vector2(1750.0, GROUND_Y - 200.0))
	sign_levelup = _make_sign("적 처치 → 경험치 → 레벨업\n3개 중 1개의 스킬을 골라요", Vector2(2480.0, GROUND_Y - 280.0))
	sign_dash = _make_sign("SHIFT — 대시\n무적 상태로 가시 구간 통과", Vector2(SPIKE_X_START + 100.0, GROUND_Y - 200.0))
	sign_jump.visible = false
	sign_attack.visible = false
	sign_levelup.visible = false
	sign_dash.visible = false

func _make_sign(text: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos - Vector2(160, 32)
	l.size = Vector2(320, 64)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l

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
		Step.MOVE:    step_name = "1/5 — 이동"
		Step.JUMP:    step_name = "2/5 — 점프"
		Step.ATTACK:  step_name = "3/5 — 사격"
		Step.LEVELUP: step_name = "4/5 — 레벨업 / 스킬"
		Step.DASH:    step_name = "5/5 — 대시"
		Step.DONE:    step_name = "튜토리얼 완료 — 골에 도달해요"
	hud_label.text = "TUTORIAL  %s" % step_name

# ─── 인터랙션 노드 ─────────────────────────────────────────────

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

func _build_jump_pickup() -> void:
	jump_pickup = Area2D.new()
	jump_pickup.collision_layer = 0
	jump_pickup.collision_mask = 2
	jump_pickup.position = JUMP_PICKUP
	add_child(jump_pickup)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	col.shape = shape
	jump_pickup.add_child(col)
	# 빛나는 마름모 비주얼
	var visual := Polygon2D.new()
	visual.color = Color(0.55, 0.95, 0.75, 0.95)
	visual.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(14, 0), Vector2(0, 14), Vector2(-14, 0),
	])
	jump_pickup.add_child(visual)
	var halo := ColorRect.new()
	halo.color = Color(0.55, 0.95, 0.75, 0.18)
	halo.position = Vector2(-26, -26)
	halo.size = Vector2(52, 52)
	jump_pickup.add_child(halo)
	jump_pickup.body_entered.connect(_on_pickup_taken)

func _on_pickup_taken(body: Node) -> void:
	if step != Step.JUMP:
		return
	if not (body is CharacterBody2D and body == player):
		return
	if jump_pickup != null:
		jump_pickup.queue_free()
		jump_pickup = null
	_advance_to(Step.ATTACK)

func _build_attack_dummy() -> void:
	attack_dummy = Node2D.new()
	attack_dummy.set_script(load("res://scripts/TutorialDummy.gd"))
	add_child(attack_dummy)
	attack_dummy.global_position = ATTACK_DUMMY
	attack_dummy.connect("killed", _on_attack_dummy_killed)

func _on_attack_dummy_killed(_pos: Vector2) -> void:
	if step != Step.ATTACK:
		return
	_advance_to(Step.LEVELUP)

func _spawn_levelup_dummies() -> void:
	# LEVELUP 단계 진입 시점에서야 생성 → 이전 단계에서 사격으로 미리 죽이는 사고 방지
	for pos in [LEVELUP_DUMMY_A, LEVELUP_DUMMY_B]:
		var d := Node2D.new()
		d.set_script(load("res://scripts/TutorialDummy.gd"))
		add_child(d)
		d.global_position = pos
		d.connect("killed", _on_levelup_dummy_killed)
		levelup_dummies.append(d)

func _on_levelup_dummy_killed(pos: Vector2) -> void:
	levelup_kills += 1
	_spawn_orb(pos + Vector2(0, -20.0))

func _spawn_orb(pos: Vector2) -> void:
	var orb := Node2D.new()
	orb.set_script(load("res://scripts/ExpOrb.gd"))
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.color = Color(0.4, 0.95, 0.6)
	sprite.position = Vector2(-6.0, -6.0)
	sprite.size = Vector2(12.0, 12.0)
	orb.add_child(sprite)
	add_child(orb)
	orb.global_position = pos

func _build_spike_zone() -> void:
	# 스파이크 시각
	var visual := ColorRect.new()
	visual.color = Color(0.85, 0.20, 0.25, 0.55)
	visual.position = Vector2(SPIKE_X_START, GROUND_Y - 30.0)
	visual.size = Vector2(SPIKE_X_END - SPIKE_X_START, 30.0)
	add_child(visual)
	for x in range(int(SPIKE_X_START) + 12, int(SPIKE_X_END), 24):
		var spike := Polygon2D.new()
		spike.color = Color(0.95, 0.30, 0.30)
		spike.polygon = PackedVector2Array([
			Vector2(float(x), GROUND_Y),
			Vector2(float(x) + 12.0, GROUND_Y),
			Vector2(float(x) + 6.0, GROUND_Y - 18.0),
		])
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
	shape.size = Vector2(20.0, 220.0)
	col.shape = shape
	col.position = Vector2(BARRIER_X, GROUND_Y - 110.0)
	barrier.add_child(col)
	barrier_visual = ColorRect.new()
	barrier_visual.color = Color(0.7, 0.55, 0.95, 0.55)
	barrier_visual.position = Vector2(BARRIER_X - 10.0, GROUND_Y - 220.0)
	barrier_visual.size = Vector2(20.0, 220.0)
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
	var beam := ColorRect.new()
	beam.color = Color(0.95, 0.85, 0.3, 0.18)
	beam.position = Vector2(-90.0, -300.0)
	beam.size = Vector2(180.0, 600.0)
	goal.add_child(beam)
	goal.body_entered.connect(_on_goal_reached)

# ─── 단계 전이 ────────────────────────────────────────────────

func _advance_to(next: int) -> void:
	step = next
	match step:
		Step.JUMP:
			sign_jump.visible = true
		Step.ATTACK:
			sign_attack.visible = true
		Step.LEVELUP:
			sign_levelup.visible = true
			_spawn_levelup_dummies()
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
	if step == Step.LEVELUP:
		if not levelup_triggered and levelup_kills >= 2:
			levelup_triggered = true
	if step == Step.DASH and spike_zone != null:
		var p: Vector2 = player.global_position
		var in_zone: bool = p.x >= SPIKE_X_START and p.x <= SPIKE_X_END
		var dt: float = float(player.get("dash_timer"))
		if in_zone and dt > 0.0:
			_advance_to(Step.DONE)

# ExpOrb가 호출하는 콜백 (Stage와 동일한 시그니처)
func _on_xp_collected(leveled_up: bool) -> void:
	if step != Step.LEVELUP:
		return
	if leveled_up and levelup_overlay == null:
		_show_levelup()

func _show_levelup() -> void:
	get_tree().paused = true
	levelup_overlay = LevelUpOverlay.show(self, "원하는 능력을 골라요. 한 번 고른 스킬은 남은 게임 동안 유지돼요.", _on_levelup_picked)

func _on_levelup_picked(_picked_id: String) -> void:
	levelup_overlay = null
	get_tree().paused = false
	_advance_to(Step.DASH)

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

# ─── 일시정지 / 설정 ──────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if levelup_overlay != null:
		return
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
