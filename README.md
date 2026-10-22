# Arcane Forge

Jogo cooperativo 3D (2 jogadores contra inimigos controlados por IA), em low poly engraçado, em que o jogador explora, encontra runas e combina essas runas numa bigorna viva para forjar magias. Cada combinação tem receita fixa e vira um medalhão na barra (ADR-032 a 034).

**Fase atual:** Fase 2, ciclo da forja jogando sozinho (Forja de Runas, ADR-035). Onde o trabalho parou: `docs/contexto/estado-atual.md`.

## Onde está cada coisa
- `CLAUDE.md`: instruções para o Claude Code trabalhar neste projeto.
- `docs/documento-mestre.md`: visão completa do projeto escrita pelo Vitor.
- `docs/decisoes.md`: registro de decisões aprovadas, propostas e pendentes. Consulte antes de qualquer mudança de arquitetura.
- `docs/contexto/estado-atual.md`: onde o trabalho parou e qual é o próximo passo.
- `docs/contexto/diario.md`: histórico do que foi implementado, achados e limitações.
- `docs/proposta-tecnica.md`: arquitetura, ficha de magia, limites, multiplayer, segurança e plano da Fase 1.
- `evidencias/`: prints e medições que comprovam cada critério de aceitação.

## Stack decidida
- Engine: Godot 4.7 (GDScript)
- Magias: receitas fixas de runas, sem IA no núcleo (o código antigo da IA fica guardado, sem uso)
- Multiplayer: um jogador hospeda e é o juiz da partida
- Orçamento: R$ 0/mês, teto de R$ 50/mês

## Regras de trabalho
1. Nada está pronto sem teste e, quando for visual, sem rodar o jogo e guardar um print como evidência.
2. Decisões grandes, gastos e operações irreversíveis exigem aprovação do Vitor.
3. Nenhuma chave de API no repositório ou no executável.
