extends Node

# 효과음 재생기. autoload — scene 전환에도 살아남는다.
# `assets/sfx/<id>.ogg` 또는 `<id><N>.ogg` (1~9 variant) 파일을 자동 등록.
# variant 패턴: `player_hurt1.ogg`, `player_hurt2.ogg` → SfxPlayer.play("player_hurt")
# 한 번 호출 시 등록된 variant 중 하나 무작위 재생.
#
# 풀링 — POOL_SIZE 개의 AudioStreamPlayer를 round-robin. 짧은 SFX 동시 재생 처리.

const POOL_SIZE: int = 8
const BASE_DB: float = -6.0
const SILENT_DB: float = -80.0

# SFX별 dB 보정 — 어떤 효과음은 너무 크고 어떤 건 너무 작아서 mixing 균형용.
# 사용자 피드백 기반(2026-05-09): jump/double_jump 너무 큼, step/land 거의 안 들림.
# 양수 = 더 크게, 음수 = 더 작게.
const VOLUME_OFFSETS: Dictionary = {
	"player_jump":        -10.0,
	"player_step":        6.0,
	"player_land":        5.0,
	"player_dash":        -8.0,
	"player_hurt":        -0.0,
	"player_death":       0.0,
	# 2026-05-16 사용자 피드백 기반 보정.
	"bullet_fire":        -8.0,   # 사격 너무 큼 — 연발이라 더 신경 쓰임
	"bullet_impact_wall": -5.0,   # 벽 충돌음 큼
	"bomb_throw":         4.0,    # 거의 안 들림
	"bomb_explode":       6.0,    # 너무 작음
	"enemy_hurt":         -4.0,   # 적 피격 큼
	"enemy_drone_hover":  6.0,    # 거의 안 들림
	"enemy_drone_drop":   -8.0,   # 너무 큼
}

# 알려진 SFX ID 목록. 새 파일 추가하면 여기 등록 (또는 _register_sfx 직접 호출).
# sfx_list.md의 ID와 1:1.
# 파일 확장자: .mp3 / .ogg / .wav 모두 시도 — ElevenLabs는 MP3 출력이라 보통 mp3.
const _SFX_EXTENSIONS: Array[String] = [".mp3", ".ogg", ".wav"]

const KNOWN_SFX: Array[String] = [
	# Player (더블점프는 player_jump 재사용 — 별도 ID 없음)
	"player_jump", "player_land", "player_dash",
	"player_hurt", "player_death", "player_step",
	# Combat
	"bullet_fire", "bullet_impact_wall", "bullet_impact_enemy", "bullet_deflect_shield",
	"bomb_throw", "bomb_explode",
	# Enemy
	"enemy_patrol_fire", "enemy_sniper_charge", "enemy_sniper_fire",
	"enemy_drone_hover", "enemy_drone_drop",
	"enemy_bomber_beep", "enemy_bomber_explode",
	"enemy_hurt", "enemy_death",
	# Boss — BossSentinel은 charge 공격 없음(bomb + missile + self-destruct only).
	# 기존 KNOWN_SFX에 있던 boss_charge_* 항목은 코드와 불일치라 제거.
	"boss_phase_change", "boss_missile_launch", "boss_hurt",
	"boss_self_destruct_alarm", "boss_self_destruct_disarm", "boss_death",
	# Pickups
	"xp_collect", "hp_collect", "levelup", "skill_pick", "skill_active_use",
	# Environment
	"spike_hit", "lever_pull", "plate_step_inactive", "plate_step_active",
	"hatch_open", "drop_platform_descend", "gate_unlock",
	"siren_flash", "blackout_fade_in", "challenge_clear", "challenge_fail",
	# UI
	"ui_focus", "ui_confirm", "ui_cancel", "ui_slider_tick", "ui_pause_open",
	# Story / special
	"veil_subtitle_in", "arcturus_enter", "terminal_typewrite",
	"bestiary_first_seen", "stage_clear_chime", "boss_alert_text",
]

var _players: Array[AudioStreamPlayer] = []
var _next_idx: int = 0
# id → Array[AudioStream]. 길이 0이면 미등록(아직 파일 없음) — play() 호출 시 무시.
var _streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = SILENT_DB
		add_child(p)
		_players.append(p)
	for id in KNOWN_SFX:
		_register_sfx(id)

# 한 SFX의 모든 variant를 스캔해 등록. base(번호 없음) + 1~9 variant 시도.
# 확장자는 mp3/ogg/wav 순으로 첫 매치 사용.
# ResourceLoader.exists로 사전 체크 → 웹 빌드에서 누락 파일 로드 에러 방지.
func _register_sfx(id: String) -> void:
	var variants: Array = []
	var base: AudioStream = _try_load_with_ext(id)
	if base != null:
		variants.append(base)
	for i in range(1, 10):
		var v: AudioStream = _try_load_with_ext("%s%d" % [id, i])
		if v != null:
			variants.append(v)
	if not variants.is_empty():
		_streams[id] = variants

func _try_load_with_ext(name: String) -> AudioStream:
	for ext in _SFX_EXTENSIONS:
		var path: String = "res://assets/sfx/%s%s" % [name, ext]
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path) as AudioStream
			if s != null:
				# MP3는 기본 looping이지만 짧은 SFX는 loop=false여야 한 번만 재생.
				if s is AudioStreamMP3:
					(s as AudioStreamMP3).loop = false
				return s
	return null

# 효과음 재생. id 미등록(파일 없음) 또는 sfx 볼륨 0 시 no-op.
# volume_offset_db: 호출 사이트에서 추가 보정. VOLUME_OFFSETS의 기본 보정에 더해짐.
func play(id: String, volume_offset_db: float = 0.0) -> void:
	if not _streams.has(id):
		return
	var variants: Array = _streams[id]
	if variants.is_empty():
		return
	var stream: AudioStream = variants[randi() % variants.size()]
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_next_idx]
	_next_idx = (_next_idx + 1) % _players.size()
	player.stream = stream
	var preset_offset: float = float(VOLUME_OFFSETS.get(id, 0.0))
	player.volume_db = _target_db() + preset_offset + volume_offset_db
	player.play()

func _target_db() -> float:
	var v: float = clampf(GameState.sfx_volume, 0.0, 1.0)
	if v <= 0.001:
		return SILENT_DB
	return BASE_DB + linear_to_db(v)
