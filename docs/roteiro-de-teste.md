# Roteiro de teste no PC do Vitor: ciclo da forja (Fase 2)

Atualizado em 22/10/2026. Tempo estimado: 25 minutos. Pode responder no chat do jeito que sair, sem formatar.

## 1. Baixar a versão nova (1 minuto)

No terminal (Git Bash ou PowerShell), dentro da pasta do projeto:

```
git checkout main
git pull origin main
```

## 2. Medir o FPS (2 minutos, antes de jogar)

Dê dois cliques em `ferramentas\medir_fps.bat`. Ele roda sozinho por uns 70 segundos; não mexa no mouse nem troque de janela. No fim, copie o texto que aparecer e me mande.

## 3. Abrir o jogo

Abra o Godot 4.7, abra a pasta `jogo` e aperte **F5**.

| Tecla | O que faz |
|---|---|
| W A S D / Espaço | andar / pular |
| Mouse | olhar e mirar |
| 1, 2, 3, 4 | usar o medalhão daquele espaço |
| Clique esquerdo | repetir o último medalhão usado |
| E | usar a bigorna (perto dela) e fechar a tela dela |
| C | primeira / terceira pessoa |
| F3 | liga e desliga o contador de FPS |
| Esc | pausa (continuar, reiniciar, sair) |

Na tela da bigorna: clique nas runas para colocar (até 3: uma de forma e até duas de elemento), **Espaço** martela. O botão "Quebrar" ao lado de um medalhão libera o espaço.

## 4. O ciclo (o critério da Fase 2, uns 10 minutos)

1. Você começa com 2 medalhões (espaços 1 e 2) e 2 espaços vazios.
2. **Ache 3 runas** na clareira: são 7 espalhadas, flutuando com a luz da cor delas. Encoste para pegar; elas aparecem embaixo da vida e da mana.
3. **Ache a caverna:** a boca fica na encosta à direita de onde você nasce (leste). Entre nela.
4. **Forje 2 medalhões diferentes** na bigorna. Não vou contar todas as receitas (descobrir faz parte), mas três para começar: fogo sozinho, vida + fogo, arremesso + água. Combinação sem receita também dá alguma coisa.
5. **Saia e use os dois medalhões na galinha zumbi.**
6. Feche o jogo, abra de novo e veja se as receitas que você descobriu continuam no grimório (na tela da bigorna).

Para zerar o grimório e descobrir tudo de novo: apague `%APPDATA%\Godot\app_userdata\Arcane Forge\grimorio.json`.

## 5. Perguntas (é isto que eu preciso de você)

1. **Forjar é divertido?** O que deu vontade de fazer de novo e o que foi chato?
2. Alguma magia **forte ou fraca demais**? A **mana** acabou rápido ou sobrou? A **recarga** dos medalhões incomodou?
3. Achar runas e a caverna foi **fácil, difícil ou confuso**?
4. O **HUD** dá para ler no meio da ação (vida, mana, runas, qual medalhão está recarregando)?
5. Apareceu algum **erro vermelho** no painel "Saída" do Godot, ou algo que travou, atravessou parede ou sumiu? Se sim, print e o texto.

## 6. Bônus: fechar a Fase 1 (5 minutos, se der)

1. Vá até o canto com a tocha e o arco (noroeste da clareira) e compare com `docs/referencias/arte-conceito-01.png`: o clima lembra a referência?
2. O combate "dá gosto" depois de uns 10 minutos jogando?
