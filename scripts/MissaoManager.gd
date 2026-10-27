extends Node
class_name MissaoManager

signal missao_atualizada

@export var game_manager: Node

var missao_ativa: Dictionary = {}
var medalhas_merito: int = 0

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
	var chaves = MissaoData.MISSOES_BASE.keys()
	var chave_aleatoria = chaves[randi() % chaves.size()]
	missao_ativa = MissaoData.gerar_missao_diaria(chave_aleatoria, andar)
	missao_atualizada.emit()
	print("Nova missão do Yami: ", missao_ativa["descricao"], " (Alvo: ", missao_ativa["alvo"], ")")

# Função pública para outros scripts injetarem progresso
func registrar_progresso(tipo: int, quantidade: int) -> void:
	if missao_ativa.is_empty() or missao_ativa.get("completada", false):
		return
	
	if missao_ativa["tipo"] == tipo:
		missao_ativa["progresso_atual"] += quantidade
		
		# Verifica se a missão foi cumprida
		if missao_ativa["progresso_atual"] >= missao_ativa["alvo"]:
			missao_ativa["progresso_atual"] = missao_ativa["alvo"]
			missao_ativa["completada"] = true
			_recompensar_jogador()
			
		missao_atualizada.emit()

func _recompensar_jogador() -> void:
	medalhas_merito += missao_ativa["recompensa_medalhas"]
	print("Missão concluída! Yami te deu ", missao_ativa["recompensa_medalhas"], " Medalhas de Mérito.")
	
	# Aguarda alguns segundos e gera a próxima missão automaticamente (fluxo Idle)
	await get_tree().create_timer(3.0).timeout
	_gerar_nova_missao_diaria()
