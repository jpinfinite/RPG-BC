extends Node
# O GameManager é registrado como Autoload Singleton global no project.godot

## Sinais
signal recursos_atualizados
signal inimigo_atualizado(dados: Dictionary)
signal inimigo_derrotado(dados: Dictionary)

# Recursos Principais
var ouro: float = 0.0
var poeira_mana: float = 0.0
var andar_atual: int = 1

# Estado de Combate
var inimigo_atual: Dictionary = {}

# Multiplicadores baseados no universo de Black Clover
var tipo_grimorio: String = "Trevo de 3 Folhas (Comum)"
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
var raridade_grimorio: String = "Comum"
var efeito_especial: String = "Nenhum"

func _ready() -> void:
	# Inicializa o loop de ganho passivo (1 vez por segundo)
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_idle_tick)
	add_child(timer)
	
	# Spawna o primeiro inimigo do andar atual
	gerar_novo_inimigo()

func gerar_novo_inimigo() -> void:
	inimigo_atual = InimigoData.gerar_inimigo(andar_atual)
	inimigo_atualizado.emit(inimigo_atual)

func _on_idle_tick() -> void:
	# Aplica o dano por segundo no inimigo ativo levando em conta (Dano Mago + Dps Esquadrão) * Grimório * Anti-Magia * Rank
	var dps_base_total = dano_por_segundo + dps_esquadrao_passivo
	var dps_efetivo = dps_base_total * mult_dano * mult_anti_magia_definitivo * mult_dano_rank
	aplicar_dano_no_inimigo(dps_efetivo)
	
	# Ganho de ouro passivo com suporte a buffs globais e multiplicador de Rank
	var ouro_base = (dps_efetivo * mult_ouro * mult_ouro_rank) * (1.0 + (andar_atual * 0.1))
	var ouro_ganho_final = ouro_base * multiplicador_ouro_global
	ouro += ouro_ganho_final
	recursos_atualizados.emit()
	
	# Simula o combate automático em segundo plano
	print("Ouro atual: ", int(ouro), " | Andar: ", andar_atual, " | Grimório: ", tipo_grimorio)

## Aplica dano direto (clique na tela ou ataque rápido do jogador)
func atacar_por_clique() -> Dictionary:
	var dps_base_total = dano_por_segundo + dps_esquadrao_passivo
	var dano = (dps_base_total * mult_dano * mult_anti_magia_definitivo * mult_dano_rank) * 0.5 # 50% do DPS por clique
	var e_critico = randf() < bonus_critico
	if e_critico:
		dano *= 2.0
	
	aplicar_dano_no_inimigo(dano)
	return {"dano": dano, "critico": e_critico}




## Processa o dano no inimigo e gerencia drops e subida de andar
func aplicar_dano_no_inimigo(dano: float) -> void:
	if inimigo_atual.is_empty():
		gerar_novo_inimigo()
		return
	
	inimigo_atual["vida_atual"] = maxf(0.0, inimigo_atual["vida_atual"] - dano)
	inimigo_atualizado.emit(inimigo_atual)
	
	if inimigo_atual["vida_atual"] <= 0.0:
		_ao_derrotar_inimigo()

func _ao_derrotar_inimigo() -> void:
	var ouro_base = inimigo_atual.get("ouro_recompensa", 10.0) * mult_ouro * mult_ouro_rank
	var ganho_ouro = ouro_base * multiplicador_ouro_global
	var ganho_poeira = inimigo_atual.get("poeira_recompensa", 5.0)
	
	ouro += ganho_ouro
	poeira_mana += ganho_poeira
	recursos_atualizados.emit()
	inimigo_derrotado.emit(inimigo_atual)
	
	# Avança para o próximo andar
	andar_atual += 1
	gerar_novo_inimigo()

	# Checa promoção de Rank
	var rank_mgr = get_node_or_null("RankManager")
	if not rank_mgr and get_tree():
		rank_mgr = get_tree().get_first_node_in_group("rank_manager")
	if rank_mgr:
		rank_mgr.verificar_promocao()

## Aplica os dados de um grimório sorteado no GrimorioData
func aplicar_dados_grimorio(dados: Dictionary) -> void:
	tipo_grimorio = dados.get("nome", tipo_grimorio)
	mult_dano = dados.get("mult_dano", dados.get("multiplicador_mana", 1.0))
	multiplicador_mana = mult_dano
	mult_ouro = dados.get("mult_ouro", 1.0)
	bonus_critico = dados.get("chance_critico", dados.get("bonus_critico", 0.05))
	chance_critico_atual = bonus_critico
	efeito_especial = dados.get("efeito_especial", "Nenhum")

	libera_demonio = dados.get("libera_demonio", raridade_grimorio == "Mítico" or efeito_especial.contains("Demônio"))
	raridade_grimorio = dados.get("raridade", "Comum")
	recursos_atualizados.emit()

## Realiza a Cerimônia de Aceitação da Torre de Grimórios (Gacha)
func realizar_cerimonia_aceitacao() -> Dictionary:
	var grimorio_sorteado = GrimorioData.rodar_gacha()
	aplicar_dados_grimorio(grimorio_sorteado)
	return grimorio_sorteado

## Evolui o grimório atual aumentando o multiplicador de mana
func equipar_grimorio(novo_tipo: GrimoireData.TipoGrimorio) -> void:
	match novo_tipo:
		GrimoireData.TipoGrimorio.TREVO_3_FOLHAS:
			aplicar_dados_grimorio(GrimorioData.GRIMORIOS["trevo_3_comum"])
		GrimoireData.TipoGrimorio.TREVO_4_FOLHAS:
			aplicar_dados_grimorio(GrimorioData.GRIMORIOS["trevo_4_lendario"])
		GrimoireData.TipoGrimorio.TREVO_5_FOLHAS:
			aplicar_dados_grimorio(GrimorioData.GRIMORIOS["trevo_5_mitico"])

## Recalcula os status globais integrando o bônus permanente de Anti-Magia, Ranks e Esquadrão
func atualizar_multiplicadores_globais() -> void:
	var esquadrao_manager = get_node_or_null("EsquadraoManager")
	if not esquadrao_manager and get_tree():
		esquadrao_manager = get_tree().get_first_node_in_group("esquadrao_manager")
	if not esquadrao_manager:
		esquadrao_manager = get_node_or_null("../EsquadraoManager")
	if esquadrao_manager:
		dps_esquadrao_passivo = esquadrao_manager.dps_total_aliados

	var rank_manager = get_node_or_null("RankManager")
	if not rank_manager and get_tree():
		rank_manager = get_tree().get_first_node_in_group("rank_manager")
	if not rank_manager:
		rank_manager = get_node_or_null("../RankManager")
	if rank_manager:
		var dados_rank = rank_manager.get_rank_atual()
		mult_dano_rank = dados_rank.get("mult_dano", 1.0)
		mult_ouro_rank = dados_rank.get("mult_ouro", 1.0)
		
	var contrato = get_node_or_null("ContratoDemonio")
	if not contrato and get_tree():
		contrato = get_tree().get_first_node_in_group("contrato_demonio")
	if not contrato:
		contrato = get_node_or_null("../ContratoDemonio")
	if contrato:
		mult_anti_magia_definitivo = contrato.bonus_anti_magia
		
	recursos_atualizados.emit()


## Alias para compatibilidade
func actualizar_multiplicadores_globais() -> void:
	atualizar_multiplicadores_globais()





