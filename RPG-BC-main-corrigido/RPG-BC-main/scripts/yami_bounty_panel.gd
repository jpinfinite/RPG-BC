extends Panel
class_name YamiBountyPanel

@export var missao_manager: MissaoManager

@onready var lbl_medalhas: Label = %LblMedalhas
@onready var lbl_titulo: Label = %LblTitulo
@onready var lbl_descricao: Label = %LblDescricao
@onready var progress_missao: ProgressBar = %ProgressMissao
@onready var lbl_progresso_texto: Label = %LblProgressoTexto
@onready var lbl_recompensa: Label = %LblRecompensa
@onready var foto_yami: TextureRect = %FotoYami
@onready var btn_trocar_missao: Button = %BtnTrocarMissao

func _ready() -> void:
	_resolver_referencias()
	_iniciar_animacao_idle_yami()
	btn_trocar_missao.pressed.connect(_on_trocar_missao_pressed)
	
	if missao_manager:
		missao_manager.missao_atualizada.connect(atualizar_painel)
		atualizar_painel()

func _resolver_referencias() -> void:
	if not missao_manager and get_tree():
		missao_manager = get_tree().get_first_node_in_group("missao_manager") as MissaoManager
		if not missao_manager:
			missao_manager = get_node_or_null("/root/Main/MissaoManager") as MissaoManager

func atualizar_painel() -> void:
	if not missao_manager:
		_resolver_referencias()
		if not missao_manager:
			return

	# Atualiza o contador de medalhas acumuladas
	lbl_medalhas.text = "🏅 Medalhas de Mérito: %d" % missao_manager.medalhas_merito

	var missao = missao_manager.missao_ativa
	if missao.is_empty():
		lbl_descricao.text = "\"Esperem um pouco... ainda estou no banheiro.\" - Yami"
		progress_missao.value = 0
		lbl_progresso_texto.text = "Aguardando próxima missão..."
		lbl_recompensa.text = ""
		return

	# Atualiza a descrição e meta
	lbl_descricao.text = "\"%s\"" % missao.get("descricao", "")
	
	var alvo = missao.get("alvo", 1)
	var progresso = missao.get("progresso_atual", 0)
	var completada = missao.get("completada", false)
	
	progress_missao.max_value = alvo
	progress_missao.value = progresso
	
	lbl_recompensa.text = "Recompensa: +%d Medalhas 🏅" % missao.get("recompensa_medalhas", 0)

	if completada:
		lbl_progresso_texto.text = "COMPLETADA! Superou seus limites!"
		_animar_conclusao_missao()
	else:
		lbl_progresso_texto.text = "%d / %d" % [progresso, alvo]

# Micro-animação do Capitão Yami (respiração / pulso sutil de respeito)
func _iniciar_animacao_idle_yami() -> void:
	if not foto_yami:
		return
	foto_yami.pivot_offset = foto_yami.size / 2.0
	var tween = create_tween().set_loops()
	tween.tween_property(foto_yami, "scale", Vector2(1.03, 1.03), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(foto_yami, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Flash dourado comemorativo ao completar
func _animar_conclusao_missao() -> void:
	var tween = create_tween()
	tween.tween_property(progress_missao, "modulate", Color(2.0, 1.8, 0.4, 1.0), 0.2)
	tween.tween_property(progress_missao, "modulate", Color.WHITE, 0.4)
	
	# Pequeno tremor de satisfação do Capitão
	if foto_yami:
		var t_yami = create_tween()
		t_yami.tween_property(foto_yami, "position:y", foto_yami.position.y - 6.0, 0.15)
		t_yami.tween_property(foto_yami, "position:y", foto_yami.position.y, 0.25)


func _on_trocar_missao_pressed() -> void:
	if missao_manager and missao_manager.trocar_missao():
		atualizar_painel()
