extends ScrollContainer
class_name EsquadraoMenu

@export var esquadrao_manager: EsquadraoManager

@onready var lista_aliados: VBoxContainer = %ListaAliados

# Guarda referências dos botões e labels de cada aliado para atualizações de alta performance
var widgets_aliados: Dictionary = {}

func _ready() -> void:
	_resolver_referencias()
	_construir_cards_aliados()
	_conectar_sinais()
	atualizar_todos_aliados()

func _resolver_referencias() -> void:
	if not esquadrao_manager:
		esquadrao_manager = get_tree().get_first_node_in_group("esquadrao_manager") as EsquadraoManager
		if not esquadrao_manager:
			esquadrao_manager = get_node_or_null("../EsquadraoManager") as EsquadraoManager

func _conectar_sinais() -> void:
	if esquadrao_manager:
		esquadrao_manager.esquadrao_atualizado.connect(atualizar_todos_aliados)
	if GameManager:
		GameManager.recursos_atualizados.connect(atualizar_todos_aliados)

func _construir_cards_aliados() -> void:
	for child in lista_aliados.get_children():
		child.queue_free()
	widgets_aliados.clear()
	
	for id_aliado in AliadosData.ALIADOS.keys():
		var dados = AliadosData.ALIADOS[id_aliado]
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 72)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.14, 0.9)
		style.set_corner_radius_all(8)
		style.border_width_bottom = 2
		style.border_color = Color(0.2, 0.22, 0.3, 0.8)
		panel.add_theme_stylebox_override("panel", style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		margin.add_child(hbox)
		
		# Coluna de Informações do Aliado
		var vbox_info = VBoxContainer.new()
		vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox_info)
		
		var lbl_nome = Label.new()
		lbl_nome.text = dados["nome"] + " • " + dados["esquadrao"]
		lbl_nome.add_theme_font_size_override("font_size", 16)
		vbox_info.add_child(lbl_nome)
		
		var lbl_detalhes = Label.new()
		lbl_detalhes.add_theme_font_size_override("font_size", 13)
		vbox_info.add_child(lbl_detalhes)
		
		# Elemento visual com cor temática
		var elemento = dados["elemento"]
		match elemento:
			"Fogo":
				lbl_nome.modulate = Color(1.0, 0.45, 0.2)
			"Água":
				lbl_nome.modulate = Color(0.35, 0.75, 1.0)
			"Vento":
				lbl_nome.modulate = Color(0.4, 0.95, 0.5)
			_:
				lbl_nome.modulate = Color.WHITE
		
		# Botão Dinâmico de Recrutar / Upar
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(170, 44)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func(): _on_btn_aliado_pressed(id_aliado))
		hbox.add_child(btn)
		
		lista_aliados.add_child(panel)
		
		widgets_aliados[id_aliado] = {
			"lbl_detalhes": lbl_detalhes,
			"btn": btn
		}

func _on_btn_aliado_pressed(id_aliado: String) -> void:
	if esquadrao_manager:
		esquadrao_manager.upar_aliado(id_aliado)

func atualizar_todos_aliados() -> void:
	if not esquadrao_manager:
		return
		
	var ouro_atual = GameManager.ouro if GameManager else 0.0
	
	for id_aliado in widgets_aliados.keys():
		var widgets = widgets_aliados[id_aliado]
		var dados = AliadosData.ALIADOS[id_aliado]
		var nivel = esquadrao_manager.niveis_aliados.get(id_aliado, 0)
		var custo = AliadosData.get_custo_aliado(id_aliado, nivel)
		var dano = AliadosData.get_dano_aliado(id_aliado, nivel)
		
		var texto_nivel = "Nível: %d" % nivel if nivel > 0 else "Não Recrutado"
		widgets["lbl_detalhes"].text = "%s | Elemento: %s | +%.1f DPS" % [texto_nivel, dados["elemento"], dano]
		
		var acao = "Upar" if nivel > 0 else "Recrutar"
		widgets["btn"].text = "%s (%s 🪙)" % [acao, _formatar_custo(custo)]
		widgets["btn"].disabled = ouro_atual < custo

func _formatar_custo(valor: float) -> String:
	if valor >= 1_000_000:
		return "%.2fM" % (valor / 1_000_000.0)
	elif valor >= 1_000:
		return "%.1fK" % (valor / 1_000.0)
	else:
		return str(int(valor))
