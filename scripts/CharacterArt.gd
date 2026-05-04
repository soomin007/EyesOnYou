class_name CharacterArt
extends RefCounted

# 모든 캐릭터는 body origin (0,0)이 발 중앙에 오도록 그린다.
# 시각 경계는 콜리전 박스와 정확히 일치하도록 제한한다.
#   Player: 28w × 56h  → x ∈ [-14, 14], y ∈ [-56, 0]
#   Patrol: 28w × 40h  → x ∈ [-14, 14], y ∈ [-40, 0]
#   Sniper: 28w × 40h  → x ∈ [-14, 14], y ∈ [-40, 0]
#   Drone:  32w × 24h  → x ∈ [-16, 16], y ∈ [-12, 12]
#
# 모든 함수는 parent에 자식 Node2D("Visual")을 추가하고 그 노드를 반환한다.
# 좌우 반전은 returned root의 scale.x = -1 로 처리한다.
#
# 도형 위에 어두운 외곽선(Line2D)을 얹어 픽토그램 톤을 만든다 — _filled 헬퍼.
# Player는 Torso/ArmFront 컨테이너 분리 → Player.gd가 idle bob/총 회전 적용.

const STROKE_COLOR: Color = Color(0.05, 0.06, 0.08, 0.95)
const STROKE_W: float = 1.6

static func build_player(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -2), Vector2(20, 5), Color(0, 0, 0, 0.45)))

	# Torso — Player.gd._update_visual()이 y bob을 적용한다.
	var torso := Node2D.new()
	torso.name = "Torso"
	root.add_child(torso)

	# 상체(어깨~가랑이) — 두 다리는 별도 polygon으로 분리해 다리답게.
	_filled(torso, Color(0.82, 0.84, 0.88), PackedVector2Array([
		Vector2(-11, -46), Vector2(11, -46),
		Vector2(10, -36), Vector2(9, -28),
		Vector2(-9, -28), Vector2(-10, -36),
	]))

	# 왼 다리 — 허벅지 너비 6 → 정강이 4 (무릎에서 살짝 좁아짐).
	_filled(torso, Color(0.78, 0.80, 0.84), PackedVector2Array([
		Vector2(-9, -28), Vector2(-3, -28),
		Vector2(-3, -16),
		Vector2(-3, -4),
		Vector2(-7, -4),
		Vector2(-7, -16),
	]))
	# 오른 다리 — 좌우 대칭. 색상 살짝 밝게(앞다리 인상).
	_filled(torso, Color(0.84, 0.86, 0.90), PackedVector2Array([
		Vector2(3, -28), Vector2(9, -28),
		Vector2(7, -16),
		Vector2(7, -4),
		Vector2(3, -4),
		Vector2(3, -16),
	]))
	# 왼 신발
	_filled(torso, Color(0.16, 0.18, 0.22), PackedVector2Array([
		Vector2(-9, -4), Vector2(-2, -4),
		Vector2(-2, 0), Vector2(-9, 0),
	]))
	# 오른 신발
	_filled(torso, Color(0.16, 0.18, 0.22), PackedVector2Array([
		Vector2(2, -4), Vector2(9, -4),
		Vector2(9, 0), Vector2(2, 0),
	]))

	# 어깨 패드 (양쪽) — 어깨 11 비례에 맞춰 살짝 바깥으로 돌출
	_filled(torso, Color(0.50, 0.54, 0.62), PackedVector2Array([
		Vector2(-13, -46), Vector2(-7, -46), Vector2(-8, -40), Vector2(-13, -40),
	]))
	_filled(torso, Color(0.50, 0.54, 0.62), PackedVector2Array([
		Vector2(7, -46), Vector2(13, -46), Vector2(13, -40), Vector2(8, -40),
	]))

	# 벨트 — 허리 라인(가랑이 위)
	_filled(torso, Color(0.18, 0.20, 0.26), PackedVector2Array([
		Vector2(-10, -34), Vector2(10, -34), Vector2(9, -28), Vector2(-9, -28),
	]))
	# 벨트 버클
	_filled(torso, Color(0.85, 0.78, 0.50), PackedVector2Array([
		Vector2(-2, -33), Vector2(2, -33), Vector2(2, -30), Vector2(-2, -30),
	]))

	# 가슴 패널
	_filled(torso, Color(0.40, 0.55, 0.70, 0.85), PackedVector2Array([
		Vector2(-5, -42), Vector2(5, -42), Vector2(5, -34), Vector2(-5, -34),
	]))
	# 가슴 LED
	_filled_circle(torso, Vector2(0, -38), 1.4, Color(0.75, 1.0, 1.0))

	# 머리 (얼굴) — radius 6 → 7
	_filled_circle(torso, Vector2(0, -50), 7.0, Color(0.95, 0.88, 0.78))

	# 헬멧 — 둥근 윗면
	_filled(torso, Color(0.18, 0.20, 0.25), PackedVector2Array([
		Vector2(-7, -56), Vector2(-6, -58), Vector2(6, -58), Vector2(7, -56),
		Vector2(7, -50), Vector2(-7, -50),
	]))
	# 챙 (전면 돌출)
	_filled(torso, Color(0.10, 0.11, 0.14), PackedVector2Array([
		Vector2(-8, -52), Vector2(8, -52), Vector2(7, -50), Vector2(-7, -50),
	]))
	# 바이저
	_filled(torso, Color(0.55, 0.90, 0.95, 0.95), PackedVector2Array([
		Vector2(-5, -50), Vector2(5, -50), Vector2(5, -47), Vector2(-5, -47),
	]))
	# 바이저 하이라이트 — stroke 없는 작은 띠
	var hl := Polygon2D.new()
	hl.color = Color(1.0, 1.0, 1.0, 0.55)
	hl.polygon = PackedVector2Array([
		Vector2(-4, -49), Vector2(-1, -49), Vector2(-1, -48), Vector2(-4, -48),
	])
	torso.add_child(hl)

	# 뒷팔
	_filled(torso, Color(0.62, 0.64, 0.70), PackedVector2Array([
		Vector2(-11, -42), Vector2(-7, -42), Vector2(-7, -32), Vector2(-11, -32),
	]))

	# 앞팔 + 총 — ArmFront origin이 손목 부근(10, -36)
	# 회전 시 총구가 어깨를 중심으로 살짝 위/아래로 흔들리도록.
	var arm_front := Node2D.new()
	arm_front.name = "ArmFront"
	arm_front.position = Vector2(10, -36)
	torso.add_child(arm_front)
	# 그립
	_filled(arm_front, Color(0.16, 0.18, 0.22), PackedVector2Array([
		Vector2(-6, -2), Vector2(1, -2), Vector2(1, 4), Vector2(-6, 4),
	]))
	# 총신
	_filled(arm_front, Color(0.30, 0.32, 0.36), PackedVector2Array([
		Vector2(1, -1), Vector2(3, -1), Vector2(3, 3), Vector2(1, 3),
	]))
	# Gun 명명 유지(외부 참조 호환)
	arm_front.add_to_group("gun_anchor")

	return root

static func build_patrol(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -1), Vector2(18, 4), Color(0, 0, 0, 0.45)))

	var torso := Node2D.new()
	torso.name = "Torso"
	root.add_child(torso)

	_filled(torso, Color(0.55, 0.18, 0.22), PackedVector2Array([
		Vector2(-11, -34), Vector2(11, -34),
		Vector2(13, -22), Vector2(13, -10),
		Vector2(9, 0), Vector2(-9, 0),
		Vector2(-13, -10), Vector2(-13, -22),
	]))

	# 어깨 패드
	_filled(torso, Color(0.40, 0.10, 0.14), PackedVector2Array([
		Vector2(-13, -34), Vector2(-9, -34), Vector2(-9, -28), Vector2(-13, -28),
	]))
	_filled(torso, Color(0.40, 0.10, 0.14), PackedVector2Array([
		Vector2(9, -34), Vector2(13, -34), Vector2(13, -28), Vector2(9, -28),
	]))

	# 머리 플레이트
	_filled(torso, Color(0.72, 0.22, 0.26), PackedVector2Array([
		Vector2(-9, -38), Vector2(-8, -40), Vector2(8, -40), Vector2(9, -38),
		Vector2(9, -32), Vector2(-9, -32),
	]))
	# 외눈 (적색)
	_filled_circle(torso, Vector2(3, -36), 2.5, Color(1.0, 0.45, 0.45))

	# 가슴 띠
	_filled(torso, Color(0.95, 0.85, 0.4, 0.9), PackedVector2Array([
		Vector2(-12, -16), Vector2(12, -16), Vector2(12, -13), Vector2(-12, -13),
	]))
	return root

static func build_sniper(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -1), Vector2(16, 4), Color(0, 0, 0, 0.45)))

	var torso := Node2D.new()
	torso.name = "Torso"
	root.add_child(torso)

	_filled(torso, Color(0.62, 0.50, 0.18), PackedVector2Array([
		Vector2(-7, -34), Vector2(7, -34),
		Vector2(9, -16), Vector2(7, 0),
		Vector2(-7, 0), Vector2(-9, -16),
	]))

	# 등 망토 라인
	_filled(torso, Color(0.42, 0.32, 0.10), PackedVector2Array([
		Vector2(-9, -16), Vector2(9, -16), Vector2(8, -8), Vector2(-8, -8),
	]))

	# 머리
	_filled_circle(torso, Vector2(0, -36), 5.5, Color(0.92, 0.84, 0.65))

	# 스코프 (상단)
	_filled(torso, Color(0.18, 0.20, 0.25), PackedVector2Array([
		Vector2(2, -38), Vector2(11, -38), Vector2(11, -34), Vector2(2, -34),
	]))
	# 레이저 도트 (작은 빨간 원, stroke 없음)
	var dot := Polygon2D.new()
	dot.color = Color(1.0, 0.3, 0.3)
	var dpts: Array = []
	for i in 8:
		var ang: float = float(i) * TAU / 8.0
		dpts.append(Vector2(11, -36) + Vector2(cos(ang) * 1.6, sin(ang) * 1.6))
	dot.polygon = PackedVector2Array(dpts)
	torso.add_child(dot)

	# 라이플
	_filled(torso, Color(0.20, 0.22, 0.26), PackedVector2Array([
		Vector2(5, -22), Vector2(13, -22), Vector2(13, -19), Vector2(5, -19),
	]))
	return root

static func build_drone(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	# Drone은 공중에 떠 있으므로 그림자는 별도 처리(현재 없음).
	var torso := Node2D.new()
	torso.name = "Torso"
	root.add_child(torso)

	_filled(torso, Color(0.30, 0.34, 0.55), PackedVector2Array([
		Vector2(-12, 0), Vector2(-6, -10), Vector2(6, -10),
		Vector2(12, 0), Vector2(6, 10), Vector2(-6, 10),
	]))

	# 카메라 렌즈
	_filled_circle(torso, Vector2(0, 0), 4.5, Color(0.55, 0.85, 1.0))
	var pupil := Polygon2D.new()
	pupil.color = Color(1.0, 1.0, 1.0, 0.95)
	var ppts: Array = []
	for i in 12:
		var ang: float = float(i) * TAU / 12.0
		ppts.append(Vector2(cos(ang) * 1.8, sin(ang) * 1.8))
	pupil.polygon = PackedVector2Array(ppts)
	torso.add_child(pupil)

	# 좌우 로터 — 회전 가능하도록 노드로 분리
	var rotor_l := Node2D.new()
	rotor_l.name = "RotorL"
	rotor_l.position = Vector2(-13, 0)
	torso.add_child(rotor_l)
	_filled(rotor_l, Color(0.60, 0.60, 0.70, 0.85), PackedVector2Array([
		Vector2(-3, -1), Vector2(3, -1), Vector2(3, 1), Vector2(-3, 1),
	]))
	var rotor_r := Node2D.new()
	rotor_r.name = "RotorR"
	rotor_r.position = Vector2(13, 0)
	torso.add_child(rotor_r)
	_filled(rotor_r, Color(0.60, 0.60, 0.70, 0.85), PackedVector2Array([
		Vector2(-3, -1), Vector2(3, -1), Vector2(3, 1), Vector2(-3, 1),
	]))
	return root

static func build_bomber(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -1), Vector2(16, 4), Color(0, 0, 0, 0.45)))

	var torso := Node2D.new()
	torso.name = "Torso"
	root.add_child(torso)

	_filled(torso, Color(0.32, 0.30, 0.34), PackedVector2Array([
		Vector2(-10, -34), Vector2(10, -34),
		Vector2(12, -22), Vector2(11, -10),
		Vector2(8, 0), Vector2(-8, 0),
		Vector2(-11, -10), Vector2(-12, -22),
	]))

	# 머리
	_filled(torso, Color(0.42, 0.40, 0.45), PackedVector2Array([
		Vector2(-7, -38), Vector2(-6, -40), Vector2(6, -40), Vector2(7, -38),
		Vector2(7, -32), Vector2(-7, -32),
	]))
	# 헬멧 줄무늬
	_filled(torso, Color(0.85, 0.30, 0.30, 0.95), PackedVector2Array([
		Vector2(-7, -36), Vector2(7, -36), Vector2(7, -34), Vector2(-7, -34),
	]))

	# 가슴 폭탄
	_filled_circle(torso, Vector2(0, -22), 5.5, Color(0.85, 0.20, 0.22))
	var cross_v := Polygon2D.new()
	cross_v.color = Color(1, 1, 1, 0.95)
	cross_v.polygon = PackedVector2Array([
		Vector2(-1, -27), Vector2(1, -27), Vector2(1, -17), Vector2(-1, -17),
	])
	torso.add_child(cross_v)
	var cross_h := Polygon2D.new()
	cross_h.color = Color(1, 1, 1, 0.95)
	cross_h.polygon = PackedVector2Array([
		Vector2(-5, -23), Vector2(5, -23), Vector2(5, -21), Vector2(-5, -21),
	])
	torso.add_child(cross_h)
	return root

static func build_shield(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -1), Vector2(20, 4), Color(0, 0, 0, 0.5)))

	var torso := Node2D.new()
	torso.name = "Torso"
	root.add_child(torso)

	_filled(torso, Color(0.30, 0.36, 0.42), PackedVector2Array([
		Vector2(-10, -34), Vector2(10, -34),
		Vector2(12, -22), Vector2(11, -10),
		Vector2(8, 0), Vector2(-8, 0),
		Vector2(-11, -10), Vector2(-12, -22),
	]))

	# 어깨 패드
	_filled(torso, Color(0.20, 0.24, 0.28), PackedVector2Array([
		Vector2(-12, -34), Vector2(-8, -34), Vector2(-8, -28), Vector2(-12, -28),
	]))
	_filled(torso, Color(0.20, 0.24, 0.28), PackedVector2Array([
		Vector2(8, -34), Vector2(12, -34), Vector2(12, -28), Vector2(8, -28),
	]))

	# 머리
	_filled_circle(torso, Vector2(0, -36), 5.5, Color(0.42, 0.46, 0.50))
	# 바이저(빨간 띠)
	_filled(torso, Color(0.85, 0.30, 0.30, 0.95), PackedVector2Array([
		Vector2(-3, -37), Vector2(3, -37), Vector2(3, -35), Vector2(-3, -35),
	]))

	# 방패 — Enemy.gd가 "Shield" 이름으로 참조
	var shield := Node2D.new()
	shield.name = "Shield"
	torso.add_child(shield)
	_filled(shield, Color(0.55, 0.60, 0.66), PackedVector2Array([
		Vector2(11, -38), Vector2(17, -38),
		Vector2(17, -4), Vector2(11, -4),
	]))
	# 보스(중앙 돌기)
	_filled(shield, Color(0.78, 0.82, 0.88), PackedVector2Array([
		Vector2(13, -24), Vector2(15, -24), Vector2(15, -18), Vector2(13, -18),
	]))
	return root

static func build_tutorial_dummy(parent: Node2D) -> Node2D:
	var root := build_patrol(parent)
	var ghost := Polygon2D.new()
	ghost.color = Color(0.95, 0.95, 0.95, 0.18)
	ghost.polygon = PackedVector2Array([
		Vector2(-13, -38), Vector2(13, -38), Vector2(13, 0), Vector2(-13, 0),
	])
	root.add_child(ghost)
	return root

# ─── 헬퍼 ───────────────────────────────────────────────

# 채워진 폴리곤 + 어두운 외곽선(Line2D, closed=true)을 함께 그린다.
# 외곽선은 폴리곤 위에 얹혀 시각적으로 "픽토그램" 톤을 만든다.
static func _filled(parent: Node2D, fill_color: Color, points: PackedVector2Array) -> Polygon2D:
	var fill := Polygon2D.new()
	fill.color = fill_color
	fill.polygon = points
	parent.add_child(fill)
	var line := Line2D.new()
	line.points = points
	line.closed = true
	line.width = STROKE_W
	line.default_color = STROKE_COLOR
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.antialiased = true
	parent.add_child(line)
	return fill

# 외곽선 포함 원 — 다각형으로 근사.
static func _filled_circle(parent: Node2D, center: Vector2, radius: float, color: Color, segments: int = 16) -> Polygon2D:
	var pts: Array = []
	for i in segments:
		var a: float = float(i) * TAU / float(segments)
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	return _filled(parent, color, PackedVector2Array(pts))

# stroke 없는 원(그림자 등에 사용).
static func _circle(center: Vector2, radius: float, color: Color, segments: int = 16) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = color
	var pts: Array = []
	for i in segments:
		var a: float = float(i) * TAU / float(segments)
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	p.polygon = PackedVector2Array(pts)
	return p

static func _ellipse(center: Vector2, half_size: Vector2, color: Color, segments: int = 16) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = color
	var pts: Array = []
	for i in segments:
		var a: float = float(i) * TAU / float(segments)
		pts.append(center + Vector2(cos(a) * half_size.x, sin(a) * half_size.y))
	p.polygon = PackedVector2Array(pts)
	return p
