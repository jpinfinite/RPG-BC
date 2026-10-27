extends Node
class_name MagiaData

const SPELLS = {
	"rugido_leao": {
		"nome": "Magia de Fogo: Rugido do Leão",
		"elemento": "Fogo",
		"mult_dano": 5.0, # Causa 5x o dano atual por segundo em área
		"cooldown": 12.0, # Segundos para recarregar
		"custo_desbloqueio": 500.0,
		"cor_aura": "ff5522"
	},
	"dragao_mar": {
		"nome": "Magia de Água: Rugido do Dragão do Mar",
		"elemento": "Água",
		"mult_dano": 12.0, # Causa 12x o dano atual por segundo
		"cooldown": 25.0,
		"custo_desbloqueio": 2500.0,
		"cor_aura": "22aaff"
	},
	"corte_dimensional": {
		"nome": "Magia de Escuridão: Corte Dimensional",
		"elemento": "Escuridão",
		"mult_dano": 35.0, # Golpe massivo de execução de chefes
		"cooldown": 60.0,
		"custo_desbloqueio": 15000.0,
		"cor_aura": "8811bb"
	}
}
