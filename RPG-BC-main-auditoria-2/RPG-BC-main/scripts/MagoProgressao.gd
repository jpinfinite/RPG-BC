extends Node
class_name MagoProgressao

@export var game_manager: Node

var nivel_mago: int = 1
var custo_base_nivel: float = 20.0

func _ready() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# Retorna o custo de poeira de mana para o próximo nível (escala exponencial típica de Idle)
func get_custo_upgrade() -> float:
	return custo_base_nivel * pow(1.2, nivel_mago - 1)

# Função chamada pelo botão de Upgrade da UI
func upar_nivel_mago() -> bool:
	if not game_manager:
		return false
		
	var custo = get_custo_upgrade()
	
	if game_manager.poeira_mana >= custo:
		game_manager.poeira_mana -= custo
		nivel_mago += 1
		
		# Registra progresso da missão de treinamento do Yami
		var missao_manager = game_manager.get_node_or_null("MissaoManager")
		if not missao_manager and get_tree():
			missao_manager = get_tree().get_first_node_in_group("missao_manager")
		if missao_manager:
			missao_manager.registrar_progresso(2, 1) # 2 = TipoMissao.UPAR_MAGO
		
		# Aumenta o dano base do jogador permanentemente
		game_manager.dano_por_segundo += 5.0 * (1.0 + (nivel_mago * 0.05))
		game_manager.recursos_atualizados.emit()
		
		print("Mago subiu para o nível ", nivel_mago, "! Novo Dano Base: ", game_manager.dano_por_segundo)
		return true
		
	print("Poeira de Mana insuficiente! Você precisa de: ", int(custo))
	return false
