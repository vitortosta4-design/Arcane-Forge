# Auditoria de animação (primeira rodada)

23/10/2026 · feita pelo papel do agente animador (ADR-042), **sem mexer no jogo**. Evidências em `evidencias/fase-2/animacao/` (folha de quadros numerada, GIF e mapa de som de cada cena). Gravações com tempo fixo a 30 FPS (modo Movie Maker do Godot) em Compatibility, sem GPU: brilho, partículas e névoa diferem do PC do Vitor.

Origem de cada nota: **[visto]** na gravação, **[medido]** por número, **[deduzido]** do código ou do arquivo, **[pendente]** sem como avaliar daqui. Escala: 0 quebrado, 1 inadequado, 2 abaixo do padrão, 3 competente, 4 profissional, 5 excelente e validado.

## Fichas

| Peça | Arte | Legibilidade | Resposta | Som e efeitos | Estabilidade | Desempenho | Veredito |
|---|---|---|---|---|---|---|---|
| Galinha zumbi (inimigo): andar, bicar, apanhar, morrer | 0 [visto] | 1 [visto] | 0 [deduzido] | 2 [medido] | 3 [deduzido] | 4 [deduzido] | **Reprovada** |
| Mago 3ª pessoa: lançar | 1 [visto] | 2 [visto] | 4 [medido] | 4 [medido] | 4 [deduzido] | 4 [deduzido] | **Reprovada** |
| Galinha invocada (Galinha Kamikaze) | 2 [deduzido] | [pendente] | [pendente] | [pendente] | 1 [medido] | 4 [deduzido] | **Reprovada** |
| Mago 3ª pessoa: andar e parado | 2 [visto] | 3 [visto] | 4 [visto] | 1 [medido] | 4 [deduzido] | 4 [deduzido] | Abaixo do padrão |
| Explosão da bola de fogo | 2 [visto] | 3 [visto] | 4 [visto] | 4 [medido] | 4 [deduzido] | 4 [deduzido] | Abaixo do padrão |
| Medalhão na barra (nascer e recarregar) | 1 [visto] | 4 [visto] | 4 [visto] | 0 [deduzido] | 4 [deduzido] | 4 [deduzido] | Abaixo do padrão |
| Mago 1ª pessoa: lançar | 3 [visto] | 4 [visto] | 4 [medido] | 4 [medido] | 4 [deduzido] | 4 [deduzido] | Competente |
| Bigorna viva: martelar | 4 [visto] | 4 [visto] | 4 [visto] | 0 [medido] | 4 [deduzido] | 3 [deduzido] | Boa, falta som e golpe |

Nenhuma nota 5 visual: nada foi validado no PC do Vitor.

## Defeitos, do mais grave para o menos

1. **Galinha zumbi sem aviso de ataque e sem reação a dano.** Gravidade crítica, impacto alto (o jogador não lê o combate), esforço médio.
   - É uma esfera com bico deslizando; nenhum quadro muda entre andar, parar e bicar [visto, `galinha_ataca_folha.png`, quadros 0 a 75].
   - O dano da bicada sai no mesmo quadro em que ela decide atacar: **0 s de aviso** [deduzido, `galinha_zumbi.gd`]. O único sinal é o som (quadros 19, 24 e 49 em `galinha_ataca_som.txt`).
   - Apanhar só tira vida e empurra; sem piscar, recuar ou se encolher [deduzido]. Morrer é encolher em linha reta em 0,3 s.
   - Tipo: artístico e de jogabilidade (o tempo de aviso é regra de combate; proposta 0,25 s, o número é do Vitor).
2. **Mago lançando sem preparação (3ª pessoa).** Gravidade alta, impacto alto, esforço pequeno.
   - O braço do cajado vai do repouso ao esticado em 1 quadro, sem recuo antes, sem o corpo inclinar, sem chapéu ou capa reagindo [visto, `mago_lancar_3p_folha.png`, quadros 14 e 16]. Visto de trás, quase não se percebe que ele lançou.
   - O que está bom: a magia e o som saem no quadro 16, um quadro depois do comando [medido]. Não trocar essa resposta por enfeite: a antecipação tem que ser curta (2 a 3 quadros) ou visual só no corpo.
3. **Pé da galinha invocada escorregando.** Gravidade alta (técnica), impacto médio, esforço pequeno.
   - A animação `Andar` do modelo anda no lugar com o pé recuando cerca de 1 m/s no apoio (tamanho original). A Galinha Kamikaze tem escala 0,6, então o pé recua uns 0,6 m/s, mas a criatura anda a 3 m/s: **o pé patina uns 2,3 m/s** [medido pela pose dos ossos]. A animação toca sempre na mesma velocidade, ande ela rápido ou devagar [deduzido, `corpos_invocacao.gd`].
   - Não gravei a galinha invocada andando (fica para a próxima rodada).
4. **Impacto sem peso.** Gravidade média, impacto médio, esforço médio.
   - Explosão é uma esfera amarela que cresce e some em velocidade constante [visto]; sem pausa de impacto, sem tremida de câmera, sem reação de quem apanha.
   - A bola de fogo nasce grande e cobre a mão em 1ª pessoa no quadro 16 [visto, `mago_lancar_1p_folha.png`].
5. **Bigorna sem som e sem golpe de martelo.** Gravidade média, impacto médio (é o coração da Fase 2), esforço médio.
   - A reação está boa: o rosto troca com antecipação, salto e acomodação, e o anel acelera [visto, `bigorna_martela_folha.png`]. Mas não há som nenhum ao martelar [medido: `bigorna_martela_som.txt` vazio], nem martelo descendo, nem clarão de impacto. O medalhão aparece na barra sem animação [visto, quadro 16].
6. **Mago andando sem cadência e parando seco.** Gravidade média, impacto médio, esforço grande se for trocar pelo mago com esqueleto.
   - O corpo balança pouco e não há passo legível; ao soltar o W ele para de uma vez, sem assentar [visto, `mago_andar_folha.png`, quadros 42 a 50]. Sem som de passo [medido].
   - O mago com esqueleto e 4 animações (`arte/piloto-modelagem/modelos/mago.glb`) existe, mas o jogo usa o boneco feito em código. Trocar é decisão do Vitor.
7. **Medalhão sem vida.** Gravidade baixa, esforço pequeno: nasce e fica pronto sem pulo, brilho ou som [visto]. A recarga (relógio e segundos) já se lê bem [visto].

Sem achado de pé atravessando o chão ou peça girada sobrando no fim; isso não foi medido em todas as peças.

## O que não foi possível validar daqui
- Galinha zumbi apanhando: duas tentativas de encenação erraram o tiro (`galinha_tiro_errou_folha.png`); a ausência de reação vem do código.
- Galinha invocada andando, leão e golem: não gravados nesta rodada.
- Sensação de controle na mão, brilho e partículas do Forward+ e FPS real: só no PC do Vitor.

## Proposta de ordem de trabalho (aguardando autorização)
1. Galinha zumbi: aviso de bicada, reação a dano e morte com graça. Decidir antes: tempo de aviso (proposta 0,25 s) e se ela continua esfera ou vira a galinha do piloto com esqueleto (já modelada).
2. Mago lançando com preparação curta (3ª e 1ª pessoa), sem atrasar a saída da magia.
3. Pé da galinha invocada: velocidade da animação proporcional à velocidade e à escala.
4. Impacto: pausa curta, tremida de câmera leve, explosão com aceleração e reação de quem apanha.
5. Bigorna: martelo descendo, clarão e som; medalhão voando até a barra.
6. Mago andando (depende da decisão do Vitor sobre o mago com esqueleto).
