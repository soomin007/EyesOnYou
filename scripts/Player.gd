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

var facing: int = 1
var attack_timer: float = 0.0
var attack_cd: float = 0.0
var jumps_used: int = 0
var dash_timer: float = 0.0
var dash_cd: float = 0.0
var invuln: float = 0.0

@onready var sprite: ColorRect = $Sprite
@onready var attack_visual: ColorRect = $AttackVisual

func _ready() -> void:
	add_to_group("player")
	attack_visual.visible = false

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
		if attack_timer <= 0.0:
			attack_visual.visible = false
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
	var width: float = 56.0
	var rx: float = 8.0 if facing > 0 else -(8.0 + width)
	attack_visual.position = Vector2(rx, -36.0)
	attack_visual.size = Vector2(width, 40.0)
	attack_visual.visible = true
	var damage: int = 2 if GameState.has_skill("melee_boost") else 1
	var rect_global := Rect2(global_position + Vector2(rx, -36.0), Vector2(width, 40.0))
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
	if invuln > 0.0:
		sprite.modulate.a = 0.4 if int(invuln * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0
