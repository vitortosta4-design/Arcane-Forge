# Estado atual (passagem de turno)

Bilhete curto para a próxima sessão. **Reescrever inteiro no fim de toda sessão**, em no máximo uma tela. Histórico vai para `diario.md`, não aqui.

Atualizado em: 29/10/2026 (galinha v4 com esqueleto e animações no jogo)

## Onde estamos
- Fase 2 do plano novo: ciclo da forja jogando sozinho (ADR-035). O ciclo inteiro já roda e tem teste de ponta a ponta; da fase só falta o que é do Vitor (jogar, achar divertido, medir FPS).
- **Galinha v4 no jogo** (29/10/2026): `arte/personagens/galinha/galinha.py` põe esqueleto (11 ossos, peças rígidas) e 5 animações no `galinha_v4.glb` do piloto MCP, sem mudar malha (1.148 tri). O mesmo modelo (`jogo/assets/modelos/galinha/galinha.glb`, via `VisualGalinha`) serve a galinha invocada e a zumbi (variante verde acinzentada, olhos acesos, 2 penas a menos, andar torto e manco). Bicada com aviso de 0,4 s e dano aos 0,47 s; morta, tomba quase de costas com as pernas para cima e some em 2,2 s. Pé no Andar desliza no máximo 0,38 m/s com o chão a 3,5 m/s (medido em teste).
- Crítico 5,5 e animador "perto do padrão, reprovada" na 1ª rodada; corrigido uma vez (asas abrindo para fora, aviso mais legível, bote sem virar a cabeça, morte de pernas para o céu, penas em losango, pausa no golpe), **sem nova rodada** por economia de cota. O que faltou está no diário.
- **Mago com esqueleto** (ramo `mago-criticas`) já está no `main`. Runas v6 no jogo; runas pelo vetor do Vitor no ramo `runas-contorno-svg`.
- **Gigante da árvore:** reprovado na 1ª rodada (braços escondidos no tronco). Espera decisão do Vitor; não mexer.
- Testes: 324/324.

## Próximo passo
1. Vitor olha `evidencias/fase-2/galinha/` (vídeo e `galinha_folha_animacoes.png`) e diz se a galinha está aprovada ou pede mais uma rodada do crítico.
2. Vitor joga o ciclo da forja no PC (`docs/roteiro-de-teste.md`), mede FPS com `ferramentas\medir_fps.bat` e confere o HUD.
3. Matheus testa com `build/ArcaneForge_teste_Matheus.zip` (gerar de novo com `ferramentas/gerar_pacote_teste.sh`: a galinha mudou).
4. Animação, pela auditoria: mago lançando com preparação, impacto com peso, bigorna com martelo e som.

## Problemas conhecidos
- Teste instável "área continua machucando a cada segundo": nunca reproduzido na nuvem. Se falhar no PC do Vitor, anotar a distância que ele imprime.
- Névoa volumétrica, SDFGI e o brilho dos olhos da zumbi só aparecem de verdade no PC do Vitor (a nuvem renderiza em Compatibility).

## Pendente do Vitor
- Galinha: se apanhar **durante o aviso** cancela a bicada (o animador recomenda, premia quem interrompe) ou não (hoje não cancela). É regra de combate.
- Gigante da árvore: investir mais uma rodada agora ou esperar (fora da Fase 2, ADR-047).
- Runas: símbolos de gravitação, arremesso e quebrar; pedra acesa tingida ou cinza.
- Apagar o projeto `arcane-forge` no Supabase e revogar a chave da Groq guardada nele.
- Referência do medalhão em close, antes da Fase 5 (ADR-033).
- Fase 1: canto de atmosfera e 10 minutos de jogo.
