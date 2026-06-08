class_name BulletTrap
extends Node2D

# 발사 함정 — 표면에 장착된 포탑이 정해진 방향으로 총알을 쏜다. 파괴 불가, 회피해야 함.
# 모드:
#   "periodic" : 텔레그래프(구경 충전) 후 주기 발사.
#   "tripwire" : 감지 레이저가 늘 켜져 있고, 플레이어가 라인을 가로지르면 잠깐 텔레그래프 후
#                버스트 발사 + 쿨다운. (침투물 분위기에 맞는 레이저 탐지기)
# 총알은 EnemyBullet 재사용(속도 240, 회피 가능). 하우징이 장착면(-direction 쪽)에 붙어 부유 안 함.
# SFX는 기존 enemy_patrol_fire. "파괴 불가" 안내는 Stage가 근접 시 VEIL 자막으로 1회 알림.

const SPEED: float = 240.0
const LINE_LEN: float = 384.0
const COL_PORT: Color = Color(0.16, 0.12, 0.10, 1.0)
const COL_EDGE: Color = Color(0.58, 0.42, 0.32, 1.0)
const COL_HOT: Color = Color(1.0, 0.55, 0.28)
const COL_LASER: Color = Color(1.0, 0.30, 0.26)

var direction: Vector2 = Vector2.DOWN
var mode: String = "periodic"
var interval: float = 1.6
var telegraph: float = 0.5
var damage: int = 1
var burst: int = 3            # tripwire 발사 수
var _t: float = 0.0
var _armed: bool = true        # tripwire: 발사 가능 상태
var _fire_t: float = -1.0      # tripwire: 트립 후 발사까지 카운트다운(>=0이면 충전 중)
var _burst_left: int = 0
var _burst_t: float = 0.0
var _player: Node2D = null

func setup(dir: Vector2, intv: float, phase: float, tel: float = 0.5, p_mode: String = "periodic") -> void:
	direction = dir.normalized()
	interval = maxf(0.5, intv)
	telegraph = clampf(tel, 0.1, interval - 0.1)
	_t = fposmod(phase, interval)
	mode = p_mode

func _ready() -> void:
	add_to_group("bullet_trap")
	z_index = 2

func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player

func _process(delta: float) -> void:
	if mode == "tripwire":
		_process_tripwire(delta)
	else:
		_t += delta
		if _t >= interval:
			_t -= interval
			_fire_one(direction)
	queue_redraw()

func _process_tripwire(delta: float) -> void:
	# 충전 중이면 발사 카운트다운.
	if _fire_t >= 0.0:
		_fire_t -= delta
		if _fire_t <= 0.0:
			_fire_t = -1.0
			_burst_left = burst
			_burst_t = 0.0
		return
	# 버스트 발사 중.
	if _burst_left > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_fire_one(direction)
			_burst_left -= 1
			_burst_t = 0.10
			if _burst_left <= 0:
				_t = 0.0  # 쿨다운 시작
		return
	# 쿨다운(재무장).
	if not _armed:
		_t += delta
		if _t >= interval:
			_armed = true
		return
	# 무장 상태 — 플레이어가 레이저 라인을 가로지르면 트립.
	var p := _get_player()
	if p == null:
		return
	var rel: Vector2 = p.global_position - global_position
	var along: float = rel.dot(direction)
	var perp: float = absf(rel.dot(Vector2(-direction.y, direction.x)))
	if along >= 0.0 and along <= LINE_LEN and perp <= 16.0:
		_armed = false
		_fire_t = telegraph  # 텔레그래프 후 버스트

func _fire_one(dir: Vector2) -> void:
	var host: Node = get_parent()
	if host == null:
		return
	var b := EnemyBullet.new()
	b.velocity = dir * SPEED
	b.damage = damage
	host.add_child(b)
	b.global_position = global_position + dir * 14.0
	SfxPlayer.play_at("enemy_patrol_fire", global_position)

# 충전/경고 강도 0~1.
func _glow() -> float:
	if mode == "tripwire":
		if _fire_t >= 0.0:
			return clampf(1.0 - _fire_t / telegraph, 0.0, 1.0)
		return 0.15 if _armed else 0.0
	var remaining: float = interval - _t
	if remaining > telegraph:
		return 0.0
	return clampf(1.0 - remaining / telegraph, 0.0, 1.0)

func _draw() -> void:
	var g: float = _glow()
	var perp := Vector2(-direction.y, direction.x)
	# 라인 — periodic은 위험 점선(텔레그래프 시 밝아짐), tripwire는 상시 레이저.
	if mode == "tripwire":
		var beam_a: float = 0.5 + 0.4 * g
		var laser: Color = COL_LASER * Color(1, 1, 1, beam_a)
		draw_line(direction * 14.0, direction * LINE_LEN, laser, 1.5 + 1.5 * g, true)
		# 끝점 발광
		draw_circle(direction * LINE_LEN, 3.0, laser)
	else:
		var line_col: Color = COL_HOT * Color(1, 1, 1, 0.10 + 0.55 * g)
		var seg: float = 16.0
		var n: int = int(LINE_LEN / seg)
		for i in range(0, n, 2):
			draw_line(direction * (float(i) * seg + 18.0), direction * (float(i + 1) * seg + 18.0), line_col, 2.0, true)
	# 장착 베이스(브래킷) — -direction 쪽 표면에 붙는 판. 부유 안 보이게.
	var base := PackedVector2Array([
		perp * 15.0 - direction * 16.0,
		-perp * 15.0 - direction * 16.0,
		-perp * 13.0 - direction * 9.0,
		perp * 13.0 - direction * 9.0,
	])
	draw_colored_polygon(base, COL_PORT.darkened(0.2))
	# 포탑 하우징.
	var housing := PackedVector2Array([
		perp * 12.0 - direction * 9.0,
		-perp * 12.0 - direction * 9.0,
		-perp * 9.0 + direction * 6.0,
		perp * 9.0 + direction * 6.0,
	])
	draw_colored_polygon(housing, COL_PORT)
	draw_polyline(_closed(housing), COL_EDGE, 1.5, true)
	# 구경 — 충전 글로우.
	draw_line(perp * 7.0 + direction * 4.0, -perp * 7.0 + direction * 4.0,
		COL_HOT * Color(1, 1, 1, 0.45 + 0.55 * g), 3.0, true)
	# ⚠ 경고 표식 — 하우징 뒤(장착면 쪽)에 작게. "파괴 불가 위험물" 단서.
	var wc: Vector2 = -direction * 22.0
	var tri := PackedVector2Array([wc + Vector2(0, -5), wc + Vector2(-5, 4), wc + Vector2(5, 4)])
	draw_polyline(_closed(tri), Color(1.0, 0.78, 0.2, 0.9), 1.5, true)
	draw_line(wc + Vector2(0, -2), wc + Vector2(0, 1.5), Color(1.0, 0.78, 0.2, 0.9), 1.5, true)

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(pts)
	if pts.size() > 0:
		out.append(pts[0])
	return out
