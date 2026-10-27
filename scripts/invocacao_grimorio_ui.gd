extends Control
class_name InvocacaoGrimorioUI

signal grimorio_invocado(dados: Dictionary)

@onready var btn_invocar: Button = %BtnInvocar
@onready var btn_fechar: Button = %BtnFechar
@onready var lbl_nome: Label = %LblNome
@onready var lbl_raridade: Label = %LblRaridade
@onready var lbl_atributos: Label = %LblAtributos
@onready var particulas_aura: GPUParticles2D = %ParticulasAura
@onready var icone_grimorio: TextureRect = %IconeGrimorio

# Custo base da Cerimônia de Aceitação (em Poeira de Mana)
const CUSTO_INVOCACAO: float = 100.0

# Gradiente para o Grimório do Desespero (5 Folhas)
var gradiente_demonio: Gradient

# Proteção contra duplo clique
var _invocando: bool = false

func _ready() -> void:
	btn_invocar.pressed.connect(_on_btn_invocar_pressed)
	if btn_fechar:
		btn_fechar.pressed.connect(fechar_cerimonia)
	_configurar_gradiente_demonio()
	_resetar_interface()
	
	# Atualiza botão ao receber recursos
	if GameManager:
		GameManager.recursos_atualizados.connect(_atualizar_botao)
	_atualizar_botao()

func abrir_cerimonia() -> void:
	visible = true
	_resetar_interface()
	_atualizar_botao()
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func fechar_cerimonia() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false)

func _atualizar_botao() -> void:
	if not btn_invocar:
		return
	var tem_recurso: bool = GameManager and GameManager.poeira_mana >= CUSTO_INVOCACAO
	btn_invocar.disabled = not tem_recurso or _invocando
	btn_invocar.text = "Invocar Grimório (%d ✨)" % int(CUSTO_INVOCACAO)

func _configurar_gradiente_demonio() -> void:
	gradiente_demonio = Gradient.new()
	gradiente_demonio.set_color(0, Color(0.9, 0.05, 0.15, 0.9))
	gradiente_demonio.add_point(0.4, Color(0.15, 0.0, 0.05, 0.85))
	gradiente_demonio.add_point(0.75, Color(0.02, 0.02, 0.02, 0.7))
	gradiente_demonio.set_color(1, Color(0.0, 0.0, 0.0, 0.0))

func _resetar_interface() -> void:
	lbl_nome.text = "Torre de Grimórios"
	lbl_raridade.text = "Aguardando Cerimônia..."
	lbl_raridade.modulate = Color.WHITE
	lbl_atributos.text = "Custo: %d Poeira de Mana para invocar." % int(CUSTO_INVOCACAO)
	icone_grimorio.texture = load(GrimorioData.GRIMORIOS["trevo_3_comum"]["sprite_path"])
	particulas_aura.emitting = false

func _on_btn_invocar_pressed() -> void:
	if _invocando:
		return
	if not GameManager or GameManager.poeira_mana < CUSTO_INVOCACAO:
		_animar_custo_insuficiente()
		return

	# Desconta o recurso
	GameManager.poeira_mana -= CUSTO_INVOCACAO
	GameManager.recursos_atualizados.emit()

	_invocando = true
	btn_invocar.disabled = true

	# Executa o sorteio e aplica ao GameManager
	var grimorio_sorteado: Dictionary = GrimorioData.rodar_gacha()
	GameManager.aplicar_dados_grimorio(grimorio_sorteado)

	# Exibe resultado e efeitos
	_exibir_resultado(grimorio_sorteado)
	aplicar_efeito_particulas(grimorio_sorteado)
	grimorio_invocado.emit(grimorio_sorteado)

	# Libera o botão após a animação (0.5s)
	await get_tree().create_timer(0.5).timeout
	_invocando = false
	_atualizar_botao()

func _exibir_resultado(dados: Dictionary) -> void:
	lbl_nome.text = dados.get("nome", "Grimório Desconhecido")
	var raridade: String = dados.get("raridade", "Comum")
	lbl_raridade.text = "Raridade: " + raridade

	var mult_dano: float = dados.get("mult_dano", dados.get("multiplicador_mana", 1.0))
	var mult_ouro: float = dados.get("mult_ouro", 1.0)
	var critico: float = dados.get("chance_critico", dados.get("bonus_critico", 0.05)) * 100.0
	var efeito: String = dados.get("efeito_especial", "Nenhum")

	lbl_atributos.text = "Dano: %.1fx  |  Ouro: %.1fx  |  Crítico: %.0f%%\nEfeito: %s" % [
		mult_dano, mult_ouro, critico, efeito
	]

	# Sprite do grimório
	var sprite_path: String = dados.get("sprite_path", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		icone_grimorio.texture = load(sprite_path)

	# Cores por raridade
	match raridade:
		"Comum":
			lbl_raridade.modulate = Color(0.3, 0.9, 0.3)
		"Lendário":
			lbl_raridade.modulate = Color(1.0, 0.85, 0.1)
		"Mítico":
			lbl_raridade.modulate = Color(1.0, 0.2, 0.3)
		_:
			lbl_raridade.modulate = Color.WHITE

	# Animação de revelação
	icone_grimorio.scale = Vector2(0.5, 0.5)
	lbl_nome.scale = Vector2(1.2, 1.2)
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icone_grimorio, "scale", Vector2.ONE, 0.35)
	tween.tween_property(lbl_nome, "scale", Vector2.ONE, 0.25)

func aplicar_efeito_particulas(dados: Dictionary) -> void:
	var mat = particulas_aura.process_material as ParticleProcessMaterial
	if not mat:
		mat = ParticleProcessMaterial.new()
		particulas_aura.process_material = mat

	var libera_demonio: bool = dados.get("raridade", "") == "Mítico" or String(dados.get("efeito_especial", "")).contains("Demônio")

	if libera_demonio:
		var grad_texture = GradientTexture1D.new()
		grad_texture.gradient = gradiente_demonio
		mat.color_ramp = grad_texture
		mat.color = Color.WHITE
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 45.0
		mat.initial_velocity_min = 60.0
		mat.initial_velocity_max = 140.0
		mat.gravity = Vector3(0, -25, 0)
		mat.scale_min = 4.0
		mat.scale_max = 8.5
		particulas_aura.amount = 48
		particulas_aura.lifetime = 1.4
	else:
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

func _animar_custo_insuficiente() -> void:
	var tween = create_tween()
	tween.tween_property(btn_invocar, "modulate", Color(2.0, 0.3, 0.3, 1.0), 0.1)
	tween.tween_property(btn_invocar, "modulate", Color.WHITE, 0.3)

## Converte strings de cor para objeto Color nativo
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
