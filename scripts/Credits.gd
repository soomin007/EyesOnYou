extends Control

# 크레딧 화면. 두 가지 모드 지원:
#   - standalone scene (game ending → credits → title)
#       set_meta("mode", "scene") 또는 기본값. 끝나면 Title로 이동.
#   - overlay (Settings에서 "크레딧 보기" → 그 자리에서 닫기)
#       open_as_overlay()로 진입. closed signal로 닫힘 알림.
#
# 본 화면은 단순 자동 스크롤 + ESC/뒤로 / SPACE / 클릭으로 종료.

signal closed

# 크레딧 본문. ANNOTATIONS:
#  · [HEADER]   : 큰 글자 (섹션 헤더)
#  · [SUB]      : 회색 작은 글자 (보조)
#  · 빈 줄      : 간격
#  · 그 외      : 본문 18pt
# 마무리에 "감사합니다" 큰 글자 + 페이드.
const CREDITS_LINES: Array[String] = [
	"[HEADER]EYES ON YOU",
	"[SUB]VEIL과 함께하는 임무",
	"",
	"",
	"[HEADER]Direction & Code",
	"soomin007",
	"",
	"",
	"[HEADER]VEIL",
	"문장 · 흐름 · 신뢰도 톤",
	"",
	"",
	"[HEADER]Music",
	"Glass Protocol — 메인 테마",
	"Cold Gear — 외곽 / 외벽",
	"Cold Wire — 시설 내부",
	"Chrome Grit — SENTINEL",
	"Gravity Static — ???",
	"[SUB]All tracks generated with Suno",
	"",
	"",
	"[HEADER]Engine",
	"Godot 4.6",
	"[SUB]GL Compatibility · Web Export",
	"",
	"",
	"[HEADER]Font",
	"Pretendard",
	"",
	"",
	"[HEADER]With thanks to",
	"부스에 들렀던 모든 플레이어",
	"끝까지 따라와 준 당신",
	"",
	"",
	"",
	"[BIG]감사합니다",
	"",
	"",
	"[SUB]— END —",
]

const SCROLL_SPEED: float = 36.0   # px / sec
const SCROLL_FAST_MULT: float = 4.0  # SPACE 누르고 있으면 빨리 감기
const TOP_GAP: float = 720.0
const BOTTOM_GAP: float = 240.0

var _is_overlay: bool = false
var _scroll: VBoxContainer
var _scroll_y: float = 0.0
var _content_height: float = 0.0
var _finished: bool = false
var _hint_label: Label
# 진입 직후 입력 lockout — 게임 종료 후 점프 연타가 즉시 크레딧을 닫는 사고 방지.
var _input_lockout_t: float = GameState.INPUT_LOCKOUT_DURATION

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# 어두운 배경. 오버레이 모드에선 dim, scene 모드에선 솔리드.
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.05, 1.0) if not _is_overlay else Color(0, 0, 0, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# 스크롤 컨테이너 — 자식들을 위에서 아래로 쌓고 _scroll_y 만큼 위로 밀어 올림.
	# anchor_preset 없이 절대 좌표만 — VBox는 자식이 추가되며 자동으로 세로로 자란다.
	_scroll = VBoxContainer.new()
	_scroll.add_theme_constant_override("separation", 6)
	_scroll.position = Vector2(0, TOP_GAP)
	_scroll.size = Vector2(1280, 0)
	_scroll.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_scroll)
	_build_lines()
	# 안내 — 우하단. ESC/뒤로 = 즉시 종료, SPACE 길게 = 빨리 감기 (overlay/scene 동일).
	_hint_label = Label.new()
	_hint_label.text = _hint_text()
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	_hint_label.position = Vector2(960, 686)
	_hint_label.size = Vector2(300, 18)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hint_label)
	GameState.input_kind_changed.connect(_on_input_kind_changed)
	# scene 모드 진입에서도 main_theme이 부드럽게 이어지도록 (이미 같은 트랙이면 무시됨).
	BgmPlayer.play("main_theme")

func _on_input_kind_changed(_kind: String) -> void:
	if is_instance_valid(_hint_label):
		_hint_label.text = _hint_text()

func _hint_text() -> String:
	return GameState.hint(
		"SPACE 빨리 감기 · ESC 닫기",
		"A 빨리 감기 · B 닫기")

func _build_lines() -> void:
	for raw in CREDITS_LINES:
		var line: String = raw
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if line.begins_with("[HEADER]"):
			l.text = line.substr("[HEADER]".length())
			l.add_theme_font_size_override("font_size", 26)
			l.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		elif line.begins_with("[SUB]"):
			l.text = line.substr("[SUB]".length())
			l.add_theme_font_size_override("font_size", 14)
			l.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
		elif line.begins_with("[BIG]"):
			l.text = line.substr("[BIG]".length())
			l.add_theme_font_size_override("font_size", 36)
			l.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		elif line.is_empty():
			l.custom_minimum_size = Vector2(0, 14)
		else:
			l.text = line
			l.add_theme_font_size_override("font_size", 18)
			l.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
		_scroll.add_child(l)
	# 컨테이너의 정확한 높이는 layout 후에야 계산됨. 다음 프레임에 측정.
	call_deferred("_measure_content")

func _measure_content() -> void:
	_content_height = _scroll.size.y

func _process(delta: float) -> void:
	if _input_lockout_t > 0.0:
		_input_lockout_t -= delta
	if _finished:
		return
	var speed: float = SCROLL_SPEED
	if Input.is_action_pressed("ui_skip") or Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept"):
		speed *= SCROLL_FAST_MULT
	_scroll_y += speed * delta
	_scroll.position.y = TOP_GAP - _scroll_y
	# 끝까지 다 올라갔으면 자동 종료.
	if _content_height > 0.0 and _scroll_y >= _content_height + BOTTOM_GAP:
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	if _input_lockout_t > 0.0:
		return
	if event.is_action_pressed("ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _is_overlay:
		emit_signal("closed")
		return
	# scene 모드 — 타이틀로.
	GameState.reset()
	get_tree().change_scene_to_file(SceneRouter.TITLE)

# Settings에서 호출. closed 시그널을 듣고 부모가 free하면 됨.
func open_as_overlay() -> void:
	_is_overlay = true
