extends Node
class_name LojaTempoJulius

signal tempo_acelerado(ouro_ganho: float, poeira_ganha: float)

@export var game_manager: Node
@export var missao_manager: MissaoManager

# Tabela de preços e durações em segundos (1h, 4h, 12h)
const ITENS_LOJA = {
	"skip_1h": {"nome": "Ampulheta de Mana (1 Hora)", "custo_medalhas": 10, "segundos": 3600.0, "icone": "⏳"},
	"skip_4h": {"nome": "Orbe Temporal (4 Horas)", "custo_medalhas": 35, "segundos": 14400.0, "icone": "🔮"},
	"skip_12h": {"nome": "Grimório do Tempo (12 Horas)", "custo_medalhas": 90, "segundos": 43200.0, "icone": "📜"}
}

func _ready() -> void:
	_resolver_referencias()

func _resolver_referencias() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		
	if not missao_manager and get_tree():
		missao_manager = get_tree().get_first_node_in_group("missao_manager") as MissaoManager
		if not missao_manager:
			missao_manager = get_node_or_null("/root/Main/MissaoManager") as MissaoManager

# Executa a compra e aplica a aceleração de tempo instantaneamente
func comprar_time_skip(id_item: String) -> bool:
	if not ITENS_LOJA.has(id_item):
		return false
	_resolver_referencias()
	if not missao_manager or not game_manager:
		return false
	
	var item = ITENS_LOJA[id_item]
	var custo = item["custo_medalhas"]
	
	# Verifica se o jogador tem medalhas de mérito suficientes com o Yami
	if missao_manager.medalhas_merito >= custo:
		missao_manager.medalhas_merito -= custo
		missao_manager.missao_atualizada.emit() # Notifica interface das missões
		_aplicar_aceleracao_temporal(item["segundos"], item["nome"])
		return true
		
	print("Medalhas de Mérito insuficientes! Julius precisa de: ", custo, " medalhas.")
	return false

# Simula o ganho de recursos acumulados durante o período acelerado
func _aplicar_aceleracao_temporal(segundos: float, nome_item: String) -> void:
	# Calcula o ganho por segundo baseado nas fórmulas existentes de dano e andares
	var mult_anti = game_manager.mult_anti_magia_definitivo if "mult_anti_magia_definitivo" in game_manager else 1.0
	var dps_base = game_manager.dano_por_segundo * game_manager.multiplicador_mana * mult_anti
	var ganho_ouro_por_segundo = dps_base * (1.0 + (game_manager.andar_atual * 0.1))
	
	# Multiplica pelo tempo comprado e pelos bônus globais ativos (como a cozinha da Charmy ou Rank)
	var mult_global = game_manager.multiplicador_ouro_global if "multiplicador_ouro_global" in game_manager else 1.0
	var mult_rank = game_manager.mult_ouro_rank if "mult_ouro_rank" in game_manager else 1.0
	var total_ouro_ganho = ganho_ouro_por_segundo * segundos * mult_global * mult_rank
	
	# Da mesma forma, calcula a poeira de mana ganha de forma estimada
	var total_poeira_ganha = (1.5 * game_manager.andar_atual) * (segundos / 2.0)
	
	# Injeta os valores diretamente na carteira do jogador
	game_manager.ouro += total_ouro_ganho
	game_manager.poeira_mana += total_poeira_ganha
	game_manager.recursos_atualizados.emit()
	
	print("¡MAGIA DE TEMPO! Usou ", nome_item, ". Avançou ", int(segundos / 3600.0), " horas instantaneamente!")
	print("Recursos recebidos: +", int(total_ouro_ganho), " de Ouro e +", int(total_poeira_ganha), " Poeira de Mana.")
	
	tempo_acelerado.emit(total_ouro_ganho, total_poeira_ganha)
