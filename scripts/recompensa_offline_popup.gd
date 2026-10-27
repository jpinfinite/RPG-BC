extends Control
class_name RecompensaOfflinePopup

@export var save_manager: SaveManager

@onready var painel_card: PanelContainer = %PainelCard
@onready var lbl_mensagem: Label = %LblMensagem
@onready var lbl_tempo: Label = %LblTempo
@onready var lbl_total_ouro: Label = %LblTotalOuro
@onready var btn_coletar: Button = %BtnColetar

func _ready() -> void:
	visible = false
	btn_coletar.pressed.connect(_on_btn_coletar_pressed)
	_conectar_save_manager()

func _conectar_save_manager() -> void:
	if not save_manager:
		save_manager = get_tree().get_first_node_in_group("save_manager") as SaveManager
		if not save_manager:
			save_manager = get_node_or_null("../SaveManager") as SaveManager

	if save_manager:
		save_manager.progresso_offline_recebido.connect(exibir_recompensa)

func exibir_recompensa(horas: int, minutos: int, ouro_ganho: float) -> void:
	if ouro_ganho <= 0.0:
		return

	lbl_mensagem.text = "Seu esquadrão retornou das Zonas de Forte Magia!"
	lbl_tempo.text = "Tempo em treinamento: %d horas e %d minutos" % [horas, minutos]
	lbl_total_ouro.text = "+ %s Magic Ouro" % _formatar_numero(ouro_ganho)
	
	visible = true
	
	# Animação de abertura suave com efeito pop-up
	modulate.a = 0.0
	painel_card.scale = Vector2(0.8, 0.8)
	painel_card.pivot_offset = painel_card.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_property(painel_card, "scale", Vector2.ONE, 0.3)

func _on_btn_coletar_pressed() -> void:
	if save_manager:
		save_manager.coletar_ouro_offline()

	# Animação de saída
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(painel_card, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(func(): visible = false)

func _formatar_numero(valor: float) -> String:
	if valor >= 1_000_000:
		return "%.2fM" % (valor / 1_000_000.0)
	elif valor >= 1_000:
		return "%.1fK" % (valor / 1_000.0)
	else:
		return str(int(valor))
