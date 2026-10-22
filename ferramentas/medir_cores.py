"""Mede brilho, contraste e saturação de prints do jogo e compara com a referência.

Critérios da auditoria visual (docs/auditoria-visual-ambiente.md, seção G):
  brilho médio entre 0,55 e 0,70
  variação de brilho (desvio) de pelo menos 0,20
  no máximo 20% da tela quase branca (brilho > 0,9)
  pelo menos 8% da tela escura (brilho < 0,3)

Uso:
  python3 ferramentas/medir_cores.py PRINT.png [PRINT2.png ...]
  (a primeira linha é sempre a referência visual, para comparar)

O HUD de texto no canto superior esquerdo é cortado da conta.
"""
import colorsys
import sys
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
REFERENCIA = RAIZ / "docs" / "referencias" / "arte-conceito-01.png"


def medir(caminho: Path, cortar_hud: bool) -> dict:
    img = Image.open(caminho).convert("RGB")
    if cortar_hud:
        w, h = img.size
        img = img.crop((0, int(h * 0.14), w, h))
    px = np.asarray(img.resize((320, 180))).reshape(-1, 3) / 255.0
    hsv = np.array([colorsys.rgb_to_hsv(*p) for p in px])
    s, v = hsv[:, 1], hsv[:, 2]
    return {
        "sat": s.mean(),
        "brilho": v.mean(),
        "contraste": v.std(),
        "escuro": (v < 0.3).mean(),
        "branco": (v > 0.9).mean(),
        "vivos": ((s > 0.6) & (v > 0.6)).mean(),
    }


def linha(nome: str, m: dict, conferir: bool) -> str:
    ok = ""
    if conferir:
        testes = [0.55 <= m["brilho"] <= 0.70, m["contraste"] >= 0.20, m["branco"] <= 0.20, m["escuro"] >= 0.08]
        ok = f"  criterios {sum(testes)}/4"
    return (f"{nome[:30]:30s} sat {m['sat']:.2f} | brilho {m['brilho']:.2f} | contraste {m['contraste']:.2f}"
            f" | escuro {m['escuro']:4.0%} | quase branco {m['branco']:4.0%} | vivos {m['vivos']:4.0%}{ok}")


if __name__ == "__main__":
    if REFERENCIA.exists():
        print(linha("REFERENCIA", medir(REFERENCIA, False), False))
    for arquivo in sys.argv[1:]:
        print(linha(Path(arquivo).name, medir(Path(arquivo), True), True))
