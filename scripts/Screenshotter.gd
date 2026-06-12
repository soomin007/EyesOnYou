extends Node

# 포스터용 실제 게임 스크린샷 캡처 하니스. 각 라우트에 대해 GameState를 게임과 동일하게
# 세팅(record_route_choice)하고 Stage 씬을 자식으로 인스턴스화해 빌드시킨 뒤, 몇 프레임 정착시키고
# 메인 뷰포트를 PNG로 저장한다. 도감 첫 조우 카드가 화면을 가리지 않게 seen_enemies를 미리 채운다.
# 실행: godot --path . --resolution 1280x720 res://scenes/screenshotter.tscn --gen

const STAGE_SCENE: String = "res://scenes/stage.tscn"
const OUT_DIR: String = "res://poster_out/shots"

# (route_id, stage_index) — 시각적으로 다른 맵을 고름.
const TARGETS: Array = [
	["route_rooftops", 0],
	["route_watchtower", 2],
	["route_subway", 2],
	["route_datacenter", 4],
]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_run.call_deferred()

func _run() -> void:
	for entry in TARGETS:
		var pair: Array = entry
		await _capture(str(pair[0]), int(pair[1]))
	print("SHOTS DONE")
	if "--gen" in OS.get_cmdline_args():
		await get_tree().create_timer(0.2).timeout
		get_tree().quit()

func _capture(rid: String, stage_idx: int) -> void:
	GameState.start_main_game()
	GameState.current_stage = stage_idx
	GameState.seen_enemies = ["patrol", "sniper", "drone", "bomber", "shield"]
	var route: Dictionary = _find_route(rid)
	if route.is_empty():
		print("SHOT SKIP (no route): ", rid)
		return
	GameState.record_route_choice(route, "")

	var packed: PackedScene = load(STAGE_SCENE) as PackedScene
	if packed == null:
		print("SHOT SKIP (no scene): ", rid)
		return
	var stage: Node = packed.instantiate()
	add_child(stage)

	# 빌드 + 카메라 정착 + 적 한두 틱 — 충분히 대기.
	var f: int = 0
	while f < 40:
		await get_tree().process_frame
		f += 1
	await RenderingServer.frame_post_draw
	await get_tree().process_frame

	var tex: Texture2D = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path: String = OUT_DIR + "/shot_" + rid + ".png"
			img.save_png(path)
			print("SHOT SAVED: ", ProjectSettings.globalize_path(path))
	stage.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _find_route(rid: String) -> Dictionary:
	for r in RouteData.ALL_ROUTES:
		var rd: Dictionary = r
		if str(rd.get("id", "")) == rid:
			return rd
	return {}
