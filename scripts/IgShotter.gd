extends Node

# 인스타 홍보용 임팩트 스크린샷 캡처 하니스 (포스터용 Screenshotter와 별개).
#  - 1920x1080 borderless 창에 메인 뷰포트를 직접 캡처 → canvas_items stretch가 월드+HUD를
#    균일 1.5배로 선명하게 렌더(창 장식 손실 없음, 모니터 1920x1080에 딱 맞음).
#  - "가만히 선 평범한 순간"이 아니라 교전/경고/맵 개성/시스템 화면을 연출해 담는다.
# 실행: Godot_..._console.exe --path . res://scenes/ig_shotter.tscn --gen
#  (--gen 없으면 캡처만 하고 창을 닫지 않음 — 수동 확인용)

const STAGE_SCENE: String = "res://scenes/stage.tscn"
const OUT_DIR: String = "res://poster_out/ig"

const SHOT_W: int = 1920
const SHOT_H: int = 1080

# kind 코드 (Stage._spawn_enemy 기준)
const K_PATROL: int = 0
const K_SNIPER: int = 1
const K_DRONE: int = 2
const K_BOMBER: int = 3
const K_SHIELD: int = 4

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_set_high_res()
	_run.call_deferred()

func _set_high_res() -> void:
	# 창 장식 없이 정확히 1920x1080 — get_viewport().get_texture()가 그 크기로 나온다.
	var win: Window = get_window()
	win.mode = Window.MODE_WINDOWED
	win.borderless = true
	# content_scale를 설계 기준(1280x720)으로 고정 → 월드/HUD가 1.5배 균일 확대(선명),
	# 카메라는 설계와 동일한 프레이밍을 유지(런타임 리사이즈로 풀리던 것 명시 고정).
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_size = Vector2i(1280, 720)
	win.size = Vector2i(SHOT_W, SHOT_H)
	win.position = Vector2i(0, 0)

func _run() -> void:
	# 창 리사이즈가 뷰포트에 반영될 시간.
	await _wait(8)

	# 1) 교전 액션 — 커버 후보 둘 (클로즈업 + 와이드 아레나).
	await _shot_combat_close()
	await _shot_combat_arena()
	# 2) VEIL 경고 순간.
	await _shot_veil_warning()
	# 3) 4개 맵 극적 컷.
	await _shot_map_rooftops()
	await _shot_map_subway()
	await _shot_map_datacenter()
	await _shot_map_watchtower()
	# 4) 루트 분기 + 5) 스킬트리 + (선택) 보스.
	await _shot_route_fork()
	await _shot_skilltree()
	await _shot_boss()

	print("IG SHOTS DONE")
	if "--gen" in OS.get_cmdline_args():
		await get_tree().create_timer(0.3).timeout
		get_tree().quit()

# ─── 공통 셋업 ────────────────────────────────────────────────

func _new_game(stage_idx: int, skills: Dictionary, story: bool = false) -> void:
	GameState.start_main_game()
	GameState.story_mode = story
	GameState.current_stage = stage_idx
	# 첫 조우 도감 카드가 화면을 가리지 않게 미리 본 것으로.
	GameState.seen_enemies = ["patrol", "sniper", "drone", "bomber", "shield"]
	for k in skills.keys():
		GameState.skills[k] = int(skills[k])

func _load_stage(rid: String, stage_idx: int, skills: Dictionary, story: bool = false) -> Node:
	_new_game(stage_idx, skills, story)
	var route: Dictionary = _find_route(rid)
	if route.is_empty():
		print("IG SKIP (no route): ", rid)
		return null
	GameState.record_route_choice(route, "")
	var packed: PackedScene = load(STAGE_SCENE) as PackedScene
	if packed == null:
		return null
	var stage: Node = packed.instantiate()
	add_child(stage)
	await _wait(30)  # 빌드 + 카메라 정착
	return stage

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _enemies() -> Array:
	return get_tree().get_nodes_in_group("enemy")

# 플레이어를 옮기고 카메라(자식)를 즉시 스냅. 정적 컷용.
func _place_player(stage: Node, pos: Vector2, facing: int = 1) -> void:
	var p: Node2D = _player()
	if p == null:
		return
	p.set("facing", facing)
	p.set("velocity", Vector2.ZERO)
	p.set("invuln", 999.0)  # 피격 깜빡임 방지
	p.global_position = pos
	p.reset_physics_interpolation()
	var cam: Camera2D = stage.get("camera")
	if cam != null and is_instance_valid(cam):
		cam.position_smoothing_enabled = false
		cam.reset_smoothing()
		cam.reset_physics_interpolation()
	await _wait(8)  # 발판에 안착

# 카메라 줌인(클로즈업) + 시선 오프셋 — HORIZONTAL/VERTICAL(플레이어 자식) 카메라용.
# 줌>1 = 확대(월드 적게 보임 → 캐릭터 큼). 오프셋은 월드 단위로 시선 중심을 옮긴다.
func _frame_cam(stage: Node, zoom: float, offset: Vector2 = Vector2.ZERO) -> void:
	var cam: Camera2D = stage.get("camera")
	if cam == null or not is_instance_valid(cam):
		return
	cam.zoom = Vector2(zoom, zoom)
	cam.offset = offset
	cam.position_smoothing_enabled = false
	cam.reset_smoothing()
	cam.reset_physics_interpolation()

# 화면에 떠 있는 모든 자막을 비운다(겹침 정리).
func _purge_subs(stage: Node) -> void:
	stage.call("_purge_subtitles")

# 모든 적의 AI를 멈춰 포즈 고정(정적 컷). 조준선 등 기존 상태는 유지된다.
func _freeze_enemies() -> void:
	for e in _enemies():
		if is_instance_valid(e):
			(e as Node).set_physics_process(false)
			(e as Node).set_process(false)

# 저격수를 조준 상태로 고정 — 붉은 조준선 + VeilSight 주황 경고 마커를 만든다.
func _force_aim(sniper: Node) -> void:
	if sniper == null or not is_instance_valid(sniper):
		return
	sniper.set("aim_los_clear", true)
	sniper.call("_start_aim")
	sniper.call("_update_aim")
	sniper.set_physics_process(false)  # 다음 틱에 _clear_aim 되지 않게 고정

# 폭발 섬광 — Bomb의 blast를 모사(데미지/큐프리 없이 한 프레임 연출용).
func _spawn_blast(stage: Node, pos: Vector2, radius: float, scl: float = 0.75) -> void:
	var blast := Polygon2D.new()
	blast.color = Color(0.98, 0.6, 0.28, 0.9)
	blast.z_index = 6
	var pts: Array = []
	for i in 24:
		var a: float = float(i) * TAU / 24.0
		pts.append(Vector2(cos(a) * radius, sin(a) * radius))
	blast.polygon = PackedVector2Array(pts)
	blast.global_position = pos
	blast.scale = Vector2(scl, scl)
	stage.add_child(blast)
	# 흰 코어 — 폭심 강조.
	var core := Polygon2D.new()
	core.color = Color(1.0, 0.95, 0.8, 0.95)
	var cpts: Array = []
	for i in 16:
		var a: float = float(i) * TAU / 16.0
		cpts.append(Vector2(cos(a) * radius * 0.45, sin(a) * radius * 0.45))
	core.polygon = PackedVector2Array(cpts)
	core.global_position = pos
	core.scale = Vector2(scl, scl)
	core.z_index = 7
	stage.add_child(core)

# 머즐 글로우 — 작은 기본 머즐 플래시를 보강.
func _spawn_muzzle_glow(stage: Node, pos: Vector2) -> void:
	var g := Polygon2D.new()
	g.color = Color(1.0, 0.9, 0.5, 0.85)
	var pts: Array = []
	for i in 12:
		var a: float = float(i) * TAU / 12.0
		var r: float = 22.0 if (i % 2 == 0) else 9.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	g.polygon = PackedVector2Array(pts)
	g.global_position = pos
	g.z_index = 6
	stage.add_child(g)

# ─── 1. 교전 액션 (클로즈업 — 큰 캐릭터) ──────────────────────
func _shot_combat_close() -> void:
	var stage: Node = await _load_stage("route_subway", 3, {"multishot": 2, "fire_boost": 3})
	if stage == null:
		return
	# 플레이어 앞에 적 무리 — 패트롤 둘 + 방패병 + 지붕 저격수. 클로즈업이라 무리를 밀착.
	var px: float = 1900.0
	var gy: float = 420.0
	_place_player(stage, Vector2(px, gy - 2.0), 1)
	stage.call("_spawn_enemy", K_PATROL, Vector2(px + 150.0, gy))
	stage.call("_spawn_enemy", K_PATROL, Vector2(px + 270.0, gy))
	stage.call("_spawn_enemy", K_SHIELD, Vector2(px + 380.0, gy))
	stage.call("_spawn_enemy", K_SNIPER, Vector2(px + 230.0, 200.0))
	# 카메라 — 줌인 + 무리 쪽으로 시선 이동. 깨끗한 액션 컷(자막 제거).
	_frame_cam(stage, 1.7, Vector2(190.0, -36.0))
	await _wait(10)
	_purge_subs(stage)
	var p: Node2D = _player()
	# 부채꼴 사격 두 번 — 탄이 두 거리대에 흩어지게.
	p.call("_try_attack")
	_spawn_muzzle_glow(stage, p.global_position + Vector2(34.0, -34.0))
	await _wait(6)
	p.call("_try_attack")
	_spawn_muzzle_glow(stage, p.global_position + Vector2(34.0, -34.0))
	# 폭발 — 적 무리 한가운데.
	_spawn_blast(stage, Vector2(px + 240.0, gy - 26.0), 56.0, 0.85)
	await _wait(3)
	await _capture("combat_hero", stage)

# ─── 1b. 교전 액션 (와이드 아레나 — 여러 명) ──────────────────
func _shot_combat_arena() -> void:
	var stage: Node = await _load_stage("route_datacenter", 4, {"multishot": 2, "fire_boost": 1})
	if stage == null:
		return
	# 모든 웨이브 강제 spawn — 아레나를 가득 채운다(드론·저격·방패·폭격기·패트롤).
	stage.call("_spawn_wave", 1)
	stage.call("_spawn_wave", 2)
	await _wait(14)
	_purge_subs(stage)  # 진입/웨이브 자막 정리 — 액션만.
	# 플레이어를 서버 랙 위 중앙에 두고 사격.
	var p: Node2D = _player()
	p.set("invuln", 999.0)
	p.set("facing", 1)
	p.global_position = Vector2(640.0, 760.0)
	p.reset_physics_interpolation()
	await _wait(8)
	p.call("_try_attack")
	_spawn_muzzle_glow(stage, p.global_position + Vector2(30.0, -30.0))
	await _wait(5)
	# 적 밀집 지점 두 곳에 폭발.
	_spawn_blast(stage, Vector2(1200.0, 760.0), 58.0, 0.8)
	_spawn_blast(stage, Vector2(960.0, 200.0), 46.0, 0.7)
	await _wait(3)
	await _capture("combat_arena", stage)

# ─── 2. VEIL 경고 순간 ───────────────────────────────────────
func _shot_veil_warning() -> void:
	var stage: Node = await _load_stage("route_subway", 3, {})
	if stage == null:
		return
	GameState.trust_score = 12  # 따뜻한 어투("해요")로 자막이 읽히게
	var px: float = 1320.0
	var gy: float = 420.0
	_place_player(stage, Vector2(px, gy - 2.0), 1)
	# 지붕 위 저격수 — 조준선이 플레이어를 향하게 강제. 하나만 둬 깔끔하게.
	stage.call("_spawn_enemy", K_SNIPER, Vector2(px + 210.0, 200.0))
	_frame_cam(stage, 1.7, Vector2(120.0, -56.0))
	await _wait(8)
	for e in _enemies():
		if int(e.get("enemy_type")) == K_SNIPER:
			_force_aim(e)
	# 진입 멘트 등 기존 자막을 비우고 VEIL 경고 한 줄만 — "위협 등장 + 경고" 순간.
	_purge_subs(stage)
	await _wait(2)
	stage.call("_show_veil_subtitle", "위, 저격이에요. 제가 표시해 둘게요 — 요원은 앞만 봐요.", 6.0, false, true)
	await _wait(12)
	await _capture("veil_warning_sniper", stage)

# ─── 3a. 외벽 옥상 — 하늘/별 + 높이 + 저격 감시선 ─────────────
func _shot_map_rooftops() -> void:
	var stage: Node = await _load_stage("route_rooftops", 0, {})
	if stage == null:
		return
	# 최상층 옥상 슬랩(620,280) 위 — 위로 별 깔린 밤하늘, 트인 옥상 가장자리에 선 요원.
	_place_player(stage, Vector2(620.0, 250.0), 1)
	# 아래 발판에 저격수 한 명 — 조준선이 위로 그어져 "트인 저격 감시선".
	stage.call("_spawn_enemy", K_SNIPER, Vector2(470.0, 390.0))
	# 하늘이 위에 더 보이게 시선을 살짝 아래로(저격수까지 포함).
	_frame_cam(stage, 1.35, Vector2(0.0, 70.0))
	await _wait(8)
	_freeze_enemies()
	for e in _enemies():
		if int(e.get("enemy_type")) == K_SNIPER:
			_force_aim(e)
	_purge_subs(stage)  # 진입/회피 자막 겹침 정리 — 깨끗한 맵 컷.
	await _wait(4)
	await _capture("map_rooftops", stage)

# ─── 3b. 폐쇄 지하철 — 어두운 터널 + 하향 포탑 + 형광등 ───────
func _shot_map_subway() -> void:
	var stage: Node = await _load_stage("route_subway", 3, {})
	if stage == null:
		return
	# 트립와이어/하향 포탑 구간(x≈1550~1780). 좁은 천장과 포탑 텔레그래프.
	_place_player(stage, Vector2(1560.0, 418.0), 1)
	stage.call("_spawn_enemy", K_PATROL, Vector2(1740.0, 420.0))
	_frame_cam(stage, 1.5, Vector2(70.0, -70.0))  # 머리 위 하향 포탑이 보이게 시선 위로
	await _wait(6)
	_freeze_enemies()
	_purge_subs(stage)
	await _wait(4)
	await _capture("map_subway", stage)

# ─── 3c. 데이터 센터 — 드론(위) + 저격(같은 층) 동시 고위험 ───
func _shot_map_datacenter() -> void:
	var stage: Node = await _load_stage("route_datacenter", 4, {})
	if stage == null:
		return
	# 웨이브 2 = 저격 둘 + 드론 하나. 깨끗한 위협 레이어링(폭격기 없이).
	stage.call("_spawn_wave", 1)
	await _wait(12)
	# 플레이어를 서버 랙 사이에 두고 정지.
	var p: Node2D = _player()
	p.set("invuln", 999.0)
	p.global_position = Vector2(500.0, 760.0)
	p.reset_physics_interpolation()
	await _wait(8)
	for e in _enemies():
		if int(e.get("enemy_type")) == K_SNIPER:
			_force_aim(e)
	_freeze_enemies()
	_purge_subs(stage)
	await _wait(4)
	await _capture("map_datacenter", stage)

# ─── 3d. 감시탑 — 붉은 스캔라인 + 둥지 저격 감시선 ────────────
func _shot_map_watchtower() -> void:
	var stage: Node = await _load_stage("route_watchtower", 2, {})
	if stage == null:
		return
	# 중층 정찰단 발판(660,1180) — 좌측 둥지 저격수(120,1172)가 가로질러 내려다봄.
	_place_player(stage, Vector2(620.0, 1148.0), -1)
	_frame_cam(stage, 1.35, Vector2(-150.0, 0.0))  # 좌측 둥지 저격수까지 시선 이동
	await _wait(6)
	_freeze_enemies()
	for e in _enemies():
		if int(e.get("enemy_type")) == K_SNIPER:
			_force_aim(e)
	_purge_subs(stage)
	await _wait(4)
	await _capture("map_watchtower", stage)

# ─── 4. 루트 분기 — 스토리 stage1 (지하철 vs 감시탑, 위험 대비) ─
func _shot_route_fork() -> void:
	_new_game(1, {}, true)  # story_mode=true → stage1 = [지하철, 감시탑] 2갈래
	var packed: PackedScene = load("res://scenes/route_map.tscn") as PackedScene
	if packed == null:
		return
	var rm: Node = packed.instantiate()
	add_child(rm)
	await _wait(44)
	await _capture("route_fork", rm)

# ─── 5. 스킬트리 — 진행된 빌드(빛나는 노드 + 연결선) ──────────
func _shot_skilltree() -> void:
	_new_game(3, {
		"fire_boost": 2, "multishot": 2, "glide": 2,
		"dash_boost": 1, "hp": 1, "shield": 1,
	})
	var o: Node = SkillTreeOverlay.open(self)
	await _wait(26)
	await _capture("skilltree", o)

# ─── (선택) 보스 — 핵심부 SENTINEL ──────────────────────────
func _shot_boss() -> void:
	var stage: Node = await _load_stage("route_lab", 5, {"multishot": 1})
	if stage == null:
		return
	await _wait(12)
	var p: Node2D = _player()
	p.set("invuln", 999.0)
	p.set("facing", 1)
	p.global_position = Vector2(620.0, 560.0)
	p.reset_physics_interpolation()
	var cam: Camera2D = stage.get("camera")
	if cam != null and is_instance_valid(cam):
		cam.reset_smoothing()
	await _wait(8)
	p.call("_try_attack")
	_spawn_muzzle_glow(stage, p.global_position + Vector2(30.0, -30.0))
	await _wait(4)
	await _capture("boss_sentinel", stage)

# ─── 캡처/유틸 ────────────────────────────────────────────────

func _capture(shot_name: String, node: Node) -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var tex: Texture2D = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path: String = OUT_DIR + "/" + shot_name + ".png"
			img.save_png(path)
			print("IG SAVED: ", ProjectSettings.globalize_path(path), "  ", img.get_width(), "x", img.get_height())
	if is_instance_valid(node):
		node.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _wait(frames: int) -> void:
	var i: int = 0
	while i < frames:
		await get_tree().process_frame
		i += 1

func _find_route(rid: String) -> Dictionary:
	for r in RouteData.ALL_ROUTES:
		var rd: Dictionary = r
		if str(rd.get("id", "")) == rid:
			return rd
	return {}
