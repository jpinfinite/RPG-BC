extends Sprite2D
class_name CorteEfeito

func _ready() -> void:
	# Cria um efeito de escala (o corte cresce e some rapidamente)
	scale = Vector2(0.2, 0.2)
	modulate.a = 1.0
	
	# Animação simples via código (Tween) compatível com Godot 4
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_LINEAR)
	
	# Quando a animação terminar, apaga o efeito da tela
	tween.chain().tween_callback(queue_free)

# Configura a posição do corte exatamente em cima do inimigo e aplica o elemento no shader
func disparar_efeito(posicao_alvo: Vector2, elemento: String = "Anti-Magia") -> void:
	global_position = posicao_alvo
	# Rotaciona levemente de forma aleatória para cada corte parecer único
	rotation_degrees = randf_range(-35.0, 35.0)
	
	# Configura cores dinâmicas via ColorManager se houver ShaderMaterial
	if material is ShaderMaterial:
		material = material.duplicate() # Duplica para instâncias simultâneas terem elementos distintos
		ColorManager.aplicar_elemento_shader(material as ShaderMaterial, elemento)
