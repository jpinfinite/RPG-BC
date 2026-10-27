extends Node
class_name CombatManager

## Sinais de Combate
signal combate_iniciado(inimigo: Dictionary)
signal dano_causado(dano: float, critico: bool, vida_restante: float)
signal combate_vencido(inimigo: Dictionary)

# Carrega a cena do efeito de corte na memória
var cena_corte = preload("res://CorteEfeito.tscn")

@export var game_manager: Node # Referência ao gerenciador de ouro/mana

var inimigo_atual: Dictionary
var timer_ataque: Timer

func _ready() -> void:
	# Fallback para o Singleton GameManager se não atribuído no Inspector
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	
	iniciar_novo_combate()
	
	# Configura o loop de ataque automático (Mago ataca a cada 1 segundo)
	timer_ataque = Timer.new()
	timer_ataque.wait_time = 1.0
	timer_ataque.autostart = true
	timer_ataque.timeout.connect(_on_mago_atacar)
	add_child(timer_ataque)

func iniciar_novo_combate() -> void:
	var andar = game_manager.andar_atual if game_manager else 1
	inimigo_atual = InimigoData.gerar_inimigo(andar)
	combate_iniciado.emit(inimigo_atual)
	print("Um novo ", inimigo_atual["nome"], " apareceu no Andar ", andar, "! Vida: ", int(inimigo_atual["vida_atual"]))

func _on_mago_atacar() -> void:
	if not game_manager or inimigo_atual.is_empty():
		return

	# Calcula o dano usando (Dano Base Mago + DPS Esquadrão) * Grimório * Anti-Magia * Rank
	var dps_esquadrao = game_manager.dps_esquadrao_passivo if "dps_esquadrao_passivo" in game_manager else 0.0
	var dps_base_total = game_manager.dano_por_segundo + dps_esquadrao
	var mult_anti = game_manager.mult_anti_magia_definitivo if "mult_anti_magia_definitivo" in game_manager else 1.0
	var mult_rank = game_manager.mult_dano_rank if "mult_dano_rank" in game_manager else 1.0
	var dano = dps_base_total * game_manager.multiplicador_mana * mult_anti * mult_rank
	var critico = false


	# Chance de Crítico baseada no Grimório
	var chance_crit = game_manager.get("chance_critico_atual")
	if chance_crit == null:
		chance_crit = game_manager.get("bonus_critico")
	if chance_crit != null and randf() <= chance_crit:
		dano *= 2.0
		critico = true
		print("¡CORTE CRÍTICO!")
		
		# Instancia o sprite de Anti-Magia com o shader
		disparar_efeito_corte(Vector2(540, 180), "Anti-Magia")

	inimigo_atual["vida_atual"] -= dano
	var vida_clamped = clampf(inimigo_atual["vida_atual"], 0.0, inimigo_atual["vida_max"])
	dano_causado.emit(dano, critico, vida_clamped)
	print("Você causou ", dano, " de dano. Vida do inimigo: ", int(vida_clamped))
	
	if inimigo_atual["vida_atual"] <= 0:
		_on_inimigo_derrotado()

func _on_inimigo_derrotado() -> void:
	print(inimigo_atual["nome"], " foi derrotado!")
	combate_vencido.emit(inimigo_atual)
	
	# Entrega as recompensas ao jogador com suporte ao multiplicador global da Charmy e Rank
	var mult_global = game_manager.multiplicador_ouro_global if "multiplicador_ouro_global" in game_manager else 1.0
	var mult_ouro_rank = game_manager.mult_ouro_rank if "mult_ouro_rank" in game_manager else 1.0
	game_manager.ouro += inimigo_atual["ouro_recompensa"] * mult_global * mult_ouro_rank
	game_manager.poeira_mana += inimigo_atual["poeira_recompensa"]
	game_manager.recursos_atualizados.emit()

	# Se for chefe, avança de andar de forma definitiva
	if inimigo_atual["tipo"] == "Chefe":
		game_manager.andar_atual += 1
		print("Parabéns! Você avançou para o Andar ", game_manager.andar_atual)
		
		# Verifica promoção de Rank de Cavaleiro Mágico
		var rank_manager = game_manager.get_node_or_null("RankManager")
		if not rank_manager and get_tree():
			rank_manager = get_tree().get_first_node_in_group("rank_manager")
		if rank_manager:
			rank_manager.verificar_promocao()
	
	# Atualiza o progresso das missões do Capitão Yami
	var missao_manager = game_manager.get_node_or_null("MissaoManager")
	if not missao_manager and get_tree():
		missao_manager = get_tree().get_first_node_in_group("missao_manager")
	if missao_manager:
		missao_manager.registrar_progresso(0, 1) # 0 = TipoMissao.DERROTAR_INIMIGOS
		missao_manager.registrar_progresso(1, int(inimigo_atual.get("ouro_recompensa", 0.0))) # 1 = TipoMissao.ACUMULAR_OURO

	# Spawna o próximo inimigo instantaneamente
	iniciar_novo_combate()

## Instancia e dispara o efeito de corte na tela com o shader e elemento configurados
func disparar_efeito_corte(posicao_alvo: Vector2 = Vector2(540, 180), elemento: String = "Anti-Magia") -> void:
	if not cena_corte or not get_tree() or not get_tree().current_scene:
		return
		
	var novo_corte = cena_corte.instantiate()
	get_tree().current_scene.add_child(novo_corte)
	novo_corte.disparar_efeito(posicao_alvo, elemento)


