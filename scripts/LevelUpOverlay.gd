class_name LevelUpOverlay
extends RefCounted

# 레벨업 시 호출. 스킬 3장 중 1장 선택 → on_picked.call(picked_id) 실행 후 오버레이 자동 정리.
# Stage / Tutorial 양쪽에서 동일하게 사용.

static func show(host: Node, advice: String, on_picked: Callable) -> CanvasLayer:
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

	if advice != "":
		var advice_label := Label.new()
		advice_label.text = "VEIL  —  " + advice
		advice_label.add_theme_font_size_override("font_size", 15)
		advice_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.95))
		advice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(advice_label)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	v.add_child(hb)

	var picks: Array = SkillSystem.roll_choices(GameState.skills, 3)
	if picks.size() == 0:
		host.add_child(layer)
		_finish(layer, "", on_picked)
		return layer

	for p in picks:
		var skill: Dictionary = p
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 140)
		btn.text = "%s\n[%s]\n\n%s" % [str(skill.get("name", "")), str(skill.get("tag", "")), str(skill.get("desc", ""))]
		btn.add_theme_font_size_override("font_size", 15)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		var sid: String = str(skill.get("id", ""))
		btn.pressed.connect(func() -> void: _finish(layer, sid, on_picked))
		hb.add_child(btn)
	(hb.get_child(0) as Button).grab_focus.call_deferred()

	host.add_child(layer)
	return layer

static func _finish(layer: CanvasLayer, picked_id: String, on_picked: Callable) -> void:
	if picked_id != "":
		GameState.add_skill(picked_id)
	if on_picked.is_valid():
		on_picked.call(picked_id)
	if is_instance_valid(layer):
		layer.queue_free()
