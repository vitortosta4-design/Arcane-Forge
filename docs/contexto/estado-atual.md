# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 12/11/2026, fim da tarde (auditoria de animação itens 1 a 4; depois martelo, som, rodada da galinha e 6ª rodada do gigante)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035). O ciclo roda e tem teste de ponta a ponta; da fase só falta o que é do Vitor (jogar, achar divertido, medir FPS).
- **Tudo de 12/11 está no ramo `auditoria-animacao-itens-1-4`, ainda não no `main`** (falta o Vitor dizer se junta).
- Auditoria de animação, feitos: mago lança com preparação de 0,1 s; impacto com peso (explosão, tremida, projétil nasce pequeno); bigorna com martelo (aprovado pelo Vitor, agora batendo com a face) e som provisório; galinha cancela a bicada se apanhar no aviso (**ADR-048, revogável**).
- **Som:** tudo mais baixo e suave a pedido do Vitor (trilha de efeitos -6 dB com filtro de agudos; explosão -9 dB). Botões em `GerenciadorSom.VOLUME_DB` e `default_bus_layout.tres`.
- **Galinha v4: crítico 7,5, aprovada com ressalvas** (aviso de frente com asas abertas, asa presa no ombro, dano com recuo, zumbi pálida).
- **Gigante da árvore: refeito pela folha, crítico 6,5, ainda reprovado.** Proporções e cor no jogo batem com a folha; ele agora anda de frente. Falta: mão como luva única com dedos curvos, ninho trançado com pássaro azul, musgo deitado abraçando os membros (26% do corpo, está em 18%), rosto mais claro na sombra da copa, pé mais cheio de perfil.
- HUD (crítico 8,0), mago com esqueleto (8,4) e runas v6 (6,5, esperando símbolos) seguem como estavam.
- Testes: 379/379. Relatórios do crítico: `evidencias/fase-2/critico_12-11-2026.md`.

## Próximo passo
1. **Gigante, mais uma rodada** (o Vitor mandou terminar): mão, ninho, musgo, rosto e perfil, na ordem do crítico; refazer o GIF e o print de lado sem árvore na frente.
2. Vitor e Matheus jogam o pacote (`build/ArcaneForge_teste_Matheus.zip`; a pasta `build/` não vai para o git, gerar com `ferramentas/gerar_pacote_teste.sh`) e respondem as 4 perguntas novas do LEIA-ME.
3. Galinha, ressalvas do crítico: clarão branco no dano, aviso da zumbi maior que o andar dela, asas inclinadas no aviso.
4. Auditoria de animação, o que sobrou: mago andando e parando seco, medalhão nascendo e voando até a barra (precisa da referência do medalhão).
5. Runas: montar as 8 quando os símbolos chegarem.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem. Se falhar no PC do Vitor, anotar a distância que ele imprime.
- Névoa volumétrica, SDFGI, brilho da explosão, do martelo e dos olhos da zumbi só aparecem de verdade no PC do Vitor (a nuvem renderiza em Compatibility).
- O gigante de perto fica fora da névoa de distância e a silhueta distante não: pode haver salto de cor na troca (52 m).

## Pendente do Vitor
- Dizer se o ramo `auditoria-animacao-itens-1-4` entra no `main`.
- **Só dá para conferir no PC dele:** se o 0,1 s de preparação do mago parece atraso; se a tremida da explosão incomoda; se o som ficou baixo e suave o bastante; se a troca de cor do gigante a 52 m incomoda; FPS (`ferramentas\medir_fps.bat`).
- ADR-048: confirmar ou revogar depois de jogar.
- Galinha: o aviso de frente ficou em "T" (asas bem abertas, como ele sugeriu); dizer se gosta ou se quer as asas inclinadas para a frente.
- Runas: símbolos de gravitação, arremesso e quebrar; pedra acesa tingida ou cinza.
- Referência do medalhão em close (ADR-033), que também destrava a animação do medalhão.
- Apagar o projeto `arcane-forge` no Supabase e revogar a chave da Groq guardada nele.
- Fase 1: canto de atmosfera e 10 minutos de jogo.
