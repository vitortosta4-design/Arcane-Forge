import sys
from PIL import Image
ref = Image.open("referencias/bigorna_folha_vitor.png").convert("RGB")
CX = {"frente": (20, 10, 425, 590), "lado": (440, 10, 745, 590), "costas": (770, 10, 1150, 590),
      "cima": (1170, 150, 1500, 590), "rosto_neutro": (20, 640, 500, 950),
      "rosto_rindo": (500, 640, 990, 950), "rosto_raiva": (990, 640, 1520, 950)}
def lado(v, img, h):
    r = ref.crop(CX[v]); r = r.resize((int(r.width*h/r.height), h))
    m = Image.open(img).convert("RGBA"); m = m.crop(m.getbbox())
    f = Image.new("RGBA", m.size, (108,108,112,255)); f.alpha_composite(m)
    m = f.convert("RGB"); m = m.resize((int(m.width*(h-20)/m.height), h-20))
    out = Image.new("RGB", (r.width+m.width+20, h), (108,108,112)); out.paste(r,(0,0)); out.paste(m,(r.width+20,10)); return out
pref, saida = sys.argv[1], sys.argv[2]
ls = [lado(v, f"{pref}_{v}.png", 560 if not v.startswith("rosto") else 400) for v in sys.argv[3].split(",")]
W = max(l.width for l in ls); o = Image.new("RGB", (W, sum(l.height for l in ls)), (108,108,112)); y = 0
for l in ls: o.paste(l, (0, y)); y += l.height
o.save(saida)
