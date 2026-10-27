extends Node
class_name ContratoDemonio

signal contrato_executado(moedas_ganhas: int)
signal poder_demoniaco_comprado(novo_bonus: float)

@export var game_manager: Node
@export var progresso_mago: MagoProgressao

# Moeda permanente de Prestígio
var moedas_submundo: int = 0

# Multiplicador permanente comprado na loja do submundo
var bonus_anti_magia: float = 1.0 # 1.0 = +0%, 2.0 = +100% de dano global

func _ready() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	if not progresso_mago and get_tree():
		progresso_mago = get_tree().get_first_node_in_group("mago_progressao") as MagoProgressao

# Calcula os ganhos antes de resetar
func calcular_moedas_ganhas() -> int:
	if not game_manager or game_manager.andar_atual < 50:
		return 0 # O contrato só fica disponível a partir do andar 50
	
	var nivel = progresso_mago.nivel_mago if progresso_mago else 1
	# Fórmula clássica Idle: ganho baseado no andar alcançado e nível do mago
	var moedas = (game_manager.andar_atual - 40) * 2 + (nivel / 5)
	return int(moedas)

# Executa o ritual de reset (Prestígio)
func realizar_contrato_proibido() -> bool:
	var moedas_a_receber = calcular_moedas_ganhas()
	
	if moedas_a_receber <= 0:
		print("Você ainda não acumulou desespero suficiente. Alcance o Andar 50+!")
		return false
		
	# 1. Entrega a recompensa permanente
	moedas_submundo += moedas_a_receber
	
	# 2. Reseta o progresso temporário do jogador
	game_manager.ouro = 0.0
	game_manager.poeira_mana = 0.0
	game_manager.andar_atual = 1
	
	if progresso_mago:
		progresso_mago.nivel_mago = 1
	game_manager.dano_por_segundo = 10.0 # Progressão temporária volta ao início.
	# O prestígio reseta o esquadrão e as magias compradas; mantém grimório e bônus demoníaco permanente.
	var esquadrao = get_tree().get_first_node_in_group("esquadrao_manager") if get_tree() else null
	if esquadrao and esquadrao.get("niveis_aliados") is Dictionary:
		for id_aliado in esquadrao.niveis_aliados.keys():
			esquadrao.niveis_aliados[id_aliado] = 0
		esquadrao.recalcular_dps_esquadrao()
	var magias = get_tree().get_first_node_in_group("spell_cooldown_manager") if get_tree() else null
	if magias and magias.get("magias_desbloqueadas") is Dictionary:
		for id_magia in magias.magias_desbloqueadas.keys():
			magias.magias_desbloqueadas[id_magia] = false
			magias.cooldowns_atuais[id_magia] = 0.0
	var rank_mgr = get_tree().get_first_node_in_group("rank_manager") if get_tree() else null
	if rank_mgr:
		rank_mgr.rank_index_atual = 0
		rank_mgr._aplicar_beneficios_rank()
	var missao_mgr = get_tree().get_first_node_in_group("missao_manager") if get_tree() else null
	if missao_mgr:
		missao_mgr.trocar_missao()
	
	# 3. Cria um inimigo de nível 1 após reiniciar a progressão temporária.
	game_manager.atualizar_multiplicadores_globais()
	game_manager.gerar_novo_inimigo()
	game_manager.recursos_atualizados.emit()
	contrato_executado.emit(moedas_a_receber)
	print("Contrato realizado! Você recebeu ", moedas_a_receber, " moedas do submundo. O mundo foi resetado.")
	return true

# Compra upgrade permanente com as moedas ganhas
func comprar_poder_demoniaco() -> bool:
	var custo = 10 * bonus_anti_magia
	if game_manager and moedas_submundo >= custo:
		moedas_submundo -= int(custo)
		bonus_anti_magia += 1.0 # Adiciona +100% de dano global definitivo
		
		# Atualiza o multiplicador global do GameManager
		game_manager.atualizar_multiplicadores_globais()
		poder_demoniaco_comprado.emit(bonus_anti_magia)
		print("Poder de Anti-Magia aumentado! Novo bônus: +", (bonus_anti_magia - 1) * 100, "% de dano.")
		return true
	
	print("Moedas do Submundo insuficientes. Custo: ", custo)
	return false
