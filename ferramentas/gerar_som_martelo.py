#!/usr/bin/env python3
"""Gera o som PROVISÓRIO do martelo na bigorna (jogo/assets/som/martelo_bigorna.wav).

Síntese própria, sem amostra de terceiro (docs/creditos-audio.md): um estalo de
ruído no ataque, um baque grave e um "clang" de metal feito de parciais que não
são múltiplos exatos (é isso que soa a sino/bigorna em vez de nota musical).
Só biblioteca padrão. Uso: python3 ferramentas/gerar_som_martelo.py
Para trocar por gravação de verdade (ADR-028): salvar o WAV novo por cima do
arquivo gerado, com o mesmo nome; nada no código muda.
"""
import math
import os
import random
import struct
import wave

TAXA = 44100
DURACAO_S = 0.7
# (frequência Hz, volume, queda por segundo): agudos morrem antes dos médios.
PARCIAIS = [(587, 0.5, 7.0), (1373, 0.42, 9.0), (2291, 0.3, 13.0), (3517, 0.2, 18.0), (5120, 0.12, 26.0)]

random.seed(7)
amostras = []
for i in range(int(TAXA * DURACAO_S)):
    t = i / TAXA
    clang = sum(v * math.exp(-q * t) * math.sin(2 * math.pi * f * t) for f, v, q in PARCIAIS)
    baque = 0.7 * math.exp(-28 * t) * math.sin(2 * math.pi * (95 - 40 * t) * t)
    estalo = 0.6 * math.exp(-140 * t) * random.uniform(-1, 1)
    amostras.append(clang * 0.55 + baque + estalo)
pico = max(abs(a) for a in amostras)
saida = os.path.join(os.path.dirname(__file__), "..", "jogo", "assets", "som", "martelo_bigorna.wav")
with wave.open(saida, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(TAXA)
    w.writeframes(b"".join(struct.pack("<h", int(a / pico * 0.85 * 32767)) for a in amostras))
print("Gerado:", os.path.normpath(saida))
