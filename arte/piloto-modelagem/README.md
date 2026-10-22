# Piloto de modelagem (21/10/2026)

Teste pedido pelo Vitor: dá para modelar as peças do jogo por script no Blender, na nuvem, sem IA de 3D e sem depender do PC dele?

Três peças, escolhidas por serem de tipos diferentes:

| Peça | O que testa | Triângulos (no Godot) |
|---|---|---|
| Correntes arcanas saindo do chão | objeto repetido seguindo uma curva + efeito de essência (brilho arcano) | ~3.300 com o círculo de runa e as pedras |
| Molotov arcano | objeto de "torno" (garrafa), pano, chama | ~1.260 |
| Galinha | criatura com esqueleto e animação de andar | ~1.450 |

Resultado da conferência no Godot 4.7.2 (headless): os três `.glb` abrem sem erro; a galinha chega com `Skeleton3D` e a animação `Andar`.

## Como foi feito
- Blender 5.2.2 como módulo Python (`pip install bpy`, PyPI, licença GPL; usado só como ferramenta, nada dele vai dentro do jogo).
- Cada peça é um script em `scripts/`. Mudou uma medida, roda de novo, sai igual sempre.
- Render de conferência com Cycles na CPU (`renders/`), iterado olhando a imagem: corrente 4 versões, molotov 4, galinha 4 (a asa parecia uma mão com dedos na v3).

Rodar: `python scripts/galinha.py -- SAIDA heroi|poses|exportar` (e `EXPORTAR=1 python scripts/corrente.py -- SAIDA` para gerar o `.glb`).

## O que ainda não está bom
- Peças soltas presas aos ossos: para o jogo, juntar por osso e material (menos chamadas de desenho).
- Cores das prévias puxam para o azul por causa da luz de preenchimento do palco de render, não do modelo.
- A chama do molotov é estática; no jogo ela precisa de animação ou partículas.
- Estas peças não seguiram referências do Vitor (o piloto testou só a técnica). Nos lotes de verdade, ele entrega as referências antes.

## Lote 1: bigorna viva (21/10/2026)

Primeira peça feita a partir de uma referência do Vitor (`referencias/bigorna_folha_vitor.png`, gerada no ChatGPT a partir do prompt de folha de modelo).

- `scripts/bigorna.py` gera a bigorna inteira: base em degraus, corpo com chifres, coluna-martelo com runas, anel de pedras com arco de fogo.
- Três rostos como nós separados (`Rosto_neutro`, `Rosto_rindo`, `Rosto_raiva`): o jogo liga um por vez.
- Animações: `Orbita` (pedras girando, 8 s em loop) e `Tremer` (0,5 s, para quando a combinação não existe).
- Conferido no Godot 4.7.2: abre, com as duas animações e os três rostos.
- 6 rodadas de ajuste. Na v4 o rosto era uma placa retangular colada ("parecia uma TV"); na v5 ele passou a fazer parte do corpo.

Falta para o jogo: juntar as ~180 peças por material (menos chamadas de desenho), fogo animado com partículas no Godot e brilho (glow), que é efeito do Godot e não do modelo.

## Lote 2: mago chibi (21/10/2026)

Feito a partir de `referencias/mago_folha_vitor.png`. ~2.600 triângulos, ~1 m com o chapéu.

- `scripts/mago.py`: chapéu de aba larga com ponta torta, rosto escuro com olhos laranja brilhando, cachecol, manto com capinha e acabamento bege, cinto com bolsas, luvas, botas e cajado com cristal.
- Esqueleto com Raiz, Quadril, Tronco, Cabeca, BracoE/D, MaoE/D, PernaE/D. O cajado vai preso na MaoD.
- Animações: `Parado` (2 s, loop), `Andar` (1 s, loop), `Conjurar` (0,8 s) e `ErguerCajado` (0,9 s). Conferido no Godot 4.7.2.
- 7 rodadas: o rosto sumia sob a aba (v1), as mãos pareciam vassouras (v5), as poses eram tampadas pelas animações gravadas (v3) e cabeça e chapéu foram aumentados em 20% para ficar mais chibi (v7).

Falta para o jogo: o brilho da magia na mão ao conjurar (efeito de partículas no Godot), o manto não balança (peças rígidas) e as ~67 peças podem ser juntadas por osso e material.

## Lote 3: runas de quebra-cabeça (21/10/2026)

Feito a partir de `referencias/runas_folha_vitor.png`. 8 runas, ~600 triângulos cada (4.844 no total).

- `scripts/runas.py`: placa de pedra grossa com borda irregular e chanfro, e o símbolo por cima. Fogo, água, vida, feroz, gravitação, prende, arremesso e quebrar.
- Encaixe de verdade: dente na direita e em cima, fenda na esquerda e embaixo. Com as runas lado a lado a 0,3 m, o dente de uma entra na fenda da próxima (as 3 combinações do render estão encaixadas assim).
- Dois arquivos: `runas.glb` (apagadas) e `runas_acesas.glb` (pedra tingida e símbolo brilhando). Cada runa é um nó com a pedra e as partes do símbolo como filhos, então o jogo também pode só trocar o material para acender.
- 2 rodadas: na v1 pareciam peças de papelão e o símbolo de vida parecia um cata-vento.

Falta para o jogo: o halo de brilho em volta do símbolo aceso (efeito glow do Godot) e a animação de acender e se encaixar na bigorna.

## Lote 3b: runas refeitas (v2, 21/10/2026)

O Vitor achou a v1 sem esmero (formato de quebra-cabeça perfeito, símbolo colado, ícones básicos e descentralizados). `scripts/runas2.py` refaz do zero:

- Laje em pé com laterais em degrau complementares: bloco, dente e recuo na direita casam com recuo, fenda e bloco na esquerda (passo 0,93 unidade). Topo quebrado e base variam por runa.
- Símbolo entalhado por booleana (sulco de 7,5 mm com parede e fundo). Acesa: fundo na cor saturada e parede no tom claro.
- Chanfro largo, face facetada, rachaduras finas.
- Ícones redesenhados no traço da referência (chama pontuda com caracol, gota com miolo, broto com folhas, garras afiladas, espiral com rabo, dois elos, flecha curva com rastros, estrela partida) e centralizados pela massa da peça.
- 8 rodadas, comparando runa por runa com recortes da referência (`renders/runas_v2/comparacao_runas_v2.png`).

O que ainda separa da referência: pintura (luz e sombra pintadas na pedra, quinas claras, contorno escuro), brilho com halo (glow) e cor mais viva da pedra acesa. Cor chapada por face chegou no limite; o próximo passo é textura pintada (assar sombra e desgaste de quina) ou testar uma ferramenta de imagem para 3D.

## Lote 3c: runas v3, desenho traçado e luz própria (21/10/2026)

Pedido do Vitor: símbolos copiados da referência (não ícones vetoriais redesenhados) e runa acesa com luz própria.

- `scripts/tracar_runas.py` (OpenCV) recorta cada runa acesa da folha do Vitor, separa os pixels do símbolo por brilho, limpa e salva os contornos com furos em `tracos/tracos.json`, junto com uma versão encolhida do traço (o miolo da brasa). Limiar ajustado por runa e conferido visualmente; pedaços soltos são descartados pela distância ao centro do símbolo.
- A flecha (arremesso) não traçou bem (o halo grudava a ponta nos rastros); ela usa o desenho da v2.
- Acesa: sulco na cor saturada, brasa mais clara no fundo, borda tingida e uma luz pontual na cor do elemento (vira `OmniLight3D` no Godot; `runas_v3_acesas.glb` tem 8).
- Prévia com bloom do compositor e modo de cor "Standard" (o AgX desbotava as cores fortes). No jogo, o halo vem do glow do Godot.

Ainda falta: pintura da pedra (quinas iluminadas, sombra nos cantos) e a pedra apagada tem menos relevo que a referência.

## Lote 4: bigorna refeita (v7, 22/10/2026)

Pedido do Vitor: refazer a bigorna da forja com a mesma análise ponto a ponto das runas. `scripts/bigorna2.py` refaz do zero, comparando lado a lado com a folha dele (`scripts/comparar2.py`), em 10 rodadas.

- Proporções medidas na folha: chifres de ponta a ponta com 4,6 unidades, base de dois degraus com 0,8 de altura, cintura 17% mais alta que a primeira medida, coluna com núcleo de lava, fuste com runas R e 8, travessa de metal e cabeças de martelo grandes. Anel de 8 pedras grossas e pontudas, raio 2,15, inclinado 30°, com caudas de fogo de cometa.
- Rosto em blocos de pedra (mesmo desenho nas 3 expressões), com sobrancelha saltada. Olhos traçados da referência (`scripts/tracar_bigorna.py`, OpenCV). As bocas do rindo e da raiva foram desenhadas à mão sobre a grade ampliada da folha, porque o interior vermelho-escuro da boca não se separa da pedra iluminada por cor.
- Atrás do rosto há um nicho com fundo de lava, fogo na garganta e luz pontual. Nas costas, parede de blocos com uma boca de fogo embaixo. Runas nas 4 faces da coluna.
- Exportado em `modelos/bigorna_viva_v7.glb`: 18.857 triângulos, 4 luzes, animações `Orbita` e `Tremer`, nós `Rosto_neutro`, `Rosto_rindo` e `Rosto_raiva` (o jogo liga um). Conferido no Godot 4.7.2.
- Comparações em `renders/bigorna_v7/comparacao_v7_vistas.png` e `comparacao_v7_rostos.png`.

O que ainda separa da referência: pintura da pedra (rachaduras escuras, quinas claras, sombra nos cantos), o fogo do anel e da garganta é mais fino e menos volumoso (no jogo, glow e partículas ajudam), a vista de cima não tem o losango no topo da coluna. São 325 malhas soltas; antes de entrar no jogo, juntar por material para cortar chamadas de desenho.

## Para um patch futuro

- **Bigorna, boca neutra (22/10/2026):** o Vitor aprovou a bigorna como está para seguir em frente, mas quer arrumar a boca do rosto neutro depois, num patch. Não mexer agora.
