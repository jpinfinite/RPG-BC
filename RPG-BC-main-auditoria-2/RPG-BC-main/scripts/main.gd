extends Control
class_name Main

const MENU_CENAS := {
	"esquadrao": preload("res://scenes/esquadrao_menu.tscn"),
	"submundo": preload("res://scenes/submundo_menu.tscn"),
	"yami": preload("res://scenes/yami_bounty_panel.tscn"),
	"julius": preload("res://scenes/loja_julius_hud.tscn")
}

@onready var save_manager: SaveManager = $SaveManager
var _overlay: Control
var _conteudo_menu: Control
var _menu_ativo: Control

func _ready() -> void:
	_criar_navegacao_menus()
	_criar_overlay_menus()
	# Carrega o save após os gerenciadores filhos terem entrado na árvore.
	if save_manager:
		save_manager.carregar_jogo()
	var auto_save_timer := Timer.new()
	auto_save_timer.name = "AutoSaveTimer"
	auto_save_timer.wait_time = 30.0
	auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)

func _criar_navegacao_menus() -> void:
	var layout := get_node_or_null("LayoutVertical") as VBoxContainer
	if not layout:
		return
	var barra := HBoxContainer.new()
	barra.name = "BarraMenusSecundarios"
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_theme_constant_override("separation", 6)
	layout.add_child(barra)
	layout.move_child(barra, 0)
	var opcoes := [
		{"id": "esquadrao", "texto": "Esquadrão"},
		{"id": "yami", "texto": "Missão Yami"},
		{"id": "submundo", "texto": "Submundo"},
		{"id": "julius", "texto": "Loja Julius"}
	]
	for opcao in opcoes:
		var botao := Button.new()
		botao.text = str(opcao["texto"])
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.custom_minimum_size.y = 42
		botao.pressed.connect(_abrir_menu.bind(str(opcao["id"])))
		barra.add_child(botao)

func _criar_overlay_menus() -> void:
	_overlay = Control.new()
	_overlay.name = "OverlayMenusSecundarios"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 80
	_overlay.visible = false
	add_child(_overlay)
	var fundo := ColorRect.new()
	fundo.name = "FundoEscuro"
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.015, 0.02, 0.035, 0.88)
	_overlay.add_child(fundo)
	var margem := MarginContainer.new()
	margem.name = "MargemPainel"
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 24)
	margem.add_theme_constant_override("margin_top", 90)
	margem.add_theme_constant_override("margin_right", 24)
	margem.add_theme_constant_override("margin_bottom", 90)
	_overlay.add_child(margem)
	var painel := PanelContainer.new()
	painel.name = "PainelMenu"
	painel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.name = "ColunaMenu"
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel.add_child(coluna)
	var fechar := Button.new()
	fechar.name = "FecharMenu"
	fechar.text = "✕  Fechar"
	fechar.custom_minimum_size.y = 44
	fechar.pressed.connect(_fechar_menu)
	coluna.add_child(fechar)
	_conteudo_menu = Control.new()
	_conteudo_menu.name = "ConteudoMenu"
	_conteudo_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_conteudo_menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(_conteudo_menu)

func _abrir_menu(id_menu: String) -> void:
	if not MENU_CENAS.has(id_menu) or not _conteudo_menu:
		return
	if is_instance_valid(_menu_ativo):
		_menu_ativo.queue_free()
	_menu_ativo = MENU_CENAS[id_menu].instantiate() as Control
	if not _menu_ativo:
		return
	_menu_ativo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_conteudo_menu.add_child(_menu_ativo)
	_overlay.visible = true

func _fechar_menu() -> void:
	_overlay.visible = false
	if is_instance_valid(_menu_ativo):
		_menu_ativo.queue_free()
	_menu_ativo = null

func _on_auto_save_timer_timeout() -> void:
	if save_manager:
		save_manager.salvar_jogo()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if save_manager:
			save_manager.salvar_jogo()
