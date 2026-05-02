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
	position.x += BASE_SPEED * speed_mult * float(dir) * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body in hit_enemies:
			return
		hit_enemies.append(body)
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position.x)
		if not pierce:
			queue_free()
	elif body is StaticBody2D:
		# 벽/플랫폼 충돌 — 사라짐
		queue_free()
