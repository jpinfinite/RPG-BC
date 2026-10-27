extends Node

func _ready() -> void:
	# Verifica se o jogo está rodando em um navegador Web
	if OS.has_feature("web"):
		print("Detectado ambiente Web! Otimizando taxa de quadros e renderização...")
		
		# Limita a taxa de atualização na Web para 60 FPS para evitar consumo exagerado de CPU no navegador
		Engine.max_fps = 60
		
		# Garante que o jogo continue rodando e calculando os ticks mesmo se o jogador mudar de aba no navegador
		# Isso é vital para jogos Idle!
		set_process_internal(true)

func _notification(what: int) -> void:
	# Na Web, se o usuário minimizar o navegador, forçamos o salvamento imediato do progresso
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and OS.has_feature("web"):
		var save_manager = get_node_or_null("/root/Main/SaveManager")
		if not save_manager and get_tree():
			save_manager = get_tree().get_first_node_in_group("save_manager")
		if save_manager:
			save_manager.salvar_jogo()
