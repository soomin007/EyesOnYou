class_name SceneRouter
extends RefCounted

const TITLE: String     = "res://scenes/title.tscn"
const BRIEFING: String  = "res://scenes/briefing.tscn"
const ROUTE_MAP: String = "res://scenes/route_map.tscn"
const STAGE: String     = "res://scenes/stage.tscn"
const LEVELUP: String   = "res://scenes/levelup.tscn"
const DEATH: String     = "res://scenes/death.tscn"
const ENDING: String    = "res://scenes/ending.tscn"

static func go(tree: SceneTree, path: String) -> void:
	tree.change_scene_to_file(path)
