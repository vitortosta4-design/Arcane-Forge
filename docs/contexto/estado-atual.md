# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 22/10/2026

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035).
- Já existe: livro de receitas (`jogo/dados/receitas.json`), runas na clareira, caverna provisória com a bigorna, tela da bigorna (E), barra 1 a 4, grimório salvo no PC. Testes: 292/292 na última rodada registrada.
- Fase 1 continua com dois critérios abertos que dependem do Vitor (canto de atmosfera e 10 minutos de jogo).

## Próximo passo
1. Organizar o HUD no layout oficial da ADR-039 (posições finais, visual provisório), com print em `evidencias/fase-2/` e rodada do crítico.
2. Vitor joga do começo ao fim no PC: achar runas, forjar 2 medalhões, usar na galinha, medir FPS com `ferramentas\medir_fps.bat`.
3. Ajustar números (mana, recarga) a partir do que ele disser.

## Problemas conhecidos
- Teste instável: "área continua machucando a cada segundo" às vezes falha e às vezes passa, sem mudança no código. Investigar antes de confiar na suíte para algo que mexa em áreas.
- Névoa volumétrica e SDFGI só aparecem no PC do Vitor (a nuvem renderiza em Compatibility).

## Pendente do Vitor
- Jogar o ciclo da forja e opinar.
- Imagem de referência do medalhão (ADR-033), antes da Fase 5.
