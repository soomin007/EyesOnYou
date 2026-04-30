extends Node2D

const STAGE_LENGTH: float = 4400.0
const GROUND_Y: float = 600.0
const PLAYER_START: Vector2 = Vector2(140.0, 540.0)

var player: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var hp_label: Label
var xp_label: Label
var stage_label: Label
var skill_label: Label
var levelup_overlay: CanvasLayer
var goal_reached: bool = false
var pending_levelup: bool = false

var pause_overlay: CanvasLayer
var settings_overlay: Control

func _ready() -> void:
	add_to_group("stage")
	GameState.player_hp = GameState.player_max_hp
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	_spawn_enemies()
	_build_goal()

func _build_world() -> void:
	_build_background()
	_build_ground()
	_build_platforms()
	_build_decorations()
	_build_wall(-50.0)
	_build_wall(STAGE_LENGTH + 50.0)

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = _stage_color()
	bg.position = Vector2(-200, -300)
	bg.size = Vector2(STAGE_LENGTH + 400.0, 1200.0)
	bg.z_index = -20
	add_child(bg)

	# 위쪽 그라디언트 (어두운 천장)
	var top_grad := ColorRect.new()
	top_grad.color = Color(0, 0, 0, 0.55)
	top_grad.position = Vector2(-200, -300)
	top_grad.size = Vector2(STAGE_LENGTH + 400.0, 320.0)
	top_grad.z_index = -19
	add_child(top_grad)

	# 멀리 있는 실루엣 기둥 (parallax 느낌)
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 7919 + 13
	var x: float = -100.0
	while x < STAGE_LENGTH + 200.0:
		var w: float = rng.randf_range(40.0, 90.0)
		var h: float = rng.randf_range(180.0, 380.0)
		var pillar := ColorRect.new()
		pillar.color = Color(0.02, 0.025, 0.035, 0.85)
		pillar.position = Vector2(x, GROUND_Y - h)
		pillar.size = Vector2(w, h + 20.0)
		pillar.z_index = -15
		add_child(pillar)
		x += w + rng.randf_range(80.0, 220.0)

func _build_ground() -> void:
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	ground.collision_mask = 0
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

	# 바닥 위 가는 라이트 라인 (지평선 강조)
	var line := ColorRect.new()
	line.color = Color(0.55, 0.62, 0.78, 0.35)
	line.position = Vector2(-200, GROUND_Y - 1.0)
	line.size = Vector2(STAGE_LENGTH + 400.0, 1.0)
	add_child(line)

func _build_platforms() -> void:
	# 스테이지 진행도에 따라 플랫폼 배치를 다양화
	var stage_idx: int = GameState.current_stage
	# 단일점프 상승 ~104px. 첫 플랫폼 y=510 (top 498), 이후 단계마다 80~90px 상승.
	# 모든 레이아웃은 단일점프 계단으로 도달 가능하도록 설계.
	var layouts: Array = [
		# 0: 안정적 진행
		[Vector2(700, 510), Vector2(1100, 480), Vector2(1500, 440), Vector2(1900, 480), Vector2(2400, 510), Vector2(2900, 470), Vector2(3400, 440), Vector2(3900, 480)],
		# 1: 위로 솟는 — 점프 강조
		[Vector2(800, 510), Vector2(1300, 430), Vector2(1700, 350), Vector2(2200, 510), Vector2(2700, 400), Vector2(3200, 320), Vector2(3700, 460), Vector2(4100, 380)],
		# 2: 협곡 — 우회 / 깊은 골
		[Vector2(700, 530), Vector2(1200, 460), Vector2(1500, 380), Vector2(1800, 460), Vector2(2400, 530), Vector2(2900, 460), Vector2(3400, 380), Vector2(3900, 460)],
		# 3: 전투 아레나 — 평탄
		[Vector2(800, 510), Vector2(1500, 510), Vector2(2200, 510), Vector2(2900, 510), Vector2(3600, 510)],
		# 4: 최종 — 가장 높이차
		[Vector2(700, 510), Vector2(1100, 420), Vector2(1500, 330), Vector2(2000, 250), Vector2(2500, 330), Vector2(3000, 250), Vector2(3500, 330), Vector2(4000, 420)],
	]
	var layout: Array = layouts[stage_idx % layouts.size()]
	for pos in layout:
		var p: Vector2 = pos
		_build_platform(p.x, p.y, 220.0)

func _build_decorations() -> void:
	# 천장 라이트 (드문드문)
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 31 + 5
	var x: float = 200.0
	while x < STAGE_LENGTH:
		var beam := ColorRect.new()
		beam.color = Color(0.92, 0.88, 0.55, 0.06)
		beam.position = Vector2(x - 30.0, -200.0)
		beam.size = Vector2(60.0, 700.0)
		beam.z_index = -8
		add_child(beam)
		x += rng.randf_range(420.0, 720.0)

func _stage_color() -> Color:
	var tags: Array = GameState.current_route_tags
	if "어두운_환경" in tags:
		return Color(0.03, 0.04, 0.06)
	if "밝은_환경" in tags:
		return Color(0.13, 0.14, 0.18)
	if "노출" in tags:
		return Color(0.08, 0.11, 0.18)
	return Color(0.06, 0.07, 0.09)

func _build_platform(x: float, y: float, w: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var col := CollisionShape2D.new()
	col.one_way_collision = true  # 위에서만 착지 가능 — 아래에서 점프 시 통과
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
	# 플랫폼 위 가는 라이트
	var top := ColorRect.new()
	top.color = Color(0.55, 0.62, 0.78, 0.55)
	top.position = Vector2(x - w * 0.5, y - 12.0)
	top.size = Vector2(w, 1.0)
	add_child(top)

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
	player.died.connect(_on_player_died)

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

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", 24)
	top.add_theme_constant_override("margin_top", 16)
	top.add_theme_constant_override("margin_right", 24)
	top.add_theme_constant_override("margin_bottom", 16)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.add_child(top)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 32)
	top.add_child(hb)
	hp_label = Label.new()
	xp_label = Label.new()
	stage_label = Label.new()
	skill_label = Label.new()
	for l in [hp_label, xp_label, stage_label, skill_label]:
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		hb.add_child(l)
	_refresh_hud()

	var bottom := MarginContainer.new()
	bottom.add_theme_constant_override("margin_left", 24)
	bottom.add_theme_constant_override("margin_bottom", 16)
	bottom.add_theme_constant_override("margin_right", 24)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud.add_child(bottom)
	var keys := Label.new()
	keys.text = "A/D 이동   SPACE 점프   J 사격   SHIFT 대시   ESC 일시정지"
	keys.add_theme_font_size_override("font_size", 13)
	keys.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	bottom.add_child(keys)

func _refresh_hud() -> void:
	hp_label.text = "HP  %s" % _hearts(GameState.player_hp, GameState.player_max_hp)
	xp_label.text = "LV %d   XP %d/%d" % [GameState.player_level, GameState.player_xp, GameState.XP_PER_LEVEL]
	stage_label.text = "STAGE %d/%d" % [GameState.current_stage + 1, GameState.TOTAL_STAGES]
	if GameState.skills.size() > 0:
		skill_label.text = "SKILL  " + ", ".join(GameState.skills)
	else:
		skill_label.text = "SKILL  —"

func _hearts(hp: int, max_hp: int) -> String:
	var s: String = ""
	for i in max_hp:
		s += "♥" if i < hp else "♡"
	return s

func _spawn_enemies() -> void:
	var tags: Array = GameState.current_route_tags
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 991 + 7
	var counts := {"patrol": 4, "sniper": 0, "drone": 0}
	if "전투" in tags or "근접전" in tags:
		counts["patrol"] = 6
	if "원거리" in tags or "노출" in tags:
		counts["sniper"] = 2
	if "드론" in tags:
		counts["drone"] = 2
	if GameState.current_stage >= 2:
		counts["sniper"] += 1
	if GameState.current_stage >= 3:
		counts["drone"] += 1

	for i in counts["patrol"]:
		var x: float = lerp(400.0, STAGE_LENGTH - 300.0, float(i + 1) / float(counts["patrol"] + 1))
		_spawn_enemy(0, Vector2(x, GROUND_Y - 30.0))
	for i in counts["sniper"]:
		var x2: float = lerp(800.0, STAGE_LENGTH - 600.0, float(i + 1) / float(counts["sniper"] + 1))
		_spawn_enemy(1, Vector2(x2, GROUND_Y - 250.0))
	for i in counts["drone"]:
		var x3: float = lerp(1000.0, STAGE_LENGTH - 800.0, float(i + 1) / float(counts["drone"] + 1))
		_spawn_enemy(2, Vector2(x3, GROUND_Y - 320.0))

func _spawn_enemy(kind: int, pos: Vector2) -> void:
	var e := CharacterBody2D.new()
	e.set_script(load("res://scripts/Enemy.gd"))
	e.collision_layer = 4
	e.collision_mask = 1
	e.set("enemy_type", kind)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28.0, 40.0) if kind != 2 else Vector2(32.0, 24.0)
	col.shape = shape
	col.position = Vector2(0, -20.0) if kind != 2 else Vector2(0, 0)
	e.add_child(col)
	add_child(e)
	e.global_position = pos
	e.killed.connect(_on_enemy_killed)

func _on_enemy_killed(at_position: Vector2) -> void:
	_spawn_orb(at_position + Vector2(0, -20.0))

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

func _build_goal() -> void:
	var goal := Area2D.new()
	goal.collision_layer = 0
	goal.collision_mask = 2
	goal.position = Vector2(STAGE_LENGTH - 80.0, GROUND_Y - 60.0)
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
	# 골 빛기둥
	var beam := ColorRect.new()
	beam.color = Color(0.95, 0.85, 0.3, 0.18)
	beam.position = Vector2(-90.0, -300.0)
	beam.size = Vector2(180.0, 600.0)
	goal.add_child(beam)
	goal.body_entered.connect(_on_goal_reached)

func _on_goal_reached(body: Node) -> void:
	if goal_reached:
		return
	if not (body is CharacterBody2D and body == player):
		return
	goal_reached = true
	GameState.on_stage_clear()
	if GameState.is_final_stage_done():
		get_tree().change_scene_to_file(SceneRouter.ENDING)
	else:
		get_tree().change_scene_to_file(SceneRouter.BRIEFING)

func _on_player_died() -> void:
	GameState.register_death()
	get_tree().change_scene_to_file(SceneRouter.DEATH)

func _process(_delta: float) -> void:
	_refresh_hud()

func _on_xp_collected(leveled_up: bool) -> void:
	if leveled_up and not pending_levelup:
		pending_levelup = true
		_show_levelup()

func _show_levelup() -> void:
	get_tree().paused = true
	var advice: String = VeilDialogue.get_levelup_advice(GameState.skills, GameState.current_route_tags)
	levelup_overlay = LevelUpOverlay.show(self, advice, _on_levelup_picked)

func _on_levelup_picked(_picked_id: String) -> void:
	levelup_overlay = null
	pending_levelup = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and levelup_overlay == null:
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
