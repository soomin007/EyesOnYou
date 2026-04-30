class_name SceneRouter
extends RefCounted

const TITLE: String     = "res://scenes/title.tscn"
const TUTORIAL: String  = "res://scenes/tutorial.tscn"
const BRIEFING: String  = "res://scenes/briefing.tscn"
const ROUTE_MAP: String = "res://scenes/route_map.tscn"
const STAGE: String     = "res://scenes/stage.tscn"
const LEVELUP: String   = "res://scenes/levelup.tscn"
const DEATH: String     = "res://scenes/death.tscn"
const ENDING: String    = "res://scenes/ending.tscn"
const SETTINGS: String  = "res://scenes/settings.tscn"

static func go(tree: SceneTree, path: String) -> void:
	tree.change_scene_to_file(path)

static func start_after_title(tree: SceneTree) -> void:
	if not GameState.tutorial_done:
		tree.change_scene_to_file(TUTORIAL)
	else:
		tree.change_scene_to_file(BRIEFING)
