class_name TutorialDummy
extends StaticBody2D

signal killed(at_position: Vector2)
# 총알이 튕겨나갈 때 emit — Tutorial이 "스킬로 처치하세요" 안내를 띄우게.
signal bullet_deflected

# skill_only: true면 총알(from_dir != 0)은 무시하고 폭발(from_dir == 0)만 받는다.
# Player 코드 분기상 Bullet은 항상 dir(-1/1)을 넘기고, 스킬 폭발은 1-arg 호출(=0).
@export var skill_only: bool = false
var hp: int = 2
var dead: bool = false
var visual: Node2D

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28.0, 40.0)
	col.shape = shape
	col.position = Vector2(0, -20.0)
	add_child(col)
	visual = CharacterArt.build_tutorial_dummy(self)
	# 스킬 전용 더미는 시각적으로 구분 — 약간 주황 + 외곽 광택. "다른 종류"라는 단서.
	if skill_only and visual != null:
		visual.modulate = Color(1.25, 0.85, 0.55)
		var ring := ColorRect.new()
		ring.color = Color(0.95, 0.55, 0.30, 0.55)
		ring.position = Vector2(-22.0, -52.0)
		ring.size = Vector2(44.0, 4.0)
		add_child(ring)

func take_damage(amount: int, from_dir: int = 0) -> void:
	if dead:
		return
	# 스킬 전용 더미 — 총알(from_dir != 0)은 튕겨내고 hp 변화 없음. 시그널로 안내.
	if skill_only and from_dir != 0:
		modulate = Color(1.8, 1.2, 0.6)
		create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.18)
		emit_signal("bullet_deflected")
		return
	hp -= amount
	modulate = Color(1.6, 1.6, 1.6)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	if hp <= 0:
		dead = true
		emit_signal("killed", global_position)
		queue_free()
