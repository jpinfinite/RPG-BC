extends Control
class_name InvocacaoGrimorioUI

@onready var btn_invocar: Button = %BtnInvocar
@onready var lbl_nome: Label = %LblNome
@onready var lbl_raridade: Label = %LblRaridade
@onready var lbl_atributos: Label = %LblAtributos
@onready var particulas_aura: GPUParticles2D = %ParticulasAura
@onready var icone_grimorio: TextureRect = %IconeGrimorio

# Gradiente padrão para o Grimório do Desespero (5 Folhas: Fumaça Negra e Vermelha)
var gradiente_demonio: Gradient

func _ready() -> void:
	btn_invocar.pressed.connect(_on_btn_invocar_pressed)
	_configurar_gradiente_demonio()
	_resetar_interface()

func _configurar_gradiente_demonio() -> void:
	gradiente_demonio = Gradient.new()
	# Inicia em vermelho carmesim vibrante, transita para preto carvão (fumaça negra) e dissipa com alfa 0
	gradiente_demonio.set_color(0, Color(0.9, 0.05, 0.15, 0.9)) # Vermelho carmesim
	gradiente_demonio.add_point(0.4, Color(0.15, 0.0, 0.05, 0.85)) # Vermelho muito escuro
	gradiente_demonio.add_point(0.75, Color(0.02, 0.02, 0.02, 0.7)) # Fumaça negra
	gradiente_demonio.set_color(1, Color(0.0, 0.0, 0.0, 0.0)) # Dissipação total

func _resetar_interface() -> void:
	lbl_nome.text = "Torre de Grimórios"
	lbl_raridade.text = "Aguardando Cerimônia..."
	lbl_raridade.modulate = Color.WHITE
	lbl_atributos.text = "Clique em 'Invocar Grimório' para receber seu trevo."
	icone_grimorio.texture = load(GrimorioData.GRIMORIOS["trevo_3_comum"]["sprite_path"])
	particulas_aura.emitting = false

func _on_btn_invocar_pressed() -> void:
	if not GameManager:
		return
	var grimorio_sorteado: Dictionary = GameManager.realizar_cerimonia_aceitacao()
	if grimorio_sorteado.has("erro"):
		lbl_raridade.text = "Ouro insuficiente"
		lbl_atributos.text = "A cerimônia custa %s de ouro. Sua primeira invocação é gratuita." % _formatar_numero(float(grimorio_sorteado.get("custo", 0.0)))
		return
	_exibir_resultado(grimorio_sorteado)
	if grimorio_sorteado.get("equipado", true):
		aplicar_efeito_particulas(grimorio_sorteado)
	else:
		lbl_atributos.text += "\nNão equipado: seu grimório atual é superior."

func _exibir_resultado(dados: Dictionary) -> void:
	lbl_nome.text = dados.get("nome", "Grimório Desconhecido")
	var raridade = dados.get("raridade", "Comum")
	lbl_raridade.text = "Raridade: " + raridade
	
	var mult_dano = dados.get("mult_dano", dados.get("multiplicador_mana", 1.0))
	var mult_ouro = dados.get("mult_ouro", 1.0)
	var critico = dados.get("chance_critico", dados.get("bonus_critico", 0.05)) * 100.0
	var efeito = dados.get("efeito_especial", "Nenhum")
	
	lbl_atributos.text = "Multiplicador de Dano: %.1fx\nBônus de Ouro: %.1fx | Crítico: %.0f%%\nEfeito Especial: %s" % [
		mult_dano, mult_ouro, critico, efeito
	]

	# Atualiza o sprite do livro
	var sprite_path = dados.get("sprite_path", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		icone_grimorio.texture = load(sprite_path)
	
	# Cores visuais para o texto de raridade
	match raridade:
		"Comum":
			lbl_raridade.modulate = Color(0.3, 0.9, 0.3) # Verde
		"Lendário":
			lbl_raridade.modulate = Color(1.0, 0.85, 0.1) # Dourado
		"Mítico":
			lbl_raridade.modulate = Color(1.0, 0.2, 0.3) # Carmesim
		_:
			lbl_raridade.modulate = Color.WHITE

	# Micro-animação visual de revelação (escala e rotação no sprite e texto)
	icone_grimorio.scale = Vector2(0.5, 0.5)
	lbl_nome.scale = Vector2(1.2, 1.2)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icone_grimorio, "scale", Vector2.ONE, 0.35)
	tween.tween_property(lbl_nome, "scale", Vector2.ONE, 0.25)


## Configura e ativa o GPUParticles2D baseado nos dados do grimório
func aplicar_efeito_particulas(dados: Dictionary) -> void:
	var mat = particulas_aura.process_material as ParticleProcessMaterial
	if not mat:
		mat = ParticleProcessMaterial.new()
		particulas_aura.process_material = mat

	var libera_demonio = dados.get("libera_demonio", false) or dados.get("raridade") == "Mítico" or String(dados.get("efeito_especial", "")).contains("Demônio")
	
	if libera_demonio:
		# Grimório de 5 Folhas: Fumaça Negra e Vermelha

		var grad_texture = GradientTexture1D.new()
		grad_texture.gradient = gradiente_demonio
		mat.color_ramp = grad_texture
		mat.color = Color.WHITE # Permite que o gradiente controle as cores
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 45.0
		mat.initial_velocity_min = 60.0
		mat.initial_velocity_max = 140.0
		mat.gravity = Vector3(0, -25, 0) # Fumaça subindo
		mat.scale_min = 4.0
		mat.scale_max = 8.5
		particulas_aura.amount = 48
		particulas_aura.lifetime = 1.4
	else:
		# Grimórios de 3 ou 4 folhas: Aura mágica elemental
		mat.color_ramp = null
		mat.color = _parsear_cor(dados.get("cor_aura", "Color(1, 1, 1)"))
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 180.0
		mat.initial_velocity_min = 20.0
		mat.initial_velocity_max = 70.0
		mat.gravity = Vector3(0, -10, 0)
		mat.scale_min = 2.0
		mat.scale_max = 4.5
		particulas_aura.amount = 28
		particulas_aura.lifetime = 1.0

	particulas_aura.restart()
	particulas_aura.emitting = true

## Converte strings como "Color(0.2, 0.8, 0.2)" para objeto Color nativo
func _parsear_cor(cor_str: Variant) -> Color:
	if cor_str is Color:
		return cor_str
	if cor_str is String:
		var var_eval = str_to_var(cor_str)
		if var_eval is Color:
			return var_eval
		if Color.html_is_valid(cor_str):
			return Color.html(cor_str)
	return Color.WHITE

func _formatar_numero(valor: float) -> String:
	if valor >= 1000000000.0: return "%.2fB" % (valor / 1000000000.0)
	if valor >= 1000000.0: return "%.2fM" % (valor / 1000000.0)
	if valor >= 1000.0: return "%.1fK" % (valor / 1000.0)
	return str(int(valor))
