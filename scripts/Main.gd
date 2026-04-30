extends Node

func _ready() -> void:
	GameState.load_settings()
	GameState.reset()
	get_tree().change_scene_to_file(SceneRouter.TITLE)
