# Arcane Forge — Vegetação e Cenários

**Tipo:** brainstorming de direção de arte, com grande chance de virar realidade
**Status:** conceito. Nada aqui é decisão aprovada até virar ADR em `docs/decisoes.md`.
**Origem:** conversa do Vitor com o ChatGPT em 25/10/2026, revisada pelo Claude contra as decisões do projeto.
**Quando usar:** Fase 5 (acabamento visual), depois do primeiro teste com o amigo (ADR-035). Antes disso, só se uma peça de cenário for necessária para o item em andamento.

---

## 0. O que foi corrigido em relação ao documento original

| O documento original dizia | O que vale |
|---|---|
| Oito territórios com nomes (Véu de Eldora, Muspelheim, Jotunheim, Terras Ocas, Substrato de Cristal, Mar de Âmbar, Jardins do Zênite, Brejo dos Ecos) | Não existe lista de territórios aprovada. O mapa é montado por módulos feitos à mão (clareira, ruína, ponte, caverna, pântano), sorteados a cada expedição (ADR-018). Até a Fase 4 o mapa é fixo: clareira, caverna da forja e uma área nova. Os nomes foram retirados: Muspelheim e Jotunheim vêm da mitologia nórdica e já são muito usados em outros jogos. |
| Acabamento "low poly refinado" | "Low poly bonitinho": meio termo entre tosco e refinado, formas simples, bem acabadas e simpáticas (ADR-007). |
| Verdes naturais e contidos (oliva, musgo), saturação só em destaques | Paleta saturada e vibrante, na linha de Fortnite: Salve o Mundo e da arte conceito (`docs/referencias/arte-conceito-01.png`): luz dourada, sombras azuladas, verdes vivos. A auditoria visual mediu que o problema do cenário era claridade demais, não saturação demais. A raridade mágica se controla com brilho, partículas e forma, não tirando cor do cenário. |
| Imagem enviada no ChatGPT "aprovada como referência do bioma inicial" | Ainda não é referência. Precisa ser conferida com a arte conceito e salva em `docs/referencias/` com nome padronizado. |
| Próximas etapas e ordem de produção | Prioridade é decidida pelo Claude como gestor, dentro do plano de fases (ADR-035). |

---

## 1. Direção visual da vegetação

- Fantasia natural estilizada: árvores, arbustos, grama, flores, cogumelos, pedras e água bonitos mesmo sem efeito mágico.
- Silhuetas legíveis, geometria simples mas intencional, cara artesanal.
- Cor chapada por face a partir da paleta do jogo; verdes vivos com variação de tom por luz e sombra (quente na luz, azulado na sombra).
- Riqueza visual vem de composição, forma, luz e distribuição, não de quantidade de objetos extraordinários.
- Modelos compartilhados entre módulos sempre que fizer sentido; cada módulo ganha combinações e algumas espécies próprias.
- Tudo modelado no projeto (script no Blender, texturas pintadas pelo Vitor). Sem pacotes prontos e sem modelo gerado por IA (ADR-040).

## 2. Famílias de árvores

**Pinheiros:** família principal das áreas de floresta. Copas em camadas irregulares, para não parecerem triângulos genéricos. Ideia inicial: 3 modelos-base com silhuetas diferentes, variando escala, rotação e tom.

**Árvores de folhas largas:** quebram a repetição dos pinheiros. Florestas mistas, margens de água, áreas úmidas.

**Árvores antigas ou retorcidas:** uso pontual em ruínas e lugares de mistério. Forma estranha não precisa significar magia.

## 3. Outros elementos naturais

**Cogumelos:** comuns de meia altura até a altura do mago; maiores só como exceção marcante. Nem todo cogumelo é especial; os que forem precisam de função ou contexto.

**Pedras:** pequenas espalhadas, médias meio enterradas, agrupamentos, pedras achatadas na beira da água e formações grandes como marco visual. Ajudam a dar escala.

**Lagos e água:** margens irregulares, integradas com pedra e grama, sem atrapalhar caminhos. Por enquanto é só visual: água em que se entra não está no plano (ver ressalva da ADR-044).

**Vegetação complementar:** arbustos, gramíneas, flores, musgo, juncos, raízes e troncos caídos, distribuídos com controle para não disputar atenção.

## 4. Princípio de raridade mágica

A magia não deve ser banalizada pelo excesso. Quatro níveis:

1. **Comum:** maior parte do cenário, sem efeito sobrenatural.
2. **Incomum:** forma, cor ou comportamento peculiar, sem ser mágico.
3. **Arcano raro:** propriedade mágica reconhecível e motivo para estar ali.
4. **Extraordinário:** único ou muito raro, ligado a criaturas, materiais ou mistérios (ex.: rede metálica da Forja, Crumi).

Brilho, partículas e runas luminosas não vão em tudo. O mistério também pode vir do silêncio, da forma, da escala ou do lugar. Isso conversa com `conceitos/forja-de-runas.md` (calçadas metálicas e obeliscos como pistas) e `conceitos/crumi.md`.

## 5. Ideias de ambientação

Ideias, não plano. Servem de cardápio quando cada módulo ou região for criado.

**Módulos já previstos (ADR-018):**
- **Clareira:** pinheiros e folhas largas, grama viva, flores, pedras, talvez um laguinho.
- **Ruína:** árvores retorcidas, raízes entre pedras quebradas, troncos caídos, vegetação mais rala.
- **Caverna (da forja):** cristais arroxeados, raízes descendo do teto, pouca vegetação.
- **Pântano:** árvores de raiz larga, juncos, água escura, musgo, cogumelos discretos.
- **Ponte:** borda de floresta, pedras grandes, vista para o fundo pintado.

**Possíveis regiões futuras (sem nome, sem decisão):**
- Entorno do vulcão inativo da Forja: rochas vulcânicas, solo avermelhado, árvores resistentes ao calor.
- Neve: coníferas com neve, arbustos baixos, lago congelado.
- Cristal: vegetação rara, pedras facetadas, plantas translúcidas.
- Âmbar: árvores douradas, gramíneas quentes, plantas presas em resina.
- Alto ou flutuante: árvores esguias, rochas flutuantes (combina com as ilhas flutuantes do céu da arte conceito).

Regra de consistência: mesma linguagem low poly em tudo; variam composição, terreno, paleta ambiental e luz. Modelos-base reaproveitados com material ou distribuição diferente.

## 6. Controle de densidade visual

- Poucos elementos dominantes por área.
- A maior parte da vegetação é simples e não interativa.
- Coisas extraordinárias precisam de espaço para se destacar.
- Brilho, partículas e formas estranhas usados com seleção.
- Caminhos, água, pontos de interesse e áreas de combate sempre legíveis.

## 7. Catálogo inicial (estimativa)

Algo em torno de 15 a 20 peças reutilizáveis, sem ser meta: pinheiros, folhas largas, arbustos, cogumelos, gramíneas e flores, raízes e troncos, pedras pequenas e médias, agrupamentos de pedra, peças de margem de água. Validar um conjunto enxuto numa área pequena antes de ampliar.

## 8. Checklist para aprovar uma peça nova de cenário

1. A silhueta se lê de longe?
2. Combina com o "low poly bonitinho"?
3. A cor conversa com a paleta saturada da arte conceito?
4. Melhora a composição ou só adiciona ruído?
5. Precisa ser mágica ou funciona como elemento natural?
6. Se for mágica, existe motivo para estar ali?
7. Pode ser reaproveitada em outros módulos?
8. Atrapalha a leitura de caminho, combate ou pontos de interesse?
9. Cabe no orçamento de FPS da RTX 2060 (ADR-031)?

## 9. Pendências

- Conferir a imagem de vegetação gerada no ChatGPT contra a arte conceito e decidir se vira referência oficial.
- Folha de referência dos pinheiros, quando a Fase 5 chegar.
- Decidir quais regiões futuras existem, se alguma, e seus nomes.
