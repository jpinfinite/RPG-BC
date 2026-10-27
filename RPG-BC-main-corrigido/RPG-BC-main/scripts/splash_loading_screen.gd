extends Control
class_name SplashLoadingScreen

const CENA_ALVO: String = "res://scenes/main.tscn"

@onready var progress_bar: ProgressBar = %ProgressBarCarregamento
@onready var lbl_status: Label = %LblStatusCarregamento
@onready var lbl_porcentagem: Label = %LblPorcentagem
@onready var logo_rect: TextureRect = %LogoRect

var carregamento_iniciado: bool = false
var cena_carregada: PackedScene = null
var trocando_cena: bool = false

func _ready() -> void:
	progress_bar.value = 0.0
	lbl_porcentagem.text = "0%"
	lbl_status.text = "Despertando Grimórios do Reino de Clover..."
	
	# Animação suave de pulso do Logo
	_iniciar_animacao_logo()
	
	# Inicia o carregamento assíncrono da cena principal
	var erro = ResourceLoader.load_threaded_request(CENA_ALVO)
	if erro == OK:
		carregamento_iniciado = true
	else:
		lbl_status.text = "Erro ao iniciar carregamento de dados."
		print("Falha ao iniciar load_threaded_request para: ", CENA_ALVO)

func _process(delta: float) -> void:
	if not carregamento_iniciado or trocando_cena:
		return

	var progress = []
	var status = ResourceLoader.load_threaded_get_status(CENA_ALVO, progress)
	
	var progresso_float = 0.0
	if progress.size() > 0:
		progresso_float = progress[0]

	# Suaviza a barra para preenchimento orgânico
	progress_bar.value = move_toward(progress_bar.value, progresso_float * 100.0, delta * 80.0)
	lbl_porcentagem.text = "%d%%" % int(progress_bar.value)

	# Mensagens temáticas de acordo com o estágio
	if progress_bar.value < 30.0:
		lbl_status.text = "Despertando Grimórios Elementares..."
	elif progress_bar.value < 65.0:
		lbl_status.text = "Sincronizando Zonas de Forte Magia..."
	elif progress_bar.value < 95.0:
		lbl_status.text = "Reunindo Esquadrão dos Touros Negros..."
	else:
		lbl_status.text = "Reino de Clover Pronto! Entrando no Mundo Mágico..."

	if status == ResourceLoader.THREAD_LOAD_LOADED and progress_bar.value >= 98.0:
		trocando_cena = true
		cena_carregada = ResourceLoader.load_threaded_get(CENA_ALVO) as PackedScene
		_finalizar_carregamento()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		carregamento_iniciado = false
		lbl_status.text = "Erro no carregamento de dados do jogo."
		print("Erro: THREAD_LOAD_FAILED para ", CENA_ALVO)

func _finalizar_carregamento() -> void:
	# Transição cinematográfica de fade-out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		if cena_carregada:
			get_tree().change_scene_to_packed(cena_carregada)
	)

func _iniciar_animacao_logo() -> void:
	if not logo_rect:
		return
	logo_rect.pivot_offset = logo_rect.size / 2.0
	var tween = create_tween().set_loops()
	tween.tween_property(logo_rect, "scale", Vector2(1.025, 1.025), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo_rect, "scale", Vector2.ONE, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
