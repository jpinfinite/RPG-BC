extends Node
class_name CombatManager

signal combate_iniciado(inimigo: Dictionary)
signal dano_causado(dano: float, critico: bool, vida_restante: float)
signal combate_vencido(inimigo: Dictionary)

var cena_corte = preload("res://scenes/CorteEfeito.tscn")
@export var game_manager: Node
var inimigo_atual: Dictionary = {}
var timer_ataque: Timer
var _chave_inimigo_atual: String = ""

func _ready() -> void:
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		push_error("CombatManager: GameManager não encontrado.")
		return
	game_manager.inimigo_atualizado.connect(_on_inimigo_atualizado)
	game_manager.inimigo_derrotado.connect(_on_inimigo_derrotado_pelo_game_manager)
	if game_manager.inimigo_atual.is_empty():
		game_manager.gerar_novo_inimigo()
	else:
		_on_inimigo_atualizado(game_manager.inimigo_atual)
	timer_ataque = Timer.new()
	timer_ataque.name = "TimerAtaque"
	timer_ataque.wait_time = 1.0
	timer_ataque.autostart = true
	timer_ataque.timeout.connect(_on_mago_atacar)
	add_child(timer_ataque)

func _on_inimigo_atualizado(dados: Dictionary) -> void:
	inimigo_atual = dados.duplicate(true)
	if inimigo_atual.is_empty():
		return
	var chave := "%s|%s|%s" % [str(inimigo_atual.get("nome", "")), str(inimigo_atual.get("vida_max", 0)), str(inimigo_atual.get("tipo", ""))]
	if chave != _chave_inimigo_atual:
		_chave_inimigo_atual = chave
		combate_iniciado.emit(inimigo_atual.duplicate(true))

func _on_mago_atacar() -> void:
	if not game_manager or game_manager.inimigo_atual.is_empty(): return
	var dano := game_manager.get_dano_efetivo()
	var chance_crit := clampf(float(game_manager.chance_critico_atual), 0.0, 1.0)
	var critico := randf() < chance_crit
	if critico:
		dano *= 2.0
		disparar_efeito_corte(Vector2(540, 180), "Anti-Magia")
	var vida_antes := float(game_manager.inimigo_atual.get("vida_atual", 0.0))
	var vida_restante := maxf(0.0, vida_antes - dano)
	# Atualiza a HUD antes de o GameManager emitir derrota e criar o próximo inimigo.
	dano_causado.emit(dano, critico, vida_restante)
	game_manager.aplicar_dano_no_inimigo(dano)

func _on_inimigo_derrotado_pelo_game_manager(dados: Dictionary) -> void:
	combate_vencido.emit(dados.duplicate(true))

func iniciar_novo_combate() -> void:
	if game_manager:
		game_manager.gerar_novo_inimigo()

func disparar_efeito_corte(posicao_alvo: Vector2 = Vector2(540, 180), elemento: String = "Anti-Magia") -> void:
	if not cena_corte or not get_tree() or not get_tree().current_scene: return
	var novo_corte = cena_corte.instantiate()
	get_tree().current_scene.add_child(novo_corte)
	if novo_corte.has_method("disparar_efeito"):
		novo_corte.disparar_efeito(posicao_alvo, elemento)
