extends Node
class_name EsquadraoManager

signal esquadrao_atualizado

@export var game_manager: Node

# Dicionário que guarda o nível de cada aliado da conta (0 = não recrutado)
var niveis_aliados: Dictionary = {
	"magna": 0,
	"noelle": 0,
	"yuno": 0
}

# Guarda o dano total passivo gerado por todos os aliados juntos
var dps_total_aliados: float = 0.0

func _ready() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	recalcular_dps_esquadrao()

# Tenta recrutar ou subir o nível de um aliado
func upar_aliado(id_aliado: String) -> bool:
	if not niveis_aliados.has(id_aliado): return false
	if not game_manager: return false
	
	var nivel_atual = niveis_aliados[id_aliado]
	var custo = AliadosData.get_custo_aliado(id_aliado, nivel_atual)
	
	if game_manager.ouro >= custo:
		game_manager.ouro -= custo
		niveis_aliados[id_aliado] += 1
		
		recalcular_dps_esquadrao()
		esquadrao_atualizado.emit()
		print(AliadosData.ALIADOS[id_aliado]["nome"], " agora está no nível ", niveis_aliados[id_aliado])
		return true
		
	print("Ouro insuficiente para recrutar/upar ", AliadosData.ALIADOS[id_aliado]["nome"])
	return false

# Passa por todos os aliados somando o poder deles
func recalcular_dps_esquadrao() -> void:
	var soma_dano = 0.0
	for id in niveis_aliados.keys():
		var nivel = niveis_aliados[id]
		soma_dano += AliadosData.get_dano_aliado(id, nivel)
	
	dps_total_aliados = soma_dano
	
	# Injeta o dano de aliados na contagem global do GameManager se a função existir
	if game_manager:
		game_manager.actualizar_multiplicadores_globais()
		game_manager.recursos_atualizados.emit()
	esquadrao_atualizado.emit()
