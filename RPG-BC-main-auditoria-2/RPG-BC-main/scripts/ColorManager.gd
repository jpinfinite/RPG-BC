extends Node
class_name ColorManager

## Ajusta os parâmetros do AntiMagiaShader dinamicamente de acordo com o elemento
static func aplicar_elemento_shader(material: ShaderMaterial, elemento: String) -> void:
	if not material:
		return

	match elemento:
		"Fogo":
			# Laranja brilhante no contorno e amarelo no núcleo
			material.set_shader_parameter("cor_contorno", Color(1.0, 0.45, 0.05, 1.0))
			material.set_shader_parameter("cor_nucleo", Color(1.0, 0.92, 0.2, 1.0))
			material.set_shader_parameter("velocidade_pulso", 5.0)
			material.set_shader_parameter("intensidade_brilho", 2.2)
			
		"Luz":
			# Dourado e branco puro com intensidade máxima
			material.set_shader_parameter("cor_contorno", Color(1.0, 0.85, 0.25, 1.0))
			material.set_shader_parameter("cor_nucleo", Color(1.0, 1.0, 1.0, 1.0))
			material.set_shader_parameter("velocidade_pulso", 6.0)
			material.set_shader_parameter("intensidade_brilho", 4.0)
			
		"Água":
			# Azul ciano cintilante e azul marinho profundo
			material.set_shader_parameter("cor_contorno", Color(0.1, 0.65, 1.0, 1.0))
			material.set_shader_parameter("cor_nucleo", Color(0.0, 0.15, 0.4, 1.0))
			material.set_shader_parameter("velocidade_pulso", 3.5)
			material.set_shader_parameter("intensidade_brilho", 1.8)
			
		"Vento":
			# Verde esmeralda brilhante
			material.set_shader_parameter("cor_contorno", Color(0.2, 0.95, 0.5, 1.0))
			material.set_shader_parameter("cor_nucleo", Color(0.05, 0.25, 0.1, 1.0))
			material.set_shader_parameter("velocidade_pulso", 4.5)
			material.set_shader_parameter("intensidade_brilho", 2.0)
			
		_: # "Anti-Magia" ou "Escuridão" (padrão)
			# Vermelho carmesim demoníaco e preto absoluto
			material.set_shader_parameter("cor_contorno", Color(0.75, 0.02, 0.12, 1.0))
			material.set_shader_parameter("cor_nucleo", Color(0.01, 0.0, 0.02, 1.0))
			material.set_shader_parameter("velocidade_pulso", 4.0)
			material.set_shader_parameter("intensidade_brilho", 1.8)
