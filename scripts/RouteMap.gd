extends Control

@onready var stage_label: Label = $Header/Stage
@onready var subtitle_label: Label = $Header/Subtitle
@onready var nodes_container: HBoxContainer = $Center/Nodes
@onready var veil_box: PanelContainer = $VeilBox
@onready var veil_text: Label = $VeilBox/Margin/V/Text
@onready var hint_label: Label = $Footer/Hint

var pool: Array = []
var recommended_id: String = ""
var hovered_idx: int = 0
var buttons: Array = []

func _ready() -> void:
	stage_label.text = "STAGE %d / %d  —  루트 선택" % [GameState.current_stage + 1, GameState.TOTAL_STAGES]
	subtitle_label.text = "● 위험도 / 보상   —   ? 미상"
	pool = RouteData.get_route_pool_for_stage(GameState.current_stage)
	recommended_id = RouteData.choose_veil_recommendation(pool)
	_build_node_buttons()
	_update_veil_comment()
	hint_label.text = "[ ←/→ : 선택 이동   SPACE/ENTER : 결정 ]"

func _build_node_buttons() -> void:
	for child in nodes_container.get_children():
		child.queue_free()
	buttons.clear()
	for i in pool.size():
		var route: Dictionary = pool[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 160)
		b.toggle_mode = false
		b.text = _format_button_text(route, route.get("id", "") == recommended_id)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_button_pressed.bind(i))
		b.focus_entered.connect(_on_focus.bind(i))
		b.mouse_entered.connect(_on_focus.bind(i))
		nodes_container.add_child(b)
		buttons.append(b)
	if buttons.size() > 0:
		buttons[0].grab_focus()

func _format_button_text(route: Dictionary, recommended: bool) -> String:
	var route_name: String = route.get("name", "?")
	var hidden: bool = route.get("hidden", false)
	var risk_str: String = "?" if hidden else _dots(route.get("risk", 0))
	var reward_str: String = "?" if hidden else _dots(route.get("reward", 0))
	var rec: String = "  ★" if recommended else ""
	return "%s%s\n\n위험  %s\n보상  %s" % [route_name, rec, risk_str, reward_str]

func _dots(n: int) -> String:
	var s: String = ""
	for i in n:
		s += "●"
	for i in (3 - n):
		s += "○"
	return s

func _on_focus(idx: int) -> void:
	hovered_idx = idx
	_update_veil_comment()

func _update_veil_comment() -> void:
	if hovered_idx < 0 or hovered_idx >= pool.size():
		return
	var route: Dictionary = pool[hovered_idx]
	var msg: String = ""
	var desc: String = str(route.get("description", ""))
	if desc != "":
		msg += desc + "\n\n"
	msg += "VEIL  —  " + str(route.get("veil_comment", ""))
	# 위험도가 보이는 루트(hidden 아님)에서만 명시 경고
	if not route.get("hidden", false):
		var risk: int = int(route.get("risk", 0))
		if risk >= 3:
			msg += "\n[고위험] 적 수가 더 많고 반응 속도도 빨라요."
		var reward: int = int(route.get("reward", 0))
		if reward >= 3:
			msg += "\n[고보상] 클리어 보너스 경험치가 큽니다."
	veil_text.text = msg

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_skip") or event.is_action_pressed("jump"):
		_on_button_pressed(hovered_idx)

func _on_button_pressed(idx: int) -> void:
	if idx < 0 or idx >= pool.size():
		return
	var route: Dictionary = pool[idx]
	GameState.record_route_choice(route, recommended_id)
	get_tree().change_scene_to_file(SceneRouter.STAGE)
