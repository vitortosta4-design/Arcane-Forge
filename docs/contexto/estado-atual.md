# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 13/11/2026, manhã (caverna da forja, etapas 1 e 2 pela folha)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035). O ciclo roda e tem teste de ponta a ponta; da fase só falta o que é do Vitor (jogar, achar divertido, medir FPS).
- Tudo de 12/11 está no `main`.
- **Gigante da árvore: encerrado na 7ª rodada por decisão do Vitor (12/11).** Crítico 7,5, reprovado por costas e perfil; o Vitor aceitou como está, por ser evento raro visto de longe. Não abrir 8ª rodada sem ele pedir. O que o crítico ainda apontou está em `evidencias/fase-2/critico_12-11-2026.md` (costas com pouco musgo, perfil sem rosto, aresta no pulso, musgo claro no jogo, pé curto de lado). 3.182 triângulos.
- Auditoria de animação, feitos: mago lança com preparação de 0,1 s; impacto com peso; bigorna com martelo e som (aprovados pelo Vitor); galinha cancela a bicada se apanhar no aviso (**ADR-048, revogável**).
- **Galinha v4: crítico 8,0, aprovada.** Ao apanhar pisca branca por 0,08 s; a zumbi incha, tomba para trás e treme no aviso da bicada (aviso x andar foi de 0,98 para 1,47 em pixels mudados). Asas ficam bem abertas no aviso (decisão do Vitor).
- HUD (crítico 8,0), mago com esqueleto (8,4) e runas v6 (6,5, esperando símbolos) seguem como estavam.
- **Mago assenta ao parar (auditoria, item 6):** o corpo inclina 7 graus para onde anda e, ao parar ou arrancar, balança numa mola e agacha 5%; em 1ª pessoa as mãos descem 1,7 cm e voltam. É só visual: a velocidade continua respondendo no mesmo quadro (tem teste). **Sem nota do crítico:** nas folhas de quadros da nuvem o efeito quase não aparece; quem julga é o Vitor em movimento.
- **Caverna da forja, etapas 1 e 2 (ADR-049), pela folha `docs/referencias/lote02/lote02_09_caverna_forja.png`:** câmara grande (raio 26 m, teto a 19,5 m), bigorna com 10 m (3,5 magos; `ESCALA_BIGORNA`), piso de lajotas em anéis, linhas e losangos de runa acesos, pedestal de dois degraus em rampa, 4 lanternas de pedra com luz, cerca de postes com lanterna e corrente, cristais roxos, cipós pequenos, **fundo aberto** do lado oposto à entrada (céu de caverna azul, colunas, 7 ilhas flutuantes com cristais, cachoeiras azuis e quedas de lava; parede invisível ali) e **ar próprio** (a câmera troca de ambiente abaixo de y -40: escuro, roxo, sem a névoa azul de fora). Decisões do Vitor em 13/11: abertura no teto fica de fora (`COM_ABERTURA_NO_TETO` falso); proporções corrigidas a pedido dele. **Falta:** móveis do posto, passarelas e escadas do fundo, água e lava paradas (sem movimento). Sem nota do crítico ainda.
- Testes: 443/443 (11 do gigante, 14 da galinha, 13 do mago, 26 da caverna).

## Próximo passo
0. **Caverna, etapa 3:** móveis do posto (estantes com runas, baú, barris, caixotes, mesa do grimório, estandartes com o losango), depois passarelas e escadas, e dar movimento às cachoeiras e à lava. Rodar o crítico quando os móveis entrarem. **Sempre abrir a folha antes de modelar cenário** (listar `docs/referencias` e `lote02`).
1. Vitor e Matheus jogam o pacote (`build/ArcaneForge_teste_Matheus.zip`; a pasta `build/` não vai para o git, gerar com `ferramentas/gerar_pacote_teste.sh`) e respondem as 4 perguntas do LEIA-ME.
2. Auditoria de animação, o que sobrou: medalhão nascendo e voando até a barra (precisa da referência do medalhão); som de passo do mago (fase de áudio).
3. Runas: montar as 8 quando os símbolos chegarem.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem. Se falhar no PC do Vitor, anotar a distância que ele imprime.
- Névoa volumétrica, SDFGI, brilho da explosão, do martelo, dos olhos da zumbi e dos olhos do gigante só aparecem de verdade no PC do Vitor (a nuvem renderiza em Compatibility).
- O gigante de perto fica fora da névoa de distância e a silhueta distante não: pode haver salto de cor na troca (52 m).
- Gigante: a mão é uma malha fundida por voxel e reduzida (`fundir` em `gigante_arvore.py`); as facetas dela são menos regulares que as do resto do corpo.
- Sessão na nuvem nova precisa baixar de novo os modelos de exportação do Godot (1,2 GB, GitHub) para gerar o pacote.

## Pendente do Vitor
- **Caverna:** ver no PC dele a cor, o brilho e o FPS dentro da câmara (ficou bem maior e com fundo aberto); dizer se a escala agora está certa.
- **Só dá para conferir no PC dele:** se o balanço do mago ao parar e arrancar agrada, é pouco ou enjoa (botões no topo de `visual_mago.gd`: `INCLINACAO_ANDAR`, `AGACHAR_NA_PARADA`, `MOLA_AMORTECIMENTO`; mãos em `maos_primeira_pessoa.gd`); se o clarão branco da galinha sai branco de verdade (na nuvem sai 214 de 255) e se o tremor do aviso da zumbi parece tremor ou falha; brilho dos olhos do gigante e se o rosto fica bom com a névoa de verdade; se o 0,1 s de preparação do mago parece atraso; se a tremida da explosão incomoda; a troca de cor do gigante a 52 m; FPS (`ferramentas\medir_fps.bat`).
- ADR-048: confirmar ou revogar depois de jogar.
- Runas: símbolos de gravitação, arremesso e quebrar; pedra acesa tingida ou cinza.
- Referência do medalhão em close (ADR-033), que também destrava a animação do medalhão.
- Apagar o projeto `arcane-forge` no Supabase e revogar a chave da Groq guardada nele.
- Fase 1: canto de atmosfera e 10 minutos de jogo.
