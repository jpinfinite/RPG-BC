extends Control
class_name RankHUD

@export var rank_manager: RankManager

@onready var lbl_rank_titulo: Label = %LblRankTitulo
@onready var lbl_bonus_rank: Label = %LblBonusRank
@onready var particulas_promocao: GPUParticles2D = %ParticulasPromocao
@onready var banner_promocao: PanelContainer = %BannerPromocao
@onready var lbl_novo_rank_banner: Label = %LblNovoRankBanner

var audio_player: AudioStreamPlayer

func _ready() -> void:
	banner_promocao.visible = false
	_configurar_audio_sintetizado()
	_resolver_referencias()
	_conectar_sinais()
	atualizar_hud()

func _resolver_referencias() -> void:
	if not rank_manager:
		rank_manager = get_tree().get_first_node_in_group("rank_manager") as RankManager
		if not rank_manager:
			rank_manager = get_node_or_null("../RankManager") as RankManager

func _conectar_sinais() -> void:
	if rank_manager:
		rank_manager.jogador_promovido.connect(_on_jogador_promovido)
	if GameManager:
		GameManager.recursos_atualizados.connect(atualizar_hud)

func atualizar_hud() -> void:
	if not rank_manager:
		return
	
	var dados = rank_manager.get_rank_atual()
	lbl_rank_titulo.text = dados.get("titulo", "Cavaleiro Mágico")
	var mult_d = dados.get("mult_dano", 1.0)
	var mult_o = dados.get("mult_ouro", 1.0)
	lbl_bonus_rank.text = "Poder de Patente: x%.1f Dano • x%.1f Ouro" % [mult_d, mult_o]

func _on_jogador_promovido(novo_titulo: String) -> void:
	atualizar_hud()
	_tocar_som_vitoria_simulado()
	_disparar_animacao_promocao(novo_titulo)

func _disparar_animacao_promocao(novo_titulo: String) -> void:
	lbl_novo_rank_banner.text = novo_titulo
	banner_promocao.visible = true
	banner_promocao.modulate.a = 0.0
	banner_promocao.scale = Vector2(0.5, 0.5)
	banner_promocao.pivot_offset = banner_promocao.size / 2.0
	
	# Dispara a chuva de partículas de mana na tela inteira
	particulas_promocao.restart()
	particulas_promocao.emitting = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner_promocao, "modulate:a", 1.0, 0.3)
	tween.tween_property(banner_promocao, "scale", Vector2.ONE, 0.4)
	
	# Fica visível por 2.5 segundos e desvanece
	var tween_out = create_tween().set_delay(2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_out.tween_property(banner_promocao, "modulate:a", 0.0, 0.5)
	tween_out.tween_callback(func(): banner_promocao.visible = false)

## Síntese procedural de uma fanfarra mágica triunfal (C - E - G - C)
func _configurar_audio_sintetizado() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func _tocar_som_vitoria_simulado() -> void:
	# Gera tons de sintetizador em arpejo maior
	var notas = [523.25, 659.25, 783.99, 1046.50] # Dó, Mi, Sol, Dó alto
	var duracao_nota = 0.12
	var sample_rate = 22050
	
	var total_samples = int(sample_rate * duracao_nota * notas.size())
	var buffer = PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var idx = 0
	for nota in notas:
		var n_samples = int(sample_rate * duracao_nota)
		for s in range(n_samples):
			var t = float(s) / sample_rate
			var sample_val = sin(t * nota * TAU) * 0.4
			# Decaimento suave da nota
			sample_val *= (1.0 - (float(s) / n_samples) * 0.4)
			var int_sample = int(sample_val * 32767.0)
			buffer.encode_s16(idx, int_sample)
			idx += 2
			
	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = sample_rate
	sample.data = buffer
	
	audio_player.stream = sample
	audio_player.play()
