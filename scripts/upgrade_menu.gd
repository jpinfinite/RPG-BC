extends Control
class_name UpgradeMenu

@export var mago_progressao: MagoProgressao
@export var cozinha_charmy: CozinhaCharmy

# Aba 1: Treinamento do Mago
@onready var btn_treinar_mago: Button = %BtnTreinarMago
@onready var lbl_nivel_mago: Label = %LblNivelMago
@onready var lbl_custo_upgrade: Label = %LblCustoUpgrade
@onready var lbl_dps_info: Label = %LblDpsInfo

# Aba 2: Cozinha da Charmy
@onready var btn_comprar_refeicao: Button = %BtnComprarRefeicao
@onready var lbl_custo_refeicao: Label = %LblCustoRefeicao
@onready var lbl_status_buff: Label = %LblStatusBuff
@onready var progress_buff_charmy: ProgressBar = %ProgressBuffCharmy

func _ready() -> void:
	_resolver_dependencias()
	_conectar_sinais()
	atualizar_interface_mago()
	atualizar_interface_charmy()

func _resolver_dependencias() -> void:
	if not mago_progressao:
		mago_progressao = get_tree().get_first_node_in_group("mago_progressao") as MagoProgressao
		if not mago_progressao:
			mago_progressao = get_node_or_null("../MagoProgressao") as MagoProgressao
			
	if not cozinha_charmy:
		cozinha_charmy = get_tree().get_first_node_in_group("cozinha_charmy") as CozinhaCharmy
		if not cozinha_charmy:
			cozinha_charmy = get_node_or_null("../CozinhaCharmy") as CozinhaCharmy

func _conectar_sinais() -> void:
	btn_treinar_mago.pressed.connect(_on_btn_treinar_mago_pressed)
	btn_comprar_refeicao.pressed.connect(_on_btn_comprar_refeicao_pressed)
	
	if GameManager:
		GameManager.recursos_atualizados.connect(_on_recursos_atualizados)

func _process(_delta: float) -> void:
	if cozinha_charmy and cozinha_charmy.buff_ativo:
		progress_buff_charmy.visible = true
		progress_buff_charmy.max_value = 300.0
		progress_buff_charmy.value = cozinha_charmy.tempo_restante_buff
		
		var minutos = int(cozinha_charmy.tempo_restante_buff) / 60
		var segundos = int(cozinha_charmy.tempo_restante_buff) % 60
		lbl_status_buff.text = "Buff Ativo: Dobro de Ouro! (%02d:%02d)" % [minutos, segundos]
		lbl_status_buff.modulate = Color(1.0, 0.85, 0.2)
		btn_comprar_refeicao.disabled = true
	elif cozinha_charmy:
		progress_buff_charmy.visible = false
		lbl_status_buff.text = "Nenhum banquete ativo no momento."
		lbl_status_buff.modulate = Color(0.7, 0.7, 0.7)
		btn_comprar_refeicao.disabled = false

func _on_recursos_atualizados() -> void:
	atualizar_interface_mago()
	atualizar_interface_charmy()

func _on_btn_treinar_mago_pressed() -> void:
	if mago_progressao:
		if mago_progressao.upar_nivel_mago():
			atualizar_interface_mago()

func _on_btn_comprar_refeicao_pressed() -> void:
	if cozinha_charmy:
		if cozinha_charmy.comprar_refeicao_charmy():
			atualizar_interface_charmy()

func atualizar_interface_mago() -> void:
	if not mago_progressao:
		return
	
	lbl_nivel_mago.text = "Nível do Mago: %d" % mago_progressao.nivel_mago
	var custo = mago_progressao.get_custo_upgrade()
	lbl_custo_upgrade.text = "Custo: %d Poeira de Mana" % int(custo)
	
	var dps = GameManager.dano_por_segundo if GameManager else 10.0
	lbl_dps_info.text = "Dano Base: %.1f DPS" % dps
	
	# Desabilita o botão caso o jogador não tenha recursos suficientes
	if GameManager:
		btn_treinar_mago.disabled = GameManager.poeira_mana < custo

func atualizar_interface_charmy() -> void:
	if not cozinha_charmy:
		return
	
	var custo_refeicao = cozinha_charmy.get_custo_refeicao()
	lbl_custo_refeicao.text = "Custo do Banquete: %d Ouro" % int(custo_refeicao)
	
	if GameManager and not cozinha_charmy.buff_ativo:
		btn_comprar_refeicao.disabled = GameManager.ouro < custo_refeicao
