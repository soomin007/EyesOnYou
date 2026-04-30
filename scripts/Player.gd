extends CharacterBody2D

signal damaged
signal died

const SPEED: float = 240.0
const JUMP_VELOCITY: float = -540.0
const GRAVITY: float = 1400.0
const MAX_FALL_SPEED: float = 1100.0
const WALL_SLIDE_FALL_SPEED: float = 140.0  # wall_slide 보유 시 벽에서의 최대 낙하 속도
const ATTACK_COOLDOWN: float = 0.30
const DASH_SPEED: float = 720.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.7
const INVULN_AFTER_HIT: float = 0.8
const SKILL_COOLDOWN: float = 3.0  # explosive 재사용 대기

const ATTACK_MUZZLE_X: float = 14.0
const ATTACK_MUZZLE_Y: float = -38.0  # 총구 높이 (가슴)
const EXPLOSION_RADIUS: float = 180.0
const EXPLOSION_DAMAGE: int = 3

var facing: int = 1
var attack_cd: float = 0.0
var jumps_used: int = 0
var dash_timer: float = 0.0
var dash_cd: float = 0.0
var skill_cd: float = 0.0
var invuln: float = 0.0

var visual: Node2D
var muzzle_flash: ColorRect

func _ready() -> void:
	add_to_group("player")
	z_index = 2
	visual = CharacterArt.build_player(self)
	muzzle_flash = ColorRect.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.color = Color(1.0, 0.92, 0.45, 1.0)
	muzzle_flash.size = Vector2(12.0, 8.0)
	muzzle_flash.position = Vector2(ATTACK_MUZZLE_X, ATTACK_MUZZLE_Y - 4.0)
	muzzle_flash.visible = false
	add_child(muzzle_flash)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_handle_input(delta)
	_apply_gravity(delta)
	move_and_slide()
	if is_on_floor():
		jumps_used = 0
	_update_visual()

func _tick_timers(delta: float) -> void:
	if attack_cd > 0.0:
		attack_cd -= delta
	if dash_timer > 0.0:
		dash_timer -= delta
	if dash_cd > 0.0:
		dash_cd -= delta
	if skill_cd > 0.0:
		skill_cd -= delta
	if invuln > 0.0:
		invuln -= delta
	if muzzle_flash != null and muzzle_flash.visible:
		muzzle_flash.modulate.a = max(0.0, muzzle_flash.modulate.a - delta * 7.0)
		if muzzle_flash.modulate.a <= 0.05:
			muzzle_flash.visible = false
			muzzle_flash.modulate.a = 1.0

func _handle_input(_delta: float) -> void:
	var dir: float = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1

	if dash_timer > 0.0:
		velocity.x = float(facing) * DASH_SPEED
	else:
		velocity.x = dir * SPEED

	if Input.is_action_just_pressed("jump"):
		_try_jump()
	if Input.is_action_just_pressed("attack"):
		_try_attack()
	if Input.is_action_just_pressed("dash"):
		_try_dash()
	if Input.is_action_just_pressed("skill"):
		_try_skill()

func _try_jump() -> void:
	var max_jumps: int = 2 if GameState.has_skill("double_jump") else 1
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumps_used = 1
	elif jumps_used < max_jumps:
		velocity.y = JUMP_VELOCITY * 0.92
		jumps_used += 1

func _try_attack() -> void:
	if attack_cd > 0.0:
		return
	var cd_mult: float = 0.75 if GameState.has_skill("ranged") else 1.0
	attack_cd = ATTACK_COOLDOWN * cd_mult
	_show_muzzle_flash()
	var shots: int = 3 if GameState.has_skill("multishot") else 1
	for i in shots:
		_spawn_bullet(i, shots)

func _spawn_bullet(idx: int, total: int) -> void:
	var b := Bullet.new()
	b.dir = facing
	b.damage = 2 if GameState.has_skill("melee_boost") else 1
	b.pierce = GameState.has_skill("piercing")
	if GameState.has_skill("ranged"):
		b.speed_mult = 1.5
		b.lifetime_mult = 1.5
	var muzzle_x: float = ATTACK_MUZZLE_X * float(facing)
	var muzzle_y: float = ATTACK_MUZZLE_Y
	if total > 1:
		var spread: float = float(idx) - float(total - 1) * 0.5
		muzzle_y += spread * 14.0
	b.global_position = global_position + Vector2(muzzle_x, muzzle_y)
	get_parent().add_child(b)

func _show_muzzle_flash() -> void:
	if muzzle_flash == null:
		return
	var mx: float = ATTACK_MUZZLE_X if facing > 0 else -(ATTACK_MUZZLE_X + 12.0)
	muzzle_flash.position = Vector2(mx, ATTACK_MUZZLE_Y - 4.0)
	muzzle_flash.modulate.a = 1.0
	muzzle_flash.visible = true

func _try_dash() -> void:
	if not GameState.has_skill("dash"):
		return
	if dash_cd > 0.0:
		return
	dash_timer = DASH_DURATION
	dash_cd = DASH_COOLDOWN
	invuln = max(invuln, DASH_DURATION)

func _try_skill() -> void:
	if not GameState.has_skill("explosive"):
		return
	if skill_cd > 0.0:
		return
	skill_cd = SKILL_COOLDOWN
	_spawn_explosion()

func _spawn_explosion() -> void:
	var center: Vector2 = global_position + Vector2(0, -28)
	# 데미지: 반경 안 모든 적
	for n in get_tree().get_nodes_in_group("enemy"):
		if not (n is Node2D):
			continue
		var enemy := n as Node2D
		if enemy.global_position.distance_to(center) <= EXPLOSION_RADIUS:
			if enemy.has_method("take_damage"):
				enemy.take_damage(EXPLOSION_DAMAGE)
	# 시각: 확장하며 페이드되는 원
	var blast := Polygon2D.new()
	blast.color = Color(1.0, 0.55, 0.30, 0.85)
	blast.z_index = 3
	var pts: Array = []
	for i in 28:
		var a: float = float(i) * TAU / 28.0
		pts.append(Vector2(cos(a) * EXPLOSION_RADIUS, sin(a) * EXPLOSION_RADIUS))
	blast.polygon = PackedVector2Array(pts)
	blast.global_position = center
	blast.scale = Vector2(0.2, 0.2)
	get_parent().add_child(blast)
	var tw := blast.create_tween()
	tw.set_parallel(true)
	tw.tween_property(blast, "scale", Vector2(1.0, 1.0), 0.30)
	tw.tween_property(blast, "modulate", Color(1, 1, 1, 0), 0.45)
	tw.chain().tween_callback(blast.queue_free)

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	# wall_slide: 벽에 붙어 떨어질 때만 낙하 속도 제한
	if GameState.has_skill("wall_slide") and is_on_wall_only() and velocity.y > 0.0:
		velocity.y = min(velocity.y, WALL_SLIDE_FALL_SPEED)

func take_hit(amount: int) -> void:
	if invuln > 0.0:
		return
	if GameState.has_skill("shield") and amount >= 2:
		amount = 1
		GameState.skills.erase("shield")
	GameState.damage_player(amount)
	invuln = INVULN_AFTER_HIT
	emit_signal("damaged")
	if GameState.is_dead():
		emit_signal("died")

func _update_visual() -> void:
	if visual == null:
		return
	if invuln > 0.0:
		visual.modulate.a = 0.4 if int(invuln * 20.0) % 2 == 0 else 1.0
	else:
		visual.modulate.a = 1.0
	visual.scale.x = -1.0 if facing < 0 else 1.0
