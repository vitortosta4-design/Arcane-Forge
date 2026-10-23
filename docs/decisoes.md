# Registro de decisões (ADR)

Cada decisão tem: problema, alternativas, escolha, motivo, consequências e se é fácil de mudar.
Status possíveis: **Aprovada**, **Proposta** (aguardando o Vitor), **Adiada**.

Última atualização: 23/10/2026 (ADR-043)

Este arquivo guarda só decisões. O histórico do que foi implementado está em `docs/contexto/diario.md`, e o ponto onde o trabalho parou está em `docs/contexto/estado-atual.md`.

---

## ADR-001 · Engine: Godot 4.7
**Status:** Aprovada (20/10/2026)

- **Problema:** escolher a engine para um jogo 3D cooperativo, desenvolvido quase todo por IA, num PC modesto (Pentium G5400, GTX 1050 2 GB, 16 GB RAM).
- **Alternativas:** Unreal Engine 5, Unity 6, Godot 4.7.
- **Escolha:** Godot 4.7 (versão estável mais recente em out/2026: 4.7.2).
- **Motivo:**
  - Unreal 5 é pesado demais para desenvolver no PC do Vitor.
  - Godot é grátis, licença MIT, sem royalties, o que deixa aberta a porta para a Steam no futuro.
  - Cenas e scripts são arquivos de texto, o que facilita a IA ler, editar e revisar.
  - Existem servidores MCP que permitem ao Claude Code abrir o jogo, rodar e ler erros.
  - Tem renderizadores leves (Mobile e Compatibility) adequados ao estilo low poly.
- **Consequências:** linguagem principal GDScript. O renderizador (Mobile ou Compatibility) será escolhido na Fase 1, medindo FPS no PC do Vitor.
- **Fácil de mudar?** Não. Trocar de engine equivale a recomeçar.

## ADR-002 · Interpretação das magias: camada trocável, começando com IA gratuita
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- **Problema:** transformar texto livre em magia, com custo zero ou baixo.
- **Alternativas:** modelo local no PC (fraco demais no hardware atual), API paga, API com plano gratuito.
- **Escolha:** um "tradutor" independente do jogo. O jogo envia a frase e recebe uma ficha estruturada. O provedor inicial será um plano gratuito (Groq ou Gemini Flash), escolhido na Fase 4 por qualidade e velocidade medidas.
- **Motivo:** custo zero na fase de aprendizado, e o provedor pode ser trocado sem mexer no jogo.
- **Consequências:**
  - Planos gratuitos podem usar os dados enviados para treino e podem proibir uso comercial. Se o projeto virar produto, migrar para plano pago, dentro do teto de R$ 50/mês.
  - Haverá um modo offline com magias pré-definidas, para testes sem gastar cota.
- **Fácil de mudar?** Sim.

## ADR-003 · Proteção da chave da IA: Supabase Edge Function
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- **Problema:** a chave da API não pode ficar dentro do executável.
- **Escolha:** uma função no Supabase (plano grátis) que guarda a chave, valida o pedido, aplica limite de uso por jogador e chama a IA.
- **Consequências:** projetos grátis do Supabase pausam após 1 semana sem uso; basta reativar.
- **Fácil de mudar?** Sim.

## ADR-004 · Multiplayer: um jogador hospeda (servidor autoritativo no PC do host)
**Status:** Aprovada (20/10/2026)

- **Problema:** partidas para 2 jogadores, sem custo, sem permitir trapaça.
- **Alternativas:** servidor dedicado alugado (custo mensal), host sendo um dos jogadores (grátis).
- **Escolha:** o host é o juiz da partida (dano, mana, criação e remoção de entidades). O outro jogador envia comandos e recebe resultados.
- **Quem hospeda:** por padrão, o PC do amigo (Ryzen 5 7600X, RTX 4070, 32 GB), que é bem mais forte.
- **Conexão:** no início, rede virtual gratuita (Radmin VPN ou ZeroTier). No futuro, avaliar o noray (NAT punchthrough + relay, MIT).
- **Consequências:** desde a Fase 1, o código separa "quem decide" (host) de "quem mostra" (cliente), mesmo jogando sozinho.
- **Fácil de mudar?** Trocar quem hospeda: fácil. Trocar o modelo inteiro: trabalhoso.

## ADR-005 · Equipe de agentes enxuta
**Status:** Aprovada (20/10/2026)

- **Problema:** o plano Pro tem cota compartilhada entre chat e Claude Code; muitos agentes esgotam a cota rápido.
- **Alternativas:** instalar o Claude Code Game Studios completo (49 agentes, 74 skills), equipe própria enxuta.
- **Escolha:** agente principal + 3 especialistas acionados só quando valem a pena:
  1. revisor de segurança e multiplayer
  2. testador (roda o jogo, tira print, confere critérios de aceitação)
  3. game designer (equilíbrio e diversão)
- **Motivo:** cota limitada, e o próprio autor do Game Studios mediu que o modo mais burocrático não gerou jogo melhor.
- **Aproveitado do Game Studios:** a regra de que nada visual está pronto sem rodar o jogo e guardar evidência (print).
- **Fácil de mudar?** Sim.

## ADR-006 · Orçamento
**Status:** Aprovada (20/10/2026)

- Meta: R$ 0/mês além do Claude Pro já pago.
- Teto absoluto: R$ 50/mês, só se necessário para manter a experiência.
- Qualquer gasto exige aprovação do Vitor.

## ADR-007 · Direção visual
**Status:** Aprovada (20/10/2026)

- Low poly "feiozinho de propósito", engraçado ("aquilo é um pombo? kkkk").
- Cores vibrantes, na linha de Fortnite: Salve o Mundo (2018).
- Criaturas montadas proceduralmente a partir de formas simples e peças modulares. O visual tosco faz parte da identidade.

### Referência visual: `docs/referencias/arte-conceito-01.png` (adicionada em 20/10/2026)
Arte conceitual gerada por IA a pedido do Vitor.

**Atualizado em 20/10/2026 a pedido do Vitor:** esta imagem é o objetivo do desenvolvimento visual em cores, iluminação, intensidade das cores, animação e ambiente. Em qualquer dúvida visual, comparar um print do jogo com ela e perguntar o que falta para chegar lá, dentro das limitações abaixo e do ADR-025. Ela não é alvo de detalhe: o Vitor achou que ela tem polígonos demais.

**Aproveitar:**
- Paleta saturada, com contraste de quente e frio: luz dourada, sombras azuladas, céu azul vivo.
- Magias brilhantes (emissivas) que se destacam do cenário: azul, roxo, verde e laranja.
- Mãos do mago em primeira pessoa ocupando os cantos da tela.
- HUD: retrato com vida e mana no canto superior esquerdo, 4 magias de bolso centralizadas embaixo, minimapa no canto inferior direito.
- Profundidade com névoa colorida e um céu pintado ao fundo (castelo, ilhas flutuantes), que custa quase nada de desempenho porque é uma imagem, não modelos 3D.
- Ruínas de pedra, tochas, barris e caixas como cenário típico.

**Não seguir:**
- Densidade de detalhe e de polígonos (personagens, pedras e vegetação muito esculpidos).
- Iluminação volumétrica e partículas em excesso: inviável na GTX 1050 2 GB.
- Inimigos com tom "sério": os nossos são absurdos (ADR-019).

**Como chegar perto barato:**
- Cores lisas por face (flat shading) a partir de uma única textura de paleta.
- Luz de contorno (rim light) e sombra suave em tom azulado.
- Brilho (glow) só nas magias, intensidade testada na Fase 1 medindo FPS.

## ADR-008 · Plataforma e controles
**Status:** Aprovada (20/10/2026)

- Windows, teclado e mouse. WASD + mira, poucos botões de interação.
- Texto sempre disponível para conjurar. Voz opcional (Fase 6).
- Chat escrito para comunicação entre jogadores.

## ADR-009 · Regras base de conjuração
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- Toda magia custa mana.
- Magias duram poucos segundos.
- Enquanto a magia está sendo interpretada, o mago pode andar, mas não correr nem se defender.
- Mana só é descontada se a magia for conjurada com sucesso.

## ADR-010 · Teclas de chat e de magia
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- **Enter:** abre o chat (vai para o parceiro).
- **Q:** abre a caixa de conjuração, visualmente diferente do chat (borda e cor próprias).
- **1 a 4:** magias favoritas do grimório, conjuradas na hora, sem chamar a IA.
- **V (segurar):** conjurar por voz, quando a Fase 6 chegar.
- Nada de prefixos dentro do chat, para evitar conjurar sem querer.

## ADR-011 · Câmera: primeira pessoa, com opção de terceira pessoa
**Status:** Aprovada (20/10/2026)

- Padrão: primeira pessoa, com mãos low poly visíveis.
- Opção no menu de vídeo: terceira pessoa sobre o ombro.
- **Motivo do custo baixo:** o corpo inteiro do mago precisa existir e ser animado de qualquer jeito, porque o parceiro o vê. A terceira pessoa reaproveita esse corpo; o custo extra é a câmera e a mira.
- **Consequência:** a mira é sempre calculada a partir do centro da câmera, nos dois modos, para o resultado ser igual.

## ADR-012 · Aproximações de magia
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- No combate: a magia sai direto, com uma legenda curta do que foi entendido.
- No grimório: prévia antes de salvar, com possibilidade de ajustar.

## ADR-013 · Progressão por "ingredientes de imaginação"
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- Explorar o mundo libera ingredientes que ampliam o que se pode inventar. Não se desbloqueiam feitiços prontos.
- Ingredientes em três naturezas:
  - **Bons:** cura, crescimento (ex.: fazer crescer uma árvore).
  - **Neutros:** construção e deslocamento (ex.: parede de tijolos, teleporte).
  - **Maus:** caos (ex.: invocar bicho do mal, buraco negro, cegueira temporária).
- O interpretador só pode usar componentes cujos ingredientes o jogador já descobriu. Se a descrição pedir algo não descoberto, o jogo aproxima ou dá uma dica do tipo "você ainda não aprendeu a dobrar a gravidade".
- Risco das magias más: ver ADR-017. O que fica salvo: ver ADR-016.

## ADR-014 · Derrota e revive
**Status:** Aprovada (20/10/2026)

- Jogador caído pode ser revivido na hora se o parceiro tiver um item de reviver.
- Sem item: o parceiro carrega o corpo até uma estátua de reviver. São 3 estátuas por partida.
- Se os dois caírem, a equipe perde a partida.
- O que se perde ao perder: ver ADR-016.

## ADR-015 · Estrutura da partida: expedições curtas
**Status:** Aprovada (20/10/2026)

- Cada partida é uma expedição: entrar, explorar, enfrentar perigos e o chefe, voltar.
- Duração alvo: 20 minutos. Máximo: 30.
- 3 estátuas de reviver por expedição (ADR-014).

## ADR-016 · O que persiste
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-034 (22/10/2026)**

- Ingredientes descobertos: ficam para sempre (progressão do mago).
- Itens da expedição (reviver, consumíveis): perdidos se os dois jogadores caírem.

## ADR-017 · Magias "más" têm risco
**Status:** Aprovada (20/10/2026)

- Magias de natureza má são as mais fortes e podem sair pela culatra (ex.: o bicho invocado se volta contra quem invocou; a cegueira atinge quem está perto, inclusive o parceiro).
- **Revisado em 20/10/2026 a pedido do Vitor:** não há aviso de risco antes de conjurar, nem porcentagem. Quem escolhe o caminho do mal precisa arcar com as consequências sem poder voltar atrás.
- O jogador sabe apenas a regra geral (ingredientes maus são poderosos e perigosos) e vê a natureza da magia no grimório.
- Quando a magia sai pela culatra, o feedback precisa ser claro e engraçado (ex.: letreiro "SAIU PELA CULATRA!"), para ser lido como consequência e não como bug.

## ADR-018 · Mapas gerados a cada expedição, por módulos
**Status:** Aprovada (20/10/2026)

- Cada expedição gera um mapa novo.
- Método: montagem aleatória de módulos feitos à mão (clareira, ruína, ponte, caverna, pântano), encaixados como peças de Lego, com posições sorteadas de baús, inimigos, estátuas e ingredientes.
- Não haverá geração de terreno "do zero" no início: é mais difícil de deixar jogável e bonito.
- **Baús:** sim. Guardam ingredientes e itens. Possibilidade de baús-mímico que mordem.
- Ordem: Fases 1 a 6 usam uma arena fixa de testes; o gerador de mapas entra na Fase 7.
- **Adendo (21/10/2026, aprovado pelo Vitor):** o primeiro módulo, a **clareira**, foi adiantado e feito no padrão visual final ("igual à referência"). Ele vira a arena fixa das Fases 1 a 6 e o molde dos outros módulos. O gerador que encaixa módulos continua na Fase 7.

## ADR-019 · Inimigos absurdos
**Status:** Aprovada (20/10/2026)

- Inimigos no mesmo tom das magias: absurdos e engraçados (ex.: galinha zumbi, cogumelo com raiva, armário possuído).

## ADR-020 · Grimório pessoal com empréstimo
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-034 (22/10/2026)**

- Cada jogador tem seu próprio grimório.
- É possível emprestar uma magia ao parceiro durante a expedição; quem empresta continua com ela.
- O parceiro só usa a magia emprestada se já tiver descoberto os ingredientes dela.

## ADR-021 · Sem login na primeira versão
**Status:** Aprovada (20/10/2026)

- Grimório e ingredientes salvos no PC de cada jogador.
- O parceiro entra na partida por código de sala.
- Nenhum dado pessoal na nuvem.
- Desvantagem aceita: formatar o PC sem backup apaga o progresso. Rever se o jogo for para a Steam.

## ADR-022 · Coleta anônima de magias mal interpretadas
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- Quando a interpretação falhar ou sair muito diferente do pedido, o jogo envia ao Supabase apenas a frase, a ficha gerada e a versão do sistema. Sem nome, sem identificador pessoal.
- Uso: melhorar o interpretador.
- Retenção: 90 dias.

## ADR-023 · Voz na nuvem, só enquanto a tecla é segurada
**Status:** Aprovada (20/10/2026) · **Substituída pela ADR-032 (22/10/2026)**

- Transcrição via Groq (Whisper). Áudio enviado apenas enquanto V está pressionada.
- Latência estimada de 1,5 a 3 segundos entre soltar a tecla e a magia sair, a ser medida na Fase 6.

## ADR-024 · Magias privadas entre os dois jogadores
**Status:** Aprovada (20/10/2026)

- Sem galeria pública por enquanto (exigiria moderação). Ideia guardada para o futuro.

## ADR-025 · Atmosfera bonita com shaders baratos
**Status:** Aprovada (20/10/2026). **Revisada em 21/10/2026, ver ADR-031.**

- **Objetivo:** atmosfera bonita como na referência `docs/referencias/arte-conceito-01.png`, vinda de luz e cor, não de polígonos.
- **Usar:** shader toon (luz em degraus de cor), luz de contorno, névoa colorida por distância e altura, céu pintado, vegetação balançando por shader de vértice, água estilizada, brilho (glow) nas magias.
- ~~**Não usar no hardware mínimo:** névoa volumétrica, iluminação global em tempo real, muitas luzes com sombra simultâneas.~~ **Revisto pela ADR-031:** com o piso subindo para RTX 2060, essas três técnicas passam a ser permitidas, dentro do que a GPU aguentar (medir FPS de verdade, não só confiar no papel).
- **Menu de qualidade (Baixo e Alto):** o Alto liga enfeites extras (partículas, sombras, vegetação) para PCs fortes. Nenhum ajuste de qualidade pode mudar o combate (colisões, visibilidade de inimigos, áreas de efeito).
- **Fácil de mudar?** Sim, é camada visual.

## ADR-031 · Hardware mínimo sobe de GTX 1050 2GB para RTX 2060 6GB
**Status:** Aprovada (21/10/2026, a pedido do Vitor)

- **Problema:** depois de ver os primeiros prints do canto de atmosfera (ADR-030) comparados com a referência visual, o Vitor achou o resultado limitado demais pela GTX 1050 2GB e quer o jogo mais "cheio" — o suficiente para chegar perto da referência.
- **Escolha:** o novo PC de referência (piso mínimo) passa a ser: **CPU Ryzen 5 3600 ou Intel i5-9400F (6 núcleos), GPU RTX 2060 6GB, 16GB de RAM.** O PC antigo do Vitor (Pentium G5400, GTX 1050 2GB) deixa de ser o piso oficial, mas continua sendo testado informalmente como "PC fraco" de referência, já que ainda é o hardware que o Vitor tem em mãos para jogar e testar.
- **O que isso libera (pedido do Vitor: só iluminação/efeitos/densidade de cena, mantendo o visual tosco/low poly do ADR-007 e o tom absurdo do ADR-019 — ele não quer modelos mais detalhados, só o jogo "parecendo mais" com a referência em luz, cor e atmosfera):**
  - Névoa volumétrica, iluminação global em tempo real (SDFGI do Godot) e mais luzes com sombra simultâneas (ADR-025, revisado).
  - Brilho (glow) mais forte nas magias e fontes de luz.
  - Cenas mais densas: mais inimigos, projéteis e efeitos ao mesmo tempo (os limites da seção 5 da proposta técnica podem subir, mas isso é ajuste de game design, não decidido aqui — fica para quando o Vitor pedir especificamente).
- **O que continua igual:** ADR-007 (low poly "feiozinho de propósito") e ADR-019 (inimigos absurdos) não mudam. Mais luz e efeito, não mais polígono.
- **Risco aceito:** o jogo pode ficar pesado demais para o Pentium G5400/GTX 1050 que o Vitor tem agora. Ele sabe disso e decidiu aceitar, priorizando o resultado visual. Se algum dia o jogo for compartilhado com alguém que só tem hardware mais fraco, um "modo Baixo" de verdade (ADR-025) precisa ser testado nessa máquina antes.
- **Consequências práticas:** `docs/proposta-tecnica.md` (seção 8) e a nota "Requisito mínimo de hardware" neste arquivo foram atualizadas. SDFGI e névoa volumétrica ainda não foram ligados no código nesta sessão — são mudanças de Environment inteiras, melhor testadas com FPS real no PC do Vitor (uma sessão na nuvem sem GPU não mede isso direito). O que já foi feito nesta sessão: brilho (glow) e sombra mais visíveis no canto de atmosfera, dentro do que dava para confirmar com o render por software (ver `docs/contexto/diario.md`).
- **Fácil de mudar?** Sim, é um número de referência; pode subir ou descer de novo facilmente.

## ADR-026 · Sistema de som por camadas
**Status:** Aprovada (20/10/2026)

- Som montado como as magias: camadas de material + ação (ex.: "pedra + voo", "fogo + explosão"), com pequena variação de tom a cada execução.
- Som posicional 3D.
- Limite de sons simultâneos (valor definido medindo desempenho e clareza).
- Volumes separados no menu: música, efeitos, vozes, interface.
- Fontes: pacotes de domínio público (ex.: Kenney), Freesound com licença conferida por arquivo, geradores de efeito retrô (ex.: jsfxr). Toda licença registrada num arquivo de créditos.

## ADR-027 · Música
**Status:** Aprovada (20/10/2026)

- Épica na exploração, bobinha e saltitante no combate. Transição suave entre as duas.
- Música gerada por IA é permitida se for gratuita.
- **Ressalva:** planos gratuitos de geradores de música costumam proibir uso comercial. Na fase A não importa; antes de qualquer lançamento comercial, cada faixa precisa ter licença compatível ou ser substituída. Registrar a origem de cada faixa nos créditos.

## ADR-028 · Sons das criaturas gravados pelos jogadores
**Status:** Aprovada (20/10/2026)

- O Vitor e o amigo gravam vozes e sons das criaturas (ex.: galinha zumbi, armário possuído).
- O jogo aplica variações de tom e velocidade para multiplicar as gravações.

## ADR-029 · Voz entre jogadores pelo Discord
**Status:** Aprovada (20/10/2026)

- Conversa por voz entre os jogadores fica no Discord. O jogo não terá voz entre jogadores.
- O jogo cuida apenas da voz que vira magia (tecla V, ADR-023) e do chat escrito (ADR-010).

## ADR-030 · Canto de atmosfera na arena da Fase 1
**Status:** Aprovada (20/10/2026)

- Um canto da arena de testes recebe o tratamento visual completo (ADR-025), para medir cedo quanto o hardware mínimo aguenta.

---

## ADR-032 · Forja de Runas: magia feita só de runas, sem escrita e sem IA
**Status:** Aprovada (proposta "Forja de Runas" aprovada em 21/10/2026; escrita retirada em 22/10/2026)

- **Problema:** magia por texto livre gera decepção (o jogador pede um "godzilla" e vem um cilindro laranja), depende de IA e obriga a gerar modelos na hora, sem a qualidade de algo modelado à mão.
- **Alternativas:** texto livre com IA (ADR-002), texto limitado por dicionário com IA de apoio (proposta de 21/10), só runas.
- **Escolha:** só runas. O jogador coloca runas na bigorna da forja e martela; a combinação vira a magia. Não existe escrita, então não existe "testar se a palavra passa".
  - Receitas fixas, estilo Dragon City: a mesma combinação dá sempre a mesma magia.
  - Toda combinação dá alguma coisa. Combinação sem receita dá uma versão básica e engraçada; as receitas certas dão as magias especiais.
  - Dois tipos de runa: de **forma** (decidem o modelo: arremesso, prende, gravitação, quebrar, vida) e de **elemento** (decidem material, cor e efeito: fogo, água, feroz). Assim modelamos poucas formas e o elemento troca a pele; receitas especiais (golem de fogo, galinha) têm modelo próprio.
  - A forja é um posto avançado numa caverna mística. 4 espaços de magia por jogador; magias padrão com cara própria. A bigorna treme e reage ao resultado (magias rápidas e lentas).
  - Tudo modelado à mão antes, nada gerado em tempo de jogo.
- **Motivo:** decisão do Vitor em 22/10/2026 ("tirar o tipo de escrita, só trazer o resultado sob soma das runas"). Elimina a parte mais frágil (adivinhar palavras e a IA errar) e o custo e risco de IA no núcleo.
- **Consequências:** a Fase 2 como estava escrita ("magia por texto com IA real") perde o sentido. O código do porteiro (Supabase + Groq) e do `Interpretador` fica guardado no repositório, sem apagar, até o plano de fases ser reescrito. A proposta técnica precisa ser revista. ADRs 002, 003, 009, 010, 012, 013, 022 e 023 ficam substituídas.
- **Fácil de mudar?** Médio. O sistema de fichas e o validador continuam servindo: só muda quem gera a ficha (a receita, em vez da IA).

## ADR-033 · A magia forjada vira um medalhão na barra
**Status:** Aprovada (22/10/2026)

- As runas se fundem na bigorna num **medalhão** redondo e lapidado, com o símbolo misturado no meio e aceso na cor do elemento. Ele ocupa um dos 4 espaços da barra de magias.
- Para trocar uma magia, quebra-se um medalhão e o espaço fica livre.
- Escolha visual do Vitor entre três opções (pedra derretida, medalhão, cristal pontudo). Precisa de imagem de referência antes de modelar.

## ADR-034 · O que fica entre expedições: grimório e melhorias da forja
**Status:** Aprovada (22/10/2026)

- As runas e os medalhões recomeçam a cada expedição (substitui a ADR-016 e a ADR-020).
- Ficam para sempre: o **grimório**, com toda receita já descoberta, e **melhorias permanentes da forja**.
- Ainda a definir: quais melhorias a forja ganha e como se conquistam.

## ADR-035 · Plano de fases da Forja de Runas
**Status:** Aprovada (22/10/2026)

- **Problema:** o plano antigo (Fases 2 a 10) girava em torno da IA por texto, abandonada pela ADR-032.
- **Escolha:** plano novo na seção 10 da `proposta-tecnica.md`: Fase 2 ciclo da forja solo, Fase 3 cooperativo, marco de teste com o amigo, Fase 4 expedição mínima, Fase 5 acabamento visual, Fase 6 áudio, Fase 7 conteúdo, Fase 8 otimização.
- **Escolhas do Vitor na aprovação:**
  - Runas no cooperativo: quem pega leva, e pode largar no chão para o parceiro.
  - A expedição começa com 2 medalhões padrão e 2 espaços vazios.
  - Até 3 runas por forja: uma de forma e até duas de elemento.
  - O primeiro teste com o amigo acontece depois do cooperativo pronto.
- **Decidido pelo Claude como gestor:** mana continua, com recarga curta por medalhão (números ajustados jogando); caverna e medalhão provisórios até a Fase 5; receitas num arquivo de dados legível.
- **Saem:** voz, teste de 50 frases na IA, Supabase (o projeto pode ser pausado).
- **Fácil de mudar?** Sim, é a ordem do trabalho.

## ADR-036 · Renderizador Forward+ e passe de luz e paleta antes do teste com o amigo
**Status:** Aprovada (22/10/2026)

- **Problema:** a auditoria visual (`docs/auditoria-visual-ambiente.md`) achou o projeto travado no renderizador Compatibility, apesar de a proposta técnica e a ADR-031 contarem com Forward+. Névoa volumétrica e SDFGI nunca funcionaram em nenhum PC. A mesma auditoria mediu que o cenário estava claro demais, não saturado demais.
- **Escolhas do Vitor:**
  - Renderizador passa para **Forward+** (`project.godot`). As sessões na nuvem continuam renderizando em Compatibility (sem GPU), então o print da nuvem é só aproximado.
  - Fazer agora só os itens baratos da auditoria (medição de FPS e de cor, renderizador, luz e exposição, paleta por camadas). Terreno, composição, peças no Blender e céu pintado ficam para a Fase 5, como manda a ADR-035.
  - Criar a skill `personagem-low-poly` (`.claude/skills/`) com o roteiro fixo de personagem.
- **Consequências:** névoa volumétrica ficou bem mais fraca (0,03 para 0,005) para não lavar a arena quando ligar de verdade no Forward+; precisa do olho do Vitor. A meta de FPS agora se mede com `ferramentas\medir_fps.bat` no PC com a RTX 2060.
- **Fácil de mudar?** Sim. Renderizador é uma linha; luz e paleta são números.

## ADR-037 · Agente crítico com força de cliente
**Status:** Aprovada (22/10/2026, pedido do Vitor)

- **Problema:** as entregas visuais saíam "boas o bastante" pelo olho de quem fez. O Vitor quer alguém que critique sem dó, compare com as referências e diga onde estamos e para onde vamos.
- **Escolha:** um quarto agente, o **crítico** (`.claude/agents/critico.md`), no papel do jogador chato que critica tudo na Steam. Roda depois de toda entrega visual ou de jogabilidade, dá nota de 0 a 10, lista o que está ruim (do pior para o menos pior) e as 3 mudanças que mais aproximam da referência, e termina com APROVADO ou REPROVADO.
- **Força:** "cliente tem sempre razão". O Claude principal é o mediador: pode argumentar, mas acata, exceto quando a exigência ferir hardware mínimo (ADR-031), orçamento (ADR-006) ou decisão aprovada; nesses casos leva ao Vitor.
- **Consequências:** amplia a equipe da ADR-005 (de 3 para 4 especialistas). Gasta cota a cada rodada; para economizar, o crítico só olha prints e medições, não roda o jogo, e é chamado uma vez por entrega, não a cada ajuste.
- **Fácil de mudar?** Sim.

## ADR-038 · Contexto separado: decisões, estado atual e diário
**Status:** Aprovada (22/10/2026, pedido do Vitor)

- **Problema:** este arquivo misturava as decisões com um diário longo de implementação. Toda sessão do Claude Code lia tudo, gastando cota com histórico que não ajuda na tarefa do dia, e não havia um lugar curto dizendo "onde paramos".
- **Escolha:** três arquivos com papéis diferentes:
  - `docs/decisoes.md`: só as decisões (a "lei" do projeto).
  - `docs/contexto/estado-atual.md`: o bilhete de passagem de turno. Curto, reescrito no fim de toda sessão: onde paramos, o que está quebrado, próximo passo.
  - `docs/contexto/diario.md`: histórico do que foi feito, achados e limitações. Só se acrescenta no fim; só se lê quando precisar de um detalhe antigo.
- **Junto:** duas regras novas no `CLAUDE.md`: proibido esconder erro em silêncio, e proibido criar complexidade antes de uma tarefa precisar dela.
- **Fácil de mudar?** Sim.

## ADR-039 · Layout oficial do HUD fixado antes da barra de medalhões
**Status:** Aprovada (22/10/2026, pedido do Vitor)

- **Problema:** a Fase 2 cria várias peças de tela (barra 1 a 4, contador de runas, mana, aviso de interação). Se cada uma nascer solta, o HUD vira remendo e o layout final vira retrabalho.
- **Escolha:** fixar agora as posições finais, seguindo a referência (`docs/referencias/arte-conceito-01.png`), mesmo com visual provisório:
  - Canto superior esquerdo: retrato do mago com vida e mana; logo abaixo, contador de runas e estados ativos.
  - Centro: mira.
  - Embaixo no centro: barra com os 4 medalhões, número da tecla e recarga em cada um.
  - Logo acima da barra: aviso de interação (ex.: "E · forjar").
  - Canto inferior direito: espaço reservado para o minimapa (círculo com o N); o minimapa de verdade entra quando houver mapa para mostrar.
- **Decidido pelo Claude como gestor:** tamanhos, margens e o visual provisório. O Vitor julga pelo print.
- **Pendência (22/10/2026):** falta a **referência visual do HUD e do medalhão**, a ser gerada pelo Vitor. Até ela chegar e ser aprovada, o HUD fica com formas lisas em cinza e nas cores dos elementos; não inventar estilo (moldura, ornamento, textura) sem ela.
- **Escolhas do Vitor (22/10/2026, depois do primeiro print):** sem selo de nível no retrato (o jogo não tem nível); medalhão continua redondo (ADR-033), dentro de uma moldura em losango como na referência; mãos em primeira pessoa mais baixas e afastadas para não encostar na barra. Estilo do HUD 100% provisório (formas lisas) até o Vitor aprovar uma referência visual do HUD.
- **Fácil de mudar?** Sim, é camada de interface.

## ADR-040 · Arte feita no próprio projeto, sem pacotes prontos
**Status:** Aprovada (22/10/2026, escolha do Vitor)

- **Alternativas:** pacotes gratuitos de domínio público (Kenney, Quaternius) para objetos genéricos, ou tudo modelado no projeto.
- **Escolha:** tudo feito no projeto (modelagem do Claude + texturas pintadas pelo Vitor). Não procurar pacotes de modelos prontos.
- **Não muda:** sons de pacotes de domínio público continuam permitidos (ADR-026).
- **Fácil de mudar?** Sim.


## ADR-041 · Magia por texto com IA removida do jogo
**Status:** Aprovada (22/10/2026, pedido do Vitor: "não tem mais magia por IA")

- **Problema:** a ADR-032 tirou a escrita do jogo e mandou guardar o código do porteiro e do `Interpretador` até o plano ser reescrito. O plano foi reescrito (ADR-035, que já tirou o Supabase), mas o jogo ainda carregava o porteiro a cada partida (com a chave pública do Supabase dentro), a tecla Q continuava cadastrada e o mago ainda tinha o caminho de conjurar por texto.
- **Escolha:** remover do jogo a caixa de texto, o porteiro, o `Interpretador`, a tecla Q e o "conjurar por texto", com os testes deles e a ferramenta `checar_porteiro.sh`. A conferência de "a ficha faz alguma coisa de verdade" foi para o `Validador` (`sem_efeito_real`), porque as receitas de runas continuam usando.
- **Fica:** os componentes de magia e as fichas de exemplo (usados pelas receitas e pelos testes).
- **Supabase (escolha do Vitor, 22/10/2026: apagar):** o projeto `arcane-forge` (só tinha as tabelas e a função da magia por IA) foi pausado pelo Claude; apagar de vez é pelo painel, porque a ferramenta do Claude não tem essa opção. A pasta `supabase/` saiu do repositório junto. Os outros projetos do Vitor no Supabase não foram tocados.
- **Fácil de mudar?** Sim: o código removido continua no histórico do git.


## ADR-042 · Agente animador (dev de animação)
**Status:** Aprovada (22/10/2026, pedido do Vitor)

- **Problema:** o Vitor quer que o jogador veja o jogo e pense "caramba, o dev da animação trabalhou". Até aqui a animação era feita de passagem por quem modelava ou programava a peça, sem um dono.
- **Escolha:** um quinto agente, o **animador** (`.claude/agents/animador.md`), com os princípios clássicos de animação e de sensação de jogo (antecipação, comprimir e esticar, continuação, tempo, pausa de impacto, reação a dano, interface que anima). Ele implementa (edita arquivos) e prova o movimento com folha de quadros, GIF e teste automático, já que a nuvem só tira prints parados.
- **Junto:** o crítico (ADR-037) continua avaliando depois dele.
- **Consequências:** amplia a equipe da ADR-005 (de 4 para 5 especialistas). Gasta cota a cada uso; chamar por entrega com movimento, não a cada ajuste. Ele respeita hardware mínimo, low poly de propósito e regras de jogo no Host.
- **Atualização (23/10/2026, auditoria pedida pelo Vitor):** o animador virou diretor técnico de animação: diagnostica, propõe e só implementa com autorização; avalia cada peça com notas de 0 a 5 em seis eixos (arte, legibilidade, resposta, som e efeitos, estabilidade, desempenho), cada nota com a origem (visto, medido, deduzido, pendente), sem média que esconda defeito grave; tem critério objetivo de "pronto". Para enxergar movimento na nuvem, usa `ferramentas/gravar_quadros.sh` (gravação com tempo fixo pelo Movie Maker do Godot, folha de quadros, GIF e mapa de som). Primeira auditoria em `docs/auditoria-animacao.md`.
- **Fácil de mudar?** Sim.


## ADR-043 · Refinar os modelos antes do teste com o amigo, começando pelo mago
**Status:** Aprovada (23/10/2026, decisão do Vitor)

- **Problema:** a ADR-035 deixava o acabamento visual (Fase 5) para depois do teste com o amigo. O Vitor preferiu refinar os modelos agora, seguindo a referência à risca, a começar pelo mago, já dentro do jogo e com "uma mãozinha bonita e dedinhos com movimento suave e fofo". Animação fina fica para depois dos modelos (conversa de 23/10/2026: animar bem um modelo que ainda vai mudar é retrabalho).
- **Escolha:** o mago passa a ser o modelo com esqueleto feito no Blender por script, pela folha do Vitor (`arte/personagens/mago/mago.py`, ~3.600 triângulos), com dois ossos por dedo e animações Parado, Andar, Conjurar, ErguerCajado e Dano; em primeira pessoa, um modelo próprio dos braços (`mago_1p.glb`, ~1.100 triângulos) com Parado1P (ondinha dos dedos) e Conjurar1P. O boneco feito em código saiu.
- **Não muda:** low poly de propósito (ADR-007), mago tosco (ADR-019), cor chapada por face até as texturas pintadas pelo Vitor.
- **Cajado na mão direita nos dois modelos** (escolha do Vitor em 23/10/2026, como na arte conceito; a folha o mostra na esquerda).
- **Fácil de mudar?** Sim: o modelo é regerado pelo script.

---

## Status da descoberta
Encerrada em 20/10/2026. `docs/proposta-tecnica.md` aprovada em 20/10/2026.

## Requisito mínimo de hardware (referência)
**Atualizado pela ADR-031 (21/10/2026):** o piso oficial agora é CPU Ryzen 5 3600 ou Intel i5-9400F (6 núcleos), GPU RTX 2060 6GB, 16GB de RAM.
O PC antigo do Vitor (Pentium G5400, GTX 1050 2GB, 16GB RAM) deixa de ser o piso oficial, mas continua sendo o hardware real que ele tem para jogar e testar — vale a pena medir FPS nele também, mesmo não sendo mais o alvo mínimo.
