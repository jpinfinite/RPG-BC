extends Node
class_name GrimorioData

# Estrutura do Banco de Dados de Grimórios
const GRIMORIOS = {
	"trevo_3_comum": {
		"nome": "Grimório de 3 Folhas (Comum)",
		"raridade": "Comum",
		"chance_drop": 0.80,
		"mult_dano": 1.0,
		"mult_ouro": 1.0,
		"chance_critico": 0.05,
		"efeito_especial": "Nenhum",
		"cor_aura": "77ff77", # Verde Claro
		"sprite_path": "res://assets/sprites/grimorio_3_folhas.svg"
	},
	"trevo_4_lendario": {
		"nome": "Grimório de 4 Folhas (Lendário)",
		"raridade": "Lendário",
		"chance_drop": 0.18,
		"mult_dano": 3.0,
		"mult_ouro": 2.5,
		"chance_critico": 0.25,
		"efeito_especial": "Magia Escolhida pelo Destino (+Velocidade)",
		"cor_aura": "ffdd44", # Dourado Brilhante
		"sprite_path": "res://assets/sprites/grimorio_4_folhas.svg"
	},
	"trevo_5_mitico": {
		"nome": "Grimório do Desespero de 5 Folhas",
		"raridade": "Mítico",
		"chance_drop": 0.02,
		"mult_dano": 10.0,
		"mult_ouro": 5.0,
		"chance_critico": 0.50,
		"efeito_especial": "Anti-Magia / Contrato de Demônio Ativo",
		"cor_aura": "990022", # Vermelho Carmesim Sombrio
		"sprite_path": "res://assets/sprites/grimorio_5_folhas.svg"
	}
}


# Função do Gacha (Cerimônia de Escolha do Grimório)
static func rodar_gacha() -> Dictionary:
	var r = randf() # Gera um número aleatório entre 0.0 e 1.0
	
	if r <= GRIMORIOS["trevo_5_mitico"]["chance_drop"]:
		return GRIMORIOS["trevo_5_mitico"]
	elif r <= (GRIMORIOS["trevo_5_mitico"]["chance_drop"] + GRIMORIOS["trevo_4_lendario"]["chance_drop"]):
		return GRIMORIOS["trevo_4_lendario"]
	else:
		return GRIMORIOS["trevo_3_comum"]

# Alias de compatibilidade
static func sortear_grimorio() -> Dictionary:
	return rodar_gacha()
