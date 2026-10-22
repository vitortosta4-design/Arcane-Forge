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
