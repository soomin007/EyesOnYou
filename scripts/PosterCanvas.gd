class_name PosterCanvas
extends Control

# 과제 제출용 게임 소개 포스터 — 인엔진 렌더. 게임의 실제 색·폰트·VEIL 눈(BriefingVisual 모티프)과
# 실제 게임 스크린샷을 함께 써서 화면 아이덴티티와 일치시킨다. _draw로 그래픽(눈/프레임/스샷/구분선),
# Label 자식으로 텍스트. 세로 포스터(A4 비율 근사, 1240×1754). Poster.gd가 SubViewport로 PNG 캡처.
# 스크린샷은 Screenshotter.gd가 res://poster_out/shots/ 에 미리 저장해 둔 것을 런타임 로드.

const W: float = 1240.0
const H: float = 1754.0

# ── 게임 아이덴티티 색 (title.tscn / BriefingVisual / SkillTreeData에서 그대로) ──
const COL_BG: Color = Color(0.043, 0.048, 0.062)
const COL_VEIL: Color = Color(0.46, 0.86, 1.0)        # VEIL 시안
const COL_WHITE: Color = Color(0.95, 0.96, 0.97)
const COL_GRAY: Color = Color(0.74, 0.79, 0.86)
const COL_DIM: Color = Color(0.50, 0.57, 0.66)
const COL_COMBAT: Color = Color(0.97, 0.58, 0.48)     # 전투
const COL_MOBI: Color = Color(0.55, 0.82, 0.97)       # 이동
const COL_SURV: Color = Color(0.58, 0.92, 0.68)       # 생존

const M: float = 100.0
const EYE_C: Vector2 = Vector2(620.0, 288.0)
const EYE_R: float = 146.0

# 스크린샷 스트립 (3장, 16:9)
const SHOT_Y: float = 794.0
const SHOT_W: float = 336.0
const SHOT_H: float = 189.0
const SHOT_GAP: float = 16.0
const SHOTS: Array = [
	["res://poster_out/shots/shot_route_subway.png", "폐쇄 지하철"],
	["res://poster_out/shots/shot_route_watchtower.png", "감시탑"],
	["res://poster_out/shots/shot_route_datacenter.png", "데이터 센터"],
]

const DIV1_Y: float = 1018.0
const DIV2_Y: float = 1452.0
# 특징 2×2 그리드
const FX_L: float = 100.0
const FX_R: float = 648.0
const FY_1: float = 1118.0
const FY_2: float = 1280.0
const FCW: float = 494.0

var _shot_tex: Array = []  # [{tex, rect}]

func _ready() -> void:
	size = Vector2(W, H)
	_load_shots()
	_build_text()

func _load_shots() -> void:
	var total: float = float(SHOTS.size()) * SHOT_W + float(SHOTS.size() - 1) * SHOT_GAP
	var x: float = (W - total) * 0.5
	for entry in SHOTS:
		var pair: Array = entry
		var path: String = str(pair[0])
		var rect: Rect2 = Rect2(x, SHOT_Y, SHOT_W, SHOT_H)
		var tex: Texture2D = null
		var img: Image = Image.new()
		if img.load(path) == OK:
			tex = ImageTexture.create_from_image(img)
		_shot_tex.append({"tex": tex, "rect": rect})
		x += SHOT_W + SHOT_GAP

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, W, H), COL_BG, true)
	# 미세 스캔라인 — CRT/감시화면 질감
	var y: float = 0.0
	while y < H:
		draw_line(Vector2(0.0, y), Vector2(W, y), Color(0.46, 0.86, 1.0, 0.016), 1.0)
		y += 5.0
	# 프레임 + 코너 브래킷 (감시 UI)
	var fm: float = 44.0
	draw_rect(Rect2(fm, fm, W - 2.0 * fm, H - 2.0 * fm), COL_VEIL * Color(1, 1, 1, 0.10), false, 1.0)
	_corner_brackets(fm)
	# 키 비주얼 — VEIL 눈
	_draw_eye(EYE_C, EYE_R)
	# 스크린샷 스트립
	_draw_shots()
	# 구분선
	_divider(DIV1_Y)
	_divider(DIV2_Y)
	# 특징 셀 강조 사각형
	_feat_accents()

func _draw_shots() -> void:
	for item in _shot_tex:
		var d: Dictionary = item
		var rect: Rect2 = d["rect"]
		var tex: Texture2D = d["tex"]
		# 바탕(로드 실패 대비) + 텍스처 + 시안 테두리
		draw_rect(rect, Color(0.06, 0.07, 0.09), true)
		if tex != null:
			draw_texture_rect(tex, rect, false)
		draw_rect(rect, COL_VEIL * Color(1, 1, 1, 0.55), false, 1.5)
		# 좌상 코너 틱
		draw_line(rect.position, rect.position + Vector2(14, 0), COL_VEIL, 2.0)
		draw_line(rect.position, rect.position + Vector2(0, 14), COL_VEIL, 2.0)

# ── VEIL 눈 (BriefingVisual.gd _draw 모티프, 정적 포즈) ──
func _draw_eye(c: Vector2, r: float) -> void:
	var col: Color = COL_VEIL
	for i in 6:
		var f: float = float(i) / 5.0
		draw_circle(c, r * (1.25 - f * 0.5), col * Color(1, 1, 1, 0.018))
	_ring(c, r, 2.0, col * Color(1, 1, 1, 0.55))
	_ring(c, r * 0.82, 1.0, col * Color(1, 1, 1, 0.28))
	for i in 12:
		var ang: float = float(i) / 12.0 * TAU
		var cardinal: bool = (i % 3 == 0)
		var inner: float = r * (0.88 if cardinal else 0.93)
		var outer: float = r * (1.10 if cardinal else 1.04)
		var d: Vector2 = Vector2(cos(ang), sin(ang))
		draw_line(c + d * inner, c + d * outer, col * Color(1, 1, 1, (0.5 if cardinal else 0.3)), (1.5 if cardinal else 1.0), true)
	var gap: float = r * 0.30
	var ch: Color = col * Color(1, 1, 1, 0.22)
	draw_line(c + Vector2(-r * 0.78, 0), c + Vector2(-gap, 0), ch, 1.0, true)
	draw_line(c + Vector2(gap, 0), c + Vector2(r * 0.78, 0), ch, 1.0, true)
	draw_line(c + Vector2(0, -r * 0.78), c + Vector2(0, -gap), ch, 1.0, true)
	draw_line(c + Vector2(0, gap), c + Vector2(0, r * 0.78), ch, 1.0, true)
	var sweep: float = -2.25
	var trail_n: int = 18
	for i in trail_n:
		var f: float = float(i) / float(trail_n)
		var ang0: float = sweep - f * 0.9
		draw_arc(c, r * 0.82, ang0 - 0.06, ang0, 4, col * Color(1, 1, 1, (1.0 - f) * 0.5), 2.0, true)
	var sd: Vector2 = Vector2(cos(sweep), sin(sweep))
	draw_line(c, c + sd * r * 0.82, col * Color(1, 1, 1, 0.7), 1.5, true)
	var pulse: float = 0.62
	var pupil_r: float = r * 0.26 * (0.92 + 0.08 * pulse)
	for i in 5:
		var f: float = float(i) / 4.0
		var rr: float = pupil_r * (2.4 - f * 1.4)
		draw_circle(c, rr, col * Color(1, 1, 1, 0.06))
	draw_circle(c, pupil_r, col * Color(1, 1, 1, 0.45 + 0.25 * pulse))
	_ring(c, pupil_r, 1.5, col * Color(1, 1, 1, 0.8))
	draw_circle(c + Vector2(-pupil_r * 0.3, -pupil_r * 0.3), pupil_r * 0.22, Color(0.9, 0.98, 1.0, 0.7))

func _ring(center: Vector2, radius: float, width: float, col: Color) -> void:
	draw_arc(center, radius, 0.0, TAU, 64, col, width, true)

func _corner_brackets(fm: float) -> void:
	var col: Color = COL_VEIL * Color(1, 1, 1, 0.55)
	var ln: float = 58.0
	var wd: float = 2.0
	draw_line(Vector2(fm, fm), Vector2(fm + ln, fm), col, wd)
	draw_line(Vector2(fm, fm), Vector2(fm, fm + ln), col, wd)
	draw_line(Vector2(W - fm, fm), Vector2(W - fm - ln, fm), col, wd)
	draw_line(Vector2(W - fm, fm), Vector2(W - fm, fm + ln), col, wd)
	draw_line(Vector2(fm, H - fm), Vector2(fm + ln, H - fm), col, wd)
	draw_line(Vector2(fm, H - fm), Vector2(fm, H - fm - ln), col, wd)
	draw_line(Vector2(W - fm, H - fm), Vector2(W - fm - ln, H - fm), col, wd)
	draw_line(Vector2(W - fm, H - fm), Vector2(W - fm, H - fm - ln), col, wd)

func _divider(dy: float) -> void:
	draw_line(Vector2(M, dy), Vector2(W - M, dy), COL_VEIL * Color(1, 1, 1, 0.22), 1.0, true)
	var c: Vector2 = Vector2(W * 0.5, dy)
	var s: float = 5.0
	var pts: PackedVector2Array = [c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]
	draw_colored_polygon(pts, COL_VEIL * Color(1, 1, 1, 0.5))

func _feat_accents() -> void:
	var sz: float = 22.0
	draw_rect(Rect2(FX_L, FY_1, sz, sz), COL_VEIL, true)
	draw_rect(Rect2(FX_R, FY_1, sz, sz), COL_COMBAT, true)
	draw_rect(Rect2(FX_R, FY_2, sz, sz), COL_MOBI, true)
	# 셀3 스킬 — 3계열 색 3개
	draw_rect(Rect2(FX_L, FY_2, 12.0, sz), COL_COMBAT, true)
	draw_rect(Rect2(FX_L + 15.0, FY_2, 12.0, sz), COL_MOBI, true)
	draw_rect(Rect2(FX_L + 30.0, FY_2, 12.0, sz), COL_SURV, true)

# ── 텍스트 (Label 자식) ──
func _build_text() -> void:
	_label("ARCTURUS DYNAMICS   ·   현장 작전 기록   ·   OPERATION PALIMPSEST",
		Vector2(M, 86.0), W - 2.0 * M, 18, COL_VEIL * Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("EYES ON YOU", Vector2(M, 452.0), W - 2.0 * M, 110, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("누군가, 당신을 보고 있다.", Vector2(M, 612.0), W - 2.0 * M, 32, COL_VEIL, HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("근미래 보안기업의 현장 요원. 상황실 AI 'VEIL'의 조언을 들으며, 혹은 무시하며 임무를 클리어한다.\n그 선택이 쌓여 — 마지막에, VEIL이 누구였는지 드러난다.",
		Vector2((W - 960.0) * 0.5, 672.0), 960.0, 23, COL_GRAY, HORIZONTAL_ALIGNMENT_CENTER, true)
	# 스크린샷 캡션
	_shot_captions(SHOT_Y + SHOT_H + 8.0)
	# 정보 칩
	_label("횡스크롤 로그라이트     ·     8–15분     ·     4종 결말     ·     Godot 4.6",
		Vector2(M, 1040.0), W - 2.0 * M, 21, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)
	# 특징 4 (2×2)
	_feat_cell(FX_L, FY_1, 36.0, "VEIL — 당신을 보는 AI",
		"위협을 미리 짚어주는 상황실 AI 파트너. 그 조언을 따른 정도가 네 개의 결말을 가른다.")
	_feat_cell(FX_R, FY_1, 36.0, "5종의 적, 둥지의 저격수",
		"정찰병·저격수·드론·자폭병·방패병. 측면 둥지의 저격은 글라이드로 덮친다.")
	_feat_cell(FX_L, FY_2, 56.0, "스킬 8라인 × 3티어",
		"전투·이동·생존 3계열. 레벨업마다 셋 중 하나를 골라 빌드를 쌓는다.")
	_feat_cell(FX_R, FY_2, 36.0, "12개 맵 · Dead Cells식",
		"스테이지마다 추첨되는 루트. 위험을 감수할수록 보상이 커진다.")
	# VEIL 인용
	_label("“위험한 건 제가 먼저 볼게요. 화면 끝에 짚어둘게요.”",
		Vector2(M, 1488.0), W - 2.0 * M, 28, COL_VEIL, HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("— VEIL", Vector2(M, 1532.0), W - 2.0 * M, 19, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)
	# 푸터
	_label("▶  soomin007.github.io/EyesOnYou", Vector2(M, 1618.0), W - 2.0 * M, 23, COL_VEIL, HORIZONTAL_ALIGNMENT_CENTER, false)
	_label("Godot 4.6 · GL Compatibility · 개인 프로젝트 / 전시 데모",
		Vector2(M, 1654.0), W - 2.0 * M, 16, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)

func _shot_captions(cy: float) -> void:
	var i: int = 0
	for entry in SHOTS:
		var pair: Array = entry
		var rect: Rect2 = (_shot_tex[i] as Dictionary)["rect"]
		_label(str(pair[1]), Vector2(rect.position.x, cy), SHOT_W, 14, COL_DIM, HORIZONTAL_ALIGNMENT_CENTER, false)
		i += 1

func _feat_cell(x: float, y: float, head_off: float, head: String, desc: String) -> void:
	_label(head, Vector2(x + head_off, y - 3.0), FCW - head_off, 24, COL_WHITE, HORIZONTAL_ALIGNMENT_LEFT, false)
	_label(desc, Vector2(x, y + 40.0), FCW, 18, COL_GRAY, HORIZONTAL_ALIGNMENT_LEFT, true)

func _label(txt: String, pos: Vector2, w: float, font_size: int, col: Color, align: int, wrap: bool) -> Label:
	var l: Label = Label.new()
	l.text = txt
	l.position = pos
	l.size = Vector2(w, 0.0)
	l.custom_minimum_size = Vector2(w, 0.0)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l
