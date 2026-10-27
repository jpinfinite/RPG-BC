extends Control
class_name ResourcesHUD
## HUD superior com recursos, DPS e informações do mago.

@onready var lbl_ouro: Label = %LblOuro
@onready var lbl_poeira: Label = %LblPoeira
@onready var lbl_dps: Label = %LblDps
@onready var lbl_rank: Label = %LblRank
@onready var lbl_andar: Label = %LblAndar

func _ready() -> void:
	if GameManager:
		GameManager.recursos_atualizados.connect(_on_recursos_atualizados)
		_on_recursos_atualizados()

	var rank_manager = get_tree().get_first_node_in_group("rank_manager") as RankManager
	if rank_manager:
		rank_manager.jogador_promovido.connect(func(_titulo): _on_recursos_atualizados())

func _on_recursos_atualizados() -> void:
	if not GameManager:
		return

	lbl_ouro.text = "🪙 " + _fmt(GameManager.ouro)
	lbl_poeira.text = "✨ " + _fmt(GameManager.poeira_mana)

	var dps_total = (GameManager.dano_por_segundo + GameManager.dps_esquadrao_passivo) * GameManager.multiplicador_mana * GameManager.mult_anti_magia_definitivo * GameManager.mult_dano_rank
	lbl_dps.text = "⚔ " + _fmt(dps_total) + " DPS"

	lbl_andar.text = "Andar " + str(GameManager.andar_atual)

	var rank_mgr = get_tree().get_first_node_in_group("rank_manager") as RankManager
	if rank_mgr:
		lbl_rank.text = rank_mgr.get_rank_atual().get("titulo", "Cavaleiro")

func _fmt(val: float) -> String:
	if val >= 1_000_000_000:
		return "%.2fB" % (val / 1_000_000_000.0)
	elif val >= 1_000_000:
		return "%.2fM" % (val / 1_000_000.0)
	elif val >= 1_000:
		return "%.1fK" % (val / 1_000.0)
	return str(int(val))
