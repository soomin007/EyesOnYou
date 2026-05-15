# 효과음 목록 (SFX)

`assets/sfx/<id>.mp3`로 채울 효과음 전수 목록. 코드에서는 `SfxPlayer.play(id)`로 호출.
각 항목은 짧은 단발(0.1~1.5s) 또는 명시된 loop. 볼륨은 `GameState.sfx_volume` 슬라이더 ×
`SfxPlayer.VOLUME_OFFSETS[id]` 보정으로 결정.

## 표기
- **상태**: ✅ 파일 존재 + 코드 wire-up 완료 / ⬜ 미작업 / ⚠ 파일은 있으나 미사용 또는 미연결
- **우선순위 P0~P2**: P0 핵심 피드백 / P1 시스템 보강 / P2 분위기 연출
- **트리거 코드**: 실제 `SfxPlayer.play()` 호출 위치 (파일:심볼 단위)

## ElevenLabs 사용 가이드
- 영문 prompt가 잘 먹힘. duration_seconds는 ElevenLabs UI에 그대로 입력. prompt_influence 0.4~0.6 권장.
- 게임 톤: **사이버펑크 / 시설 침투 / 정밀한 SF**. 음악적이지 않게, 무톤(non-tonal) 또는 짧은 sub-bass.
- 공통 prefix(원하면 모든 prompt 앞에 붙임): `cyberpunk infiltration game sfx, dry studio recording, no music, no reverb tail, mono`
- loop 항목(`drone_hover`, `bomber_beep`, `self_destruct_alarm`)은 결과를 Audacity에서 zero-crossing trim 필요.
- 변주 필요한 SFX(`player_step`, `player_hurt`)는 같은 prompt로 N개 생성 → 코드가 자동으로 `<id>1`, `<id>2` … 인식.

---

## 1. Player

### `player_jump` ✅ P0 (0.2s)
- **트리거**: `Player.gd::_do_jump` (첫 점프 + 더블 점프 둘 다 재사용)
- **현재 보정**: `-10dB` (사용자 피드백 — 너무 큼)
- **prompt**: Short pneumatic jump push, soft fabric whoosh with quick mechanical click at the attack, dry, no reverb.

### `player_land` ✅ P1 (0.25s)
- **트리거**: `Player.gd::_handle_input` floor 착지 순간
- **현재 보정**: `+5dB`
- **prompt**: Soft thud of boots landing on metal grating, low frequency thump with very short metallic tap, dry.

### `player_dash` ✅ P0 (0.35s)
- **트리거**: `Player.gd::_do_dash`
- **현재 보정**: `-8dB`
- **prompt**: Sharp horizontal whoosh with electric crackle layered, fast attack, very short tail, sci-fi dash.

### `player_hurt` ✅ P0 (0.3s, 3 variants)
- **트리거**: `Player.gd::take_hit`
- **prompt**: Quick masculine grunt cut short, layered with low metallic impact, no music, dry. (variant마다 grunt 톤 살짝 다르게)

### `player_death` ✅ P0 (0.7s)
- **트리거**: `Player.gd::take_hit` hp 0 분기
- **prompt**: Heavy body collapse on metal floor, single low thump fading into electronic data corruption glitch, no music.

### `player_step` ✅ P2 (0.15s, 4 variants)
- **트리거**: `Player.gd::_handle_input` 이동 중 timer
- **현재 보정**: `+6dB`
- **prompt**: Soft single boot step on metal grating walkway, dry, mono, no reverb tail.

---

## 2. Combat — 사격 / 폭발

### `bullet_fire` ✅ P0 (0.15s)
- **트리거**: `Player.gd::_try_attack` (multishot이어도 1회)
- **현재 보정**: `-8dB` (너무 큼 — 연발이라 더 부담)
- **prompt**: Suppressed pistol shot, quick metallic pew with subtle electronic snap, very dry, no echo. Tight low-mid body, no high sizzle.

### `bullet_impact_wall` ✅ P1 (0.1s)
- **트리거**: `Bullet.gd::_on_body_entered` StaticBody2D 충돌 (단, `boundary_wall` 그룹 제외 — 맵 끝 경계벽은 무음)
- **현재 보정**: `-5dB`
- **prompt**: Single sharp metallic ping of small caliber bullet hitting steel plate, very short tick, no decay, dry.

### `bullet_impact_enemy` ✅ P0 (0.15s)
- **트리거**: `Enemy.gd::take_damage` / `TutorialDummy.gd::take_damage` (from_dir != 0, 방패 막힘 제외)
- **prompt**: Dull thud of bullet hitting armored synthetic body, low frequency punch with subtle soft impact, dry, no ring.

### `bullet_deflect_shield` ✅ P0 (0.25s)
- **트리거**: `Enemy.gd::take_damage` SHIELD 정면 막힘 + `TutorialDummy.gd::take_damage` 스킬 더미 튕김
- **prompt**: Loud metallic clang of bullet ricocheting off heavy steel shield, bright high frequency ring with short tail, sci-fi armor deflect.

### `bomb_throw` ✅ P0 (0.2s)
- **트리거**: `Bomb.gd::_ready` (드론·보스 양쪽 자동 커버)
- **현재 보정**: `+4dB` (거의 안 들림)
- **prompt**: Quick airborne whoosh of small grenade tossed forward, light tail with subtle metallic hiss, dry.

### `bomb_explode` ✅ P0 (0.5s)
- **트리거**: `Bomb.gd::_explode`
- **현재 보정**: `+6dB`
- **prompt**: Compact close-range explosion, mid-low frequency thump with debris crackle and brief shrapnel hiss, short controlled tail, no big reverb.

---

## 3. Enemy

### `enemy_patrol_fire` ✅ P0 (0.18s)
- **트리거**: `Enemy.gd::_patrol_fire` (Patrol FIRING 상태에서 `EnemyBullet` 발사 시)
- **prompt**: Mid-range military pistol shot, slightly muffled and heavier than player_fire, single dry crack with very small low-end punch, no high sparkle.

### `enemy_sniper_charge` ✅ P0 (0.45s)
- **트리거**: `Enemy.gd::_start_aim` (조준선 생성 순간)
- **prompt**: Rising electric hum charge-up, faint pulsing rhythm at increasing rate, ends WITHOUT release/click, sci-fi targeting laser warming up. Should sound incomplete on its own — paired with sniper_fire.

### `enemy_sniper_fire` ✅ P0 (0.18s)
- **트리거**: `Enemy.gd::_fire_at_player`
- **prompt**: Sharp cracking high-velocity rifle shot, bright snap with brief tail, distinctly louder and harsher than enemy_patrol_fire, single shot only.

### `enemy_drone_hover` ✅ P1 (3s seamless loop)
- **트리거**: `Enemy.gd::_tick_drone` hover_ok false→true 전환 시 1회 (현재는 loop 미지원 — 단발 재생)
- **현재 보정**: `+6dB` (거의 안 들림)
- **prompt**: Steady low electric drone hum with quadcopter rotor whine layered on top, seamless 3-second loop, no variation across the loop. Quiet enough to underlay other sfx but with audible rotor texture.

### `enemy_drone_drop` ✅ P1 (0.2s)
- **트리거**: `Enemy.gd::_drop_bomb` (드론이 폭탄 투하 직전)
- **현재 보정**: `-8dB` (너무 큼)
- **prompt**: Brief mechanical release click followed by faint object detachment whoosh, dry, subtle. NOT explosive — just the moment of release.

### `enemy_bomber_beep` ✅ P0 (1.5s, loop+accelerating recommended)
- **트리거**: `Enemy.gd::_tick_bomber` ARMING 진입 1회 (현재 단발 — 추후 loop 전환 검토)
- **prompt**: Electronic warning beep that accelerates from slow (≈3Hz) to fast (≈10Hz) over 1.5 seconds, single pulse tone, sci-fi proximity arming alarm. Each pulse should be very short and clean.

### `enemy_bomber_explode` ✅ P0 (0.6s)
- **트리거**: `Enemy.gd::_bomber_explode`
- **prompt**: Closer compact explosion than bomb_explode, sharper attack, slight glass-and-metal debris crackle, brief sub-bass thump under, no long tail.

### `enemy_hurt` ✅ P0 (0.12s, variants OK)
- **트리거**: `Enemy.gd::take_damage` (hp > 0)
- **현재 보정**: `-4dB`
- **prompt**: Brief mechanical buzz layered with a subtle low robotic grunt, dry. Short — should not linger past 0.15s.

### `enemy_death` ✅ P0 (0.35s)
- **트리거**: `Enemy.gd::_die` (Bomber 제외 — `_bomber_explode`가 죽음 소리 역할)
- **prompt**: Robotic shutdown thud, mid-low frequency drop with brief electronic dissipation tail and tiny servo whine fading out.

---

## 4. Boss (SENTINEL)

### `boss_phase_change` ⬜ P0 (0.6s)
- **트리거**: `BossSentinel.gd::_transition_to` (P1→P2, P2→P3 진입 순간)
- **prompt**: Heavy mechanical impact with deep sub-bass slam, brief electronic surge tail, ominous sci-fi power-up. Should feel weighty and final — the boss is entering a new phase.

### `boss_missile_launch` ⬜ P1 (0.25s)
- **트리거**: `BossSentinel.gd::_fire_missiles` (좌/우 두 발이지만 1회 재생)
- **prompt**: Compact twin missile launch hiss with mechanical ka-chunk, dry, slight metallic resonance, no reverb. Two-burst feel implied even though it's a single sample.

### `boss_hurt` ⬜ P1 (0.2s)
- **트리거**: `BossSentinel.gd::take_damage` (hp > 0)
- **prompt**: Heavy metallic dull impact, deeper and more resonant than enemy_hurt, brief electronic shudder tail, NO grunt — purely mechanical.

### `boss_self_destruct_alarm` ⬜ P0 (3s seamless loop)
- **트리거**: `BossSentinel.gd::_arm_self_destruct` (HP가 HP_SELF_DESTRUCT 이하로 떨어진 순간 — 현재 단발 재생, 추후 loop 전환 검토)
- **prompt**: Loud urgent mechanical klaxon repeating roughly every 0.6s, slight metallic clang on each pulse, low-mid alarm tone, seamless 3-second loop, dread-inducing sci-fi self-destruct warning.

### `boss_self_destruct_disarm` ⬜ P1 (1.2s)
- **트리거**: `BossSentinel.gd::_die` (자폭 전 처치한 경우 — 카운트다운 진행 중)
- **prompt**: Power-down hum descending in pitch over 1 second, system relaxing, soft electronic sigh tail. Sense of relief — the threat just got neutralized.

### `boss_death` ⬜ P0 (1.6s)
- **트리거**: `BossSentinel.gd::_die`
- **prompt**: Massive mechanical explosion with prolonged metallic tearing tail, sub-bass slam followed by debris and brief electric arcs fading. Should sound bigger than enemy_bomber_explode.

> **제거됨**: `boss_charge_telegraph` / `boss_charge_dash` — BossSentinel은 charge 공격이 없음 (bomb + missile + self-destruct only). 기존 design doc 잔재.

---

## 5. Pickups / Skills

### `xp_collect` ⬜ P0 (0.18s)
- **트리거**: `ExpOrb.gd` magnet 흡수
- **prompt**: Tiny crystalline chime, single bright high-frequency note, very short, sci-fi pickup ping. Should be poly-able (many can play overlapping).

### `hp_collect` ⬜ P0 (0.35s)
- **트리거**: `HpOrb.gd` 흡수
- **prompt**: Warm rising heal chime, two-note ascending interval, soft glow texture, no reverb, restorative sci-fi feel.

### `levelup` ⬜ P0 (0.7s)
- **트리거**: `LevelUpOverlay.gd` 진입
- **prompt**: Triumphant ascending three-note chime sequence, sci-fi confirmation, mild crystalline shimmer, no big reverb, decisive.

### `skill_pick` ⬜ P1 (0.22s)
- **트리거**: `LevelUpOverlay.gd` 카드 confirm
- **prompt**: Crisp digital confirm tick with subtle holographic sweep, dry, sci-fi UI selection.

### `skill_active_use` ⬜ P0 (0.25s)
- **트리거**: `Player.gd::_try_skill` (액티브 스킬 발동 — 폭발물 등)
- **prompt**: Quick electric zap with mechanical release, sci-fi gadget activation, dry, focused punch.

---

## 6. Environment / Hazards

### `spike_hit` ⬜ P0 (0.18s)
- **트리거**: `Stage.gd` spike 충돌 처리
- **prompt**: Sharp metallic stab with single high-frequency ring and quick pain pulse, dry, brief.

### `lever_pull` ⬜ P0 (0.35s)
- **트리거**: `LeverInteractable.gd::try_pull`
- **prompt**: Mechanical lever ratchet click followed by heavy contact thunk, industrial old-facility feel, dry.

### `plate_step_inactive` ⬜ P2 (0.2s)
- **트리거**: `PressurePlate.gd` armed=false 상태에서 step
- **prompt**: Dull metallic thump of foot on inactive pressure plate, no resonance, dead muted sound. Should feel ignored.

### `plate_step_active` ⬜ P0 (0.3s)
- **트리거**: `PressurePlate.gd` armed plate stepped
- **prompt**: Crisp pneumatic click with rising power-on chime, plate activating beneath foot, sci-fi affirmative.

### `hatch_open` ⬜ P1 (0.55s)
- **트리거**: `Stage.gd::_open_hatch`
- **prompt**: Pneumatic ventilation hiss with metal panel sliding aside, brief mechanical motor whir, sci-fi maintenance hatch.

### `drop_platform_descend` ⬜ P1 (0.7s)
- **트리거**: `Stage.gd::_descend_drop_platform`
- **prompt**: Heavy mechanical platform lowering with hydraulic descent rumble, ends with soft thud landing.

### `gate_unlock` ⬜ P0 (0.55s)
- **트리거**: `Stage.gd` 도전방 게이트 fade
- **prompt**: Magnetic lock disengaging with electric click, then heavy panel sliding away, sci-fi facility access grant.

### `siren_flash` ⬜ P0 (0.8s)
- **트리거**: `Stage.gd::_play_siren_flash`
- **prompt**: Two short alarm whoops in quick succession (≈0.3s apart), urgent klaxon, danger warning, no reverb tail.

### `blackout_fade_in` ⬜ P1 (1.2s)
- **트리거**: challenge_dark_root fade in
- **prompt**: Deep ominous sub-bass swell rising slowly, lights cutting out feeling, oppressive sci-fi atmosphere, ends sustained.

### `challenge_clear` ⬜ P0 (0.7s)
- **트리거**: 도전방 골 도달
- **prompt**: Relieved ascending chime, breath of accomplishment, sci-fi success confirmation, brief.

### `challenge_fail` ⬜ P0 (0.55s)
- **트리거**: `Stage.gd::_challenge_fail`
- **prompt**: Cutting buzzer error tone descending in pitch, abrupt failure signal, dry, no tail.

---

## 7. UI / Menu

### `ui_focus` ⬜ P1 (0.06s)
- **트리거**: 메뉴 버튼 focus_entered
- **prompt**: Tiny digital tick, single high-frequency click, very short, UI navigation feedback.

### `ui_confirm` ⬜ P0 (0.14s)
- **트리거**: 메뉴 버튼 pressed
- **prompt**: Soft sci-fi confirmation chime, two-tone ascending, brief, no reverb.

### `ui_cancel` ⬜ P1 (0.12s)
- **트리거**: ESC / B
- **prompt**: Low descending UI click, brief negative feedback tone, dry.

### `ui_slider_tick` ⬜ P2 (0.05s)
- **트리거**: volume slider 값 변경
- **prompt**: Micro digital tick at very low volume, single grain, very short.

### `ui_pause_open` ⬜ P2 (0.25s)
- **트리거**: pause overlay open
- **prompt**: Muffled woosh as if pulling away from the world, slight low frequency drop, sci-fi pause-in.

---

## 8. Story / Special

### `veil_subtitle_in` ⬜ P2 (0.12s)
- **트리거**: VEIL 자막 fade in
- **prompt**: Subtle digital chirp, brief data transmission tick, sci-fi communicator, very faint — should not interrupt the line.

### `arcturus_enter` ⬜ P1 (0.9s)
- **트리거**: `ArcturusDocumentOverlay.gd` 진입
- **prompt**: Deep ominous sub-bass swell with paper-like rustle and time-stop hush, mysterious archive opening, sense of stepping into something older.

### `terminal_typewrite` ⬜ P2 (0.05s, one-shot click; code loops per char)
- **트리거**: ARCTURUS 문서 타자 per-char
- **prompt**: Single mechanical key click of old terminal keyboard, very dry, very short, no resonance.

### `bestiary_first_seen` ⬜ P2 (0.35s)
- **트리거**: `BestiaryData.gd::mark_enemy_seen` 첫 조우
- **prompt**: Deep contemplative chime, single resonant note, sci-fi catalog entry, brief but weighty.

### `stage_clear_chime` ⬜ P1 (0.7s)
- **트리거**: `Stage.gd::_begin_clear_sequence`
- **prompt**: Brief relieving fanfare, three ascending notes, breath of accomplishment, sci-fi, no big reverb.

### `boss_alert_text` ⬜ P1 (0.3s)
- **트리거**: `Stage.gd::_show_boss_alert`
- **prompt**: Sharp alarm sting with single high-frequency stab, danger emphasis, brief.

---

## 구현 순서 권장

1. **Boss (P0)** — `boss_phase_change` / `boss_self_destruct_alarm` / `boss_death`. 코드 wire-up은 이미 끝나있고 파일만 추가하면 됨. 클라이맥스 임팩트 최우선.
2. **Pickups (P0)** — `xp_collect` / `hp_collect` / `levelup`. 진행 보상 피드백 — 매 적 처치마다 들음.
3. **Environment (P0)** — `lever_pull` / `plate_step_active` / `siren_flash` / `spike_hit` / `gate_unlock` / `challenge_clear`·`fail`. 환경 인터랙션 학습 강화.
4. **UI (P0~P1)** — `ui_confirm` / `skill_active_use` / `skill_pick`. 메뉴·스킬 피드백.
5. **나머지 P1~P2** — 환경/연출 보강 + Story SFX.

## 코드 연결 메모

- 파일 위치: `assets/sfx/<id>.mp3`. 확장자 mp3/ogg/wav 모두 가능 (`SfxPlayer._SFX_EXTENSIONS` 순서대로 시도).
- variant: `<id>1.mp3`, `<id>2.mp3` … 자동 등록. `SfxPlayer.play(id)`가 무작위 하나 재생.
- 볼륨 보정은 `scripts/SfxPlayer.gd::VOLUME_OFFSETS` 사전에 dB 값 추가.
- loop SFX(`drone_hover`, `bomber_beep`, `self_destruct_alarm`)는 현재 단발 재생 — 추후 loop 지원 추가 시 별도 처리 필요.
- 신규 SFX ID 추가 시 `KNOWN_SFX` 배열에도 등록.
