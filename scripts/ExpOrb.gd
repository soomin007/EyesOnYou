extends Node2D

const PICKUP_RANGE: float = 220.0
const ATTRACT_SPEED: float = 480.0
const VALUE: int = 1

@onready var sprite: ColorRect = $Sprite

var collected: bool = false
var spawn_anim_t: float = 0.0
var bounce_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("exp_orb")
	bounce_velocity = Vector2(randf_range(-80.0, 80.0), randf_range(-220.0, -120.0))

func _process(delta: float) -> void:
	if collected:
		return
	spawn_anim_t += delta
	if spawn_anim_t < 0.45:
		bounce_velocity.y += 900.0 * delta
		position += bounce_velocity * delta
		return
	var player := _find_player()
	if player == null:
		return
	var to: Vector2 = player.global_position - global_position
	if to.length() < 18.0:
		_collect()
		return
	if to.length() < PICKUP_RANGE:
		position += to.normalized() * ATTRACT_SPEED * delta

func _find_player() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() == 0:
		return null
	return nodes[0] as Node2D

func _collect() -> void:
	collected = true
	var leveled_up: bool = GameState.add_xp(VALUE)
	get_tree().call_group("stage", "_on_xp_collected", leveled_up)
	queue_free()
