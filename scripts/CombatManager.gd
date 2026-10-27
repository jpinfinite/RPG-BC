extends Node
class_name CombatManager

## Sinais de Combate
signal combate_iniciado(inimigo: Dictionary)
signal dano_causado(dano: float, critico: bool, vida_restante: float)
signal combate_vencido(inimigo: Dictionary)
signal andar_avancou(novo_andar: int)

# Carrega a cena do efeito de corte na memória
var cena_corte = preload("res://CorteEfeito.tscn")

# Referência ao GameManager (singleton via autoload)
var gm: Node

var inimigo_atual: Dictionary = {}
var timer_ataque: Timer

# Guarda referências de managers para evitar busca repetida no process
var _rank_manager: RankManager = null
var _missao_manager: MissaoManager = null
var _spell_manager: SpellCooldownManager = null

func _ready() -> void:
	gm = get_node_or_null("/root/GameManager")
	if not gm:
		push_error("CombatManager: GameManager não encontrado!")
		return

	# Configura o loop de ataque automático (Mago ataca a cada 1 segundo)
	timer_ataque = Timer.new()
	timer_ataque.wait_time = 1.0
	timer_ataque.autostart = true
	timer_ataque.timeout.connect(_on_mago_atacar)
	add_child(timer_ataque)

	# Spawna o primeiro inimigo
	iniciar_novo_combate()

func _resolver_managers() -> void:
	if not _rank_manager:
		_rank_manager = get_tree().get_first_node_in_group("rank_manager") as RankManager
	if not _missao_manager:
		_missao_manager = get_tree().get_first_node_in_group("missao_manager") as MissaoManager
	if not _spell_manager:
		_spell_manager = get_tree().get_first_node_in_group("spell_cooldown_manager") as SpellCooldownManager

func iniciar_novo_combate() -> void:
	if not gm:
		return
	inimigo_atual = InimigoData.gerar_inimigo(gm.andar_atual)
	# Sincroniza com GameManager para compatibilidade de UI e Save
	gm.inimigo_atual = inimigo_atual
	combate_iniciado.emit(inimigo_atual)

func _on_mago_atacar() -> void:
	if not gm or inimigo_atual.is_empty():
		return

	# Calcula DPS: (Base + Esquadrão) * Grimório * Anti-Magia * Rank
	var dps_base_total: float = gm.dano_por_segundo + gm.dps_esquadrao_passivo
	var dano: float = dps_base_total * gm.multiplicador_mana * gm.mult_anti_magia_definitivo * gm.mult_dano_rank
	var critico: bool = false

	# Chance de Crítico
	if randf() <= gm.chance_critico_atual:
		dano *= 2.0
		critico = true
		disparar_efeito_corte(Vector2(540, 180), "Anti-Magia")

	_aplicar_dano(dano, critico)

## Aplica dano direto por clique do jogador (50% do DPS efetivo)
func atacar_por_clique() -> Dictionary:
	if not gm or inimigo_atual.is_empty():
		return {}
	var dps_base_total: float = gm.dano_por_segundo + gm.dps_esquadrao_passivo
	var dano: float = (dps_base_total * gm.multiplicador_mana * gm.mult_anti_magia_definitivo * gm.mult_dano_rank) * 0.5
	var critico: bool = randf() < gm.bonus_critico
	if critico:
		dano *= 2.0
	_aplicar_dano(dano, critico)
	return {"dano": dano, "critico": critico}

## Aplica dano de uma magia (chamado pelo SpellCooldownManager)
## Retorna true se o inimigo morreu
func aplicar_dano_magia(dano: float, elemento: String) -> bool:
	if inimigo_atual.is_empty():
		return false
	_aplicar_dano(dano, true)
	disparar_efeito_corte(Vector2(540, 180), elemento)
	return inimigo_atual.is_empty()  # Será vazio se morreu em _aplicar_dano

func _aplicar_dano(dano: float, critico: bool) -> void:
	if inimigo_atual.is_empty():
		return
	inimigo_atual["vida_atual"] = maxf(0.0, inimigo_atual["vida_atual"] - dano)
	gm.inimigo_atual = inimigo_atual  # Mantém GM sincronizado
	var vida_clamped: float = clampf(inimigo_atual["vida_atual"], 0.0, inimigo_atual.get("vida_max", 1.0))
	dano_causado.emit(dano, critico, vida_clamped)

	if inimigo_atual["vida_atual"] <= 0.0:
		_ao_derrotar_inimigo()

func _ao_derrotar_inimigo() -> void:
	_resolver_managers()
	var inimigo_morto = inimigo_atual.duplicate()
	combate_vencido.emit(inimigo_morto)

	# Entrega recompensas
	var mult_global: float = gm.multiplicador_ouro_global
	var ouro_ganho: float = inimigo_morto.get("ouro_recompensa", 10.0) * gm.mult_ouro * gm.mult_ouro_rank * mult_global
	gm.ouro += ouro_ganho
	gm.poeira_mana += inimigo_morto.get("poeira_recompensa", 5.0)
	gm.recursos_atualizados.emit()

	# Avança andar (inimigos comuns E chefes avançam)
	gm.andar_atual += 1
	andar_avancou.emit(gm.andar_atual)

	# Verifica promoção de Rank
	if _rank_manager:
		_rank_manager.verificar_promocao()

	# Registra progresso de missões
	if _missao_manager:
		_missao_manager.registrar_progresso(0, 1)  # DERROTAR_INIMIGOS
		_missao_manager.registrar_progresso(1, int(ouro_ganho))  # ACUMULAR_OURO

	# Limpa inimigo atual e spawna o próximo
	inimigo_atual = {}
	gm.inimigo_atual = {}
	iniciar_novo_combate()

## Instancia e dispara o efeito de corte na tela
func disparar_efeito_corte(posicao_alvo: Vector2 = Vector2(540, 180), elemento: String = "Anti-Magia") -> void:
	if not cena_corte or not get_tree() or not get_tree().current_scene:
		return
	var novo_corte = cena_corte.instantiate()
	get_tree().current_scene.add_child(novo_corte)
	novo_corte.disparar_efeito(posicao_alvo, elemento)
