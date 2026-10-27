extends Node
class_name RankManager

signal jogador_promovido(novo_titulo: String)

@export var game_manager: Node

# Lista ordenada de Ranks inspirada na hierarquia oficial de Black Clover
const RANKS = [
	{"titulo": "Cavaleiro Mágico Júnior - Classe 5", "andar_req": 1, "mult_dano": 1.0, "mult_ouro": 1.0},
	{"titulo": "Cavaleiro Mágico Júnior - Classe 1", "andar_req": 15, "mult_dano": 1.5, "mult_ouro": 1.2},
	{"titulo": "Cavaleiro Mágico Intermediário", "andar_req": 40, "mult_dano": 2.5, "mult_ouro": 1.8},
	{"titulo": "Cavaleiro Mágico Sênior", "andar_req": 80, "mult_dano": 5.0, "mult_ouro": 3.0},
	{"titulo": "Gran Cavaleiro Mágico (Capitão)", "andar_req": 150, "mult_dano": 12.0, "mult_ouro": 8.0},
	{"titulo": "Candidato a Rei Mago", "andar_req": 300, "mult_dano": 30.0, "mult_ouro": 20.0},
	{"titulo": "Rei Mago (Julius Novachrono)", "andar_req": 500, "mult_dano": 100.0, "mult_ouro": 50.0}
]

var rank_index_atual: int = 0

func _ready() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	_aplicar_beneficios_rank()

# Verifica se o jogador se qualificou para um novo Rank com base no andar atual
func verificar_promocao() -> void:
	if not game_manager:
		return
		
	var proximo_rank_index = rank_index_atual + 1
	
	# Verifica se existe um próximo rank na lista
	if proximo_rank_index < RANKS.size():
		var proximo_rank = RANKS[proximo_rank_index]
		
		if game_manager.andar_atual >= proximo_rank["andar_req"]:
			rank_index_atual = proximo_rank_index
			_aplicar_beneficios_rank()
			jogador_promovido.emit(RANKS[rank_index_atual]["titulo"])

func _aplicar_beneficios_rank() -> void:
	var rank_data = RANKS[rank_index_atual]
	print("PROMOÇÃO! Você agora é um: ", rank_data["titulo"])
	
	# Injeta os multiplicadores de rank diretamente na fórmula global do GameManager
	if game_manager:
		game_manager.actualizar_multiplicadores_globais()

# Retorna os dados do Rank atual do jogador
func get_rank_atual() -> Dictionary:
	return RANKS[clamp(rank_index_atual, 0, RANKS.size() - 1)]
