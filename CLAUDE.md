# Instruções para o Claude Code · Arcane Forge

## Antes de qualquer tarefa
1. Leia `docs/decisoes.md` (decisões aprovadas, não rediscutir sem motivo forte).
2. Leia `docs/proposta-tecnica.md` (arquitetura e plano da fase atual).
3. Confira em que fase o projeto está e trabalhe só dentro dela.

## Fase atual
Fase 2: magia por texto com IA real (o porteiro no Supabase já está ligado em `mago.gd`, com fallback para o interpretador local).

A Fase 1 (esqueleto jogável) está praticamente concluída: todos os critérios de aceitação verificáveis por teste e código passam (seção 9 da proposta técnica). Restam só dois critérios que dependem do Vitor jogar e olhar: comparar o canto de atmosfera com a referência visual, e jogar 10 minutos para avaliar se o combate "dá gosto". Não fechar a Fase 1 como concluída até o Vitor confirmar essas duas coisas.

## Quem é o Vitor
- Dono do projeto, iniciante em programação e desenvolvimento de jogos. Nunca abriu uma engine.
- Quer autonomia do Claude: decida sozinho o que um especialista competente decidiria e registre.
- Fale sempre em português do Brasil, texto natural, sem travessões.
- Em temas técnicos, explique de forma lúdica, com analogias e exemplos concretos. Em decisões visuais e de design, ele opina bem: pergunte.
- Prefere feedback honesto a validação.

## Norte visual (pedido do Vitor, 20/10/2026)
A imagem `docs/referencias/arte-conceito-01.png` é o **objetivo do desenvolvimento visual**: cores, iluminação, intensidade e saturação das cores, animação e ambiente.
- Sempre que houver dúvida se o visual está no caminho, abra essa imagem, compare com um print do jogo e pergunte: **o que falta para chegar lá?**
- Responda levando em conta as limitações já aprovadas (ADR-007, ADR-025 revisado e ADR-031): poucos polígonos, hardware mínimo RTX 2060 6 GB (névoa volumétrica, iluminação global em tempo real e mais luzes com sombra agora são permitidas, medindo FPS).
- Toda entrega visual inclui, no relatório ao Vitor, essa comparação: o que já se parece com a referência, o que ainda falta e o que não dá para alcançar no hardware mínimo.
- A densidade de detalhe e de polígonos da imagem não é objetivo. O tom absurdo dos inimigos e o mago tosco de propósito (ADR-007, ADR-019) continuam valendo.

## Pedir aprovação do Vitor antes de
- Mudar uma decisão aprovada em `docs/decisoes.md`.
- Qualquer gasto ou serviço pago.
- Instalar ferramentas ou dependências (diga o nome, a origem e a licença).
- Operações destrutivas ou irreversíveis.
- Ampliar o escopo da fase atual.

## Regras de trabalho
- Nada está pronto sem teste. Mudança visual só está pronta depois de rodar o jogo e guardar um print em `evidencias/fase-N/`.
- Nunca inventar resultado de teste nem esconder limitação.
- Commits pequenos, só de alterações verificadas, mensagens em português.
- Nenhuma chave de API no repositório ou no jogo. Segredos ficam no Supabase.
- A IA de linguagem nunca executa código nem decide física: ela só gera fichas de magia, que o validador confere.
- Toda lógica de combate passa pelo "juiz" (host), mesmo jogando sozinho.
- Respeitar os limites da seção 5 da proposta técnica.

## Ferramentas (sessões na nuvem)
O hook `.claude/hooks/session-start.sh` instala o Godot 4.7.2 e reimporta o projeto ao abrir a sessão.
- Testes: `ferramentas/rodar_testes.sh` (sai com 0 se tudo passar).
- Print do jogo rodando: `ferramentas/tirar_print.sh SAIDA.png [--posicao x,y,z] [--olhar x,y,z] [--frase "..."]`. Renderiza só o modo Compatibility (sem GPU): névoa volumétrica e SDFGI só aparecem no PC do Vitor. O FPS do print não vale nada.
- Depois de criar um script com `class_name` novo, rodar `godot --headless --editor --quit --path jogo` antes dos testes.
- Antes de reimplantar a função do Supabase: `ferramentas/checar_porteiro.sh` (confere a sintaxe com o Node, sem precisar do Deno).
- A rede desta sessão não alcança o Supabase: o deploy da função funciona pela ferramenta MCP, mas a resposta da IA só é testada jogando.

## Agentes (ADR-005)
Equipe enxuta por causa da cota do plano Pro. Acionar especialistas só quando valer a pena:
1. revisor de segurança e multiplayer
2. testador (roda o jogo, tira print, confere critérios)
3. game designer (equilíbrio e diversão)
Evitar agentes em paralelo editando os mesmos arquivos.

## Ao fim de cada etapa, relatar ao Vitor
O que foi feito, arquivos alterados, testes executados e resultados, problemas e riscos restantes, critérios atendidos e o que depende dele.
