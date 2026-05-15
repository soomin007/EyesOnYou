# ElevenLabs SFX 프롬프트 (Eyes on You)

이 문서는 [`sfx_list.md`](sfx_list.md)에 통합됨. 각 SFX의 ElevenLabs용 영문 프롬프트는
`sfx_list.md`의 항목별 `prompt:` 줄에 있다. 중복 관리 부담을 줄이려고 단일 source로 통합.

`sfx_list.md`에서 찾을 항목: ID / 트리거 위치 / 길이 / 볼륨 보정 / 영문 prompt / 우선순위 / 현재 상태.

## ElevenLabs 사용 팁 (참고)
- 동일 프롬프트로도 매 생성마다 결과가 다름. 마음에 드는 결과 안 나오면 2~3번 재생성.
- `_step` / `_hurt` 같이 변주가 필요한 SFX는 같은 프롬프트로 N개 생성 → `<id>1.mp3`, `<id>2.mp3` … 형식으로 저장하면 `SfxPlayer`가 자동 인식.
- loop 항목(`drone_hover`, `bomber_beep`, `self_destruct_alarm`)은 결과를 Audacity에서 zero-crossing trim 필요.
- 결과는 `assets/sfx/<id>.mp3`로 저장.
- prompt_influence는 0.4~0.6 권장. 너무 높이면 변주가 안 됨.
