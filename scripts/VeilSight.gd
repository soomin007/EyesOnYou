class_name VeilSight
extends Control

# ─── VEIL 시야 마킹 (시야=신뢰 파일럿, v3 §2 보류분) ───────────────────────
# "VEIL이 요원 대신 본다"를 *플레이로 실연*하는 첫 시스템. VEIL이 요원이 못 보는 원거리/공중
# 위협(저격수·드론·폭격기)을 HUD로 짚어준다:
#   - 화면 안 위협 → 시안색 다이아몬드 reticle ("눈을 두고 있다")
#   - 화면 밖 위협 → 화면 가장자리 화살표 ("네가 못 보는 걸 내가 본다") ← 핵심 가치
# ACT3(degraded=true)에선 마커가 staggered하게 깜빡이고 군데군데 꺼진다 = "제 눈이 여기서 멈춰요"가
# 글이 아니라 화면에서 일어남. 그때부터 표시 안 된 위협은 요원이 직접 봐야 한다 = 역전이 플레이로.
#
# 파일럿 범위: 현재 위협(presence) 마킹 + ACT3 degradation까지만. 조준 경고 펄스 / 길 제시 / 마커
# 위치 lag 등은 체감 확인 후 확장. (정면 위협인 patrol/shield는 요원이 직접 보므로 마킹 제외.)

var player: Node2D = null
var degraded: bool = false  # ACT3 — 마커가 흐려지고 꺼짐

const DETECT_RADIUS: float = 1500.0           # 이 안의 위협만 VEIL이 본다 (≈ 화면 한 칸 너머까지)
const MARKED_TYPES: Array[int] = [1, 2, 3]    # sniper / drone / bomber (patrol=0, shield=4 제외)
const CALM: Color = Color(0.42, 0.86, 1.0)    # VEIL 시안 — 자막 색과 통일감
const EDGE_MARGIN: float = 48.0               # 화면 밖 화살표가 가장자리에서 떨어지는 여백
const RETICLE_R: float = 17.0

var _t: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var xform: Transform2D = get_viewport().get_canvas_transform()
	var view: Vector2 = get_viewport_rect().size
	var center: Vector2 = view * 0.5
	var ppos: Vector2 = player.global_position
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		var en: Node2D = e as Node2D
		if not is_instance_valid(en):
			continue
		if bool(en.get("dead")):
			continue
		if int(en.get("enemy_type")) not in MARKED_TYPES:
			continue
		var wpos: Vector2 = en.global_position
		if ppos.distance_to(wpos) > DETECT_RADIUS:
			continue
		# ACT3 degradation — 위협별 staggered 깜빡임 + 암점.
		var alpha_mul: float = 1.0
		if degraded:
			var phase: float = float(en.get_instance_id() % 997) * 0.0131
			if fmod(_t * 0.9 + phase, 1.0) < 0.34:   # 주기의 1/3은 VEIL이 못 봄 → 마커 꺼짐
				continue
			alpha_mul = clamp(0.5 + 0.3 * sin(_t * 6.0 + phase), 0.22, 0.8)  # 남은 동안도 불안정
		var spos: Vector2 = xform * wpos
		var on_screen: bool = spos.x >= 0.0 and spos.x <= view.x and spos.y >= 0.0 and spos.y <= view.y
		if on_screen:
			# 화면 안 — 요원도 볼 수 있으니 살짝 은은하게.
			var rc: Color = CALM
			rc.a *= 0.55 * alpha_mul
			_draw_reticle(spos, rc)
		else:
			# 화면 밖 — VEIL의 봄이 빛나는 곳. 또렷하게.
			var ec: Color = CALM
			ec.a *= alpha_mul
			_draw_edge_arrow(spos, center, view, ec)

func _draw_reticle(pos: Vector2, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		pos + Vector2(0.0, -RETICLE_R),
		pos + Vector2(RETICLE_R, 0.0),
		pos + Vector2(0.0, RETICLE_R),
		pos + Vector2(-RETICLE_R, 0.0),
		pos + Vector2(0.0, -RETICLE_R),
	])
	draw_polyline(pts, col, 2.0)

func _draw_edge_arrow(spos: Vector2, center: Vector2, view: Vector2, col: Color) -> void:
	# 위협 방향으로 화면 가장자리(여백 inset)에 클램프한 점 + 그 방향을 가리키는 삼각형.
	var edge: Vector2 = Vector2(
		clamp(spos.x, EDGE_MARGIN, view.x - EDGE_MARGIN),
		clamp(spos.y, EDGE_MARGIN, view.y - EDGE_MARGIN),
	)
	var dir: Vector2 = spos - center
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var tip: Vector2 = edge + dir * 13.0
	var a: Vector2 = edge - dir * 6.0 + perp * 9.0
	var b: Vector2 = edge - dir * 6.0 - perp * 9.0
	draw_colored_polygon(PackedVector2Array([tip, a, b]), col)
	var dot: Color = col
	dot.a *= 0.7
	draw_circle(edge - dir * 7.0, 3.0, dot)
