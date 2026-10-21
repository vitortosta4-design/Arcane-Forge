# Arcane Forge

Jogo cooperativo 3D (2 jogadores contra inimigos controlados por IA), em low poly engraçado, em que o jogador descreve magias com as próprias palavras e o jogo transforma a descrição em habilidade real.

**Fase atual:** Fase 2, magia por texto com IA real. A Fase 1 (esqueleto jogável) está praticamente concluída; restam só os dois critérios que dependem do Vitor jogar e avaliar (ver `docs/decisoes.md`).

## Onde está cada coisa
- `CLAUDE.md`: instruções para o Claude Code trabalhar neste projeto.
- `docs/documento-mestre.md`: visão completa do projeto escrita pelo Vitor.
- `docs/decisoes.md`: registro de decisões aprovadas, propostas e pendentes. Consulte antes de qualquer mudança de arquitetura.
- `docs/proposta-tecnica.md`: arquitetura, ficha de magia, limites, multiplayer, segurança e plano da Fase 1.
- `evidencias/`: prints e medições que comprovam cada critério de aceitação.

## Stack decidida
- Engine: Godot 4.7 (GDScript)
- IA das magias: camada trocável, começando com plano gratuito (Groq ou Gemini)
- Proteção de chaves: Supabase Edge Function
- Multiplayer: um jogador hospeda e é o juiz da partida
- Orçamento: R$ 0/mês, teto de R$ 50/mês

## Regras de trabalho
1. Nada está pronto sem teste e, quando for visual, sem rodar o jogo e guardar um print como evidência.
2. Decisões grandes, gastos e operações irreversíveis exigem aprovação do Vitor.
3. Nenhuma chave de API no repositório ou no executável.
