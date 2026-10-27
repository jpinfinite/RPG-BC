extends Node
## Fonte única da verdade para recursos, inimigo, recompensas e progresso.
signal recursos_atualizados
signal inimigo_atualizado(dados: Dictionary)
signal inimigo_derrotado(dados: Dictionary)

var ouro: float = 0.0
var poeira_mana: float = 0.0
var andar_atual: int = 1
var inimigo_atual: Dictionary = {}
var tipo_grimorio: String = "Trevo de 3 Folhas (Comum)"
var multiplicador_mana: float = 1.0
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
var invocacao_inicial_disponivel: bool = true
const CUSTO_INVOCACAO_OURO: float = 5000.0

func _ready() -> void:
	if inimigo_atual.is_empty():
		gerar_novo_inimigo()

func gerar_novo_inimigo() -> void:
	inimigo_atual = InimigoData.gerar_inimigo(maxi(1, andar_atual))
	inimigo_atualizado.emit(inimigo_atual.duplicate(true))

func _on_idle_tick() -> void:
	# Mantido como compatibilidade; o combate real é executado apenas pelo CombatManager.
	pass

func get_dano_efetivo() -> float:
	return maxf(0.0, (dano_por_segundo + dps_esquadrao_passivo) * mult_dano * mult_anti_magia_definitivo * mult_dano_rank)

func atacar_por_clique() -> Dictionary:
	var dano := get_dano_efetivo() * 0.5
	var critico := randf() < clampf(chance_critico_atual, 0.0, 1.0)
	if critico:
		dano *= 2.0
	aplicar_dano_no_inimigo(dano)
	return {"dano": dano, "critico": critico}

func aplicar_dano_no_inimigo(dano: float) -> void:
	if inimigo_atual.is_empty():
		gerar_novo_inimigo()
		return
	if dano <= 0.0:
		return
	inimigo_atual["vida_atual"] = maxf(0.0, float(inimigo_atual.get("vida_atual", 0.0)) - dano)
	inimigo_atualizado.emit(inimigo_atual.duplicate(true))
	if float(inimigo_atual["vida_atual"]) <= 0.0:
		_ao_derrotar_inimigo()

func _ao_derrotar_inimigo() -> void:
	if inimigo_atual.is_empty():
		return
	var derrotado := inimigo_atual.duplicate(true)
	var ouro_base := float(derrotado.get("ouro_recompensa", 10.0))
	var ganho_ouro := ouro_base * mult_ouro * mult_ouro_rank * multiplicador_ouro_global
	ouro += ganho_ouro
	poeira_mana += float(derrotado.get("poeira_recompensa", 5.0))
	inimigo_derrotado.emit(derrotado)
	_registrar_missao(derrotado, ganho_ouro)
	# Cada inimigo derrotado avança um andar; o chefe aparece nos andares múltiplos de 10.
	andar_atual += 1
	atualizar_multiplicadores_globais()
	var rank_mgr := get_tree().get_first_node_in_group("rank_manager") if get_tree() else null
	if rank_mgr and rank_mgr.has_method("verificar_promocao"):
		rank_mgr.verificar_promocao()
	gerar_novo_inimigo()
	recursos_atualizados.emit()

func _registrar_missao(derrotado: Dictionary, ganho_ouro: float) -> void:
	if not get_tree():
		return
	var missao_mgr = get_tree().get_first_node_in_group("missao_manager")
	if missao_mgr and missao_mgr.has_method("registrar_progresso"):
		missao_mgr.registrar_progresso(0, 1)
		missao_mgr.registrar_progresso(1, int(ganho_ouro))

func aplicar_dados_grimorio(dados: Dictionary) -> void:
	tipo_grimorio = str(dados.get("nome", tipo_grimorio))
	mult_dano = maxf(0.1, float(dados.get("mult_dano", dados.get("multiplicador_mana", 1.0))))
	multiplicador_mana = mult_dano
	mult_ouro = maxf(0.1, float(dados.get("mult_ouro", 1.0)))
	bonus_critico = clampf(float(dados.get("chance_critico", dados.get("bonus_critico", 0.05))), 0.0, 1.0)
	chance_critico_atual = bonus_critico
	efeito_especial = str(dados.get("efeito_especial", "Nenhum"))
	raridade_grimorio = str(dados.get("raridade", "Comum"))
	libera_demonio = bool(dados.get("libera_demonio", raridade_grimorio == "Mítico" or efeito_especial.contains("Demônio")))
	recursos_atualizados.emit()

func realizar_cerimonia_aceitacao() -> Dictionary:
	# Uma cerimônia inicial gratuita; as seguintes custam ouro e não rebaixam o grimório equipado.
	if not invocacao_inicial_disponivel and ouro < CUSTO_INVOCACAO_OURO:
		return {"erro": "ouro_insuficiente", "custo": CUSTO_INVOCACAO_OURO}
	if invocacao_inicial_disponivel:
		invocacao_inicial_disponivel = false
	else:
		ouro -= CUSTO_INVOCACAO_OURO
	var sorteado := GrimorioData.rodar_gacha()
	var peso_raridade := {"Comum": 0, "Lendário": 1, "Mítico": 2}
	if int(peso_raridade.get(sorteado.get("raridade", "Comum"), 0)) >= int(peso_raridade.get(raridade_grimorio, 0)):
		aplicar_dados_grimorio(sorteado)
	else:
		sorteado = sorteado.duplicate(true)
		sorteado["equipado"] = false
		sorteado["mensagem"] = "Grimório inferior encontrado; seu grimório atual foi preservado."
	recursos_atualizados.emit()
	return sorteado

func equipar_grimorio(novo_tipo: GrimoireData.TipoGrimorio) -> void:
	match novo_tipo:
		GrimoireData.TipoGrimorio.TREVO_3_FOLHAS: aplicar_dados_grimorio(GrimorioData.GRIMORIOS["trevo_3_comum"])
		GrimoireData.TipoGrimorio.TREVO_4_FOLHAS: aplicar_dados_grimorio(GrimorioData.GRIMORIOS["trevo_4_lendario"])
		GrimoireData.TipoGrimorio.TREVO_5_FOLHAS: aplicar_dados_grimorio(GrimorioData.GRIMORIOS["trevo_5_mitico"])

func atualizar_multiplicadores_globais() -> void:
	if not get_tree(): return
	var squad = get_tree().get_first_node_in_group("esquadrao_manager")
	if squad: dps_esquadrao_passivo = float(squad.dps_total_aliados)
	var rank_mgr = get_tree().get_first_node_in_group("rank_manager")
	if rank_mgr:
		var dados_rank: Dictionary = rank_mgr.get_rank_atual()
		mult_dano_rank = float(dados_rank.get("mult_dano", 1.0))
		mult_ouro_rank = float(dados_rank.get("mult_ouro", 1.0))
	var contrato = get_tree().get_first_node_in_group("contrato_demonio")
	if contrato: mult_anti_magia_definitivo = float(contrato.bonus_anti_magia)
	recursos_atualizados.emit()

func actualizar_multiplicadores_globais() -> void:
	atualizar_multiplicadores_globais()
