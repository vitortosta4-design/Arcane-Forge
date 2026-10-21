# Registro de decisões (ADR)

Cada decisão tem: problema, alternativas, escolha, motivo, consequências e se é fácil de mudar.
Status possíveis: **Aprovada**, **Proposta** (aguardando o Vitor), **Adiada**.

Última atualização: 20/10/2026

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
**Status:** Aprovada (20/10/2026)

- **Problema:** transformar texto livre em magia, com custo zero ou baixo.
- **Alternativas:** modelo local no PC (fraco demais no hardware atual), API paga, API com plano gratuito.
- **Escolha:** um "tradutor" independente do jogo. O jogo envia a frase e recebe uma ficha estruturada. O provedor inicial será um plano gratuito (Groq ou Gemini Flash), escolhido na Fase 4 por qualidade e velocidade medidas.
- **Motivo:** custo zero na fase de aprendizado, e o provedor pode ser trocado sem mexer no jogo.
- **Consequências:**
  - Planos gratuitos podem usar os dados enviados para treino e podem proibir uso comercial. Se o projeto virar produto, migrar para plano pago, dentro do teto de R$ 50/mês.
  - Haverá um modo offline com magias pré-definidas, para testes sem gastar cota.
- **Fácil de mudar?** Sim.

## ADR-003 · Proteção da chave da IA: Supabase Edge Function
**Status:** Aprovada (20/10/2026)

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
**Status:** Aprovada (20/10/2026)

- Toda magia custa mana.
- Magias duram poucos segundos.
- Enquanto a magia está sendo interpretada, o mago pode andar, mas não correr nem se defender.
- Mana só é descontada se a magia for conjurada com sucesso.

## ADR-010 · Teclas de chat e de magia
**Status:** Aprovada (20/10/2026)

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
**Status:** Aprovada (20/10/2026)

- No combate: a magia sai direto, com uma legenda curta do que foi entendido.
- No grimório: prévia antes de salvar, com possibilidade de ajustar.

## ADR-013 · Progressão por "ingredientes de imaginação"
**Status:** Aprovada (20/10/2026)

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
**Status:** Aprovada (20/10/2026)

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

## ADR-019 · Inimigos absurdos
**Status:** Aprovada (20/10/2026)

- Inimigos no mesmo tom das magias: absurdos e engraçados (ex.: galinha zumbi, cogumelo com raiva, armário possuído).

## ADR-020 · Grimório pessoal com empréstimo
**Status:** Aprovada (20/10/2026)

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
**Status:** Aprovada (20/10/2026)

- Quando a interpretação falhar ou sair muito diferente do pedido, o jogo envia ao Supabase apenas a frase, a ficha gerada e a versão do sistema. Sem nome, sem identificador pessoal.
- Uso: melhorar o interpretador.
- Retenção: 90 dias.

## ADR-023 · Voz na nuvem, só enquanto a tecla é segurada
**Status:** Aprovada (20/10/2026)

- Transcrição via Groq (Whisper). Áudio enviado apenas enquanto V está pressionada.
- Latência estimada de 1,5 a 3 segundos entre soltar a tecla e a magia sair, a ser medida na Fase 6.

## ADR-024 · Magias privadas entre os dois jogadores
**Status:** Aprovada (20/10/2026)

- Sem galeria pública por enquanto (exigiria moderação). Ideia guardada para o futuro.

## ADR-025 · Atmosfera bonita com shaders baratos
**Status:** Aprovada (20/10/2026)

- **Objetivo:** atmosfera bonita como na referência `docs/referencias/arte-conceito-01.png`, vinda de luz e cor, não de polígonos.
- **Usar:** shader toon (luz em degraus de cor), luz de contorno, névoa colorida por distância e altura, céu pintado, vegetação balançando por shader de vértice, água estilizada, brilho (glow) nas magias.
- **Não usar no hardware mínimo:** névoa volumétrica, iluminação global em tempo real, muitas luzes com sombra simultâneas.
- **Menu de qualidade (Baixo e Alto):** o Alto liga enfeites extras (partículas, sombras, vegetação) para PCs fortes. Nenhum ajuste de qualidade pode mudar o combate (colisões, visibilidade de inimigos, áreas de efeito).
- **Fácil de mudar?** Sim, é camada visual.

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

## Status da descoberta
Encerrada em 20/10/2026. `docs/proposta-tecnica.md` aprovada em 20/10/2026.

## Status das fases (atualizado em 21/10/2026)
- **Fase 1 (esqueleto jogável):** praticamente concluída. Todos os critérios de aceitação verificáveis por teste e código (seção 9 da proposta técnica) estão com o `[x]`. Restam dois critérios que só o Vitor pode confirmar: o canto de atmosfera lembrar a referência visual, e jogar 10 minutos para dizer se o combate "dá gosto". A Fase 1 só pode ser marcada como encerrada depois dessa confirmação.
- **Fase 2 (magia por texto com IA real):** já ligada de verdade. `mago.gd` chama `Porteiro.interpretar()` (Supabase + Groq) e cai para o `Interpretador` local se a IA estiver fora do ar. README.md e CLAUDE.md foram corrigidos nesta data porque ainda diziam "Fase atual: Fase 1".
- **Suíte de testes automáticos:** confirmada rodando de verdade em 21/10/2026, numa sessão na nuvem sem GPU (Godot 4.7.2 headless instalado só para isso). 43/43 testes passando. Dois avisos inofensivos do motor em modo headless (vazamento de 2 objetos e 1 recurso ao sair; erro de material nulo do renderizador fictício) não afetam o jogo jogável — são ruído de rodar sem tela, registrados aqui para não esconder nada.

## Requisito mínimo de hardware (referência)
O PC do Vitor é o piso: Pentium G5400 (2 núcleos), GTX 1050 com 2 GB de VRAM, 16 GB de RAM.
Se rodar bem nele, roda na maioria dos PCs.

## Notas de implementação da Fase 2

- **Projeto Supabase criado** em 20/10/2026 (ADR-003): nome `arcane-forge`, região São Paulo (`sa-east-1`), plano grátis. Para abrir vaga (o plano grátis só permite 2 projetos ativos), o projeto pessoal `ana-e-eu` do Vitor foi pausado, a pedido dele; pode ser reativado quando ele quiser.
- **Provedor de IA provisório da Fase 2: Groq.** A ADR-002 deixa a escolha final para a Fase 4 (medindo qualidade e velocidade), mas a Fase 2 precisa de algum provedor para testar o caminho completo. Groq foi escolhido como provisório porque: (1) tem plano grátis generoso, (2) é muito rápido, o que importa para a magia não demorar para sair, (3) a ADR-023 já previa usar o Whisper da Groq na Fase 6 (voz), então é uma conta só para gerenciar. Essa escolha pode mudar na Fase 4 sem problema.
