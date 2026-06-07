class_name VeilSight
extends Control

# ─── VEIL 시야 마킹 (시야=신뢰 파일럿, v3 §2 보류분) ───────────────────────
# "VEIL이 요원 대신 본다"를 *플레이로 실연*하는 시스템. VEIL이 요원 주변의 모든 위협을 HUD로 짚어준다:
#   - 화면 안 위협 → 시안색 다이아몬드 reticle (요원도 보니 은은하게)
#   - 화면 밖 위협 → 화면 가장자리 화살표 ("네가 못 보는 걸 내가 본다") ← 핵심 가치
#   - 공격 임박(조준/돌진/폭탄) → 경고색 주황으로 펄스 ("VEIL이 위험을 미리 짚어준다")
# ACT3(degraded=true)에선 마커가 staggered하게 깜빡이고 군데군데 꺼진다 = "제 눈이 여기서 멈춰요"가
# 글이 아니라 화면에서. 표시 안 된 위협은 요원이 직접 봐야 한다 = 역전이 플레이로.
#
# 확장 이력: 처음엔 원거리/공중(저격수·드론·폭격기)만 마킹했으나 "있는지조차 모르겠다"는 피드백으로
# 전 적 마킹 + 공격 경고 펄스 + 탐지 범위 확대(VEIL의 권한 강화). 길 제시는 다음 확장 후보.

var player: Node2D = null
var degraded: bool = false  # ACT3 — 마커가 흐려지고 꺼짐

const DETECT_RADIUS: float = 2200.0           # 이 안의 위협을 VEIL이 본다 (≈ 화면 한 칸 반 너머)
const CALM: Color = Color(0.42, 0.86, 1.0)    # 평시 — VEIL 시안 (자막 색과 통일감)
const WARN: Color = Color(1.0, 0.55, 0.22)    # 공격 임박 — 경고 주황
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
		var wpos: Vector2 = en.global_position
		if ppos.distance_to(wpos) > DETECT_RADIUS:
			continue
		# 공격 임박 여부 — 경고색 + 빠른 펄스.
		var danger: bool = en.has_method("veil_is_telegraphing") and en.veil_is_telegraphing()
		var col: Color = WARN if danger else CALM
		var alpha_mul: float = 1.0
		# ACT3 degradation — 위협별 staggered 깜빡임 + 암점.
		if degraded:
			var phase: float = float(en.get_instance_id() % 997) * 0.0131
			if fmod(_t * 0.9 + phase, 1.0) < 0.34:   # 주기의 1/3은 VEIL이 못 봄 → 마커 꺼짐
				continue
			alpha_mul = clamp(0.5 + 0.3 * sin(_t * 6.0 + phase), 0.22, 0.8)  # 남은 동안도 불안정
		if danger:
			alpha_mul *= 0.7 + 0.3 * sin(_t * 11.0)  # 경고 펄스
		var spos: Vector2 = xform * wpos
		var on_screen: bool = spos.x >= 0.0 and spos.x <= view.x and spos.y >= 0.0 and spos.y <= view.y
		if on_screen:
			# 화면 안 — 요원도 볼 수 있으니 평시엔 은은하게, 위험할 땐 또렷하게.
			var rc: Color = col
			rc.a *= (0.92 if danger else 0.5) * alpha_mul
			_draw_reticle(spos, rc, danger)
		else:
			# 화면 밖 — VEIL의 봄이 빛나는 곳. 또렷하게.
			var ec: Color = col
			ec.a *= alpha_mul
			_draw_edge_arrow(spos, center, view, ec)

func _draw_reticle(pos: Vector2, col: Color, danger: bool) -> void:
	var r: float = RETICLE_R + (4.0 if danger else 0.0)
	var pts: PackedVector2Array = PackedVector2Array([
		pos + Vector2(0.0, -r),
		pos + Vector2(r, 0.0),
		pos + Vector2(0.0, r),
		pos + Vector2(-r, 0.0),
		pos + Vector2(0.0, -r),
	])
	draw_polyline(pts, col, 2.0 if danger else 1.6)

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
