extends Node

func _ready() -> void:
	if OS.has_feature("web"):
		Engine.max_fps = 60
		# Browsers can throttle/suspend background tabs. The game cannot force a
		# browser to keep executing; Main/SaveManager persist timestamps and recover
		# a bounded offline reward when the player returns.
		process_mode = Node.PROCESS_MODE_ALWAYS

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and OS.has_feature("web"):
		var save_manager := get_tree().get_first_node_in_group("save_manager") if get_tree() else null
		if save_manager and save_manager.has_method("salvar_jogo"):
			save_manager.salvar_jogo()
