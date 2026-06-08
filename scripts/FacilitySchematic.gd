extends Control

# 미션 브리핑 도면 — SILO-7 시설 단면. 자산 없이 _draw 도형으로 그린다.
# stage 0 인트로에서 대사 박스 오른쪽(허전하던 자리)에 표시. 진입(상단)→하강 경로→
# 목표 서버실(하단)을 한 장에 보여줘 "어디로 가는 임무인지"를 직관화한다.
# 색: VEIL 시안 기조 + 목표는 따뜻한 호박색으로 강조해 시선을 끌어내린다. 스캔선·맥동으로 생동.

const COL_VEIL: Color = Color(0.46, 0.86, 1.0)
const COL_TARGET: Color = Color(1.0, 0.72, 0.42)
const LEVELS: int = 6
const TWO_PI: float = PI * 2.0

var t: float = 0.0
var appear: float = 0.0   # 0→1 등장 이징

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	t += delta
	if appear < 1.0:
		appear = minf(1.0, appear + delta / 1.1)
	queue_redraw()

func _draw() -> void:
	var a: float = 1.0 - pow(1.0 - appear, 3.0)
	if a <= 0.001 or size.x < 30.0 or size.y < 30.0:
		return
	var top: float = size.y * 0.13
	var bot: float = size.y * 0.93
	var sw: float = minf(size.x * 0.50, 150.0)
	var cx: float = size.x * 0.5
	var lx: float = cx - sw * 0.5
	var rx: float = cx + sw * 0.5
	var col: Color = COL_VEIL * Color(1, 1, 1, a)
	var faint: Color = COL_VEIL * Color(1, 1, 1, 0.32 * a)
	var level_h: float = (bot - top) / float(LEVELS)

	# 외벽(두 겹) + 상/하 캡
	draw_line(Vector2(lx, top), Vector2(lx, bot), col, 2.0, true)
	draw_line(Vector2(rx, top), Vector2(rx, bot), col, 2.0, true)
	draw_line(Vector2(lx - 6.0, top), Vector2(lx - 6.0, bot), faint, 1.0, true)
	draw_line(Vector2(rx + 6.0, top), Vector2(rx + 6.0, bot), faint, 1.0, true)
	draw_line(Vector2(lx, top), Vector2(rx, top), col, 2.0, true)
	draw_line(Vector2(lx, bot), Vector2(rx, bot), col, 2.0, true)

	# 층 분리선(점선)
	for i in range(1, LEVELS):
		var y: float = top + level_h * float(i)
		draw_dashed_line(Vector2(lx, y), Vector2(rx, y), faint, 1.0, 5.0)

	# 하강 침투 경로 — 층마다 좌우 교대 지그재그
	var path_col: Color = COL_VEIL * Color(1, 1, 1, 0.85 * a)
	var pts: Array = []
	for i in LEVELS + 1:
		var y: float = top + level_h * float(i)
		var f: float = 0.30 if (i % 2 == 0) else 0.70
		pts.append(Vector2(lx + sw * f, y))
	for i in pts.size() - 1:
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		draw_line(p0, p1, path_col, 1.5, true)
		draw_circle(p0, 2.4, path_col)
	# 경로를 따라 내려가는 현재 위치 점("지금 브리핑 중인 침투 경로")
	var prog: float = fmod(t * 0.45, 1.0)
	var seg_f: float = prog * float(pts.size() - 1)
	var si: int = int(seg_f)
	si = clampi(si, 0, pts.size() - 2)
	var marker: Vector2 = pts[si].lerp(pts[si + 1], seg_f - float(si))
	draw_circle(marker, 4.0 * a, Color(0.95, 0.99, 1.0, 0.9 * a))

	# 진입 마커(상단) — 링 + 아래로 향한 삼각형
	var entry: Vector2 = Vector2(cx, top)
	draw_arc(entry, 7.0, 0.0, TWO_PI, 20, col, 1.5, true)
	var tri: PackedVector2Array = PackedVector2Array([
		entry + Vector2(-4.0, 1.0), entry + Vector2(4.0, 1.0), entry + Vector2(0.0, 6.0)])
	draw_colored_polygon(tri, col)

	# 목표(하단 서버실) — 맥동 글로우 + 데이터 드라이브 사각
	var pulse: float = 0.5 + 0.5 * sin(t * 2.2)
	var target: Vector2 = Vector2(cx, bot - level_h * 0.5)
	draw_circle(target, (11.0 + 4.0 * pulse) * a, COL_TARGET * Color(1, 1, 1, 0.16 * a))
	var trect := Rect2(target - Vector2(7.0, 5.0), Vector2(14.0, 10.0))
	draw_rect(trect, COL_TARGET * Color(1, 1, 1, (0.45 + 0.3 * pulse) * a), true)
	draw_rect(trect, COL_TARGET * Color(1, 1, 1, a), false, 1.5)

	# 세로 드리프트 스캔선
	var sy: float = top + (bot - top) * (0.5 + 0.5 * sin(t * 0.6))
	draw_line(Vector2(lx, sy), Vector2(rx, sy), COL_VEIL * Color(1, 1, 1, 0.14 * a), 1.0, true)

	# 라벨 — 프로젝트 기본 폰트(한글 지원)
	var font: Font = get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(lx - 6.0, top - 9.0), "SILO-7", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
		draw_string(font, Vector2(rx + 10.0, top + 5.0), "진입", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, faint)
		draw_string(font, Vector2(rx + 10.0, target.y + 5.0), "서버실", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COL_TARGET * Color(1, 1, 1, a))
