class_name LevelUpOverlay
extends RefCounted

# 레벨업 시 호출. 스킬 3장 중 1장 선택 → on_picked.call(picked_id) 실행 후 오버레이 자동 정리.
# Stage / Tutorial 양쪽에서 동일하게 사용.

static func show(host: Node, advice: Variant, on_picked: Callable, forced_picks: Array = []) -> CanvasLayer:
	# advice: Dictionary {"line": String, "family": String} 권장.
	# 호환성: String을 받으면 line만 있는 dict로 처리 (튜토리얼 등 family 없음).
	# forced_picks: 비어있지 않으면 roll_choices 대신 이 카드 배열 사용 (튜토리얼 강제 픽).
	var advice_line: String = ""
	var advice_family: String = ""
	if advice is Dictionary:
		advice_line = str((advice as Dictionary).get("line", ""))
		advice_family = str((advice as Dictionary).get("family", ""))
	elif advice is String:
		advice_line = advice as String
	var layer := CanvasLayer.new()
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)

	var title := Label.new()
	title.text = "LEVEL UP  —  스킬을 선택해요"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	# VEIL 신뢰도 게이지 — 카드 위에 5단계 점으로 표시.
	# 신뢰도 따라 색이 바뀌어 플레이어와 VEIL의 관계가 매 선택에 보이게.
	var gauge := Label.new()
	var net: int = GameState.trust_score - GameState.aggression_score
	var dots: String = ""
	for i in 5:
		var th: int = -4 + i * 2
		if net >= th:
			dots += "●"
		else:
			dots += "○"
	gauge.text = "VEIL 신뢰   " + dots
	gauge.add_theme_font_size_override("font_size", 13)
	gauge.add_theme_color_override("font_color", GameState.veil_tone_color())
	gauge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(gauge)

	if advice_line != "":
		# prefix 사용 폐지 — "그럼, " 같은 짧은 토막이 뒷 문장과 부자연스러움.
		# 신뢰도는 폰트 색(veil_tone_color)으로 표현.
		var advice_label := Label.new()
		advice_label.text = "VEIL  —  " + advice_line
		advice_label.add_theme_font_size_override("font_size", 22)
		advice_label.add_theme_color_override("font_color", GameState.veil_tone_color())
		advice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(advice_label)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	# 카드가 1장일 때(튜토리얼 강제 픽 등) 좌측이 아니라 가운데 정렬되도록.
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)

	var picks: Array
	if forced_picks.size() > 0:
		picks = forced_picks
	else:
		picks = SkillSystem.roll_choices(GameState.skills, 3)
	if picks.size() == 0:
		host.add_child(layer)
		_finish(layer, "", on_picked)
		return layer

	# VEIL 추천 — 멘트가 가리키는 family를 그대로 따라 표시. 멘트와 ★가 어긋나지
	# 않게 단일 source(advice.family)로 통일. family가 없으면(generic 멘트) 추천 없음.
	var recommended_families: Array = []
	if advice_family != "":
		recommended_families.append(advice_family)

	for p in picks:
		var skill: Dictionary = p
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 170)
		var family: String = str(skill.get("family", ""))
		var tier: int = int(skill.get("tier", 1))
		var tier_tag: String = "T%d" % tier
		var header: String
		if family != "":
			header = "[%s · %s]" % [family, tier_tag]
		else:
			header = "[%s]" % tier_tag
		var body_text: String = "%s  %s\n\n%s" % [str(skill.get("name", "")), header, str(skill.get("desc", ""))]
		var is_recommended: bool = family != "" and family in recommended_families
		if is_recommended:
			body_text += "\n\n★ VEIL 추천"
		btn.text = body_text
		btn.add_theme_font_size_override("font_size", 15)
		if is_recommended:
			btn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
			btn.add_theme_color_override("font_focus_color", Color(1.0, 0.92, 0.55))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.55))
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		var sid: String = str(skill.get("id", ""))
		btn.pressed.connect(func() -> void: _finish(layer, sid, on_picked))
		hb.add_child(btn)
	host.add_child(layer)
	GameState.arm_focus_with_delay(layer, hb.get_child(0) as Button)
	return layer

static func _finish(layer: CanvasLayer, picked_id: String, on_picked: Callable) -> void:
	if picked_id != "":
		GameState.add_skill(picked_id)
	if on_picked.is_valid():
		on_picked.call(picked_id)
	if is_instance_valid(layer):
		layer.queue_free()
