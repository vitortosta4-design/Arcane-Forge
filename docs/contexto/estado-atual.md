# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 23/10/2026

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035).
- Já existe: livro de receitas, runas na clareira, caverna provisória com a bigorna, tela da bigorna (E), barra 1 a 4, grimório salvo no PC.
- **HUD no layout oficial da ADR-039** (feito agora): retrato placeholder + vida e mana + runas (canto superior esquerdo), estados numa faixa logo abaixo, mira no centro, barra 1 a 4 (medalhão redondo em moldura de losango) com tecla e recarga em segundos embaixo, aviso de interação logo acima da barra, minimapa reservado no canto inferior direito, FPS escondido (F3 liga). Visual 100% provisório de propósito: formas lisas em cinza e nas cores dos elementos.
- **Ciclo da forja testado de ponta a ponta na arena de verdade** (teste automático): encosta em 3 runas, entra na caverna pela boca, forja 2 medalhões diferentes, sai e usa os dois na galinha (o Jato a molha, o Golem a alcança e machuca). Da Fase 2 só falta o que é do Vitor: jogar, achar divertido e medir FPS.
- HUD placeholder aprovado pelo Vitor como provisório; o texto da magia lançada saiu (era do plano da IA por texto).
- Magia por texto com IA **removida do jogo** (ADR-041): sem caixa de texto, porteiro, `Interpretador` ou tecla Q.
- **Mago novo no jogo** (ADR-043): modelo da folha do Vitor com esqueleto, dedos de dois ossos e 5 animações; braços próprios em primeira pessoa com ondinha nos dedos. Crítico: 4,5 → 6,0 (reprovado na 2ª rodada); a 3ª rodada de ajustes (mão menor e mais clara, dobra suave, aba maior) não passou de novo pelo crítico.
- Testes: 291/291. Crítico do HUD (só posição, tamanho e legibilidade): 7/10 reprovado na 2ª rodada; os 3 itens que ele exigiu foram feitos depois (sem nova rodada, para poupar cota).
- Fase 1 continua com dois critérios abertos que dependem do Vitor (canto de atmosfera e 10 minutos de jogo).

- Equipe tem agora o **animador** (ADR-042), além do crítico. Primeira auditoria de animação feita (`docs/auditoria-animacao.md`): galinha zumbi sem aviso de ataque nem reação a dano (crítico), mago lançando sem preparação, pé da galinha invocada patinando. Nada corrigido ainda: aguarda o Vitor autorizar a ordem de trabalho.

## Próximo passo
0. Vitor olha o mago novo (prints e GIF em `evidencias/fase-2/mago_v2/`) e decide de que lado fica o cajado; depois, refinar o próximo modelo (galinha zumbi ou bigorna, escolha dele).
1. Vitor segue `docs/roteiro-de-teste.md` (reescrito para o ciclo da forja) e joga do começo ao fim no PC: achar runas, forjar 2 medalhões, usar na galinha, medir FPS com `ferramentas\medir_fps.bat`, e olhar se o HUD está legível.
2. Ajustar números (mana, recarga) a partir do que ele disser.
3. Quando a referência do HUD chegar: aplicar o estilo nas peças que já estão no lugar.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem (12 rodadas, 6 em paralelo, e com engasgo simulado). O teste foi deixado mais robusto (espera em quadros de física) e agora diz a distância da galinha se falhar. Se falhar no PC do Vitor, anotar essa distância.
- Névoa volumétrica e SDFGI só aparecem no PC do Vitor (a nuvem renderiza em Compatibility).

## Pendente do Vitor
- Animação: autorizar a ordem de trabalho da auditoria; decidir o tempo de aviso da bicada (proposta 0,25 s), se a galinha zumbi vira a galinha do piloto com esqueleto e se o mago passa a usar o modelo com esqueleto.
- Apagar o projeto `arcane-forge` no painel do Supabase (já pausado pelo Claude; a ferramenta dele não apaga) e revogar a chave da Groq que ficava guardada nele.
- **Referência visual do HUD e do medalhão, a ser gerada pelo Vitor** (o estilo do HUD espera por ela; ADR-033 pede a do medalhão antes da Fase 5).
- Jogar o ciclo da forja e opinar.
