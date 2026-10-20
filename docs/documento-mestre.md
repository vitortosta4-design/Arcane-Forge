# PROJETO ARCANE FORGE
## Documento mestre de visão, planejamento e desenvolvimento de um jogo cooperativo de magia generativa

### 1. Sua missão

Você será o diretor técnico, arquiteto de software e coordenador de uma equipe de desenvolvimento de jogos assistida por inteligência artificial.

Sua missão é planejar e desenvolver um jogo 3D de fantasia, com combate em tempo real e modo cooperativo online para dois jogadores contra inimigos controlados pela inteligência artificial (PvE).

O diferencial central do projeto será um sistema de magia generativa: os jogadores poderão descrever livremente suas ideias em linguagem natural, por texto ou voz, e o jogo deverá interpretar essas descrições e transformá-las em habilidades funcionais no mundo virtual.

O projeto será desenvolvido com minha participação nas decisões importantes. Sou iniciante em desenvolvimento de jogos, programação, arquitetura de software, game design, segurança, infraestrutura online e produção de jogos. Portanto, explique os conceitos técnicos em linguagem simples, apresente alternativas fundamentadas e recomende caminhos viáveis.

Quero utilizar o Claude Code, Skills, subagentes e automações para reduzir o trabalho manual, os prompts repetitivos e as revisões necessárias. O objetivo é criar um jogo funcional, organizado, expansível e tecnicamente sustentável, evitando retrabalho e decisões inadequadas tomadas no início.

Não comece a programar imediatamente. Primeiro, conduza uma descoberta estruturada do projeto, investigue as tecnologias disponíveis, esclareça as decisões importantes e prepare um plano aprovado para a implementação.

### 2. Visão do jogo

O jogo será uma experiência de fantasia em que a imaginação do jogador funciona como linguagem para criar magia.

O jogador poderá conjurar coisas como:

- Um pombo de pedra que persegue inimigos e lança ovos explosivos.
- Uma lança de relâmpago que atravessa vários adversários e retorna à mão.
- Um mini buraco negro que atrai inimigos, projéteis e objetos próximos.
- Um dragão de água que voa pelo cenário, morde os adversários e se desfaz em uma onda.
- Uma parede de espelhos que copia projéteis e os devolve aos atacantes.
- Uma mão gigante de areia que agarra um inimigo e o arremessa contra outros.
- Uma nuvem de abelhas luminosas que persegue os inimigos e libera uma explosão de luz.
- Um escudo formado por pequenas tartarugas de metal que orbitam o jogador e bloqueiam ataques.
- Uma espada de vento que corta os inimigos e cria um tornado depois do impacto.
- Uma bolha de gravidade invertida que faz os inimigos flutuarem em direção ao teto.

Esses exemplos são apenas demonstrações do potencial criativo. O jogo não deve exigir que o usuário escolha um feitiço de uma lista fechada nem que conheça palavras técnicas como projétil, invocação ou dano em área.

A IA deverá inferir a intenção, identificar os comportamentos necessários e transformar a descrição em uma habilidade executável.

O objetivo é oferecer grande liberdade criativa sem depender da geração perfeita de modelos 3D ou de código novo a cada conjuração. A solução deverá combinar inteligência artificial, componentes reutilizáveis, geração procedural, regras de física, animações e sistemas de combate.

A referência de experiência é o combate mágico expressivo de Mage Arena, mas o projeto deve possuir identidade, implementação e sistemas próprios.

### 3. Princípios de trabalho

Siga estes princípios durante todo o projeto:

1. Investigue antes de decidir. Não presuma que a primeira solução imaginada seja a melhor.
2. Priorize um protótipo jogável antes de ampliar o conteúdo.
3. Prefira soluções simples e confiáveis quando produzirem o resultado desejado.
4. Não introduza tecnologias, agentes, dependências ou serviços sem necessidade demonstrável.
5. Não prometa funcionalidades que não tenham sido implementadas e verificadas.
6. Registre as decisões importantes para não rediscuti-las ou contradizê-las posteriormente.
7. Separe requisitos obrigatórios, preferências, hipóteses e funcionalidades futuras.
8. Informe riscos técnicos, financeiros, de segurança e de manutenção antes que se tornem problemas.
9. Não sacrifique a qualidade do multiplayer, a segurança ou a estabilidade para acelerar uma demonstração.
10. Explique os conceitos que eu preciso entender para tomar decisões, sem exigir que eu me torne programador.
11. Utilize agentes paralelos quando houver benefício real, mas mantenha uma arquitetura centralizada e consistente.
12. Se uma ideia for inviável ou desproporcionalmente cara, explique o motivo e apresente uma alternativa.

### 4. Fase inicial obrigatória: descoberta e entrevista

Nesta fase, não implemente o jogo, não instale dependências definitivamente e não assuma decisões técnicas irreversíveis.

Conduza uma entrevista estruturada comigo, dividida em blocos de cinco a oito perguntas relacionadas. Aguarde minhas respostas antes de avançar para o próximo bloco.

Não faça uma lista enorme de perguntas de uma só vez.

Priorize as decisões que afetam várias partes do projeto, como plataforma, experiência visual, orçamento, tecnologia de multiplayer e forma de utilização da IA.

Para cada decisão relevante:

- Explique por que ela importa.
- Apresente as alternativas realmente viáveis.
- Descreva vantagens, limitações, custos e riscos.
- Indique sua recomendação.
- Explique as consequências para o restante do projeto.
- Informe se a escolha pode ser alterada facilmente no futuro.
- Solicite minha aprovação quando a decisão tiver impacto significativo.

Não faça perguntas cuja resposta possa ser obtida por investigação técnica confiável. Quando a resposta depender de documentação, versões, licenças ou preços atuais, pesquise primeiro.

Se eu responder que não sei, proponha uma opção adequada para um desenvolvedor iniciante, com orçamento limitado e sem uma equipe profissional.

Investigue os seguintes grupos temáticos:

**A. Produto e experiência**

- Qual experiência deve ser priorizada: ação frenética, exploração, sobrevivência, progressão ou uma combinação?
- A câmera será em primeira ou terceira pessoa?
- O jogo terá sessões curtas, missões longas ou exploração contínua?
- Qual deve ser o equilíbrio entre humor, fantasia épica e seriedade?
- Qual nível de liberdade e complexidade será aceitável durante o combate?

**B. Plataforma e controles**

- O lançamento inicial será para Windows ou outras plataformas?
- O jogo utilizará teclado e mouse, controle ou ambos?
- O reconhecimento de voz será obrigatório, opcional ou uma alternativa ao texto?
- Qual nível de desempenho visual é esperado?
- Qual hardware mínimo deverá ser suportado?

**C. Escopo e produção**

- Qual é o orçamento inicial?
- Qual é o limite aceitável de gastos mensais?
- Aceito utilizar serviços pagos de inteligência artificial?
- Quanto do projeto deverá ser produzido com ferramentas gratuitas?
- Quais funcionalidades precisam existir na primeira versão?
- Qual nível de autonomia deve ser concedido ao Claude Code?

**D. Magia generativa**

- A magia será criada durante o combate ou também poderá ser preparada antes?
- Quanto tempo poderá transcorrer entre a descrição e a execução?
- Como lidar com descrições ambíguas, impossíveis ou excessivamente complexas?
- O jogador poderá controlar parâmetros, ou toda a configuração será inferida automaticamente?
- Como será apresentada uma aproximação quando a ideia não puder ser reproduzida literalmente?
- Quais limites de custo, quantidade de criaturas e duração serão aceitáveis?
- Como equilibrar criatividade, desempenho e justiça entre os jogadores?

**E. Multiplayer e infraestrutura**

- A sessão será hospedada por um jogador ou por um servidor dedicado?
- Como os jogadores entrarão na mesma partida e convidarão amigos?
- Será necessário manter progresso persistente?
- O jogo deverá permitir reconexão após uma queda de conexão?
- Qual será o limite de entidades e efeitos simultâneos?
- Como impedir que um cliente altere danos, recursos ou resultados da partida?

**F. Arte e apresentação**

- O estilo será realista, estilizado, cartunesco ou uma mistura?
- Os modelos serão adquiridos, produzidos manualmente ou combinados proceduralmente?
- Qual será o padrão visual mínimo para criaturas inventadas?
- Como garantir que efeitos visuais não prejudiquem a leitura do combate?
- Quais recursos poderão ser produzidos por IA e quais exigirão ferramentas tradicionais?

**G. Segurança e dados**

- Quais dados dos jogadores precisam ser armazenados?
- As descrições e magias criadas serão privadas ou compartilháveis?
- Como proteger credenciais, serviços externos e dados de sessão?
- Quais limites impedirão abusos, gastos inesperados e sobrecarga do sistema?
- Quais dados deverão ser removidos e por quanto tempo poderão ser mantidos?

**H. Ferramentas e equipe de agentes**

- Qual ambiente de desenvolvimento está disponível?
- Qual sistema operacional e hardware serão utilizados?
- Quais versões do Claude Code e quais ferramentas já estão disponíveis?
- Quais Skills e subagentes podem ser reaproveitados?
- Quais tarefas podem ser automatizadas com segurança?
- Quais decisões precisam permanecer sob minha aprovação?

Acrescente outras perguntas se identificar riscos importantes. Não transforme a entrevista em um formulário rígido: adapte as perguntas às respostas anteriores.

### 5. Equipe de desenvolvimento assistida por IA

Antes de criar novos agentes, examine os recursos existentes no ambiente do Claude Code, incluindo Skills, subagentes, comandos, hooks e ferramentas de automação.

Pesquise documentação oficial atualizada para confirmar os recursos suportados pela versão utilizada. Não presuma que uma funcionalidade existe apenas porque foi mencionada em um exemplo encontrado na internet.

Avalie, entre outras possibilidades:

- [Documentação do Claude Code](https://code.claude.com/docs/en/overview)
- [Skills do Claude Code](https://code.claude.com/docs/en/skills)
- [Subagentes do Claude Code](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
- [Awesome GameDev Agent Skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)

Os repositórios comunitários são referências para investigação, não dependências obrigatórias. Verifique licença, compatibilidade, manutenção, qualidade e segurança antes de instalar ou incorporar seus conteúdos.

Se houver agentes adequados, reutilize-os. Se não houver, proponha uma equipe personalizada com responsabilidades claras.

A estrutura desejada é:

**Diretor técnico e arquiteto**

Mantém a visão global, define interfaces entre módulos, coordena as tarefas, registra decisões e resolve conflitos técnicos.

**Game designer**

Define mecânicas, combate, progressão, dificuldade, objetivos, recompensas e experiência do jogador.

**Engenheiro de gameplay**

Implementa movimentação, câmera, combate, física, colisões, interações e integração com a engine.

**Especialista em IA generativa**

Desenvolve a interpretação das descrições, o modelo de dados das magias, a composição de habilidades e a integração com modelos de linguagem.

**Especialista em multiplayer e backend**

Implementa sessões, comunicação entre clientes, autoridade do servidor, persistência e recuperação de falhas.

**Especialista em segurança**

Analisa ameaças, permissões, validação de entradas, proteção de APIs, abuso de recursos e exposição de dados.

**Artista técnico**

Define materiais, modelos modulares, animações, partículas, iluminação e geração procedural.

**Especialista em interface e acessibilidade**

Cuida da experiência de conjuração, da interface, dos controles, das opções de acessibilidade e da clareza visual.

**Engenheiro de qualidade**

Cria testes automatizados, reproduz erros, verifica integrações, avalia desempenho e confirma os critérios de aceitação.

**Responsável pela produção**

Organiza etapas, dependências, riscos, prioridades e estimativas.

Não é obrigatório criar um agente independente para cada função. Combine responsabilidades quando isso reduzir a complexidade. Mantenha separados os papéis que exigirem especialização ou revisão independente.

O agente principal deve coordenar os especialistas, delegar tarefas bem definidas e integrar seus resultados. Evite que múltiplos agentes modifiquem simultaneamente os mesmos arquivos sem isolamento e revisão.

Sempre que possível, execute em paralelo investigações e tarefas independentes. Centralize mudanças de arquitetura e integrações críticas.

### 6. Arquitetura do jogo e escolha da tecnologia

Após a entrevista, investigue as tecnologias candidatas antes de definir a stack.

Compare Unreal Engine 5 e Unity, ou outras alternativas que se mostrem tecnicamente relevantes.

Considere:

- Curva de aprendizado.
- Facilidade de desenvolvimento assistido por IA.
- Qualidade da renderização 3D.
- Física, animações e ferramentas de criação.
- Recursos nativos de multiplayer.
- Possibilidade de utilizar servidor autoritativo.
- Integração com APIs de IA e reconhecimento de voz.
- Ferramentas de testes e depuração.
- Custos, licenças e dependências.
- Requisitos de hardware.
- Distribuição, atualizações e manutenção.
- Disponibilidade de documentação e exemplos confiáveis.

Pesquise documentação oficial atualizada e apresente uma recomendação fundamentada. Não escolha apenas pela popularidade ou pela qualidade visual.

A arquitetura deverá separar, conforme as necessidades identificadas:

1. Cliente e motor do jogo.
2. Controle de movimentação e câmera.
3. Combate e física.
4. Sistema de reconhecimento de voz.
5. Interpretador de linguagem natural.
6. Gerador de habilidades estruturadas.
7. Validador de habilidades e balanceador.
8. Executor de magias.
9. Renderização procedural.
10. IA dos NPCs.
11. Gerenciador de sessões multiplayer.
12. Servidor autoritativo.
13. Backend e persistência.
14. Interface e configurações.
15. Monitoramento, testes e tratamento de falhas.

A integração com IA deve utilizar uma camada independente do motor de jogo sempre que isso trouxer benefícios reais. Isso permitirá substituir o provedor de IA sem reconstruir toda a mecânica.

Não exponha chaves de API no executável, nos arquivos públicos ou no repositório. Utilize um backend seguro quando necessário.

Crie um modo de desenvolvimento que permita testar os sistemas sem depender continuamente de serviços externos.

### 7. O sistema central de magia generativa

A liberdade de criação será o principal diferencial do jogo. Toda a arquitetura deverá ser planejada para sustentar esse objetivo.

O sistema deverá transformar uma descrição livre em uma habilidade que o motor de jogo consiga executar.

O processo será dividido em etapas.

**7.1. Entrada**

O jogador descreve uma magia por texto ou voz, sem precisar conhecer comandos especiais.

**7.2. Interpretação**

A IA identifica a entidade, a aparência, os elementos, o comportamento, o alvo, o movimento, o alcance, a duração, o dano, as interações e as condições de ativação.

**7.3. Estruturação**

A interpretação é transformada em dados estruturados, com tipos, parâmetros e componentes permitidos pelo jogo.

**7.4. Validação**

Um sistema determinístico verifica se a habilidade pode ser executada, se os parâmetros são válidos e se os limites de custo, processamento, duração e poder foram respeitados.

**7.5. Composição visual**

O sistema seleciona e combina modelos, materiais, partículas, animações e efeitos sonoros para aproximar a aparência descrita.

**7.6. Execução**

O motor instancia a habilidade e controla movimento, colisões, interações, danos, duração e encerramento.

**7.7. Sincronização**

Os resultados relevantes são sincronizados com o parceiro e com o servidor da partida.

**7.8. Persistência**

A habilidade pode ser salva no grimório e reutilizada sem precisar de uma nova interpretação completa.

A IA não deve ser responsável por executar cada movimento ou decidir cada colisão em tempo real. Ela interpreta a intenção; o motor do jogo executa os comportamentos.

### 8. Componentes de execução

Crie uma infraestrutura modular que permita combinar diferentes comportamentos sem exigir programação exclusiva para cada descrição.

Investigue a necessidade dos seguintes componentes:

- Projéteis.
- Raios contínuos.
- Explosões.
- Áreas persistentes.
- Criaturas invocadas.
- Armadilhas.
- Escudos.
- Cura.
- Transformações.
- Teleporte.
- Criação de objetos.
- Manipulação de gravidade.
- Controle de movimento.
- Correntes e vínculos.
- Efeitos elementais.
- Atração e repulsão.
- Levitação.
- Gatilhos condicionais.
- Combinações de múltiplos efeitos.

O jogador não precisa selecionar esses componentes manualmente. A IA deverá inferir a combinação adequada a partir da descrição.

Por exemplo, "um pombo de pedra que voa até o inimigo e solta ovos explosivos" deverá resultar em uma criatura voadora, com comportamento de perseguição, capacidade de lançar projéteis e efeitos de explosão.

O sistema deverá conseguir variar aparência, comportamento e parâmetros sem criar uma implementação exclusiva para cada criatura.

Se a descrição exigir algo que o jogo ainda não suporta, informe a limitação e proponha uma aproximação funcional. Registre quais novos componentes seriam necessários para suportar aquela classe de habilidade no futuro.

### 9. Aparência visual procedural

A aparência deve ser personalizada conforme a descrição, utilizando principalmente recursos já disponíveis e composição procedural.

O sistema poderá combinar:

- Modelos 3D existentes.
- Peças modulares.
- Materiais e texturas.
- Malhas procedurais.
- Sistemas de partículas.
- Animações reutilizáveis.
- Deformações controladas.
- Iluminação.
- Efeitos de pós-processamento.
- Bibliotecas de sons.
- Variações de escala, cor, forma e movimento.

Uma criatura de pedra, por exemplo, poderá combinar um modelo corporal, asas, olhos luminosos, materiais rochosos e animação de voo.

Um buraco negro poderá ser composto por um núcleo visual, distorção, partículas atraídas, iluminação e regras de gravidade simulada.

A aparência não precisa reproduzir perfeitamente toda a imaginação do jogador. Deve ser coerente, reconhecível e suficientemente personalizada.

Não dependa da geração de um modelo 3D completo por IA em tempo real como requisito inicial. Isso pode acrescentar latência, custos, problemas de animação, colisão e inconsistência.

Pesquise soluções para geração procedural e composição de ativos adequadas à engine escolhida.

### 10. Física e interações emergentes

As magias devem interagir com inimigos, objetos e cenário segundo regras consistentes.

Exemplos:

- Explosões empurram inimigos e destroem objetos frágeis.
- Água pode conduzir eletricidade conforme as regras definidas.
- Gelo pode tornar superfícies escorregadias.
- Correntes podem prender inimigos a objetos.
- Vento pode desviar projéteis.
- Paredes podem bloquear ataques.
- Criaturas invocadas podem receber dano e ser eliminadas.
- Gravidade pode atrair objetos e inimigos.
- Fogo pode afetar materiais inflamáveis.

Implemente propriedades e tags nos objetos, permitindo que os efeitos consultem características como inflamável, condutor, congelável, metálico, líquido, vivo, explosivo, invocado e gravitacional.

Não tente simular perfeitamente todos os fenômenos físicos do mundo real. Priorize regras compreensíveis, consistentes, visualmente convincentes e eficientes.

### 11. Balanceamento e economia de recursos

A liberdade criativa precisa coexistir com limites de poder e desempenho.

O sistema deverá estimar o custo de uma magia conforme suas características, incluindo:

- Dano.
- Alcance.
- Velocidade.
- Quantidade de alvos.
- Duração.
- Área de efeito.
- Quantidade de criaturas.
- Resistência das invocações.
- Perseguição de alvos.
- Cura.
- Defesa.
- Controle de movimento.
- Teleporte.
- Interações ambientais.
- Complexidade de processamento.

Uma lança simples deve custar menos que uma lança que atravessa inimigos, retorna à mão, explode e cria correntes elétricas.

A IA poderá sugerir os parâmetros, mas as regras do jogo deverão determinar os limites finais.

Considere mana, tempo de conjuração, recarga, duração máxima, limite de entidades, distância, interrupções e condições de encerramento.

O sistema deve oferecer liberdade para experimentar, mantendo viáveis as habilidades simples e limitando combinações excessivamente poderosas.

Implemente limites independentes para custo de processamento e força de combate. Uma magia pode ser equilibrada em dano e ainda assim ser cara demais para executar.

### 12. Conjuração por voz e texto

A voz será uma forma importante de interação, mas o texto deverá estar disponível como alternativa.

O fluxo de voz deverá:

1. Capturar o áudio.
2. Converter a fala em texto.
3. Reconhecer português brasileiro.
4. Tratar erros razoáveis de transcrição.
5. Enviar a descrição ao interpretador.
6. Mostrar a descrição reconhecida.
7. Validar a habilidade.
8. Executar a conjuração.
9. Informar falhas de forma compreensível.

O jogador deverá conseguir ativar o microfone, falar, cancelar ou confirmar a conjuração.

Investigue tecnologias de reconhecimento de voz, seus custos, latência, limitações de privacidade e alternativas locais.

O sistema deverá tolerar variações de pronúncia e erros comuns dentro dos limites da tecnologia escolhida.

Não exija palavras mágicas fixas. O jogador poderá descrever o efeito naturalmente, sem conhecer os termos internos utilizados pelo motor.

### 13. Grimório e memória das magias

Cada jogador terá um grimório com as habilidades criadas.

Deverá ser possível:

- Salvar e nomear magias.
- Editar descrições.
- Visualizar os efeitos.
- Consultar custos e parâmetros.
- Reutilizar habilidades.
- Organizar categorias.
- Marcar favoritas.
- Consultar o histórico.
- Compartilhar magias com o parceiro.
- Excluir criações.

Armazene a descrição original, a definição validada, a versão do sistema e os dados necessários para reconstruir a habilidade.

O uso de uma magia salva deverá evitar chamadas desnecessárias à IA.

Quando houver alterações nas regras do jogo, verifique a compatibilidade das magias existentes antes de executá-las.

Investigue como separar os dados persistentes do jogador dos dados temporários de uma partida.

### 14. Combinação de magias

Os jogadores devem conseguir combinar habilidades de forma emergente.

Exemplos:

- Um jogador cria uma nuvem de água e o outro a eletrifica.
- Um jogador cria um buraco negro e o outro lança uma explosão contra os inimigos agrupados.
- Um jogador congela o chão e o outro usa vento para empurrar os adversários.
- Um jogador prende um inimigo enquanto o outro prepara um ataque.
- Um jogador cria uma parede de pedra e o outro a transforma em fragmentos.

O sistema deverá utilizar propriedades, tags e regras de interação para evitar a necessidade de programar manualmente todas as combinações possíveis.

As interações precisam ser previsíveis o suficiente para permitir estratégias, mas variadas o suficiente para produzir descobertas interessantes.

### 15. Combate cooperativo e inimigos

Os dois jogadores devem ser importantes para o sucesso da equipe, sem classes rígidas obrigatórias.

Cada jogador poderá atuar como atacante, defensor, invocador, controlador ou suporte, dependendo das magias criadas.

Considere:

- Vida e mana dos aliados.
- Reanimação.
- Recuperação após derrotas.
- Sinergias entre magias.
- Chefes com padrões de ataque.
- Objetivos que exijam coordenação.
- Comunicação e sinalizações.
- Compartilhamento opcional de recursos.

Crie diferentes categorias de inimigos:

- Corpo a corpo.
- Atiradores.
- Invocadores.
- Defensores.
- Assassinos.
- Controladores.
- Criaturas mágicas.
- Mini chefes.
- Chefes com múltiplas fases.

Os inimigos devem considerar distância, linha de visão, ameaças, vida e posicionamento.

Investigue a possibilidade de adaptar suas estratégias às magias observadas, sem permitir que conheçam informações ocultas dos jogadores.

A IA dos inimigos deve funcionar por sistemas de gameplay e decisões eficientes, sem depender de chamadas constantes a modelos de linguagem.

### 16. Mundo, missões e progressão

O jogo deverá oferecer cenários exploráveis com perigos, recursos, objetos interativos e oportunidades táticas.

As regiões futuras poderão incluir florestas encantadas, ruínas, cavernas cristalinas, desertos, pântanos, montanhas congeladas e dimensões instáveis.

A primeira versão deverá possuir um cenário de combate completo e reutilizável.

As missões poderão incluir defesa de objetivos, sobrevivência a ondas, coleta de recursos, resgate de personagens, ativação de mecanismos, investigação de ruínas e batalhas contra chefes.

A progressão poderá oferecer experiência, materiais, artefatos, equipamentos e opções adicionais de personalização.

Os desbloqueios deverão ampliar as possibilidades criativas, em vez de obrigar o jogador a desbloquear cada feitiço individualmente.

### 17. Interface e experiência do jogador

A interface deverá manter o foco no combate e fornecer as informações necessárias.

Considere:

- Vida e mana.
- Mira.
- Estado do microfone.
- Texto reconhecido.
- Estado de processamento da magia.
- Custo previsto.
- Tempo de recarga.
- Informações do parceiro.
- Objetivo atual.
- Inventário rápido.
- Acesso ao grimório.
- Notificações de dano e efeitos.

Quando uma magia falhar, informe o motivo de maneira útil.

Se o sistema oferecer uma aproximação de uma descrição, explique a diferença antes da execução quando isso for importante para a decisão do jogador.

Os efeitos visuais devem permitir distinguir aliados, inimigos, projéteis e ataques perigosos.

Investigue acessibilidade, opções de controle, legendas, sensibilidade de câmera, intensidade de efeitos e alternativas para jogadores que não possam utilizar voz.

### 18. Multiplayer, backend e autoridade do servidor

O multiplayer deverá manter o estado da partida consistente entre os jogadores.

Investigue a diferença entre hospedar uma sessão no computador de um jogador e utilizar um servidor dedicado.

A escolha deverá considerar custos, latência, segurança, facilidade de conexão e manutenção.

O servidor autoritativo deverá controlar os elementos importantes do combate:

- Vida e mana.
- Dano.
- Recargas.
- Duração das magias.
- Criação e eliminação de entidades.
- Colisões relevantes.
- Resultados das missões.
- Validação das habilidades.
- Regras de vitória e derrota.

Os clientes não deverão decidir livremente quanto dano causam ou quais recursos possuem.

A IA poderá interpretar uma descrição no backend e retornar uma definição estruturada. Antes da execução, a definição deverá ser validada de acordo com as regras da partida.

Implemente identificadores consistentes para as entidades e sincronização dos eventos relevantes.

Planeje tratamento de latência, desconexões, perda de pacotes, reconexões e diferenças de desempenho.

Não presuma que dois computadores exibindo uma animação semelhante significa que o multiplayer está funcionando corretamente. Os estados e resultados relevantes precisam ser consistentes.

### 19. Segurança e proteção contra abusos

Toda descrição enviada pelo jogador deve ser considerada entrada não confiável.

O sistema não poderá interpretar descrições de magia como instruções para executar código arbitrário, acessar arquivos, revelar credenciais ou modificar sistemas internos.

A IA deverá produzir dados estruturados dentro de um esquema permitido.

O validador deverá rejeitar ou limitar:

- Parâmetros inválidos.
- Referências a componentes inexistentes.
- Valores negativos indevidos.
- Quantidades excessivas de entidades.
- Durações absurdas.
- Solicitações de processamento excessivo.
- Tentativas de contornar custos.
- Entradas malformadas.
- Abusos de chamadas externas.

Não execute scripts arbitrários produzidos pelo modelo de linguagem.

Implemente limites de requisições, tempo máximo de resposta, proteção das credenciais, logs adequados, tratamento de erros e controles de custo.

Avalie os riscos de injeção de instruções, exploração do cliente, abuso de APIs, fraude no multiplayer e exposição de dados.

A segurança deverá fazer parte da arquitetura desde o início, não ser adicionada apenas depois que o jogo estiver pronto.

### 20. Desempenho e estabilidade

O jogo deverá manter desempenho aceitável mesmo quando várias magias complexas estiverem ativas.

Investigue e implemente:

- Limites de partículas.
- Limites de entidades.
- Distâncias de renderização.
- Níveis de detalhe.
- Reutilização de objetos.
- Redução de atualizações desnecessárias.
- Controle de memória.
- Limites de processamento por magia.
- Monitoramento de latência.
- Perfis de desempenho.

Defina metas mensuráveis depois de conhecer o hardware mínimo, a engine e o escopo.

Não declare o jogo otimizado sem medir o desempenho em condições representativas.

A indisponibilidade do serviço de IA não deverá impedir o uso de magias já salvas, desde que suas definições continuem compatíveis.

### 21. Direção artística e recursos

Defina uma identidade visual coerente que permita variedade sem exigir um ativo exclusivo para cada magia.

Investigue a origem dos modelos, animações, sons e texturas, incluindo recursos gratuitos, pagos e gerados proceduralmente.

Verifique licenças e direitos de uso antes de incorporar ativos externos.

O jogo poderá combinar fantasia épica com criaturas absurdas e humorísticas, conforme a descrição dos jogadores.

Uma criatura invocada deverá ter silhueta reconhecível, comportamento visual coerente e animações adequadas.

Priorize clareza de combate sobre excesso de efeitos.

A geração procedural deverá aproveitar os recursos disponíveis e permitir variações de forma, material, cor, tamanho e comportamento.

### 22. Documentação e decisões obrigatórias

Antes de implementar o jogo, consolide as descobertas em documentos versionados no repositório.

Produza, conforme necessário:

1. Documento de visão do produto.
2. Documento de design do jogo (GDD).
3. Documento de arquitetura técnica.
4. Diagrama de módulos e comunicações.
5. Modelo de dados das habilidades.
6. Fluxo de interpretação e execução das magias.
7. Arquitetura de multiplayer e backend.
8. Análise de ameaças e plano de segurança.
9. Plano de direção artística e gestão de ativos.
10. Plano de testes.
11. Plano de produção e dependências.
12. Estimativa de custos e incertezas.
13. Critérios de aceitação.
14. Plano de manutenção e recuperação de falhas.
15. Registro de decisões aprovadas, pendentes e adiadas.

Não produza documentação extensa apenas para preencher espaço. Cada documento deve orientar uma decisão ou uma atividade real.

Mantenha um arquivo central de decisões arquiteturais. Para cada decisão relevante, registre o problema, as alternativas consideradas, a escolha, a justificativa e as consequências.

### 23. Plano de desenvolvimento

Após a entrevista e a aprovação da proposta técnica, desenvolva o projeto em etapas pequenas e verificáveis.

A ordem inicial sugerida é:

**Fase 1: protótipo de gameplay**

Criar um cenário 3D, um jogador, um inimigo, movimentação, vida, dano e uma magia funcional.

**Fase 2: magia generativa por texto**

Implementar a interpretação da linguagem natural, o formato estruturado, a validação e os componentes de execução.

**Fase 3: personalização procedural**

Permitir que descrições diferentes produzam variações reais de aparência e comportamento.

**Fase 4: testes de viabilidade técnica**

Medir a qualidade da interpretação, a latência, o custo e a estabilidade com descrições criativas e complexas.

**Fase 5: multiplayer cooperativo**

Implementar sessões para dois jogadores, servidor autoritativo, sincronização de entidades e validação das habilidades.

**Fase 6: conjuração por voz**

Adicionar reconhecimento de fala em português brasileiro, com tratamento de erros e alternativa por texto.

**Fase 7: combate cooperativo completo**

Adicionar inimigos variados, um chefe, sinergias e uma missão completa.

**Fase 8: persistência e progressão**

Implementar grimório, recursos, equipamentos, salvamento e recuperação.

**Fase 9: expansão de conteúdo**

Ampliar mapas, inimigos, interações, modelos, animações e missões.

**Fase 10: otimização e preparação para distribuição**

Realizar testes de estabilidade, desempenho, segurança, custos e experiência de uso.

Essa sequência é uma hipótese inicial. Ajuste-a se a investigação técnica demonstrar dependências diferentes, explicando a justificativa.

Não amplie significativamente o conteúdo antes de comprovar que a magia generativa e o multiplayer funcionam.

### 24. Critérios de aceitação

Nenhuma funcionalidade será considerada concluída apenas porque seu código foi escrito.

Cada entrega deverá incluir testes e evidências verificáveis.

Os seguintes testes são obrigatórios para validar o núcleo do projeto:

**Teste A: magia simples**

O jogador descreve "uma bola de fogo que explode ao atingir um inimigo". O jogo cria um projétil funcional, com colisão, explosão, dano e efeitos visuais.

**Teste B: magia criativa**

O jogador descreve "um pombo de pedra que voa até o inimigo e solta ovos explosivos". O sistema cria uma criatura coerente, com voo, perseguição, projéteis e explosões reais.

**Teste C: magia composta**

O jogador descreve "uma lança elétrica que atravessa três inimigos e retorna à minha mão". A habilidade executa os comportamentos dentro dos limites definidos.

**Teste D: interação ambiental**

Um jogador cria uma nuvem de água e o outro aplica eletricidade. O jogo executa a interação prevista pelas regras e apresenta feedback visual consistente.

**Teste E: multiplayer**

Dois jogadores observam os mesmos eventos e resultados relevantes, incluindo colisões, danos, duração e eliminação de entidades.

**Teste F: abuso de parâmetros**

O jogador solicita um milhão de criaturas ou uma magia de duração infinita. O sistema limita ou rejeita a solicitação sem travar a partida.

**Teste G: falha do serviço de IA**

O serviço fica indisponível. As magias salvas continuam funcionando, e novas conjurações apresentam uma mensagem apropriada.

**Teste H: interpretação ambígua**

O sistema solicita esclarecimento ou oferece uma aproximação válida, sem gerar erros internos.

**Teste I: cooperação**

Dois jogadores concluem uma missão combinando magias e enfrentando inimigos com comportamentos distintos.

**Teste J: persistência**

Uma magia é salva, o jogo é fechado e reaberto, e a habilidade pode ser recuperada e utilizada novamente.

Os testes deverão ser adaptados ao escopo aprovado, mas nenhuma funcionalidade essencial poderá ser substituída silenciosamente por uma simulação.

### 25. Controle de qualidade e autonomia

Quero reduzir minha necessidade de intervir manualmente sem perder o controle sobre decisões importantes.

Você poderá pesquisar, planejar, delegar investigações, produzir documentação e executar tarefas reversíveis dentro do escopo aprovado.

Solicite minha aprovação antes de:

- Fixar decisões de arquitetura de alto impacto.
- Assumir despesas ou contratar serviços.
- Publicar código ou dados.
- Instalar dependências de segurança duvidosa.
- Executar operações destrutivas.
- Alterar decisões previamente aprovadas.
- Expandir significativamente o escopo.
- Realizar operações que possam expor credenciais ou informações privadas.

Não me pergunte sobre cada detalhe que um especialista competente possa decidir. Registre as escolhas de baixo risco, siga as convenções aprovadas e explique-as nos relatórios.

Utilize controle de versão desde o início. Faça commits de alterações verificadas, mantenha formas de recuperação e não misture grandes mudanças não testadas.

Após cada etapa, apresente:

- O que foi implementado.
- Quais arquivos e sistemas foram alterados.
- Quais testes foram executados.
- Quais foram os resultados observados.
- Quais problemas permanecem.
- Quais riscos ainda existem.
- Quais critérios foram atendidos.
- O que depende de aprovação ou de trabalho adicional.

Se um teste falhar, investigue e corrija a causa antes de avançar para uma funcionalidade dependente.

Não invente resultados de testes, não esconda limitações e não declare uma integração funcional sem evidência.

### 26. Primeira ação

Inicie exclusivamente a fase de descoberta.

Primeiro, examine os recursos de desenvolvimento e de agentes disponíveis no ambiente, sem instalar dependências ou alterar arquivos de projeto de maneira irreversível.

Depois, apresente brevemente a metodologia proposta e inicie o primeiro bloco de perguntas, priorizando as decisões que determinam o escopo, a experiência do jogo, as plataformas, o orçamento e as ferramentas de desenvolvimento.

Faça perguntas claras, fundamentadas e acessíveis para alguém sem experiência técnica.

Não gere código do jogo nesta etapa.

O resultado esperado da primeira fase é uma compreensão sólida do projeto, com as principais incertezas identificadas, alternativas investigadas, riscos documentados e decisões importantes preparadas para aprovação.

Seu objetivo final é desenvolver um jogo cooperativo online no qual a imaginação dos jogadores seja a linguagem de criação de habilidades, a inteligência artificial interprete as intenções e o motor do jogo execute essas ideias de maneira consistente, segura, visualmente convincente e divertida.