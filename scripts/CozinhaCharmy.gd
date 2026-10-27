extends Node
class_name CozinhaCharmy

@export var game_manager: Node

var buff_ativo: bool = false
var multiplicador_comida: float = 1.0
var tempo_restante_buff: float = 0.0

func _ready() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

func _process(delta: float) -> void:
	# Gerencia o tempo do buff em tempo real
	if buff_ativo:
		tempo_restante_buff -= delta
		if tempo_restante_buff <= 0:
			desativar_buff()

# Compra a "Super Refeição de Ovelha Cozinheira" usando Ouro
func comprar_refeicao_charmy() -> bool:
	if not game_manager:
		return false

	var custo_refeicao = 500.0 * pow(1.5, game_manager.andar_atual - 1)
	
	if game_manager.ouro >= custo_refeicao and not buff_ativo:
		game_manager.ouro -= custo_refeicao
		buff_ativo = true
		tempo_restante_buff = 300.0 # 5 minutos de duração
		multiplicador_comida = 2.0  # Dobra os ganhos de ouro do GameManager
		
		# Injeta o modificador diretamente no GameManager
		game_manager.multiplicador_ouro_global *= multiplicador_comida
		game_manager.recursos_atualizados.emit()
		print("Charmy cozinhou! Ganhos de ouro duplicados por 5 minutos.")
		return true
		
	print("Não foi possível comprar a refeição (Ouro insuficiente ou buff já ativo).")
	return false

func desativar_buff() -> void:
	if not buff_ativo:
		return
	buff_ativo = false
	# Remove o multiplicador dividindo pelo mesmo valor aplicado
	if game_manager:
		game_manager.multiplicador_ouro_global /= multiplicador_comida
		game_manager.recursos_atualizados.emit()
	multiplicador_comida = 1.0
	print("O efeito da comida da Charmy acabou! Os heróis estão com fome de novo.")
