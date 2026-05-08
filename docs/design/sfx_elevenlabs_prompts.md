# ElevenLabs SFX 프롬프트 (Eyes on You)

각 항목은 [`sfx_list.md`](sfx_list.md)의 ID 1:1 대응. ElevenLabs sound effects는
영어 프롬프트가 잘 먹혀서 영어 위주. duration_seconds는 ElevenLabs UI의 길이
필드에 입력. prompt_influence는 0.4~0.6 권장 (너무 높이면 변주가 안 됨).

게임 톤: **사이버펑크 / 시설 침투 / 정밀한 SF**. 음악적이지 않게, 무톤(non-tonal)
또는 짧은 sub-bass. 화려한 effect보다 묵직하고 기능적인 느낌.

> **공통 prefix 추천(원하면 모든 프롬프트 앞에 붙임)**:
> `cyberpunk infiltration game sfx, dry studio recording, no music, no reverb tail, mono`

---

## 1. Player

### `player_jump` — 점프 (0.2s)
> Short pneumatic jump push, soft fabric whoosh with quick mechanical click at attack, dry, no reverb.

### `player_double_jump` — 이중 점프 (0.2s)
> Sharper aerial jump puff, slightly higher pitch than first jump, brief electronic shimmer overlay, no reverb.

### `player_land` — 착지 (0.25s)
> Soft thud of boots landing on metal grating, low frequency thump with very short metallic tap, dry.

### `player_dash` — 대시 (0.35s)
> Sharp horizontal whoosh with electric crackle layered, fast attack, very short tail, sci-fi dash.

### `player_hurt` — 피격 (0.3s)
> Quick masculine grunt cut short, layered with low metallic impact, no music, dry.

### `player_death` — 사망 (0.7s)
> Heavy body collapse on metal floor, single low thump fading into electronic data corruption glitch, no music.

### `player_step` — 발걸음 (0.15s, generate 4 variants)
> Soft single boot step on metal grating walkway, dry, mono, no reverb tail.

---

## 2. Combat — 사격 / 폭발

### `bullet_fire` — 플레이어 사격 (0.15s)
> Suppressed pistol shot, quick metallic pew with subtle electronic snap, very dry, no echo.

### `bullet_impact_wall` — 벽 명중 (0.1s)
> Sharp metallic ping of bullet hitting steel plate, single tick, very short.

### `bullet_impact_enemy` — 적 명중 (0.15s)
> Dull thud of bullet hitting armored body, low frequency punch with subtle wet impact, dry.

### `bullet_deflect_shield` — 방패 튕김 (0.25s)
> Loud metallic clang of bullet ricocheting off shield, bright high frequency ring with short tail.

### `bomb_throw` — 폭발물 투척 (0.2s)
> Quick airborne whoosh of small object thrown forward, dry, no reverb.

### `bomb_explode` — 폭발 (0.5s)
> Compact explosion, mid-low frequency thump with debris crackle, short controlled tail, no big reverb.

---

## 3. Enemy

### `enemy_patrol_fire` — 정찰병 사격 (0.15s)
> Standard pistol shot, slightly muffled compared to player, dry tactical fire.

### `enemy_sniper_charge` — 저격 텔레그래프 (0.45s)
> Rising electric hum charge-up, faint pulse rhythm, ends without release, sci-fi targeting laser warming up.

### `enemy_sniper_fire` — 저격 발사 (0.18s)
> Sharp cracking pew of high velocity sniper rifle, bright snap, very short tail.

### `enemy_drone_hover` — 드론 호버 (3s loop)
> Steady low electric drone hum, quadcopter rotor whine layered, seamless loop, no variation.

### `enemy_drone_drop` — 드론 폭탄 투하 (0.15s)
> Quick mechanical release click followed by faint object falling whoosh, dry.

### `enemy_bomber_beep` — 자폭 비프 (1.5s loop, accelerating)
> Electronic warning beep speeding up over time, simple pulse, sci-fi proximity alarm.

### `enemy_bomber_explode` — 자폭병 폭발 (0.6s)
> Closer compact explosion than bomb_explode, sharper attack, slight glass debris crackle.

### `enemy_hurt` — 적 피격 (0.12s)
> Brief mechanical buzz with subtle robotic hurt grunt, dry.

### `enemy_death` — 적 처치 (0.35s)
> Robotic shutdown thud, mid-low frequency drop with electronic dissipation tail.

---

## 4. Boss (SENTINEL)

### `boss_phase_change` — 페이즈 전환 (0.6s)
> Heavy mechanical impact with deep sub-bass slam, brief electronic surge tail, ominous sci-fi.

### `boss_charge_telegraph` — 돌진 텔레그래프 (0.35s)
> Rising mechanical hum-up with red alarm pulse, building tension without release, sci-fi.

### `boss_charge_dash` — 돌진 (0.7s)
> Massive horizontal whoosh of heavy machine charging forward, low rumble with metal scrape, intense.

### `boss_missile_launch` — 미사일 발사 (0.25s)
> Compact missile launch hiss with mechanical ka-chunk, dry, no reverb.

### `boss_hurt` — 보스 피격 (0.2s)
> Heavy metallic dull impact, deeper than enemy_hurt, brief electronic shudder.

### `boss_self_destruct_alarm` — 자폭 알람 (3s loop)
> Repeating loud mechanical alarm klaxon, urgent rhythm, slight metallic clang on each pulse, seamless loop.

### `boss_self_destruct_disarm` — 자폭 해제 (1.2s)
> Power-down hum descending in pitch, system relaxing, soft electronic sigh tail.

### `boss_death` — 보스 처치 (1.6s)
> Massive mechanical explosion with prolonged metallic tearing tail, sub-bass slam followed by debris and electric arcs fading.

---

## 5. Pickups

### `xp_collect` — XP orb 흡수 (0.18s)
> Tiny crystalline chime, single bright note, very short, sci-fi pickup ping.

### `hp_collect` — HP orb 흡수 (0.35s)
> Warm rising heal chime, two-note ascending, soft glow texture, no reverb.

### `levelup` — 레벨업 (0.7s)
> Triumphant ascending chime sequence, three-note rising sci-fi confirmation, mild crystalline shimmer.

### `skill_pick` — 스킬 카드 선택 (0.22s)
> Crisp digital confirm tick with subtle holographic sweep, dry, sci-fi UI.

### `skill_active_use` — 액티브 스킬 발동 (0.25s)
> Quick electric zap with mechanical release, sci-fi gadget activation, dry.

---

## 6. Environment / Hazards

### `spike_hit` — 가시 피격 (0.18s)
> Sharp metallic stab with single high-frequency ring and quick pain pulse, dry.

### `lever_pull` — 레버 당김 (0.35s)
> Mechanical lever ratchet click followed by heavy contact thunk, industrial, dry.

### `plate_step_inactive` — 비활성 발판 (0.2s)
> Dull metallic thump of foot on inactive pressure plate, no resonance, dead sound.

### `plate_step_active` — 활성 발판 (0.3s)
> Crisp pneumatic click with rising power-on chime, plate activating beneath foot, sci-fi.

### `hatch_open` — 비밀 해치 열림 (0.55s)
> Pneumatic ventilation hiss with metal panel sliding aside, brief mechanical motor whir.

### `drop_platform_descend` — 강하 발판 내려옴 (0.7s)
> Heavy mechanical platform lowering with hydraulic descent rumble, ends with soft thud landing.

### `gate_unlock` — 도전방 게이트 fade (0.55s)
> Magnetic lock disengaging with electric click, then heavy panel sliding away, sci-fi facility access.

### `siren_flash` — 사이렌 빨강 플래시 (0.8s)
> Two short alarm whoops in quick succession, urgent klaxon, danger warning, no reverb tail.

### `blackout_fade_in` — 도전 암전 fade (1.2s)
> Deep ominous sub-bass swell rising slowly, lights cutting out, oppressive sci-fi atmosphere, ends sustained.

### `challenge_clear` — 도전 클리어 (0.7s)
> Relieved ascending chime, breath of relief, sci-fi success confirmation, brief.

### `challenge_fail` — 도전 실패 (0.55s)
> Cutting buzzer error tone descending in pitch, abrupt failure, dry.

---

## 7. UI / Menu

### `ui_focus` — 포커스 이동 (0.06s)
> Tiny digital tick, single high frequency click, very short, UI navigation.

### `ui_confirm` — 확정 (0.14s)
> Soft sci-fi confirmation chime, two-tone ascending, brief, no reverb.

### `ui_cancel` — 취소 (0.12s)
> Low descending UI click, brief negative feedback tone, dry.

### `ui_slider_tick` — 슬라이더 변경 (0.05s)
> Micro digital tick at very low volume, single grain, very short.

### `ui_pause_open` — 일시정지 진입 (0.25s)
> Muffled woosh as if pulling away from world, slight low frequency drop, sci-fi pause.

---

## 8. Story / Special

### `veil_subtitle_in` — VEIL 자막 등장 (0.12s)
> Subtle digital chirp, brief data transmission tick, sci-fi communicator, very faint.

### `arcturus_enter` — ARCTURUS 진입 (0.9s)
> Deep ominous sub-bass swell with paper-like rustle and time-stop hush, mysterious archive opening.

### `terminal_typewrite` — 단말기 타이핑 (0.05s, generate as one-shot click; loop in code)
> Single mechanical key click of old terminal keyboard, very dry, very short.

### `bestiary_first_seen` — 도감 첫 조우 (0.35s)
> Deep contemplative chime, single resonant note, sci-fi catalog entry, brief.

### `stage_clear_chime` — stage 클리어 (0.7s)
> Brief relieving fanfare, three ascending notes, breath of accomplishment, sci-fi.

### `boss_alert_text` — 보스 강조 자막 (0.3s)
> Sharp alarm sting with single high-frequency stab, danger emphasis, brief.

---

## 사용 팁

- ElevenLabs는 동일 프롬프트로도 매 생성마다 결과가 다름. 마음에 드는 결과 안
  나오면 같은 프롬프트로 2~3번 재생성.
- `_step` / `_hurt` 같이 변주가 필요한 SFX는 같은 프롬프트로 여러 개 받아 코드에서
  랜덤 재생 (`SfxPlayer.play_random("player_step", count=4)` 패턴).
- loop 항목(`drone_hover`, `bomber_beep`, `self_destruct_alarm`)은 ElevenLabs
  결과 자체가 깔끔히 loop되지 않을 수 있음 — 받은 후 Audacity 등에서 zero-crossing
  맞춰 trim.
- 결과 mp3/wav는 `assets/sfx/<id>.ogg`로 저장(웹 빌드 호환). Godot 4.6은 mp3도
  지원하지만 ogg가 가벼움.
- 길이 의도와 다르게 길게 나오면 ElevenLabs에서 trim 또는 prompt_influence
  올려서 재생성.
