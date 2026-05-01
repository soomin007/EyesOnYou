class_name BestiaryData
extends RefCounted

# 적 도감 — 첫 조우 시 BestiaryOverlay가 이 데이터를 카드로 표시.
# id는 Enemy._enemy_id() 반환값과 일치해야 함.

const ENEMIES: Dictionary = {
	"patrol": {
		"name": "정찰병 (Patrol)",
		"blurb": "구역을 좌우로 순찰하는 보병. 평소엔 천천히 왕복하지만, 가까이서 같은 높이에 들어오면 머리 LED가 붉게 깜빡인 뒤 짧게 돌진해 들이받는다.",
		"tactic": "붉게 깜빡일 때 점프나 대시로 옆으로 빠지면 헛돌진하고 잠시 멈춰선다. 회복 중인 사이가 가장 안전한 사격 타이밍.",
	},
	"sniper": {
		"name": "저격수 (Sniper)",
		"blurb": "한 자리에 박혀 붉은 조준선으로 잠시 겨눈 뒤 발사하는 원거리 적. 사거리는 길지만 조준이 끊기면 발사를 취소한다.",
		"tactic": "조준선이 보이는 동안 플랫폼이나 벽 뒤로 시야를 끊으면 사격이 취소된다. 엄폐 후 측면으로 돌아 들어가 단발에 정리.",
	},
	"drone": {
		"name": "공습 드론 (Strike Drone)",
		"blurb": "공중에서 플레이어를 추적하는 정찰체. 머리 위로 올라오면 호버링하며 폭탄을 투하한다. 폭탄은 떨어지면서 광역 폭발.",
		"tactic": "그림자가 머리 위에 들어오면 즉시 옆으로 이동. 호버링 중에는 발이 멈춰 있어 사격하기 좋다. 폭탄을 떨구기 전에 떨어뜨리는 게 핵심.",
	},
}

static func get_data(id: String) -> Dictionary:
	return ENEMIES.get(id, {})
