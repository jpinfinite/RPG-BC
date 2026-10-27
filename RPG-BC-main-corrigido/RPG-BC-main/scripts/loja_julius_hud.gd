extends VBoxContainer
class_name LojaJuliusHUD

@export var loja_tempo_julius: LojaTempoJulius
@export var missao_manager: MissaoManager

@onready var lbl_medalhas: Label = %LblMedalhasDisponiveis
@onready var lbl_feedback: Label = %LblFeedbackTempo
@onready var container_itens: VBoxContainer = %ContainerItens

# Armazena os nós dos botões de cada time skip
var botoes_itens: Dictionary = {}

func _ready() -> void:
	_resolver_referencias()
	_inicializar_botoes()
	atualizar_interface()
	
	if loja_tempo_julius:
		loja_tempo_julius.tempo_acelerado.connect(_on_tempo_acelerado)
	if missao_manager:
		missao_manager.missao_atualizada.connect(atualizar_interface)

func _resolver_referencias() -> void:
	if not loja_tempo_julius and get_tree():
		loja_tempo_julius = get_tree().get_first_node_in_group("loja_tempo_julius") as LojaTempoJulius
		if not loja_tempo_julius:
			loja_tempo_julius = get_node_or_null("/root/Main/LojaTempoJulius") as LojaTempoJulius
			
	if not missao_manager and get_tree():
		missao_manager = get_tree().get_first_node_in_group("missao_manager") as MissaoManager
		if not missao_manager:
			missao_manager = get_node_or_null("/root/Main/MissaoManager") as MissaoManager

func _inicializar_botoes() -> void:
	for id_item in LojaTempoJulius.ITENS_LOJA.keys():
		var row_node = container_itens.get_node_or_null("Row_" + id_item)
		if not row_node:
			continue
			
		var btn = row_node.get_node("Margin/HBox/BtnComprar") as Button
		btn.pressed.connect(func(): _on_comprar_clicado(id_item))
		botoes_itens[id_item] = {
			"row": row_node,
			"btn": btn,
			"custo": LojaTempoJulius.ITENS_LOJA[id_item]["custo_medalhas"]
		}

func _process(_delta: float) -> void:
	atualizar_interface()

func atualizar_interface() -> void:
	var medalhas = 0
	if missao_manager:
		medalhas = missao_manager.medalhas_merito
	else:
		_resolver_referencias()
		if missao_manager:
			medalhas = missao_manager.medalhas_merito
			
	if lbl_medalhas:
		lbl_medalhas.text = "🏅 Medalhas de Mérito: %d" % medalhas

	# Atualiza o estado dos botões conforme as medalhas disponíveis
	for id_item in botoes_itens.keys():
		var info = botoes_itens[id_item]
		var btn: Button = info["btn"]
		var custo: int = info["custo"]
		
		if medalhas >= custo:
			btn.disabled = false
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.7, 0.8)

func _on_comprar_clicado(id_item: String) -> void:
	if not loja_tempo_julius:
		_resolver_referencias()
		if not loja_tempo_julius:
			return
			
	var comprou = loja_tempo_julius.comprar_time_skip(id_item)
	if not comprou:
		_animar_erro_compra(id_item)

func _on_tempo_acelerado(ouro_ganho: float, poeira_ganha: float) -> void:
	atualizar_interface()
	
	if lbl_feedback:
		lbl_feedback.text = "¡TEMPO DISTORCIDO! +%s Ouro | +%s Poeira de Mana" % [
			_formatar_numero(ouro_ganho),
			_formatar_numero(poeira_ganha)
		]
		lbl_feedback.modulate = Color(1.2, 2.0, 2.5, 1.0) # Flash ciano temporal brilhante
		
		var tween = create_tween()
		tween.tween_property(lbl_feedback, "modulate", Color(0.3, 0.85, 1.0, 1.0), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animar_erro_compra(id_item: String) -> void:
	if not botoes_itens.has(id_item):
		return
	var row_node: Control = botoes_itens[id_item]["row"]
	var tween = create_tween()
	tween.tween_property(row_node, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.1)
	tween.tween_property(row_node, "modulate", Color.WHITE, 0.25)

func _formatar_numero(valor: float) -> String:
	if valor >= 1_000_000:
		return "%.1fM" % (valor / 1_000_000.0)
	elif valor >= 1_000:
		return "%.1fK" % (valor / 1_000.0)
	return str(int(valor))
