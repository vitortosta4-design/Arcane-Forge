"""Traca olhos e boca de lava das 3 expressoes da bigorna na folha do Vitor.

Ancoragem por expressao (pixels do recorte, medidos na grade):
  bloco do rosto entre as placas laterais (x0, x1), topo da laje (y_topo),
  topo da base (y_base) e o fim da runa da testa (y_runa).
Mapeia para o modelo: rosto de x = -0.76 a 0.76; z = 0.42 (base) a 2.15 (topo da laje).
"""
import json
import cv2
import numpy as np

REF = "referencias/bigorna_folha_vitor.png"
RECORTES = {"neutro": (20, 640, 500, 960), "rindo": (500, 640, 990, 960), "raiva": (990, 640, 1520, 960)}
ANCORAS = {  # x0, x1, y_topo, y_base, y_runa
    "neutro": (150, 330, 40, 245, 96),
    "rindo": (130, 315, 40, 240, 82),
    "raiva": (165, 355, 35, 245, 96),
}
Z_BASE, Z_TOPO, MEIA_LARG = 0.42, 2.15, 0.76

img = cv2.imread(REF)
saida = {}
for nome, (cx0, cy0, cx1, cy1) in RECORTES.items():
    c = img[cy0:cy1, cx0:cx1].copy()
    x0, x1, yt, yb, yr = ANCORAS[nome]
    xc = (x0 + x1) / 2
    ex = 2 * MEIA_LARG / (x1 - x0)
    ez = (Z_TOPO - Z_BASE) / (yb - yt)
    hsv = cv2.cvtColor(c, cv2.COLOR_BGR2HSV)
    v, s = hsv[:, :, 2], hsv[:, :, 1]
    lava = ((v >= 215) & (s >= 60)).astype(np.uint8) * 255
    lava = cv2.morphologyEx(lava, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    lava = cv2.morphologyEx(lava, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    janela = np.zeros_like(lava)
    janela[yt + 30:yb, x0 + 4:x1 - 4] = 255
    lava = lava & janela
    n, rot, st, cen = cv2.connectedComponentsWithStats(lava)
    limpo = np.zeros_like(lava)
    for i in range(1, n):
        cxp, cyp = cen[i]
        runa_testa = abs(cxp - xc) < 32 and cyp < yr
        if st[i, cv2.CC_STAT_AREA] > 40 and not runa_testa:
            limpo[rot == i] = 255
    vis = c.copy()
    vis[limpo > 0] = (255, 255, 0)
    cv2.imwrite(f"tracos/bigorna/{nome}_lava.png", np.hstack([c, vis]))
    cont, hier = cv2.findContours(limpo, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    pecas = []
    for i, k in enumerate(cont):
        k = cv2.approxPolyDP(k, 1.0, True)[:, 0, :]
        if len(k) < 3:
            continue
        pecas.append({"buraco": bool(hier[0][i][3] != -1),
                      "pts": [(float((px - xc) * ex), float(Z_BASE + (yb - py) * ez)) for px, py in k]})
    saida[nome] = {"pecas": pecas}
    print(nome, "pecas", len([p for p in pecas if not p["buraco"]]), "buracos", len([p for p in pecas if p["buraco"]]))
json.dump(saida, open("tracos/bigorna/rostos.json", "w"))
