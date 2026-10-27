extends Node
class_name SaveManager

signal save_realizado()
signal progresso_offline_recebido(horas: int, minutos: int, ouro_ganho: float)

const SAVE_PATH = "user://black_clover_idle_save.json"
const SAVE_VERSION = 2  # Incrementar ao mudar estrutura do save

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
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")

	var tree = get_tree()

	if not progresso_mago:
		if tree:
			progresso_mago = tree.get_first_node_in_group("mago_progressao") as MagoProgressao
		if not progresso_mago:
			progresso_mago = get_node_or_null("../MagoProgressao") as MagoProgressao

	if not contrato_demonio:
		if tree:
			contrato_demonio = tree.get_first_node_in_group("contrato_demonio") as ContratoDemonio
		if not contrato_demonio:
			contrato_demonio = get_node_or_null("../ContratoDemonio") as ContratoDemonio

	if not rank_manager:
		if tree:
			rank_manager = tree.get_first_node_in_group("rank_manager") as RankManager
		if not rank_manager:
			rank_manager = get_node_or_null("../RankManager") as RankManager

	if not esquadrao_manager:
		if tree:
			esquadrao_manager = tree.get_first_node_in_group("esquadrao_manager") as EsquadraoManager
		if not esquadrao_manager:
			esquadrao_manager = get_node_or_null("../EsquadraoManager") as EsquadraoManager

	if not spell_cooldown_manager:
		if tree:
			spell_cooldown_manager = tree.get_first_node_in_group("spell_cooldown_manager") as SpellCooldownManager
		if not spell_cooldown_manager:
			spell_cooldown_manager = get_node_or_null("../SpellCooldownManager") as SpellCooldownManager

	if not missao_manager:
		if tree:
			missao_manager = tree.get_first_node_in_group("missao_manager") as MissaoManager
		if not missao_manager:
			missao_manager = get_node_or_null("../MissaoManager") as MissaoManager


# ─────────────────────────────────────────────────────────
# SAVE
# ─────────────────────────────────────────────────────────
func salvar_jogo() -> void:
	_resolver_referencias()
	if not game_manager or not progresso_mago or not contrato_demonio:
		push_warning("SaveManager: nós essenciais não encontrados ao salvar.")
		return

	var nivel_mago: int = progresso_mago.nivel_mago if progresso_mago else 1

	var dados_save: Dictionary = {
		"save_version": SAVE_VERSION,
		# Recursos
		"ouro": game_manager.ouro,
		"poeira_mana": game_manager.poeira_mana,
		"andar_atual": game_manager.andar_atual,
		# Grimório
		"tipo_grimorio": game_manager.tipo_grimorio,
		"raridade_grimorio": game_manager.raridade_grimorio,
		"multiplicador_mana": game_manager.multiplicador_mana,
		"mult_dano": game_manager.mult_dano,
		"mult_ouro": game_manager.mult_ouro,
		"chance_critico": game_manager.chance_critico_atual,
		"efeito_especial": game_manager.efeito_especial,
		# Mago (DPS explícito para restauração correta)
		"nivel_mago": nivel_mago,
		"dano_por_segundo": game_manager.dano_por_segundo,
		# Contrato / Prestígio
		"moedas_submundo": contrato_demonio.moedas_submundo,
		"bonus_anti_magia": contrato_demonio.bonus_anti_magia,
		# Rank
		"rank_index": rank_manager.rank_index_atual if rank_manager else 0,
		# Esquadrão
		"niveis_aliados": esquadrao_manager.niveis_aliados if esquadrao_manager else {"magna": 0, "noelle": 0, "yuno": 0},
		# Magias
		"magias_desbloqueadas": spell_cooldown_manager.magias_desbloqueadas if spell_cooldown_manager else {},
		# Missões
		"medalhas_merito": missao_manager.medalhas_merito if missao_manager else 0,
		"missao_ativa": missao_manager.missao_ativa if missao_manager else {},
		# Timestamp para cálculo offline
		"ultimo_timestamp": Time.get_unix_time_from_system()
	}

	var json_string: String = JSON.stringify(dados_save, "\t")
	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(json_string)
		arquivo.close()
		save_realizado.emit()
	else:
		push_warning("SaveManager: não foi possível abrir arquivo para escrita.")


# ─────────────────────────────────────────────────────────
# LOAD
# ─────────────────────────────────────────────────────────
func carregar_jogo() -> void:
	_resolver_referencias()
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var arquivo = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not arquivo:
		return

	var json_string: String = arquivo.get_as_text()
	arquivo.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_warning("SaveManager: save corrompido, iniciando novo jogo.")
		return

	var d = json.get_data()
	if not d is Dictionary:
		push_warning("SaveManager: formato de save inválido.")
		return

	# ── GameManager ──
	if game_manager:
		game_manager.ouro = _safe_float(d, "ouro", 0.0)
		game_manager.poeira_mana = _safe_float(d, "poeira_mana", 0.0)
		game_manager.andar_atual = _safe_int(d, "andar_atual", 1)
		game_manager.tipo_grimorio = d.get("tipo_grimorio", "Trevo de 3 Folhas (Comum)")
		game_manager.raridade_grimorio = d.get("raridade_grimorio", "Comum")
		game_manager.efeito_especial = d.get("efeito_especial", "Nenhum")
		game_manager.multiplicador_mana = _safe_float(d, "multiplicador_mana", 1.0)
		game_manager.mult_dano = _safe_float(d, "mult_dano", game_manager.multiplicador_mana)
		game_manager.mult_ouro = _safe_float(d, "mult_ouro", 1.0)
		game_manager.chance_critico_atual = _safe_float(d, "chance_critico", 0.05)
		game_manager.bonus_critico = game_manager.chance_critico_atual

		# DPS: usa o valor salvo diretamente (v2) ou recalcula pelo nível (migração v1)
		var dps_salvo: float = _safe_float(d, "dano_por_segundo", -1.0)
		if dps_salvo > 0.0:
			game_manager.dano_por_segundo = dps_salvo
		else:
			# Migração de save v1: recalcula DPS pelo nível
			var nivel_v1: int = _safe_int(d, "nivel_mago", 1)
			game_manager.recalcular_dps_por_nivel(nivel_v1)

	# ── Mago ──
	if progresso_mago:
		progresso_mago.nivel_mago = _safe_int(d, "nivel_mago", 1)

	# ── Contrato ──
	if contrato_demonio:
		contrato_demonio.moedas_submundo = _safe_int(d, "moedas_submundo", 0)
		contrato_demonio.bonus_anti_magia = _safe_float(d, "bonus_anti_magia", 1.0)

	# ── Rank ──
	if rank_manager:
		rank_manager.rank_index_atual = _safe_int(d, "rank_index", 0)
		rank_manager._aplicar_beneficios_rank()

	# ── Esquadrão ──
	if esquadrao_manager:
		esquadrao_manager.niveis_aliados = d.get("niveis_aliados", {"magna": 0, "noelle": 0, "yuno": 0})
		esquadrao_manager.recalcular_dps_esquadrao()

	# ── Magias ──
	if spell_cooldown_manager:
		spell_cooldown_manager.magias_desbloqueadas = d.get("magias_desbloqueadas", {"rugido_leao": false, "dragao_mar": false, "corte_dimensional": false})

	# ── Missões ──
	if missao_manager:
		missao_manager.medalhas_merito = _safe_int(d, "medalhas_merito", 0)
		var missao_salva = d.get("missao_ativa", {})
		if not missao_salva.is_empty():
			missao_manager.missao_ativa = missao_salva
		# Se missão_ativa vazia, MissaoManager._ready() já gerou nova

	# Sincroniza multiplicadores globais (precisa de todos os managers acima já restaurados)
	if game_manager:
		game_manager.atualizar_multiplicadores_globais()
		game_manager.recursos_atualizados.emit()

	# Cálculo de recompensa offline
	var ultimo_time: float = _safe_float(d, "ultimo_timestamp", Time.get_unix_time_from_system())
	_calcular_progresso_offline(ultimo_time)


# ─────────────────────────────────────────────────────────
# GANHO OFFLINE
# ─────────────────────────────────────────────────────────
var ouro_offline_pendente: float = 0.0

func coletar_ouro_offline() -> float:
	var coletado: float = ouro_offline_pendente
	if game_manager and coletado > 0.0:
		game_manager.ouro += coletado
		game_manager.recursos_atualizados.emit()
		ouro_offline_pendente = 0.0
		salvar_jogo()
	return coletado

func _calcular_progresso_offline(ultimo_timestamp: float) -> void:
	if not game_manager:
		return

	var timestamp_atual: float = Time.get_unix_time_from_system()
	var segundos_offline: float = timestamp_atual - ultimo_timestamp

	if segundos_offline <= 60.0:
		return  # Menos de 1 minuto — sem recompensa

	# Cap de 12 horas para balanceamento
	segundos_offline = minf(segundos_offline, 43200.0)

	# DPS efetivo considera esquadrão + rank
	var dps_efetivo: float = (game_manager.dano_por_segundo + game_manager.dps_esquadrao_passivo) * game_manager.multiplicador_mana * game_manager.mult_anti_magia_definitivo * game_manager.mult_dano_rank
	# Taxa de ouro por segundo (igual ao combate real)
	var ouro_por_segundo: float = (dps_efetivo * game_manager.mult_ouro * game_manager.mult_ouro_rank) * (1.0 + (game_manager.andar_atual * 0.1))
	var total_ouro: float = ouro_por_segundo * segundos_offline * game_manager.multiplicador_ouro_global

	# Garante valor não negativo
	total_ouro = maxf(0.0, total_ouro)
	ouro_offline_pendente = total_ouro

	var horas: int = int(segundos_offline) / 3600
	var minutos: int = (int(segundos_offline) % 3600) / 60
	progresso_offline_recebido.emit(horas, minutos, total_ouro)


# ─────────────────────────────────────────────────────────
# HELPERS de leitura segura
# ─────────────────────────────────────────────────────────
func _safe_float(d: Dictionary, key: String, fallback: float) -> float:
	var v = d.get(key, null)
	if v == null:
		return fallback
	if v is float or v is int:
		return float(v)
	return fallback

func _safe_int(d: Dictionary, key: String, fallback: int) -> int:
	var v = d.get(key, null)
	if v == null:
		return fallback
	if v is int or v is float:
		return int(v)
	return fallback
