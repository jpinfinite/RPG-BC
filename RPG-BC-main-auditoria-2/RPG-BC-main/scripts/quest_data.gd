extends Resource
class_name QuestData

enum TipoMissao {
	DERROTAR_INIMIGOS,
	COLETAR_OURO,
	ALCANCAR_ANDAR,
	EVOLUIR_HEROI
}

@export var id: String = ""
@export var titulo: String = ""
@export_multiline var descricao: String = ""
@export var fala_npc: String = "Supere seus limites agora mesmo!"
@export var tipo: TipoMissao = TipoMissao.ALCANCAR_ANDAR
@export var objetivo_quantidade: int = 10
@export var progresso_atual: int = 0
@export var recompensa_ouro: float = 500.0
@export var recompensa_poeira_mana: float = 50.0
@export var completada: bool = false
@export var resgatada: bool = false
