#!/usr/bin/env python3
"""Gera os RASCUNHOS de som ambiente da caverna da forja, para o Vitor ouvir
e aprovar antes de entrar no jogo (pedido dele em 13/11/2026):

  martelada na bigorna (domina o ambiente), poções borbulhando, páginas de
  livro virando, fogo crepitando, e uma mistura de 45 s com tudo junto.

Síntese própria, sem amostra de terceiro (mesma regra de docs/creditos-audio.md).
O eco de caverna é uma convolução com uma "resposta de sala" inventada: ruído
que vai sumindo, como o rastro que um estalo deixa num salão de pedra.

Uso: python3 ferramentas/gerar_ambiente_forja.py [PASTA_DE_SAIDA]
Sai um .wav de cada som (padrão: evidencias/fase-2/audio). Precisa de numpy.
"""
import os
import sys
import wave

import numpy as np

TAXA = 44100
rng = np.random.default_rng(13)


def tempo(duracao_s):
    return np.arange(int(duracao_s * TAXA)) / TAXA


def ruido_em_faixa(duracao_s, grave_hz, agudo_hz):
    """Ruído só entre duas frequências (corta o resto no espectro)."""
    n = int(duracao_s * TAXA)
    espectro = np.fft.rfft(rng.standard_normal(n))
    freq = np.fft.rfftfreq(n, 1 / TAXA)
    espectro[(freq < grave_hz) | (freq > agudo_hz)] = 0
    som = np.fft.irfft(espectro, n)
    return som / (np.abs(som).max() + 1e-9)


def somar(destino, som, inicio_s, volume=1.0):
    i = int(inicio_s * TAXA)
    fim = min(len(destino), i + len(som))
    if fim > i:
        destino[i:fim] += som[:fim - i] * volume


def convoluir(som, resposta):
    n = len(som) + len(resposta) - 1
    tamanho = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(som, tamanho) * np.fft.rfft(resposta, tamanho), tamanho)[:n]


def eco_de_caverna(som, cauda_s=2.6, quanto=0.35, semente=0):
    """Salão de pedra grande: reflexos cedo e uma cauda escura que demora a sumir."""
    r = np.random.default_rng(100 + semente)
    t = tempo(cauda_s)
    cauda = r.standard_normal(len(t)) * np.exp(-t / (cauda_s / 5.5))
    espectro = np.fft.rfft(cauda)
    freq = np.fft.rfftfreq(len(cauda), 1 / TAXA)
    espectro *= 1 / (1 + (freq / 2600.0) ** 2)   # pedra come o agudo
    cauda = np.fft.irfft(espectro, len(cauda))
    cauda[: int(0.012 * TAXA)] = 0
    for atraso_ms, forca in ((23, 0.5), (41, 0.38), (67, 0.3), (97, 0.22), (143, 0.16)):
        cauda[int(atraso_ms / 1000 * TAXA)] += forca * 14
    cauda /= np.abs(cauda).max()
    molhado = convoluir(som, cauda)
    molhado /= np.abs(molhado).max() + 1e-9
    saida = np.zeros(len(molhado))
    saida[: len(som)] += som * (1 - quanto)
    saida += molhado * quanto * np.abs(som).max()
    return saida


def martelada(forca=1.0, tom=1.0):
    """Clang de metal: parciais que não são múltiplos exatos (bigorna, não nota
    musical), estalo no ataque e um baque grave do peso do martelo."""
    t = tempo(1.4)
    parciais = [(540, 0.55, 5.0), (1265, 0.5, 6.5), (2110, 0.42, 9.0), (2980, 0.3, 12.0), (3890, 0.22, 16.0), (5230, 0.14, 22.0), (6710, 0.08, 30.0)]
    som = np.zeros(len(t))
    for f, vol, queda in parciais:
        f *= tom * (1 + rng.uniform(-0.004, 0.004))
        som += vol * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-queda * t)
    estalo = ruido_em_faixa(0.03, 2500, 12000) * np.exp(-tempo(0.03) * 160)
    som[: len(estalo)] += estalo * 0.9
    som += 0.7 * np.sin(2 * np.pi * 82 * tom * t) * np.exp(-t * 26)
    return som * forca / np.abs(som).max()


def pocoes(duracao_s=10.0):
    """Caldeirão: fervura baixa contínua e bolhas (assobios curtos que sobem de tom)."""
    som = ruido_em_faixa(duracao_s, 180, 650) * 0.1
    t_total = tempo(duracao_s)
    som *= 0.7 + 0.3 * np.sin(2 * np.pi * 0.31 * t_total)
    instante = 0.1
    while instante < duracao_s - 0.3:
        dur = rng.uniform(0.04, 0.11)
        t = tempo(dur)
        f0 = rng.uniform(260, 620)
        f1 = f0 * rng.uniform(1.5, 2.3)
        fase = 2 * np.pi * (f0 * t + (f1 - f0) * t * t / (2 * dur))
        bolha = np.sin(fase) * np.sin(np.pi * t / dur) ** 2
        somar(som, bolha, instante, rng.uniform(0.25, 0.8))
        instante += rng.exponential(0.16) + 0.02
    # um "glub" grande de vez em quando
    for instante in np.arange(1.3, duracao_s - 1, 2.7):
        t = tempo(0.22)
        glub = np.sin(2 * np.pi * (120 + 160 * t / 0.22) * t) * np.sin(np.pi * t / 0.22) ** 2
        somar(som, glub, instante + rng.uniform(-0.4, 0.4), 0.9)
    return som / np.abs(som).max()


def pagina():
    """Uma página virando: chiado de papel que tremula e um toque seco no fim."""
    dur = rng.uniform(0.32, 0.5)
    t = tempo(dur)
    chiado = ruido_em_faixa(dur, 1800, 8500)
    forma = np.sin(np.pi * (t / dur) ** 0.6) ** 1.5
    tremula = 0.55 + 0.45 * np.sin(2 * np.pi * rng.uniform(28, 55) * t + rng.uniform(0, 6))
    som = chiado * forma * tremula
    toque = ruido_em_faixa(0.05, 300, 2500) * np.exp(-tempo(0.05) * 90)
    saida = np.zeros(len(som) + len(toque))
    saida[: len(som)] = som
    saida[len(som) - len(toque) // 3: len(som) - len(toque) // 3 + len(toque)] += toque * 0.5
    return saida / np.abs(saida).max()


def paginas(duracao_s=7.0):
    som = np.zeros(int(duracao_s * TAXA))
    for instante in (0.4, 2.1, 2.75, 4.6, 6.0):
        somar(som, pagina(), instante, rng.uniform(0.6, 1.0))
    return som / np.abs(som).max()


def fogo(duracao_s=12.0):
    """Fogo: ronco grave que respira e estalos secos de lenha (uns 14 por segundo)."""
    t = tempo(duracao_s)
    ronco = ruido_em_faixa(duracao_s, 40, 420)
    respira = 0.6 + 0.25 * np.sin(2 * np.pi * 0.23 * t) + 0.15 * np.sin(2 * np.pi * 0.71 * t + 1.0)
    chama = ruido_em_faixa(duracao_s, 500, 2600) * 0.16 * (0.6 + 0.4 * np.sin(2 * np.pi * 3.1 * t) * np.sin(2 * np.pi * 0.4 * t))
    som = ronco * respira * 0.5 + chama
    instante = 0.0
    while instante < duracao_s - 0.05:
        dur = rng.uniform(0.002, 0.012)
        estalo = ruido_em_faixa(max(dur, 0.004), 1500, 11000)[: int(dur * TAXA)]
        estalo = estalo * np.exp(-np.arange(len(estalo)) / (len(estalo) / 4.0))
        grande = rng.random() < 0.07
        somar(som, estalo, instante, rng.uniform(0.9, 1.6) if grande else rng.uniform(0.12, 0.55))
        instante += rng.exponential(1 / 14.0)
    return som / np.abs(som).max()


def mistura(duracao_s=45.0):
    """O ambiente inteiro, em estéreo: o fogo é o chão, as poções ficam de um
    lado e as páginas do outro, e as marteladas, com eco de caverna, mandam."""
    n = int(duracao_s * TAXA)
    esq = np.zeros(n)
    dir_ = np.zeros(n)
    chao = np.tile(fogo(15.0), 4)[:n]
    esq += chao * 0.16
    dir_ += np.roll(chao, 4000) * 0.16
    caldeirao = np.tile(pocoes(15.0), 4)[:n]
    esq += caldeirao * 0.12
    dir_ += caldeirao * 0.04
    papel = np.zeros(n)
    for instante in np.arange(3.0, duracao_s - 2, 6.5):
        somar(papel, pagina(), instante + rng.uniform(-1.5, 1.5), rng.uniform(0.5, 0.9))
        if rng.random() < 0.5:
            somar(papel, pagina(), instante + rng.uniform(0.5, 0.9), rng.uniform(0.4, 0.7))
    papel = eco_de_caverna(papel, 1.6, 0.2, 1)[:n]
    esq += papel * 0.07
    dir_ += papel * 0.2
    # ferreiro: séries de golpes fortes com batidinhas de quique entre elas
    golpes = np.zeros(n)
    instante = 1.5
    while instante < duracao_s - 3:
        for k in range(rng.integers(3, 7)):
            somar(golpes, martelada(rng.uniform(0.85, 1.0), rng.uniform(0.985, 1.015)), instante)
            if rng.random() < 0.6:
                somar(golpes, martelada(rng.uniform(0.18, 0.3), rng.uniform(1.03, 1.06)), instante + rng.uniform(0.17, 0.22))
            instante += rng.uniform(0.95, 1.2)
        instante += rng.uniform(2.5, 5.0)
    golpes = eco_de_caverna(golpes, 3.0, 0.42, 2)[:n]
    esq += golpes * 0.62
    dir_ += golpes * 0.62
    pico = max(np.abs(esq).max(), np.abs(dir_).max())
    return np.stack([esq, dir_], axis=1) / pico * 0.9


def salvar(caminho, som):
    som = np.asarray(som)
    canais = 1 if som.ndim == 1 else som.shape[1]
    # entrada e saída suaves para não dar clique
    rampa = int(0.02 * TAXA)
    envelope = np.ones(len(som))
    envelope[:rampa] = np.linspace(0, 1, rampa)
    envelope[-rampa:] = np.linspace(1, 0, rampa)
    som = som * (envelope if canais == 1 else envelope[:, None])
    dados = (np.clip(som, -1, 1) * 32000).astype("<i2")
    with wave.open(caminho, "wb") as arq:
        arq.setnchannels(canais)
        arq.setsampwidth(2)
        arq.setframerate(TAXA)
        arq.writeframes(dados.tobytes())
    print("SALVO", caminho, f"{len(som) / TAXA:.1f} s")


def principal():
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pasta = sys.argv[1] if len(sys.argv) > 1 else os.path.join(raiz, "evidencias", "fase-2", "audio")
    os.makedirs(pasta, exist_ok=True)
    tres = np.zeros(int(4.6 * TAXA))
    for k, instante in enumerate((0.1, 1.2, 2.3)):
        somar(tres, martelada(1.0 - k * 0.04, 1.0 + (k - 1) * 0.008), instante)
    salvar(os.path.join(pasta, "forja_1_martelada_na_bigorna.wav"), eco_de_caverna(tres, 3.0, 0.42, 2) * 0.9 / 1.0)
    salvar(os.path.join(pasta, "forja_2_pocoes_borbulhando.wav"), pocoes(10.0) * 0.8)
    salvar(os.path.join(pasta, "forja_3_paginas_virando.wav"), eco_de_caverna(paginas(7.0), 1.6, 0.2, 1) * 0.8)
    salvar(os.path.join(pasta, "forja_4_fogo_crepitando.wav"), fogo(12.0) * 0.8)
    salvar(os.path.join(pasta, "forja_5_ambiente_completo.wav"), mistura(45.0))


if __name__ == "__main__":
    principal()
