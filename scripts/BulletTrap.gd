class_name BulletTrap
extends Node2D

# 발사 함정 — 정해진 방향으로 주기적으로 총알을 쏘는 고정 함정(프로토타입).
# 발사 전 텔레그래프(구경이 충전되며 위험 라인이 밝아짐) → 플레이어가 타이밍·대시·글라이드로
# 라인을 건너게. 총알은 EnemyBullet 재사용(속도 240, 회피 가능). 기동/회피 스킬 가치 부여.
# MapData 레이아웃의 "traps" 배열로 배치, Stage._build_traps가 생성.

const SPEED: float = 240.0          # EnemyBullet.BASE_SPEED와 동일
const LINE_LEN: float = 384.0       # 위험 표시 라인 길이(탄 사거리와 동일)
const COL_PORT: Color = Color(0.16, 0.12, 0.10, 1.0)
const COL_EDGE: Color = Color(0.55, 0.40, 0.30, 1.0)
const COL_HOT: Color = Color(1.0, 0.55, 0.28)

var direction: Vector2 = Vector2.RIGHT
var interval: float = 1.6
var telegraph: float = 0.5
var damage: int = 1
var _t: float = 0.0

func setup(dir: Vector2, intv: float, phase: float, tel: float = 0.5) -> void:
	direction = dir.normalized()
	interval = maxf(0.5, intv)
	telegraph = clampf(tel, 0.1, interval - 0.1)
	_t = fposmod(phase, interval)

func _ready() -> void:
	add_to_group("bullet_trap")
	z_index = 2

func _process(delta: float) -> void:
	_t += delta
	if _t >= interval:
		_t -= interval
		_fire()
	queue_redraw()

# 발사 직전 telegraph초 동안 0→1로 충전.
func _glow() -> float:
	var remaining: float = interval - _t
	if remaining > telegraph:
		return 0.0
	return clampf(1.0 - remaining / telegraph, 0.0, 1.0)

func _fire() -> void:
	var host: Node = get_parent()
	if host == null:
		return
	var b := EnemyBullet.new()
	b.velocity = direction * SPEED
	b.damage = damage
	host.add_child(b)
	b.global_position = global_position + direction * 14.0
	SfxPlayer.play_at("enemy_patrol_fire", global_position)

func _draw() -> void:
	var g: float = _glow()
	var perp := Vector2(-direction.y, direction.x)
	# 위험 라인(점선) — 평소 흐릿, 텔레그래프 시 밝아짐.
	var line_col: Color = COL_HOT * Color(1, 1, 1, 0.10 + 0.55 * g)
	var seg: float = 16.0
	var n: int = int(LINE_LEN / seg)
	for i in range(0, n, 2):
		draw_line(direction * (float(i) * seg + 18.0), direction * (float(i + 1) * seg + 18.0), line_col, 2.0, true)
	# 에미터 하우징 — 방향 수직 슬롯(벽에 박힌 포트).
	var housing := PackedVector2Array([
		perp * 12.0 - direction * 9.0,
		-perp * 12.0 - direction * 9.0,
		-perp * 9.0 + direction * 6.0,
		perp * 9.0 + direction * 6.0,
	])
	draw_colored_polygon(housing, COL_PORT)
	draw_polyline(_closed(housing), COL_EDGE, 1.5, true)
	# 구경(aperture) — 충전 글로우.
	draw_line(perp * 7.0 + direction * 4.0, -perp * 7.0 + direction * 4.0,
		COL_HOT * Color(1, 1, 1, 0.45 + 0.55 * g), 3.0, true)

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(pts)
	if pts.size() > 0:
		out.append(pts[0])
	return out
