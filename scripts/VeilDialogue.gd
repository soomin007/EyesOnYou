class_name VeilDialogue
extends RefCounted

const BRIEFINGS: Array[String] = [
	"첫 임무예요, 요원. 천천히 가도 돼요.",
	"이전 루트 덕분에 정보가 생겼어요. 활용해봐요.",
	"중간 지점이에요. 여기서부터 달라져요.",
	"거의 다 왔어요. 조심해요, 요원.",
	"마지막이에요. 저도 — 긴장되네요.",
]

const SKILL_GENERIC_COMMENTS: Array[String] = [
	"이 상황엔 어느 쪽도 나쁘지 않아요.",
	"요원이 더 잘 알 것 같아요.",
	"저라면 두 번째를 고르겠지만 — 틀릴 수도 있어요.",
	"직감을 믿어요.",
]

const DEATH_FIRST: String = "처음 쓰러진 거예요. 괜찮아요, 요원."
const DEATH_FOLLOWED_BAD: String = "제 말을 믿었는데 결과가 좋지 않았네요. 미안해요."
const DEATH_IGNORED: String = "제 말은 안 들었는데, 결과는 비슷했네요."
const DEATH_DEFAULT: String = "이 루트가 어려웠어요. 다음엔 달라질 거예요."

static func get_briefing(stage_index: int) -> String:
	if stage_index < 0:
		return BRIEFINGS[0]
	if stage_index >= BRIEFINGS.size():
		return BRIEFINGS[BRIEFINGS.size() - 1]
	return BRIEFINGS[stage_index]

static func get_levelup_advice(player_skills: Array, route_tags: Array) -> String:
	if "근접전" in route_tags and not ("ranged" in player_skills):
		return "원거리가 없으면 불리할 수 있어요. 선택은 요원 몫이지만."
	if "함정" in route_tags and not ("dash" in player_skills):
		return "대시가 있으면 함정을 건너뛸 수 있어요."
	if "드론" in route_tags and not ("ranged" in player_skills):
		return "드론은 위에서 와요. 원거리가 도움이 될 거예요."
	if "노출" in route_tags and not ("wall_slide" in player_skills):
		return "노출 구역이에요. 벽에 붙어 시야를 끊는 게 도움될 거예요."
	var idx: int = randi() % SKILL_GENERIC_COMMENTS.size()
	return SKILL_GENERIC_COMMENTS[idx]

static func get_death_briefing(death_count: int, followed_advice: bool) -> String:
	if death_count <= 1:
		return DEATH_FIRST
	if followed_advice and death_count > 2:
		return DEATH_FOLLOWED_BAD
	if not followed_advice:
		return DEATH_IGNORED
	return DEATH_DEFAULT
