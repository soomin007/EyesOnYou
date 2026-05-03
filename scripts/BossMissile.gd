extends Area2D

# 보스 SENTINEL 측면 미사일. 수평으로 등속 비행, 벽 충돌 시 파괴, 플레이어 닿으면 데미지 1.

const DAMAGE: int = 1
const LIFETIME: float = 4.0

var velocity: Vector2 = Vector2.ZERO
var t: float = 0.0
var consumed: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2  # 벽/플랫폼 + 플레이어
	body_entered.connect(_on_body_entered)
	z_index = 2
	# 시각 — 빨간 작은 막대 + 후미 광점
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20.0, 8.0)
	col.shape = shape
	add_child(col)
	var body := ColorRect.new()
	body.color = Color(0.95, 0.30, 0.30)
	body.position = Vector2(-10.0, -4.0)
	body.size = Vector2(20.0, 8.0)
	add_child(body)
	var glow := ColorRect.new()
	glow.color = Color(1.0, 0.55, 0.30, 0.55)
	glow.position = Vector2(-14.0, -3.0)
	glow.size = Vector2(6.0, 6.0)
	add_child(glow)
	# 진행 방향에 맞춰 좌우 반전 (velocity.x 음수면 글로우 우측에)
	if velocity.x < 0.0:
		body.position = Vector2(-10.0, -4.0)
		glow.position = Vector2(8.0, -3.0)

func _process(delta: float) -> void:
	if consumed:
		return
	t += delta
	position += velocity * delta
	if t >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if consumed:
		return
	consumed = true
	if body.is_in_group("player") and body.has_method("take_hit"):
		body.take_hit(DAMAGE)
	queue_free()
