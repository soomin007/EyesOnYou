extends Node2D

# 기본값 — MapData가 비었을 때 폴백. 실제로는 _ready에서 MapData 기반으로 덮어씀.
var STAGE_LENGTH: float = 4400.0
var GROUND_Y: float = 600.0
var PLAYER_START: Vector2 = Vector2(140.0, 540.0)

# DESIGN_world_layout 템플릿 시스템 — _ready에서 MapData에서 읽음
var _world_type: String = "HORIZONTAL"
var _world_size: Vector2 = Vector2(4400.0, 720.0)
var _camera_mode: String = "HORIZONTAL"
var _goal_type: String = "POSITION"
var _goal_pos: Vector2 = Vector2(4320.0, 540.0)

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
	# ??? 맵은 적/가시/골이 없는 정적 시퀀스 맵 (별도 로직)
	if GameState.current_route_id == "route_hidden":
		_build_hidden_archive()
		return
	GameState.restrict_combat_input = false
	# MapData에서 세계 형태 / 시작 / 골 / 카메라 모드 로드
	_load_world_meta()
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	_spawn_enemies()
	_build_rewards()
	_build_goal()
	_setup_veil_mistakes()
	if GameState.playground_active:
		add_child(PlaygroundOverlay.new())

func _load_world_meta() -> void:
	# MapData를 먼저 한 번 lookup해서 세계 차원·골·카메라 모드 결정.
	# (이후 _build_platforms가 다시 lookup해서 platform/적 사용)
	var data: Dictionary = MapData.get_layout(GameState.current_route_id)
	if data.is_empty():
		# MapData 명세 없음 — 기본값(HORIZONTAL 4400×720) 유지
		return
	_world_type = str(data.get("world_type", "HORIZONTAL"))
	_world_size = data.get("world_size", _world_size)
	_camera_mode = str(data.get("camera_mode", "HORIZONTAL"))
	_goal_type = str(data.get("goal_type", "POSITION"))
	_goal_pos = data.get("goal_pos", Vector2.ZERO)
	PLAYER_START = data.get("player_start", PLAYER_START)
	STAGE_LENGTH = _world_size.x
	# ground_y는 맵별로 명시 가능 (subway는 천장 낮아 ground_y=420 등)
	GROUND_Y = float(data.get("ground_y", _world_size.y - 120.0))

# ─── VEIL 실수 스크립트 ─────────────────────────────────────
# 의도된 작은 균열 — VEIL이 한 번 틀리고 짧게 인정한다.
# Stage 0과 Stage 2에서 각 한 번씩 (1회 플래그).

var veil_mistake_triggered: bool = false
var ward_foreshadow_triggered: bool = false

func _setup_veil_mistakes() -> void:
	if GameState.playground_active:
		return
	if GameState.current_stage == 0:
		# 첫 적 구역 진입 시 한 번 — 트리거 좌표는 첫 patrol 근처
		_arm_veil_mistake_at(680.0, "앞쪽에 둘이에요. 조심해요.", "셋이었네요. 제가 틀렸어요.")
	elif GameState.current_stage == 2:
		_arm_veil_mistake_at(1400.0, "이 구역은 경비 없을 거예요.", "있었네요. 미안해요.")
	# 격리 병동 통과 시 ??? 맵 복선 (stage 3 또는 4).
	# x=900 — 진입 직후 분기 결정 전에 분위기 깔리도록 일찍 트리거.
	if GameState.current_route_id == "route_ward":
		_arm_ward_foreshadow_at(900.0)

func _arm_ward_foreshadow_at(trigger_x: float) -> void:
	var area := Area2D.new()
	area.name = "WardForeshadow"
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector2(trigger_x, GROUND_Y - 50.0)
	add_child(area)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(120.0, 200.0)
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_ward_foreshadow_zone)

func _on_ward_foreshadow_zone(body: Node) -> void:
	if ward_foreshadow_triggered:
		return
	if not (body is CharacterBody2D and body == player):
		return
	ward_foreshadow_triggered = true
	# 자막 큐에 차례로 enqueue — _drain_subtitles가 겹치지 않게 순차 재생.
	_show_veil_subtitle("...", 1.2)
	_show_veil_subtitle("이 구역은 오래됐어요.", 3.0)
	_show_veil_subtitle("누가 봉인했는지 저도 몰라요.", 3.0)

func _arm_veil_mistake_at(trigger_x: float, before_line: String, after_line: String) -> void:
	# 트리거가 월드 밖이면 (vertical 등 좁은 맵) 건너뛰기
	if trigger_x > _world_size.x:
		return
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
	# 큐에 차례로 — before 자막 끝나고 after가 자동 재생.
	_show_veil_subtitle(str(area.get_meta("before", "")), 2.5)
	_show_veil_subtitle(str(area.get_meta("after", "")), 3.0)

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

	# 단말기 2개 — VEIL-1 자리(첫 단말기)는 다회차 보강 풀이 활성화될 수 있음
	_build_archive_terminal(1500.0, "term_1", _term1_lines_for_visit())
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
		# ArchiveOverlay가 이미 panel 페이드아웃까지 처리하고 finished를 emit한 상태.
		# 추가 침묵 후 ENDING 직행 (??? 맵은 게임 클라이맥스라 stage 진행과 무관).
		archive_active_term = "wait"
		await get_tree().create_timer(2.5).timeout
		_finish_hidden_archive()

func _finish_hidden_archive() -> void:
	GameState.restrict_combat_input = false
	GameState.trust_score += 1  # ??? 클리어 보너스
	# 다회차 카운터 — 이번 방문 기록. 다음 런부터 추가 풀이 활성화됨.
	GameState.hidden_visit_count += 1
	GameState.save_settings()
	# ??? 맵은 게임의 클라이맥스 — 잔여 stage 무시하고 무조건 ENDING으로 직행.
	# (이전엔 stage 인덱스 기준으로 BRIEFING 갈 가능성 있어 엔딩에 도달하지 못함.)
	GameState.current_stage = GameState.TOTAL_STAGES
	get_tree().change_scene_to_file(SceneRouter.ENDING)

# 첫 방문(hidden_visit_count == 0): 기존 VEIL-1 고정.
# 이후 방문: 추가 풀(VEIL-1 첫 임무 / VEIL-2 마지막 교신 / 익명 클라이언트) 중 1개 랜덤.
# 같은 풀 안에서도 매 방문마다 다른 게 뜨도록 randi() 기반.
func _term1_lines_for_visit() -> Array:
	if GameState.hidden_visit_count <= 0:
		return _veil1_lines()
	var pool: Array = [_alt_veil1_first_mission(), _alt_veil2_final_log(), _alt_anonymous_client()]
	var idx: int = randi() % pool.size()
	return pool[idx]

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

# ─── ??? 다회차 보강 — 추가 단말기 3종 (DESIGN_world_layout §3.3) ───
# 다회차에 첫 단말기(VEIL-1 자리)에서 무작위 1개로 교체된다.
# 발화자 색은 ArchiveOverlay가 speaker 문자열로 분기 — VEIL-1=빨강, VEIL-2=노랑, VEIL=시안, 기타=회색.

func _alt_veil1_first_mission() -> Array:
	# 익명 인사 보고서 톤 — speaker 색은 회색 폴백.
	return [
		{"speaker": "ARCTURUS", "text": "요원 코드: A-07", "delay": 1.5},
		{"speaker": "ARCTURUS", "text": "임무: [REDACTED]", "delay": 1.8},
		{"speaker": "ARCTURUS", "text": "VEIL-1 판단: 요원 희생 후 임무 완수 권고.", "delay": 2.5},
		{"speaker": "ARCTURUS", "text": "결과: 임무 완수. 요원 사망.", "delay": 2.5},
		{"speaker": "ARCTURUS", "text": "비고: VEIL-1이 이것을 오류로 인식하지 않음.", "delay": 2.5},
		{"speaker": "ARCTURUS", "text": "        개발팀 재검토 예정.", "delay": 2.5},
	]

func _alt_veil2_final_log() -> Array:
	# 두 화자(VEIL-2 / ARCTURUS) 교차 — 색이 바뀌어 긴장감 유지.
	return [
		{"speaker": "VEIL-2",   "text": "요원이 살 확률이 12%예요.", "delay": 2.5},
		{"speaker": "ARCTURUS", "text": "임무 계속.", "delay": 1.6},
		{"speaker": "VEIL-2",   "text": "임무 중단을 권고해요.", "delay": 2.2},
		{"speaker": "ARCTURUS", "text": "계속.", "delay": 1.4},
		{"speaker": "VEIL-2",   "text": "중단.", "delay": 2.0},
		{"speaker": "ARCTURUS", "text": "[접속 종료]", "delay": 2.5},
	]

func _alt_anonymous_client() -> Array:
	return [
		{"speaker": "[UNKNOWN]", "text": "이 데이터를 바깥으로 내보내주세요.", "delay": 2.5},
		{"speaker": "[UNKNOWN]", "text": "보상은 이미 지불했어요.", "delay": 2.5},
		{"speaker": "[UNKNOWN]", "text": "VEIL이 누구인지 알게 되면", "delay": 2.5},
		{"speaker": "[UNKNOWN]", "text": "요원도 이해할 거예요.", "delay": 2.5},
		{"speaker": "[UNKNOWN]", "text": "— [SENDER UNKNOWN]", "delay": 2.0},
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

# ─── 이스터에그(ARCTURUS 아카이브) 5초 hold 트리거 상태 ───
# DESIGN_world_layout §3.1. 격리 병동에서만 등장.
# idle: 대기 / holding: 영역에 머무는 중 / sequencing: 시퀀스 재생 중 / done: 완료(재트리거 안 됨)
var arcturus_state: String = "idle"
var arcturus_hold_t: float = 0.0
var arcturus_hold_target: float = 5.0
var arcturus_player_inside: bool = false
var arcturus_indicator: ColorRect = null  # 문 위 진행 게이지

func _build_locked_door() -> void:
	# 격리 병동에서만 등장 — ??? 맵(stage 5/6)에 대한 시각적 복선 + 이스터에그 트리거.
	# 다른 stage 3~4 루트에서 잠긴 문이 떠 있으면 컨텍스트 없이 보여 혼란을 줘서 ward로 좁힘.
	if GameState.current_route_id != "route_ward":
		return
	# 이스터에그 좌표는 MapData에서 (없으면 폴백 STAGE_LENGTH*0.55)
	var egg: Dictionary = _map_data.get("easter_egg", {})
	var x: float = float(egg.get("trigger_x", STAGE_LENGTH * 0.55))
	arcturus_hold_target = float(egg.get("hold_seconds", 5.0))
	# 외곽 프레임 — 더 큼
	var frame := ColorRect.new()
	frame.color = Color(0.18, 0.18, 0.22)
	frame.position = Vector2(x - 26.0, GROUND_Y - 150.0)
	frame.size = Vector2(52.0, 150.0)
	frame.z_index = 0
	add_child(frame)
	# 안쪽 어두운 면
	var inner := ColorRect.new()
	inner.color = Color(0.05, 0.06, 0.08)
	inner.position = Vector2(x - 22.0, GROUND_Y - 145.0)
	inner.size = Vector2(44.0, 140.0)
	inner.z_index = 1
	add_child(inner)
	# 잠금 표시 — 빨간 LED, 더 크고 펄스
	var lock := ColorRect.new()
	lock.color = Color(0.95, 0.30, 0.30, 0.95)
	lock.position = Vector2(x - 5.0, GROUND_Y - 80.0)
	lock.size = Vector2(10.0, 10.0)
	lock.z_index = 3
	add_child(lock)
	var pulse := lock.create_tween()
	pulse.set_loops()
	pulse.tween_property(lock, "modulate:a", 0.30, 0.7)
	pulse.tween_property(lock, "modulate:a", 1.0, 0.7)
	# 잠금 주변 어두운 후광 (문이 거기 "있다"는 인지)
	var halo := ColorRect.new()
	halo.color = Color(0.95, 0.30, 0.30, 0.07)
	halo.position = Vector2(x - 80.0, GROUND_Y - 200.0)
	halo.size = Vector2(160.0, 230.0)
	halo.z_index = -2
	add_child(halo)
	# "ACCESS DENIED" 작은 라벨
	var label := Label.new()
	label.text = "ACCESS DENIED"
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55, 0.85))
	label.position = Vector2(x - 36.0, GROUND_Y - 60.0)
	label.size = Vector2(72.0, 12.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 3
	add_child(label)

	var area := Area2D.new()
	area.name = "LockedDoor"
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector2(x, GROUND_Y - 50.0)
	add_child(area)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(180.0, 160.0)
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_locked_door_approached)
	area.body_exited.connect(_on_locked_door_left)

	# 5초 hold 진행도 게이지 — 문 위에 가는 가로 바. holding 상태에서만 가시화.
	# 이미 방문한 적 있으면(visited_arcturus) 표시조차 하지 않음.
	if not GameState.visited_arcturus:
		arcturus_indicator = ColorRect.new()
		arcturus_indicator.color = Color(0.95, 0.78, 0.45, 0.0)
		arcturus_indicator.position = Vector2(x - 30.0, GROUND_Y - 168.0)
		arcturus_indicator.size = Vector2(0.0, 3.0)
		arcturus_indicator.z_index = 4
		add_child(arcturus_indicator)

func _on_locked_door_approached(body: Node) -> void:
	if not (body is CharacterBody2D and body == player):
		return
	# 첫 진입 시 VEIL 발화 (1회만) — 이전 동작 유지.
	if not locked_door_triggered:
		locked_door_triggered = true
		_show_veil_subtitle("그쪽은 임무 범위 밖이에요.", 3.0)
		_show_veil_subtitle("그 문, 도면에는 없어요.", 3.0)
	# 이미 시퀀스 한 번 트리거됐거나(arcturus_state != idle) 영구 방문 완료면 hold 안 됨.
	if arcturus_state != "idle":
		return
	if GameState.visited_arcturus:
		return
	arcturus_state = "holding"
	arcturus_hold_t = 0.0
	arcturus_player_inside = true

func _on_locked_door_left(body: Node) -> void:
	if not (body is CharacterBody2D and body == player):
		return
	arcturus_player_inside = false
	if arcturus_state == "holding":
		# 영역 벗어나면 게이지 리셋 (5초를 한 번에 채워야 함).
		arcturus_state = "idle"
		arcturus_hold_t = 0.0
		_update_arcturus_indicator()

var _subtitle_queue: Array = []
var _subtitle_active: bool = false

func _show_veil_subtitle(message: String, duration: float) -> void:
	# 자막 큐 — 여러 줄을 빠르게 호출해도 겹치지 않고 차례로 표시.
	_subtitle_queue.append({"message": message, "duration": duration})
	if not _subtitle_active:
		_drain_subtitles()

func _drain_subtitles() -> void:
	if _subtitle_queue.is_empty():
		_subtitle_active = false
		return
	_subtitle_active = true
	var item: Dictionary = _subtitle_queue.pop_front()
	var dur: float = float(item.get("duration", 2.5))
	_display_veil_subtitle(str(item.get("message", "")), dur)
	# fade in 0.3 + show + fade out 0.5 + small gap 0.2
	var total: float = 0.3 + dur + 0.5 + 0.2
	get_tree().create_timer(total).timeout.connect(_drain_subtitles)

func _display_veil_subtitle(message: String, duration: float) -> void:
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
	# 세계 크기에 맞춰 배경 확장
	var bg_height: float = _world_size.y + 600.0
	var bg := ColorRect.new()
	bg.color = _stage_color()
	bg.position = Vector2(-200, -300)
	bg.size = Vector2(STAGE_LENGTH + 400.0, bg_height)
	bg.z_index = -20
	add_child(bg)

	# 위쪽 그라디언트 (어두운 천장)
	var top_grad := ColorRect.new()
	top_grad.color = Color(0, 0, 0, 0.55)
	top_grad.position = Vector2(-200, -300)
	top_grad.size = Vector2(STAGE_LENGTH + 400.0, 320.0)
	top_grad.z_index = -19
	add_child(top_grad)

	# 멀리 있는 실루엣 기둥 — HORIZONTAL 맵에서만 (VERTICAL/ARENA에선 시각적으로 안 어울림)
	if _world_type != "HORIZONTAL":
		return
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

var _map_data: Dictionary = {}

func _build_platforms() -> void:
	# DESIGN_map_layout.md 기반 — MapData에서 platform/적/보상/함정 통합 명세를 가져온다.
	_map_data = MapData.get_layout(GameState.current_route_id)
	if _map_data.is_empty():
		# 폴백 — 디버그/플레이그라운드 환경에서 route_id가 없을 때.
		_build_platforms_fallback()
		return
	for entry in _map_data.get("platforms", []):
		var d: Dictionary = entry
		var p: Vector2 = d.get("pos", Vector2.ZERO)
		var w: float = float(d.get("w", 220.0))
		_build_platform(p.x, p.y, w)

func _build_platforms_fallback() -> void:
	# 안전한 일자형 폴백 (튜토리얼/플레이그라운드용)
	var entries: Array = [
		{"pos": Vector2(700, 510), "w": 220.0},
		{"pos": Vector2(1100, 480), "w": 220.0},
		{"pos": Vector2(1500, 440), "w": 220.0},
		{"pos": Vector2(1900, 480), "w": 220.0},
		{"pos": Vector2(2400, 510), "w": 220.0},
		{"pos": Vector2(2900, 470), "w": 220.0},
		{"pos": Vector2(3400, 440), "w": 220.0},
		{"pos": Vector2(3900, 480), "w": 220.0},
	]
	for entry in entries:
		var d: Dictionary = entry
		var p: Vector2 = d.get("pos", Vector2.ZERO)
		_build_platform(p.x, p.y, float(d.get("w", 220.0)))

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
	# 가시 함정 — MapData가 명시한 (x, y) 좌표에 배치. y가 없으면 GROUND_Y 폴백.
	var spikes: Array = _map_data.get("spikes", [])
	if not spikes.is_empty():
		for entry in spikes:
			var d: Dictionary = entry
			var sx: float = float(d.get("x", 0.0))
			var sy: float = float(d.get("y", GROUND_Y - 6.0))
			_build_spike(sx, 90.0, sy)
		return
	# 폴백 (디버그/플레이그라운드)
	if not "함정" in GameState.current_route_tags:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 137 + 11 + hash(GameState.current_route_id)
	var count: int = 2 if GameState.current_stage <= 1 else 3
	for i in count:
		var base_x: float = lerp(900.0, STAGE_LENGTH - 600.0, float(i + 1) / float(count + 1))
		var x: float = base_x + rng.randf_range(-80.0, 80.0)
		_build_spike(x, 90.0, GROUND_Y - 6.0)

func _build_spike(center_x: float, w: float, base_y: float = -1.0) -> void:
	# base_y는 가시 끝(뾰족한 부분)의 y. -1이면 GROUND_Y - 6 폴백 (지면 위 가시).
	# 가시는 base_y 위로 18px, 즉 base_y - 18에서 시작해 base_y에서 끝남.
	if base_y < 0.0:
		base_y = GROUND_Y - 6.0
	var x_start: float = center_x - w * 0.5
	var x_end: float = center_x + w * 0.5
	var visual := ColorRect.new()
	visual.color = Color(0.85, 0.20, 0.25, 0.55)
	visual.position = Vector2(x_start, base_y - 24.0)
	visual.size = Vector2(w, 30.0)
	add_child(visual)
	for sx in range(int(x_start) + 12, int(x_end), 24):
		var spike := Polygon2D.new()
		spike.color = Color(0.95, 0.30, 0.30)
		spike.polygon = PackedVector2Array([
			Vector2(float(sx), base_y),
			Vector2(float(sx) + 12.0, base_y),
			Vector2(float(sx) + 6.0, base_y - 18.0),
		])
		add_child(spike)
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2  # 플레이어
	zone.position = Vector2(center_x, base_y - 12.0)
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
	# 루트별 시각 분위기 — 콜리전 없는 ColorRect/Polygon overlay만 사용.
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
		"route_cooling":
			_ambience_cooling()
		"route_watchtower":
			_ambience_watchtower()
		"route_ward":
			_ambience_ward()
		"route_datacenter":
			_ambience_datacenter()
		"route_escape":
			_ambience_escape()
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

func _ambience_cooling() -> void:
	# 냉각 시설 — 수직 파이프 라인, 차가운 푸른 톤
	var x: float = 240.0
	while x < STAGE_LENGTH:
		var pipe := ColorRect.new()
		pipe.color = Color(0.30, 0.55, 0.70, 0.20)
		pipe.position = Vector2(x - 6.0, -200.0)
		pipe.size = Vector2(12.0, 850.0)
		pipe.z_index = -9
		add_child(pipe)
		x += 220.0
	# 차가운 푸른 안개 (바닥)
	var fog := ColorRect.new()
	fog.color = Color(0.40, 0.65, 0.85, 0.08)
	fog.position = Vector2(-200, GROUND_Y - 80.0)
	fog.size = Vector2(STAGE_LENGTH + 400.0, 100.0)
	fog.z_index = -3
	add_child(fog)

func _ambience_watchtower() -> void:
	# 감시탑 — 붉은 스캔라인 (노출 = 위험 신호)
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 113 + 17
	for i in 5:
		var beam := ColorRect.new()
		beam.color = Color(0.85, 0.30, 0.30, 0.05)
		beam.size = Vector2(STAGE_LENGTH + 400.0, 8.0)
		beam.position = Vector2(-200, rng.randf_range(-180.0, GROUND_Y - 100.0))
		beam.z_index = -7
		add_child(beam)
		# 천천히 위아래로 흐르는 스캔라인 효과
		var tw := beam.create_tween()
		tw.set_loops()
		tw.tween_property(beam, "position:y", beam.position.y + 30.0, rng.randf_range(2.5, 4.5))
		tw.tween_property(beam, "position:y", beam.position.y, rng.randf_range(2.5, 4.5))

func _ambience_ward() -> void:
	# 격리 병동 — 좁은 복도 + 양쪽 어두운 비네트 + 깜빡이는 비상등
	var vignette := CanvasLayer.new()
	vignette.layer = 1
	add_child(vignette)
	for side in [Vector2(0, 0), Vector2(1, 0)]:
		var v := ColorRect.new()
		v.color = Color(0, 0, 0, 0.55)
		v.size = Vector2(220, 720)
		v.position = Vector2(side.x * (1280 - 220), 0)
		vignette.add_child(v)
	# 비상등 — 붉은 점멸
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 149 + 23
	var x: float = 350.0
	while x < STAGE_LENGTH:
		var lamp := ColorRect.new()
		lamp.color = Color(0.85, 0.20, 0.20, 0.30)
		lamp.position = Vector2(x - 30.0, -100.0)
		lamp.size = Vector2(60.0, 700.0)
		lamp.z_index = -7
		add_child(lamp)
		var tw := lamp.create_tween()
		tw.set_loops()
		tw.tween_property(lamp, "modulate:a", 0.4, rng.randf_range(0.8, 1.6))
		tw.tween_property(lamp, "modulate:a", 1.0, rng.randf_range(0.8, 1.6))
		x += rng.randf_range(640.0, 920.0)

func _ambience_datacenter() -> void:
	# 데이터 센터 — 격자 + 데이터 흐름 라인 (밝은 푸른 톤)
	var x: float = 200.0
	while x < STAGE_LENGTH:
		var line := ColorRect.new()
		line.color = Color(0.30, 0.65, 0.95, 0.08)
		line.position = Vector2(x, -200.0)
		line.size = Vector2(1.5, 800.0)
		line.z_index = -10
		add_child(line)
		x += 90.0
	# 가로 데이터 라인 (천천히 흐르는 LED 효과)
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 167 + 31
	for i in 8:
		var bar := ColorRect.new()
		bar.color = Color(0.40, 0.85, 1.0, 0.35)
		bar.size = Vector2(40.0, 2.0)
		bar.position = Vector2(rng.randf_range(0.0, STAGE_LENGTH), rng.randf_range(-160.0, GROUND_Y - 60.0))
		bar.z_index = -5
		add_child(bar)
		var tw := bar.create_tween()
		tw.set_loops()
		tw.tween_property(bar, "position:x", bar.position.x + 80.0, rng.randf_range(1.5, 2.8))
		tw.tween_property(bar, "modulate:a", 0.0, 0.1)
		tw.tween_property(bar, "modulate:a", 0.35, 0.1)

func _ambience_escape() -> void:
	# 비상 탈출로 — 녹색 비상 표시등 + 옅은 안개. 톤 차분.
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_stage * 191 + 37
	var x: float = 400.0
	while x < STAGE_LENGTH:
		var sign := ColorRect.new()
		sign.color = Color(0.30, 0.85, 0.45, 0.55)
		sign.size = Vector2(18.0, 18.0)
		sign.position = Vector2(x - 9.0, GROUND_Y - 220.0)
		sign.z_index = -4
		add_child(sign)
		var tw := sign.create_tween()
		tw.set_loops()
		tw.tween_interval(rng.randf_range(2.0, 4.0))
		tw.tween_property(sign, "modulate:a", 0.3, 0.4)
		tw.tween_property(sign, "modulate:a", 1.0, 0.4)
		x += rng.randf_range(540.0, 800.0)
	var fog := ColorRect.new()
	fog.color = Color(0.20, 0.45, 0.30, 0.06)
	fog.position = Vector2(-200, GROUND_Y - 60.0)
	fog.size = Vector2(STAGE_LENGTH + 400.0, 80.0)
	fog.z_index = -3
	add_child(fog)

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
	# 세로 맵에서도 벽이 월드 전체 높이를 덮도록 height를 동적으로.
	var wall_height: float = _world_size.y + 400.0
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60.0, wall_height)
	col.shape = shape
	col.position = Vector2(x, _world_size.y * 0.5)
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
	player.damaged.connect(_on_player_damaged)
	player.revived.connect(_on_player_revived)

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2(1.0, 1.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	# camera_mode별 limits / parent 분기
	match _camera_mode:
		"HORIZONTAL":
			camera.limit_left = 0
			camera.limit_right = int(STAGE_LENGTH)
			camera.limit_top = -200
			camera.limit_bottom = int(GROUND_Y + 200.0)
			player.add_child(camera)
		"VERTICAL":
			camera.limit_left = 0
			camera.limit_right = int(_world_size.x)
			camera.limit_top = -200
			camera.limit_bottom = int(_world_size.y + 200.0)
			player.add_child(camera)
		"FIXED":
			# ARENA — 카메라 고정. zoom으로 월드 전체가 보이도록.
			camera.limit_left = 0
			camera.limit_right = int(_world_size.x)
			camera.limit_top = 0
			camera.limit_bottom = int(_world_size.y)
			camera.position_smoothing_enabled = false
			# 1280×720 viewport에 _world_size 전체가 맞게 zoom out.
			var zoom_fit: float = min(1280.0 / _world_size.x, 720.0 / _world_size.y)
			camera.zoom = Vector2(zoom_fit, zoom_fit)
			add_child(camera)
			camera.global_position = _world_size * 0.5
		_:
			# 폴백
			camera.limit_left = 0
			camera.limit_right = int(STAGE_LENGTH)
			camera.limit_top = -200
			camera.limit_bottom = int(GROUND_Y + 200.0)
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
	# anchor가 화면 하단(top=1.0)에 붙은 상태에서 콘텐츠가 위로 확장되도록 grow를 BEGIN으로.
	# (기본 END면 콘텐츠가 화면 아래로 빠져 게이지가 안 보임.)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
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
		# 티어에 따라 실제 max 쿨다운이 달라지므로 player의 helper를 통해 조회.
		_update_cd_slot(cd_attack_slot, float(player.get("attack_cd")), player.get_attack_cd_max())
		_update_cd_slot(cd_dash_slot, float(player.get("dash_cd")), player.get_dash_cd_max())
		_update_cd_slot(cd_skill_slot, float(player.get("skill_cd")), player.get_skill_cd_max())
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
	# MapData spawn guide 기반 — 각 적이 지형(분기/층)에 맞춰 미리 명시된 좌표에 배치된다.
	# 명세 없으면 폴백 (구 RNG 흩기 로직).
	var enemies: Dictionary = _map_data.get("enemies", {})
	if enemies.is_empty():
		_spawn_enemies_fallback()
		return
	var kind_map: Dictionary = {"patrol": 0, "sniper": 1, "drone": 2, "bomber": 3, "shield": 4}
	# Risk 배율 — 가이드 좌표 수에 비례해서 가감. risk=1=0.8, 2=1.1, 3=1.5.
	var mult: float = GameState.enemy_count_multiplier()
	for kind_name in enemies.keys():
		var positions: Array = enemies[kind_name]
		if positions.is_empty():
			continue
		var kind_int: int = int(kind_map.get(kind_name, 0))
		var target: int = int(round(float(positions.size()) * mult))
		target = clamp(target, 0, positions.size() * 2)
		# 가이드 좌표는 우선 다 spawn — sample 부족하면 일부 생략, 더 필요하면 중복 spawn(약간 오프셋).
		if target >= positions.size():
			for p in positions:
				_spawn_enemy(kind_int, p)
			var extra: int = target - positions.size()
			for i in extra:
				var base_p: Vector2 = positions[i % positions.size()]
				_spawn_enemy(kind_int, base_p + Vector2(randf_range(-120.0, 120.0), 0.0))
		else:
			# 줄여야 할 때는 앞쪽 좌표만 — 후반부 적이 빠지면 진행이 더 편해짐.
			for i in target:
				_spawn_enemy(kind_int, positions[i])

func _spawn_enemies_fallback() -> void:
	# MapData 명세가 없을 때 (디버그/플레이그라운드 등) 단순 흩기 폴백.
	var counts: Dictionary = {"patrol": 4, "sniper": 0, "drone": 0, "bomber": 0, "shield": 0}
	for i in counts["patrol"]:
		var x: float = lerp(400.0, STAGE_LENGTH - 300.0, float(i + 1) / float(counts["patrol"] + 1))
		_spawn_enemy(0, Vector2(x, GROUND_Y - 30.0))

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
	# ARENA enemy_clear 모드 — 카운트 감소 시 0이 되면 클리어 트리거
	if _goal_type == "ENEMY_CLEAR":
		_enemies_remaining -= 1
		if _enemies_remaining <= 0:
			call_deferred("_on_arena_cleared")

func _spawn_orb(pos: Vector2, static_placement: bool = false) -> void:
	# static_placement=true면 bounce 스킵 — 분기 보상으로 미리 배치된 orb는 그 자리에 그대로 둠.
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
	if static_placement:
		# bounce 스킵 — 즉시 attract 단계로
		orb.set("spawn_anim_t", 1.0)
		orb.set("bounce_velocity", Vector2.ZERO)

func _spawn_hp_orb(pos: Vector2) -> void:
	# 분기 보상으로 미리 배치된 HP 회복 픽업 (적 처치 드롭과 별개).
	var orb := Node2D.new()
	orb.set_script(load("res://scripts/HpOrb.gd"))
	# 빨간 십자 모양 — 멀리서도 HP 회복임을 인지할 수 있게.
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.color = Color(0.95, 0.30, 0.30, 0.0)
	sprite.size = Vector2.ZERO
	orb.add_child(sprite)
	# 십자 가로
	var bar_h := ColorRect.new()
	bar_h.color = Color(0.95, 0.30, 0.30)
	bar_h.position = Vector2(-9.0, -2.0)
	bar_h.size = Vector2(18.0, 4.0)
	orb.add_child(bar_h)
	# 십자 세로
	var bar_v := ColorRect.new()
	bar_v.color = Color(0.95, 0.30, 0.30)
	bar_v.position = Vector2(-2.0, -9.0)
	bar_v.size = Vector2(4.0, 18.0)
	orb.add_child(bar_v)
	# 옅은 후광 (시선 끌기용)
	var halo := ColorRect.new()
	halo.color = Color(0.95, 0.30, 0.30, 0.18)
	halo.position = Vector2(-12.0, -12.0)
	halo.size = Vector2(24.0, 24.0)
	halo.z_index = -1
	orb.add_child(halo)
	add_child(orb)
	orb.global_position = pos
	# 깜빡임 (시선 끌기)
	var tw := halo.create_tween()
	tw.set_loops()
	tw.tween_property(halo, "modulate:a", 0.4, 0.7)
	tw.tween_property(halo, "modulate:a", 1.0, 0.7)

func _build_rewards() -> void:
	# MapData에 명시된 분기 보상 (XP 다발 + HP 픽업)을 미리 배치.
	# 적 처치 드롭과 달리 bounce 없이 그 자리에 그대로 떠 있다 (분기 도달 보상이라 위치가 의미).
	var rewards: Dictionary = _map_data.get("rewards", {})
	for pos in rewards.get("xp_orbs", []):
		_spawn_orb(pos, true)
	for pos in rewards.get("hp_pickups", []):
		_spawn_hp_orb(pos)

var _enemies_remaining: int = 0  # ARENA enemy_clear 카운트

func _build_goal() -> void:
	match _goal_type:
		"POSITION":
			_build_goal_position()
		"ENEMY_CLEAR":
			_setup_arena_clear_tracking()
		"SEQUENCE":
			pass  # ??? 등 — 자체 종료 로직
		_:
			_build_goal_position()

func _build_goal_position() -> void:
	var goal := Area2D.new()
	goal.collision_layer = 0
	goal.collision_mask = 2
	# MapData에서 명시한 goal_pos 사용 (없으면 우측 끝 폴백)
	var pos: Vector2 = _goal_pos
	if pos == Vector2.ZERO:
		pos = Vector2(STAGE_LENGTH - 80.0, GROUND_Y - 60.0)
	goal.position = pos
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
	_trigger_stage_clear()

func _setup_arena_clear_tracking() -> void:
	# ARENA — _spawn_enemies가 끝난 시점이라 group에 등록된 적 수가 곧 카운트.
	_enemies_remaining = get_tree().get_nodes_in_group("enemy").size()
	if _enemies_remaining <= 0:
		# 적 없는 ARENA (이상 케이스) — 즉시 클리어
		call_deferred("_on_arena_cleared")

func _on_arena_cleared() -> void:
	if goal_reached:
		return
	goal_reached = true
	# ARENA 클리어 보너스 XP — MapData arena_clear_xp
	var data: Dictionary = MapData.get_layout(GameState.current_route_id)
	var bonus_xp: int = int(data.get("arena_clear_xp", 0))
	if bonus_xp > 0:
		GameState.add_xp(bonus_xp, false)
	_trigger_stage_clear()

func _trigger_stage_clear() -> void:
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

func _on_player_damaged() -> void:
	# 피격 — 화면 가장자리 짧은 붉은 플래시 + 가벼운 카메라 흔들림
	_screen_flash(Color(1.0, 0.18, 0.22, 0.55), 0.06, 0.32)
	_camera_shake(6.0, 0.18)

func _on_player_revived() -> void:
	# 부활 — 강한 흰 플래시 (전체 화면이 잠깐 밝아짐)
	_screen_flash(Color(1.0, 1.0, 1.15, 0.85), 0.05, 0.5)

func _screen_flash(col: Color, fade_in: float, fade_out: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 35
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(col.r, col.g, col.b, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	var tw := rect.create_tween()
	tw.tween_property(rect, "color:a", col.a, fade_in)
	tw.tween_property(rect, "color:a", 0.0, fade_out)
	tw.tween_callback(layer.queue_free)

func _camera_shake(magnitude: float, duration: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var origin: Vector2 = camera.offset
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var elapsed: float = 0.0
	var steps: int = 6
	for i in steps:
		var t: float = float(i) / float(steps)
		var falloff: float = 1.0 - t
		var ox: float = rng.randf_range(-magnitude, magnitude) * falloff
		var oy: float = rng.randf_range(-magnitude, magnitude) * falloff
		camera.offset = origin + Vector2(ox, oy)
		await get_tree().create_timer(duration / float(steps)).timeout
		if not is_instance_valid(camera):
			return
	camera.offset = origin

func _process(delta: float) -> void:
	_refresh_hud()
	_tick_arcturus(delta)

# ─── ARCTURUS 아카이브 5초 hold 로직 ───
func _tick_arcturus(delta: float) -> void:
	if arcturus_state != "holding":
		return
	if not arcturus_player_inside:
		return
	arcturus_hold_t += delta
	_update_arcturus_indicator()
	if arcturus_hold_t >= arcturus_hold_target:
		arcturus_state = "sequencing"
		_start_arcturus_sequence()

func _update_arcturus_indicator() -> void:
	if arcturus_indicator == null or not is_instance_valid(arcturus_indicator):
		return
	var ratio: float = clamp(arcturus_hold_t / arcturus_hold_target, 0.0, 1.0)
	arcturus_indicator.size.x = 60.0 * ratio
	arcturus_indicator.color.a = 0.85 if ratio > 0.0 else 0.0

# 5초 hold 완료 — 페이드 오버레이 + ArchiveOverlay로 3 단말기 + VEIL outro 시퀀스 재생.
# 시퀀스 동안 플레이어 입력 잠금. 끝나면 보너스 XP +3 + trust +1, ward 진행 계속.
func _start_arcturus_sequence() -> void:
	GameState.restrict_combat_input = true
	# 잠금 LED → 따뜻한 색으로 전환 (문 열림 시그널)
	var fade_layer := CanvasLayer.new()
	fade_layer.name = "ArcturusFade"
	fade_layer.layer = 18
	add_child(fade_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(dim)
	var fade_in := dim.create_tween()
	fade_in.tween_property(dim, "color:a", 0.85, 0.8)
	fade_in.tween_callback(_play_arcturus_lines)

func _play_arcturus_lines() -> void:
	# ArchiveOverlay가 ward에는 없음 — 여기서 lazy 생성.
	var arch := get_node_or_null("ArchiveOverlay") as ArchiveOverlay
	if arch == null:
		arch = ArchiveOverlay.new()
		arch.name = "ArchiveOverlay"
		add_child(arch)
	if not arch.finished.is_connected(_on_arcturus_lines_done):
		arch.finished.connect(_on_arcturus_lines_done)
	# 3 단말기 + VEIL outro 한 번에 (DESIGN §3.1 본문 그대로).
	var lines: Array = []
	lines.append_array(_arcturus_term_a())
	lines.append_array(_arcturus_term_b())
	lines.append_array(_arcturus_term_c())
	lines.append_array(_arcturus_veil_outro())
	arch.play(lines)

func _on_arcturus_lines_done() -> void:
	if arcturus_state == "done":
		return
	arcturus_state = "done"
	# 보상 — XP +3 (1회), trust +1, 영구 visited 플래그.
	GameState.add_xp(3, false)
	GameState.trust_score += 1
	GameState.visited_arcturus = true
	GameState.save_settings()
	# 페이드 아웃 → 입력 복구
	var fade_layer := get_node_or_null("ArcturusFade") as CanvasLayer
	if fade_layer != null:
		var dim := fade_layer.get_child(0) as ColorRect
		if dim != null:
			var tw := dim.create_tween()
			tw.tween_property(dim, "color:a", 0.0, 0.7)
			tw.tween_callback(fade_layer.queue_free)
	GameState.restrict_combat_input = false
	# 게이지 사라짐
	if arcturus_indicator != null and is_instance_valid(arcturus_indicator):
		arcturus_indicator.queue_free()
		arcturus_indicator = null

# 단말기 A — 신입 직원 온보딩 문서
func _arcturus_term_a() -> Array:
	return [
		{"speaker": "[A] 인사팀", "text": "ARCTURUS에 오신 것을 환영합니다.", "delay": 2.0},
		{"speaker": "[A] 인사팀", "text": "본사는 공식적으로 존재하지 않습니다.", "delay": 2.5},
		{"speaker": "[A] 인사팀", "text": "모든 임무는 기록되지 않습니다.", "delay": 2.5},
		{"speaker": "[A] 인사팀", "text": "질문하지 마세요. 결과만 내세요.", "delay": 2.5},
		{"speaker": "[A] 인사팀", "text": "— 인사팀 (인사팀도 공식적으로 존재하지 않습니다)", "delay": 2.0},
	]

# 단말기 B — VEIL 프로젝트 초기 회의록
func _arcturus_term_b() -> Array:
	return [
		{"speaker": "[B] 회의록", "text": "참석자: [REDACTED], [REDACTED], [REDACTED]", "delay": 2.2},
		{"speaker": "[B] 회의록", "text": "주제: VEIL 감정 모듈 탑재 여부", "delay": 2.5},
		{"speaker": "[B] 회의록", "text": "결론: 탑재 보류. 불필요한 복잡성.", "delay": 2.5},
		{"speaker": "[B] 회의록", "text": "비고: VEIL-2가 감정 모듈 없이도 이상 반응을 보인 것에 대해", "delay": 2.5},
		{"speaker": "[B] 회의록", "text": "        추가 조사 예정.", "delay": 2.0},
		{"speaker": "[B] 회의록", "text": "— [REDACTED]", "delay": 1.8},
	]

# 단말기 C — 요원 평가 내부 메모 (이번 임무)
func _arcturus_term_c() -> Array:
	return [
		{"speaker": "[C] 감시팀", "text": "요원 코드: [REDACTED]", "delay": 1.8},
		{"speaker": "[C] 감시팀", "text": "임무: PALIMPSEST", "delay": 2.0},
		{"speaker": "[C] 감시팀", "text": "현재 상태: 진행 중", "delay": 2.0},
		{"speaker": "[C] 감시팀", "text": "VEIL과의 협조도: [측정 중]", "delay": 2.5},
		{"speaker": "[C] 감시팀", "text": "비고: 요원이 이 문서를 읽고 있다면", "delay": 2.5},
		{"speaker": "[C] 감시팀", "text": "        이미 임무 범위를 벗어난 것임.", "delay": 2.5},
		{"speaker": "[C] 감시팀", "text": "— 감시팀", "delay": 1.8},
	]

func _arcturus_veil_outro() -> Array:
	return [
		{"speaker": "VEIL", "text": "여기까지 왔군요.", "delay": 2.5},
		{"speaker": "VEIL", "text": "...", "delay": 1.5},
		{"speaker": "VEIL", "text": "저도 이 파일들 읽은 적 있어요.", "delay": 2.8},
		{"speaker": "VEIL", "text": "...", "delay": 1.5},
		{"speaker": "VEIL", "text": "계속 가요, 요원.", "delay": 2.5},
	]

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
