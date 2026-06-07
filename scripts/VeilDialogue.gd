class_name VeilDialogue
extends RefCounted

# Stage 브리핑 — stage 인덱스별 풀에서 랜덤 선택. ACT 톤 변화 반영.
# ACT 1 (stage 0~1): 담담하고 직업적
# ACT 2 (stage 2~3): "저도" 등장, 균열 시작
# ACT 3 (stage 4):   임무 외 말, 가장 개인적
# 스토리 모드 5스테이지 전용 briefing — 일반 모드(7스테이지)의 BRIEFINGS는
# 후반부 핵심부/드론/저격수 컨텍스트가 짙어 5스테이지 압축 흐름과 맞지 않음.
# 스토리 모드 stage 매핑: 0=외곽, 1=시설 안, 2=격리/배수로, 3=lab(보스), 4=탈출.
const STORY_BRIEFINGS: Array = [
	# stage 0 — 외곽 진입 (ACT1 건조 · 모티프 주 거점은 인트로)
	# 인트로가 이미 "외곽부터, 천천히 가요"를 말하므로 여기선 그 어휘를 반복하지 않음(중복 회피).
	[
		"경계가 느슨해요. 여기서 감을 잡아요.",
		"첫 임무예요, 요원. 제가 봐줄게요.",
	],
	# stage 1 — 시설 안으로 (신뢰 쌓임)
	[
		"안으로 들어왔어요. 경비 보여요.",
		"두 번째 구역이에요. 잘 따라오고 있어요.",
	],
	# stage 2 — 흠칫 + 시야 새기 시작(겸함). 스토리 모드는 곡선이 짧아 1·2단계를 s2가 겸함 (v3 §2).
	[
		"저 문 너머는... 잠깐. 아니에요. 가던 길 가요.",
		"여기부터는 잘 안 보여요. 머리 위는 요원이 봐줘요.",
	],
	# stage 3 — 핵심부 보스 · 역전 완성(최고조). 두 줄 다 "이제 요원이 VEIL 대신 본다" (v3 §2).
	[
		"다 와서 앞이 안 보여요. 이런 적 없어요. 요원이 봐줘요.",
		"여기서부터 잘 안 보여요. 이제 요원 차례예요. 저 대신.",
	],
	# stage 4 — 탈출
	[
		"잡았어요. 이제 빠져나가요.",
		"조용히 빠져요. 거의 다 왔어요.",
	],
]

# 재작성(STORY_REDESIGN_v1 §4): "두려움 에스컬레이션"을 진행도에 묶어 점증.
# 각 stage 풀을 톤 동질화 — 어느 줄이 뽑혀도 그 stage의 ACT/두려움 비트를 운반.
# 그래서 아크는 stage 순서로 결정론적으로 누적되고, 회차 변화는 유지된다.
# 시야가 흐려지는 비트의 원인(차폐인지 VEIL의 두려움인지)은 게임이 답하지 않음 — 대사는 "안 보인다"만.
# 보이스(§2-1): 40자 내외 / "요원" 호칭 / em dash 없음 / "저도"는 ACT2(stage 3)부터.
const BRIEFINGS: Array = [
	# stage 0 — ACT1 건조·직업적 (시야 모티프 주 거점은 인트로로 이전 — v2 §1-3)
	# 인트로 "외곽부터, 천천히 가요"와 어휘 중복 회피 — 여기선 전술 정보 위주.
	[
		"경비가 느슨한 편이에요. 앞쪽이 더 빨라요.",
		"첫 임무예요, 요원. 제가 봐줄게요.",
		"여기서 감을 잡아요. 무리하지 말아요.",
	],
	# stage 1 — ACT1 신뢰 쌓임
	[
		"안으로 들어왔어요. 경비 패턴 보여요.",
		"두 번째예요. 잘 따라오고 있어요.",
		"여기서부터 좁아요. 제가 먼저 짚을게요.",
	],
	# stage 2 — ACT2 시작 · 1단계 흠칫(시야 역전 전조). 모든 줄이 "VEIL이 앞의 무언가에 흠칫하고
	# 얼버무린다"(v3 §2). 숨기는 걸 signposting하지 않음 — 플레이어는 불안만, 숨김은 엔딩에서 회수.
	[
		"저 문 너머는... 잠깐. 아니에요. 가던 길 가요.",
		"앞에 뭔가... 아니에요. 제가 잘못 봤어요. 가요.",
		"방금... 아니에요. 신경 쓰지 말아요. 저도 가끔 이래요.",
	],
	# stage 3 — ACT2 균열 · 봉인/오래된 구역 ("저도" 등장)
	[
		"이 층은 도면이랑 달라요. 저도 처음 봐요.",
		"어딘가 잠긴 문이 있을 거예요. 누가 봉인했는진 저도 몰라요.",
		"이 구역은 오래됐어요. 오래 닫혀 있었고요.",
	],
	# stage 4 — 2단계 시야가 새기 시작 · 차폐. 모든 줄이 "VEIL의 봄이 끊기고 요원에게 봐달라 넘긴다"(v3 §2).
	[
		"여기부터는 잘 안 보여요. 머리 위는 요원이 봐줘요.",
		"자꾸... 놓쳐요. 이런 적 없는데. 요원이 직접 봐요.",
		"제가 못 보는 데가 생겨요. 거긴 요원이 봐줘요.",
	],
	# stage 5 — ACT3 · 두려움 오름 · 임무 외 말 (??? 복선)
	[
		"서버실이 저 아래예요. ...요원. 천천히 가도 돼요.",
		"여기 도면에 없는 길이 하나 있어요. 저도 잘 모르겠어요.",
		"요원. 끝까지 따라와줘서, 고마워요.",
	],
	# stage 6 — 3단계 역전 완성 · 서버 직전. 모든 줄이 "VEIL이 거의 못 보고 이제 요원이 자기 대신 본다"(v3 §2).
	# 안심 줄("제가 보는 한")은 이 풀에서 빼 보스 처치 후 자막으로 이전(v3 §4, Stage._on_boss_killed).
	# 최고조 비트는 ACT3 인게임 자막(Stage._arm_act3_vision_subtitle)으로도 한 번 더 보강.
	[
		"다 와서... 앞이 안 보여요. 이런 적 없어요.",
		"여기, 제가 잘 안 보여요. 이제 요원이 봐줘요. 저 대신.",
		"지금부터 제가 틀릴 수도 있어요. 미리 말해둘게요.",
	],
]

# 첫 임무 시작 화면 — Briefing.gd가 stage 0 진입 시 한 번만 표시.
# 한 화면에 임무명·목표·VEIL 동행을 같이 통보 — 이전엔 라인이 4개로 쪼개져
# 사용자가 무슨 내용인지 못 읽고 그냥 ENTER로 넘기던 문제(사용자 보고).
const INTRO_SYSTEM: String = "침투 작전 — 보안 시설 SILO-7\n목표: 핵심 데이터 회수\n도면 없음. 사전 정보 없음.\n현장 지원 AI: VEIL.\n작전명: PALIMPSEST"

# 시스템 텍스트 직후 VEIL 첫 마디 — 한 화면(여러 줄)으로 묶음.
# 한 줄씩 나누면 ENTER 연타로 의미가 다 새서 한 호흡으로 통보.
const INTRO_VEIL: Array[String] = [
	"...연결됐어요. 들리세요, 요원?\n이 안은 도면이 없어요. 제가 보이는 대로 알려줄게요.\n멀리는 제가 봐줄 테니, 눈앞은 요원이 맡아줘요.\n외곽부터, 천천히 가요.",
]

# 레벨업 fallback — 특정 추천(★)이 없을 때. 그래서 카드에 ★가 안 붙으니, 멘트도 "딱 집어줄 게
# 없다 / 요원 선택을 따른다"로 일관되게(위치 참조 금지 — "두 번째" 같은 건 ★ 앵커가 없어 혼란).
const SKILL_GENERIC_COMMENTS: Array[String] = [
	"이번엔 어느 쪽도 나쁘지 않아요. 요원이 골라요.",
	"딱 집어줄 게 없네요. 끌리는 쪽으로.",
	"지금 스타일에 맞는 걸로 가요.",
	"이건 요원 판단이 더 나아요.",
	"뭘 골라도 받쳐줄게요.",
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
	"제가 잘 못 봐서... 미안해요. 다시 가요.",  # 시야 역전을 죽음과 묶음 (v3 §4)
]
const DEATH_ACT3_HEAVY: Array[String] = [
	"이 임무가 너무 힘든 거면 말해줘도 돼요.",
	"제가 더 잘 안내했어야 했어요.",
]

# ─── API ──────────────────────────────────────────────────

static func get_briefing(stage_index: int) -> String:
	# 스토리 모드는 5스테이지 전용 풀에서 선택 — 일반 모드 BRIEFINGS는 7스테이지
	# 흐름이라 후반부 컨텍스트가 다름.
	var pool_arr: Array = STORY_BRIEFINGS if GameState.story_mode else BRIEFINGS
	var idx: int = clamp(stage_index, 0, pool_arr.size() - 1)
	var pool: Array = pool_arr[idx]
	if pool.size() == 0:
		return ""
	return str(pool[randi() % pool.size()])

static func get_intro_system_text() -> String:
	return INTRO_SYSTEM

static func get_intro_veil_lines() -> Array[String]:
	return INTRO_VEIL

static func get_levelup_advice(player_skills: Dictionary, route_tags: Array, route_id: String = "") -> Dictionary:
	# 멘트 + 추천 family + (있으면) 콕 집은 skill_id를 반환 → LevelUpOverlay가 일치 카드에 ★.
	# 트리 라인 보유 여부는 player_skills.has(id)로 체크 (티어 무관).
	# 1순위: 현재 맵 적 구성에 따른 스킬-적 상성 — 미보유 약점 스킬을 콕 집어 추천.
	var mskill: String = SkillTreeData.matchup_skill_for_route(route_id, player_skills)
	if mskill != "":
		var fam: String = str(SkillTreeData.find_line(mskill).get("family", ""))
		return {"line": _matchup_line(mskill), "family": fam, "skill_id": mskill}
	# 2순위(폴백): 기존 route_tags 기반 family 추천.
	var has_ranged_buff: bool = player_skills.has("fire_boost") or player_skills.has("multishot") or player_skills.has("explosive")
	var has_mobility_buff: bool = player_skills.has("dash_boost") or player_skills.has("glide")
	var has_survival: bool = player_skills.has("hp") or player_skills.has("shield") or player_skills.has("barrier")
	if "근접전" in route_tags and not has_ranged_buff:
		return {"line": "근접전이 많아요. 화력이 있으면 좋겠어요.", "family": SkillTreeData.FAMILY_COMBAT, "skill_id": ""}
	if "함정" in route_tags and not has_mobility_buff:
		return {"line": "함정 구간이에요. 대시 강화나 글라이드가 도움돼요.", "family": SkillTreeData.FAMILY_MOBILITY, "skill_id": ""}
	if "드론" in route_tags and not has_ranged_buff:
		return {"line": "드론은 위에서 와요. 원거리가 있으면 더 안전해요.", "family": SkillTreeData.FAMILY_COMBAT, "skill_id": ""}
	if "노출" in route_tags and not has_survival:
		return {"line": "이 구간은 숨을 데가 없어요. 생존 쪽이 안심돼요.", "family": SkillTreeData.FAMILY_SURVIVAL, "skill_id": ""}
	if "수직" in route_tags and not has_mobility_buff:
		return {"line": "위로 가는 길이에요. 이동 능력이 있으면 편해요.", "family": SkillTreeData.FAMILY_MOBILITY, "skill_id": ""}
	if "도전" in route_tags and not has_survival:
		return {"line": "여기 위험해요. 생존 능력 한 줄 챙겨두는 게 어때요.", "family": SkillTreeData.FAMILY_SURVIVAL, "skill_id": ""}
	if "전투" in route_tags and not has_ranged_buff:
		return {"line": "정면 교전이에요. 화력이 부족하면 길어져요.", "family": SkillTreeData.FAMILY_COMBAT, "skill_id": ""}
	var idx: int = randi() % SKILL_GENERIC_COMMENTS.size()
	return {"line": SKILL_GENERIC_COMMENTS[idx], "family": "", "skill_id": ""}

# 스킬-적 상성 추천 멘트 — 어느 적에 왜 그 스킬인지 콕 짚어 가르친다.
static func _matchup_line(skill_id: String) -> String:
	match skill_id:
		"explosive": return "방패병이 정면을 막아요. 폭발물이면 방패째 뚫어요."
		"glide":     return "저격수가 노려요. 글라이드로 떠서 사선을 흔들어요."
		"multishot": return "드론이 위에서 와요. 연사로 쓸어내요."
		"fire_boost": return "폭격기가 붙기 전에. 화력을 올려두는 게 좋아요."
	return "이 구역에 맞는 한 수가 있어요."

static func get_death_briefing(death_count: int, followed_advice: bool) -> String:
	# stage 진행도로 ACT 판별 (current_stage는 사망 시점의 진행 stage).
	# 7스테이지 매핑: ACT 1=stage 0~1, ACT 2=stage 2~4, ACT 3=stage 5~6.
	var stage: int = GameState.current_stage
	var is_first: bool = death_count <= 1
	if stage <= 1:
		# ACT 1
		if is_first:
			return _pick(DEATH_ACT1_FIRST)
		return _pick(DEATH_ACT1_FOLLOWED) if followed_advice else _pick(DEATH_ACT1_IGNORED)
	elif stage <= 4:
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
