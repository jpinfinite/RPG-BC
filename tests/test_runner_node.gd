extends Node

func _ready() -> void:
	print("\n==================================================")
	print("  SUITE DE TESTES AUTOMATIZADOS (IN-ENGINE GODOT) ")
	print("==================================================")

	var erros = 0

	# 1. Teste Autoload GameManager
	print("[TESTE 1] Autoload GameManager...")
	if not GameManager:
		print("  FALHA: GameManager singleton nao encontrado!")
		erros += 1
	else:
		print("  OK: GameManager ativo! DPS: %.1f | Ouro: %.0f | Andar: %d" % [GameManager.dano_por_segundo, GameManager.ouro, GameManager.andar_atual])

	# 2. Teste InimigoData
	print("[TESTE 2] Escalabilidade de Inimigos...")
	var ini_1 = InimigoData.gerar_inimigo(1)
	var ini_50 = InimigoData.gerar_inimigo(50)
	if ini_1.vida_max <= 0 or ini_50.vida_max <= ini_1.vida_max:
		print("  FALHA: Escalabilidade de vida inconsistente!")
		erros += 1
	else:
		print("  OK: HP Andar 1: %.1f | HP Andar 50: %.1f (escalonamento 1.10)" % [ini_1.vida_max, ini_50.vida_max])

	# 3. Teste CozinhaCharmy Custo
	print("[TESTE 3] Cozinha da Charmy proporcao de custo...")
	var charmy = CozinhaCharmy.new()
	charmy.game_manager = GameManager
	GameManager.andar_atual = 1
	var c1 = charmy.get_custo_refeicao()
	GameManager.andar_atual = 20
	var c20 = charmy.get_custo_refeicao()
	if c1 <= 0 or c20 <= c1 or c20 > 50000.0:
		print("  FALHA: Custo de banquete desbalanceado: ", c20)
		erros += 1
	else:
		print("  OK: Custo Banquete Andar 1: %.0f Ouro | Andar 20: %.0f Ouro" % [c1, c20])
	charmy.free()

	# 4. Teste Gacha de Grimorio com Custo
	print("[TESTE 4] Cerimonia de Aceitacao (Gacha)...")
	GameManager.poeira_mana = 250.0
	var grimorio = GameManager.realizar_cerimonia_aceitacao()
	if grimorio.is_empty() or not grimorio.has("nome") or not grimorio.has("raridade"):
		print("  FALHA: Formato do grimorio sorteado invalido!")
		erros += 1
	else:
		print("  OK: Sorteado %s (%s, Mult Dano: %.1fx)" % [grimorio.nome, grimorio.raridade, grimorio.mult_dano])

	# 5. Teste Save/Load Persistencia
	print("[TESTE 5] Persistencia de Save (SaveManager v2)...")
	var main_inst = load("res://scenes/main.tscn").instantiate()
	add_child(main_inst)
	var save_mgr = main_inst.get_node("SaveManager") as SaveManager

	GameManager.ouro = 99999.0
	GameManager.poeira_mana = 4444.0
	GameManager.dano_por_segundo = 250.0
	GameManager.andar_atual = 55

	save_mgr.salvar_jogo()
	print("  Dados salvos com sucesso no SaveManager v2. Modificando estado em memoria...")

	GameManager.ouro = 0.0
	GameManager.poeira_mana = 0.0
	GameManager.dano_por_segundo = 10.0
	GameManager.andar_atual = 1

	save_mgr.carregar_jogo()

	if GameManager.ouro == 99999.0 and GameManager.dano_por_segundo == 250.0 and GameManager.andar_atual == 55:
		print("  OK: Save restaurou perfeitamente Ouro (%.0f), DPS (%.1f) e Andar (%d)" % [GameManager.ouro, GameManager.dano_por_segundo, GameManager.andar_atual])
	else:
		print("  FALHA: Restauracao inconsistente! Ouro: %.0f, DPS: %.1f, Andar: %d" % [GameManager.ouro, GameManager.dano_por_segundo, GameManager.andar_atual])
		erros += 1
	main_inst.queue_free()

	# 6. Teste Combate e Dano
	print("[TESTE 6] CombatManager aplicacao de dano...")
	var combat_mgr = CombatManager.new()
	add_child(combat_mgr)
	combat_mgr.gm = GameManager
	combat_mgr.iniciar_novo_combate()

	if combat_mgr.inimigo_atual.is_empty():
		print("  FALHA: Inimigo nao instanciado no CombatManager!")
		erros += 1
	else:
		var hp_inicial = combat_mgr.inimigo_atual.vida_atual
		var res_ataque = combat_mgr.atacar_por_clique()
		var hp_depois = combat_mgr.inimigo_atual.vida_atual if not combat_mgr.inimigo_atual.is_empty() else 0.0
		if hp_depois >= hp_inicial:
			print("  FALHA: Ataque manual nao reduziu HP do monstro!")
			erros += 1
		else:
			print("  OK: Ataque desferido: %.1f de dano (HP: %.1f -> %.1f)" % [res_ataque.dano, hp_inicial, hp_depois])
	combat_mgr.free()

	print("==================================================")
	if erros == 0:
		print("  RESULTADO: TODOS OS 6 TESTES PASSARAM COM SUCESSO! ")
		print("==================================================")
		get_tree().quit(0)
	else:
		print("  RESULTADO: %d TESTE(S) FALHARAM! " % erros)
		print("==================================================")
		get_tree().quit(1)
