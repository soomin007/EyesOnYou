# 효과음 목록 (SFX)

직접 만들어 채울 효과음 전수 목록. 사용 위치 + 톤 가이드 + 우선순위.
파일 포맷은 `.ogg` 권장(웹 빌드 호환). 각 항목은 짧은 단발(0.1~1.5s) 또는 명시된
loop. 볼륨은 게임 안 `GameState.sfx_volume` 슬라이더에 연결될 예정.

## 우선순위 표기
- **P0** — 게임의 기본 행동 피드백. 빠지면 즉시 어색함.
- **P1** — 시스템 보강. 빠져도 플레이는 가능하지만 quality 큰 차이.
- **P2** — 분위기·연출. 있으면 좋고, 없어도 큰 문제 없음.

---

## 1. Player

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `player_jump` | 점프 | `Player._do_jump` | 짧은 woosh 0.15s | P0 |
| `player_double_jump` | 이중 점프 | 두 번째 점프 | 첫 점프와 다른 톤 (살짝 높게) | P0 |
| `player_land` | 착지 | floor에 닿는 순간 | 부드러운 thud 0.2s | P1 |
| `player_dash` | 대시 | `Player._do_dash` | sharp woosh + 미세 잔향 0.3s | P0 |
| `player_hurt` | 피격 | `Player.take_hit` | 짧은 그르렁 / 흠칫 0.3s | P0 |
| `player_death` | 사망 | hp 0 → death 전환 | 호흡 끊김 + 다운 톤 0.6s | P0 |
| `player_step` | 발걸음 | 이동 중 일정 간격 | 가벼운 step (loop 또는 timer) | P2 |

## 2. Combat — 사격 / 폭발

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `bullet_fire` | 플레이어 사격 | `Bullet` 생성 | 짧은 pew 0.1s | P0 |
| `bullet_impact_wall` | 벽/플랫폼 명중 | bullet과 world 충돌 | 짧은 click 0.08s | P1 |
| `bullet_impact_enemy` | 적 명중 | bullet 적중 시 | 둔탁한 hit 0.12s | P0 |
| `bullet_deflect_shield` | 방패병 튕김 | shield enemy bullet 튕김 | 금속 clang 0.2s | P0 |
| `bomb_throw` | 폭발물 투척 | `Bomb` 생성 | 짧은 whoosh 0.15s | P0 |
| `bomb_explode` | 폭발 | Bomb 터질 때 | 묵직한 boom + 잔향 0.4s | P0 |

## 3. Enemy

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `enemy_patrol_fire` | 정찰병 사격 | patrol 발사 | 작은 pew (player보다 둔하게) | P0 |
| `enemy_sniper_charge` | 저격수 조준 텔레그래프 | sniper TELEGRAPH | 짧은 hum + 미세 펄스 0.4s | P0 |
| `enemy_sniper_fire` | 저격수 발사 | sniper 발사 | 날카로운 cracking pew 0.15s | P0 |
| `enemy_drone_hover` | 드론 호버 | drone 활성 동안 loop | 낮은 미세 hum (loop) | P1 |
| `enemy_drone_drop` | 드론 폭탄 투하 | drone bomb 생성 | 짧은 release click | P1 |
| `enemy_bomber_beep` | bomber 자폭 카운트 | bomber 활성 임박 | 빨라지는 비프 (loop+pitch up) | P0 |
| `enemy_bomber_explode` | bomber 자폭 | bomber 터질 때 | bomb_explode와 다른 톤 — 더 가까이 | P0 |
| `enemy_hurt` | 적 피격 | `Enemy.take_hit` | 짧은 흠칫 0.1s | P0 |
| `enemy_death` | 적 처치 | `Enemy.killed` emit | 작은 thud + dissipate 0.3s | P0 |

## 4. Boss (SENTINEL)

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `boss_phase_change` | 페이즈 전환 | `BossSentinel.phase_changed` | 묵직한 impact + 잔향 0.5s | P0 |
| `boss_charge_telegraph` | 돌진 텔레그래프 | TELEGRAPH 진입 | 빨강 깜빡과 동기. 짧은 hum-up 0.3s | P0 |
| `boss_charge_dash` | 돌진 | CHARGING 진입 | 큰 woosh + 진동 0.6s | P0 |
| `boss_missile_launch` | 미사일 발사 | BossMissile 생성 | 발사 woosh 0.2s | P1 |
| `boss_hurt` | 보스 피격 | hp 감소 | enemy_hurt보다 훨씬 둔탁 | P1 |
| `boss_self_destruct_alarm` | 자폭 카운트다운 알람 | `self_destruct_started` | 5초 동안 비프 loop | P0 |
| `boss_self_destruct_disarm` | 자폭 해제 | `self_destruct_disarmed` | 안도하는 페이드 1.2s | P1 |
| `boss_death` | 보스 처치 | `BossSentinel.killed` | 큰 폭발 + 잔향 1.5s | P0 |

## 5. Pickups

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `xp_collect` | XP orb 흡수 | `ExpOrb` magnet | 작은 chime 0.15s | P0 |
| `hp_collect` | HP orb 흡수 | `HpOrb` 흡수 | 부드러운 heal 0.3s | P0 |
| `levelup` | 레벨업 발생 | `LevelUpOverlay` 진입 | 상승하는 chime 0.6s | P0 |
| `skill_pick` | 스킬 카드 선택 | LevelUp 카드 confirm | 짧은 confirm 0.2s | P1 |
| `skill_active_use` | 액티브 스킬 발동 | `Player._try_skill` (폭발물 등) | 짧은 zap 0.2s | P0 |

## 6. Environment / Hazards

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `spike_hit` | 가시 피격 | `_on_spike_touched` | 날카로운 metal stab 0.15s | P0 |
| `lever_pull` | 레버 당김 | `LeverInteractable.try_pull` | 기계 ratchet click 0.3s | P0 |
| `plate_step_inactive` | 비활성 발판 step | require_armed plate (armed=false) | 둔탁한 thump (피드백 X 시각화) | P2 |
| `plate_step_active` | 활성 발판 step | armed plate stepped | 청량한 click + chime 0.25s | P0 |
| `hatch_open` | 비밀 해치 fade | `_open_hatch` | 부드러운 ventilation hiss 0.5s | P1 |
| `drop_platform_descend` | 강하 발판 내려옴 | `_descend_drop_platform` | 묵직한 rumble 0.6s | P1 |
| `gate_unlock` | 도전방 게이트 fade | `_start_challenge_run` 게이트 자리 | 자석 unlock + slide 0.5s | P0 |
| `siren_flash` | 사이렌 빨강 플래시 | `_play_siren_flash` | 짧은 alarm whoop ×2 (총 0.7s) | P0 |
| `blackout_fade_in` | 도전 암전 fade | challenge_dark_root fade in | 잠긴 듯한 sub-bass swell 1.0s | P1 |
| `challenge_clear` | 도전 클리어 | 도전 골 도달 | 안도 + 상승 chime 0.6s | P0 |
| `challenge_fail` | 도전 실패 | `_challenge_fail` | 끊기는 buzzer + 다운 0.5s | P0 |

## 7. UI / Menu

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `ui_focus` | 포커스 이동 | 버튼 focus_entered | 미세한 tick 0.05s | P1 |
| `ui_confirm` | 확정 | 버튼 pressed | 부드러운 confirm 0.12s | P0 |
| `ui_cancel` | 취소 / 뒤로 | ESC / B | 낮은 tick 0.1s | P1 |
| `ui_slider_tick` | 슬라이더 변경 | volume slider 값 변경 | 매우 짧은 micro tick 0.04s | P2 |
| `ui_pause_open` | 일시정지 메뉴 진입 | pause overlay open | 살짝 muffled woosh 0.2s | P2 |

## 8. Story / Special

| ID | 설명 | 트리거 | 톤 / 길이 | 우선 |
|---|---|---|---|---|
| `veil_subtitle_in` | VEIL 자막 등장 | `_show_veil_subtitle` fade in | 미세한 데이터 chirp 0.1s | P2 |
| `arcturus_enter` | ARCTURUS 시퀀스 진입 | `_start_arcturus_sequence` | 깊은 sub-bass swell + 페이지 turn 0.8s | P1 |
| `terminal_typewrite` | 단말기 타이핑 | ARCTURUS 문서 타자 | per-char 미세 click (loop 가능) | P2 |
| `bestiary_first_seen` | 도감 첫 조우 카드 | `mark_enemy_seen` | 짧은 deep chime 0.3s | P2 |
| `stage_clear_chime` | stage 클리어 | `_begin_clear_sequence` | 안도하는 짧은 fanfare 0.6s | P1 |
| `boss_alert_text` | 보스 강조 자막 | `_show_boss_alert` | 짧은 alarm sting 0.3s | P1 |

## 9. Tutorial

대부분 위 항목 재사용. 별도 SFX 없음.

---

## 구현 순서 권장

1. **Player + Combat (P0)** — `player_jump` / `player_dash` / `player_hurt` /
   `bullet_fire` / `bomb_explode`. 게임 1분 안에 사용자가 듣는 핵심.
2. **Enemy + Pickup (P0)** — `enemy_death` / `xp_collect` / `levelup`.
   진행 보상 피드백.
3. **Environment (P0)** — `lever_pull` / `plate_step_active` / `siren_flash` /
   `spike_hit`. 환경 인터랙션 학습 강화.
4. **Boss (P0)** — `boss_phase_change` / `boss_self_destruct_alarm` /
   `boss_death`. 클라이맥스 임팩트.
5. **UI (P0~P1)** — `ui_confirm` / `levelup` / `challenge_clear`/`challenge_fail`.
6. **나머지 P1~P2** — 환경/연출 보강.

## 코드 연결 메모

- 각 SFX는 `assets/sfx/<id>.ogg`로. (현재 `assets/sfx/` 폴더 신설 필요)
- `BgmPlayer`와 비슷한 패턴의 `SfxPlayer` autoload 신설 권장 — 풀링된 N개의
  AudioStreamPlayer 슬롯으로 동시 재생 처리. `GameState.sfx_volume` 참조.
- 일부 loop SFX(`enemy_drone_hover`, `boss_self_destruct_alarm`)는 streaming
  AudioStreamPlayer 별도 인스턴스로.
- 코드 호출 패턴: `SfxPlayer.play("player_jump")`. 위치 기반 attenuation 필요한
  경우(폭발 등)는 AudioStreamPlayer2D를 spawn.
