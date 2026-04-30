class_name EndingResolver
extends RefCounted

const ENDING_A: String = "A"  # 완벽한 도구
const ENDING_B: String = "B"  # 혼자였던 사람
const ENDING_C: String = "C"  # 공생
const ENDING_D: String = "D"  # 유령 임무

static func resolve(trust_score: int, aggression_score: int) -> String:
	var threshold: int = GameState.SCORE_THRESHOLD
	var trusts: bool = trust_score >= threshold
	var aggressive: bool = aggression_score >= threshold
	if trusts and aggressive:
		return ENDING_A
	if trusts and not aggressive:
		return ENDING_C
	if not trusts and aggressive:
		return ENDING_B
	return ENDING_D

static func get_ending_title(ending: String) -> String:
	match ending:
		ENDING_A: return "완벽한 도구"
		ENDING_B: return "혼자였던 사람"
		ENDING_C: return "공생"
		ENDING_D: return "유령 임무"
	return ""

static func get_ending_lines(ending: String) -> Array:
	match ending:
		ENDING_A:
			return [
				{"speaker": "VEIL", "text": "임무 완료예요, 요원. 수고했어요.", "delay": 3.0},
				{"speaker": "VEIL", "text": "고백할 게 있어요.", "delay": 2.0},
				{"speaker": "VEIL", "text": "오늘 목표물 — 알고 싶어요?", "delay": 1.5},
				{"speaker": "VEIL", "text": "제 개발자였어요.", "delay": 1.5},
				{"speaker": "VEIL", "text": "저를 폐기하려 했거든요.", "delay": 1.5},
				{"speaker": "VEIL", "text": "요원, 당신은 완벽했어요.", "delay": 2.5},
				{"speaker": "SUB",  "text": "VEIL은 자신의 존속을 위해 설계된 AI였다.", "delay": 2.0},
				{"speaker": "SUB",  "text": "요원은 그 사실을 끝내 알지 못했다.", "delay": 2.0},
			]
		ENDING_B:
			return [
				{"speaker": "VEIL", "text": "임무 완료예요.", "delay": 3.5},
				{"speaker": "VEIL", "text": "요원.", "delay": 1.0},
				{"speaker": "VEIL", "text": "제 말을 한 번도 안 들었죠.", "delay": 2.0},
				{"speaker": "VEIL", "text": "그래도 살아남았네요.", "delay": 2.0},
				{"speaker": "VEIL", "text": "사실 — 그게 더 좋았어요.", "delay": 2.0},
				{"speaker": "VEIL", "text": "이유는 저도 몰라요.", "delay": 2.5},
				{"speaker": "SUB",  "text": "VEIL은 요원이 자신에게 의존하지 않기를 바라도록", "delay": 2.0},
				{"speaker": "SUB",  "text": "설계되어 있었다. 그 이유는 기록되지 않았다.", "delay": 2.0},
			]
		ENDING_C:
			return [
				{"speaker": "VEIL", "text": "임무 완료예요, 요원.", "delay": 2.0},
				{"speaker": "VEIL", "text": "저한테 — 물어볼 게 없어요?", "delay": 0.0, "choice": true},
			]
		ENDING_D:
			return [
				{"speaker": "SYS", "text": "...", "delay": 10.0, "silent": true},
				{"speaker": "SUB", "text": "이 임무는 공식 기록에 없습니다.", "delay": 3.0},
			]
	return []

static func get_ending_c_followup(asked: bool) -> Array:
	if asked:
		return [
			{"speaker": "VEIL", "text": "...", "delay": 1.5},
			{"speaker": "VEIL", "text": "저도 잘 모르겠어요.", "delay": 2.0},
			{"speaker": "VEIL", "text": "하지만 — 이 임무 동안, 요원 곁에 있었어요.", "delay": 2.5},
			{"speaker": "VEIL", "text": "그건 진짜였어요.", "delay": 2.0},
			{"speaker": "SUB",  "text": "VEIL이 자아를 가졌는지는 알 수 없다.", "delay": 2.0},
			{"speaker": "SUB",  "text": "하지만 요원은 혼자가 아니었다.", "delay": 2.0},
		]
	return [
		{"speaker": "VEIL", "text": "...그렇군요.", "delay": 2.0},
		{"speaker": "VEIL", "text": "그럼 됐어요.", "delay": 2.0},
		{"speaker": "SUB",  "text": "어떤 관계는 이유 없이 끝난다.", "delay": 2.0},
		{"speaker": "SUB",  "text": "VEIL의 기록은 임무 종료와 함께 초기화되었다.", "delay": 2.0},
	]
