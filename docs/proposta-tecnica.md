# Proposta técnica · Arcane Forge

Versão 2 · 22/10/2026 · Status: **Aprovada pelo Vitor** (v1 em 20/10/2026; plano de fases da Forja de Runas em 22/10/2026, ADR-035)

> **Aviso de versão:** a IA que interpretava texto foi abandonada (ADR-032) e removida do jogo (ADR-041). O motor (ficha, validador, executor, componentes) continua valendo: quem preenche a ficha agora é a receita de runas. Revisado em 22/10/2026 para tirar as menções à IA.

Este documento junta as decisões de `decisoes.md` num plano único: como o jogo é dividido, como uma magia funciona por dentro, como o multiplayer e a segurança se encaixam, e o que exatamente será feito na Fase 1.

---

## 1. A ideia em uma frase

As runas são os **ingredientes** que o jogador acha explorando. A bigorna é o **fogão**: o jogador junta até 3 ingredientes e o **livro de receitas** diz que prato sai (a mesma soma dá sempre o mesmo prato; sem receita, sai um prato básico e engraçado). O **gerente** (validador) confere se o prato está dentro dos limites e quanto custa de mana. A **cozinha** (motor do jogo) monta a magia com os componentes que existem.

---

## 2. Como o jogo é dividido

| Módulo | O que faz | Quando nasce |
|---|---|---|
| Mago | movimento WASD, pulo, mira, câmera 1ª/3ª pessoa, vida e mana | Fase 1 |
| Combate | dano, colisões, morte, revive | Fase 1 (revive na 7) |
| Ficha de magia | formato padrão que descreve qualquer magia | Fase 1 |
| Executor | lê a ficha e monta a magia no mundo usando componentes | Fase 1 |
| Validador e custo | confere limites, calcula mana, aplica regras de natureza | Fase 2 |
| Livro de receitas e forja | soma as runas na bigorna e devolve a ficha da magia | Fase 2 |
| Barra de medalhões | 4 espaços com as magias forjadas, recarga por medalhão | Fase 2 |
| Visual procedural | monta a aparência com formas e peças low poly | Fases 1 a 3 |
| Inimigos | comportamento por regras (sem IA de linguagem) | Fase 1 (básico), 7 (completo) |
| Rede | host é o juiz; o outro jogador envia comandos | arquitetura na Fase 1, uso real na 3 |
| Mapa | módulos encaixados aleatoriamente | Fase 7 |
| Grimório e progressão | receitas descobertas (Fase 2); melhorias da forja (Fase 7) | Fases 2 e 7 |

**Regra de ouro da arquitetura:** desde a Fase 1, todo o jogo roda como se houvesse um host, mesmo jogando sozinho. Quem decide dano, mana e criação de entidades é sempre o "juiz". Assim, quando o seu amigo entrar na Fase 3, não é preciso reescrever o combate.

---

## 3. A ficha de uma magia

Toda magia, seja escrita à mão nos testes ou vinda de uma receita de runas, vira uma ficha neste formato. Exemplo de um pombo de pedra que voa até o inimigo e solta ovos explosivos (o campo `frase_original` é da época da IA e hoje é opcional):

```json
{
  "versao_sistema": 1,
  "nome": "Pombo de Pedra Bombardeiro",
  "frase_original": "um pombo de pedra que voa até o inimigo e solta ovos explosivos",
  "natureza": "neutra",
  "ingredientes": ["voo", "invocacao", "explosao"],
  "componentes": [
    {
      "id": "pombo",
      "tipo": "invocacao",
      "corpo": "ave",
      "material": "pedra",
      "escala": 0.7,
      "movimento": "voo",
      "comportamento": "perseguir_inimigo_proximo",
      "vida": 20,
      "duracao_s": 6
    },
    {
      "tipo": "lancador",
      "anexado_a": "pombo",
      "intervalo_s": 1.5,
      "projetil": { "forma": "ovo", "material": "pedra", "velocidade": 8 },
      "ao_impactar": [
        { "tipo": "explosao", "raio_m": 2, "dano": 12, "empurrao": 3 }
      ]
    }
  ],
  "legenda": "criatura voadora de pedra que persegue e solta bombas"
}
```

Pontos importantes:

- Os valores vêm de listas fechadas (`corpo`: ave, quadrúpede, verme, bolha...; `material`: pedra, água, fogo, metal...). Algo fora da lista é rejeitado.
- A receita **sugere** números, mas o validador corta tudo o que passar dos limites (até um erro no arquivo de receitas fica dentro dos limites).
- **O custo de mana é calculado pelo jogo**, a partir dos componentes.
- `versao_sistema` permite saber se uma magia salva ainda é compatível depois que as regras mudarem.
- A natureza (boa, neutra, má) vem dos ingredientes usados. Magias más ganham a chance secreta de sair pela culatra (ADR-017).

### Componentes previstos

- **Primeira leva (Fases 1 e 2):** projétil, explosão, área persistente, invocação, lançador, escudo, cura, empurrar/puxar, parede/construção, teleporte curto, estados (queimando, molhado, eletrizado, cego, lento).
- **Depois:** raio contínuo, correntes, levitação, transformação, gatilhos condicionais ("quando X, faça Y").

### Interações por etiquetas

Cada objeto tem etiquetas como `inflamavel`, `condutor`, `molhado`, `metalico` e `invocado`. As regras são curtas e gerais, por exemplo: "eletricidade em algo molhado se espalha num raio". Assim a nuvem de água do seu amigo e o seu raio se combinam sem ninguém ter programado essa dupla especificamente.

---

## 4. O caminho de uma magia (Forja de Runas)

1. O jogador explora e pega runas (quem pega leva; pode largar no chão para o parceiro).
2. Na caverna, coloca até 3 runas na bigorna viva (uma de forma e até duas de elemento) e martela.
3. O host procura a combinação no livro de receitas, um arquivo de dados. A mesma soma sempre dá a mesma ficha. Sem receita, sai a versão básica e engraçada.
4. O validador confere a ficha como antes; o custo de mana é calculado pelo jogo.
5. A ficha vira um medalhão num dos 4 espaços da barra. Receita nova entra no grimório (salvo no PC, fica para sempre).
6. Teclas 1 a 4 usam o medalhão. Quebrar um medalhão libera o espaço.

Não há internet, IA nem escrita nesse caminho.

## 5. Limites iniciais (ajustáveis com testes)

| Limite | Valor inicial |
|---|---|
| Duração máxima de uma magia | 8 s |
| Magias ativas por jogador | 3 |
| Criaturas invocadas no mapa (somando os dois) | 6 |
| Projéteis ativos no mapa | 40 |
| Partículas por magia | baixo (definido na Fase 1 medindo FPS) |

Uma ficha que peça mais do que isso é cortada pelo validador: duração infinita vira 8 segundos, criatura além do limite simplesmente não nasce.

---

## 6. Multiplayer

- O PC do seu amigo (Ryzen 7600X, RTX 4070) hospeda e é o juiz. Você joga como convidado.
- Conexão inicial por rede virtual gratuita (Radmin VPN ou ZeroTier). Futuro: noray.
- Cada entidade (mago, pombo, ovo, galinha zumbi) tem um número único dado pelo host.
- O convidado só envia "o que quero fazer" (andar, mirar, conjurar). O host responde "o que aconteceu".
- **Risco aceito:** sem login, os ingredientes ficam salvos no PC de cada um. Entre amigos isso não importa. Se o jogo for para a Steam, isso precisa ser revisto.

---

## 7. Segurança (o essencial)

- Sem IA e sem servidor próprio: nenhuma chave de API no jogo nem no GitHub (o projeto da IA no Supabase foi desligado, ADR-041).
- Toda ficha passa pelo validador, mesmo vinda do livro de receitas: um arquivo de receitas editado não escapa dos limites.
- O host revalida tudo o que o convidado manda, inclusive se ele tem as runas que diz ter antes de forjar (Fase 3).

---

## 8. Desempenho

- **Hardware mínimo oficial (atualizado pela ADR-031, 21/10/2026):** CPU Ryzen 5 3600 ou Intel i5-9400F (6 núcleos), GPU RTX 2060 6GB, 16GB de RAM. Antes era o PC do Vitor (Pentium G5400, GTX 1050 2GB); o Vitor pediu para subir o piso para poder deixar o jogo visualmente mais cheio (ver ADR-031 em `decisoes.md`), mesmo isso significando que seu PC atual deixa de garantir rodar bem.
- **Meta inicial:** 60 FPS na arena vazia e nunca abaixo de 30 FPS no pior caso permitido pelos limites, em 1080p com gráficos altos (dentro do novo piso). Já medido uma vez no PC antigo do Vitor (Fase 1: 53-60 FPS com o piso antigo); precisa remedir depois que a atmosfera usar o orçamento novo (névoa volumétrica, iluminação global em tempo real, mais luzes com sombra — ADR-025 revisado).
- Renderizador: Forward+ (já configurado no projeto), que é o que aguenta SDFGI e névoa volumétrica.
- Contador de FPS ligável no jogo, desde a Fase 1.

---

## 9. Fase 1: primeiro protótipo jogável

**Objetivo:** provar o esqueleto do jogo, com a magia já passando pelo formato de ficha, mas ainda sem IA.

### O que será feito
1. Projeto Godot 4.7.2 criado com estrutura de pastas e git.
2. Avaliar e instalar um servidor MCP de Godot, depois de checar licença e segurança, para o Claude Code rodar o jogo e ler erros.
3. Arena de teste low poly: chão, obstáculos, caixas que quebram, um barril inflamável.
4. Mago em primeira pessoa (WASD, pulo, mira, mãos low poly), com troca para terceira pessoa no menu.
5. Vida, mana e HUD simples.
6. Primeiro inimigo absurdo: galinha zumbi que anda até você e bica.
7. Sistema de ficha + executor com os componentes **projétil** e **explosão**.
8. "Bola de fogo" como ficha escrita à mão, disparada com o botão do mouse.
9. Estrutura host/convidado ativa, rodando local.
10. Contador de FPS e escolha do renderizador.
11. Canto de atmosfera na arena (ADR-030): shader toon, luz de contorno, névoa colorida, céu pintado, vegetação ao vento e brilho nas magias, seguindo a paleta de `docs/referencias/arte-conceito-01.png`.
12. Sons provisórios com o sistema de camadas (ADR-026) para tiro, explosão e galinha zumbi; se o Vitor enviar gravações, usar as dele.

### Critérios de aceitação
- [x] A bola de fogo sai da mão, colide, explode, causa dano, empurra a galinha e quebra caixas (versão sem IA do Teste A). Verificado por teste automático e jogando.
- [x] O barril inflamável pega fogo com a explosão (primeira interação por etiquetas). Verificado por teste automático.
- [x] A galinha zumbi persegue, ataca e morre. Verificado por teste automático e jogando.
- [x] A mana desce ao conjurar e impede conjurar sem mana. Verificado por teste automático.
- [x] Troca entre 1ª e 3ª pessoa funciona e a mira acerta o mesmo ponto nos dois modos. Verificado por teste automático (achado e corrigido um bug real nisso); confirmação visual sua ainda bem-vinda.
- [x] Testes automáticos do executor e das regras de dano passando. 39/39.
- [x] FPS medido no seu PC e registrado, inclusive dentro do canto de atmosfera com várias bolas de fogo ao mesmo tempo. Ficou entre 53 e 60 FPS.
- [ ] O canto de atmosfera lembra as cores e o clima da referência visual (avaliado pelo Vitor). **Pendente: depende do seu olho.**
- [x] Explosão e galinha zumbi têm som posicional 3D. Implementado e testado sem erros; qualidade sonora ainda depende de você ouvir.
- [x] Prints de evidência guardados em `evidencias/fase-1/`.
- [ ] **Você joga 10 minutos e diz se o tiro e a explosão "dão gosto".** **Pendente: depende de você jogar.**

### O que você precisa fazer na Fase 1
- Aprovar a instalação do Godot e do MCP quando o Claude Code pedir.
- Jogar no final e dar sua opinião.
- Nada mais.

---

## 10. Plano geral das fases (Forja de Runas, aprovado em 22/10/2026, ADR-035)

Objetivo: chegar o quanto antes ao ciclo jogável (explorar, achar runas, chegar à bigorna, forjar o medalhão e usar a magia da barra) com visual provisório, e testar com o amigo do Vitor.

**Fase 1 · Esqueleto jogável:** feita, com dois critérios pendentes do Vitor (seção 9), que serão fechados no primeiro teste com o amigo.

**Fase 2 · Ciclo da forja, jogando sozinho** (grande, é o coração do jogo)
- Livro de receitas em arquivo de dados legível. Uma runa de elemento sozinha vira projétil; forma + elemento sem receita dá a versão básica e engraçada; receitas especiais têm modelo próprio.
- Primeira leva: 6 runas (formas: arremesso, vida, prende; elementos: fogo, água, feroz) e cerca de 8 receitas especiais, aproveitando o piloto (molotov, corrente, galinha) e os componentes existentes. Exemplos: fogo = bola de fogo rápida; vida + fogo = golem de fogo lento; vida + feroz = leão; arremesso + fogo = molotov arcano; prende + fogo = correntes em brasa saindo do chão.
- Até 3 runas por forja: uma forma e até dois elementos. **Revisto pela ADR-046:** a expedição começa com 2 runas; a 3ª libera com 10 partidas.
- Runas em pontos fixos da clareira, contador no HUD.
- Caverna provisória ligada à clareira, com a bigorna viva aprovada.
- Interface da bigorna: escolher runas, martelar, a bigorna reage (treme, faísca) e sai um medalhão provisório (disco na cor do elemento, com o símbolo).
- Barra 1 a 4. A expedição começa com 2 medalhões padrão e 2 espaços vazios. Quebrar um medalhão libera o espaço.
- Mana continua, com recarga curta por medalhão; números ajustados jogando.
- Grimório mínimo: receitas descobertas salvas no PC, lista simples.
- Caixa de texto (Q) sai do jogo, junto com o porteiro e o `Interpretador` (removidos na ADR-041).
- **Pronto quando:** jogando do começo ao fim, acho 3 runas, forjo 2 medalhões diferentes e uso os dois na galinha; teste automático confirma que a mesma soma sempre dá a mesma magia; o grimório sobrevive a fechar e reabrir o jogo; FPS medido no PC do Vitor.

**Fase 3 · Cooperativo** (médio)
- O amigo hospeda, o Vitor entra pelo Radmin VPN (ou ZeroTier).
- Os dois veem os mesmos resultados: runas coletadas, forja, medalhões, magias, dano e inimigos.
- Runas: quem pega leva, e pode largar no chão para o parceiro.
- O convidado não consegue forjar runa que não tem; o host revalida tudo.
- Revisão de segurança e multiplayer (ADR-005) uma vez, nesta fase.

**Marco · Primeiro teste com o amigo:** sessão de 20 minutos, roteiro curto e 5 perguntas. Fecha os critérios pendentes da Fase 1. O resultado decide se a forja é ajustada antes de seguir.

**Fase 4 · Expedição mínima** (médio, desenho na ADR-046)
- Começo, meio e fim: chefe simples, 3 estátuas de reviver, carregar o corpo, derrota (ADR-014, ADR-015).
- Ciclo de dia até a noite; território do chefe que acorda ao entrar ou ao anoitecer.
- O Núcleo: pegar, fugir até a forja com chefe e minions atrás, efeitos caóticos em quem carrega, bigorna digere e enfraquece o chefe, duelo final.
- Brasa Arcana como objetivo secundário.
- Bigorna começa com 2 runas; contador de partidas (3ª runa em 10) e de vitórias (cor do manto) salvos no PC.
- Baús com runas, consumíveis e um mímico; 2 ou 3 inimigos absurdos novos (minions do chefe entre eles).
- Mapa ainda fixo: clareira, caverna e uma área nova.
- Fecha com o segundo teste com o amigo.

**Fase 5 · Acabamento visual:** texturas pintadas pelo Vitor (runa como piloto), estilo do HUD (precisa da referência do HUD, ADR-039), medalhão definitivo (precisa de referência, ADR-033), caverna mística de verdade, animações expressivas do mago.

**Fase 6 · Áudio:** lista de gravações para o Vitor, com duração e formato de cada uma (ADR-028).

**Fase 7 · Conteúdo:** gerador de mapas por módulos (ADR-018), runas de nível alto (ex.: gravitação), melhorias permanentes da forja (ADR-034), chefe com fases.

**Fase 8 · Otimização e distribuição.**

**Saem do plano antigo:** voz, o teste de 50 frases na IA e o uso do Supabase.

**Regra:** nada das Fases 5 a 7 antes de o teste com o amigo provar que forjar é divertido. Modelagem nova só quando a peça for usada pelo item em andamento.

---

## 11. Maiores riscos

| Risco | O que fazemos |
|---|---|
| Forjar não ser divertido | Marco de teste com o amigo logo após o cooperativo; ajustar receitas antes de criar conteúdo |
| Cota do Claude Pro acabar no meio do trabalho | Equipe enxuta, tarefas pequenas, trabalho dividido em sessões curtas |
| Seu PC não aguentar | Limites rígidos e medição de FPS desde o primeiro dia |
| Conexão entre as casas falhar | Rede virtual no começo; noray depois |
| Escopo crescer demais | Nada das Fases 5 a 7 antes do primeiro teste com o amigo |

---

## 12. Custo previsto

R$ 0/mês além do Claude Pro. A reserva de até R$ 50/mês (ADR-006) continua existindo, só com aprovação; o motivo original dela (IA paga) saiu com a ADR-041.
