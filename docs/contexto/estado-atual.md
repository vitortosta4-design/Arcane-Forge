# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 13/11/2026, manhã (luz da caverna aprovada; entrada refeita, 1ª passada)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035). O ciclo roda e tem teste de ponta a ponta; da fase só falta o que é do Vitor (jogar, achar divertido, medir FPS).
- Tudo de 12/11 está no `main`.
- **Gigante da árvore: encerrado na 7ª rodada por decisão do Vitor (12/11).** Crítico 7,5, reprovado por costas e perfil; o Vitor aceitou como está, por ser evento raro visto de longe. Não abrir 8ª rodada sem ele pedir. O que o crítico ainda apontou está em `evidencias/fase-2/critico_12-11-2026.md` (costas com pouco musgo, perfil sem rosto, aresta no pulso, musgo claro no jogo, pé curto de lado). 3.182 triângulos.
- Auditoria de animação, feitos: mago lança com preparação de 0,1 s; impacto com peso; bigorna com martelo e som (aprovados pelo Vitor); galinha cancela a bicada se apanhar no aviso (**ADR-048, revogável**).
- **Galinha v4: crítico 8,0, aprovada.** Ao apanhar pisca branca por 0,08 s; a zumbi incha, tomba para trás e treme no aviso da bicada (aviso x andar foi de 0,98 para 1,47 em pixels mudados). Asas ficam bem abertas no aviso (decisão do Vitor).
- HUD (crítico 8,0), mago com esqueleto (8,4) e runas v6 (6,5, esperando símbolos) seguem como estavam.
- **Mago assenta ao parar (auditoria, item 6):** o corpo inclina 7 graus para onde anda e, ao parar ou arrancar, balança numa mola e agacha 5%; em 1ª pessoa as mãos descem 1,7 cm e voltam. É só visual: a velocidade continua respondendo no mesmo quadro (tem teste). **Sem nota do crítico:** nas folhas de quadros da nuvem o efeito quase não aparece; quem julga é o Vitor em movimento.
- **Caverna da forja, etapas 1 a 3 (ADR-049), pela folha `docs/referencias/lote02/lote02_09_caverna_forja.png`. Crítico: 5,5/10, reprovado** (era 4; avaliou a etapa 5 antes dos dois últimos consertos). Tem: câmara de raio 26 m, bigorna de 10 m (3,5 magos, aprovado pelo Vitor), piso de lajotas em anéis, linhas de runa, pedestal em rampa, lanternas, cerca na frente e no abismo, cristais, fundo aberto (ilhas, cachoeiras, lava, parede invisível), ar próprio da caverna e os **móveis do posto** em `moveis_da_forja.gd` (2 estantes com tábuas de runa, livros e poções; 4 estandartes; mesa do grimório; mesa de trabalho; baú, barris, caixotes; 126 livros; 105 velas; 6 lanternas penduradas; mirante com rampa na beira do abismo), tudo em duas malhas. Depois do crítico a paleta foi esquentada (pedra menos roxa, mais luz laranja). Decisões do Vitor: sem abertura no teto; escala aprovada; "encher de detalhe".
- **Caverna, etapa 4 (depois do crítico, sem nova nota):** os móveis foram juntados em dois blocos encostados na parede (96 e -92 graus), cada um dentro de um andaime de madeira de dois andares com escada (rampa com colisão), passarela com corrimão, travessas em X, correntes em arco com lanterna e uma segunda estante em cima; e **livros voadores** (`livros_voadores.gd`: 6 livros que decolam de cima de uma estante, batem as capas e pousam em outra; só enfeite, não sincronizado no cooperativo).
- **Caverna, etapa 5:** quedas de lava e de água com faixas descendo (`shaders/queda.gdshader`), lava escorrendo pela parede de dentro dos dois lados do fundo, com poça, pedras e luz; faixas do piso viraram sulcos finos rentes ao chão com rachaduras laterais, e junto com as linhas de runa pulsam a partir da bigorna (`shaders/brasa_viva.gdshader`); rachaduras de lava descendo o pedestal. Depois do crítico: frestas do pedestal fechadas, fundo escuro sob as lajotas (vira rejunte) e estalactites fora do miolo da câmara.
- **Caverna, etapa 6 (pedido do Vitor, que disse que o resto "está ótimo"):** plataformas e pontes distantes no fundo (6 pontes de tábua com corda entre as ilhas e até a beirada, 3 plataformas em anel nas colunas com casinha e lanternas) e cristais refeitos em cachos pequenos (8 pontas curtas, corpo e ponta em tons diferentes; o maior tem menos de 3,6 m). Sem nova nota do crítico (a última é 5,5).
- **Som ambiente da forja: 5 rascunhos para o Vitor ouvir** em `evidencias/fase-2/audio/` (martelada com eco de caverna, poções borbulhando, páginas virando, fogo crepitando e a mistura de 45 s em estéreo), gerados por `ferramentas/gerar_ambiente_forja.py`. **Ainda não estão no jogo**: esperam a opinião dele.
- Testes: 461/461 (11 do gigante, 14 da galinha, 13 do mago, 44 da caverna). **A suíte leva uns 45 s**; o limite do `rodar_testes.sh` é 120 s.

## Próximo passo
- **REGRA: luz, cor, brilho e névoa DENTRO DA CAVERNA se conferem com `ferramentas/tirar_print_forward.sh`** (Forward+ por Vulkan de software; o hook de sessão já instala o `mesa-vulkan-drivers`, aprovado pelo Vitor em 13/11). **Ao ar livre esse print sai enevoado e esbranquiçado e não bate com o PC do Vitor** (névoa volumétrica e SDFGI não assentam em poucos quadros): lá fora, forma se confere em Compatibility e cor só com print dele.
- **Entrada da caverna (1ª passada, 13/11):** refeita pela referência `docs/referencias/caverna_entrada_referencia.png` (arco de pedregulhos com runa, pilares com runa, cipós, 2 estandartes, 2 braseiros com luz, cristais, túnel roxo de 7,5 m, caminho de lajes, pedras, cogumelos, flores). Tem as peças, **não tem a qualidade da referência**: as pedras são bolas facetadas claras, sem cor pintada nem luz macia. O Vitor perguntou o que seria preciso para chegar lá mesmo mudando diretrizes; a resposta e a decisão dele estão pendentes (piloto proposto: pedras esculpidas no Blender, cor por vértice com sombra de contato, luz macia no lugar do toon de 3 faixas, vegetação densa; só na entrada, medindo FPS).
0. **Caverna: o Vitor considera o resto ótimo.** Não mexer mais em pedestal, livros voadores, lanternas ou piso sem ele pedir. Só fica pendente o acerto de cor, com o print do PC dele (o crítico mediu laranja demais: saturação 0,77 a 0,88 contra 0,53 da folha). **Som ambiente:** quando ele aprovar os rascunhos, pôr no jogo como sons em laço posicionados na câmara (fogo na bigorna, poções na estante de poções, páginas perto das estantes, marteladas na bigorna), registrar em `docs/creditos-audio.md` e ligar ao barramento de eco da caverna previsto para a fase de áudio. **Sempre abrir a folha antes de modelar cenário** (listar `docs/referencias` e `lote02`).
1. Vitor e Matheus jogam o pacote (`build/ArcaneForge_teste_Matheus.zip`; a pasta `build/` não vai para o git, gerar com `ferramentas/gerar_pacote_teste.sh`) e respondem as 4 perguntas do LEIA-ME.
2. Auditoria de animação, o que sobrou: medalhão nascendo e voando até a barra (precisa da referência do medalhão); som de passo do mago (fase de áudio).
3. Runas: montar as 8 quando os símbolos chegarem.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem. Se falhar no PC do Vitor, anotar a distância que ele imprime.
- **Caverna estourava em branco no jogo de verdade** (print do Vitor no PC do serviço, 13/11): as luzes tinham sido calibradas no Compatibility, que acende no máximo 8 luzes por malha e não tem brilho. Refeito no Forward+: luzes cortadas para um terço ou menos, brilho contido no ar da caverna (`glow_intensity` 0,8, limiar 1,1), exposição 0,85, SDFGI desligado lá dentro. **Falta o Vitor confirmar no PC dele.** Os prints `caverna_etapa*` são do Compatibility e não mostram a cor real; os `caverna_forward_*` mostram.
- Névoa volumétrica, SDFGI, brilho da explosão, do martelo, dos olhos da zumbi e dos olhos do gigante só aparecem de verdade no PC do Vitor (a nuvem renderiza em Compatibility).
- O gigante de perto fica fora da névoa de distância e a silhueta distante não: pode haver salto de cor na troca (52 m).
- Gigante: a mão é uma malha fundida por voxel e reduzida (`fundir` em `gigante_arvore.py`); as facetas dela são menos regulares que as do resto do corpo.
- Sessão na nuvem nova precisa baixar de novo os modelos de exportação do Godot (1,2 GB, GitHub) para gerar o pacote.

## Pendente do Vitor
- **Sons da forja:** ouvir os 5 rascunhos e dizer o que muda (volume da martelada, ritmo, timbre) antes de entrarem no jogo.
- **Cara da bigorna:** ele acha estranha desde o começo e quer mexer nela mais para a frente (13/11). Não mexer antes de ele trazer a direção ou uma folha nova.
- **Caverna:** luz de dentro aprovada pelo Vitor (13/11, "boa"). Falta o FPS lá dentro.
- **Entrada da caverna:** decidir o caminho de qualidade (piloto com mudança de diretriz ou não) e mandar um print da entrada nova no PC dele.
- **Sons da forja (candidatos CC0):** escolher um de cada letra (A martelada, B poções, C páginas, D fogo) entre os 9 que recebeu.
- **Só dá para conferir no PC dele:** se o balanço do mago ao parar e arrancar agrada, é pouco ou enjoa (botões no topo de `visual_mago.gd`: `INCLINACAO_ANDAR`, `AGACHAR_NA_PARADA`, `MOLA_AMORTECIMENTO`; mãos em `maos_primeira_pessoa.gd`); se o clarão branco da galinha sai branco de verdade (na nuvem sai 214 de 255) e se o tremor do aviso da zumbi parece tremor ou falha; brilho dos olhos do gigante e se o rosto fica bom com a névoa de verdade; se o 0,1 s de preparação do mago parece atraso; se a tremida da explosão incomoda; a troca de cor do gigante a 52 m; FPS (`ferramentas\medir_fps.bat`).
- ADR-048: confirmar ou revogar depois de jogar.
- Runas: símbolos de gravitação, arremesso e quebrar; pedra acesa tingida ou cinza.
- Referência do medalhão em close (ADR-033), que também destrava a animação do medalhão.
- Apagar o projeto `arcane-forge` no Supabase e revogar a chave da Groq guardada nele.
- Fase 1: canto de atmosfera e 10 minutos de jogo.
