# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 28/10/2026 (gigante da árvore, 1ª rodada com esqueleto: reprovado)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035).
- Já existe: livro de receitas, runas na clareira, caverna provisória com a bigorna, tela da bigorna (E), barra 1 a 4, grimório salvo no PC.
- **HUD no estilo da referência aprovada** (`docs/referencias/hud-referencia-01.png`, ADR-039, 23/10/2026): retrato com o modelo do mago em aro dourado, barras de vida e mana de metal com ponta cortada, estados em ícones, mira de 4 tracinhos, vida do inimigo só depois do acerto, 4 medalhões redondos com a runa da folha do Vitor acesa e recarga em sombra de relógio, contador de runas à esquerda da barra, minimapa de verdade (foto de cima da clareira, runas, inimigos, forja). A tela escala com a janela. Crítico: 6,5 (reprovado) → 8,0 (aprovado); os 5 itens que ele deixou como dívida foram feitos depois, sem nova rodada.
- **Ciclo da forja testado de ponta a ponta na arena de verdade** (teste automático): encosta em 3 runas, entra na caverna pela boca, forja 2 medalhões diferentes, sai e usa os dois na galinha (o Jato a molha, o Golem a alcança e machuca). Da Fase 2 só falta o que é do Vitor: jogar, achar divertido e medir FPS.
- HUD placeholder aprovado pelo Vitor como provisório; o texto da magia lançada saiu (era do plano da IA por texto).
- Magia por texto com IA **removida do jogo** (ADR-041): sem caixa de texto, porteiro, `Interpretador` ou tecla Q.
- **Mago novo no jogo** (ADR-043): modelo da folha do Vitor com esqueleto, dedos de dois ossos e 5 animações; braços próprios em primeira pessoa com ondinha nos dedos. Mão aprovada pelo Vitor. Crítico: 4,5 → 6,0 → 6,5 → 6,5 → 7,0 → 7,2 → 7,8 → 8,0 → **8,4 aprovado** (9ª rodada, ADR-045: proporção da folha; ramo `mago-criticas`, ainda fora do `main`). Pendências aceitas: lapelas e casaco esvoaçando.
- **Runas pelo vetor do Vitor** (ramo `runas-contorno-svg`): contorno dele nas 8; faltam os símbolos gravitação, arremesso e quebrar (e talvez refazer a água como contorno).
- **Runas v6 no jogo** (`runas_v4_acesas.glb`, gerada por `arte/personagens/runas/runas.py`): encaixe de quebra-cabeça, topo torto com pico, pedra acesa escura. Crítico: 5 → 6 → 6,5 (reprovado). Detalhes e pedidos dele no diário.
- Testes: 302/302. Crítico do HUD (só posição, tamanho e legibilidade): 7/10 reprovado na 2ª rodada; os 3 itens que ele exigiu foram feitos depois (sem nova rodada, para poupar cota).
- Fase 1 continua com dois critérios abertos que dependem do Vitor (canto de atmosfera e 10 minutos de jogo).

- Equipe tem agora o **animador** (ADR-042), além do crítico. Primeira auditoria de animação feita (`docs/auditoria-animacao.md`): galinha zumbi sem aviso de ataque nem reação a dano (crítico), mago lançando sem preparação, pé da galinha invocada patinando. Nada corrigido ainda: aguarda o Vitor autorizar a ordem de trabalho.
- **Gigante da árvore (ADR-047), 1ª rodada pela skill `personagem-low-poly`** (28/10/2026): modelo em Blender com esqueleto de verdade (`arte/personagens/gigante_arvore/gigante_arvore.py`, 1.652 triângulos) e animações `Parado`/`Andar` (sem `Atacar`/`Dano`, decisão: a árvore não ataca nem reage a dano), integrado no jogo (`jogo/scripts/eventos/arvore_gigante.gd` troca o visual procedural por `gigante_arvore.glb`). **Reprovado**: os braços existem no script mas não aparecem na silhueta (ficam colados e escondidos dentro do tronco), que é o traço mais marcante da folha do Vitor. Testes 307/308 (igual ao estado anterior, falha conhecida não relacionada). Prints em `evidencias/fase-2/eventos-ambientais/` (`gigante_frente.png`, `gigante_lado.png`, `gigante_costas.png`, mais 2 do jogo — esses saíram escuros/contraluz, não são boa evidência de cor). Pergunta de prioridade abaixo.

## Próximo passo
- **Gigante da árvore:** decidir com o Vitor se vale investir mais uma rodada agora (separar/afastar os braços do tronco de verdade, conferir se o resto da silhueta bate com a folha) ou se isso espera, já que é fora da Fase 2 (ADR-047 já registra que é ampliação de escopo).
- Matheus testa com `build/ArcaneForge_teste_Matheus.zip` (gerar de novo com `ferramentas/gerar_pacote_teste.sh`) e manda o RELATORIO_PARA_O_VITOR.md.
- Vitor olha o mago aprovado (ramo `mago-criticas`) e decide se junta ao `main`.
- Runas: montar as 8 quando os símbolos chegarem, trocar no jogo e acertar o brilho da pedra pelo print.
0. Runas: o Vitor decide se a pedra acesa fica tingida (como a folha) ou cinza com cor só em volta do símbolo (pedido do crítico), e se segue mais uma rodada (abas maiores, chanfro) ou passa para o próximo modelo (galinha zumbi ou bigorna).
1. Vitor segue `docs/roteiro-de-teste.md` (reescrito para o ciclo da forja) e joga do começo ao fim no PC: achar runas, forjar 2 medalhões, usar na galinha, medir FPS com `ferramentas\medir_fps.bat`, e olhar se o HUD está legível.
2. Ajustar números (mana, recarga) a partir do que ele disser.
3. HUD: o Vitor confere no PC (1080p, Forward+) se o retrato, o minimapa e a barra estão legíveis. O parceiro (só vida, 4b) entra na Fase 3.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem (12 rodadas, 6 em paralelo, e com engasgo simulado). O teste foi deixado mais robusto (espera em quadros de física) e agora diz a distância da galinha se falhar. Se falhar no PC do Vitor, anotar essa distância.
- Névoa volumétrica e SDFGI só aparecem no PC do Vitor (a nuvem renderiza em Compatibility).

## Pendente do Vitor
- Animação: autorizar a ordem de trabalho da auditoria; decidir o tempo de aviso da bicada (proposta 0,25 s), se a galinha zumbi vira a galinha do piloto com esqueleto e se o mago passa a usar o modelo com esqueleto.
- Apagar o projeto `arcane-forge` no painel do Supabase (já pausado pelo Claude; a ferramenta dele não apaga) e revogar a chave da Groq que ficava guardada nele.
- Referência do **medalhão em close** (o objeto forjado, com runa em relevo), antes da Fase 5 (ADR-033). A do HUD já chegou e foi aplicada.
- Jogar o ciclo da forja e opinar.
