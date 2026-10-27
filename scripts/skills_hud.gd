extends Control
class_name SkillsHUD

@export var spell_cooldown_manager: SpellCooldownManager
@export var game_manager: Node

# Referências dos nós da interface para cada slot
@onready var slots_container: HBoxContainer = $MarginContainer/SlotsContainer

# Armazena nós e referências rápidas para cada magia
var slots_data: Dictionary = {}

func _ready() -> void:
	_resolver_referencias()
	_inicializar_slots()
	
	if spell_cooldown_manager:
		spell_cooldown_manager.magia_conjurada.connect(_on_magia_conjurada)
		spell_cooldown_manager.magia_desbloqueada.connect(_on_magia_desbloqueada)

func _resolver_referencias() -> void:
	if not game_manager and get_node_or_null("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		
	if not spell_cooldown_manager and get_tree():
		spell_cooldown_manager = get_tree().get_first_node_in_group("spell_cooldown_manager") as SpellCooldownManager
		if not spell_cooldown_manager:
			spell_cooldown_manager = get_node_or_null("../SpellCooldownManager") as SpellCooldownManager

func _inicializar_slots() -> void:
	for id_magia in MagiaData.SPELLS.keys():
		var slot_node = slots_container.get_node_or_null("Slot_" + id_magia)
		if not slot_node:
			continue
			
		var dados = MagiaData.SPELLS[id_magia]
		var btn = slot_node.get_node("BotaoMagia") as TextureButton
		var progress = slot_node.get_node("CooldownBar") as TextureProgressBar
		var label_tempo = slot_node.get_node("TempoLabel") as Label
		var lock_panel = slot_node.get_node("LockOverlay") as Control
		var lock_custo = lock_panel.get_node("VBox/CustoLabel") as Label
		var border = slot_node.get_node("Border") as TextureRect
		
		# Conectar clique do botão
		btn.pressed.connect(func(): _on_slot_clicado(id_magia))
		
		# Configurar valores padrão
		progress.min_value = 0.0
		progress.max_value = dados["cooldown"]
		progress.step = 0.05
		progress.value = 0.0
		
		lock_custo.text = _formatar_numero(dados["custo_desbloqueio"]) + " ✨"
		
		slots_data[id_magia] = {
			"slot": slot_node,
			"btn": btn,
			"progress": progress,
			"label_tempo": label_tempo,
			"lock_panel": lock_panel,
			"lock_custo": lock_custo,
			"border": border,
			"dados": dados,
			"tween_brilho": null
		}

func _process(_delta: float) -> void:
	if not spell_cooldown_manager:
		_resolver_referencias()
		if not spell_cooldown_manager:
			return

	for id_magia in slots_data.keys():
		var slot_info = slots_data[id_magia]
		var desbloqueada = spell_cooldown_manager.magias_desbloqueadas.get(id_magia, false)
		var cd_atual = spell_cooldown_manager.cooldowns_atuais.get(id_magia, 0.0)
		var cd_max = slot_info["dados"]["cooldown"]
		
		var btn: TextureButton = slot_info["btn"]
		var progress: TextureProgressBar = slot_info["progress"]
		var label_tempo: Label = slot_info["label_tempo"]
		var lock_panel: Control = slot_info["lock_panel"]
		
		if not desbloqueada:
			# Magia ainda bloqueada
			lock_panel.visible = true
			label_tempo.visible = false
			progress.value = 0.0
			btn.modulate = Color(0.35, 0.35, 0.35, 1.0)
			btn.disabled = false # Permite clicar para comprar se tiver mana dust
		else:
			# Magia desbloqueada
			lock_panel.visible = false
			
			if cd_atual > 0.0:
				# Em recarga: fica cinza e desativa interação
				btn.modulate = Color(0.4, 0.4, 0.45, 1.0)
				btn.disabled = true
				progress.visible = true
				progress.value = cd_atual
				
				label_tempo.visible = true
				if cd_atual >= 10.0:
					label_tempo.text = "%.0fs" % cd_atual
				else:
					label_tempo.text = "%.1fs" % cd_atual
			else:
				# Pronta para disparar
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
				btn.disabled = false
				progress.value = 0.0
				progress.visible = false
				label_tempo.visible = false

# Ao clicar no slot
func _on_slot_clicado(id_magia: String) -> void:
	if not spell_cooldown_manager:
		return
		
	var desbloqueada = spell_cooldown_manager.magias_desbloqueadas.get(id_magia, false)
	if not desbloqueada:
		# Tenta desbloquear a habilidade
		var comprou = spell_cooldown_manager.desbloquear_magia(id_magia)
		if not comprou:
			# Feedback de falta de mana
			_animar_aviso_falta_mana(id_magia)
	else:
		# Se já desbloqueada e pronta, o jogador pode forçar o cast manual imediato
		if spell_cooldown_manager.cooldowns_atuais.get(id_magia, 0.0) <= 0.0:
			spell_cooldown_manager._conjurar_magia_automatica(id_magia)

# Efeito visual de brilho e pulso quando a magia dispara automaticamente
func _on_magia_conjurada(id_magia: String) -> void:
	if not slots_data.has(id_magia):
		return
		
	var slot_info = slots_data[id_magia]
	var slot_node: Control = slot_info["slot"]
	var btn: TextureButton = slot_info["btn"]
	var dados = slot_info["dados"]
	var cor_aura = Color.from_string(dados.get("cor_aura", "ffffff"), Color.WHITE)
	
	# Cancela animação anterior se houver
	if slot_info["tween_brilho"] and slot_info["tween_brilho"].is_valid():
		slot_info["tween_brilho"].kill()
		
	var tween = create_tween().set_parallel(true)
	slot_info["tween_brilho"] = tween
	
	# 1. Flash de cor da aura mágica brilhante
	btn.modulate = cor_aura.lightened(0.6)
	tween.tween_property(btn, "modulate", Color(0.4, 0.4, 0.45, 1.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Pulso de escala com pivô centralizado
	slot_node.pivot_offset = slot_node.size / 2.0
	slot_node.scale = Vector2(1.22, 1.22)
	tween.tween_property(slot_node, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Feedback visual ao desbloquear uma nova técnica
func _on_magia_desbloqueada(id_magia: String) -> void:
	if not slots_data.has(id_magia):
		return
		
	var slot_info = slots_data[id_magia]
	var slot_node: Control = slot_info["slot"]
	slot_info["lock_panel"].visible = false
	
	var tween = create_tween()
	slot_node.pivot_offset = slot_node.size / 2.0
	slot_node.scale = Vector2(0.5, 0.5)
	slot_node.modulate = Color(2.0, 2.0, 2.0, 1.0)
	tween.tween_property(slot_node, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(slot_node, "modulate", Color.WHITE, 0.5)

# Feedback quando jogador clica sem poeira suficiente
func _animar_aviso_falta_mana(id_magia: String) -> void:
	if not slots_data.has(id_magia):
		return
	var lock_panel: Control = slots_data[id_magia]["lock_panel"]
	var tween = create_tween()
	tween.tween_property(lock_panel, "modulate", Color(2.0, 0.2, 0.2, 1.0), 0.1)
	tween.tween_property(lock_panel, "modulate", Color.WHITE, 0.25)

# Formatação limpa de números para Idle RPG
func _formatar_numero(valor: float) -> String:
	if valor >= 1_000_000:
		return "%.1fM" % (valor / 1_000_000.0)
	elif valor >= 1_000:
		return "%.1fK" % (valor / 1_000.0)
	return str(int(valor))
