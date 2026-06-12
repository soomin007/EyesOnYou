extends Control

# 포스터 렌더 하니스 — PosterCanvas를 정확한 포스터 해상도의 SubViewport에 담아 그리고,
# 화면엔 창 비율에 맞춰 미리보기를 띄우며, PNG로 캡처해 저장한다.
# 생성 전용 실행: godot --path . res://scenes/poster.tscn --gen  → 저장 후 자동 종료.
# 일반 실행: S=다시 저장, ESC=종료(미리보기 확인용).

const PW: int = 1240
const PH: int = 1754
const OUT_PATH: String = "res://poster_out/eyes_on_you_poster.png"

var _sv: SubViewport
var _canvas: PosterCanvas

func _ready() -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(PW, PH)
	_sv.disable_3d = true
	_sv.transparent_bg = false
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)

	_canvas = PosterCanvas.new()
	_sv.add_child(_canvas)

	var tr: TextureRect = TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.texture = _sv.get_texture()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)

	_capture_when_ready.call_deferred()

func _capture_when_ready() -> void:
	# SubViewport이 실제로 그려질 때까지 몇 프레임 대기 후 캡처.
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	_save()

func _save() -> void:
	DirAccess.make_dir_recursive_absolute("res://poster_out")
	var tex: Texture2D = _sv.get_texture()
	if tex == null:
		print("POSTER: null texture")
		return
	var img: Image = tex.get_image()
	if img == null:
		print("POSTER: null image")
		return
	var err: int = img.save_png(OUT_PATH)
	var abs_path: String = ProjectSettings.globalize_path(OUT_PATH)
	if err == OK:
		print("POSTER SAVED: ", abs_path)
	else:
		print("POSTER SAVE FAILED err=", err, " path=", abs_path)
	if "--gen" in OS.get_cmdline_args():
		await get_tree().create_timer(0.2).timeout
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k: InputEventKey = event as InputEventKey
		if k.keycode == KEY_S:
			_save()
		elif k.keycode == KEY_ESCAPE:
			get_tree().quit()
