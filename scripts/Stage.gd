extends Node2D

const STAGE_LENGTH: float = 4400.0
const GROUND_Y: float = 600.0
const PLAYER_START: Vector2 = Vector2(120.0, 480.0)

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
	var bg := ColorRect.new()
	bg.color = _stage_color()
	bg.position = Vector2(-200, -200)
	bg.size = Vector2(STAGE_LENGTH + 400.0, 1100.0)
	bg.z_index = -10
	add_child(bg)

	# 단순 지면 (StaticBody2D)
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
	var ground_visual := ColorRect.new()
	ground_visual.color = Color(0.05, 0.05, 0.07)
	ground_visual.position = Vector2(-200, GROUND_Y)
	ground_visual.size = Vector2(STAGE_LENGTH + 400.0, 300.0)
	add_child(ground_visual)

	_build_platform(900.0, GROUND_Y - 140.0, 220.0)
	_build_platform(1500.0, GROUND_Y - 220.0, 180.0)
	_build_platform(2200.0, GROUND_Y - 160.0, 260.0)
	_build_platform(3100.0, GROUND_Y - 240.0, 200.0)
	_build_platform(3700.0, GROUND_Y - 140.0, 240.0)

	# 좌/우 벽
	_build_wall(-50.0)
	_build_wall(STAGE_LENGTH + 50.0)

func _stage_color() -> Color:
	var tags: Array = GameState.current_route_tags
	if "어두운_환경" in tags:
		return Color(0.04, 0.05, 0.07)
	if "밝은_환경" in tags:
		return Color(0.16, 0.16, 0.20)
	if "노출" in tags:
		return Color(0.10, 0.13, 0.20)
	return Color(0.07, 0.08, 0.10)

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
	var atk := ColorRect.new()
	atk.name = "AttackVisual"
	atk.color = Color(1.0, 0.95, 0.3, 0.55)
	atk.position = Vector2(8.0, -36.0)
	atk.size = Vector2(56.0, 40.0)
	player.add_child(atk)
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
	keys.text = "A/D 이동   SPACE 점프   J 공격   SHIFT 대시"
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
	levelup_overlay = CanvasLayer.new()
	levelup_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(levelup_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	levelup_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	levelup_overlay.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)
	var title := Label.new()
	title.text = "LEVEL UP  —  스킬을 선택해요"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var advice := Label.new()
	advice.text = "VEIL  —  " + VeilDialogue.get_levelup_advice(GameState.skills, GameState.current_route_tags)
	advice.add_theme_font_size_override("font_size", 15)
	advice.add_theme_color_override("font_color", Color(0.6, 0.85, 0.95))
	advice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(advice)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	v.add_child(hb)
	var picks: Array = SkillSystem.roll_choices(GameState.skills, 3)
	if picks.size() == 0:
		_close_levelup()
		return
	for p in picks:
		var skill: Dictionary = p
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 130)
		b.text = "%s\n[%s]\n\n%s" % [str(skill.get("name", "")), str(skill.get("tag", "")), str(skill.get("desc", ""))]
		b.add_theme_font_size_override("font_size", 15)
		b.process_mode = Node.PROCESS_MODE_ALWAYS
		b.pressed.connect(_on_skill_picked.bind(str(skill.get("id", ""))))
		hb.add_child(b)
	if hb.get_child_count() > 0:
		(hb.get_child(0) as Control).grab_focus()

func _on_skill_picked(id: String) -> void:
	GameState.add_skill(id)
	_close_levelup()

func _close_levelup() -> void:
	if levelup_overlay != null:
		levelup_overlay.queue_free()
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
