extends Node
class_name SpellCooldownManager

signal magia_conjurada(id_magia: String)
signal magia_desbloqueada(id_magia: String)

@export var game_manager: Node
@export var combat_manager: CombatManager

# Dicionário rastreando quais magias foram compradas (false = bloqueada, true = ativa)
var magias_desbloqueadas: Dictionary = {
	"rugido_leao": false,
	"dragao_mar": false,
	"corte_dimensional": false
}

# Dicionário mantendo o tempo atual de recarga restante de cada uma
var cooldowns_atuais: Dictionary = {
	"rugido_leao": 0.0,
	"dragao_mar": 0.0,
	"corte_dimensional": 0.0
}

func _ready() -> void:
	_resolver_referencias()

func _resolver_referencias() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	if not combat_manager and get_tree():
		combat_manager = get_tree().get_first_node_in_group("combat_manager") as CombatManager
		if not combat_manager:
			combat_manager = get_node_or_null("../CombatManager") as CombatManager

func _process(delta: float) -> void:
	for id_magia in magias_desbloqueadas.keys():
		if not magias_desbloqueadas[id_magia]: 
			continue # Pula se a magia ainda não foi comprada
			
		if cooldowns_atuais[id_magia] > 0.0:
			cooldowns_atuais[id_magia] -= delta
		else:
			# Cooldown zerou! Dispara o feitiço automaticamente
			_conjurar_magia_automatica(id_magia)

func _conjurar_magia_automatica(id_magia: String) -> void:
	if not MagiaData.SPELLS.has(id_magia):
		return
	if not game_manager:
		_resolver_referencias()
		if not game_manager:
			return

	var dados_magia = MagiaData.SPELLS[id_magia]
	
	# Reseta o cooldown para o padrão da tabela
	cooldowns_atuais[id_magia] = dados_magia["cooldown"]
	
	# Calcula o golpe usando o dano atualizado do jogador com todos os modificadores
	var dps_base = game_manager.dano_por_segundo + game_manager.get("dps_esquadrao_passivo")
	var mult_anti = game_manager.get("mult_anti_magia_definitivo")
	if mult_anti == null: mult_anti = 1.0
	var mult_rank = game_manager.get("mult_dano_rank")
	if mult_rank == null: mult_rank = 1.0
	
	var dano_base = dps_base * game_manager.multiplicador_mana * mult_anti * mult_rank
	var dano_burst = dano_base * dados_magia["mult_dano"]
	
	# Aplica o golpe no inimigo que estiver na tela através do CombatManager
	if not combat_manager:
		_resolver_referencias()
		
	if combat_manager and not combat_manager.inimigo_atual.is_empty():
		combat_manager.inimigo_atual["vida_atual"] -= dano_burst
		var vida_clamped = clampf(combat_manager.inimigo_atual["vida_atual"], 0.0, combat_manager.inimigo_atual["vida_max"])
		combat_manager.dano_causado.emit(dano_burst, true, vida_clamped)
		print("¡AUTO-CAST! ", dados_magia["nome"], " causou ", int(dano_burst), " de dano mágico em área!")
		
		# Dispara o efeito visual do corte com o elemento da magia usando o AntiMagiaShader e ColorManager
		combat_manager.disparar_efeito_corte(Vector2(540, 180), dados_magia.get("elemento", "Anti-Magia"))
		
		# Verifica se o monstro faleceu devido ao feitiço
		if combat_manager.inimigo_atual["vida_atual"] <= 0:
			combat_manager._on_inimigo_derrotado()
			
	magia_conjurada.emit(id_magia)

# Função para comprar novas magias usando Poeira de Mana
func desbloquear_magia(id_magia: String) -> bool:
	if not magias_desbloqueadas.has(id_magia) or magias_desbloqueadas[id_magia]:
		return false # Já comprada ou ID inválido
	if not game_manager:
		_resolver_referencias()
		if not game_manager:
			return false
		
	var custo = MagiaData.SPELLS[id_magia]["custo_desbloqueio"]
	if game_manager.poeira_mana >= custo:
		game_manager.poeira_mana -= custo
		magias_desbloqueadas[id_magia] = true
		cooldowns_atuais[id_magia] = randf_range(1.0, 4.0) # Escalona o primeiro tiro para não disparar tudo junto
		game_manager.recursos_atualizados.emit()
		magia_desbloqueada.emit(id_magia)
		print("Nova técnica desbloqueada: ", MagiaData.SPELLS[id_magia]["nome"])
		return true
		
	print("Poeira de Mana insuficiente para transcrever este pergaminho.")
	return false
