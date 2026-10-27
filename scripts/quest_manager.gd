extends Node
class_name QuestManager

signal missao_atualizada(missao: QuestData)
signal missao_completada(missao: QuestData)

@export var missao_npc_nome: String = "Capitão Yami"
@export var missao_npc_retrato: Texture2D
@export var missoes: Array[QuestData] = []

func _ready() -> void:
	_inicializar_missoes_padrao()

func _inicializar_missoes_padrao() -> void:
	if missoes.is_empty():
		var m1 = QuestData.new()
		m1.id = "m1_andar_10"
		m1.titulo = "Teste dos Touros Negros"
		m1.fala_npc = "Se você não conseguir passar do andar 10, eu mesmo te mato. Supere seus limites!"
		m1.tipo = QuestData.TipoMissao.ALCANCAR_ANDAR
		m1.objetivo_quantidade = 10
		m1.recompensa_ouro = 1000.0
		m1.recompensa_poeira_mana = 100.0
		missoes.append(m1)

func verificar_progresso_andar(andar: int, game_manager: Node) -> void:
	for missao in missoes:
		if missao.tipo == QuestData.TipoMissao.ALCANCAR_ANDAR and not missao.completada:
			missao.progresso_atual = andar
			if missao.progresso_atual >= missao.objetivo_quantidade:
				missao.completada = true
				missao_completada.emit(missao)
			missao_atualizada.emit(missao)

func resgatar_recompensa(missao: QuestData, game_manager: Node) -> bool:
	if missao.completada and not missao.resgatada:
		missao.resgatada = true
		game_manager.ouro += missao.recompensa_ouro
		game_manager.poeira_mana += missao.recompensa_poeira_mana
		game_manager.recursos_atualizados.emit()
		missao_atualizada.emit(missao)
		return true
	return false
