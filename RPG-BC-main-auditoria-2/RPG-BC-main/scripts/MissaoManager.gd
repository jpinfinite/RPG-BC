extends Node
class_name MissaoManager

signal missao_atualizada

@export var game_manager: Node

var missao_ativa: Dictionary = {}
var medalhas_merito: int = 0
var _geracao_missao: int = 0

func _ready() -> void:
	_resolver_referencias()
	if missao_ativa.is_empty():
		_gerar_nova_missao_diaria()

func _resolver_referencias() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

func _gerar_nova_missao_diaria() -> void:
	_resolver_referencias()
	var andar = 1
	if game_manager:
		andar = game_manager.andar_atual
		
	# Escolhe uma missão aleatória do banco de dados
	var chaves: Array = MissaoData.MISSOES_BASE.keys()
	if chaves.is_empty():
		missao_ativa = {}
		return
	var chave_aleatoria = chaves[randi() % chaves.size()]
	missao_ativa = MissaoData.gerar_missao_diaria(chave_aleatoria, andar)
	_geracao_missao += 1
	missao_atualizada.emit()
	print("Nova missão do Yami: ", missao_ativa["descricao"], " (Alvo: ", missao_ativa["alvo"], ")")

# Função pública para outros scripts injetarem progresso
func registrar_progresso(tipo: int, quantidade: int) -> void:
	if missao_ativa.is_empty() or missao_ativa.get("completada", false):
		return
	
	if int(missao_ativa.get("tipo", -1)) == tipo and quantidade > 0:
		missao_ativa["progresso_atual"] = int(missao_ativa.get("progresso_atual", 0)) + quantidade
		
		# Verifica se a missão foi cumprida
		if missao_ativa["progresso_atual"] >= missao_ativa["alvo"]:
			missao_ativa["progresso_atual"] = missao_ativa["alvo"]
			missao_ativa["completada"] = true
			_recompensar_jogador()
			
		missao_atualizada.emit()

func _recompensar_jogador() -> void:
	var recompensa := int(missao_ativa.get("recompensa_medalhas", 0))
	medalhas_merito += recompensa
	var geracao_concluida := _geracao_missao
	print("Missão concluída! Yami te deu ", recompensa, " Medalhas de Mérito.")
	# A missão seguinte só é gerada se o jogador ainda estiver na missão que foi concluída.
	await get_tree().create_timer(3.0).timeout
	if geracao_concluida == _geracao_missao and bool(missao_ativa.get("completada", false)):
		_gerar_nova_missao_diaria()


## Permite trocar uma missão bloqueada ou indesejada sem ficar preso a ela.
func trocar_missao() -> bool:
	if missao_ativa.is_empty():
		_gerar_nova_missao_diaria()
		return true
	var chaves: Array = MissaoData.MISSOES_BASE.keys()
	if chaves.size() <= 1:
		return false
	var atual_tipo = missao_ativa.get("tipo", -1)
	var candidatas: Array = []
	for chave in chaves:
		if MissaoData.MISSOES_BASE[chave].get("tipo", -2) != atual_tipo:
			candidatas.append(chave)
	if candidatas.is_empty():
		return false
	var andar = int(game_manager.andar_atual) if game_manager else 1
	missao_ativa = MissaoData.gerar_missao_diaria(candidatas[randi() % candidatas.size()], andar)
	_geracao_missao += 1
	missao_atualizada.emit()
	return true
