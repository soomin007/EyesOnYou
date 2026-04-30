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
const SNIPER_FIRE_INTERVAL: float = 2.6
const SNIPER_AIM_TIME: float = 0.7  # 발사 전 조준 라인 노출 시간

var origin_x: float = 0.0
var dir: int = 1
var touch_cd: float = 0.0
var dead: bool = false
var fire_timer: float = 0.0
var aim_line: Line2D

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
	if fire_timer < SNIPER_AIM_TIME and aim_line == null:
		_start_aim()
	if aim_line != null:
		_update_aim()
	if fire_timer <= 0.0:
		fire_timer = SNIPER_FIRE_INTERVAL
		_fire_at_player()
		_clear_aim()

func _start_aim() -> void:
	aim_line = Line2D.new()
	aim_line.width = 1.0
	aim_line.default_color = Color(1.0, 0.30, 0.30, 0.55)
	aim_line.z_index = 1
	get_parent().add_child(aim_line)

func _update_aim() -> void:
	if aim_line == null:
		return
	var p := _find_player()
	if p == null:
		return
	aim_line.clear_points()
	aim_line.add_point(global_position + Vector2(0, -20))
	aim_line.add_point(p.global_position + Vector2(0, -28))

func _clear_aim() -> void:
	if aim_line != null:
		aim_line.queue_free()
		aim_line = null

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
	# 가시 트레이서 — 어디서 맞았는지 알 수 있도록
	var tracer := Line2D.new()
	tracer.width = 2.5
	tracer.default_color = Color(1.0, 0.55, 0.30, 1.0)
	tracer.z_index = 2
	tracer.add_point(global_position + Vector2(0, -20))
	tracer.add_point(player.global_position + Vector2(0, -28))
	get_parent().add_child(tracer)
	var tw := tracer.create_tween()
	tw.tween_property(tracer, "default_color", Color(1.0, 0.55, 0.30, 0.0), 0.30)
	tw.tween_callback(tracer.queue_free)
	if player.has_method("take_hit"):
		player.take_hit(1)

func _exit_tree() -> void:
	_clear_aim()

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
