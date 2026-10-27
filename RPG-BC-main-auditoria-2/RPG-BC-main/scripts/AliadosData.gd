extends Node
class_name AliadosData

const ALIADOS = {
	"magna": {
		"nome": "Magna Swing",
		"esquadrao": "Touros Negros",
		"custo_base": 150.0,
		"dano_base_por_nivel": 8.0,
		"elemento": "Fogo"
	},
	"noelle": {
		"nome": "Noelle Silva",
		"esquadrao": "Touros Negros",
		"custo_base": 800.0,
		"dano_base_por_nivel": 45.0,
		"elemento": "Água"
	},
	"yuno": {
		"nome": "Yuno Grinberryall",
		"esquadrao": "Alvorecer Dourado",
		"custo_base": 5000.0,
		"dano_base_por_nivel": 320.0,
		"elemento": "Vento"
	}
}

# Retorna o custo atualizado de um aliado com base no nível dele
static func get_custo_aliado(id_aliado: String, nivel_atual: int) -> float:
	if not ALIADOS.has(id_aliado): return 0.0
	return ALIADOS[id_aliado]["custo_base"] * pow(1.22, nivel_atual)

# Retorna o dano total que o aliado fornece com base no nível dele
static func get_dano_aliado(id_aliado: String, nivel_atual: int) -> float:
	if not ALIADOS.has(id_aliado) or nivel_atual == 0: return 0.0
	return ALIADOS[id_aliado]["dano_base_por_nivel"] * nivel_atual
