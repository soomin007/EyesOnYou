class_name Player
extends CharacterBody2D

signal damaged
signal died
signal revived

const SPEED: float = 240.0
const JUMP_VELOCITY: float = -540.0
const GRAVITY: float = 1400.0
const MAX_FALL_SPEED: float = 1100.0
const GLIDE_FALL_SPEED: float = 130.0  # glide(공중 글라이드) 시 점프 키 홀드 중 최대 낙하 속도
const ATTACK_COOLDOWN: float = 0.30
const DASH_SPEED: float = 720.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.7
const INVULN_AFTER_HIT: float = 0.8
const SKILL_COOLDOWN: float = 3.0  # explosive 재사용 대기
const DROP_THROUGH_DURATION: float = 0.25  # 플랫폼 통과 예외 유지 시간

# 충전형 방패(barrier) — SkillTreeData.barrier 라인.
# T1: 10초 충전 후 1회 피격 무효 / T2: 6초 충전 / T3: 무효 직후 0.6s 무적.
const BARRIER_CHARGE_T1: float = 10.0
const BARRIER_CHARGE_T2: float = 6.0
const BARRIER_INVULN_T3: float = 0.6

const ATTACK_MUZZLE_X: float = 13.0
const ATTACK_MUZZLE_Y: float = -31.0  # 총구 높이 — 5두신 비례 재조정 후 새 손목 위치
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
var torso: Node2D = null      # CharacterArt가 만든 Torso 컨테이너 — idle bob에 사용
var arm_front: Node2D = null  # 앞팔/총 — 사격 시 반동 회전, 이동 시 흔들림
var leg_l: Node2D = null      # 왼다리 — 가랑이 origin. walk swing.
var leg_r: Node2D = null      # 오른다리
var anim_t: float = 0.0       # 시각 애니메이션 누적 시간(sin bob 위상)
var muzzle_flash: ColorRect

# explosive T3 — 2회 충전. 사용 시 charges -1, cd 끝나면 +1 누적.
var skill_charges: int = 1
var skill_max_charges: int = 1

# barrier 상태
var barrier_ready: bool = false
var barrier_charge_t: float = 0.0
var barrier_indicator: ColorRect = null

func _ready() -> void:
	add_to_group("player")
	z_index = 2
	visual = CharacterArt.build_player(self)
	torso = visual.get_node_or_null("Torso")
	if torso != null:
		arm_front = torso.get_node_or_null("ArmFront")
		leg_l = torso.get_node_or_null("LegL")
		leg_r = torso.get_node_or_null("LegR")
	_refresh_skill_charges()
	muzzle_flash = ColorRect.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.color = Color(1.0, 0.92, 0.45, 1.0)
	muzzle_flash.size = Vector2(12.0, 8.0)
	muzzle_flash.position = Vector2(ATTACK_MUZZLE_X, ATTACK_MUZZLE_Y - 4.0)
	muzzle_flash.visible = false
	add_child(muzzle_flash)
	# barrier indicator — 머리 위 작은 점, 충전 완료 시 푸른빛.
	barrier_indicator = ColorRect.new()
	barrier_indicator.name = "BarrierIndicator"
	barrier_indicator.color = Color(0.45, 0.75, 1.0, 0.0)
	barrier_indicator.size = Vector2(6.0, 6.0)
	barrier_indicator.position = Vector2(-3.0, -64.0)
	barrier_indicator.pivot_offset = Vector2(3.0, 3.0)
	add_child(barrier_indicator)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_handle_input(delta)
	_apply_gravity(delta)
	move_and_slide()
	if is_on_floor():
		jumps_used = 0
	anim_t += delta
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
		# 쿨다운 종료 — charges 미만이면 +1 (T3 2회 충전).
		if skill_cd <= 0.0 and skill_charges < skill_max_charges:
			skill_charges += 1
			if skill_charges < skill_max_charges:
				skill_cd = get_skill_cd_max()  # 다음 충전 시작
	if invuln > 0.0:
		invuln -= delta
	if muzzle_flash != null and muzzle_flash.visible:
		muzzle_flash.modulate.a = max(0.0, muzzle_flash.modulate.a - delta * 7.0)
		if muzzle_flash.modulate.a <= 0.05:
			muzzle_flash.visible = false
			muzzle_flash.modulate.a = 1.0
	_tick_barrier(delta)

func _tick_barrier(delta: float) -> void:
	# barrier 라인 미보유 시 indicator 숨김.
	if not GameState.has_skill("barrier"):
		if barrier_indicator != null:
			barrier_indicator.color.a = 0.0
		return
	if barrier_ready:
		# 충전 완료 — 푸른빛 펄스
		if barrier_indicator != null:
			barrier_indicator.color.a = 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.005)
		return
	# 충전 진행
	var charge_max: float = BARRIER_CHARGE_T2 if GameState.get_skill_tier("barrier") >= 2 else BARRIER_CHARGE_T1
	barrier_charge_t += delta
	# 충전 비율에 따라 indicator alpha 가늘게 (0.05 → 0.4)
	if barrier_indicator != null:
		var ratio: float = clamp(barrier_charge_t / charge_max, 0.0, 1.0)
		barrier_indicator.color.a = lerp(0.05, 0.4, ratio)
	if barrier_charge_t >= charge_max:
		barrier_ready = true
		barrier_charge_t = 0.0
		# 충전 완료 시 짧은 펄스 + 작은 후광
		if barrier_indicator != null:
			var tw := barrier_indicator.create_tween()
			barrier_indicator.scale = Vector2(2.6, 2.6)
			tw.tween_property(barrier_indicator, "scale", Vector2(1.0, 1.0), 0.25)

func _handle_input(_delta: float) -> void:
	var dir: float = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1

	if dash_timer > 0.0:
		# dash_boost T2 = 대시 거리 +30% → 속도 *1.3 (지속시간은 그대로라 거리 늘어남)
		var dash_speed_mult: float = 1.3 if GameState.get_skill_tier("dash_boost") >= 2 else 1.0
		velocity.x = float(facing) * DASH_SPEED * dash_speed_mult
	else:
		velocity.x = dir * SPEED

	if Input.is_action_just_pressed("jump"):
		_try_jump()
	# 전투 입력 제한 (??? 맵에서) — 이동/점프만 허용
	if not GameState.restrict_combat_input:
		# 공격 — 꾹 누르면 쿨다운마다 자동 연발. _try_attack이 cd 체크해 자체 무시.
		if Input.is_action_pressed("attack"):
			_try_attack()
		if Input.is_action_just_pressed("dash"):
			_try_dash()
		if Input.is_action_just_pressed("skill"):
			_try_skill()
	if Input.is_action_just_pressed("move_down"):
		_try_drop_through()

func _try_drop_through() -> void:
	if not is_on_floor():
		return
	# 직전 move_and_slide의 충돌 결과에서 발 밑이 one-way 플랫폼인지 검사
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var collider: Object = c.get_collider()
		if collider is Node and (collider as Node).is_in_group("platform"):
			add_collision_exception_with(collider)
			get_tree().create_timer(DROP_THROUGH_DURATION).timeout.connect(
				func() -> void:
					if is_instance_valid(collider):
						remove_collision_exception_with(collider)
			)
			position.y += 2.0
			velocity.y = max(velocity.y, 80.0)
			return

func _try_jump() -> void:
	var max_jumps: int = 2 if GameState.has_skill("double_jump") else 1
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumps_used = 1
	elif jumps_used < max_jumps:
		velocity.y = JUMP_VELOCITY * 0.92
		jumps_used += 1

# 현재 티어가 반영된 실제 max 쿨다운 (HUD 게이지 표시용).
func get_attack_cd_max() -> float:
	return ATTACK_COOLDOWN * (0.75 if GameState.get_skill_tier("fire_boost") >= 2 else 1.0)

func get_dash_cd_max() -> float:
	return DASH_COOLDOWN * (0.8 if GameState.get_skill_tier("dash_boost") >= 1 else 1.0)

func get_skill_cd_max() -> float:
	var ex_tier: int = GameState.get_skill_tier("explosive")
	if ex_tier >= 2:
		return 2.5
	return SKILL_COOLDOWN

func _try_attack() -> void:
	if attack_cd > 0.0:
		return
	# fire_boost T2 "사격 시 잠깐 가속" → 사격 쿨다운 -25%.
	var fb_tier: int = GameState.get_skill_tier("fire_boost")
	var cd_mult: float = 0.75 if fb_tier >= 2 else 1.0
	attack_cd = ATTACK_COOLDOWN * cd_mult
	_show_muzzle_flash()
	# multishot T1=3발, T2/T3=5발.
	var ms_tier: int = GameState.get_skill_tier("multishot")
	var shots: int = 1
	if ms_tier == 1:
		shots = 3
	elif ms_tier >= 2:
		shots = 5
	for i in shots:
		_spawn_bullet(i, shots)

func _spawn_bullet(idx: int, total: int) -> void:
	var b := Bullet.new()
	b.dir = facing
	# fire_boost: T1=+1, T2=+2, T3=관통(데미지 추가 없음). 베이스 데미지 1.
	var fb_tier: int = GameState.get_skill_tier("fire_boost")
	b.damage = 1 + min(fb_tier, 2)  # T0=1, T1=2, T2=3, T3=3
	b.pierce = fb_tier >= 3
	# multishot T3 — 약한 추적
	b.tracking = GameState.get_skill_tier("multishot") >= 3
	# 부채꼴 — 가운데를 0으로 양 끝으로 10°씩 벌림.
	# T1(3발): -10°/0/+10°. T2(5발): -20/-10/0/+10/+20.
	if total > 1:
		var step: float = deg_to_rad(10.0)
		var center: float = float(total - 1) * 0.5
		b.angle = (float(idx) - center) * step
	var muzzle_x: float = ATTACK_MUZZLE_X * float(facing)
	var muzzle_y: float = ATTACK_MUZZLE_Y
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
	# dash_boost: T1=쿨다운 -20%, T2=거리 +30%(_handle_input의 dash_timer 분기에서 적용),
	#            T3=대시 후 0.3s 무적 추가.
	var db_tier: int = GameState.get_skill_tier("dash_boost")
	var cd_mult: float = 0.8 if db_tier >= 1 else 1.0
	dash_timer = DASH_DURATION
	dash_cd = DASH_COOLDOWN * cd_mult
	var iframe: float = DASH_DURATION
	if db_tier >= 3:
		iframe += 0.3
	invuln = max(invuln, iframe)

func _try_skill() -> void:
	# explosive: T1=쿨다운 3.0s, T2=반경+30% 쿨다운 2.5s, T3=쿨다운 2.5s + 2회 충전.
	var ex_tier: int = GameState.get_skill_tier("explosive")
	if ex_tier == 0:
		return
	_refresh_skill_charges()  # 티어 변경(레벨업 직후) 반영
	if skill_charges <= 0:
		return
	skill_charges -= 1
	if skill_cd <= 0.0:
		skill_cd = get_skill_cd_max()
	_spawn_explosion()

# T3에서 max 2 charges. 매 _ready/_try_skill 진입 시 호출해 티어 갱신을 반영.
func _refresh_skill_charges() -> void:
	var ex_tier: int = GameState.get_skill_tier("explosive")
	var new_max: int = 2 if ex_tier >= 3 else 1
	if new_max != skill_max_charges:
		skill_max_charges = new_max
		skill_charges = clampi(skill_charges, 0, skill_max_charges)
		# T3로 막 진입했으면 충전 1개 추가 보장(이전엔 1/1 상태)
		if new_max == 2 and skill_charges < new_max and skill_cd <= 0.0:
			skill_charges = new_max

func _spawn_explosion() -> void:
	var center: Vector2 = global_position + Vector2(0, -28)
	# explosive T2/T3 = 반경 +30%
	var radius: float = EXPLOSION_RADIUS
	if GameState.get_skill_tier("explosive") >= 2:
		radius *= 1.3
	# 데미지: 반경 안 모든 적
	for n in get_tree().get_nodes_in_group("enemy"):
		if not (n is Node2D):
			continue
		var enemy := n as Node2D
		if enemy.global_position.distance_to(center) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(EXPLOSION_DAMAGE)
	# 시각: 확장하며 페이드되는 원
	var blast := Polygon2D.new()
	blast.color = Color(1.0, 0.55, 0.30, 0.85)
	blast.z_index = 3
	var pts: Array = []
	for i in 28:
		var a: float = float(i) * TAU / 28.0
		pts.append(Vector2(cos(a) * radius, sin(a) * radius))
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
	# 공중 글라이드 — 낙하 중 점프 키 누르고 있으면 천천히 떨어진다.
	# T2 "낙하 중 가속": 점프 키를 짧게 떼었다 누르면 가속 (간단히 좌우 입력 시 살짝 가속).
	# T3 "공중 사격 패널티 제거": 효과는 _try_attack과 무관 — 현재 사격에 패널티 없으므로 보유만 인정.
	var glide_tier: int = GameState.get_skill_tier("glide")
	if glide_tier >= 1 and velocity.y > 0.0 and Input.is_action_pressed("jump"):
		var fall_speed: float = GLIDE_FALL_SPEED
		# T2 — 좌우 이동 입력 시 낙하 속도 살짝 ↑ (가속 효과)
		if glide_tier >= 2 and Input.get_axis("move_left", "move_right") != 0.0:
			fall_speed = GLIDE_FALL_SPEED * 1.6
		velocity.y = min(velocity.y, fall_speed)

func take_hit(amount: int) -> void:
	if invuln > 0.0:
		return
	# barrier 충전 완료 상태면 1회 무효화 + 충전 리셋. T3는 후속 무적.
	if GameState.has_skill("barrier") and barrier_ready:
		barrier_ready = false
		barrier_charge_t = 0.0
		if barrier_indicator != null:
			barrier_indicator.color.a = 0.0
		_show_shield_flash()
		if GameState.get_skill_tier("barrier") >= 3:
			invuln = max(invuln, BARRIER_INVULN_T3)
		emit_signal("damaged")  # 화면 플래시·shake 트리거 (시각 피드백 유지)
		return
	GameState.damage_player(amount)
	# hp T2 = 피격 후 1s 무적 (기본 0.8보다 길게)
	var hp_tier: int = GameState.get_skill_tier("hp")
	invuln = 1.0 if hp_tier >= 2 else INVULN_AFTER_HIT
	emit_signal("damaged")
	# 비상 방어막 — T1: HP 1로 부활, T2: HP 2로 부활. 발동 시 라인 erase (T3 재충전은 미구현).
	var sh_tier: int = GameState.get_skill_tier("shield")
	if GameState.is_dead() and sh_tier >= 1:
		GameState.player_hp = 2 if sh_tier >= 2 else 1
		GameState.skills.erase("shield")
		_show_shield_flash()
		emit_signal("revived")
		return
	if GameState.is_dead():
		emit_signal("died")

func _show_shield_flash() -> void:
	# 방어막 발동 — 강한 흰 플래시 + 확장하는 후광 (한 번에 인지되도록 강화).
	if visual != null:
		visual.modulate = Color(3.5, 3.5, 4.0)
		create_tween().tween_property(visual, "modulate", Color(1, 1, 1), 0.6)
	var halo := Polygon2D.new()
	halo.color = Color(1.0, 1.0, 1.2, 0.85)
	var pts: Array = []
	for i in 28:
		var a: float = float(i) * TAU / 28.0
		pts.append(Vector2(cos(a) * 28.0, sin(a) * 28.0))
	halo.polygon = PackedVector2Array(pts)
	halo.position = Vector2(0, -28)
	halo.z_index = 5
	add_child(halo)
	var tw := halo.create_tween()
	tw.set_parallel(true)
	tw.tween_property(halo, "scale", Vector2(3.4, 3.4), 0.55)
	tw.tween_property(halo, "modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(halo.queue_free)
	# 두 번째 후광 (살짝 늦게 따라옴 — 섬광 느낌)
	var halo2 := Polygon2D.new()
	halo2.color = Color(0.85, 0.95, 1.0, 0.5)
	halo2.polygon = PackedVector2Array(pts)
	halo2.position = Vector2(0, -28)
	halo2.z_index = 4
	add_child(halo2)
	var tw2 := halo2.create_tween()
	tw2.tween_interval(0.12)
	tw2.set_parallel(true)
	tw2.tween_property(halo2, "scale", Vector2(4.5, 4.5), 0.5)
	tw2.tween_property(halo2, "modulate:a", 0.0, 0.5)
	tw2.chain().tween_callback(halo2.queue_free)

func _update_visual() -> void:
	if visual == null:
		return
	if invuln > 0.0:
		visual.modulate.a = 0.4 if int(invuln * 20.0) % 2 == 0 else 1.0
	else:
		visual.modulate.a = 1.0
	visual.scale.x = -1.0 if facing < 0 else 1.0
	# 자세 — Torso의 작은 y bob + ArmFront 회전으로 정적 인상 완화.
	# scale.x로 좌우 반전돼도 child rotation은 시각적으로 자동 미러됨.
	if torso == null:
		return
	var moving: bool = absf(velocity.x) > 10.0
	var grounded: bool = is_on_floor()
	var bob: float = 0.0
	var lean: float = 0.0
	var arm_rot: float = 0.0
	if not grounded:
		bob = -1.0
		if velocity.y < 0.0:
			lean = 0.05
			arm_rot = -0.18
		else:
			lean = -0.03
			arm_rot = 0.10
	elif moving:
		bob = sin(anim_t * 14.0) * 1.4
		arm_rot = sin(anim_t * 14.0) * 0.10
	else:
		bob = sin(anim_t * 3.0) * 0.6
		arm_rot = sin(anim_t * 3.0) * 0.03
	# 사격 직후 반동 — attack_cd가 max에서 0으로 줄어드는 동안 팔이 위로 튀었다 내려옴.
	var max_cd: float = get_attack_cd_max()
	if attack_cd > 0.0 and max_cd > 0.0:
		var t: float = clamp(attack_cd / max_cd, 0.0, 1.0)
		arm_rot += -0.30 * t
	torso.position.y = bob
	torso.rotation = lean
	if arm_front != null:
		arm_front.rotation = arm_rot
	# 다리 — 가랑이 origin인 LegL/LegR을 회전시켜 보행/점프 자세.
	var leg_l_rot: float = 0.0
	var leg_r_rot: float = 0.0
	if grounded:
		if moving:
			var swing: float = sin(anim_t * 14.0) * 0.45
			leg_l_rot = -swing
			leg_r_rot = swing
	else:
		# 점프/낙하 — 한쪽 다리 앞 한쪽 뒤로 살짝(running jump 자세).
		# 양다리가 같은 방향이면 어색하니 비대칭으로.
		leg_l_rot = -0.22
		leg_r_rot = 0.10
	if leg_l != null:
		leg_l.rotation = leg_l_rot
	if leg_r != null:
		leg_r.rotation = leg_r_rot
