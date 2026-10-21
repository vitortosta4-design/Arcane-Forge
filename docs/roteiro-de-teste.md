# Roteiro de teste no PC do Vitor (21/10/2026)

Tempo estimado: 20 a 30 minutos. Pode anotar as respostas direto no chat, do jeito que sair.

## 1. Baixar a versão nova

No terminal (Git Bash ou PowerShell), dentro da pasta do projeto:

```
git fetch origin
git checkout claude/arcane-forge-continuation-4rfd9u
git pull origin claude/arcane-forge-continuation-4rfd9u
```

Depois abra o Godot 4.7, importe (ou abra) a pasta `jogo` e aperte **F5** para rodar.

## 2. Controles

| Tecla | O que faz |
|---|---|
| W A S D | andar |
| Espaço | pular |
| Mouse | olhar |
| Clique esquerdo | bola de fogo rápida (sem IA) |
| C | trocar primeira/terceira pessoa |
| Q | abrir a caixa de magia; escreva a frase e aperte Enter |
| Esc | fechar a caixa de magia |

## 3. Primeiro olhar (2 minutos, sem conjurar nada)

1. Qual o **FPS** no canto da tela, parado e andando?
2. Aparece **névoa no ar** (raios de luz, ar meio "denso")? Na nuvem eu não consigo ver isso.
3. A tocha do canto de atmosfera **brilha e espalha luz** nas paredes?
4. Comparando com `docs/referencias/arte-conceito-01.png`: o que mais incomoda?

## 4. Magias pela IA (uma frase por vez)

Para cada frase, anote: **a IA entendeu?** (fez algo parecido com o pedido), **a legenda** que apareceu embaixo, e **quanto tempo** demorou.

1. "bola de fogo que explode"
2. "me cure"
3. "escudo de pedra no meu corpo"
4. "levante um muro de pedra na minha frente"
5. "teleporte para frente"
6. "chuva ao meu redor que deixa todo mundo molhado"
7. "faísca elétrica" (de preferência logo depois da chuva, na galinha molhada)
8. "bola de lava que deixa uma poça de fogo no chão"
9. "pó que cega a galinha"
10. "invoque um pombo de pedra"
11. "pombo de pedra que bombardeia com ovos explosivos"
12. Uma frase **livre e absurda**, do jeito que você imagina o jogo (ex.: "vaca de água que solta bolhas")

Se aparecer "não entendi" ou nada acontecer, anote a frase exata.

## 5. Sensação do combate (10 minutos)

Esse é um dos dois critérios da Fase 1 que só você pode fechar. Jogue livremente contra a galinha e responda:
- O combate **dá gosto**? O que ficou chato ou sem graça?
- Alguma magia ficou forte ou fraca demais? Mana acabando rápido ou devagar?

## 6. Decisões visuais que esperam você

- **"Queimando"** ainda puxa para salmão. Vale gastar desempenho com partículas de chama?
- A **parede** é um bloco cinza liso. Deixar assim por enquanto ou caprichar já?
- A regra de magia "má" **sair pela culatra** (ADR-017) ainda não existe: com que frequência e o que deveria acontecer?

## 7. Se der erro

Tire um print da tela e copie o texto vermelho do painel "Saída" (Output) do Godot.
