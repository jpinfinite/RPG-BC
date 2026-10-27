extends Node
class_name InimigoData

const INIMIGOS = {
	"javali_mana": {
		"nome": "Javali de Mana Selvagem",
		"vida_base": 50.0,
		"ouro_base": 10.0,
		"poeira_base": 5.0,
		"tipo": "Comum",
		"sprite_path": "res://assets/sprites/enemy_javali_mana.svg"
	},
	"mago_rebelde": {
		"nome": "Mago Rebelde de Diamond",
		"vida_base": 120.0,
		"ouro_base": 25.0,
		"poeira_base": 15.0,
		"tipo": "Comum",
		"sprite_path": "res://assets/sprites/enemy_mago_rebelde.svg"
	},
	"vetto": {
		"nome": "Vetto, o Desespero (Chefe)",
		"vida_base": 1000.0,
		"ouro_base": 200.0,
		"poeira_base": 100.0,
		"tipo": "Chefe",
		"sprite_path": "res://assets/sprites/enemy_vetto.svg"
	}
}

# Gera um inimigo escalado com base no andar atual
static func gerar_inimigo(andar: int) -> Dictionary:
	var dados_base: Dictionary
	
	# Boss a cada 10 andares
	if andar % 10 == 0:
		dados_base = INIMIGOS["vetto"].duplicate()
	else:
		dados_base = INIMIGOS["javali_mana"].duplicate() if randf() > 0.4 else INIMIGOS["mago_rebelde"].duplicate()
	
	# Escalonamento matemático de jogo Idle (vida cresce exponencialmente)
	dados_base["vida_max"] = dados_base["vida_base"] * pow(1.15, andar)
	dados_base["vida_atual"] = dados_base["vida_max"]
	dados_base["ouro_recompensa"] = dados_base["ouro_base"] * pow(1.12, andar)
	dados_base["poeira_recompensa"] = dados_base["poeira_base"] * pow(1.12, andar)
	
	return dados_base
