extends Control
class_name SubmundoMenu

@export var contrato_demonio: ContratoDemonio

@onready var lbl_carteira_submundo: Label = %LblCarteiraSubmundo
@onready var lbl_bonus_atual: Label = %LblBonusAtual
@onready var lbl_aviso_reset: Label = %LblAvisoReset
@onready var btn_contrato: Button = %BtnContratoDemonio
@onready var btn_comprar_poder: Button = %BtnComprarPoder
@onready var particulas_fumaca: GPUParticles2D = %ParticulasFumacaPreta

func _ready() -> void:
	_resolver_referencias()
	_conectar_sinais()
	atualizar_interface()

func _resolver_referencias() -> void:
	if not contrato_demonio:
		contrato_demonio = get_tree().get_first_node_in_group("contrato_demonio") as ContratoDemonio
		if not contrato_demonio:
			contrato_demonio = get_node_or_null("../ContratoDemonio") as ContratoDemonio

func _conectar_sinais() -> void:
	btn_contrato.pressed.connect(_on_btn_contrato_pressed)
	btn_comprar_poder.pressed.connect(_on_btn_comprar_poder_pressed)
	
	if GameManager:
		GameManager.recursos_atualizados.connect(atualizar_interface)
	if contrato_demonio:
		contrato_demonio.contrato_executado.connect(func(_qtd): atualizar_interface())
		contrato_demonio.poder_demoniaco_comprado.connect(func(_b): atualizar_interface())

func _process(_delta: float) -> void:
	# Atualiza estimativa de moedas dinamicamente
	if visible:
		_atualizar_estimativa_moedas()

func _on_btn_contrato_pressed() -> void:
	if contrato_demonio:
		if contrato_demonio.realizar_contrato_proibido():
			# Animação de tremor ou flash demoníaco
			_animar_flash_demoniaco()
			atualizar_interface()

func _on_btn_comprar_poder_pressed() -> void:
	if contrato_demonio:
		if contrato_demonio.comprar_poder_demoniaco():
			atualizar_interface()

func atualizar_interface() -> void:
	if not contrato_demonio:
		return
	
	lbl_carteira_submundo.text = "Moedas do Submundo: %d 🩸" % contrato_demonio.moedas_submundo
	var porcentagem_bonus = int((contrato_demonio.bonus_anti_magia - 1.0) * 100.0)
	lbl_bonus_atual.text = "Anti-Magia Definitiva: +%d%% Dano Global (x%.1f)" % [porcentagem_bonus, contrato_demonio.bonus_anti_magia]
	
	var custo_poder = int(10 * contrato_demonio.bonus_anti_magia)
	btn_comprar_poder.text = "Poder Demoníaco (+100%% Dano) - Custo: %d Moedas" % custo_poder
	btn_comprar_poder.disabled = contrato_demonio.moedas_submundo < custo_poder
	
	_atualizar_estimativa_moedas()

func _atualizar_estimativa_moedas() -> void:
	if not contrato_demonio or not GameManager:
		return
		
	var moedas_ganhas = contrato_demonio.calcular_moedas_ganhas()
	var andar = GameManager.andar_atual
	
	if andar < 50:
		lbl_aviso_reset.text = "Desespero Insuficiente!\nAlcance o Andar 50+ para despertar o Contrato.\n(Andar Atual: %d / 50)" % andar
		lbl_aviso_reset.modulate = Color(0.85, 0.4, 0.4)
		btn_contrato.disabled = true
	else:
		lbl_aviso_reset.text = "O Pacto está disponível!\nAo resetar o mundo agora, você receberá:\n+ %d Moedas do Submundo" % moedas_ganhas
		lbl_aviso_reset.modulate = Color(1.0, 0.2, 0.25)
		btn_contrato.disabled = moedas_ganhas <= 0

func _animar_flash_demoniaco() -> void:
	var tween = create_tween()
	modulate = Color(2.5, 0.3, 0.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.6)
