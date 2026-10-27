extends Node
class_name MissaoData

enum TipoMissao { DERROTAR_INIMIGOS, ACUMULAR_OURO, UPAR_MAGO }

const MISSOES_BASE = {
	"superar_limites": {
		"descricao": "Supere seus limites! Derrote monstros nas Zonas de Magia.",
		"tipo": TipoMissao.DERROTAR_INIMIGOS,
		"alvo_base": 50,
		"recompensa_medalhas": 5
	},
	"capitalismo_clover": {
		"descricao": "Financie o esquadrão: Acumule ouro de combate.",
		"tipo": TipoMissao.ACUMULAR_OURO,
		"alvo_base": 1000,
		"recompensa_medalhas": 3
	},
	"treinamento_pesado": {
		"descricao": "Evolua seu poder de mana: Suba o nível do seu Mago.",
		"tipo": TipoMissao.UPAR_MAGO,
		"alvo_base": 5,
		"recompensa_medalhas": 6
	}
}

# Gera uma missão escalada com base no andar atual do jogador
static func gerar_missao_diaria(id_missao: String, andar_atual: int) -> Dictionary:
	if not MISSOES_BASE.has(id_missao): return {}
	
	var missao = MISSOES_BASE[id_missao].duplicate()
	# Escala o alvo numericamente para que a missão não fique fácil demais em andares altos
	if missao["tipo"] == TipoMissao.ACUMULAR_OURO:
		missao["alvo"] = missao["alvo_base"] * pow(1.25, andar_atual)
	else:
		missao["alvo"] = missao["alvo_base"] + int(andar_atual * 0.5)
		
	missao["progresso_atual"] = 0
	missao["completada"] = false
	return missao
