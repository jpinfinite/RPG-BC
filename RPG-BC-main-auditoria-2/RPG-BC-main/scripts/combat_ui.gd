extends Control
class_name CombatUI

@export var combat_manager: CombatManager

@onready var lbl_nome_monstro: Label = %LblNomeMonstro
@onready var lbl_tipo_andar: Label = %LblTipoAndar
@onready var progress_vida: ProgressBar = %ProgressVida
@onready var lbl_vida_texto: Label = %LblVidaTexto
@onready var spawn_dano: Control = %SpawnDano

# Referências visuais dos personagens
@onready var hero_sprite: TextureRect = %HeroSprite
@onready var enemy_sprite: TextureRect = %EnemySprite
@onready var hero_container: Control = %HeroContainer
@onready var enemy_container: Control = %EnemyContainer

var pos_original_hero: Vector2 = Vector2.ZERO
var pos_original_enemy: Vector2 = Vector2.ZERO

func _ready() -> void:
	if hero_container:
		pos_original_hero = hero_container.position
	if enemy_container:
		pos_original_enemy = enemy_container.position
		
	_iniciar_idle_heroi()

	if not combat_manager:
		combat_manager = get_tree().get_first_node_in_group("combat_manager") as CombatManager
		if not combat_manager:
			combat_manager = get_node_or_null("../CombatManager") as CombatManager

	if combat_manager:
		combat_manager.combate_iniciado.connect(_on_combate_iniciado)
		combat_manager.dano_causado.connect(_on_dano_causado)
		combat_manager.combate_vencido.connect(_on_combate_vencido)
		
		if not combat_manager.inimigo_atual.is_empty():
			_on_combate_iniciado(combat_manager.inimigo_atual)

func _on_combate_iniciado(inimigo: Dictionary) -> void:
	lbl_nome_monstro.text = inimigo.get("nome", "Monstro Desconhecido")
	var tipo = inimigo.get("tipo", "Comum")
	var andar = 1
	if combat_manager and combat_manager.game_manager:
		andar = combat_manager.game_manager.andar_atual
	
	if tipo == "Chefe":
		lbl_tipo_andar.text = "👑 CHEFE • Andar %d" % andar
		lbl_tipo_andar.modulate = Color(1.0, 0.25, 0.35)
	else:
		lbl_tipo_andar.text = "Andar %d • [%s]" % [andar, tipo]
		lbl_tipo_andar.modulate = Color(0.65, 0.85, 1.0)
	
	var vida_max = inimigo.get("vida_max", 100.0)
	var vida_atual = inimigo.get("vida_atual", vida_max)
	
	progress_vida.max_value = vida_max
	progress_vida.value = vida_atual
	_atualizar_texto_vida(vida_atual, vida_max)

	# Atualiza o sprite do monstro
	_carregar_sprite_inimigo(inimigo)

	# Animação de entrada do monstro (Pop-in)
	if enemy_container:
		enemy_container.scale = Vector2(0.3, 0.3)
		enemy_container.modulate = Color(2.0, 2.0, 2.0, 0.0)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(enemy_container, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(enemy_container, "modulate", Color.WHITE, 0.3)

func _carregar_sprite_inimigo(inimigo: Dictionary) -> void:
	if not enemy_sprite:
		return
		
	var path = inimigo.get("sprite_path", "")
	if path != "" and ResourceLoader.exists(path):
		enemy_sprite.texture = load(path)
	else:
		# Fallback se não especificado
		var nome = inimigo.get("nome", "").to_lower()
		if "javali" in nome:
			enemy_sprite.texture = load("res://assets/sprites/enemy_javali_mana.svg")
		elif "vetto" in nome:
			enemy_sprite.texture = load("res://assets/sprites/enemy_vetto.svg")
		else:
			enemy_sprite.texture = load("res://assets/sprites/enemy_mago_rebelde.svg")

func _on_dano_causado(dano: float, critico: bool, vida_restante: float) -> void:
	progress_vida.value = vida_restante
	_atualizar_texto_vida(vida_restante, progress_vida.max_value)
	
	# Aciona animação de ataque do Herói (dash para frente com a espada)
	_animar_ataque_heroi(critico)
	
	# Aciona tremor e flash de impacto no monstro
	_animar_impacto_monstro(critico)
	
	# Aciona o efeito de texto flutuante (Floating Text)
	spawn_floating_text(dano, critico)

func _on_combate_vencido(_inimigo: Dictionary) -> void:
	progress_vida.value = 0
	_atualizar_texto_vida(0, progress_vida.max_value)
	
	# Animação de derrota do monstro (encolhe e desaparece)
	if enemy_container:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(enemy_container, "scale", Vector2(0.1, 0.1), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(enemy_container, "modulate:a", 0.0, 0.3)

func _atualizar_texto_vida(atual: float, maxima: float) -> void:
	lbl_vida_texto.text = "%d / %d HP" % [int(atual), int(maxima)]

## Animação de Respiração / Idle constante do Asta
func _iniciar_idle_heroi() -> void:
	if not hero_sprite:
		return
	hero_sprite.pivot_offset = Vector2(hero_sprite.size.x / 2.0, hero_sprite.size.y)
	var tween = create_tween().set_loops()
	tween.tween_property(hero_sprite, "scale", Vector2(1.0, 1.04), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hero_sprite, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Herói avança rapidamente para golpear com a espada Anti-Magia
func _animar_ataque_heroi(critico: bool) -> void:
	if not hero_container:
		return
	
	var tween = create_tween()
	var dist_dash = 55.0 if not critico else 85.0
	var duracao = 0.12
	
	# Salto/Avanço de ataque
	tween.tween_property(hero_container, "position:x", pos_original_hero.x + dist_dash, duracao).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(hero_container, "rotation_degrees", 8.0 if not critico else 14.0, duracao)
	
	# Retorno para a posição base
	tween.tween_property(hero_container, "position:x", pos_original_hero.x, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(hero_container, "rotation_degrees", 0.0, 0.2)

## Monstro treme e pisca em vermelho/branco ao ser golpeado
func _animar_impacto_monstro(critico: bool) -> void:
	if not enemy_container or not enemy_sprite:
		return
		
	var tween = create_tween().set_parallel(true)
	
	# Flash de dano
	var cor_flash = Color(2.8, 0.2, 0.2, 1.0) if critico else Color(2.0, 0.6, 0.6, 1.0)
	enemy_sprite.modulate = cor_flash
	tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Tremor físico (Shake)
	var shake_intensidade = 12.0 if critico else 6.0
	var t_shake = create_tween()
	t_shake.tween_property(enemy_container, "position:x", pos_original_enemy.x + shake_intensidade, 0.04)
	t_shake.tween_property(enemy_container, "position:x", pos_original_enemy.x - shake_intensidade, 0.04)
	t_shake.tween_property(enemy_container, "position:x", pos_original_enemy.x + (shake_intensidade * 0.5), 0.04)
	t_shake.tween_property(enemy_container, "position:x", pos_original_enemy.x, 0.05)

## Cria um texto de dano flutuante na tela com animação de subida e desvanecimento
func spawn_floating_text(dano: float, critico: bool) -> void:
	var lbl = Label.new()
	lbl.text = ("¡CRÍTICO! -" if critico else "-") + str(int(dano))
	
	if critico:
		lbl.modulate = Color(1.0, 0.85, 0.1) # Dourado vibrante
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 4)
	else:
		lbl.modulate = Color(1.0, 0.35, 0.35) # Vermelho suave
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 3)
	
	# Posiciona sobre o monstro
	var pos_offset = Vector2(randf_range(-30, 30), randf_range(-20, 20))
	lbl.position = (spawn_dano.size / 2.0) + pos_offset
	lbl.pivot_offset = Vector2(30, 10)
	spawn_dano.add_child(lbl)
	
	# Animação de Floating Text com Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 75.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	if critico:
		lbl.scale = Vector2(1.5, 1.5)
		tween.tween_property(lbl, "scale", Vector2.ONE, 0.25)
	
	tween.chain().tween_callback(lbl.queue_free)
