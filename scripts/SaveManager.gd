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
	if not game_manager or not progresso_mago or not contrato_demonio:
		print("Aviso: Falha ao salvar jogo, nós essenciais não encontrados.")
		return

	var dados_save = {
		"ouro": game_manager.ouro,
		"poeira_mana": game_manager.poeira_mana,
		"andar_atual": game_manager.andar_atual,
		"tipo_grimorio": game_manager.tipo_grimorio,
		"multiplicador_mana": game_manager.multiplicador_mana,
		"mult_dano": game_manager.mult_dano,
		"mult_ouro": game_manager.mult_ouro,
		"chance_critico": game_manager.chance_critico_atual,
		"nivel_mago": progresso_mago.nivel_mago,
		"moedas_submundo": contrato_demonio.moedas_submundo,
		"bonus_anti_magia": contrato_demonio.bonus_anti_magia,
		"rank_index": rank_manager.rank_index_atual if rank_manager else 0,
		"niveis_aliados": esquadrao_manager.niveis_aliados if esquadrao_manager else {"magna": 0, "noelle": 0, "yuno": 0},
		"magias_desbloqueadas": spell_cooldown_manager.magias_desbloqueadas if spell_cooldown_manager else {"rugido_leao": false, "dragao_mar": false, "corte_dimensional": false},
		"medalhas_merito": missao_manager.medalhas_merito if missao_manager else 0,
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
		if erro == OK:
			var dados_save = json.get_data()
			
			# Restaurando os dados do GameManager
			if game_manager:
				game_manager.ouro = dados_save.get("ouro", 0.0)
				game_manager.poeira_mana = dados_save.get("poeira_mana", 0.0)
				game_manager.andar_atual = dados_save.get("andar_atual", 1)
				game_manager.tipo_grimorio = dados_save.get("tipo_grimorio", "Trevo de 3 Folhas (Comum)")
				game_manager.multiplicador_mana = dados_save.get("multiplicador_mana", 1.0)
				game_manager.mult_dano = dados_save.get("mult_dano", game_manager.multiplicador_mana)
				game_manager.mult_ouro = dados_save.get("mult_ouro", 1.0)
				game_manager.chance_critico_atual = dados_save.get("chance_critico", 0.05)
			
			# Restaurando Progresso do Mago, Contrato, Rank, Esquadrão, Magias e Missões
			if progresso_mago:
				progresso_mago.nivel_mago = dados_save.get("nivel_mago", 1)
			if contrato_demonio:
				contrato_demonio.moedas_submundo = dados_save.get("moedas_submundo", 0)
				contrato_demonio.bonus_anti_magia = dados_save.get("bonus_anti_magia", 1.0)
			if rank_manager:
				rank_manager.rank_index_atual = dados_save.get("rank_index", 0)
				rank_manager._aplicar_beneficios_rank()
			if esquadrao_manager:
				esquadrao_manager.niveis_aliados = dados_save.get("niveis_aliados", {"magna": 0, "noelle": 0, "yuno": 0})
				esquadrao_manager.recalcular_dps_esquadrao()
			if spell_cooldown_manager:
				spell_cooldown_manager.magias_desbloqueadas = dados_save.get("magias_desbloqueadas", {"rugido_leao": false, "dragao_mar": false, "corte_dimensional": false})
			if missao_manager:
				missao_manager.medalhas_merito = dados_save.get("medalhas_merito", 0)
			
			# Sincroniza multiplicadores internos
			if game_manager:
				game_manager.actualizar_multiplicadores_globais()
				game_manager.recursos_atualizados.emit()



			
			# CALCULO RECOMPENSA OFFLINE
			var ultimo_time = dados_save.get("ultimo_timestamp", Time.get_unix_time_from_system())
			_calcular_progresso_offline(ultimo_time)

var ouro_offline_pendente: float = 0.0

# Coleta o ouro acumulado offline
func coletar_ouro_offline() -> float:
	var coletado = ouro_offline_pendente
	if game_manager and coletado > 0.0:
		game_manager.ouro += coletado
		game_manager.recursos_atualizados.emit()
		ouro_offline_pendente = 0.0
		salvar_jogo()
	return coletado

# Calcula o ganho do esquadrão enquanto o app estava fechado
func _calcular_progresso_offline(ultimo_timestamp: float) -> void:
	if not game_manager:
		return

	var timestamp_atual = Time.get_unix_time_from_system()
	var segundos_offline = timestamp_atual - ultimo_timestamp
	
	if segundos_offline > 60: # Só dá recompensa se ficou fora por mais de 1 minuto
		# Limita o farm offline a no máximo 12 horas (43200 segundos) para balanceamento do jogo
		if segundos_offline > 43200:
			segundos_offline = 43200
			
		# Calcula o ganho por segundo baseado no andar e poder atual do mago
		var dps_efetivo = game_manager.dano_por_segundo * game_manager.multiplicador_mana * game_manager.mult_anti_magia_definitivo
		var ganho_ouro_por_segundo = (dps_efetivo * game_manager.mult_ouro) * (1.0 + (game_manager.andar_atual * 0.1))
		var total_ouro_ganho = ganho_ouro_por_segundo * segundos_offline * game_manager.multiplicador_ouro_global
		
		ouro_offline_pendente = total_ouro_ganho
		
		var horas = int(segundos_offline) / 3600
		var minutos = (int(segundos_offline) % 3600) / 60
		progresso_offline_recebido.emit(horas, minutos, total_ouro_ganho)
		print("Seu esquadrão treinou por ", horas, "h ", minutos, "m offline e coletou ", int(total_ouro_ganho), " de Ouro!")

