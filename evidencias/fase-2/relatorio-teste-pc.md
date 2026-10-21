# Relatório de teste no PC do Vitor (21/10/2026)

Branch testado: `claude/arcane-forge-continuation-4rfd9u`.

## 0. Ambiente

- **Godot:** 4.7.2.stable.official.ed1daf0bf (achado em `C:\Users\User\AppData\Local\Microsoft\WinGet\Links\godot.exe`, instalado pelo WinGet).
- **Placa de vídeo real:** NVIDIA GeForce GT 1030, 2 GB, driver 582.67. Também existe uma Intel UHD Graphics 630 integrada (1 GB) nesta máquina, mas o Godot escolheu a NVIDIA sozinho ("Using Device: NVIDIA - NVIDIA GeForce GT 1030").
- **Atenção, Vitor:** o pedido dizia "placa RTX", mas a GPU real deste PC é uma **GT 1030**, não uma RTX. Ela é mais fraca até que o piso antigo (GTX 1050 2 GB, ADR-025 original) e bem abaixo do piso novo aprovado na ADR-031 (RTX 2060 6 GB). Não troquei nada, só registro a diferença para você decidir o que fazer com isso.

## 1. Testes automáticos

Reimportação (`godot --headless --editor --quit --path jogo`) rodou sem erro (só o aviso de sempre: "Volumetric fog is only available when using the Forward+ renderer", porque o editor headless não tem GPU de verdade disponível nesse passo).

Suíte (`godot --headless --path jogo res://cenas/testes/suite_testes.tscn`):

```
FALHAS: 1 de 225 testes
```

- O pedido esperava 226/226. A suíte desta branch tem 225 testes, não 226 — não sei dizer se é porque algum teste foi removido/renomeado desde que o número 226 foi escrito, ou outro motivo; não inventei essa contagem, é a que o Godot imprimiu.
- **1 teste falhou:** `área continua machucando a cada segundo`. O framework de teste deste projeto só imprime `[FALHOU]` com o nome, sem detalhe adicional no console — não consegui ver a causa exata sem ler o código do teste, e não alterei nada para investigar mais fundo (fora do que o pedido autorizava).
- **Erros/avisos vermelhos vistos no console durante a suíte** (nenhum travou a suíte):
  - `ERROR: Parameter "material" is null.` — 2 vezes.
  - `SCRIPT ERROR: Invalid call. Nonexistent function '_explodir' in base 'previously freed'.` — 1 vez, dentro de um teste que passou (`_testar_projetil_aplica_estado_em_quem_atingiu`, suite_testes.gd:871). Parece uso de um objeto já liberado durante a limpeza do teste, não durante o jogo normal.
  - `ERROR: Node origin and target are in the same position, look_at() failed.` — por volta de 31 vezes, espalhado em vários testes de teleporte/mira.

## 2. Névoa volumétrica, SDFGI e o renderer

Antes dos prints, uma descoberta importante: **o projeto está fixado no renderer Compatibility** (`project.godot`, linhas 66-67: `renderer/rendering_method="gl_compatibility"`), não Forward+. Isso vale para qualquer máquina, inclusive esta, com GPU NVIDIA dedicada — não é uma limitação de hardware, é uma configuração do projeto.

Confirmei isso pelo aviso que aparece em **toda** execução, mesmo aqui no PC:
```
WARNING: Volumetric fog is only available when using the Forward+ renderer.
```

**Consequência prática:** névoa volumétrica e SDFGI (liberados pela ADR-031 "quando tivesse uma GPU real") continuam invisíveis neste teste, não porque a GT 1030 seja fraca demais para eles (ela também seria, mas isso nem chegou a ser testado), e sim porque o motor nunca liga o Forward+ enquanto o projeto estiver configurado assim. Não mudei esse arquivo, porque é uma decisão de configuração do jogo, não um "resultado de teste" — fica para você decidir quando quiser realmente testar Forward+.

## 3. Prints (evidências visuais)

Usei `jogo/scripts/ferramentas/tirar_print.gd` direto (sem o `.sh`). **Achado no caminho:** minha primeira tentativa minimizou a janela do Godot durante a captura (hábito de não atrapalhar você usando o PC) e isso gerou 6 prints completamente em branco — janela minimizada não renderiza de verdade no Windows. Refiz todos sem minimizar; a janela apareceu na tela por uns 3 segundos, 6 vezes seguidas, durante a captura.

Salvos em `evidencias/fase-2/`: `pc_trilha.png`, `pc_ruinas.png`, `pc_canto_tocha.png`, `pc_mago_frente.png`, `pc_mago_terceira.png`, `pc_bola_de_fogo.png`.

**Comparando com `docs/referencias/arte-conceito-01.png`:**

O que já se parece:
- Paleta saturada: verde vivo da grama, laranja do caminho, azul forte do céu — bate com a referência.
- Geometria low poly de propósito (ADR-007), sem excesso de detalhe.
- Elementos de cenário certos: arcos de ruína, castelo ao fundo, barris, caixas, tocha.
- O bug do mago nunca aparecer em terceira pessoa está corrigido: `pc_mago_terceira.png` e `pc_mago_frente.png` mostram o rosto dele.
- Mãos saindo em primeira pessoa, ocupando o canto da tela, como a referência pede.

O que ainda falta:
- Nenhuma névoa/profundidade atmosférica (zero, pelo motivo da seção 2 acima).
- Brilho (glow) fraco: a tocha do canto de atmosfera tem um cristal branco claro, mas sem o halo "estourado" que a referência tem nas tochas e magias.
- Sombras neutras (cinza), não o contraste quente/frio (dourado x azulado) que a referência usa.
- Céu é só um gradiente liso; a referência tem céu pintado com ilhas flutuantes.
- Nenhum inimigo nos prints (a referência mostra vários goblins e um troll em combate); os prints daqui são só o cenário vazio.

O que não dá para alcançar, mesmo com hardware melhor:
- A densidade de polígonos dos personagens da referência — isso é decisão de design (ADR-007), não limitação técnica, e continua valendo por pedido seu.

## 4. FPS

Usei um script temporário (`jogo/scripts/ferramentas/medir_fps_temp.gd`, apagado ao final) que roda a arena de teste, mede `Engine.get_frames_per_second()` por 9 segundos parado e depois por mais 10 segundos conjurando magias de verdade (Interpretador local + Executor direto, sem IA, sem rede) a cada 0,15 s.

```
FPS parado (média, 540 amostras):        57,5
FPS com magias simultâneas (média, 580 amostras): 56,8
FPS com magias simultâneas (mínimo):     42
Magias disparadas na janela de 10s:      62
```

A meta é 60 e nunca abaixo de 30: o jogo nunca chegou perto de 30 (mínimo visto foi 42, sob carga), mas também não bateu os 60 "limpos" nem parado — ficou na casa dos 57-58. Dentro do aceitável, mas não no alvo ideal.

**Nota sobre um número que não vale:** o print `pc_bola_de_fogo.png` mostra "FPS: 1" no HUD — isso é um valor de um único frame, capturado 0,56 s depois da cena abrir (ainda esquentando), não uma medida real. Os números confiáveis são os do script dedicado acima.

## 5. Teste da IA de verdade (Groq via Supabase)

Script temporário (`jogo/scripts/ferramentas/testar_ia_temp.gd`, apagado ao final) chamou `Porteiro.interpretar()` direto, uma frase de cada vez, com uma pausa de 0,5 s entre pedidos.

| # | Frase | Entendeu? | Legenda | Tempo | Custo de mana |
|---|---|---|---|---|---|
| 1 | bola de fogo que explode | Sim | uma esfera de fogo que explode ao atingir o alvo | 3598 ms | 20,0 |
| 2 | me cure | Sim | cura o conjurador imediatamente | 1767 ms | 10,0 |
| 3 | escudo de pedra no meu corpo | Sim | Escudo de pedra que protege o corpo do conjurador | 2134 ms | 20,0 |
| 4 | levante um muro de pedra na minha frente | **Não** | — | 683 ms | — |
| 5 | teleporte para frente | **Não** | — | 634 ms | — |
| 6 | chuva ao meu redor que deixa todo mundo molhado | **Não** | — | 667 ms | — |
| 7 | faísca elétrica | **Não** | — | 584 ms | — |
| 8 | bola de lava que deixa uma poça de fogo no chão | **Não** | — | 600 ms | — |
| 9 | pó que cega a galinha | **Não** | — | 617 ms | — |
| 10 | invoque um pombo de pedra | Sim | invoca um pombo feito de pedra que persegue o inimigo mais próximo | 2617 ms | 21,5 |
| 11 | pombo de pedra que bombardeia com ovos explosivos | **Não** | — | 634 ms | — |
| 12 | vaca de água que solta bolhas | **Não** | — | 617 ms | — |

**4 de 12 frases tiveram resposta real da IA; 8 vieram vazias.** Nos 4 casos com resposta, o Validador aceitou todas (custo de mana > 0 nas quatro).

**Causa raiz confirmada (não é chute):** usei as ferramentas de log do Supabase (projeto `arcane-forge`, id `avasfvsditrkwyrdglfu`) para ver o que aconteceu de verdade. As 8 frases "vazias" bateram, uma por uma, num erro HTTP 429 do **Groq** (não do nosso limitador):

```
Rate limit reached for model `openai/gpt-oss-120b` ... tokens per minute (TPM): Limit 8000, Used ~7700-7800, Requested ~2400-2700
```

O plano grátis da Groq para esse modelo libera **8000 tokens por minuto**, e cada pedido desta função consome por volta de 2400 a 2700 tokens (o prompt que explica o formato da ficha é grande). Ou seja: **só cabem uns 3 pedidos reais por minuto** antes de bater nesse teto — exatamente o que aconteceu (as 3 primeiras frases passaram, aí travou; destravou um pouco depois, passando a décima, e travou de novo). Isso não é bug do nosso código: é o tamanho do teto gratuito da Groq batendo de frente com o tamanho do prompt.

Conferi também que **o limitador de 20 pedidos/minuto por sala do nosso lado nunca bloqueou nada** (toda chamada passou pelo `conferir_e_registrar_limite`/inserção e foi registrada, vi isso nos logs do Edge Function). Então isso **não tem relação** com a alteração que ficou guardada no stash (ela mexe numa corrida entre dois pedidos simultâneos contando a mesma sala; aqui os pedidos foram um de cada vez, sequenciais, e o limitador nem chegou perto do teto de 20).

**O que isso quer dizer na prática para jogar:** se você conjurar 3-4 magias reais (não as de clique rápido, que não usam IA) em menos de um minuto, é bem provável que a quarta ou quinta venha "vazia" e caia no Interpretador local — isso é esperado com o provedor atual (Groq, provisório, ADR-002/notas da Fase 2), não um bug novo.

## 6. Nota sobre o stash

A alteração local em `supabase/functions/interpretar-magia/index.ts` (troca de `conferirLimite` para a chamada atômica `conferir_e_registrar_limite` via RPC do Postgres) segue guardada em `stash@{0}`, **não aplicada, não enviada**. O SQL da função `conferir_e_registrar_limite` não está no repositório — só a mudança do lado do TypeScript ficou no stash. Não mexi em nada disso além de guardar, como você pediu.

## 7. Commit

Vou commitar só o relatório e os 6 prints `pc_*.png`. Nenhum código do jogo foi alterado — os dois scripts temporários (`medir_fps_temp.gd` e `testar_ia_temp.gd`) e este próprio pedido (`PEDIDO-TESTE-PC.md`) foram apagados antes do commit.

## Perguntas para você preencher

- O combate "dá gosto"? O que ficou chato ou sem graça?
- Gostou do mago e da clareira, olhando de verdade (não só pelos prints)?

**Resposta do Vitor (21/10/2026):** primeira pessoa ok, ambiente parece bom. Não gostou do formato do boneco em terceira pessoa (queria mais cabeçudo e mais baixo), sente falta de movimento de braço, de roupa com mais acabamento, e de mais refino no ambiente (mesmo sendo low poly). Resumo dele: "precisa demais, apesar de estarmos no caminho". Combate ainda não avaliado diretamente. Registrado em `docs/decisoes.md`.
