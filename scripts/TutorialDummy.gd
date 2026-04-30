extends Node2D

signal killed

var hp: int = 2
var dead: bool = false

func _ready() -> void:
	add_to_group("enemy")
	var sprite := Sprite2D.new()
	sprite.name = "Visual"
	var tex: Texture2D = load("res://assets/sprites/patrol.png") as Texture2D
	if tex != null:
		sprite.texture = tex
		sprite.scale = Vector2(0.36, 0.36)
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/remove_white.gdshader")
		sprite.material = mat
	else:
		var fallback := PlaceholderTexture2D.new()
		fallback.size = Vector2(56, 160)
		sprite.texture = fallback
		sprite.modulate = Color(0.85, 0.30, 0.30)
	sprite.position = Vector2(0, -72.0)
	add_child(sprite)

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	modulate = Color(1.5, 1.5, 1.5)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	if hp <= 0:
		dead = true
		emit_signal("killed")
		queue_free()
