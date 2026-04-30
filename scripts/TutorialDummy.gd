extends Node2D

signal killed(at_position: Vector2)

var hp: int = 2
var dead: bool = false
var visual: Node2D

func _ready() -> void:
	add_to_group("enemy")
	visual = CharacterArt.build_tutorial_dummy(self)

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	modulate = Color(1.6, 1.6, 1.6)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	if hp <= 0:
		dead = true
		emit_signal("killed", global_position)
		queue_free()
