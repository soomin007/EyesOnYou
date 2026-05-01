extends CharacterBody2D

signal killed(at_position: Vector2)

enum EnemyType { PATROL, SNIPER, DRONE }
enum PatrolState { ROAMING, TELEGRAPH, CHARGING, RECOVERING }

@export var enemy_type: int = EnemyType.PATROL
@export var patrol_range: float = 140.0
@export var hp: int = 2
@export var harmless: bool = false

const GRAVITY: float = 1400.0
const TOUCH_DAMAGE: int = 1
const TOUCH_COOLDOWN: float = 0.6

# Patrol — 평소 순찰 + 근접 시 텔레그래프 후 돌진
const PATROL_SPEED: float = 70.0
const PATROL_CHARGE_SPEED: float = 280.0
const PATROL_DETECT_X: float = 260.0
const PATROL_DETECT_Y: float = 70.0
const PATROL_TELEGRAPH: float = 0.45
const PATROL_CHARGE_DURATION: float = 0.6
const PATROL_RECOVERY: float = 1.0

# Sniper — 시야가 트여 있을 때만 발사
const SNIPER_FIRE_INTERVAL: float = 2.6
const SNIPER_AIM_TIME: float = 0.7
const SNIPER_RANGE: float = 520.0

# Drone — 머리 위 호버 후 폭탄 투하
const DRONE_SPEED: float = 110.0
const DRONE_HOVER_OFFSET_Y: float = -180.0
const DRONE_BOMB_INTERVAL: float = 2.5
const DRONE_BOMB_X_BAND: float = 90.0
const DRONE_BOMB_Y_MIN: float = 80.0
const DRONE_BOMB_Y_MAX: float = 240.0

# 도감 — 화면 안에 들어와야 트리거되도록 거리/높이 제한
const ENCOUNTER_X_LIMIT: float = 480.0
const ENCOUNTER_Y_LIMIT: float = 280.0

var origin_x: float = 0.0
var dir: int = 1
var touch_cd: float = 0.0
var dead: bool = false

var patrol_state: int = PatrolState.ROAMING
var patrol_state_timer: float = 0.0

var fire_timer: float = 0.0
var aim_line: Line2D
var aim_los_clear: bool = false

var drone_bomb_cd: float = 0.0

var encountered: bool = false
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
	fire_timer = _sniper_interval()
	drone_bomb_cd = 1.2  # 스폰 직후 즉시 폭격 방지

# Risk 3 루트에서는 적이 더 빨리 반응한다.
# 수치는 보수적으로 잡았으니 플레이테스트 후 조정 필요 (상의 항목).
func _telegraph_time() -> float:
	return PATROL_TELEGRAPH * (0.6 if GameState.is_high_risk() else 1.0)

func _sniper_interval() -> float:
	return SNIPER_FIRE_INTERVAL * (0.7 if GameState.is_high_risk() else 1.0)

func _drone_bomb_interval() -> float:
	return DRONE_BOMB_INTERVAL * (0.7 if GameState.is_high_risk() else 1.0)

func _enemy_id() -> String:
	match enemy_type:
		EnemyType.PATROL: return "patrol"
		EnemyType.SNIPER: return "sniper"
		EnemyType.DRONE: return "drone"
	return ""

func _flip_visual(facing_left: bool) -> void:
	if visual != null:
		visual.scale.x = -1.0 if facing_left else 1.0

func _physics_process(delta: float) -> void:
	if dead:
		return
	if touch_cd > 0.0:
		touch_cd -= delta
	_check_first_encounter()
	match enemy_type:
		EnemyType.PATROL:
			_tick_patrol(delta)
		EnemyType.SNIPER:
			_tick_sniper(delta)
		EnemyType.DRONE:
			_tick_drone(delta)
	_check_touch_player()

# ─── 도감 첫 조우 ───────────────────────────────────────────

func _check_first_encounter() -> void:
	if encountered or harmless:
		return
	if BestiaryOverlay.is_active():
		return
	var p := _find_player()
	if p == null:
		return
	var dx: float = abs(p.global_position.x - global_position.x)
	var dy: float = abs(p.global_position.y - global_position.y)
	if dx > ENCOUNTER_X_LIMIT or dy > ENCOUNTER_Y_LIMIT:
		return
	var stage_node := get_tree().get_first_node_in_group("stage")
	if stage_node == null:
		return
	encountered = true
	var id: String = _enemy_id()
	if not GameState.mark_enemy_seen(id):
		return  # 이미 본 적이라 카드 안 띄움
	BestiaryOverlay.show_card(stage_node, id)

# ─── Patrol ─────────────────────────────────────────────────

func _tick_patrol(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 1100.0)
	else:
		velocity.y = 0.0

	var p := _find_player()

	match patrol_state:
		PatrolState.ROAMING:
			velocity.x = float(dir) * PATROL_SPEED
			if global_position.x > origin_x + patrol_range:
				dir = -1
			elif global_position.x < origin_x - patrol_range:
				dir = 1
			if is_on_wall():
				dir = -dir
			if not harmless and p != null and _player_in_charge_range(p):
				dir = 1 if p.global_position.x > global_position.x else -1
				patrol_state = PatrolState.TELEGRAPH
				patrol_state_timer = _telegraph_time()
				velocity.x = 0.0
		PatrolState.TELEGRAPH:
			velocity.x = 0.0
			patrol_state_timer -= delta
			# 머리/몸 빨갛게 깜빡 — 돌진 예고
			if visual != null:
				if int(patrol_state_timer * 10.0) % 2 == 0:
					visual.modulate = Color(1.6, 0.55, 0.55)
				else:
					visual.modulate = Color(1, 1, 1)
			if patrol_state_timer <= 0.0:
				if visual != null:
					visual.modulate = Color(1, 1, 1)
				patrol_state = PatrolState.CHARGING
				patrol_state_timer = PATROL_CHARGE_DURATION
		PatrolState.CHARGING:
			velocity.x = float(dir) * PATROL_CHARGE_SPEED
			patrol_state_timer -= delta
			if is_on_wall() or patrol_state_timer <= 0.0:
				patrol_state = PatrolState.RECOVERING
				patrol_state_timer = PATROL_RECOVERY
				velocity.x = 0.0
		PatrolState.RECOVERING:
			velocity.x = 0.0
			patrol_state_timer -= delta
			if patrol_state_timer <= 0.0:
				origin_x = global_position.x  # 돌진 후 새 위치 기준으로 순찰
				patrol_state = PatrolState.ROAMING

	_flip_visual(dir < 0)
	move_and_slide()

func _player_in_charge_range(p: Node2D) -> bool:
	var dx: float = abs(p.global_position.x - global_position.x)
	var dy: float = abs(p.global_position.y - global_position.y)
	return dx <= PATROL_DETECT_X and dy <= PATROL_DETECT_Y

# ─── Sniper ─────────────────────────────────────────────────

func _tick_sniper(delta: float) -> void:
	velocity = Vector2.ZERO
	var p := _find_player()
	if p == null:
		_clear_aim()
		return
	var dist: float = global_position.distance_to(p.global_position)
	if dist > SNIPER_RANGE:
		_clear_aim()
		fire_timer = _sniper_interval()
		return

	fire_timer -= delta
	if fire_timer < SNIPER_AIM_TIME:
		aim_los_clear = _has_line_of_sight(p)
		if aim_los_clear:
			if aim_line == null:
				_start_aim()
			_update_aim()
		else:
			# 시야 끊김 → 발사 취소, 조준 다시 처음부터
			_clear_aim()
			fire_timer = _sniper_interval()

	if fire_timer <= 0.0:
		fire_timer = _sniper_interval()
		if aim_los_clear:
			_fire_at_player()
		_clear_aim()

func _has_line_of_sight(p: Node2D) -> bool:
	var space := get_world_2d().direct_space_state
	var from: Vector2 = global_position + Vector2(0, -20)
	var to: Vector2 = p.global_position + Vector2(0, -28)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.exclude = [get_rid()]
	var result: Dictionary = space.intersect_ray(query)
	return result.is_empty()

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

# ─── Drone ──────────────────────────────────────────────────

func _tick_drone(delta: float) -> void:
	if drone_bomb_cd > 0.0:
		drone_bomb_cd -= delta
	var player := _find_player()
	if player == null:
		return
	var dx: float = abs(player.global_position.x - global_position.x)
	var dy_above: float = player.global_position.y - global_position.y  # 양수면 드론이 위
	var hover_ok: bool = dx <= DRONE_BOMB_X_BAND and dy_above >= DRONE_BOMB_Y_MIN and dy_above <= DRONE_BOMB_Y_MAX
	if hover_ok and drone_bomb_cd <= 0.0 and not harmless:
		velocity = Vector2.ZERO
		_drop_bomb()
		drone_bomb_cd = _drone_bomb_interval()
	else:
		var target: Vector2 = player.global_position + Vector2(0, DRONE_HOVER_OFFSET_Y)
		var to: Vector2 = target - global_position
		if to.length() > 6.0:
			velocity = to.normalized() * DRONE_SPEED
			_flip_visual((player.global_position.x - global_position.x) < 0.0)
		else:
			velocity = Vector2.ZERO
	move_and_slide()

func _drop_bomb() -> void:
	var b := Bomb.new()
	b.global_position = global_position + Vector2(0, 8)
	get_parent().add_child(b)

# ─── 공통 ───────────────────────────────────────────────────

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
	if dist > SNIPER_RANGE:
		return
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
