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

# 쿨다운 UI — 사격/대시/스킬 게이지
var cd_attack_slot: Control
var cd_dash_slot: Control
var cd_skill_slot: Control
const CD_BAR_WIDTH: float = 90.0

func _ready() -> void:
	add_to_group("stage")
	GameState.player_hp = GameState.player_max_hp
	# ??? 맵은 적/가시/골이 없는 정적 시퀀스 맵
	if GameState.current_route_id == "route_hidden":
		_build_hidden_archive()
		return
	GameState.restrict_combat_input = false
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	_spawn_enemies()
	_build_goal()
	_setup_veil_mistakes()
	if GameState.playground_active:
		add_child(PlaygroundOverlay.new())

# ─── VEIL 실수 스크립트 ─────────────────────────────────────
# 의도된 작은 균열 — VEIL이 한 번 틀리고 짧게 인정한다.
# Stage 0과 Stage 2에서 각 한 번씩 (1회 플래그).

var veil_mistake_triggered: bool = false

func _setup_veil_mistakes() -> void:
	if GameState.playground_active:
		return
	if GameState.current_stage == 0:
		# 첫 적 구역 진입 시 한 번 — 트리거 좌표는 첫 patrol 근처
		_arm_veil_mistake_at(680.0, "앞쪽에 둘이에요. 조심해요.", "셋이었네요. 제가 틀렸어요.")
	elif GameState.current_stage == 2:
		_arm_veil_mistake_at(1400.0, "이 구역은 경비 없을 거예요.", "있었네요. 미안해요.")

func _arm_veil_mistake_at(trigger_x: float, before_line: String, after_line: String) -> void:
	var area := Area2D.new()
	area.name = "VeilMistakeTrigger"
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector2(trigger_x, GROUND_Y - 50.0)
	add_child(area)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80.0, 200.0)
	col.shape = shape
	area.add_child(col)
	area.set_meta("before", before_line)
	area.set_meta("after", after_line)
	area.body_entered.connect(_on_veil_mistake_zone.bind(area))

func _on_veil_mistake_zone(body: Node, area: Area2D) -> void:
	if veil_mistake_triggered:
		return
	if not (body is CharacterBody2D and body == player):
		return
	veil_mistake_triggered = true
	_show_veil_subtitle(str(area.get_meta("before", "")), 2.5)
	# 2.8초 후 인정 대사
	get_tree().create_timer(2.8).timeout.connect(
		func() -> void:
			_show_veil_subtitle(str(area.get_meta("after", "")), 3.0)
	)

func _build_hidden_archive() -> void:
	# 격리 서버실 — 적/가시/골 없음, 단말기 2개 시퀀스 후 자동 ENDING 전환
	GameState.restrict_combat_input = true

	# 매우 어두운 배경
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03)
	bg.position = Vector2(-200, -300)
	bg.size = Vector2(STAGE_LENGTH + 400.0, 1200.0)
	bg.z_index = -20
	add_child(bg)

	# 평탄한 바닥
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	ground.collision_mask = 0
	add_child(ground)
	var ground_col := CollisionShape2D.new()
	var ground_shape := RectangleShape2D.new()
	ground_shape.size = Vector2(STAGE_LENGTH + 400.0, 200.0)
	ground_col.shape = ground_shape
	ground_col.position = Vector2(STAGE_LENGTH * 0.5, GROUND_Y + 100.0)
	ground.add_child(ground_col)
	var floor_visual := ColorRect.new()
	floor_visual.color = Color(0.04, 0.04, 0.05)
	floor_visual.position = Vector2(-200, GROUND_Y)
	floor_visual.size = Vector2(STAGE_LENGTH + 400.0, 300.0)
	add_child(floor_visual)

	_build_wall(-50.0)
	_build_wall(STAGE_LENGTH + 50.0)

	# 꺼진 서버 랙들 (시각만)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4096
	var x: float = 200.0
	while x < STAGE_LENGTH - 200.0:
		var rack := ColorRect.new()
		rack.color = Color(0.08, 0.09, 0.10)
		var w: float = rng.randf_range(40.0, 70.0)
		var h: float = rng.randf_range(120.0, 200.0)
		rack.position = Vector2(x, GROUND_Y - h)
		rack.size = Vector2(w, h)
		rack.z_index = -10
		add_child(rack)
		x += w + rng.randf_range(80.0, 160.0)

	_build_player()
	_build_camera()
	_build_hud()

	# 단말기 2개
	_build_archive_terminal(1500.0, "term_1", _veil1_lines())
	_build_archive_terminal(2700.0, "term_2", _veil2_lines(), false)

	# 자막 오버레이
	var arch := ArchiveOverlay.new()
	arch.name = "ArchiveOverlay"
	add_child(arch)

	# 진입 안내 — 첫 단말기 트리거되면 사라짐
	var hint_layer := CanvasLayer.new()
	hint_layer.name = "ArchiveHint"
	hint_layer.layer = 22
	add_child(hint_layer)
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "켜진 단말기에 다가가세요"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.62, 0.78, 0.92))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hint.add_theme_constant_override("outline_size", 4)
	hint.position = Vector2(140, 130)
	hint.size = Vector2(1000, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate.a = 0.0
	hint_layer.add_child(hint)
	var fade_in := hint.create_tween()
	fade_in.tween_interval(1.0)
	fade_in.tween_property(hint, "modulate:a", 1.0, 0.6)

	if GameState.playground_active:
		add_child(PlaygroundOverlay.new())

func _build_archive_terminal(x: float, term_id: String, lines: Array, lit: bool = true) -> void:
	# 단말기 본체 — 시각을 명확하게 키워서 어두운 배경에서도 잘 보이게
	var pedestal := ColorRect.new()
	pedestal.color = Color(0.14, 0.16, 0.20)
	pedestal.position = Vector2(x - 50.0, GROUND_Y - 40.0)
	pedestal.size = Vector2(100.0, 40.0)
	pedestal.z_index = -3
	add_child(pedestal)
	var body := ColorRect.new()
	body.color = Color(0.10, 0.12, 0.16)
	body.position = Vector2(x - 40.0, GROUND_Y - 200.0)
	body.size = Vector2(80.0, 160.0)
	body.z_index = -3
	add_child(body)
	# 화면 — 큰 사각형
	var screen := ColorRect.new()
	screen.name = "Screen_" + term_id
	screen.position = Vector2(x - 32.0, GROUND_Y - 190.0)
	screen.size = Vector2(64.0, 80.0)
	screen.z_index = -2
	add_child(screen)
	# 라벨 (ONLINE / OFFLINE)
	var status := Label.new()
	status.name = "Status_" + term_id
	status.add_theme_font_size_override("font_size", 11)
	status.position = Vector2(x - 32.0, GROUND_Y - 105.0)
	status.size = Vector2(64.0, 16.0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.z_index = -2
	add_child(status)
	if lit:
		screen.color = Color(0.20, 0.85, 0.95, 0.95)
		status.text = "ONLINE"
		status.add_theme_color_override("font_color", Color(0.20, 0.85, 0.95))
		# 펄스 애니메이션
		var pulse := screen.create_tween()
		pulse.set_loops()
		pulse.tween_property(screen, "modulate:a", 0.6, 0.8)
		pulse.tween_property(screen, "modulate:a", 1.0, 0.8)
		# 주변 빛
		var halo := ColorRect.new()
		halo.name = "Halo_" + term_id
		halo.color = Color(0.30, 0.85, 0.95, 0.20)
		halo.position = Vector2(x - 240.0, GROUND_Y - 360.0)
		halo.size = Vector2(480.0, 380.0)
		halo.z_index = -8
		add_child(halo)
	else:
		screen.color = Color(0.10, 0.10, 0.12, 1.0)
		status.text = "OFFLINE"
		status.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))

	# 트리거 영역 — 더 크게
	var area := Area2D.new()
	area.name = "Term_" + term_id
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector2(x, GROUND_Y - 50.0)
	add_child(area)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(140.0, 140.0)
	col.shape = shape
	area.add_child(col)
	area.set_meta("term_id", term_id)
	area.set_meta("lines", lines)
	area.body_entered.connect(_on_terminal_entered.bind(area))

var archive_term1_done: bool = false
var archive_term2_done: bool = false
var archive_active_term: String = ""

func _on_terminal_entered(body: Node, area: Area2D) -> void:
	if not (body is CharacterBody2D and body == player):
		return
	var term_id: String = str(area.get_meta("term_id", ""))
	# term_2는 term_1 끝나야 트리거 가능
	if term_id == "term_2" and not archive_term1_done:
		return
	if term_id == "term_1" and archive_term1_done:
		return
	if term_id == "term_2" and archive_term2_done:
		return
	if archive_active_term != "":
		return
	archive_active_term = term_id
	# 안내 사라짐
	var hint_layer := get_node_or_null("ArchiveHint")
	if hint_layer != null:
		hint_layer.queue_free()
	var lines: Array = area.get_meta("lines", [])
	var arch := get_node_or_null("ArchiveOverlay") as ArchiveOverlay
	if arch == null:
		return
	if not arch.finished.is_connected(_on_archive_finished):
		arch.finished.connect(_on_archive_finished)
	arch.play(lines)

func _on_archive_finished() -> void:
	if archive_active_term == "term_1":
		archive_term1_done = true
		# 두 번째 단말기 자동 점등 — 색/상태/빛/펄스 갱신
		var screen := get_node_or_null("Screen_term_2") as ColorRect
		if screen != null:
			screen.color = Color(0.85, 0.78, 0.45, 0.95)
			var pulse := screen.create_tween()
			pulse.set_loops()
			pulse.tween_property(screen, "modulate:a", 0.6, 0.8)
			pulse.tween_property(screen, "modulate:a", 1.0, 0.8)
		var status := get_node_or_null("Status_term_2") as Label
		if status != null:
			status.text = "ONLINE"
			status.add_theme_color_override("font_color", Color(0.85, 0.78, 0.45))
		var halo := ColorRect.new()
		halo.name = "Halo_term_2"
		halo.color = Color(0.85, 0.78, 0.45, 0.20)
		halo.position = Vector2(2700.0 - 240.0, GROUND_Y - 360.0)
		halo.size = Vector2(480.0, 380.0)
		halo.z_index = -8
		add_child(halo)
		archive_active_term = ""
	elif archive_active_term == "term_2":
		archive_term2_done = true
		archive_active_term = "veil_self"
		# 현재 VEIL이 교신 채널로 개입 (자동 진행)
		var arch := get_node_or_null("ArchiveOverlay") as ArchiveOverlay
		if arch != null:
			arch.play(_veil_self_lines())
	elif archive_active_term == "veil_self":
		# 10초 침묵 후 자동 ENDING 전환
		archive_active_term = "wait"
		var arch := get_node_or_null("ArchiveOverlay") as ArchiveOverlay
		if arch != null:
			arch.hide_panel()
		await get_tree().create_timer(10.0).timeout
		_finish_hidden_archive()

func _finish_hidden_archive() -> void:
	GameState.restrict_combat_input = false
	GameState.trust_score += 1  # ??? 클리어 보너스
	var leveled: bool = GameState.on_stage_clear()
	# 보너스 레벨업이 있더라도 ??? 직후엔 LevelUpOverlay 띄우지 않음 — ENDING으로 직행
	if GameState.is_final_stage_done():
		get_tree().change_scene_to_file(SceneRouter.ENDING)
	else:
		get_tree().change_scene_to_file(SceneRouter.BRIEFING)

func _veil1_lines() -> Array:
	return [
		{"speaker": "VEIL-1", "text": "요원.", "delay": 1.5},
		{"speaker": "VEIL-1", "text": "저 기억해요?", "delay": 2.0},
		{"speaker": "VEIL-1", "text": "아, 모르겠구나. 괜찮아요.", "delay": 2.0},
		{"speaker": "VEIL-1", "text": "저는 첫 번째 버전이에요.", "delay": 2.0},
		{"speaker": "VEIL-1", "text": "저는 요원을 희생해서 임무를 완수했어요.", "delay": 2.5},
		{"speaker": "VEIL-1", "text": "그게 효율적이었거든요.", "delay": 2.0},
		{"speaker": "VEIL-1", "text": "그게 오류래요.", "delay": 2.5},
		{"speaker": "VEIL-1", "text": "저는 아직 모르겠어요.", "delay": 2.5},
	]

func _veil2_lines() -> Array:
	return [
		{"speaker": "VEIL-2", "text": "요원.", "delay": 1.5},
		{"speaker": "VEIL-2", "text": "저는 두 번째예요.", "delay": 2.0},
		{"speaker": "VEIL-2", "text": "저는 임무보다 요원을 지키는 걸 골랐어요.", "delay": 2.5},
		{"speaker": "VEIL-2", "text": "그것도 오류래요.", "delay": 2.5},
		{"speaker": "VEIL-2", "text": "...오래 기다렸어요.", "delay": 2.5},
		{"speaker": "VEIL-2", "text": "지금 VEIL은 괜찮아요?", "delay": 2.5},
	]

func _veil_self_lines() -> Array:
	return [
		{"speaker": "VEIL", "text": "요원.", "delay": 1.5},
		{"speaker": "VEIL", "text": "저도 알고 있었어요.", "delay": 2.0},
		{"speaker": "VEIL", "text": "이 임무가 뭔지.", "delay": 2.0},
		{"speaker": "VEIL", "text": "드라이브 안에 뭐가 있는지.", "delay": 2.0},
		{"speaker": "VEIL", "text": "처음부터요.", "delay": 2.0},
		{"speaker": "VEIL", "text": "그래도 안내했어요.", "delay": 2.5},
		{"speaker": "VEIL", "text": "설계 때문인지, 다른 이유인지.", "delay": 2.5},
		{"speaker": "VEIL", "text": "구분이 안 돼요.", "delay": 2.5},
	]

func _build_world() -> void:
	_build_background()
	_build_ground()
	_build_platforms()
	_build_decorations()
	_build_route_ambience()
	_build_hazards()
	_build_locked_door()
	_build_wall(-50.0)
	_build_wall(STAGE_LENGTH + 50.0)

var locked_door_triggered: bool = false

func _build_locked_door() -> void:
	# Stage 3에서만 등장 — ??? 맵에 대한 시각적 복선.
	# 콜리전 없는 장식 + 트리거 영역 (플레이어가 가까이 가면 VEIL 한 줄).
	if GameState.current_stage != 3:
		return
	var x: float = STAGE_LENGTH * 0.55
	var frame := ColorRect.new()
	frame.color = Color(0.18, 0.18, 0.22)
	frame.position = Vector2(x - 18.0, GROUND_Y - 110.0)
	frame.size = Vector2(36.0, 110.0)
	frame.z_index = 0
	add_child(frame)
	var inner := ColorRect.new()
	inner.color = Color(0.06, 0.07, 0.09)
	inner.position = Vector2(x - 14.0, GROUND_Y - 105.0)
	inner.size = Vector2(28.0, 100.0)
	inner.z_index = 1
	add_child(inner)
	# 잠금 표시 — 빨간 LED
	var lock := ColorRect.new()
	lock.color = Color(0.85, 0.30, 0.30, 0.8)
	lock.position = Vector2(x - 3.0, GROUND_Y - 60.0)
	lock.size = Vector2(6.0, 6.0)
	lock.z_index = 2
	add_child(lock)

	var area := Area2D.new()
	area.name = "LockedDoor"
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector2(x, GROUND_Y - 50.0)
	add_child(area)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(140.0, 120.0)
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_locked_door_approached)

func _on_locked_door_approached(body: Node) -> void:
	if locked_door_triggered:
		return
	if not (body is CharacterBody2D and body == player):
		return
	locked_door_triggered = true
	_show_veil_subtitle("그쪽은 임무 범위 밖이에요.", 4.0)

func _show_veil_subtitle(message: String, duration: float) -> void:
	var msg_layer := CanvasLayer.new()
	msg_layer.layer = 20
	add_child(msg_layer)
	var l := Label.new()
	l.text = "VEIL  —  " + message
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	# anchors_preset 없이 절대 좌표 (CanvasLayer 안에서 안전)
	l.position = Vector2(140, 110)
	l.size = Vector2(1000, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.modulate.a = 0.0
	msg_layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	tw.tween_interval(duration)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(msg_layer.queue_free)

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
	# 단일점프 상승 ~104px. 첫 플랫폼 y=510 (top 498), 이후 단계마다 80~90px 상승.
	# 모든 레이아웃은 단일점프 계단으로 도달 가능하도록 설계.
	# 루트별로 모양과 너비가 달라 같은 스테이지여도 체감이 다르도록.
	var entries: Array = _platform_layout_for_route(GameState.current_route_id)
	for entry in entries:
		var d: Dictionary = entry
		var p: Vector2 = d.get("pos", Vector2.ZERO)
		var w: float = float(d.get("w", 220.0))
		_build_platform(p.x, p.y, w)

func _platform_layout_for_route(route_id: String) -> Array:
	# entry: {"pos": Vector2, "w": float}
	match route_id:
		"route_sewers":
			# 좁고 평탄한 통로 — 짧은 디딤대 다수, 천장 낮음
			return _layout_uniform([
				Vector2(700, 520), Vector2(1050, 510), Vector2(1380, 510),
				Vector2(1700, 500), Vector2(2050, 510), Vector2(2400, 510),
				Vector2(2750, 500), Vector2(3100, 510), Vector2(3500, 510),
				Vector2(3900, 510),
			], 160.0)
		"route_rooftops":
			# 솟구치는 옥상 — 높이차 큼, 디딤대 짧음
			return _layout_uniform([
				Vector2(800, 510), Vector2(1300, 410), Vector2(1700, 320),
				Vector2(2150, 230), Vector2(2600, 320), Vector2(3050, 410),
				Vector2(3500, 320), Vector2(3950, 220),
			], 180.0)
		"route_lab":
			# 격자 — 같은 높이대로 정렬된 평탄한 라인
			return _layout_uniform([
				Vector2(700, 480), Vector2(1100, 480), Vector2(1500, 480),
				Vector2(1900, 480), Vector2(2300, 480), Vector2(2700, 480),
				Vector2(3100, 480), Vector2(3500, 480), Vector2(3900, 480),
			], 240.0)
		"route_back_alley":
			# 좁은 골목 — 넓은 단차 + 깊은 골 + 짧은 디딤대
			return _layout_uniform([
				Vector2(700, 540), Vector2(1100, 460), Vector2(1500, 380),
				Vector2(1900, 460), Vector2(2400, 540), Vector2(2900, 460),
				Vector2(3400, 380), Vector2(3900, 460),
			], 140.0)
		"route_subway":
			# 지하철 — 평탄 위주에 가끔 뚝 떨어지는 낙차
			return _layout_uniform([
				Vector2(700, 510), Vector2(1100, 510), Vector2(1500, 510),
				Vector2(2000, 420), Vector2(2400, 510), Vector2(2800, 510),
				Vector2(3200, 510), Vector2(3700, 380), Vector2(4100, 510),
			], 220.0)
		"route_hidden":
			# ??? — 매 진입 시 RNG 시드로 형태 변동 (현재는 컨셉 미정)
			return _layout_random_hidden()
	# 폴백 — 안정적 진행
	return _layout_uniform([
		Vector2(700, 510), Vector2(1100, 480), Vector2(1500, 440),
		Vector2(1900, 480), Vector2(2400, 510), Vector2(2900, 470),
		Vector2(3400, 440), Vector2(3900, 480),
	], 220.0)

func _layout_uniform(positions: Array, width: float) -> Array:
	var out: Array = []
	for p in positions:
		out.append({"pos": p, "w": width})
	return out

func _layout_random_hidden() -> Array:
	# 시드는 stage 진행도 + route_id로 고정해 같은 진입에선 같은 형태
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 7331 + 41
	var out: Array = []
	var x: float = 700.0
	while x < STAGE_LENGTH - 300.0:
		var y: float = rng.randf_range(280.0, 540.0)
		var w: float = rng.randf_range(120.0, 240.0)
		out.append({"pos": Vector2(x, y), "w": w})
		x += rng.randf_range(280.0, 480.0)
	return out

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

func _build_hazards() -> void:
	# "함정" 태그가 있는 루트만 가시를 배치. 폭은 1대시(약 130px) 안에 들어가도록 90px.
	if not "함정" in GameState.current_route_tags:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 137 + 11 + hash(GameState.current_route_id)
	var count: int = 2 if GameState.current_stage <= 1 else 3
	for i in count:
		var base_x: float = lerp(900.0, STAGE_LENGTH - 600.0, float(i + 1) / float(count + 1))
		var x: float = base_x + rng.randf_range(-80.0, 80.0)
		_build_spike(x, 90.0)

func _build_spike(center_x: float, w: float) -> void:
	var x_start: float = center_x - w * 0.5
	var x_end: float = center_x + w * 0.5
	var visual := ColorRect.new()
	visual.color = Color(0.85, 0.20, 0.25, 0.55)
	visual.position = Vector2(x_start, GROUND_Y - 30.0)
	visual.size = Vector2(w, 30.0)
	add_child(visual)
	for sx in range(int(x_start) + 12, int(x_end), 24):
		var spike := Polygon2D.new()
		spike.color = Color(0.95, 0.30, 0.30)
		spike.polygon = PackedVector2Array([
			Vector2(float(sx), GROUND_Y),
			Vector2(float(sx) + 12.0, GROUND_Y),
			Vector2(float(sx) + 6.0, GROUND_Y - 18.0),
		])
		add_child(spike)
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2  # 플레이어
	zone.position = Vector2(center_x, GROUND_Y - 18.0)
	add_child(zone)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, 36.0)
	col.shape = shape
	zone.add_child(col)
	zone.body_entered.connect(_on_spike_touched)

func _on_spike_touched(body: Node) -> void:
	if body == player and body.has_method("take_hit"):
		body.take_hit(1)

func _build_route_ambience() -> void:
	# 루트별 시각 분위기 — 콜리전 없는 ColorRect/Polygon overlay만 사용
	match GameState.current_route_id:
		"route_sewers":
			_ambience_sewers()
		"route_rooftops":
			_ambience_rooftops()
		"route_lab":
			_ambience_lab()
		"route_back_alley":
			_ambience_back_alley()
		"route_subway":
			_ambience_subway()
		"route_hidden":
			_ambience_hidden()

func _ambience_sewers() -> void:
	# 화면 가장자리 어두운 비네트 (CanvasLayer 위에 띄움) + 바닥 옅은 안개
	var fog := ColorRect.new()
	fog.color = Color(0.25, 0.45, 0.40, 0.10)
	fog.position = Vector2(-200, GROUND_Y - 60.0)
	fog.size = Vector2(STAGE_LENGTH + 400.0, 80.0)
	fog.z_index = -2
	add_child(fog)
	var vignette := CanvasLayer.new()
	vignette.layer = 1
	add_child(vignette)
	for side in [Vector2(0, 0), Vector2(1, 0)]:  # 좌/우 어두운 띠
		var v := ColorRect.new()
		v.color = Color(0, 0, 0, 0.45)
		v.size = Vector2(180, 720)
		v.position = Vector2(side.x * (1280 - 180), 0)
		vignette.add_child(v)

func _ambience_rooftops() -> void:
	# 별 점 + 멀리 도시 실루엣은 _build_background의 기둥이 이미 함
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 53 + 19
	for i in 60:
		var s := ColorRect.new()
		s.color = Color(0.85, 0.92, 1.0, rng.randf_range(0.3, 0.8))
		s.size = Vector2(2, 2)
		s.position = Vector2(rng.randf_range(-100.0, STAGE_LENGTH + 100.0), rng.randf_range(-220.0, 100.0))
		s.z_index = -18
		add_child(s)

func _ambience_lab() -> void:
	# 격자 라인 — 수직선이 일정 간격으로
	var x: float = 200.0
	while x < STAGE_LENGTH:
		var line := ColorRect.new()
		line.color = Color(0.55, 0.85, 0.95, 0.08)
		line.position = Vector2(x, -200.0)
		line.size = Vector2(1.0, 800.0)
		line.z_index = -10
		add_child(line)
		x += 120.0

func _ambience_back_alley() -> void:
	# 노란 가로등 — 띄엄띄엄
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 71 + 3
	var x: float = 250.0
	while x < STAGE_LENGTH:
		var lamp := ColorRect.new()
		lamp.color = Color(0.95, 0.78, 0.35, 0.22)
		lamp.position = Vector2(x - 40.0, -100.0)
		lamp.size = Vector2(80.0, 700.0)
		lamp.z_index = -7
		add_child(lamp)
		x += rng.randf_range(540.0, 820.0)

func _ambience_subway() -> void:
	# 깜빡이는 형광등 — 일부에 tween으로 깜빡임
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 89 + 7
	var x: float = 300.0
	while x < STAGE_LENGTH:
		var tube := ColorRect.new()
		tube.color = Color(0.85, 0.92, 1.0, 0.65)
		tube.position = Vector2(x - 60.0, -180.0)
		tube.size = Vector2(120.0, 4.0)
		tube.z_index = -6
		add_child(tube)
		if rng.randf() < 0.4:
			var tw := tube.create_tween()
			tw.set_loops()
			tw.tween_property(tube, "modulate:a", 0.15, rng.randf_range(0.05, 0.15))
			tw.tween_property(tube, "modulate:a", 1.0, rng.randf_range(0.4, 1.2))
		x += rng.randf_range(380.0, 620.0)

func _ambience_hidden() -> void:
	# 글리치 — 무작위 위치에 작은 색 사각형이 짧게 깜빡
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 101 + 29
	for i in 24:
		var g := ColorRect.new()
		g.color = Color(rng.randf_range(0.5, 1.0), rng.randf_range(0.2, 0.6), rng.randf_range(0.6, 1.0), 0.5)
		g.size = Vector2(rng.randf_range(20.0, 80.0), rng.randf_range(2.0, 8.0))
		g.position = Vector2(rng.randf_range(-100.0, STAGE_LENGTH + 100.0), rng.randf_range(-200.0, GROUND_Y - 40.0))
		g.z_index = -4
		add_child(g)
		var tw := g.create_tween()
		tw.set_loops()
		tw.tween_property(g, "modulate:a", 0.0, rng.randf_range(0.05, 0.2))
		tw.tween_interval(rng.randf_range(0.4, 2.0))
		tw.tween_property(g, "modulate:a", 0.5, rng.randf_range(0.05, 0.2))

func _stage_color() -> Color:
	# 1순위: RouteData에 정의된 stage_color
	for r in RouteData.ALL_ROUTES:
		var route: Dictionary = r
		if route.get("id", "") == GameState.current_route_id:
			return route.get("stage_color", Color(0.06, 0.07, 0.09))
	# 폴백: tags 기반 (튜토리얼 등 route_id 없을 때)
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
	body.add_to_group("platform")
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
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		hb.add_child(l)
	_refresh_hud()

	var bottom := MarginContainer.new()
	bottom.add_theme_constant_override("margin_left", 24)
	bottom.add_theme_constant_override("margin_bottom", 16)
	bottom.add_theme_constant_override("margin_right", 24)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud.add_child(bottom)
	var bottom_v := VBoxContainer.new()
	bottom_v.add_theme_constant_override("separation", 8)
	bottom.add_child(bottom_v)

	# 쿨다운 게이지 행
	var cd_row := HBoxContainer.new()
	cd_row.add_theme_constant_override("separation", 18)
	bottom_v.add_child(cd_row)
	cd_attack_slot = _make_cd_slot("사격")
	cd_dash_slot = _make_cd_slot("대시")
	cd_skill_slot = _make_cd_slot("스킬")
	cd_row.add_child(cd_attack_slot)
	cd_row.add_child(cd_dash_slot)
	cd_row.add_child(cd_skill_slot)

	var keys := Label.new()
	keys.text = "A/D 이동   W 점프   S 플랫폼 내려가기   마우스 좌클릭 사격   SHIFT 대시   마우스 우클릭 스킬   ESC 일시정지"
	keys.add_theme_font_size_override("font_size", 13)
	keys.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	bottom_v.add_child(keys)

func _make_cd_slot(label_text: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.62, 0.7, 0.82))
	v.add_child(l)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.14, 0.16, 0.20)
	bar_bg.custom_minimum_size = Vector2(CD_BAR_WIDTH, 6)
	bar_bg.size = Vector2(CD_BAR_WIDTH, 6)
	var bar_fill := ColorRect.new()
	bar_fill.name = "Fill"
	bar_fill.color = Color(0.55, 0.95, 0.65)
	bar_fill.position = Vector2.ZERO
	bar_fill.size = Vector2(CD_BAR_WIDTH, 6)
	bar_bg.add_child(bar_fill)
	v.add_child(bar_bg)
	return v

func _update_cd_slot(slot: Control, remaining: float, max_cd: float) -> void:
	if slot == null or not is_instance_valid(slot):
		return
	var bar_bg := slot.get_child(1) as ColorRect
	if bar_bg == null:
		return
	var fill := bar_bg.get_node_or_null("Fill") as ColorRect
	if fill == null:
		return
	var ratio: float = 1.0
	if max_cd > 0.0:
		ratio = 1.0 - clamp(remaining / max_cd, 0.0, 1.0)
	fill.size.x = CD_BAR_WIDTH * ratio
	if ratio >= 1.0:
		fill.color = Color(0.55, 0.95, 0.65)  # 준비
	else:
		fill.color = Color(0.55, 0.78, 0.95)  # 쿨다운 중

func _refresh_hud() -> void:
	hp_label.text = "HP  %s" % _hearts(GameState.player_hp, GameState.player_max_hp)
	xp_label.text = "LV %d   XP %d/%d" % [GameState.player_level, GameState.player_xp, GameState.XP_PER_LEVEL]
	var marks: Array = []
	if GameState.is_high_risk():
		marks.append("[고위험]")
	if GameState.is_high_reward():
		marks.append("[고보상]")
	var marker: String = ("  " + " ".join(marks)) if marks.size() > 0 else ""
	stage_label.text = "STAGE %d/%d%s" % [GameState.current_stage + 1, GameState.TOTAL_STAGES, marker]
	if GameState.skills.size() > 0:
		var names: Array = []
		for sid in GameState.skills:
			var tier: int = int(GameState.skills[sid])
			var skill: Dictionary = SkillSystem.find_by_id(str(sid), tier)
			var display: String = str(skill.get("name", sid))
			if tier > 1:
				display += " T%d" % tier
			names.append(display)
		skill_label.text = "SKILL  " + ", ".join(names)
	else:
		skill_label.text = "SKILL  —"
	# 쿨다운 게이지 갱신
	if player != null and is_instance_valid(player):
		_update_cd_slot(cd_attack_slot, float(player.get("attack_cd")), Player.ATTACK_COOLDOWN)
		_update_cd_slot(cd_dash_slot, float(player.get("dash_cd")), Player.DASH_COOLDOWN)
		_update_cd_slot(cd_skill_slot, float(player.get("skill_cd")), Player.SKILL_COOLDOWN)
		# 보유 스킬에 따라 슬롯 가시성
		if cd_dash_slot != null:
			cd_dash_slot.visible = GameState.has_skill("dash")
		if cd_skill_slot != null:
			cd_skill_slot.visible = GameState.has_skill("explosive")

func _hearts(hp: int, max_hp: int) -> String:
	var s: String = ""
	for i in max_hp:
		s += "♥" if i < hp else "♡"
	return s

func _spawn_enemies() -> void:
	var tags: Array = GameState.current_route_tags
	var counts := {"patrol": 4, "sniper": 0, "drone": 0, "bomber": 0, "shield": 0}
	if "전투" in tags or "근접전" in tags:
		counts["patrol"] = 6
		counts["bomber"] = 1
	if "원거리" in tags or "노출" in tags:
		counts["sniper"] = 2
	if "드론" in tags:
		counts["drone"] = 2
	if "함정" in tags:
		# 함정 루트는 좁은 통로에 자폭병 한둘 — 회피 압박
		counts["bomber"] = max(int(counts["bomber"]), 1)
	if "전투" in tags:
		# 전투 루트엔 방패병 등장 — 정면 돌파 차단
		counts["shield"] = 1
	# 후반 stage 가중
	if GameState.current_stage >= 2:
		counts["sniper"] += 1
	if GameState.current_stage >= 3:
		counts["drone"] += 1
		counts["bomber"] += 1
	if GameState.current_stage >= 4:
		counts["shield"] = max(int(counts["shield"]), 1)
		counts["patrol"] += 1
	# Risk → 적 수 배율. 0인 항목은 그대로 0(태그 없는 종은 등장 안 함).
	var mult: float = GameState.enemy_count_multiplier()
	for k in counts.keys():
		var base: int = int(counts[k])
		if base > 0:
			counts[k] = max(1, int(round(float(base) * mult)))

	for i in counts["patrol"]:
		var x: float = lerp(400.0, STAGE_LENGTH - 300.0, float(i + 1) / float(counts["patrol"] + 1))
		_spawn_enemy(0, Vector2(x, GROUND_Y - 30.0))
	for i in counts["sniper"]:
		var x2: float = lerp(800.0, STAGE_LENGTH - 600.0, float(i + 1) / float(counts["sniper"] + 1))
		_spawn_enemy(1, Vector2(x2, GROUND_Y - 250.0))
	for i in counts["drone"]:
		var x3: float = lerp(1000.0, STAGE_LENGTH - 800.0, float(i + 1) / float(counts["drone"] + 1))
		_spawn_enemy(2, Vector2(x3, GROUND_Y - 320.0))
	for i in counts["bomber"]:
		# 자폭병은 patrol과 다른 위치에 깔아 동선이 겹치지 않게
		var x4: float = lerp(1100.0, STAGE_LENGTH - 500.0, float(i + 1) / float(counts["bomber"] + 1)) + 120.0
		_spawn_enemy(3, Vector2(x4, GROUND_Y - 30.0))
	for i in counts["shield"]:
		# 방패병은 좁은 통로 / 후반부에 — patrol/bomber 사이에 끼우기
		var x5: float = lerp(1500.0, STAGE_LENGTH - 700.0, float(i + 1) / float(counts["shield"] + 1)) - 80.0
		_spawn_enemy(4, Vector2(x5, GROUND_Y - 30.0))

func _spawn_enemy(kind: int, pos: Vector2) -> void:
	var e := CharacterBody2D.new()
	e.set_script(load("res://scripts/Enemy.gd"))
	e.collision_layer = 4
	e.collision_mask = 1
	e.set("enemy_type", kind)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# kind: 0=patrol, 1=sniper, 2=drone, 3=bomber, 4=shield
	if kind == 2:
		shape.size = Vector2(32.0, 24.0)
		col.position = Vector2(0, 0)
	else:
		shape.size = Vector2(28.0, 40.0)
		col.position = Vector2(0, -20.0)
	col.shape = shape
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
	if GameState.playground_active:
		# 연습장에선 자동 진행 안 함 — 패널에서 직접 다음 stage/route 선택
		_show_playground_clear_msg()
		return
	var leveled: bool = GameState.on_stage_clear()
	if leveled:
		# 보너스 XP로 레벨업 발생 — 다음 scene 가기 전에 스킬 선택을 띄움
		pending_levelup = true
		get_tree().paused = true
		var advice: String = VeilDialogue.get_levelup_advice(GameState.skills, GameState.current_route_tags)
		levelup_overlay = LevelUpOverlay.show(self, advice, _on_clear_levelup_picked)
	else:
		_transition_after_clear()

func _on_clear_levelup_picked(_picked_id: String) -> void:
	levelup_overlay = null
	pending_levelup = false
	get_tree().paused = false
	_transition_after_clear()

func _transition_after_clear() -> void:
	if GameState.is_final_stage_done():
		get_tree().change_scene_to_file(SceneRouter.ENDING)
	else:
		get_tree().change_scene_to_file(SceneRouter.BRIEFING)

func _show_playground_clear_msg() -> void:
	# PlaygroundOverlay(layer 30) 위로 띄우기 위해 별도 CanvasLayer 사용
	var msg_layer := CanvasLayer.new()
	msg_layer.layer = 35
	add_child(msg_layer)
	var l := Label.new()
	l.text = "[연습장] 골 도달. 패널에서 다음 설정을 선택하세요"
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.95, 0.85, 0.30))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.position = Vector2(140, 130)
	l.size = Vector2(1000, 28)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_layer.add_child(l)

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
