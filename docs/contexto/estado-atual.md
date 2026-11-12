# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 12/11/2026 (auditoria de animação, itens 1 a 4 feitos; crítico com medição na galinha e no gigante)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035). O ciclo roda e tem teste de ponta a ponta; da fase só falta o que é do Vitor (jogar, achar divertido, medir FPS).
- **Feito em 12/11 (um commit cada, evidências em `evidencias/fase-2/animacao/*_v2*`):**
  1. Mago lança com preparação: corpo recolhe no clique, magia sai 0,1 s depois (`PREPARACAO_S`).
  2. Impacto com peso: explosão com clarão, estouro que freia, anel e lascas; tremida de câmera por distância; projétil nasce pequeno.
  3. Bigorna: martelo fantasma (visual provisório em código) bate em 0,29 s com som, clarão e faíscas. Som provisório gerado por `ferramentas/gerar_som_martelo.py`.
  4. Galinha: apanhar durante o aviso cancela a bicada (**ADR-048, revogável** em uma constante).
- **Crítico, rodada única com medição** (`evidencias/fase-2/critico_12-11-2026.md`), nada corrigido depois:
  - Galinha v4: **6,5, reprovada por pouco**. Proporções batem com o piloto. Falta: aviso da bicada legível de frente, asa colada no corpo, dano com mais recuo, zumbi destacada da grama.
  - Gigante da árvore: **3/10, reprovado**. Cor no jogo errada (tronco azulado, copa acinzentada), braço em tábua sem mão, copa 32% da altura contra 47% da folha, pouco musgo, pés estreitos.
- HUD (ADR-039, crítico 8,0), mago com esqueleto (crítico 8,4) e runas v6 (crítico 6,5, reprovado, esperando símbolos) seguem como estavam.
- Testes: 363/363.

## Próximo passo
1. Vitor e Matheus jogam o pacote novo (`build/ArcaneForge_teste_Matheus.zip`, gerado em 12/11; a pasta `build/` não vai para o git, gerar de novo com `ferramentas/gerar_pacote_teste.sh`) e respondem as 4 perguntas novas do LEIA-ME.
2. Vitor decide o que fazer com as duas reprovações (ver "Pendente do Vitor").
3. Auditoria de animação, o que sobrou: pé da galinha invocada patinando (conferir se a v4 já resolveu), mago andando e parando seco, medalhão nascendo e voando até a barra (precisa da referência do medalhão).
4. Runas: montar as 8 quando os símbolos chegarem.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem. Se falhar no PC do Vitor, anotar a distância que ele imprime.
- Névoa volumétrica, SDFGI, brilho da explosão, do martelo e dos olhos da zumbi só aparecem de verdade no PC do Vitor (a nuvem renderiza em Compatibility).
- Prints "de frente" da galinha em `evidencias/fase-2/galinha/` estão girados (achado do crítico); `arvore_gigante_perto.png` é da árvore antiga.

## Pendente do Vitor
- **Só dá para conferir no PC dele:** se o 0,1 s de preparação do mago parece atraso; se a tremida da explosão incomoda; volume e timbre do som do martelo; FPS (`ferramentas\medir_fps.bat`).
- **Decisão de arte:** o martelo da bigorna é provisório (feito em código). Aprovar assim, pedir outro desenho ou mandar referência.
- **Galinha (6,5):** autorizar uma rodada de correção do aviso de frente, da asa e do dano, ou aceitar como está por enquanto.
- **Gigante da árvore (3/10):** autorizar refazer por medição (cor, braço com mão, copa, musgo, pés), ou adiar (é evento raro, fora do ciclo principal).
- ADR-048: confirmar ou revogar depois de jogar.
- Runas: símbolos de gravitação, arremesso e quebrar; pedra acesa tingida ou cinza.
- Referência do medalhão em close (ADR-033), que também destrava a animação do medalhão.
- Apagar o projeto `arcane-forge` no Supabase e revogar a chave da Groq guardada nele.
- Fase 1: canto de atmosfera e 10 minutos de jogo.
