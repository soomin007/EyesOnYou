class_name BestiaryOverlay
extends RefCounted

# 적 첫 조우 시 일시정지하고 도감 카드 한 장을 띄움.
# 동시 조우가 발생해도 한 번에 하나만 표시되도록 정적 플래그로 가드.

static var _active: bool = false

static func is_active() -> bool:
	return _active

static func show_card(host: Node, enemy_id: String) -> CanvasLayer:
	if _active:
		return null
	var data: Dictionary = BestiaryData.get_data(enemy_id)
	if data.is_empty():
		return null
	_active = true
	host.get_tree().paused = true

	var layer := CanvasLayer.new()
	layer.layer = 45
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 0)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	var header := Label.new()
	header.text = "[조우]"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.55, 0.85, 0.95))
	v.add_child(header)

	var name_label := Label.new()
	name_label.text = str(data.get("name", "???"))
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	v.add_child(name_label)

	# 관찰 메모 — 짧은 행동 단서. 공략은 플레이로 알아가게 (글로 풀지 않음).
	# 행동 키워드("LED", "조준선", "그림자" 등)만 강조 색으로 구분.
	var blurb := RichTextLabel.new()
	blurb.bbcode_enabled = true
	blurb.fit_content = true
	blurb.scroll_active = false
	blurb.text = _highlight_keywords(str(data.get("blurb", "")))
	blurb.add_theme_font_size_override("normal_font_size", 15)
	blurb.add_theme_color_override("default_color", Color(0.85, 0.85, 0.85))
	blurb.custom_minimum_size = Vector2(480, 0)
	v.add_child(blurb)

	var btn := Button.new()
	btn.text = "확인"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(func() -> void: _close(layer))
	v.add_child(btn)

	host.add_child(layer)
	GameState.arm_focus_after_release(layer, btn, PackedStringArray(["ui_accept", "jump", "ui_skip"]))
	return layer

# 행동 단서 단어를 노란색으로 강조 — 정보를 글로 풀지 않고 시선만 유도.
static func _highlight_keywords(text: String) -> String:
	var keywords: Array = [
		"붉게 깜빡", "조준선", "그림자", "빨갛게 깜빡", "방패", "튕겨낸다",
		"순찰", "호버", "자폭",
	]
	var result: String = text
	for k in keywords:
		var word: String = str(k)
		result = result.replace(word, "[color=#f5d873]%s[/color]" % word)
	return result

static func _close(layer: CanvasLayer) -> void:
	_active = false
	if not is_instance_valid(layer):
		return
	var tree := layer.get_tree()
	if tree != null:
		tree.paused = false
	layer.queue_free()
