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

# 외곽선은 형태를 잡아주는 정도로만. 너무 진하면 픽토그램이 아니라 만화책처럼 느껴짐.
const STROKE_COLOR: Color = Color(0.08, 0.10, 0.13, 0.55)
const STROKE_W: float = 0.9

static func build_player(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -2), Vector2(20, 5), Color(0, 0, 0, 0.45)))

	# Torso — Player.gd._update_visual()이 y bob을 적용한다.
	var torso := Node2D.new()
	torso.name = "Torso"
	root.add_child(torso)

	# 5두신 비례 — 머리 14 / 상체 22 / 다리 16 / 신발 4. 가랑이 -20.
	# 이전엔 다리(28) > 상체(18)라 "상체 없는" 인상이었음.
	# 상체(어깨 -42 ~ 가랑이 -20) — V형 어깨~허리.
	_filled(torso, Color(0.82, 0.84, 0.88), PackedVector2Array([
		Vector2(-11, -42), Vector2(11, -42),
		Vector2(10, -32), Vector2(9, -20),
		Vector2(-9, -20), Vector2(-10, -32),
	]))

	# 다리 — 가랑이 origin인 LegL/LegR Node2D로 분리. 평행 직사각형
	# (이전 무릎 부분이 바깥으로 휘어 오다리처럼 보였음). Player.gd가
	# 이 노드를 회전시켜 걷기 애니메이션을 만든다(번갈아 swing).
	var leg_l := Node2D.new()
	leg_l.name = "LegL"
	leg_l.position = Vector2(-6, -20)
	torso.add_child(leg_l)
	_filled(leg_l, Color(0.78, 0.80, 0.84), PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0),
		Vector2(3, 16), Vector2(-3, 16),
	]))
	_filled(leg_l, Color(0.16, 0.18, 0.22), PackedVector2Array([
		Vector2(-4, 16), Vector2(4, 16),
		Vector2(4, 20), Vector2(-4, 20),
	]))

	var leg_r := Node2D.new()
	leg_r.name = "LegR"
	leg_r.position = Vector2(6, -20)
	torso.add_child(leg_r)
	_filled(leg_r, Color(0.84, 0.86, 0.90), PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0),
		Vector2(3, 16), Vector2(-3, 16),
	]))
	_filled(leg_r, Color(0.16, 0.18, 0.22), PackedVector2Array([
		Vector2(-4, 16), Vector2(4, 16),
		Vector2(4, 20), Vector2(-4, 20),
	]))

	# 어깨 패드 — 어깨 라인(-42)에서 살짝 바깥으로
	_filled(torso, Color(0.50, 0.54, 0.62), PackedVector2Array([
		Vector2(-13, -42), Vector2(-7, -42), Vector2(-8, -36), Vector2(-13, -36),
	]))
	_filled(torso, Color(0.50, 0.54, 0.62), PackedVector2Array([
		Vector2(7, -42), Vector2(13, -42), Vector2(13, -36), Vector2(8, -36),
	]))

	# 벨트 — 허리(-25 ~ -20) 5px. 짙은 색 + 상단 highlight로 허리 라인 명확.
	_filled(torso, Color(0.10, 0.12, 0.16), PackedVector2Array([
		Vector2(-10, -25), Vector2(10, -25), Vector2(10, -20), Vector2(-10, -20),
	]))
	var belt_hl := Polygon2D.new()
	belt_hl.color = Color(0.55, 0.65, 0.78, 0.45)
	belt_hl.polygon = PackedVector2Array([
		Vector2(-10, -25), Vector2(10, -25), Vector2(10, -24), Vector2(-10, -24),
	])
	torso.add_child(belt_hl)
	# 벨트 버클
	_filled(torso, Color(0.85, 0.78, 0.50), PackedVector2Array([
		Vector2(-2.5, -24), Vector2(2.5, -24), Vector2(2.5, -21), Vector2(-2.5, -21),
	]))

	# 가슴 패널 — 어깨 -42 ~ 벨트 위 -28 (14px 길게)
	_filled(torso, Color(0.40, 0.55, 0.70, 0.85), PackedVector2Array([
		Vector2(-5, -38), Vector2(5, -38), Vector2(5, -28), Vector2(-5, -28),
	]))
	# 가슴 LED
	_filled_circle(torso, Vector2(0, -33), 1.4, Color(0.75, 1.0, 1.0))

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

	# 뒷팔 — 어깨 -38 ~ 허리 -28
	_filled(torso, Color(0.62, 0.64, 0.70), PackedVector2Array([
		Vector2(-11, -38), Vector2(-7, -38), Vector2(-7, -28), Vector2(-11, -28),
	]))

	# 앞팔 + 총 — ArmFront origin이 손목 부근(10, -32) — 어깨에서 허리 사이.
	# 회전 시 총구가 살짝 위/아래로 흔들리도록.
	var arm_front := Node2D.new()
	arm_front.name = "ArmFront"
	arm_front.position = Vector2(10, -32)
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
	# 사격 연습용 목제 더미. 좌표는 origin(0)이 ground level이라는 전제.
	# 받침대 바닥 = y=0(지면), 본체는 받침대 위, 머리는 본체 위.
	var root := Node2D.new()
	parent.add_child(root)
	# 받침대 — 받침대 윗면 y=-6, 바닥 y=0 (지면에 정확히 닿음).
	_filled(root, Color(0.32, 0.28, 0.25), PackedVector2Array([
		Vector2(-18, -6), Vector2(18, -6), Vector2(20, 0), Vector2(-20, 0),
	]))
	# 본체 (사다리꼴, 짚단/모래주머니 톤). 바닥 y=-6 (받침대 윗면 위), 윗면 y=-44.
	_filled(root, Color(0.72, 0.62, 0.45), PackedVector2Array([
		Vector2(-12, -44), Vector2(12, -44), Vector2(15, -6), Vector2(-15, -6),
	]))
	# 어깨 / 머리 영역 y=-58 ~ -44.
	_filled(root, Color(0.65, 0.55, 0.40), PackedVector2Array([
		Vector2(-10, -58), Vector2(10, -58), Vector2(12, -44), Vector2(-12, -44),
	]))
	# 흰색 X 봉합 자국 (직물/짚단 느낌)
	var stitch1 := Line2D.new()
	stitch1.points = PackedVector2Array([Vector2(-8, -38), Vector2(8, -14)])
	stitch1.width = 1.2
	stitch1.default_color = Color(0.92, 0.88, 0.78, 0.85)
	root.add_child(stitch1)
	var stitch2 := Line2D.new()
	stitch2.points = PackedVector2Array([Vector2(8, -38), Vector2(-8, -14)])
	stitch2.width = 1.2
	stitch2.default_color = Color(0.92, 0.88, 0.78, 0.85)
	root.add_child(stitch2)
	# 중앙 과녁 — 가슴(본체 중심) y=-26 부근.
	var bull_outer := Polygon2D.new()
	bull_outer.color = Color(0.85, 0.30, 0.30, 0.85)
	bull_outer.polygon = _circle_pts(7.0, 18, Vector2(0, -26))
	root.add_child(bull_outer)
	var bull_inner := Polygon2D.new()
	bull_inner.color = Color(0.95, 0.92, 0.45, 0.95)
	bull_inner.polygon = _circle_pts(3.0, 14, Vector2(0, -26))
	root.add_child(bull_inner)
	return root

static func _circle_pts(radius: float, n: int, center: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in n:
		var a: float = float(i) * TAU / float(n)
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	return pts

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
