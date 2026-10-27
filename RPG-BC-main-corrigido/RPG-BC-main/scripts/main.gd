extends Control
class_name Main

@onready var save_manager: SaveManager = $SaveManager

func _ready() -> void:
	# Carrega os dados salvos assim que o jogo inicia
	if save_manager:
		save_manager.carregar_jogo()
	
	# Cria um timer para salvar o progresso sozinho a cada 30 segundos
	var auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 30.0
	auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)

func _on_auto_save_timer_timeout() -> void:
	if save_manager:
		save_manager.salvar_jogo()

# Executa o salvamento se o jogador fechar a janela no computador ou minimizar no celular
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if save_manager:
			save_manager.salvar_jogo()
