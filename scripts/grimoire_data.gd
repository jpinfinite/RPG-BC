extends Resource
class_name GrimoireData

enum TipoGrimorio {
	TREVO_3_FOLHAS,
	TREVO_4_FOLHAS,
	TREVO_5_FOLHAS
}

@export var tipo: TipoGrimorio = TipoGrimorio.TREVO_3_FOLHAS
@export var nome: String = "Trevo de 3 Folhas"
@export var multiplicador_mana: float = 1.0
@export var custo_poeira_desbloqueio: float = 0.0
@export var icone: Texture2D
@export_multiline var descricao: String = ""
