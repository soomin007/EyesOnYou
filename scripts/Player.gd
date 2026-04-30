extends CharacterBody2D

signal damaged
signal died
signal attacked(hitbox_rect: Rect2)

const SPEED: float = 240.0
const JUMP_VELOCITY: float = -540.0
const GRAVITY: float = 1400.0
const MAX_FALL_SPEED: float = 1100.0
const ATTACK_DURATION: float = 0.18
const ATTACK_COOLDOWN: float = 0.30
const DASH_SPEED: float = 720.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.7
const INVULN_AFTER_HIT: float = 0.8

# 콜리전 28×56 (centered y=-28). 시각도 정확히 같은 박스 안에 그려짐.
const ATTACK_WIDTH: float = 220.0
const ATTACK_HEIGHT: float = 36.0
const ATTACK_OFFSET_Y: float = -38.0
const ATTACK_MUZZLE_X: float = 14.0

var facing: int = 1
var attack_timer: float = 0.0
var attack_cd: float = 0.0
var jumps_used: int = 0
var dash_timer: float = 0.0
var dash_cd: float = 0.0
var invuln: float = 0.0

var visual: Node2D
var attack_visual: ColorRect
var muzzle_flash: ColorRect

func _ready() -> void:
	add_to_group("player")
	visual = CharacterArt.build_player(self)
	_setup_attack_visuals()

func _setup_attack_visuals() -> void:
	attack_visual = ColorRect.new()
	attack_visual.name = "AttackVisual"
	attack_visual.color = Color(1.0, 0.95, 0.55, 0.90)
	attack_visual.size = Vector2(ATTACK_WIDTH, 4.0)
	attack_visual.position = Vector2(ATTACK_MUZZLE_X, ATTACK_OFFSET_Y)
	attack_visual.visible = false
	add_child(attack_visual)

	muzzle_flash = ColorRect.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.color = Color(1.0, 0.92, 0.45, 1.0)
	muzzle_flash.size = Vector2(10.0, 10.0)
	muzzle_flash.position = Vector2(ATTACK_MUZZLE_X, ATTACK_OFFSET_Y - 3.0)
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
	if attack_timer > 0.0:
		attack_timer -= delta
		var t: float = clamp(attack_timer / ATTACK_DURATION, 0.0, 1.0)
		if attack_visual != null:
			attack_visual.modulate.a = t
		if muzzle_flash != null:
			muzzle_flash.modulate.a = t
		if attack_timer <= 0.0:
			if attack_visual != null:
				attack_visual.visible = false
				attack_visual.modulate.a = 1.0
			if muzzle_flash != null:
				muzzle_flash.visible = false
				muzzle_flash.modulate.a = 1.0
	if attack_cd > 0.0:
		attack_cd -= delta
	if dash_timer > 0.0:
		dash_timer -= delta
	if dash_cd > 0.0:
		dash_cd -= delta
	if invuln > 0.0:
		invuln -= delta

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
	attack_timer = ATTACK_DURATION
	attack_cd = ATTACK_COOLDOWN
	var rx: float = ATTACK_MUZZLE_X if facing > 0 else -(ATTACK_MUZZLE_X + ATTACK_WIDTH)
	if attack_visual != null:
		attack_visual.position = Vector2(rx, ATTACK_OFFSET_Y - 2.0)
		attack_visual.size = Vector2(ATTACK_WIDTH, 4.0)
		attack_visual.modulate.a = 1.0
		attack_visual.visible = true
	if muzzle_flash != null:
		var mx: float = ATTACK_MUZZLE_X if facing > 0 else -(ATTACK_MUZZLE_X + 10.0)
		muzzle_flash.position = Vector2(mx, ATTACK_OFFSET_Y - 5.0)
		muzzle_flash.modulate.a = 1.0
		muzzle_flash.visible = true
	var damage: int = 2 if GameState.has_skill("melee_boost") else 1
	var rect_global := Rect2(global_position + Vector2(rx, ATTACK_OFFSET_Y - 16.0), Vector2(ATTACK_WIDTH, ATTACK_HEIGHT))
	emit_signal("attacked", rect_global)
	_apply_damage_in_rect(rect_global, damage)

func _try_dash() -> void:
	if not GameState.has_skill("dash"):
		return
	if dash_cd > 0.0:
		return
	dash_timer = DASH_DURATION
	dash_cd = DASH_COOLDOWN
	invuln = max(invuln, DASH_DURATION)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

func _apply_damage_in_rect(rect_global: Rect2, damage: int) -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		if not (n is Node2D):
			continue
		var enemy := n as Node2D
		if rect_global.has_point(enemy.global_position):
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

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
