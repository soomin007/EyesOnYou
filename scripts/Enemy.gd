extends CharacterBody2D

signal killed(at_position: Vector2)

enum EnemyType { PATROL, SNIPER, DRONE }

@export var enemy_type: int = EnemyType.PATROL
@export var patrol_range: float = 140.0
@export var hp: int = 2
@export var harmless: bool = false

const PATROL_SPEED: float = 70.0
const GRAVITY: float = 1400.0
const TOUCH_DAMAGE: int = 1
const TOUCH_COOLDOWN: float = 0.6
const DRONE_SPEED: float = 110.0
const SNIPER_FIRE_INTERVAL: float = 2.4

var origin_x: float = 0.0
var dir: int = 1
var touch_cd: float = 0.0
var dead: bool = false
var fire_timer: float = 0.0

var visual: Node2D

func _ready() -> void:
	add_to_group("enemy")
	origin_x = global_position.x
	match enemy_type:
		EnemyType.PATROL:
			hp = 2
			visual = CharacterArt.build_patrol(self)
		EnemyType.SNIPER:
			hp = 1
			visual = CharacterArt.build_sniper(self)
		EnemyType.DRONE:
			hp = 1
			visual = CharacterArt.build_drone(self)

func _flip_visual(facing_left: bool) -> void:
	if visual != null:
		visual.scale.x = -1.0 if facing_left else 1.0

func _physics_process(delta: float) -> void:
	if dead:
		return
	if touch_cd > 0.0:
		touch_cd -= delta
	match enemy_type:
		EnemyType.PATROL:
			_tick_patrol(delta)
		EnemyType.SNIPER:
			_tick_sniper(delta)
		EnemyType.DRONE:
			_tick_drone(delta)
	_check_touch_player()

func _tick_patrol(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 1100.0)
	else:
		velocity.y = 0.0
	velocity.x = float(dir) * PATROL_SPEED
	if global_position.x > origin_x + patrol_range:
		dir = -1
	elif global_position.x < origin_x - patrol_range:
		dir = 1
	if is_on_wall():
		dir = -dir
	_flip_visual(dir < 0)
	move_and_slide()

func _tick_sniper(delta: float) -> void:
	velocity = Vector2.ZERO
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = SNIPER_FIRE_INTERVAL
		_fire_at_player()

func _tick_drone(delta: float) -> void:
	var player := _find_player()
	if player == null:
		return
	var to: Vector2 = player.global_position - global_position
	if to.length() > 4.0:
		velocity = to.normalized() * DRONE_SPEED
		_flip_visual(to.x < 0.0)
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _find_player() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() == 0:
		return null
	return nodes[0] as Node2D

func _fire_at_player() -> void:
	if harmless:
		return
	var player := _find_player()
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist > 520.0:
		return
	if player.has_method("take_hit"):
		player.take_hit(1)

func _check_touch_player() -> void:
	if harmless:
		return
	if touch_cd > 0.0:
		return
	var player := _find_player()
	if player == null:
		return
	if global_position.distance_to(player.global_position) < 36.0:
		if player.has_method("take_hit"):
			player.take_hit(TOUCH_DAMAGE)
			touch_cd = TOUCH_COOLDOWN

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	modulate = Color(1.6, 1.6, 1.6)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	if hp <= 0:
		_die()

func _die() -> void:
	dead = true
	emit_signal("killed", global_position)
	queue_free()
