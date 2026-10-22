---
name: personagem-low-poly
description: Use ao criar ou refazer qualquer personagem ou criatura animada do Arcane Forge (mago, galinha, goblins, inimigos, invocações, bigorna viva) no Blender por script, da folha de referência do Vitor até o .glb conferido no Godot.
---

# Personagem low poly do Arcane Forge

Roteiro fixo para todo personagem sair com a mesma qualidade e sem pular etapa.
O estilo é low poly chibi, cores chapadas por face, tom absurdo (ADR-007, ADR-019),
mas **low poly não é tosco**: galinha tem cara de galinha, leão tem cara de leão.

Ferramentas já aprovadas: Blender como módulo Python (`pip install bpy`, GPL, só ferramenta),
scripts em `arte/piloto-modelagem/scripts/`, helpers em `base.py`
(`material`, `chapado`, `juntar`, `contar_triangulos`, `palco`, `camera`, `renderizar`,
`exportar_glb`, `ativar_brilho`). Nada de escultura nem retopologia: no nosso estilo a
malha já nasce leve, peça por peça (box modeling por código).

## 0. Antes de modelar: a folha do Vitor
O Vitor quer dar a referência antes de ver qualquer modelo. Escreva para ele um prompt de
**folha de modelo** (ele gera no ChatGPT) pedindo, na mesma imagem e no mesmo estilo de
`docs/referencias/arte-conceito-01.png`:
- frente, perfil e costas em pose neutra (T ou A), mesma escala, fundo liso;
- 3 expressões (neutro, feliz/rindo, bravo; o mago também espantado);
- detalhes de acessórios (chapéu, arma, cajado) soltos ao lado.
Salvar em `docs/referencias/` com nome padronizado (`<personagem>_folha_vitor.png`).
Sem folha aprovada, não modele: pergunte.

## 1. Proporção e silhueta (blocking)
- Monte só com blocos (caixas, cilindros, esferas de poucos lados) e renderize frente e perfil
  **lado a lado com a folha, na mesma escala**.
- Regra chibi do projeto: cabeça grande (no mago, cabeça + chapéu perto de metade da altura),
  pernas curtas, mãos e pés grandes o bastante para ler de longe.
- Teste de silhueta: render preto chapado sobre branco. Se não der para reconhecer o
  personagem só pela sombra, corrija antes de detalhar.
- Escala no mundo: mago ~1 m com chapéu; inimigos medidos em relação a ele.

## 2. Malha final
- Detalhe onde o olho para: rosto, mãos, acessório principal. Corpo e roupa com poucos planos.
- Rosto faz parte da cabeça (lição da bigorna: placa colada "parece uma TV").
- Mãos com dedos legíveis em grupos (lição do mago: mãos de vassoura).
- Expressões como nós separados (`Rosto_neutro`, `Rosto_rindo`, `Rosto_raiva`...) que o jogo liga
  um por vez, ou olhos/sobrancelhas em ossos próprios.
- Orçamento: até ~3.000 triângulos para personagem principal, ~1.500 para inimigo comum.
- Paleta: respeite as camadas de cor de `docs/auditoria-visual-ambiente.md` (seção C).
  Personagem é camada 2 a 3; brilho próprio (emissão) só em magia, olhos mágicos e cristais.

## 3. UV e molde para o Vitor pintar
Só quando a fase pedir textura pintada (Fase 5) ou o Vitor pedir:
- abrir UV por partes lógicas (rosto, corpo, roupa, acessório), ilhas retas e sem esticar;
- molde PSD 1024x1024 (potência de 2) com as áreas marcadas e nomeadas, mais uma camada de
  brilho em preto e branco (fluxo do CLAUDE.md);
- especificação curta: o que vai em cada área, de que cor, com que luz pintada.

## 4. Esqueleto e animação
- Nomes de ossos padronizados (iguais aos do mago e da galinha): `Raiz`, `Quadril`, `Tronco`,
  `Cabeca`, `BracoE/D`, `MaoE/D`, `PernaE/D`; extras com o mesmo padrão (`AsaE`, `Rabo`, `Chapeu`).
- Peças rígidas presas a um osso (sem pintura de peso) são o padrão; pintura de peso só para
  partes que precisam dobrar (manto, barriga). Depois, **juntar as peças por osso e material**
  (menos chamadas de desenho).
- Animações mínimas: `Parado` (loop), `Andar` (loop), uma de ação (`Atacar`/`Conjurar`) e uma de
  reação (`Dano`). Exagere: pose forte, antecipação e volta (o Vitor quer expressividade,
  principalmente nos olhos).
- Cuidado já visto: poses de teste tampadas por animações gravadas; confira cada ação isolada.

## 5. Exportar e conferir no Godot
1. `exportar_glb(...)` para `jogo/assets/modelos/<pasta>/<nome>.glb`.
2. `godot --headless --editor --quit --path jogo` (reimporta) e confira: abre sem erro, chega com
   `Skeleton3D`, as animações certas e os nós de expressão.
3. Print no jogo com `ferramentas/tirar_print.sh` (perto e na distância de combate) e na
   luz da arena, não só no palco do Blender.

## 6. Entrega ao Vitor (obrigatório)
Antes de entregar, análise ponto a ponto contra a folha, lado a lado e na mesma escala:
silhueta e proporção, profundidade e relevo, detalhe de superfície, rosto e expressões,
cores, animação. Para cada diferença: a causa e como corrigir. Só entregar quando estiver
à altura; nunca destacar só o que bateu. Registrar rodadas e lições no README do piloto.
