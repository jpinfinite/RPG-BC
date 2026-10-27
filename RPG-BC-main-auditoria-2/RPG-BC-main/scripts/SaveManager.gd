extends Node
class_name SaveManager

signal save_realizado()
signal progresso_offline_recebido(horas: int, minutos: int, ouro_ganho: float)

const SAVE_PATH = "user://black_clover_idle_save.json"

@export var game_manager: Node
@export var progresso_mago: MagoProgressao
@export var contrato_demonio: ContratoDemonio
@export var rank_manager: RankManager
@export var esquadrao_manager: EsquadraoManager
@export var spell_cooldown_manager: SpellCooldownManager
@export var missao_manager: MissaoManager

func _ready() -> void:
	_resolver_referencias()

func _resolver_referencias() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		
	if not progresso_mago and get_tree():
		progresso_mago = get_tree().get_first_node_in_group("mago_progressao") as MagoProgressao
		if not progresso_mago:
			progresso_mago = get_node_or_null("../MagoProgressao") as MagoProgressao
			
	if not contrato_demonio and get_tree():
		contrato_demonio = get_tree().get_first_node_in_group("contrato_demonio") as ContratoDemonio
		if not contrato_demonio:
			contrato_demonio = get_node_or_null("../ContratoDemonio") as ContratoDemonio

	if not rank_manager and get_tree():
		rank_manager = get_tree().get_first_node_in_group("rank_manager") as RankManager
		if not rank_manager:
			rank_manager = get_node_or_null("../RankManager") as RankManager

	if not esquadrao_manager and get_tree():
		esquadrao_manager = get_tree().get_first_node_in_group("esquadrao_manager") as EsquadraoManager
		if not esquadrao_manager:
			esquadrao_manager = get_node_or_null("../EsquadraoManager") as EsquadraoManager

	if not spell_cooldown_manager and get_tree():
		spell_cooldown_manager = get_tree().get_first_node_in_group("spell_cooldown_manager") as SpellCooldownManager
		if not spell_cooldown_manager:
			spell_cooldown_manager = get_node_or_null("../SpellCooldownManager") as SpellCooldownManager

	if not missao_manager and get_tree():
		missao_manager = get_tree().get_first_node_in_group("missao_manager") as MissaoManager
		if not missao_manager:
			missao_manager = get_node_or_null("../MissaoManager") as MissaoManager




# Salva o progresso atual do jogo
func salvar_jogo() -> void:
	_resolver_referencias()
	if not game_manager:
		push_warning("SaveManager: GameManager indisponível; save cancelado.")
		return

	var dados_save = {
		"ouro": game_manager.ouro,
		"poeira_mana": game_manager.poeira_mana,
		"andar_atual": game_manager.andar_atual,
		"tipo_grimorio": game_manager.tipo_grimorio,
		"multiplicador_mana": game_manager.multiplicador_mana,
		"mult_dano": game_manager.mult_dano,
		"dano_por_segundo": game_manager.dano_por_segundo,
		"chance_critico_atual": game_manager.chance_critico_atual,
		"raridade_grimorio": game_manager.raridade_grimorio,
		"efeito_especial": game_manager.efeito_especial,
		"libera_demonio": game_manager.libera_demonio,
		"invocacao_inicial_disponivel": game_manager.invocacao_inicial_disponivel,
		"grimorios_obtidos": game_manager.grimorios_obtidos,
		"mult_ouro": game_manager.mult_ouro,
		"chance_critico": game_manager.chance_critico_atual,
		"nivel_mago": progresso_mago.nivel_mago if progresso_mago else 1,
		"moedas_submundo": contrato_demonio.moedas_submundo if contrato_demonio else 0,
		"bonus_anti_magia": contrato_demonio.bonus_anti_magia if contrato_demonio else 1.0,
		"rank_index": rank_manager.rank_index_atual if rank_manager else 0,
		"niveis_aliados": esquadrao_manager.niveis_aliados if esquadrao_manager else {"magna": 0, "noelle": 0, "yuno": 0},
		"magias_desbloqueadas": spell_cooldown_manager.magias_desbloqueadas if spell_cooldown_manager else {"rugido_leao": false, "dragao_mar": false, "corte_dimensional": false},
		"medalhas_merito": missao_manager.medalhas_merito if missao_manager else 0,
		"save_version": 2,
		"ultimo_timestamp": Time.get_unix_time_from_system() # Salva a hora exata em segundos
	}
	
	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if arquivo:
		var json_string = JSON.stringify(dados_save, "\t")
		arquivo.store_string(json_string)
		arquivo.close()
		save_realizado.emit()
		print("Jogo salvo automaticamente!")

# Carrega o progresso e calcula as recompensas offline
func carregar_jogo() -> void:
	_resolver_referencias()
	if not FileAccess.file_exists(SAVE_PATH):
		print("Nenhum save encontrado. Iniciando nova jornada no Reino de Clover!")
		return
		
	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if arquivo:
		var json_string = arquivo.get_as_text()
		arquivo.close()
		
		var json = JSON.new()
		var erro = json.parse(json_string)
		if erro == OK and json.get_data() is Dictionary:
			var dados_save: Dictionary = json.get_data()
			
			# Restaurando os dados do GameManager
			if game_manager:
				game_manager.ouro = dados_save.get("ouro", 0.0)
				game_manager.poeira_mana = dados_save.get("poeira_mana", 0.0)
				game_manager.andar_atual = maxi(1, int(dados_save.get("andar_atual", 1)))
				game_manager.tipo_grimorio = dados_save.get("tipo_grimorio", "Trevo de 3 Folhas (Comum)")
				game_manager.multiplicador_mana = dados_save.get("multiplicador_mana", 1.0)
				game_manager.mult_dano = dados_save.get("mult_dano", game_manager.multiplicador_mana)
				game_manager.dano_por_segundo = maxf(10.0, float(dados_save.get("dano_por_segundo", _dano_para_nivel(int(dados_save.get("nivel_mago", 1))))))
				game_manager.raridade_grimorio = str(dados_save.get("raridade_grimorio", "Comum"))
				game_manager.efeito_especial = str(dados_save.get("efeito_especial", "Nenhum"))
				game_manager.libera_demonio = bool(dados_save.get("libera_demonio", false))
				game_manager.invocacao_inicial_disponivel = bool(dados_save.get("invocacao_inicial_disponivel", true))
				var grimorios_save: Variant = dados_save.get("grimorios_obtidos", [game_manager.raridade_grimorio])
				if grimorios_save is Array:
					game_manager.grimorios_obtidos.clear()
					for raridade in grimorios_save:
						if str(raridade) in ["Comum", "Lendário", "Mítico"] and not game_manager.grimorios_obtidos.has(str(raridade)):
							game_manager.grimorios_obtidos.append(str(raridade))
				if game_manager.grimorios_obtidos.is_empty():
					game_manager.grimorios_obtidos.append("Comum")
				game_manager.mult_ouro = dados_save.get("mult_ouro", 1.0)
				game_manager.chance_critico_atual = float(dados_save.get("chance_critico_atual", dados_save.get("chance_critico", 0.05)))
				game_manager.bonus_critico = game_manager.chance_critico_atual
			
			# Restaurando Progresso do Mago, Contrato, Rank, Esquadrão, Magias e Missões
			if progresso_mago:
				progresso_mago.nivel_mago = dados_save.get("nivel_mago", 1)
			if contrato_demonio:
				contrato_demonio.moedas_submundo = dados_save.get("moedas_submundo", 0)
				contrato_demonio.bonus_anti_magia = dados_save.get("bonus_anti_magia", 1.0)
			if rank_manager:
				rank_manager.rank_index_atual = clampi(int(dados_save.get("rank_index", 0)), 0, RankManager.RANKS.size() - 1)
				rank_manager._aplicar_beneficios_rank()
			if esquadrao_manager:
				var aliados_save: Variant = dados_save.get("niveis_aliados", {"magna": 0, "noelle": 0, "yuno": 0})
				if aliados_save is Dictionary:
					for id_aliado in esquadrao_manager.niveis_aliados.keys():
						esquadrao_manager.niveis_aliados[id_aliado] = maxi(0, int(aliados_save.get(id_aliado, 0)))
				esquadrao_manager.recalcular_dps_esquadrao()
			if spell_cooldown_manager:
				var magias_save: Variant = dados_save.get("magias_desbloqueadas", {})
				if magias_save is Dictionary:
					for id_magia in spell_cooldown_manager.magias_desbloqueadas.keys():
						spell_cooldown_manager.magias_desbloqueadas[id_magia] = bool(magias_save.get(id_magia, false))
			if missao_manager:
				missao_manager.medalhas_merito = maxi(0, int(dados_save.get("medalhas_merito", 0)))
			
			# Sincroniza multiplicadores internos
			if game_manager:
				game_manager.actualizar_multiplicadores_globais()
				game_manager.recursos_atualizados.emit()



			
			# CALCULO RECOMPENSA OFFLINE
			var ultimo_time = dados_save.get("ultimo_timestamp", Time.get_unix_time_from_system())
			_calcular_progresso_offline(ultimo_time)
		else:
			push_warning("Save inválido ou corrompido; o jogo iniciará com valores padrão.")

var ouro_offline_pendente: float = 0.0
var poeira_offline_pendente: float = 0.0

# Coleta o ouro acumulado offline
func coletar_ouro_offline() -> float:
	var coletado = ouro_offline_pendente
	if game_manager and (coletado > 0.0 or poeira_offline_pendente > 0.0):
		game_manager.ouro += coletado
		game_manager.poeira_mana += poeira_offline_pendente
		game_manager.recursos_atualizados.emit()
		ouro_offline_pendente = 0.0
		poeira_offline_pendente = 0.0
		salvar_jogo()
	return coletado

# Calcula o ganho do esquadrão enquanto o app estava fechado
func _calcular_progresso_offline(ultimo_timestamp: float) -> void:
	if not game_manager:
		return
	var timestamp_atual := Time.get_unix_time_from_system()
	var segundos_offline := maxf(0.0, timestamp_atual - float(ultimo_timestamp))
	if segundos_offline <= 60.0:
		return
	segundos_offline = minf(segundos_offline, 43200.0) # Limite de 12 horas.
	# Estima o ciclo real do combate: vida média dos inimigos comuns e um chefe a cada 10 andares.
	# A recompensa é reduzida para 25% para que o modo offline seja útil sem superar o jogo ativo.
	var dps := maxf(1.0, game_manager.get_dano_efetivo())
	var andar := maxi(1, game_manager.andar_atual)
	var fator_vida := pow(1.15, andar)
	var fator_recompensa := pow(1.12, andar)
	var hp_comum := 85.0 * fator_vida
	var ouro_comum := 17.5 * fator_recompensa
	var poeira_comum := 10.0 * fator_recompensa
	var hp_chefe := 1000.0 * fator_vida
	var ouro_chefe := 200.0 * fator_recompensa
	var poeira_chefe := 100.0 * fator_recompensa
	var tempo_ciclo := (hp_comum * 9.0 + hp_chefe) / dps
	var ouro_ciclo := ouro_comum * 9.0 + ouro_chefe
	var poeira_ciclo := poeira_comum * 9.0 + poeira_chefe
	var ciclos := segundos_offline / maxf(0.1, tempo_ciclo)
	var eficiencia := 0.25
	var bonus_ouro := game_manager.mult_ouro * game_manager.mult_ouro_rank * game_manager.multiplicador_ouro_global
	ouro_offline_pendente = maxf(0.0, ciclos * ouro_ciclo * bonus_ouro * eficiencia)
	poeira_offline_pendente = maxf(0.0, ciclos * poeira_ciclo * eficiencia)
	var horas := int(segundos_offline / 3600.0)
	var minutos := int(fmod(segundos_offline, 3600.0) / 60.0)
	progresso_offline_recebido.emit(horas, minutos, ouro_offline_pendente)
	print("Recompensa offline calculada: ", horas, "h ", minutos, "m; ouro pendente: ", int(ouro_offline_pendente))



func _dano_para_nivel(nivel: int) -> float:
	var dano := 10.0
	for nivel_novo in range(2, maxi(1, nivel) + 1):
		dano += 5.0 * (1.0 + (nivel_novo * 0.05))
	return dano
