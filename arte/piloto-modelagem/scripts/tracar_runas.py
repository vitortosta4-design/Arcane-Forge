"""Extrai o desenho do simbolo aceso de cada runa da folha de referencia.

Para cada runa: recorta a runa acesa, separa os pixels do simbolo (claros e
saturados), limpa a mascara e salva contornos (com buracos) normalizados.
Saida: tracos/<nome>.json e tracos/<nome>_mascara.png (para conferencia).
"""
import json
import sys
import cv2
import numpy as np

REF = "referencias/runas_folha_vitor.png"
# caixa (x0, y0, x1, y1) de cada runa ACESA na folha 1536x1024
CAIXAS = {
    "fogo": (215, 55, 380, 280), "agua": (590, 55, 745, 280), "vida": (955, 55, 1110, 280),
    "feroz": (1330, 55, 1490, 280), "gravitacao": (205, 350, 375, 575), "prende": (585, 350, 750, 575),
    "arremesso": (955, 350, 1120, 575), "quebrar": (1325, 350, 1495, 575),
}
# (limiar de brilho V, saturacao minima)
CAIXAS_APAGADAS = {}
LIMIAR_ESCURO = {"feroz": 88, "arremesso": 88}
LIMIAR_V = {"fogo": (245, 0), "agua": (245, 0), "vida": (190, 70), "feroz": (238, 0), "gravitacao": (245, 0),
            "prende": (245, 0), "arremesso": (242, 0), "quebrar": (238, 0)}

img = cv2.imread(REF)
saida = {}
for nome, (x0, y0, x1, y1) in CAIXAS.items():
    rec = img[y0:y1, x0:x1]
    hsv = cv2.cvtColor(rec, cv2.COLOR_BGR2HSV)
    v, s = hsv[:, :, 2], hsv[:, :, 1]
    lim, smin = LIMIAR_V[nome]
    mask = ((v >= lim) & (s >= smin)).astype(np.uint8) * 255
    if nome in CAIXAS_APAGADAS:
        ax0, ay0, ax1, ay1 = CAIXAS_APAGADAS[nome]
        rec = img[ay0:ay1, ax0:ax1]
        hsv = cv2.cvtColor(rec, cv2.COLOR_BGR2HSV)
        v = hsv[:, :, 2]
        mask = (v <= LIMIAR_ESCURO[nome]).astype(np.uint8) * 255
        dif = np.abs(rec.astype(np.int16) - np.array([110, 106, 107], dtype=np.int16)).sum(axis=2)
        pedra_a = (dif > 30).astype(np.uint8)
        pedra_a = cv2.morphologyEx(pedra_a, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
        interior = cv2.erode(pedra_a, np.ones((23, 23), np.uint8))
        mask = mask & (interior * 255)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    # so os componentes perto do centro (tira brilho de borda da pedra)
    n, rotulos, stats, cent = cv2.connectedComponentsWithStats(mask)
    h, w = mask.shape
    limpo = np.zeros_like(mask)
    for i in range(1, n):
        cx, cy = cent[i]
        area = stats[i, cv2.CC_STAT_AREA]
        if area > 90 and abs(cx - w / 2) < w * 0.3 and abs(cy - h * 0.5) < h * 0.3:
            limpo[rotulos == i] = 255
    if nome == "feroz":   # garras finas demais no traco: engrossa um pouco
        limpo = cv2.dilate(limpo, np.ones((3, 3), np.uint8), iterations=2)
    cv2.imwrite(f"tracos/{nome}_mascara.png", limpo)
    # miolo: parte mais clara (para a brasa no fundo do sulco)
    miolo = ((v >= 245) & (limpo > 0)).astype(np.uint8) * 255
    fundo = np.array([110, 106, 107], dtype=np.int16)
    dif = np.abs(rec.astype(np.int16) - fundo).sum(axis=2)
    pedra = (dif > 30).astype(np.uint8)
    pedra = cv2.morphologyEx(pedra, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    py_, px_ = np.nonzero(pedra)
    alt_runa = float(py_.max() - py_.min())
    contornos, hier = cv2.findContours(limpo, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    ys, xs = np.nonzero(limpo)
    cxm, cym = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    alt = alt_runa  # normaliza pela altura da runa: 1 = runa inteira
    pecas = []
    for i, c in enumerate(contornos):
        c = cv2.approxPolyDP(c, 0.9, True)[:, 0, :]
        if len(c) < 3:
            continue
        pts = [((float(px) - cxm) / alt, -(float(py) - cym) / alt) for px, py in c]
        eh_buraco = hier[0][i][3] != -1
        pecas.append({"buraco": bool(eh_buraco), "pai": int(hier[0][i][3]), "id": i, "pts": pts})
    # miolo: o traco encolhido (brasa no fundo do sulco)
    nucleo = cv2.erode(limpo, np.ones((5, 5), np.uint8), iterations=1)
    cn, hn = cv2.findContours(nucleo, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    miolos = []
    for i, c in enumerate(cn):
        if abs(cv2.contourArea(c)) < 12:
            continue
        c = cv2.approxPolyDP(c, 0.8, True)[:, 0, :]
        if len(c) >= 3:
            miolos.append({"buraco": bool(hn[0][i][3] != -1),
                           "pts": [((float(px) - cxm) / alt, -(float(py) - cym) / alt) for px, py in c]})
    saida[nome] = {"pecas": pecas, "miolos": miolos}
    print(nome, "pecas", sum(1 for p in pecas if not p["buraco"]), "buracos", sum(1 for p in pecas if p["buraco"]),
          "pontos", sum(len(p["pts"]) for p in pecas))
json.dump(saida, open("tracos/tracos.json", "w"))
