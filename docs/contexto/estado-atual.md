# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 29/10/2026 (galinha v4 no jogo; gigante da árvore, 4ª rodada: crítico 3/10 → corrigido)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035). O ciclo inteiro já roda e tem teste de ponta a ponta; da fase só falta o que é do Vitor (jogar, achar divertido, medir FPS).
- **HUD no estilo da referência aprovada** (`docs/referencias/hud-referencia-01.png`, ADR-039): retrato com o modelo do mago em aro dourado, barras de metal com ponta cortada, estados em ícones, mira de 4 tracinhos, vida do inimigo só depois do acerto, 4 medalhões redondos com a runa acesa e recarga em sombra de relógio, minimapa de verdade. Crítico: 6,5 (reprovado) → 8,0 (aprovado).
- **Mago com esqueleto** (ADR-043/045) já está no `main` (ramo `mago-criticas` incorporado): modelo da folha do Vitor, dedos de dois ossos, 5 animações, braços 1ª pessoa com ondinha. Crítico 8,4 aprovado. Pendências aceitas: lapelas e casaco esvoaçando.
- **Galinha v4 no jogo** (29/10/2026): `arte/personagens/galinha/galinha.py` põe esqueleto (11 ossos, peças rígidas) e 5 animações no `galinha_v4.glb` do piloto MCP, sem mudar malha (1.148 tri). O mesmo modelo (`jogo/assets/modelos/galinha/galinha.glb`, via `VisualGalinha`) serve a galinha invocada e a zumbi (variante verde acinzentada, olhos acesos, 2 penas a menos, andar torto e manco). Bicada com aviso de 0,4 s e dano aos 0,47 s; morta, tomba quase de costas com as pernas para cima e some em 2,2 s. Pé no Andar desliza no máximo 0,38 m/s com o chão a 3,5 m/s (medido em teste). Crítico 5,5 e animador "perto do padrão, reprovada" na 1ª rodada; corrigido uma vez (asas abrindo para fora, aviso mais legível, bote sem virar a cabeça, morte de pernas para o céu, penas em losango, pausa no golpe), **sem nova rodada** por economia de cota. O que faltou está no diário.
- **Runas pelo vetor do Vitor** (ramo `runas-contorno-svg`): contorno dele nas 8; faltam os símbolos gravitação, arremesso e quebrar. **Runas v6 no jogo** (`runas_v4_acesas.glb`): crítico 5 → 6 → 6,5 (reprovado).
- **Gigante da árvore (ADR-047) pela skill `personagem-low-poly`**: modelo em Blender com esqueleto de verdade (`arte/personagens/gigante_arvore/gigante_arvore.py`, 1.716 triângulos) e animações `Parado`/`Andar` (sem `Atacar`/`Dano`: a árvore não ataca nem reage a dano), integrado no jogo (`jogo/scripts/eventos/arvore_gigante.gd`). 4 rodadas até aqui: 1ª reprovada (braços sumindo na silhueta), 2ª consertou mas exagerou (pernas largas, copa pequena, braços longe demais, pés finos), 3ª ajustou essas 4 coisas, **4ª (29/10) rodou o agente crítico de verdade (3/10, reprovado: "de longe vira aranha de pernas abertas") e corrigiu os 6 pontos** (braço mais fino que a perna com cotovelo, torso com volume, mãos com dedos separados, pés com 3 raízes, galho/ninho que tinham sumido dentro da copa, rosto maior). Prints em `evidencias/fase-2/eventos-ambientais/` (`gigante_frente.png`, `gigante_lado.png`, `gigante_costas.png`, `gigante_arvore_jogo_bracos.png`). Correção não voltou ao crítico (os 6 pontos dele foram endereçados um a um; economia de cota).
- Equipe tem o **animador** (ADR-042), além do crítico. Primeira auditoria de animação feita (`docs/auditoria-animacao.md`): mago lançando sem preparação, impacto sem peso, bigorna sem martelo/som. Nada corrigido ainda: aguarda o Vitor autorizar a ordem de trabalho.
- Testes: 324/324.

## Próximo passo
1. Vitor olha `evidencias/fase-2/galinha/` (vídeo e `galinha_folha_animacoes.png`) e diz se a galinha está aprovada ou pede mais uma rodada do crítico.
2. **Gigante da árvore:** Vitor olha os prints novos (correção dos 6 pontos do crítico) e diz se aprova ou pede mais uma rodada (nesse caso, recomendo chamar o crítico de novo antes, já estamos na 5ª).
3. Vitor joga o ciclo da forja no PC (`docs/roteiro-de-teste.md`), mede FPS com `ferramentas\medir_fps.bat` e confere o HUD.
4. Matheus testa com `build/ArcaneForge_teste_Matheus.zip` (gerar de novo com `ferramentas/gerar_pacote_teste.sh`: a galinha mudou).
5. Animação, pela auditoria: mago lançando com preparação, impacto com peso, bigorna com martelo e som.
6. Runas: montar as 8 quando os símbolos chegarem; decidir se a pedra acesa fica tingida ou cinza com cor só em volta do símbolo.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem. Se falhar no PC do Vitor, anotar a distância que ele imprime.
- Névoa volumétrica, SDFGI e o brilho dos olhos da zumbi só aparecem de verdade no PC do Vitor (a nuvem renderiza em Compatibility).

## Pendente do Vitor
- Galinha: se apanhar **durante o aviso** cancela a bicada (o animador recomenda, premia quem interrompe) ou não (hoje não cancela). É regra de combate.
- Gigante da árvore: aprovar a correção do crítico (4ª rodada) ou pedir mais ajuste.
- Runas: símbolos de gravitação, arremesso e quebrar; pedra acesa tingida ou cinza.
- Apagar o projeto `arcane-forge` no Supabase e revogar a chave da Groq guardada nele.
- Referência do medalhão em close, antes da Fase 5 (ADR-033).
- Fase 1: canto de atmosfera e 10 minutos de jogo.
