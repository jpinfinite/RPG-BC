extends Node
# O GameManager é registrado como Autoload Singleton global no project.godot
# FONTE DE VERDADE: repositório de estado do jogador.
# NÃO possui loop de combate próprio — isso é responsabilidade do CombatManager.

## Sinais
signal recursos_atualizados
signal inimigo_atualizado(dados: Dictionary)
signal inimigo_derrotado(dados: Dictionary)

# Recursos Principais
var ouro: float = 0.0
var poeira_mana: float = 0.0
var andar_atual: int = 1

# Estado de Combate (mantido para compatibilidade com Save/Load e UI observadores)
var inimigo_atual: Dictionary = {}

# Multiplicadores baseados no universo de Black Clover
var tipo_grimorio: String = "Trevo de 3 Folhas (Comum)"
var raridade_grimorio: String = "Comum"
var efeito_especial: String = "Nenhum"
var multiplicador_mana: float = 1.0  # 3 folhas = 1x, 4 folhas = 2x, 5 folhas (Anti-Magia) = 5x
var mult_dano: float = 1.0
var mult_ouro: float = 1.0
var dano_por_segundo: float = 10.0
var bonus_critico: float = 0.05
var chance_critico_atual: float = 0.05
var multiplicador_ouro_global: float = 1.0
var mult_anti_magia_definitivo: float = 1.0
var mult_dano_rank: float = 1.0
var mult_ouro_rank: float = 1.0
var dps_esquadrao_passivo: float = 0.0
var libera_demonio: bool = false

func _ready() -> void:
	# GameManager apenas inicializa estado — sem timer de combate próprio
	pass

## Aplica os dados de um grimório sorteado
func aplicar_dados_grimorio(dados: Dictionary) -> void:
	tipo_grimorio = dados.get("nome", tipo_grimorio)
	mult_dano = dados.get("mult_dano", dados.get("multiplicador_mana", 1.0))
	multiplicador_mana = mult_dano
	mult_ouro = dados.get("mult_ouro", 1.0)
	bonus_critico = dados.get("chance_critico", dados.get("bonus_critico", 0.05))
	chance_critico_atual = bonus_critico
	efeito_especial = dados.get("efeito_especial", "Nenhum")
	raridade_grimorio = dados.get("raridade", "Comum")
	libera_demonio = dados.get("libera_demonio", raridade_grimorio == "Mítico" or efeito_especial.contains("Demônio"))
	recursos_atualizados.emit()

## Realiza a Cerimônia de Aceitação da Torre de Grimórios (Gacha)
func realizar_cerimonia_aceitacao() -> Dictionary:
	var grimorio_sorteado = GrimorioData.rodar_gacha()
	aplicar_dados_grimorio(grimorio_sorteado)
	return grimorio_sorteado

## Recalcula os status globais integrando bônus de Anti-Magia, Ranks e Esquadrão
func atualizar_multiplicadores_globais() -> void:
	var tree = get_tree()
	if not tree:
		return

	var esquadrao_manager = tree.get_first_node_in_group("esquadrao_manager") as EsquadraoManager
	if esquadrao_manager:
		dps_esquadrao_passivo = esquadrao_manager.dps_total_aliados

	var rank_manager = tree.get_first_node_in_group("rank_manager") as RankManager
	if rank_manager:
		var dados_rank = rank_manager.get_rank_atual()
		mult_dano_rank = dados_rank.get("mult_dano", 1.0)
		mult_ouro_rank = dados_rank.get("mult_ouro", 1.0)

	var contrato = tree.get_first_node_in_group("contrato_demonio") as ContratoDemonio
	if contrato:
		mult_anti_magia_definitivo = contrato.bonus_anti_magia

	recursos_atualizados.emit()

## Alias de compatibilidade
func actualizar_multiplicadores_globais() -> void:
	atualizar_multiplicadores_globais()

## Recalcula o DPS do mago a partir do nível (usado ao carregar save)
func recalcular_dps_por_nivel(nivel_mago: int) -> void:
	# Fórmula inversa de MagoProgressao.upar_nivel_mago()
	# Cada nível adiciona 5.0 * (1 + nivel * 0.05) — acumulado
	dano_por_segundo = 10.0
	for n in range(1, nivel_mago):
		dano_por_segundo += 5.0 * (1.0 + (n * 0.05))
