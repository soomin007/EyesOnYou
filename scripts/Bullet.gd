class_name Bullet
extends Area2D

# 플레이어 사격으로 발생하는 총알. Player._try_attack에서 spawn.
# 적(layer 4) / 벽(layer 1)과 충돌. piercing 스킬 보유 시 적을 관통.

const BASE_SPEED: float = 900.0
const BASE_LIFETIME: float = 0.55

var dir: int = 1
var damage: int = 1
var pierce: bool = false
var speed_mult: float = 1.0
var lifetime_mult: float = 1.0
var lifetime: float = BASE_LIFETIME
var hit_enemies: Array = []
# 부채꼴 발사용 — 0이면 수평. radian, dir 기준 위/아래로 벌림.
var angle: float = 0.0
# multishot T3 — 가장 가까운 적 방향으로 약하게 휨.
var tracking: bool = false
const TRACKING_BLEND: float = 0.06  # 매 프레임 현재 방향과 타깃 방향을 lerp하는 비율

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4  # 벽 + 적
	body_entered.connect(_on_body_entered)
	z_index = 2
	lifetime = BASE_LIFETIME * lifetime_mult

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14.0, 6.0)
	col.shape = shape
	add_child(col)

	var trail := ColorRect.new()
	trail.color = Color(1.0, 0.92, 0.45, 0.55)
	trail.size = Vector2(20.0, 2.0)
	if dir > 0:
		trail.position = Vector2(-20.0, -1.0)
	else:
		trail.position = Vector2(0.0, -1.0)
	add_child(trail)

	var bullet := ColorRect.new()
	bullet.color = Color(1.0, 0.95, 0.55, 1.0)
	bullet.size = Vector2(10.0, 4.0)
	bullet.position = Vector2(-5.0, -2.0)
	add_child(bullet)

func _process(delta: float) -> void:
	# 진행 벡터 — 수평 베이스(dir) + 각도(angle) 적용. 시각적 회전은 생략(스프라이트가
	# 작아 어색하지 않음).
	if tracking:
		_apply_tracking(delta)
	var vx: float = cos(angle) * float(dir)
	var vy: float = sin(angle)
	position.x += BASE_SPEED * speed_mult * vx * delta
	position.y += BASE_SPEED * speed_mult * vy * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _apply_tracking(_delta: float) -> void:
	# 가장 가까운 적을 찾아 진행 방향을 살짝 그쪽으로 기울인다.
	# bullet의 진행은 (cos(angle)*dir, sin(angle)). 진행이 dir 부호를 따라가니까
	# x 축 부호 자체는 보존하고 y 성분(angle)만 천천히 조정한다.
	var nearest: Node2D = _find_nearest_enemy()
	if nearest == null:
		return
	var dx: float = nearest.global_position.x - global_position.x
	# 적이 진행 방향 반대편이면 추적 안 함 (이미 지나친 적).
	if dx * float(dir) <= 0.0:
		return
	var dy: float = (nearest.global_position.y - 28.0) - global_position.y  # 적 가슴 높이
	# 새 angle 계산: 진행 방향(+dir 쪽)에서 dy/dx 비율로 기울기.
	var target_angle: float = atan2(dy, abs(dx))
	# 너무 급하게 꺾이지 않게 clamp (±25도 안)
	target_angle = clamp(target_angle, -0.43, 0.43)
	angle = lerp(angle, target_angle, TRACKING_BLEND)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_d: float = 99999.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		if e in hit_enemies:
			continue
		var d: float = global_position.distance_to((e as Node2D).global_position)
		if d < min_d:
			min_d = d
			nearest = e as Node2D
	return nearest

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body in hit_enemies:
			return
		hit_enemies.append(body)
		if body.has_method("take_damage"):
			# bullet의 진행 방향(dir)을 전달 — 방패 판정에 사용. 위치(global_position.x)는
			# 충돌 시점에 enemy 안쪽으로 이미 들어가 있어 부호가 어긋날 수 있음.
			body.take_damage(damage, dir)
		if not pierce:
			queue_free()
	elif body is StaticBody2D:
		# 벽/플랫폼 충돌 — 사라짐
		queue_free()
