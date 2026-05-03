class_name BossSentinel
extends CharacterBody2D

# 핵심부(lab) ARENA 보스. 명세: docs/design/world_layout.md §2.10
# 3페이즈 구조 — HP 12 → 8(P2 전환) → 4(P3 전환) → 0(자폭 카운트다운).
# 적 그룹("enemy")에 추가돼서 ARENA enemy_clear 카운트에 자연스럽게 포함된다.
# Stage가 killed 시그널을 받아 클리어 처리.

signal killed(at_position: Vector2)
signal phase_changed(new_phase: int)
signal self_destruct_started
signal self_destruct_disarmed

const HP_MAX: int = 24
const HP_PHASE2: int = 16  # 이 값 이하 들어오면 P2
const HP_PHASE3: int = 8   # 이 값 이하 들어오면 P3
const HP_SELF_DESTRUCT: int = 1  # 이 값 이하 시 자폭 카운트다운 시작
const PHASE_FREEZE_DURATION: float = 1.2  # 페이즈 전환 시 정지 + 무적 시간

const SELF_DESTRUCT_TIME: float = 5.0
const SELF_DESTRUCT_INNER: float = 380.0   # 이 안: full 데미지
const SELF_DESTRUCT_OUTER: float = 1200.0  # 이 너머: 1뎀 (멀리 있으면 약한 회피)
const SELF_DESTRUCT_DAMAGE: int = 3
const SELF_DESTRUCT_DAMAGE_MIN: int = 1

const TOUCH_DAMAGE: int = 1
const TOUCH_COOLDOWN: float = 1.0

# 페이즈별 이동/공격 파라미터
const SPEED_P1: float = 77.0   # 일반 drone 110 × 0.7
const SPEED_P2: float = 165.0  # × 1.5
const SPEED_P3: float = 220.0
const BOMB_INTERVAL_P1: float = 1.5
const BOMB_INTERVAL_P2: float = 1.0
const BOMB_INTERVAL_P3: float = 0.7
const BOMB_TELEGRAPH: float = 0.5
const MISSILE_INTERVAL_P2: float = 3.5
const MISSILE_INTERVAL_P3: float = 2.5
const MISSILE_TELEGRAPH: float = 0.3
const MISSILE_SPEED: float = 380.0
const HOVER_Y: float = 280.0  # 호버 라인 (lab ground 820 기준 위쪽)
const HOVER_RANGE_X: Vector2 = Vector2(160.0, 1760.0)  # 좌/우 한계 (lab 1920 기준)
const TRACK_DEAD_ZONE: float = 80.0  # P2/P3 추적 시 dead zone

var hp: int = HP_MAX
var phase: int = 1
var dir: int = 1  # 1=우, -1=좌
var dead: bool = false
var visual: Node2D
var touch_cd: float = 0.0
var bomb_cd: float = 0.8
var missile_cd: float = 3.0
var bomb_telegraph_t: float = 0.0   # >0: 텔레그래프 진행 중
var pending_bomb_x: float = 0.0
var missile_telegraph_t: float = 0.0
var pending_missile_dir: int = 0
var self_destruct_active: bool = false
var self_destruct_t: float = 0.0
var phase_freeze_t: float = 0.0  # 페이즈 전환 시 잠깐 정지 (시각적 강조)

# 텔레그래프 시각 노드
var bomb_dot: ColorRect = null
var wing_l: Polygon2D = null
var wing_r: Polygon2D = null

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 1
	# 콜리전 — 32×24 드론의 2배 (64×48). 상단 발판 위로 올라가지 않도록 mask=1만.
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56.0, 40.0)
	col.shape = shape
	add_child(col)
	# Visual — 일반 drone 스프라이트 2배 스케일
	visual = CharacterArt.build_drone(self)
	visual.scale = Vector2(2.0, 2.0)
	# 텔레그래프용 빨간 점 (폭탄 발사 직전)
	bomb_dot = ColorRect.new()
	bomb_dot.color = Color(1.0, 0.20, 0.20, 0.0)
	bomb_dot.position = Vector2(-3.0, 18.0)
	bomb_dot.size = Vector2(6.0, 6.0)
	add_child(bomb_dot)
	# 날개(좌/우) 깜빡임 — P2/P3 미사일 발사 텔레그래프
	wing_l = Polygon2D.new()
	wing_l.color = Color(1.0, 0.20, 0.20, 0.0)
	wing_l.polygon = PackedVector2Array([
		Vector2(-32, -2), Vector2(-20, -2), Vector2(-20, 2), Vector2(-32, 2),
	])
	add_child(wing_l)
	wing_r = Polygon2D.new()
	wing_r.color = Color(1.0, 0.20, 0.20, 0.0)
	wing_r.polygon = PackedVector2Array([
		Vector2(20, -2), Vector2(32, -2), Vector2(32, 2), Vector2(20, 2),
	])
	add_child(wing_r)

func _physics_process(delta: float) -> void:
	if dead:
		return
	touch_cd = max(0.0, touch_cd - delta)
	# 자폭 카운트다운 진행
	if self_destruct_active:
		self_destruct_t += delta
		if self_destruct_t >= SELF_DESTRUCT_TIME:
			_detonate()
			return
	# 페이즈 전환 정지
	if phase_freeze_t > 0.0:
		phase_freeze_t -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_move(delta)
	_attacks(delta)
	_check_touch_player()

func _current_speed() -> float:
	match phase:
		2: return SPEED_P2
		3: return SPEED_P3
	return SPEED_P1

func _move(_delta: float) -> void:
	var p: Node2D = _find_player()
	# Y는 HOVER_Y에 고정 (drone-like 호버), X는 페이즈별 행동
	if phase == 1:
		# 가로 왕복
		velocity.x = float(dir) * _current_speed()
		if global_position.x < HOVER_RANGE_X.x:
			dir = 1
		elif global_position.x > HOVER_RANGE_X.y:
			dir = -1
	else:
		# P2/P3 — 플레이어 추적 (느슨/적극)
		if p == null:
			velocity.x = 0.0
		else:
			var dx: float = p.global_position.x - global_position.x
			if abs(dx) < TRACK_DEAD_ZONE:
				velocity.x = 0.0
			else:
				velocity.x = sign(dx) * _current_speed()
				dir = int(sign(dx))
	# Y 회복 (HOVER_Y 라인으로)
	var dy: float = HOVER_Y - global_position.y
	velocity.y = clamp(dy * 4.0, -120.0, 120.0)
	move_and_slide()

func _attacks(delta: float) -> void:
	# 폭탄 — 모든 페이즈 공통 (간격만 다름)
	if bomb_telegraph_t > 0.0:
		bomb_telegraph_t -= delta
		# 점멸
		bomb_dot.color.a = 0.6 + 0.4 * sin(bomb_telegraph_t * 30.0)
		if bomb_telegraph_t <= 0.0:
			_drop_bomb()
			bomb_dot.color.a = 0.0
			bomb_cd = _bomb_interval()
	else:
		bomb_cd -= delta
		if bomb_cd <= 0.0:
			bomb_telegraph_t = BOMB_TELEGRAPH
			pending_bomb_x = global_position.x
	# 미사일 — P2/P3
	if phase >= 2:
		if missile_telegraph_t > 0.0:
			missile_telegraph_t -= delta
			var pulse: float = 0.5 + 0.5 * sin(missile_telegraph_t * 40.0)
			wing_l.color.a = pulse
			wing_r.color.a = pulse
			if missile_telegraph_t <= 0.0:
				_fire_missiles()
				wing_l.color.a = 0.0
				wing_r.color.a = 0.0
				missile_cd = (MISSILE_INTERVAL_P3 if phase == 3 else MISSILE_INTERVAL_P2)
		else:
			missile_cd -= delta
			if missile_cd <= 0.0:
				missile_telegraph_t = MISSILE_TELEGRAPH

func _bomb_interval() -> float:
	match phase:
		2: return BOMB_INTERVAL_P2
		3: return BOMB_INTERVAL_P3
	return BOMB_INTERVAL_P1

func _drop_bomb() -> void:
	var bomb := Bomb.new()
	bomb.global_position = global_position + Vector2(0, 20.0)
	bomb.velocity = Vector2(0, 60.0)
	get_parent().add_child(bomb)

func _fire_missiles() -> void:
	# 좌/우 두 발 — 수평 이동, 플레이어 방향 노리지 않고 양방향으로 압박
	_spawn_missile(global_position + Vector2(-30.0, -2.0), -1)
	_spawn_missile(global_position + Vector2(30.0, -2.0), 1)

func _spawn_missile(pos: Vector2, side: int) -> void:
	var m := Area2D.new()
	m.set_script(load("res://scripts/BossMissile.gd"))
	m.global_position = pos
	m.set("velocity", Vector2(MISSILE_SPEED * float(side), 0.0))
	get_parent().add_child(m)

func _check_touch_player() -> void:
	if touch_cd > 0.0:
		return
	var p: Node2D = _find_player()
	if p == null:
		return
	if global_position.distance_to(p.global_position) < 50.0:
		if p.has_method("take_hit"):
			p.take_hit(TOUCH_DAMAGE)
			touch_cd = TOUCH_COOLDOWN

func _find_player() -> Node2D:
	for n in get_tree().get_nodes_in_group("player"):
		if n is Node2D:
			return n as Node2D
	return null

func take_damage(amount: int, _from_dir: int = 0) -> void:
	if dead or self_destruct_active:
		return
	# 페이즈 전환 동안은 무적 — 플레이어가 페이즈 연출을 인지할 시간 보장.
	if phase_freeze_t > 0.0:
		return
	hp = max(0, hp - amount)
	_flash_hit()
	# 페이즈 전환 검사
	if phase < 2 and hp <= HP_PHASE2:
		_transition_to(2)
	elif phase < 3 and hp <= HP_PHASE3:
		_transition_to(3)
	# 자폭 트리거 (HP 1 이하)
	if not self_destruct_active and hp <= HP_SELF_DESTRUCT:
		_arm_self_destruct()
	if hp <= 0 and not self_destruct_active:
		_die()

func _flash_hit() -> void:
	if visual == null:
		return
	visual.modulate = Color(1.4, 1.0, 1.0, 1.0)
	var tw := visual.create_tween()
	tw.tween_property(visual, "modulate", Color(1, 1, 1, 1), 0.18)

func _transition_to(new_phase: int) -> void:
	phase = new_phase
	phase_freeze_t = PHASE_FREEZE_DURATION
	# 텔레그래프 노드 리셋 — 전환 직후 잔존 점등이 어색.
	bomb_telegraph_t = 0.0
	missile_telegraph_t = 0.0
	if bomb_dot != null:
		bomb_dot.color.a = 0.0
	if wing_l != null:
		wing_l.color.a = 0.0
	if wing_r != null:
		wing_r.color.a = 0.0
	# 페이즈별 visual tint — 색으로 인지 보강
	if visual != null:
		match new_phase:
			2: visual.self_modulate = Color(1.2, 0.85, 0.65)  # 주황 tint
			3: visual.self_modulate = Color(1.4, 0.55, 0.55)  # 빨강 tint
			_: visual.self_modulate = Color(1, 1, 1)
	emit_signal("phase_changed", new_phase)

func _arm_self_destruct() -> void:
	self_destruct_active = true
	self_destruct_t = 0.0
	emit_signal("self_destruct_started")

func _detonate() -> void:
	# 거리 감쇠: inner 안=full 3뎀, outer 너머=1뎀, 그 사이는 lerp.
	# ARENA 1920에서 끝까지 도망쳐도 거리 ≈1700이라 1뎀 회피 가능.
	for n in get_tree().get_nodes_in_group("player"):
		if not (n is Node2D):
			continue
		var p := n as Node2D
		var dist: float = p.global_position.distance_to(global_position)
		var dmg: int = SELF_DESTRUCT_DAMAGE
		if dist >= SELF_DESTRUCT_OUTER:
			dmg = SELF_DESTRUCT_DAMAGE_MIN
		elif dist > SELF_DESTRUCT_INNER:
			# inner~outer 사이에서 3 → 1로 선형 감쇠
			var t_lerp: float = (dist - SELF_DESTRUCT_INNER) / (SELF_DESTRUCT_OUTER - SELF_DESTRUCT_INNER)
			dmg = int(round(lerp(float(SELF_DESTRUCT_DAMAGE), float(SELF_DESTRUCT_DAMAGE_MIN), t_lerp)))
		if p.has_method("take_hit"):
			p.take_hit(dmg)
	# 거대한 폭발 시각 효과
	var blast := Polygon2D.new()
	blast.color = Color(1.0, 0.35, 0.20, 0.9)
	blast.z_index = 8
	var pts: Array = []
	for i in 32:
		var a: float = float(i) * TAU / 32.0
		pts.append(Vector2(cos(a) * 480.0, sin(a) * 480.0))
	blast.polygon = PackedVector2Array(pts)
	blast.global_position = global_position
	blast.scale = Vector2(0.1, 0.1)
	get_parent().add_child(blast)
	var tw := blast.create_tween()
	tw.set_parallel(true)
	tw.tween_property(blast, "scale", Vector2(1.0, 1.0), 0.5)
	tw.tween_property(blast, "modulate", Color(1, 1, 1, 0), 0.7)
	tw.chain().tween_callback(blast.queue_free)
	# 자폭으로 사망 처리
	_die()

# 플레이어가 자폭 카운트다운 안에 보스를 처치하면 _die가 호출되며 정상 클리어.
func _die() -> void:
	if dead:
		return
	dead = true
	emit_signal("self_destruct_disarmed")
	emit_signal("killed", global_position)
	# 시각적 사라짐
	var tw := visual.create_tween() if visual != null else null
	if tw != null:
		tw.tween_property(visual, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)
	else:
		queue_free()
