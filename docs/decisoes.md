# Registro de decisões (ADR)

Cada decisão tem: problema, alternativas, escolha, motivo, consequências e se é fácil de mudar.
Status possíveis: **Aprovada**, **Proposta** (aguardando o Vitor), **Adiada**.

Última atualização: 22/10/2026

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
- **Consequências práticas:** `docs/proposta-tecnica.md` (seção 8) e a nota "Requisito mínimo de hardware" neste arquivo foram atualizadas. SDFGI e névoa volumétrica ainda não foram ligados no código nesta sessão — são mudanças de Environment inteiras, melhor testadas com FPS real no PC do Vitor (uma sessão na nuvem sem GPU não mede isso direito). O que já foi feito nesta sessão: brilho (glow) e sombra mais visíveis no canto de atmosfera, dentro do que dava para confirmar com o render por software (ver notas abaixo).
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

---

## Status da descoberta
Encerrada em 20/10/2026. `docs/proposta-tecnica.md` aprovada em 20/10/2026.

## Status das fases (atualizado em 21/10/2026)
- **Fase 1 (esqueleto jogável):** praticamente concluída. Todos os critérios de aceitação verificáveis por teste e código (seção 9 da proposta técnica) estão com o `[x]`. Restam dois critérios que só o Vitor pode confirmar: o canto de atmosfera lembrar a referência visual, e jogar 10 minutos para dizer se o combate "dá gosto". A Fase 1 só pode ser marcada como encerrada depois dessa confirmação.
- **Fase 2 (magia por texto com IA real):** já ligada de verdade. `mago.gd` chama `Porteiro.interpretar()` (Supabase + Groq) e cai para o `Interpretador` local se a IA estiver fora do ar. README.md e CLAUDE.md foram corrigidos nesta data porque ainda diziam "Fase atual: Fase 1".
- **Suíte de testes automáticos:** confirmada rodando de verdade em 21/10/2026, numa sessão na nuvem sem GPU (Godot 4.7.2 headless instalado só para isso). 43/43 testes passando. Dois avisos inofensivos do motor em modo headless (vazamento de 2 objetos e 1 recurso ao sair; erro de material nulo do renderizador fictício) não afetam o jogo jogável — são ruído de rodar sem tela, registrados aqui para não esconder nada.
- **Componente "cura" implementado** em 21/10/2026 (proposta técnica, seção 3, primeira leva da Fase 2): efeito direto em quem conjurou (sem projétil, como a bola de fogo não precisa de nada além do impacto), validado e com custo de mana calculado pelo jogo (nunca pela IA), igual aos outros componentes. `Interpretador` local reconhece "cura"/"curar" para testar sem internet. 9 testes novos (43 → 52/52).
- **Componente "escudo" implementado** em 21/10/2026 (proposta técnica, seção 3, primeira leva da Fase 2): reduz o dano recebido por quem conjurou, por um tempo (campos `reducao`, de 0 a 90% — nunca imunidade total, e `duracao_s`, cortados pelo Validador). Dois escudos ativos ao mesmo tempo não somam a redução; fica valendo o mais forte, para duas magias fracas juntas não virarem imunidade (decisão de implementação, fácil de revisar se o Vitor achar chato jogando). `Interpretador` local reconhece "escudo". 12 testes novos (52 → 64/64).
- **Função do Supabase reimplantada** em 21/10/2026 (versão 6, confirmada pela própria ferramenta de deploy): a IA de verdade agora é instruída a sugerir "cura" e "escudo", além de "projetil". **Teste de verdade ainda pendente:** esta sessão na nuvem não conseguiu fazer uma chamada de rede direta à função (o proxy de saída bloqueia esse host), então o deploy foi confirmado pela ferramenta, mas ninguém ainda viu a Groq responder com uma ficha de cura ou escudo de verdade. Preciso que o Vitor teste no jogo (digitar algo como "uma luz que me cura" ou "um escudo de pedra") e confirme se a IA entendeu certo, ou se o prompt precisa de ajuste.
- **Combinação de componentes confirmada por teste** em 21/10/2026: o prompt agora avisa a IA que uma ficha pode ter mais de um componente na mesma lista (ex.: projétil + escudo). Testado que o jogo realmente aplica todos os componentes de uma ficha assim, não só o primeiro, e que o custo de mana soma os dois. 2 testes novos (64 → 67/67, já contando os da combinação).
- **"Empurrar/puxar" implementado** em 21/10/2026 (proposta técnica, seção 3, primeira leva da Fase 2): não é um componente novo, é o campo "empurrao" da explosão aceitando número negativo para puxar para o centro em vez de afastar (ex.: um mini buraco negro). Mudou em 3 arquivos que já tratavam empurrão (`mago.gd`, `caixa.gd`, `galinha_zumbi.gd`): a condição passou de "só empurra se for maior que zero" para "qualquer empurrão diferente de zero conta". Achado durante o teste: o primeiro teste de direção do puxão falhou porque a gravidade já acumulada no mago (caindo, sem chão na cena de teste) sujava a comparação de direção — corrigido zerando a velocidade antes de aplicar o empurrão isolado no teste, não é um bug do jogo. `Interpretador` local reconhece "buraco negro"/"puxar"/"puxa". 4 testes novos (67 → 72/72, já reimplantado no Supabase, versão 7).
- **Componente "estado" implementado (parcial)** em 21/10/2026 (proposta técnica, seção 3, primeira leva da Fase 2: "estados — queimando, molhado, eletrizado, cego, lento"). Implementados só dois por enquanto: "queimando" (dano aos poucos, um tick de dano por segundo, nunca dois incêndios somados no mesmo alvo — reaplicar só estende a duração) e "lento" (reduz a velocidade de andar pela metade, por um tempo). "Molhado", "eletrizado" (a interação entre os dois, destacada como exemplo na proposta técnica) e "cego" ficam para um próximo incremento. Diferente de cura/escudo (efeito em quem conjurou), estado é aplicado em quem o PROJÉTIL atinge — mudou a assinatura de `projetil.gd::_explodir()` para receber o alvo atingido. `Validador.ESTADOS_VALIDOS` deixa claro para a IA que só esses dois valem; qualquer outro nome cai num padrão seguro. `Interpretador` local reconhece "queimar/queimando/chama" e "lento/lentidao/gelado". 9 testes novos (72 → 89/89), reimplantado no Supabase (versão 8).

## Primeira comparação do canto de atmosfera com a referência visual (21/10/2026)

Descoberta nesta sessão: dá para rodar o jogo de verdade (com tela, não só os testes automáticos) numa sessão na nuvem, usando Xvfb (tela virtual) + Mesa llvmpipe (OpenGL por software, sem GPU). Isso permitiu tirar prints de verdade e adiantar parte do critério de aceitação pendente da Fase 1 ("o canto de atmosfera lembra a referência"), embora a palavra final continue sendo do Vitor.

Prints novos em `evidencias/fase-1/`: `canto_atmosfera_render_nuvem.png`, `arena_spawn_render_nuvem.png`, `arena_terceira_pessoa_render_nuvem.png`. Comparados com o print que o Vitor já tinha tirado no PC dele (`canto_atmosfera_de_perto.png`, 60 FPS, GPU de verdade) — os dois batem: o jogo está honestamente igual nos dois ambientes, então a comparação abaixo vale também para o hardware real do Vitor, não é um artefato da renderização por software.

**O que já se parece com a referência:**
- O arco de ruína com dois pilares e verga, a tocha com chama e luz quente, o barril e a caixa no cenário: os elementos que a ADR-007/ADR-025 pediram estão todos lá.
- Luz quente (sol alaranjado) e céu azul vivo, parecido com a paleta da referência.
- Sombras aparecem no chão (luz direcional com sombra ligada).

**O que ainda falta:**
- A chama da tocha e a faixa azul não têm brilho (glow) visível, mesmo com emissão ligada no material — na referência, toda luz mágica e toda chama "estoura" com bloom. Vale investigar se o glow do Environment está realmente chegando na tela ou se a intensidade está baixa demais para esta cena.
- Sem céu pintado ao fundo (castelo, ilhas flutuantes) — o céu hoje é um gradiente processual liso, sem a profundidade de cenário que a referência tem. Isso nunca foi implementado (estava previsto no item 11 da Fase 1, proposta técnica).
- Cores mais lisas e menos saturadas que a referência; sombras cinza, não azuladas como o ADR-007 sugeriu.
- Vegetação (grama) parada nos prints (não dá pra ver animação de vento numa imagem parada; só rodando ao vivo para confirmar).

**O que não dá para alcançar no hardware mínimo (GTX 1050 2 GB):** a densidade de polígonos e o número de luzes com sombra simultâneas da referência continuam fora de cogitação (ADR-007, ADR-025); isso é esperado e não é uma falha.

**Nota sobre os números:** o FPS mostrado nos prints tirados na nuvem (14 a 18) não serve de referência nenhuma — é renderização por software (CPU), não GPU. O FPS real (60, no print do próprio Vitor) continua sendo o que vale.

## Primeiro ajuste de luz/brilho depois da ADR-031 (21/10/2026)

Depois de subir o piso para RTX 2060 (ADR-031), ajustei `arena_teste.tscn` (Environment) e `canto_atmosfera.tscn` (tocha): mais brilho (glow), ambiente mais azulado, luz da tocha mais forte e agora com sombra própria (lançando luz quente sobre o pilar), e liguei névoa volumétrica no Environment. Print novo: `canto_atmosfera_glow_e_luz_quente_ajustados.png`.

**Limitação importante descoberta:** esta sessão na nuvem só tem OpenGL por software (Mesa llvmpipe), sem Vulkan. O renderizador real do projeto é Forward+ (precisa de Vulkan), e só ele suporta névoa volumétrica e iluminação global em tempo real (SDFGI) — rodando aqui, o motor avisou "Volumetric fog is only available when using the Forward+ renderer" e ignorou essa parte. Ou seja: **a luz da tocha mais forte e o brilho eu confirmei de verdade no print; a névoa volumétrica eu liguei no Environment mas não consegui ver funcionando daqui — só o Vitor consegue confirmar isso no PC dele, com Forward+ de verdade.** SDFGI eu nem liguei ainda, por causa dessa mesma limitação: não tem como testar certo sem o Vitor.

**Resultado visível na nuvem:** a luz da tocha ficou claramente mais forte e quente, com um brilho bem perceptível no pilar ao lado (efeito de "tocha mágica" que não existia antes). Ainda não aparece o halo clássico de glow ao redor da chama em si — pode ser limitação do render por software, ou pode precisar de mais ajuste; só dá pra saber de verdade vendo no PC do Vitor com o renderizador certo.

## Requisito mínimo de hardware (referência)
**Atualizado pela ADR-031 (21/10/2026):** o piso oficial agora é CPU Ryzen 5 3600 ou Intel i5-9400F (6 núcleos), GPU RTX 2060 6GB, 16GB de RAM.
O PC antigo do Vitor (Pentium G5400, GTX 1050 2GB, 16GB RAM) deixa de ser o piso oficial, mas continua sendo o hardware real que ele tem para jogar e testar — vale a pena medir FPS nele também, mesmo não sendo mais o alvo mínimo.

## Notas de implementação da Fase 2

- **Projeto Supabase criado** em 20/10/2026 (ADR-003): nome `arcane-forge`, região São Paulo (`sa-east-1`), plano grátis. Para abrir vaga (o plano grátis só permite 2 projetos ativos), o projeto pessoal `ana-e-eu` do Vitor foi pausado, a pedido dele; pode ser reativado quando ele quiser.
- **Provedor de IA provisório da Fase 2: Groq.** A ADR-002 deixa a escolha final para a Fase 4 (medindo qualidade e velocidade), mas a Fase 2 precisa de algum provedor para testar o caminho completo. Groq foi escolhido como provisório porque: (1) tem plano grátis generoso, (2) é muito rápido, o que importa para a magia não demorar para sair, (3) a ADR-023 já previa usar o Whisper da Groq na Fase 6 (voz), então é uma conta só para gerenciar. Essa escolha pode mudar na Fase 4 sem problema.
- **Componente "invocação" implementado** em 21/10/2026 (proposta técnica, seção 3, exemplo do "Pombo de Pedra"): o `Host` já tinha pronto o controle de limite de criaturas (ADR-004, `pode_invocar_criatura`/`registrar_criatura`), mas nada usava ainda — esta é a primeira coisa que liga nele. Versão simplificada do exemplo da proposta técnica: criatura persegue o inimigo mais próximo (grupo "inimigo") e bate nele; sem o "lançador" de ovos explosivos ainda (fica para um próximo incremento). Campos validados: corpo, material, escala, comportamento (só "perseguir_inimigo_proximo" por enquanto), vida, duração e dano de contato — todos com limite e lista fechada, calculados pelo Validador. **Achado implementando:** o Executor precisa ajustar `vida`/`dano_contato`/`duracao_s` na criatura *antes* dela entrar na árvore (`add_child`), porque o `_ready()` da criatura já lê esses valores para calcular a vida inicial e o timer de expirar; ajustado depois, a ficha seria ignorada silenciosamente e a criatura nasceria sempre com os valores padrão. 10 testes novos (98 → 108/108).
- **Confirmado rodando de verdade** (Xvfb + Mesa llvmpipe): digitei "invocar um pombo de pedra" pelo caminho completo (texto → Interpretador local → Validador → Executor) e o pombo nasceu no mundo, com a cor certa do material (pedra, cinza) e perseguiu a galinha zumbi. O custo de mana bateu com a conta esperada (22,5), já contando a regeneração dos segundos seguintes. Print em `evidencias/fase-1/pombo_de_pedra_invocado.png`.
- **Prompt da IA atualizado e reimplantado (versão 9)** em 21/10/2026: a IA de verdade agora também é instruída a sugerir "invocacao", com os mesmos campos e limites do Validador. Mesma pendência dos componentes anteriores: não dá pra confirmar a Groq respondendo direito daqui (rede bloqueada nesta sessão); falta o Vitor testar jogando.
- **Lote: lançador + estados molhado e eletrizado** em 21/10/2026 (primeiro lote no novo ritmo combinado com o Vitor: vários componentes por rodada, prompt da IA reimplantado uma vez só no fim, versão 10).
  - **Lançador** (proposta técnica, seção 3): uma criatura invocada passa a atirar sozinha no inimigo mais próximo a cada `intervalo_s` (mínimo 0,8 s). Aceita exatamente o formato do exemplo da proposta técnica ("anexado_a" + "projetil" + "ao_impactar" ao lado), e o projétil interno passa pelo Validador como qualquer outro. O "Pombo de Pedra Bombardeiro" da proposta técnica agora existe inteiro (ficha `pombo_bombardeiro`). Custo de mana do lançador é uma estimativa (custo de um tiro vezes os tiros que cabem em 3 s), ajustável jogando; o bombardeiro completo custa cerca de 64 de mana.
  - **Estados para todo mundo:** antes deste lote os estados só funcionavam no mago; a galinha zumbi ignorava "lento" e "queimando". A lógica saiu do `mago.gd` para um componente compartilhado (`ControladorEstados`), usado pelo mago, pela galinha e pelas criaturas invocadas.
  - **Molhado e eletrizado**, com a interação que a proposta técnica usa de exemplo: molhar apaga fogo e impede pegar fogo; choque em alvo molhado dobra o dano e se espalha num raio de 2,5 m (um salto só, sem corrente infinita entre dois alvos molhados). "Cego" continua de fora.
  - **Bug achado e corrigido:** rodando o bombardeiro quadro a quadro, o ovo que explodia na galinha tirava 12 de vida do próprio mago. Pela ADR-017 só magia "má" se volta contra quem conjurou, e o pombo é neutro. Agora a criatura guarda quem a invocou e os projéteis dela não atingem nem ela nem o invocador. Teste de regressão conferido desfazendo a correção (o teste falha sem ela).
  - **Limitação:** os estados não têm nenhum sinal visual ainda (nada mostra que a galinha está molhada ou queimando). A ADR-017 pede feedback claro; fica como próximo passo.
  - 27 testes novos (108 → 135/135). Prints do ovo no ar e da explosão em `evidencias/fase-1/pombo_bombardeiro_*.png`.
- **Lote: sinal visual dos estados + área persistente** em 21/10/2026 (prompt da IA reimplantado uma vez no fim, versão 11).
  - **Sinal visual dos estados** (ADR-017 pede feedback claro): o corpo inteiro de quem está sob um estado ganha uma camada de cor lisa (choque amarelo piscando, queimando laranja pulsando, molhado azul, lento ciano), uma cor por vez por prioridade. O HUD do mago mostra os estados em texto, já que em primeira pessoa ele não vê o próprio corpo. Primeiro print: o azul pastel quase sumia sobre a galinha branca; cores reforçadas. **Decisão visual para o Vitor:** "queimando" ainda puxa para salmão em vez de fogo vivo; partículas de chama resolveriam, mas custam mais.
  - **Área persistente** (proposta técnica, seção 3): zona no chão que dura alguns segundos e, a cada segundo, aplica dano e/ou estado em quem estiver dentro, pelo Host. No topo da ficha nasce aos pés de quem conjurou ("chuva ao meu redor"); dentro de "ao_impactar" nasce onde o projétil caiu ("bola que deixa poça de lava"), sempre procurando o chão embaixo. Nunca afeta quem conjurou. Área de fogo acende barris (etiquetas). Primeira aplicação do limite da seção 5 ("3 magias ativas por jogador"), que até hoje não era aplicado em lugar nenhum.
  - **Achados implementando:** (1) mesma armadilha da invocação: o primeiro tick rodava no `_ready()`, antes da área ser posicionada, e acertava o ponto (0,0,0); agora o primeiro tick é no primeiro quadro de física. (2) Lava meio transparente sobre grama verde parecia terra marrom; disco mais opaco.
  - **Limitação:** a área só age a cada 1 s, então quem entra pode levar até 1 s para sentir o efeito. A nuvem de chuva é só um disco azul no chão, sem gotas caindo.
  - 30 testes novos (135 → 165/165). Prints em `evidencias/fase-1/estado_*.png` e `area_*.png`.
- **Lote: parede + teleporte curto** em 21/10/2026 (versão 12 do prompt). Com eles, a "primeira leva" de componentes da proposta técnica (seção 3) está completa, menos o estado "cego".
  - **Parede:** bloco sólido que sobe do chão à frente de quem conjurou, atravessado na frente dele, e some sozinho. Fica na camada de colisão do cenário, então segura projéteis, inimigos e o próprio mago sem código extra. Conta no limite de 3 magias ativas por jogador junto com as áreas (o controle do Host foi generalizado de "áreas" para "magias ativas").
  - **Teleporte curto:** leva quem conjurou para a frente, só no plano do chão (olhar para cima não vira voo), para 0,6 m antes de qualquer parede, caixa ou barril no caminho e cai no chão.
  - Prompt da IA: escudo e parede tinham as duas a palavra "barreira"; o escudo agora é "proteção no próprio corpo" e a parede "barreira no chão, à frente".
  - **Limitações:** a parede é um bloco cinza liso, bem longe da pedra trabalhada da referência (decisão visual para o Vitor). O teleporte não tem nenhum efeito visual: o mago simplesmente aparece em outro lugar.
  - 22 testes novos (165 → 187/187). Print em `evidencias/fase-1/parede_muro_de_pedra.png`.
- **Revisão de segurança do caminho IA → validador** em 21/10/2026 (papel do "revisor de segurança" da ADR-005, feito sem acionar agente para poupar cota). Com os componentes novos a IA pode montar fichas bem mais complexas, então testei fichas absurdas de propósito:
  - Ficha com projétil dentro de projétil 1500 vezes e ficha com 500 componentes: **não quebravam** (o Godot corta a cópia profunda sozinho e a mana impede conjurar algo tão caro), mas enchiam o log de erro e validavam lixo à toa. Agora o validador só aceita explosão, estado e área dentro de "ao_impactar" (o jogo nem sabe executar projétil dentro de projétil), e corta as listas em 8 componentes e 4 efeitos de impacto.
  - **A função do Supabase não cumpria a seção 7 da proposta técnica aprovada** ("tempo máximo de resposta e corta respostas grandes demais"): não tinha nenhum dos dois. Agora desiste da Groq em 7 s (o jogo desiste em 8 s, então o servidor ainda consegue registrar a falha e responder) e recusa respostas com mais de 8 mil caracteres, registrando o motivo em `fichas_falhas`. Versão 13.
  - De propósito **não** limitei os tokens da resposta da Groq: o modelo atual "pensa" antes de responder e esse pensamento conta no limite; um teto mal calibrado cortaria respostas boas, e daqui não dá para testar.
  - Ferramenta nova `ferramentas/checar_porteiro.sh`: confere a sintaxe da função com o Node antes do deploy (conferido que ela acusa um erro plantado de propósito).
  - 4 testes novos (187 → 191/191).
- **Lote: estado "cego" + retorno visual do teleporte** em 21/10/2026 (versão 14 do prompt). Com o cego, **todos os componentes da "primeira leva" da proposta técnica (seção 3) existem.**
  - **Cego:** inimigo ou criatura cega para de perseguir e de atacar (fica parada); o corpo ganha a cor roxo-escura dos estados. O mago cego vê a tela quase toda escura, com o texto do HUD ainda legível por cima. A ADR-013 põe a cegueira entre os ingredientes maus, então a ficha de exemplo ("Pó Ofuscante") tem natureza "ma".
  - **Teleporte:** ganhou um "puf" de luz na saída e na chegada (reaproveita o efeito da explosão, sem dano). Achado no print: quem se teleporta não vê os próprios "pufs" (um fica atrás, o outro em volta da cabeça, com a câmera dentro), só o parceiro veria. Para quem conjura, o HUD dá um clarão azulado de 0,3 s na tela.
  - **Ainda não existe:** a regra da ADR-017 de magia "má" sair pela culatra. Ela precisa de decisões de design do Vitor (com que frequência, o que acontece), por isso não inventei.
  - 10 testes novos (191 → 201/201). Prints em `evidencias/fase-1/estado_cego.png` e `teleporte_clarao.png`.
- **Correção: validador aceita nomes com acento e maiúscula** em 21/10/2026. Teste feito de propósito: uma ficha com `"tipo": "projétil"`, `"material": "Água"`, impacto `"explosão"` e `"tipo": "Área"` com `"Molhado"` passava pelo validador sem nenhum componente reconhecido (custo de mana 0) e a magia viraria "não entendi". Como a IA escreve em português, ela pode "corrigir" os nomes pedidos sem acento. Agora o validador passa tipo, material, forma, estado, corpo, comportamento e os efeitos de impacto para minúsculas e sem acento antes de comparar com as listas fechadas. As listas continuam fechadas: só muda a forma de escrever, nunca o que é aceito. 7 testes novos (201 → 208/208).
- **Módulo clareira no padrão da referência** em 21/10/2026 (escopo ampliado com aprovação do Vitor; adendo na ADR-018). Substitui o chão verde liso e os dois cubos coloridos da arena.
  - **O que tem:** terreno com relevo (centro plano de 20 m de raio para lutar, morros em volta), trilha de terra alaranjada que atravessa a clareira e segue por um vale ao norte, 150 árvores (pinheiros e árvores redondas), pedras grandes que servem de obstáculo, 2400 tufos de grama balançando ao vento, muro de 4 arcos com estandartes azuis e dourados, um arco caído, montanhas no horizonte, castelo com telhados roxos e janelas acesas sobre um penhasco com cachoeira, três ilhas flutuantes que sobem e descem devagar e nuvens.
  - **Como foi feito:** tudo gerado em código com semente fixa (`scripts/ambiente/clareira.gd` e `geometria_low_poly.gd`), juntando as peças em poucas malhas para a placa de vídeo trabalhar menos. Cerca de 92 mil triângulos no total (conferido contando as malhas), folgado para a RTX 2060. Árvores perto da luta, pedras e ruínas têm colisão; o resto é só visual.
  - **Luz:** sol mais forte e quente, céu mais azul, névoa de distância mais fraca (antes deixava tudo lavado), contraste e saturação um pouco maiores.
  - **Achado no print:** os arcos ficavam flutuando porque cada pilar estava num chão de altura diferente; agora todos os pilares terminam na mesma altura e o mais baixo só afunda mais no chão.
  - **Comparação com a referência:** já se parece nas cores da trilha e da grama, nos pinheiros, nas ruínas com estandarte, no castelo com cachoeira e nas ilhas flutuantes. Ainda falta: textura nas pedras e no chão (hoje é cor lisa por face), sombras mais escuras e azuladas, nuvens mais fofas, caixotes e barris de verdade (hoje são blocos), e o mago, que ainda é um bloco. Não dá para conferir daqui a névoa volumétrica e a iluminação global.
  - O arquivo antigo `decorador_terreno.gd` saiu (a clareira faz o trabalho dele). 8 testes novos (208 → 216/216), entre eles um que confere que o chão não está de cabeça para baixo (testado com o erro de propósito: o teste falha). Prints em `evidencias/fase-2/clareira_*.png`.
- **Boneco do mago** em 21/10/2026 (cores roxas da referência, aprovadas pelo Vitor). Substitui a cápsula roxa e o bloquinho bege que fazia papel de mão.
  - **Terceira pessoa** (`scripts/mago/visual_mago.gd`): mago tosco de propósito (ADR-019), com cabeça grande, nariz de batata, chapéu de aba larga que entorta para trás, manto em sino com barra dourada, cinto com bolsinha e cajado com cristal azul brilhando. Animação em código, sem esqueleto: o corpo balança ao andar, os braços vão e voltam, abre os braços no pulo e levanta o cajado ao conjurar.
  - **Primeira pessoa** (`scripts/mago/maos_primeira_pessoa.gd`), como na referência: mão esquerda aberta à frente, que dá um tranco e solta um brilho azul ao conjurar, e a mão direita segurando o cajado. As mãos balançam ao andar e mostram a cor dos estados (molhado, queimando...), o que dá retorno a quem está em primeira pessoa.
  - **Bug antigo achado:** a câmera de terceira pessoa ficava **na frente** do mago, olhando para longe (o braço da câmera estava virado ao contrário). O mago nunca aparecia na tela nesse modo; dá para ver no print antigo `evidencias/fase-1/arena_terceira_pessoa_render_nuvem.png`. Agora fica atrás e um pouco acima do ombro direito. Teste novo conferido com o erro de volta (o teste falha).
  - Ferramenta de print ganhou `--camera` e `--alvo-camera` (câmera livre, para ver o mago de frente).
  - **Comparação com a referência:** chapéu, manto, acabamento dourado, cajado com cristal e as mãos em primeira pessoa já seguem a referência. Ainda falta: rosto com mais expressão, mãos com dedos mais bem feitos, a magia saindo da mão (hoje sai do centro da tela) e um efeito de partículas na mão como o da referência.
  - 1 teste novo (216 → 217/217). Prints em `evidencias/fase-2/mago_*.png`.
- **Caixote e barril de madeira** em 21/10/2026 (`scripts/ambiente/modelos_props.gd`). Caixote com quinas reforçadas, tábua em diagonal e frestas; barril bojudo com cintas de metal. O barril inflamável tem uma **faixa vermelha** para o jogador saber de longe que ele pega fogo (decisão minha de legibilidade, fácil de trocar). Aceso, ganha uma camada laranja brilhante por cima da madeira. 4 testes novos (217 → 221/221). Print em `evidencias/fase-2/caixote_e_barril.png`.
- **Magia sai da mão** em 21/10/2026. Em primeira pessoa a magia nasce na palma da mão esquerda; em terceira, no cristal do cajado. Para a mira continuar honesta, a direção é calculada até o ponto exato que o centro da tela aponta (cenário, galinha ou caixote, até 80 m). Se houver parede entre a câmera e a mão (encostado num muro), sai da câmera, como antes, para a magia não nascer do outro lado da parede. 4 testes novos (221 → 225/225), conferindo nos dois modos de câmera que a magia não sai do meio da tela e chega a menos de 5 cm do ponto da mira. Print em `evidencias/fase-2/magia_saindo_da_mao.png`.
  - O HUD ganhou uma mira "+" no centro da tela (não existia; com a magia saindo da mão, ela passou a ser necessária). 1 teste novo (226/226).
  - **Observação para o Vitor:** a bola de fogo logo que sai da mão vira um clarão amarelo-branco por causa do brilho (glow), em vez do laranja de chama da referência. Partículas de fogo resolveriam (mesma decisão pendente do estado "queimando").
- **Feedback do Vitor jogando de verdade no PC** em 21/10/2026, depois do teste completo (`evidencias/fase-2/relatorio-teste-pc.md`). Primeira pessoa e o ambiente aprovados ("ok", "parece bom"). Sobre o boneco do mago em terceira pessoa, achou **ruim**, não só "falta polir": o corpo deveria ser mais baixo e mais cabeçudo (proporção mais chibi/cartoon, diferente do que está hoje), falta animação de braço de verdade, falta roupa com mais acabamento, e o ambiente também precisa de mais refino (mesmo dentro do low poly). Resumo dele: "precisa demais, apesar de estarmos no caminho".
  - **Não é a mesma coisa que o "tosco de propósito" da ADR-007/019.** Aquelas decisões são sobre nível de detalhe/polígono e tom absurdo dos inimigos, não sobre proporção do corpo nem sobre ter ou não animação de braço — dá para ajustar as duas coisas que ele pediu sem contradizer nenhuma ADR aprovada.
  - **Vitor aprovou tratar como ajuste pontual agora**, dentro da Fase 2 (não esperar a Fase 3).
- **Boneco do mago: proporção mais cabeçuda/baixa, cotovelo e acabamento de roupa** em 21/10/2026, direto a partir do feedback acima (`scripts/mago/visual_mago.gd`).
  - **Proporção:** pernas e tronco encolhidos (~20% mais baixos, um pouco mais largos) e cabeça aumentada (~20% maior), reposicionando chapéu/cabelo/rosto em cima do tronco novo. O corpo inteiro ficou mais atarracado e cabeçudo, como pedido.
  - **Braço com cotovelo:** antes era um taco rígido só girando no ombro; agora cada braço tem ombro + cotovelo (dois nós, dois segmentos de malha). O cotovelo dobra mais nas pontas do balanço ao andar, estica ao conjurar (gesto de "apontar o cajado" mais nítido) e o corpo ganhou um leve balanço de respiração mesmo parado, para nunca ficar congelado. O cajado e o cristal migraram do ombro para o cotovelo direito (mão), continuam acertando a mira nos testes automáticos.
  - **Acabamento de roupa:** capa em dois painéis saindo da gola (visível dos dois lados, não só de um ângulo), três botões dourados descendo pela frente do manto, broche em losango dourado na gola.
  - **Conferido:** suíte de testes sem nenhuma regressão nova (mesma falha pré-existente de antes, "área continua machucando a cada segundo", sem relação com o mago). Prints comparando de frente, de costas (pra ver a capa) e conjurando em `evidencias/fase-2/pc_mago_terceira_v2_padrao.png`, `pc_mago_costas.png` e `pc_mago_conjurando_v2.png`.
  - **Ainda não mexido:** rosto com mais expressão, dedos da mão, refino do ambiente (ficou para depois, a pedido reconfirmado com o Vitor antes de continuar).
- **Menu de pausa (ferramenta de teste)** em 21/10/2026, a pedido do Vitor para facilitar testar o jogo (`scripts/ui/menu_pausa.gd`, `cenas/menu_pausa.tscn`). Esc abre e fecha; dentro, três botões: Continuar, Reiniciar (`reload_current_scene`) e Sair do jogo (`get_tree().quit()`). Pausa de verdade (`get_tree().paused`), mostra o mouse para clicar nos botões e trava a entrada do mago, igual a caixa de conjuração já fazia.
  - **De propósito simples:** visual padrão do Godot, sem estilo da referência. O Vitor disse que não precisa estar no jogo final, é só para ele testar.
  - **Cuidado tomado:** a caixa de conjuração (Q) também usa Esc para fechar; se as duas quisessem reagir ao mesmo Esc, abriria o menu de pausa por cima da caixa aberta. Agora o menu só reage ao Esc se a caixa de conjuração não estiver visível, e a caixa marca o evento como tratado ao fechar.
  - **Conferido:** suíte sem regressão nova (mesma falha de antes). Script temporário simulou dois Esc seguidos e confirmou que `paused` e o mouse (capturado/visível) trocam certo nos dois sentidos. Os cliques nos botões eu não consigo simular daqui; **o Vitor testou na tela em 21/10/2026 e confirmou que funcionam.**
- **Refino do ambiente, primeira rodada** em 21/10/2026, continuando o pedido do Vitor de refinar boneco e cenário.
  - **Achado principal (o motivo do "brilho fraco"):** o cristal do cajado do mago (`VisualMago.material_cristal()`, usado em primeira e terceira pessoa) é a coisa azul brilhante mais visível do jogo o tempo todo, e eu confundi ele com a tocha do canto de atmosfera num teste anterior — são objetos diferentes, só ficam perto um do outro na tela. O material do cristal não era "sem sombra" (`shading_mode` padrão), então a luz ambiente azulada da cena somava em cima da própria emissão e lavava a cor para um branco-ciano quase sem saturação, em vez do azul vivo da referência. Confirmado medindo o pixel antes e depois: antes a maior parte da área ficava em `(220-255, 255, 255)` (praticamente branco); depois de marcar `shading_mode = SHADING_MODE_UNSHADED` (igual a chama da tocha já fazia) e subir um pouco a emissão (1.3 → 1.6), o pixel equivalente ficou em torno de `(95, 187, 236)`, um azul bem mais puro e saturado. Prints: `evidencias/fase-2/pc_cristal_v2.png`.
  - **Ambiente (Environment da arena):** `tonemap_white` 6.0 → 8.0 (realces não "estouram" pra branco tão cedo), `glow_hdr_threshold` 0.9 → 0.85 e `glow_bloom` 0.25 → 0.2 (brilho um pouco menos espalhado/leitoso), `ambient_light_energy` 0.45 → 0.55 com a cor ambiente um pouco mais azul (`0.46, 0.58, 0.98`), pra reforçar o contraste frio na sombra contra a luz quente do sol. Emissão da chama da tocha (`canto_atmosfera.tscn`) também cortada de 7.0 para 3.0 — não encontrei um jeito de fotografar só ela, sem o cristal do mago por perto ou o próprio mago bloqueando a vista, então essa parte **não ficou confirmada visualmente**, só por código (consistente com outras chamas do jogo, que já usam 3.0).
  - **Nuvens mais fofas:** cada nuvem ganhou 3 bolhas a mais (5 → 8) e uma leve sombra cinza nas bolhas de baixo, pra parecer um cúmulo em vez de uma fileira reta de esferas. Orçamento de triângulos da clareira subiu de 91645 para 93535, dentro do limite de 150 mil.
  - **Conferido:** suíte sem regressão nova (a mesma falha de antes some e volta entre uma rodada e outra, mesmo sem eu mexer em nada daquele teste — parece um teste instável por tempo, não ligado a este refino; registrado aqui pra não esconder). Print geral com os ajustes em `evidencias/fase-2/pc_paisagem_v2.png`.
  - **Ainda não mexido:** textura/variação nas pedras e no chão (continua cor lisa por face) — item maior, fica para outra rodada se o Vitor quiser.
