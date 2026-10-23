"""Folha de quadros numerada e mapa de som de uma gravação (gravar_quadros.sh).

Uso: python3 -I folha_quadros.py PASTA FPS COLUNAS DE ATE PASSO
Lê PASTA/quadros/q*.png e PASTA/quadros/q.wav (o Movie Maker grava os dois).
"""
import glob
import os
import struct
import sys
import wave

from PIL import Image, ImageDraw

pasta, fps, colunas, de, ate, passo = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6])
quadros = sorted(glob.glob(os.path.join(pasta, "quadros", "q*.png")))
if ate < 0 or ate >= len(quadros):
    ate = len(quadros) - 1
escolhidos = list(range(de, ate + 1, passo))
largura, altura = 384, 216
linhas = (len(escolhidos) + colunas - 1) // colunas
folha = Image.new("RGB", (largura * colunas, altura * linhas), "black")
desenho = ImageDraw.Draw(folha)
for i, n in enumerate(escolhidos):
    imagem = Image.open(quadros[n]).convert("RGB").resize((largura, altura))
    x, y = (i % colunas) * largura, (i // colunas) * altura
    folha.paste(imagem, (x, y))
    rotulo = "q%d  %.3fs" % (n, n / fps)
    desenho.rectangle((x, y, x + 110, y + 16), fill="black")
    desenho.text((x + 4, y + 2), rotulo, fill="yellow")
folha.save(os.path.join(pasta, "folha.png"))
print("Folha: %s (quadros %d a %d, passo %d, de %d gravados)" % (os.path.join(pasta, "folha.png"), de, ate, passo, len(quadros)))

# Som: pico por quadro, para conferir se o som cai no quadro do impacto.
arquivo_som = os.path.join(pasta, "quadros", "q.wav")
linhas_som = []
if os.path.exists(arquivo_som):
    w = wave.open(arquivo_som)
    canais, taxa, largura_amostra, total = w.getnchannels(), w.getframerate(), w.getsampwidth(), w.getnframes()
    bruto = w.readframes(total)
    formato = {2: "h", 4: "i"}.get(largura_amostra)
    if formato:
        amostras = struct.unpack("<%d%s" % (len(bruto) // largura_amostra, formato), bruto)
        maximo = float(2 ** (8 * largura_amostra - 1))
        por_quadro = taxa // fps
        for q in range(total // por_quadro):
            trecho = amostras[q * por_quadro * canais:(q + 1) * por_quadro * canais]
            pico = max((abs(a) for a in trecho), default=0) / maximo
            if pico > 0.01:
                linhas_som.append("quadro %d (%.3fs): pico %.2f" % (q, q / fps, pico))
    else:
        linhas_som.append("formato de áudio não lido (%d bytes por amostra)" % largura_amostra)
else:
    linhas_som.append("sem áudio gravado")
with open(os.path.join(pasta, "som.txt"), "w") as f:
    f.write("\n".join(linhas_som) + "\n")
print("Som: %s (%d quadros com som)" % (os.path.join(pasta, "som.txt"), len([l for l in linhas_som if l.startswith("quadro")])))
