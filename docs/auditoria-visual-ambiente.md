# Auditoria visual e técnica do ambiente (clareira)

22/10/2026 · Itens 1 a 4 aprovados pelo Vitor e aplicados no mesmo dia; itens 5 a 9 ficam para a Fase 5 (ADR-035, ADR-036).

## Achado principal
O problema percebido como "saturação excessiva" era, medido, **excesso de luz**. Antes do ajuste, a saturação média dos prints era igual à da referência (0,48 contra 0,52), mas o brilho médio era 0,83 contra 0,60, o contraste era metade e não havia nenhuma área escura. Baixar só a saturação teria deixado o cenário desbotado.

Medição: `python3 ferramentas/medir_cores.py PRINT.png` (compara com `docs/referencias/arte-conceito-01.png`).

## A. Diagnóstico visual (causas no código)
1. **Luz:** sol forte (1,35) + luz ambiente de cor chapada (0,55) + saturação e contraste globais aumentados no Environment. Nenhuma face ficava na sombra; a trilha estourava no branco.
2. **Cor:** grama (sat. 0,73), terra (0,64) e céu (0,87) todos acima de 0,6; nada "descansava".
3. **Terreno:** grade regular 100 x 100, mesma diagonal em todos os quadrados e tom sorteado por triângulo (vira xadrez no chão plano). `scripts/ambiente/clareira.gd`, `_criar_terreno`.
4. **Objetos:** todo o cenário sai das primitivas do Godot (pinheiro = 3 cones, pedra = esfera achatada, ruína = caixas); uma silhueta só por tipo. Não existem baús nem portais.
5. **Composição:** árvores e pedras sorteadas de forma uniforme num anel; centro de 20 m vazio; castelo como único foco e quase branco.
6. **Profundidade:** névoa fraca no meio e forte só no fundo; céu em gradiente liso.

## B. Diagnóstico técnico
- **Renderizador estava em Compatibility** (contrariando a proposta técnica e a ADR-031): névoa volumétrica e SDFGI nunca funcionaram. Corrigido para Forward+ (ADR-036).
- **"3 FPS":** o print foi tirado no PC do trabalho (GT 1030, abaixo do piso) e o contador do HUD mente nos primeiros segundos, enquanto a clareira é gerada. Medição dedicada nesse PC já tinha dado ~57 FPS. Falta medir na RTX 2060.
- **Triângulos por quadro: 400 a 615 mil** (medido pela `medir_fps`, nuvem), contra ~93 mil de malha. A sombra do sol redesenha a cena várias vezes e as malhas gigantes (árvores, pedras, grama cobrindo o mapa todo) nunca são descartadas pela câmera. Risco médio na RTX 2060; dividir em blocos é o item 6.
- Chamadas de desenho: média 60, máximo 130 (baixo, ok).
- Riscos menores: geração do mapa em GDScript ao abrir (travada inicial), tocha com sombra omnidirecional.

## C. Direção artística: paleta por camadas
| Camada | O quê | Saturação alvo |
|---|---|---|
| 0 Fundo | montanhas, castelo, nuvens | 0,15 a 0,35, puxando para o azul da névoa |
| 1 Chão | grama, encostas, trilha | grama 0,50 a 0,60; trilha 0,40 a 0,55 |
| 2 Estruturas | pedra, madeira, ruína | 0,15 a 0,45 |
| 3 Interativos | runas, barril de perigo, estandartes, baús | 0,65 a 0,85 |
| 4 Magia | projéteis, cristais, bigorna acesa | 0,8 a 1,0 com emissão; só ela passa do limiar do glow (1,0) |

Luz: sol quente vindo de oeste-sudoeste a 38°, luz ambiente vinda do céu (sombra fica fria sozinha), saturação global neutra. Geometria e composição (Fase 5): terreno sem padrão de grade, vegetação em grupos com 3 a 4 silhuetas, moldura no primeiro plano, castelo com luz de contorno como foco.

## D. Plano de evolução
| # | Item | Status |
|---|---|---|
| 1 | Medição confiável de FPS e de cor | **feito** (`ferramentas/medir_fps.bat` / `.sh`, `ferramentas/medir_cores.py`) |
| 2 | Renderizador Forward+ | **feito** (ADR-036) |
| 3 | Passe de luz e exposição | **feito**, falta conferir no PC com Forward+ |
| 4 | Paleta por camadas | **feito** (terreno, vegetação, fundo, céu, madeira) |
| 5 | Terreno: triangulação e lógica de cor | Fase 5 |
| 6 | Dividir malhas gigantes em blocos | Fase 5, ou antes se a RTX 2060 não bater a meta |
| 7 | Composição: bosques, moldura, focos | Fase 5 |
| 8 | Peças-chave no Blender (pinheiros, pedras, kit de ruína, castelo, baú) | Fase 5 |
| 9 | Céu pintado | Fase 5 |

## E. Estratégia de assets
- Código no Godot: terreno e distribuição (variam por expedição, ADR-018).
- Blender por script: peças com silhueta própria (vegetação, pedras, ruínas, castelo, baú, personagens; skill `personagem-low-poly`).
- Shader e Environment: luz, névoa, vento, água.
- Céu pintado: imagem gerada pelo Vitor + shader.
- Bibliotecas externas só como referência de proporção; geração de modelo por IA fora por enquanto.

## F. Plano de desempenho
`ferramentas\medir_fps.bat` no PC com a RTX 2060: 5 s de aquecimento descartados, 30 s de passeio e 30 s de combate com bolas de fogo sem parar. Comparar antes e depois de cada mudança; queda acima de 10% é investigada antes de seguir.

## G. Critérios de aceitação
Medidos:
- RTX 2060, 1080p: combate com média >= 60 FPS e "1% pior" >= 45.
- Nos 3 prints padrão: brilho médio 0,55 a 0,70; contraste >= 0,20; quase branco <= 20%; escuro >= 8%.
- Cor mais viva da tela vinda das camadas 3 ou 4.
- Até 150 mil triângulos de malha.

Avaliação do Vitor: lado a lado com a referência, teste de apertar os olhos (perto, meio e fundo separados) e teste de silhueta em preto e branco.

Prints padrão (`ferramentas/tirar_print.sh ... --espera 4`):
- spawn: `--posicao 0,1.6,8 --olhar 0,1.4,-10`
- ruínas: `--posicao -4,1.6,3 --olhar -15,2.5,-12`
- vale: `--posicao 1,1.6,-10 --olhar -4,9,-90`

## Resultado dos itens 1 a 4 (nuvem, render Compatibility)
| Print | Brilho | Contraste | Escuro | Quase branco | Critérios |
|---|---|---|---|---|---|
| Referência | 0,61 | 0,26 | 15% | 19% | |
| Antes (3 prints) | 0,80 a 0,83 | 0,13 a 0,14 | 0% | 26 a 35% | 0/4 |
| Depois (3 prints) | 0,60 a 0,64 | 0,13 a 0,17 | 1 a 2% | 1% | 2/4 |

Brilho e brancos estourados resolvidos. Contraste e áreas escuras **não** se resolvem só com luz: o chão plano ocupa metade da tela e recebe a mesma luz em todo lugar. Na referência, os escuros vêm de sombra de árvores sobre o caminho, moldura no primeiro plano e lados sombreados de volumes grandes, ou seja, dos itens 5 e 7. Evidências em `evidencias/fase-2/luz-paleta/`.
