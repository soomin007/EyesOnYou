class_name VeilDialogue
extends RefCounted

# Stage 브리핑 — stage 인덱스별 풀에서 랜덤 선택. ACT 톤 변화 반영.
# ACT 1 (stage 0~1): 담담하고 직업적
# ACT 2 (stage 2~3): "저도" 등장, 균열 시작
# ACT 3 (stage 4):   임무 외 말, 가장 개인적
const BRIEFINGS: Array = [
	# stage 0 — ACT 1
	[
		"외곽 경비 두 명이에요. 앞쪽이 더 빨라요.",
		"첫 임무예요, 요원. 천천히 가도 돼요.",
		"외곽부터 시작해요. 경계가 느슨한 편이에요.",
	],
	# stage 1 — ACT 1 후반
	[
		"안으로 들어왔어요. 경비 패턴이 달라져요.",
		"두 번째예요. 경비가 늘었어요.",
		"여기서부터 좁아요. 적 수 늘어날 거예요.",
	],
	# stage 2 — ACT 2
	[
		"중간이에요. 이 다음부터 저격수가 나와요.",
		"경비가 예상보다 많아요. 제 판단이 틀렸어요.",
		"이 시설, 생각보다 오래됐어요.",
	],
	# stage 3 — ACT 2 후반
	[
		"드론도 섞여서 나와요. 위쪽도 봐요.",
		"핵심부 가까워요. 여기서부터 달라요.",
		"요원, 이 임무 의뢰인이 누군지 알아요? 저도 몰라요. 그냥 궁금했어요.",
	],
	# stage 4 — ACT 3
	[
		"마지막이에요. 저도 좀 긴장돼요.",
		"서버실 바로 앞이에요. 빠르게 처리해요.",
		"거의 다 왔어요, 요원.",
	],
]

# 첫 임무 시작 화면 — Briefing.gd가 stage 0 진입 시 한 번만 표시.
# VEIL 발화가 아닌 시스템 텍스트 (의뢰인/목표/지원 정보).
const INTRO_SYSTEM: String = "ARCTURUS SECURE CHANNEL\nOPERATION PALIMPSEST\n\n의뢰인: 익명\n목표: SILO-7 침투. 서버실 데이터 드라이브 회수. 흔적 없이 철수.\n지원: VEIL (상황실 파트너)\n\n[교신 연결 중...]"

# 시스템 텍스트 직후 VEIL 첫 마디 (한 번만, stage 0 진입 시)
const INTRO_VEIL: Array[String] = [
	"요원, 들려요?",
	"저는 VEIL이에요. 오늘 임무 지원할게요.",
	"외곽부터 시작해요.",
]

# 레벨업 fallback (랜덤 6개)
const SKILL_GENERIC_COMMENTS: Array[String] = [
	"이 상황엔 어느 쪽도 나쁘지 않아요.",
	"요원이 더 잘 알 것 같아요.",
	"저라면 두 번째를 고르겠지만, 틀릴 수도 있어요.",
	"직감을 믿어요.",
	"지금 스타일에 맞는 걸 고르는 게 나을 것 같아요.",
	"어느 쪽이든 이유가 있으면 돼요.",
]

# ─── 사망 메시지 (ACT별) ──────────────────────────────────

# ACT 1 (stage 0~1) — 담담하고 직업적
const DEATH_ACT1_FIRST: Array[String] = [
	"처음 쓰러진 거예요. 다시 가요.",
	"괜찮아요, 요원. 첫 번이에요.",
]
const DEATH_ACT1_FOLLOWED: Array[String] = [
	"제 루트가 어려웠어요. 다시 해요.",
	"조언이 별로였나요. 다시 가요.",
]
const DEATH_ACT1_IGNORED: Array[String] = [
	"다른 방법으로 가봤군요. 다시 해요.",
	"이 루트가 맞지 않았던 것 같아요.",
]

# ACT 2 (stage 2~3) — 균열, "저도" 등장
const DEATH_ACT2_FIRST: Array[String] = [
	"저도 좀 걱정됐어요. 다시 가요.",
	"이 구역이 어려워요. 같이 풀어봐요.",
]
const DEATH_ACT2_FOLLOWED: Array[String] = [
	"제 말을 믿었는데 결과가 좋지 않았어요. 미안해요.",
	"제 판단이 틀렸어요. 미안해요, 요원.",
]
const DEATH_ACT2_IGNORED: Array[String] = [
	"제 말은 안 들었는데, 결과는 비슷했네요.",
	"요원 방식대로 해봤는데 쉽지 않죠.",
]

# ACT 3 (stage 4) — 가장 개인적, 어떤 사망이든
const DEATH_ACT3_ANY: Array[String] = [
	"거의 다 왔어요. 다시 해요.",
	"여기서 멈추지 않아도 돼요, 요원.",
	"마지막인데 쉽지 않네요. 저도요.",
]
const DEATH_ACT3_HEAVY: Array[String] = [
	"이 임무가 너무 힘든 거면 말해줘도 돼요.",
	"제가 더 잘 안내했어야 했어요.",
]

# ─── API ──────────────────────────────────────────────────

static func get_briefing(stage_index: int) -> String:
	var idx: int = clamp(stage_index, 0, BRIEFINGS.size() - 1)
	var pool: Array = BRIEFINGS[idx]
	if pool.size() == 0:
		return ""
	return str(pool[randi() % pool.size()])

static func get_intro_system_text() -> String:
	return INTRO_SYSTEM

static func get_intro_veil_lines() -> Array[String]:
	return INTRO_VEIL

static func get_levelup_advice(player_skills: Dictionary, route_tags: Array) -> String:
	# 트리 라인 보유 여부는 player_skills.has(id)로 체크 (티어 무관).
	# "ranged"는 v2 트리에서 사라져 fire_boost / multishot 중 하나라도 있으면 원거리 보강된 것으로 간주.
	var has_ranged_buff: bool = player_skills.has("fire_boost") or player_skills.has("multishot")
	if "근접전" in route_tags and not has_ranged_buff:
		return "원거리가 없으면 불리해요. 선택은 요원 몫이지만."
	if "함정" in route_tags and not player_skills.has("dash"):
		return "대시가 있으면 함정을 건너뛸 수 있어요."
	if "드론" in route_tags and not has_ranged_buff:
		return "드론은 위에서 와요. 원거리가 도움돼요."
	if "근접전" in route_tags and not player_skills.has("dash"):
		return "근접전이 많아요. 대시로 헛돌진 유도할 수 있어요."
	if "드론" in route_tags and not player_skills.has("double_jump"):
		return "위로 올라갈 수 있으면 드론한테 유리해요."
	var idx: int = randi() % SKILL_GENERIC_COMMENTS.size()
	return SKILL_GENERIC_COMMENTS[idx]

static func get_death_briefing(death_count: int, followed_advice: bool) -> String:
	# stage 진행도로 ACT 판별 (current_stage는 사망 시점의 진행 stage)
	var stage: int = GameState.current_stage
	var is_first: bool = death_count <= 1
	if stage <= 1:
		# ACT 1
		if is_first:
			return _pick(DEATH_ACT1_FIRST)
		return _pick(DEATH_ACT1_FOLLOWED) if followed_advice else _pick(DEATH_ACT1_IGNORED)
	elif stage <= 3:
		# ACT 2
		if is_first:
			return _pick(DEATH_ACT2_FIRST)
		return _pick(DEATH_ACT2_FOLLOWED) if followed_advice else _pick(DEATH_ACT2_IGNORED)
	# ACT 3
	if death_count >= 3:
		return _pick(DEATH_ACT3_HEAVY)
	return _pick(DEATH_ACT3_ANY)

static func _pick(pool: Array) -> String:
	if pool.size() == 0:
		return ""
	return str(pool[randi() % pool.size()])
