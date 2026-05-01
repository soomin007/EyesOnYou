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
	header.text = "[NEW] 적 도감"
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(0.55, 0.85, 0.95))
	v.add_child(header)

	var name_label := Label.new()
	name_label.text = str(data.get("name", "???"))
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	v.add_child(name_label)

	var blurb := Label.new()
	blurb.text = str(data.get("blurb", ""))
	blurb.add_theme_font_size_override("font_size", 15)
	blurb.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(480, 0)
	v.add_child(blurb)

	v.add_child(HSeparator.new())

	var tactic_h := Label.new()
	tactic_h.text = "공략"
	tactic_h.add_theme_font_size_override("font_size", 13)
	tactic_h.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	v.add_child(tactic_h)

	var tactic := Label.new()
	tactic.text = str(data.get("tactic", ""))
	tactic.add_theme_font_size_override("font_size", 15)
	tactic.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	tactic.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tactic.custom_minimum_size = Vector2(480, 0)
	v.add_child(tactic)

	var btn := Button.new()
	btn.text = "확인 (SPACE)"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(func() -> void: _close(layer))
	v.add_child(btn)
	btn.grab_focus.call_deferred()

	host.add_child(layer)
	return layer

static func _close(layer: CanvasLayer) -> void:
	_active = false
	if not is_instance_valid(layer):
		return
	var tree := layer.get_tree()
	if tree != null:
		tree.paused = false
	layer.queue_free()
