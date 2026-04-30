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

static func build_player(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -2), Vector2(20, 5), Color(0, 0, 0, 0.45)))

	var body := Polygon2D.new()
	body.color = Color(0.82, 0.84, 0.88)
	body.polygon = PackedVector2Array([
		Vector2(-9, -46),
		Vector2(9, -46),
		Vector2(12, -28),
		Vector2(10, -10),
		Vector2(8, 0),
		Vector2(2, 0),
		Vector2(0, -8),
		Vector2(-2, 0),
		Vector2(-8, 0),
		Vector2(-10, -10),
		Vector2(-12, -28),
	])
	root.add_child(body)

	var belt := Polygon2D.new()
	belt.color = Color(0.18, 0.20, 0.26)
	belt.polygon = PackedVector2Array([
		Vector2(-12, -30), Vector2(12, -30), Vector2(11, -26), Vector2(-11, -26),
	])
	root.add_child(belt)

	var chest_panel := Polygon2D.new()
	chest_panel.color = Color(0.40, 0.55, 0.70, 0.65)
	chest_panel.polygon = PackedVector2Array([
		Vector2(-5, -42), Vector2(5, -42), Vector2(5, -34), Vector2(-5, -34),
	])
	root.add_child(chest_panel)

	root.add_child(_circle(Vector2(0, -50), 6, Color(0.95, 0.88, 0.78)))

	var helmet := Polygon2D.new()
	helmet.color = Color(0.18, 0.20, 0.25)
	helmet.polygon = PackedVector2Array([
		Vector2(-7, -56), Vector2(7, -56), Vector2(7, -50), Vector2(-7, -50),
	])
	root.add_child(helmet)

	var visor := Polygon2D.new()
	visor.color = Color(0.55, 0.90, 0.95, 0.95)
	visor.polygon = PackedVector2Array([
		Vector2(-5, -50), Vector2(5, -50), Vector2(5, -47), Vector2(-5, -47),
	])
	root.add_child(visor)

	var gun_root := Node2D.new()
	gun_root.name = "Gun"
	root.add_child(gun_root)
	var grip := Polygon2D.new()
	grip.color = Color(0.16, 0.18, 0.22)
	grip.polygon = PackedVector2Array([
		Vector2(4, -38), Vector2(11, -38), Vector2(11, -32), Vector2(4, -32),
	])
	gun_root.add_child(grip)
	var barrel := Polygon2D.new()
	barrel.color = Color(0.30, 0.32, 0.36)
	barrel.polygon = PackedVector2Array([
		Vector2(11, -37), Vector2(13, -37), Vector2(13, -33), Vector2(11, -33),
	])
	gun_root.add_child(barrel)
	return root

static func build_patrol(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -1), Vector2(18, 4), Color(0, 0, 0, 0.45)))

	var body := Polygon2D.new()
	body.color = Color(0.55, 0.18, 0.22)
	body.polygon = PackedVector2Array([
		Vector2(-11, -34), Vector2(11, -34),
		Vector2(13, -22), Vector2(13, -10),
		Vector2(9, 0), Vector2(-9, 0),
		Vector2(-13, -10), Vector2(-13, -22),
	])
	root.add_child(body)

	var head_plate := Polygon2D.new()
	head_plate.color = Color(0.72, 0.22, 0.26)
	head_plate.polygon = PackedVector2Array([
		Vector2(-9, -38), Vector2(9, -38), Vector2(9, -32), Vector2(-9, -32),
	])
	root.add_child(head_plate)

	root.add_child(_circle(Vector2(3, -28), 2.5, Color(1.0, 0.45, 0.45)))

	var stripe := Polygon2D.new()
	stripe.color = Color(0.95, 0.85, 0.4, 0.85)
	stripe.polygon = PackedVector2Array([
		Vector2(-12, -16), Vector2(12, -16), Vector2(12, -13), Vector2(-12, -13),
	])
	root.add_child(stripe)
	return root

static func build_sniper(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	root.add_child(_ellipse(Vector2(0, -1), Vector2(16, 4), Color(0, 0, 0, 0.45)))

	var body := Polygon2D.new()
	body.color = Color(0.62, 0.50, 0.18)
	body.polygon = PackedVector2Array([
		Vector2(-7, -34), Vector2(7, -34),
		Vector2(9, -16), Vector2(7, 0),
		Vector2(-7, 0), Vector2(-9, -16),
	])
	root.add_child(body)

	root.add_child(_circle(Vector2(0, -36), 5, Color(0.92, 0.84, 0.65)))

	var scope := Polygon2D.new()
	scope.color = Color(0.18, 0.20, 0.25)
	scope.polygon = PackedVector2Array([
		Vector2(2, -38), Vector2(11, -38), Vector2(11, -34), Vector2(2, -34),
	])
	root.add_child(scope)
	root.add_child(_circle(Vector2(11, -36), 1.6, Color(1.0, 0.3, 0.3)))

	var rifle := Polygon2D.new()
	rifle.color = Color(0.20, 0.22, 0.26)
	rifle.polygon = PackedVector2Array([
		Vector2(5, -22), Vector2(13, -22), Vector2(13, -19), Vector2(5, -19),
	])
	root.add_child(rifle)
	return root

static func build_drone(parent: Node2D) -> Node2D:
	var root := Node2D.new()
	root.name = "Visual"
	parent.add_child(root)

	var body := Polygon2D.new()
	body.color = Color(0.30, 0.34, 0.55)
	body.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-6, -10), Vector2(6, -10),
		Vector2(12, 0), Vector2(6, 10), Vector2(-6, 10),
	])
	root.add_child(body)

	root.add_child(_circle(Vector2(0, 0), 4, Color(0.55, 0.85, 1.0)))
	root.add_child(_circle(Vector2(0, 0), 2, Color(1.0, 1.0, 1.0)))

	var rotor_l := Polygon2D.new()
	rotor_l.color = Color(0.60, 0.60, 0.70, 0.8)
	rotor_l.polygon = PackedVector2Array([
		Vector2(-16, -1), Vector2(-10, -1), Vector2(-10, 1), Vector2(-16, 1),
	])
	root.add_child(rotor_l)
	var rotor_r := Polygon2D.new()
	rotor_r.color = Color(0.60, 0.60, 0.70, 0.8)
	rotor_r.polygon = PackedVector2Array([
		Vector2(10, -1), Vector2(16, -1), Vector2(16, 1), Vector2(10, 1),
	])
	root.add_child(rotor_r)
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
