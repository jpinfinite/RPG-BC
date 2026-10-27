# CHANGELOG — BLACK CLOVER IDLE RPG

Todas as alterações técnicas, correções de bugs, balanceamento econômico e redesign visual implementados nesta auditoria profunda.

---

## [Fase 1] — Auditoria Técnica Completa
- Inventário de 12 problemas técnicos detectados (4 Críticos, 5 Altos, 3 Médios).
- Identificação de código morto e duplicado (`grimoire_data.gd`, `hero_data.gd`, `quest_data.gd`, `quest_manager.gd`, `zone_data.gd`).
- Diagnóstico de falha de Godot 4.x (`set_delay()` no Tween em `rank_hud.gd` e acesso inválido a `combat_manager.game_manager`).

---

## [Fase 2] — Combate e Progressão Unificados
- **Fonte única de verdade:** O `CombatManager.gd` agora é a autoridade absoluta sobre vida do monstro, cálculo de dano, morte, respawn e avanço de andares.
- **Eliminação de loop concorrente:** Removido o loop independente de dano/timer do `game_manager.gd`.
- **Prevenção de Double-Kill:** Criado método `aplicar_dano_magia()` no `CombatManager` para que o `SpellCooldownManager` aplique dano através da autoridade central sem corromper o estado do monstro.
- **Ataque manual funcional:** Método `atacar_por_clique()` balanceado aplicando 50% do DPS efetivo com cálculo correto de crítico.

---

## [Fase 3] — Persistência e Ganho Offline (SaveManager v2)
- **SaveManager v2:** Novo esquema de salvamento com verificação de integridade e migração controlada de versões anteriores.
- **Persistência de DPS e Missão:** O valor do DPS real do jogador (`dano_por_segundo`) e a missão ativa do Yami agora são salvos e restaurados com fidelidade.
- **Proteção contra corrupção e Null Pointer:** Adicionada guarda em `get_tree()` para prevenir falhas caso o save seja chamado fora da árvore ativa.
- **Recompensa Offline Segura:** Limitador de tempo de até 12 horas, garantindo ouro não-negativo calculado a partir do DPS e andar efetivos.

---

## [Fase 4] — Redesign Visual Profissional (Dark Fantasy)
- **Paleta de Cores Black Clover:**
  - Fundo principal: `#100E17`
  - Painéis: `#17131F` com bordas roxas arcanas `#49305F`
  - Realces e títulos: Dourado imperial `#D7AA3E` e Ouro claro `#F4D77C`
  - Destaques de atributos: Verde de energia `#58B947` e texto claro `#EEE7D8`
- **Cabeçalho com ResourcesHUD:**
  - Painéis estilizados para Ouro (`🪙`), Poeira de Mana (`✨`) e DPS (`⚔`) com formatação compacta (K/M/B).
  - Indicador do Andar atual e Rank do Cavaleiro Mágico.
  - Botão de acesso rápido à Cerimônia de Grimório com indicação da raridade atual.
- **Arena de Combate Rebalanceada:**
  - `CombatUI` agora é o foco visual central com expansão vertical dinâmica (`size_flags_vertical = 3`).
  - Proporções equilibradas entre o Herói (Asta), o Inimigo e os efeitos de corte.
- **Cerimônia de Aceitação (Grimório) como Modal:**
  - Card centralizado com temática arcana e bordas douradas.
  - Animação de revelação com levitação, rotação, aura de partículas coloridas por raridade e gradiente de demônio para 5 folhas.
  - Botão de fechar modal para retornar imediatamente ao combate.
- **Menus e Abas (UpgradeMenu):**
  - Estilização completa do `TabContainer` com abas temáticas, botões de ação dourados com estados normais, hover e desabilitados.

---

## [Fase 5] — Responsividade e Telas Verticais
- Suporte a proporção mobile (resolução base 1080x1920 com override 540x960 no desktop).
- Substituição de coordenadas absolutas por `VBoxContainer`, `MarginContainer` e `PanelContainer` com âncoras automáticas.
- Proteção contra colapso de nós de UI em janelas redimensionadas.

---

## [Fase 6] — Economia e Balanceamento
- **Eliminação do Gargalo de Vida:** O escalonamento de vida dos inimigos em `InimigoData.gd` foi ajustado de `1.15^andar` para `1.10^andar`.
- **Resultados de Simulação Comprovados:**
  - *10 Minutos:* Andar 54 atingido (vs 35 anterior), 3.531 Poeira acumulada, 1ª magia desbloqueada.
  - *1 Hora:* Andar 82 atingido (vs 54 anterior), 55.677 Poeira, Prestígio (Andar 50+) alcançado e desbloqueado.
  - *12 Horas:* Andar 116 atingido, 412M de Ouro, 1.49M de Poeira, ciclo de prestígio perfeito.
- **Cozinha da Charmy Rebalanceada:**
  - Fórmula antiga com base `1.5^andar` tornava a comida inacessível nos andares altos.
  - Nova fórmula baseada em `250.0 * pow(1.10, andar - 1)` escala proporcionalmente ao ganho de ouro do monstro.
- **Custo da Invocação:** Estabelecido em 100 Poeiras de Mana, impedindo invocações infinitas sem custo.

---

## [Fase 7 e 8] — Testes Reais e Limpeza
- **Suite de Testes Automatizada (`tests/test_runner_scene.tscn`):**
  - 6 testes unitários e de integração executados diretamente no motor Godot headless:
    1. Autoload GameManager e estado inicial.
    2. Escalabilidade matemática de monstros.
    3. Custo proporcional da Cozinha da Charmy.
    4. Gacha de Grimórios e atribuição de bônus.
    5. Save/Load com SaveManager v2 (Ouro, DPS e Andar restaurados com 100% de precisão).
    6. Combate, clique manual e aplicação de dano com feedback.
  - **Status:** 100% Aprovado (`exit code 0`).
- **Limpeza de Código:**
  - 5 scripts legados obsoletos arquivados com segurança com extensão `.bak` em `scripts/obsolete/`.
  - Remoção de prints de debug excessivos em loops de processo.
