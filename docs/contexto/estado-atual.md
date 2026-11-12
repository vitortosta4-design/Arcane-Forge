# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 12/11/2026, noite (7ª rodada do gigante da árvore)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035). O ciclo roda e tem teste de ponta a ponta; da fase só falta o que é do Vitor (jogar, achar divertido, medir FPS).
- Tudo de 12/11 está no `main`.
- **Gigante da árvore, 7ª rodada: crítico 7,5, ainda reprovado (era 6,5).** A frente o crítico aprovaria sozinha: mão em luva única, ninho trançado com pássaro azul de bico laranja, musgo em placas deitadas (25% do corpo, folha 24% pelo mesmo método), rosto claro (0,53 contra 0,55 da folha) com olhos em meia-lua e brilho, peito e barriga com volume. Reprovou por costas e perfil. 3.182 triângulos. Parei aqui: o combinado era uma rodada só.
- Auditoria de animação, feitos: mago lança com preparação de 0,1 s; impacto com peso; bigorna com martelo e som (aprovados pelo Vitor); galinha cancela a bicada se apanhar no aviso (**ADR-048, revogável**).
- Galinha v4: crítico 7,5, aprovada com ressalvas; asas ficam bem abertas no aviso (decisão do Vitor).
- HUD (crítico 8,0), mago com esqueleto (8,4) e runas v6 (6,5, esperando símbolos) seguem como estavam.
- Testes: 390/390 (11 novos do gigante). Relatórios do crítico: `evidencias/fase-2/critico_12-11-2026.md`.

## Próximo passo
1. **Vitor decide se o gigante ganha uma 8ª rodada** (ver "Pendente do Vitor"). Se sim, na ordem do crítico: vestir as costas (placa do ombro, tornozelos por trás, dorso dos antebraços, meta 20% de verde, está 13,8%); dar rosto ao perfil (a copa cobre a cabeça de lado) e tirar a aresta do pulso; musgo mais escuro no jogo (está 122,174,70, folha 94,142,36), placa do antebraço com contorno quebrado, capa nos dois ombros; pé mais comprido de lado (0,15 contra 0,23).
2. Vitor e Matheus jogam o pacote (`build/ArcaneForge_teste_Matheus.zip`; a pasta `build/` não vai para o git, gerar com `ferramentas/gerar_pacote_teste.sh`) e respondem as 4 perguntas do LEIA-ME.
3. Galinha, ressalvas do crítico: clarão branco no dano e aviso da zumbi maior que o andar dela.
4. Auditoria de animação, o que sobrou: mago andando e parando seco, medalhão nascendo e voando até a barra (precisa da referência do medalhão).
5. Runas: montar as 8 quando os símbolos chegarem.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem. Se falhar no PC do Vitor, anotar a distância que ele imprime.
- Névoa volumétrica, SDFGI, brilho da explosão, do martelo, dos olhos da zumbi e dos olhos do gigante só aparecem de verdade no PC do Vitor (a nuvem renderiza em Compatibility).
- O gigante de perto fica fora da névoa de distância e a silhueta distante não: pode haver salto de cor na troca (52 m).
- Gigante: a mão é uma malha fundida por voxel e reduzida (`fundir` em `gigante_arvore.py`); as facetas dela são menos regulares que as do resto do corpo.
- Sessão na nuvem nova precisa baixar de novo os modelos de exportação do Godot (1,2 GB, GitHub) para gerar o pacote.

## Pendente do Vitor
- **Decisão de arte no gigante:** (a) 8ª rodada para costas e perfil, como o crítico pede; (b) aceitar como está, já que é evento raro visto de longe; (c) 8ª rodada só das costas (o mais barato e o que mais aparece quando ele vai embora).
- **Só dá para conferir no PC dele:** brilho dos olhos do gigante e se o rosto fica bom com a névoa de verdade; se o 0,1 s de preparação do mago parece atraso; se a tremida da explosão incomoda; a troca de cor do gigante a 52 m; FPS (`ferramentas\medir_fps.bat`).
- ADR-048: confirmar ou revogar depois de jogar.
- Runas: símbolos de gravitação, arremesso e quebrar; pedra acesa tingida ou cinza.
- Referência do medalhão em close (ADR-033), que também destrava a animação do medalhão.
- Apagar o projeto `arcane-forge` no Supabase e revogar a chave da Groq guardada nele.
- Fase 1: canto de atmosfera e 10 minutos de jogo.
