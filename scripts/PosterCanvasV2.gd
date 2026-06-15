class_name PosterCanvasV2
extends Control

# 과제 전시용 포스터 v2 — "FULLY AI-GENERATED"를 헤드라인으로 내세운 홍보판.
# v1(PosterCanvas)이 게임 소개라면, v2는 *과제로서의 게임*을 전시·홍보한다: 코드·배경음악·효과음까지
# 전부 생성형 AI로 만들었다는 점을 실제 수치(코드 17,132줄 / 음악 9트랙 / 효과음 59개)와 함께 제시하고,
# 스크린샷을 큼지막한 hero + 보조 3컷으로 보여준다. 게임 실제 색·VEIL 눈 모티프·스크린샷을 그대로 쓴다.
# PosterV2.gd가 SubViewport로 PNG 캡처. 스크린샷은 Screenshotter.gd가 미리 저장해 둔 것을 런타임 로드.

const W: float = 1240.0
const H: float = 1754.0

# ── 게임 아이덴티티 색 ──
const COL_BG: Color = Color(0.043, 0.048, 0.062)
const COL_VEIL: Color = Color(0.46, 0.86, 1.0)        # VEIL 시안 (브랜드 / 코드)
const COL_WHITE: Color = Color(0.95, 0.96, 0.97)
const COL_GRAY: Color = Color(0.74, 0.79, 0.86)
const COL_DIM: Color = Color(0.50, 0.57, 0.66)
const COL_AMBER: Color = Color(0.96, 0.80, 0.42)      # 앰버 (음악)
const COL_SURV: Color = Color(0.58, 0.92, 0.68)       # 민트 (효과음)

const M: float = 100.0
const FM: float = 44.0

# ── 헤더 / 키 비주얼 ──
const EYE_C: Vector2 = Vector2(620.0, 166.0)
const EYE_R: float = 52.0
const TITLE_Y: float = 234.0

# ── AI-GENERATED 배지 ──
const BADGE_Y: float = 354.0
const BADGE_W: float = 600.0
const BADGE_H: float = 56.0

# ── hero 스크린샷 (큰 한 컷, 16:9) ──
const HERO_X: float = 120.0
const HERO_Y: float = 512.0
const HERO_W: float = 1000.0
const HERO_H: float = 562.0
const HERO_SHOT: String = "res://poster_out/shots/shot_route_subway.png"
const HERO_CAP: String = "실제 플레이 화면 — VEIL이 위협을 짚어주는 횡스크롤 침투전"

# ── 보조 스크린샷 3컷 ──
const SUP_Y: float = 1106.0
const SUP_W: float = 322.0
const SUP_H: float = 181.0
const SUP_GAP: float = 17.0
const SUPS: Array = [
	["res://poster_out/shots/shot_routemap.png", "맵 선택 · 12개 루트"],
	["res://poster_out/shots/shot_skilltree.png", "스킬 트리 · 3계열"],
	["res://poster_out/shots/shot_route_datacenter.png", "전투 · 적 웨이브"],
]

# ── AI 제작 분해 (실제 수치 — docs/contributions.md 진실) ──
const AIB_HEAD_Y: float = 1324.0
const AIB_Y: float = 1352.0
const AIB_H: float = 150.0
const AIB_GAP: float = 16.0
# [accent, 큰수치, 제목, 상세, 생성툴]
const AI_CELLS: Array = [
	["code", "17,132", "줄 GDScript 코드", "시스템 · 적 · 보스 · UI · 세이브 전부", "CLAUDE  (ANTHROPIC)"],
	["music", "9", "곡 배경음악", "메인 테마부터 4종 엔딩까지", "SUNO"],
	["sound", "59", "개 효과음", "사격 · 폭발 · 보스 · UI · 환경", "ELEVENLABS"],
]

# ── 푸터 ──
const DIR_Y: float = 1520.0
const CHIP_Y: float = 1560.0
const URL_Y: float = 1596.0
const FOOT_Y: float = 1638.0

var _hero_tex: Texture2D = null
var _sup_tex: Array = []  # [{tex, rect}]

func _ready() -> void:
	size = Vector2(W, H)
	_load_shots()
	_build_text()

func _load_shots() -> void:
	_hero_tex = _load_tex(HERO_SHOT)
	var total: float = float(SUPS.size()) * SUP_W + float(SUPS.size() - 1) * SUP_GAP
	var x: float = (W - total) * 0.5
	for entry in SUPS:
		var pair: Array = entry
		var rect: Rect2 = Rect2(x, SUP_Y, SUP_W, SUP_H)
		_sup_tex.append({"tex": _load_tex(str(pair[0])), "rect": rect})
		x += SUP_W + SUP_GAP

func _load_tex(path: String) -> Texture2D:
	var img: Image = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _cell_rect(i: int) -> Rect2:
	var bw: float = (W - 2.0 * M - 2.0 * AIB_GAP) / 3.0
	var x: float = M + float(i) * (bw + AIB_GAP)
	return Rect2(x, AIB_Y, bw, AIB_H)

func _accent_for(key: String) -> Color:
	match key:
		"music":
			return COL_AMBER
		"sound":
			return COL_SURV
		_:
			return COL_VEIL

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, W, H), COL_BG, true)
	# 미세 스캔라인 — CRT/감시화면 질감
	var y: float = 0.0
	while y < H:
		draw_line(Vector2(0.0, y), Vector2(W, y), Color(0.46, 0.86, 1.0, 0.015), 1.0)
		y += 5.0
	draw_rect(Rect2(FM, FM, W - 2.0 * FM, H - 2.0 * FM), COL_VEIL * Color(1, 1, 1, 0.10), false, 1.0)
	_corner_brackets(FM)
	_draw_eye(EYE_C, EYE_R)
	_draw_badge()
	_draw_hero()
	_draw_sups()
	_draw_ai_cells()

# ── AI-GENERATED 배지 — v2의 헤드라인 차별점 ──
func _draw_badge() -> void:
	var x: float = (W - BADGE_W) * 0.5
	var rect: Rect2 = Rect2(x, BADGE_Y, BADGE_W, BADGE_H)
	# 옅은 시안 글로우 + 테두리
	for i in 4:
		var f: float = float(i) / 3.0
		var gr: Rect2 = rect.grow(2.0 + f * 7.0)
		draw_rect(gr, COL_VEIL * Color(1, 1, 1, 0.05 * (1.0 - f)), false, 1.0)
	draw_rect(rect, Color(0.07, 0.13, 0.17, 0.92), true)
	draw_rect(rect, COL_VEIL * Color(1, 1, 1, 0.75), false, 2.0)
	# 코너 틱
	var tl: Vector2 = rect.position
	var tr: Vector2 = rect.position + Vector2(rect.size.x, 0)
	var bl: Vector2 = rect.position + Vector2(0, rect.size.y)
	var br: Vector2 = rect.position + rect.size
	for corner in [[tl, Vector2(1, 0), Vector2(0, 1)], [tr, Vector2(-1, 0), Vector2(0, 1)], [bl, Vector2(1, 0), Vector2(0, -1)], [br, Vector2(-1, 0), Vector2(0, -1)]]:
		var c: Vector2 = corner[0]
		draw_line(c, c + (corner[1] as Vector2) * 14.0, COL_VEIL, 2.5)
		draw_line(c, c + (corner[2] as Vector2) * 14.0, COL_VEIL, 2.5)

func _draw_hero() -> void:
	var rect: Rect2 = Rect2(HERO_X, HERO_Y, HERO_W, HERO_H)
	# 글로우 테두리
	for i in 4:
		var f: float = float(i) / 3.0
		draw_rect(rect.grow(2.0 + f * 6.0), COL_VEIL * Color(1, 1, 1, 0.06 * (1.0 - f)), false, 1.0)
	draw_rect(rect, Color(0.06, 0.07, 0.09), true)
	if _hero_tex != null:
		draw_texture_rect(_hero_tex, rect, false)
	draw_rect(rect, COL_VEIL * Color(1, 1, 1, 0.6), false, 2.0)
	# 코너 브래킷 (감시 UI 프레임)
	_rect_corners(rect, 26.0, COL_VEIL)

func _draw_sups() -> void:
	for item in _sup_tex:
		var d: Dictionary = item
		var rect: Rect2 = d["rect"]
		var tex: Texture2D = d["tex"]
		draw_rect(rect, Color(0.06, 0.07, 0.09), true)
		if tex != null:
			draw_texture_rect(tex, rect, false)
		draw_rect(rect, COL_VEIL * Color(1, 1, 1, 0.5), false, 1.5)
		_rect_corners(rect, 14.0, COL_VEIL)

func _draw_ai_cells() -> void:
	for i in AI_CELLS.size():
		var cell: Array = AI_CELLS[i]
		var accent: Color = _accent_for(str(cell[0]))
		var r: Rect2 = _cell_rect(i)
		draw_rect(r, Color(0.085, 0.105, 0.14, 0.92), true)
		draw_rect(r, accent * Color(1, 1, 1, 0.35), false, 1.0)
		draw_line(r.position, r.position + Vector2(14, 0), accent, 2.0)
		draw_line(r.position, r.position + Vector2(0, 14), accent, 2.0)
		_cell_icon(str(cell[0]), Vector2(r.position.x + 30.0, r.position.y + 30.0), 13.0, accent)

func _cell_icon(key: String, c: Vector2, r: float, accent: Color) -> void:
	match key:
		"music":
			_icon_wave(c, r, accent)
		"sound":
			_icon_speaker(c, r, accent)
		_:
			_icon_code(c, r, accent)

func _icon_code(c: Vector2, r: float, col: Color) -> void:
	# </> — 코드 기호
	var lp: PackedVector2Array = PackedVector2Array([
		c + Vector2(-r * 0.35, -r * 0.7), c + Vector2(-r, 0), c + Vector2(-r * 0.35, r * 0.7)])
	var rp: PackedVector2Array = PackedVector2Array([
		c + Vector2(r * 0.35, -r * 0.7), c + Vector2(r, 0), c + Vector2(r * 0.35, r * 0.7)])
	draw_polyline(lp, col, 2.0, true)
	draw_polyline(rp, col, 2.0, true)
	draw_line(c + Vector2(-r * 0.18, r * 0.6), c + Vector2(r * 0.18, -r * 0.6), col * Color(1, 1, 1, 0.85), 2.0, true)

func _icon_wave(c: Vector2, r: float, col: Color) -> void:
	# 오디오 파형 — 막대 5개
	var heights: Array = [0.45, 0.9, 0.6, 1.0, 0.5]
	var n: int = heights.size()
	var step: float = (r * 2.0) / float(n - 1)
	for i in n:
		var hx: float = c.x - r + float(i) * step
		var hh: float = r * float(heights[i])
		draw_line(Vector2(hx, c.y - hh), Vector2(hx, c.y + hh), col, 2.0, true)

func _icon_speaker(c: Vector2, r: float, col: Color) -> void:
	# 스피커 + 음파 2줄
	var body: PackedVector2Array = PackedVector2Array([
		c + Vector2(-r, -r * 0.35), c + Vector2(-r * 0.35, -r * 0.35), c + Vector2(r * 0.15, -r * 0.75),
		c + Vector2(r * 0.15, r * 0.75), c + Vector2(-r * 0.35, r * 0.35), c + Vector2(-r, r * 0.35)])
	draw_colored_polygon(body, col * Color(1, 1, 1, 0.85))
	draw_arc(c + Vector2(r * 0.15, 0), r * 0.55, -0.9, 0.9, 10, col, 1.8, true)
	draw_arc(c + Vector2(r * 0.15, 0), r * 0.85, -0.8, 0.8, 12, col * Color(1, 1, 1, 0.7), 1.8, true)

# ── VEIL 눈 (PosterCanvas와 동일 모티프) ──
func _draw_eye(c: Vector2, r: float) -> void:
	var col: Color = COL_VEIL
	for i in 6:
		var hf: float = float(i) / 5.0
		draw_circle(c, r * (1.34 - hf * 0.5), col * Color(1, 1, 1, 0.032 * (1.0 - hf * 0.55)))
	_ring(c, r, 2.0, col * Color(1, 1, 1, 0.55))
	_ring(c, r * 0.82, 1.0, col * Color(1, 1, 1, 0.28))
	for i in 12:
		var ang: float = float(i) / 12.0 * TAU
		var cardinal: bool = (i % 3 == 0)
		var inner: float = r * (0.88 if cardinal else 0.93)
		var outer: float = r * (1.10 if cardinal else 1.04)
		var d: Vector2 = Vector2(cos(ang), sin(ang))
		draw_line(c + d * inner, c + d * outer, col * Color(1, 1, 1, (0.5 if cardinal else 0.3)), (1.5 if cardinal else 1.0), true)
	var sweep: float = -2.25
	var trail_n: int = 18
	for i in trail_n:
		var f: float = float(i) / float(trail_n)
		var ang0: float = sweep - f * 0.9
		draw_arc(c, r * 0.82, ang0 - 0.06, ang0, 4, col * Color(1, 1, 1, (1.0 - f) * 0.5), 2.0, true)
	var sd: Vector2 = Vector2(cos(sweep), sin(sweep))
	draw_line(c, c + sd * r * 0.82, col * Color(1, 1, 1, 0.7), 1.5, true)
	var pupil_r: float = r * 0.27
	for i in 5:
		var f: float = float(i) / 4.0
		var rr: float = pupil_r * (2.4 - f * 1.4)
		draw_circle(c, rr, col * Color(1, 1, 1, 0.06))
	draw_circle(c, pupil_r, col * Color(1, 1, 1, 0.6))
	_ring(c, pupil_r, 1.5, col * Color(1, 1, 1, 0.8))
	draw_circle(c + Vector2(-pupil_r * 0.3, -pupil_r * 0.3), pupil_r * 0.22, Color(0.9, 0.98, 1.0, 0.7))

func _ring(center: Vector2, radius: float, width: float, col: Color) -> void:
	draw_arc(center, radius, 0.0, TAU, 64, col, width, true)

func _rect_corners(rect: Rect2, ln: float, col: Color) -> void:
	var tl: Vector2 = rect.position
	var tr: Vector2 = rect.position + Vector2(rect.size.x, 0)
	var bl: Vector2 = rect.position + Vector2(0, rect.size.y)
	var br: Vector2 = rect.position + rect.size
	draw_line(tl, tl + Vector2(ln, 0), col, 2.0)
	draw_line(tl, tl + Vector2(0, ln), col, 2.0)
	draw_line(tr, tr + Vector2(-ln, 0), col, 2.0)
	draw_line(tr, tr + Vector2(0, ln), col, 2.0)
	draw_line(bl, bl + Vector2(ln, 0), col, 2.0)
	draw_line(bl, bl + Vector2(0, -ln), col, 2.0)
	draw_line(br, br + Vector2(-ln, 0), col, 2.0)
	draw_line(br, br + Vector2(0, -ln), col, 2.0)

func _corner_brackets(fm: float) -> void:
	var col: Color = COL_VEIL * Color(1, 1, 1, 0.55)
	var ln: float = 40.0
	var wd: float = 2.0
	draw_line(Vector2(fm, fm), Vector2(fm + ln, fm), col, wd)
	draw_line(Vector2(fm, fm), Vector2(fm, fm + ln), col, wd)
	draw_line(Vector2(W - fm, fm), Vector2(W - fm - ln, fm), col, wd)
	draw_line(Vector2(W - fm, fm), Vector2(W - fm, fm + ln), col, wd)
	draw_line(Vector2(fm, H - fm), Vector2(fm + ln, H - fm), col, wd)
	draw_line(Vector2(fm, H - fm), Vector2(fm, H - fm - ln), col, wd)
	draw_line(Vector2(W - fm, H - fm), Vector2(W - fm - ln, H - fm), col, wd)
	draw_line(Vector2(W - fm, H - fm), Vector2(W - fm, H - fm - ln), col, wd)

# ── 텍스트 ──
func _build_text() -> void:
	# 헤더 키커
	_label("ARCTURUS DYNAMICS  //  전시 작품", Vector2(M, 70.0), W - 2.0 * M, 16,
		COL_VEIL * Color(1, 1, 1, 0.80), HORIZONTAL_ALIGNMENT_LEFT, false)
	_label("OPERATION PALIMPSEST", Vector2(M, 70.0), W - 2.0 * M, 16,
		COL_DIM, HORIZONTAL_ALIGNMENT_RIGHT, false)
	# 타이틀
	_label("EYES ON YOU", Vector2(M, TITLE_Y), W - 2.0 * M, 100, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER, false, 8)
	# AI-GENERATED 배지 텍스트
	_label("FULLY  AI-GENERATED", Vector2((W - BADGE_W) * 0.5, BADGE_Y + 11.0), BADGE_W, 30,
		COL_VEIL, HORIZONTAL_ALIGNMENT_CENTER, false, 5)
	# 메타 훅
	_label("코드부터 배경음악·효과음까지 — 전부 생성형 AI의 산출물",
		Vector2(M, BADGE_Y + BADGE_H + 16.0), W - 2.0 * M, 27, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("당신을 지켜보는 AI를 그린 게임을, 사람이 방향을 잡고 AI가 만들었다.",
		Vector2(M, BADGE_Y + BADGE_H + 56.0), W - 2.0 * M, 20, COL_GRAY, HORIZONTAL_ALIGNMENT_CENTER, false)
	# hero 캡션
	_label(HERO_CAP, Vector2(HERO_X, HERO_Y + HERO_H + 8.0), HERO_W, 15,
		COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)
	# 보조 캡션
	_sup_captions(SUP_Y + SUP_H + 8.0)
	# AI 제작 분해
	_label("무엇을, 무엇으로 만들었나", Vector2(M, AIB_HEAD_Y), W - 2.0 * M, 16,
		COL_VEIL * Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, false)
	_label("외부 자산·생성 도구", Vector2(M, AIB_HEAD_Y + 1.0), W - 2.0 * M, 15,
		COL_DIM, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_ai_cell_text()
	# Direction (정직한 분담 — contributions.md)
	_label("DIRECTION  ·  기획 · 창작 방향 · 모든 설계 결정 · 검수  —  김수민 (자유전공학부)",
		Vector2(M, DIR_Y), W - 2.0 * M, 16, COL_GRAY, HORIZONTAL_ALIGNMENT_CENTER, false)
	# 푸터
	_label("횡스크롤 로그라이트     ·     8–15분     ·     4종 결말     ·     Godot 4.6",
		Vector2(M, CHIP_Y), W - 2.0 * M, 19, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("▶  soomin007.github.io/EyesOnYou", Vector2(M, URL_Y), W - 2.0 * M, 24,
		COL_VEIL, HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("Windows PC · 키보드 / 게임패드 · Suno · ElevenLabs · Pretendard(OFL)",
		Vector2(M, FOOT_Y), W - 2.0 * M, 15, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)

func _sup_captions(cy: float) -> void:
	var i: int = 0
	for entry in SUPS:
		var pair: Array = entry
		var rect: Rect2 = (_sup_tex[i] as Dictionary)["rect"]
		_label(str(pair[1]), Vector2(rect.position.x, cy), SUP_W, 14, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)
		i += 1

func _ai_cell_text() -> void:
	for i in AI_CELLS.size():
		var cell: Array = AI_CELLS[i]
		var accent: Color = _accent_for(str(cell[0]))
		var r: Rect2 = _cell_rect(i)
		var x: float = r.position.x
		var w: float = r.size.x
		# 생성 툴 태그 (우상단)
		_label(str(cell[4]), Vector2(x, r.position.y + 14.0), w - 16.0, 12, accent, HORIZONTAL_ALIGNMENT_RIGHT, false)
		# 큰 수치
		_label(str(cell[1]), Vector2(x + 16.0, r.position.y + 40.0), w - 32.0, 42, accent, HORIZONTAL_ALIGNMENT_LEFT, false)
		# 제목
		_label(str(cell[2]), Vector2(x + 16.0, r.position.y + 92.0), w - 32.0, 17, COL_WHITE, HORIZONTAL_ALIGNMENT_LEFT, false)
		# 상세
		_label(str(cell[3]), Vector2(x + 16.0, r.position.y + 116.0), w - 32.0, 13, COL_GRAY, HORIZONTAL_ALIGNMENT_LEFT, false)

func _label(txt: String, pos: Vector2, w: float, font_size: int, col: Color, align: int, wrap: bool, outline: int = 4) -> Label:
	var l: Label = Label.new()
	l.text = txt
	l.position = pos
	l.size = Vector2(w, 0.0)
	l.custom_minimum_size = Vector2(w, 0.0)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l
