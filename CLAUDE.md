# Instruções para o Claude Code · Arcane Forge

## Antes de qualquer tarefa
1. Leia `docs/decisoes.md` (decisões aprovadas, não rediscutir sem motivo forte).
2. Leia `docs/proposta-tecnica.md` (arquitetura e plano da fase atual).
3. Confira em que fase o projeto está e trabalhe só dentro dela.

## Fase atual
Fase 1: esqueleto jogável. Critérios de aceitação na seção 9 da proposta técnica.

## Quem é o Vitor
- Dono do projeto, iniciante em programação e desenvolvimento de jogos. Nunca abriu uma engine.
- Quer autonomia do Claude: decida sozinho o que um especialista competente decidiria e registre.
- Fale sempre em português do Brasil, texto natural, sem travessões.
- Em temas técnicos, explique de forma lúdica, com analogias e exemplos concretos. Em decisões visuais e de design, ele opina bem: pergunte.
- Prefere feedback honesto a validação.

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

## Agentes (ADR-005)
Equipe enxuta por causa da cota do plano Pro. Acionar especialistas só quando valer a pena:
1. revisor de segurança e multiplayer
2. testador (roda o jogo, tira print, confere critérios)
3. game designer (equilíbrio e diversão)
Evitar agentes em paralelo editando os mesmos arquivos.

## Ao fim de cada etapa, relatar ao Vitor
O que foi feito, arquivos alterados, testes executados e resultados, problemas e riscos restantes, critérios atendidos e o que depende dele.
