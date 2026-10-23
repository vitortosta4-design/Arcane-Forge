"""Runas da forja, versao 4 (23/10/2026), evolucao da v3 do piloto (runas2.py).

V4, pela comparacao com a folha do Vitor (docs/referencias/runas_folha_vitor.png):
encaixes de quebra-cabeca maiores, laje mais grossa com chanfro largo e claro,
mais lascas e rachaduras, pedra acesa mais tingida. Simbolos iguais aos da v3
(tracados da folha).

Historico da v2:

O que mudou em relacao a runas.py:
- Laje de pedra em pe (mais alta que larga), silhueta propria por runa: topo
  quebrado e assimetrico, quinas lascadas, dentes e fendas em degrau retangular.
- Encaixe preservado: dente retangular na direita, fenda na esquerda (passo PASSO).
- Simbolo ENTALHADO de verdade (booleana): sulco com parede e fundo.
- Face da frente facetada, chanfro largo mais claro, rachaduras finas.
- Acesa: fundo do sulco claro (miolo da brasa), parede na cor saturada do
  elemento, pedra tingida e borda com leve brilho.
- Simbolos redesenhados no traco da referencia e centralizados pela massa da peca.

Uso: python runas.py -- SAIDA folha|comparar|exportar
"""
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "piloto-modelagem", "scripts"))
import base  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else "/tmp/runas2"
MODO = args[1] if len(args) > 1 else "folha"

U = 0.3            # 1 unidade de desenho = 0,3 m
ESP = 0.11 * U / 0.3 * 1.0  # espessura da laje (m)
ESP = 0.075
FUNDO = 0.0075     # profundidade do sulco (m)
PASSO = 0.93       # distancia entre runas encaixadas (em unidades)

# nome: (cor saturada do brilho, miolo claro, tom da pedra acesa)
ELEMENTOS = {
    "fogo": ("#ff4a00", "#ffd24a", "#8c5a4c"),
    "agua": ("#0f7bff", "#8fe4ff", "#4b62a8"),
    "vida": ("#3cff1e", "#c8ff8a", "#5d7a55"),
    "feroz": ("#ff1a1a", "#ff9a7a", "#8c4c46"),
    "gravitacao": ("#9a2cff", "#e2b0ff", "#6a4aa6"),
    "prende": ("#ff9a00", "#ffe27a", "#977650"),
    "arremesso": ("#1a8cff", "#9ae0ff", "#4b68b0"),
    "quebrar": ("#d23cff", "#ffc4ff", "#7c4aa2"),
}
USAR_TRACO = os.environ.get("DESENHO") != "manual"
LUZ_W = 0.3
ORDEM = ["fogo", "agua", "vida", "feroz", "gravitacao", "prende", "arremesso", "quebrar"]

# ---------------------------------------------------------------- silhueta
# Laterais em degrau. A esquerda e a direita deslocada de PASSO, para encaixar:
#   direita: bloco baixo x=0.52 | dente x=0.65 | recuo x=0.40
#   esquerda: recuo x=-0.41    | fenda x=-0.28 | bloco x=-0.53
Z_DEGRAUS = (-0.5, -0.24, 0.2, 0.45)


def silhueta(seed):
    """Contorno (x, z) anti-horario de quebra-cabeca de verdade, como na
    folha: dente quadrado na direita e reentrancia do mesmo tamanho na
    esquerda, na mesma altura em todas as runas, para o dente de uma entrar na
    outra quando ficam a PASSO de distancia. Topo e base com dentes retos de
    tamanho e posicao diferentes em cada runa, e quinas cortadas variadas."""
    r = random.Random(seed)
    j = lambda a: r.uniform(-a, a)  # noqa: E731
    dir_x, esq_x = 0.45, 0.45 - PASSO      # largura da peca = PASSO
    dente = 0.16                           # quanto o dente sai (e a reentrancia entra)
    za, zb = -0.17, 0.13                   # altura do dente (fixa: e o encaixe)
    base_z, topo_z = -0.6 + j(0.03), 0.58 + j(0.03)

    def dentes_horizontais(z, sinal, x_de, x_ate):
        """Um ou dois dentes retos saindo do topo (sinal 1) ou da base (-1),
        andando de x_de para x_ate. Cada dente fica na sua faixa, sem
        sobrepor (contorno que se cruza faz o chanfro explodir)."""
        pts = []
        n = r.choice((1, 1, 2))
        passo = (x_ate - x_de) / n
        for k in range(n):
            ini = x_de + passo * k
            larg = abs(passo) * r.uniform(0.35, 0.6)
            folga = abs(passo) - larg
            x0 = ini + math.copysign(folga * r.uniform(0.2, 0.8), passo)
            x1 = x0 + math.copysign(larg, passo)
            h = r.uniform(0.07, 0.15) * sinal
            pts += [(x0, z), (x0, z + h), (x1, z + h + j(0.015)), (x1, z)]
        return pts

    q1, q2, q3, q4 = (r.uniform(0.06, 0.13) for _ in range(4))   # quinas cortadas
    pts = [(esq_x + q1, base_z)]
    pts += dentes_horizontais(base_z, -1, esq_x + q1 + 0.05, dir_x - q2 - 0.05)
    pts += [(dir_x - q2, base_z), (dir_x, base_z + q2)]
    # direita: dente quadrado para fora
    pts += [(dir_x, za), (dir_x + dente, za), (dir_x + dente, zb), (dir_x, zb)]
    pts += [(dir_x, topo_z - q3), (dir_x - q3, topo_z)]
    pts += dentes_horizontais(topo_z, 1, dir_x - q3 - 0.05, esq_x + q4 + 0.05)
    pts += [(esq_x + q4, topo_z), (esq_x, topo_z - q4)]
    # esquerda: reentrancia quadrada para dentro (o dente da vizinha entra aqui)
    pts += [(esq_x, zb), (esq_x + dente, zb), (esq_x + dente, za), (esq_x, za)]
    pts += [(esq_x, base_z + q1)]
    return pts


def centroide(pts):
    a = cx = cz = 0.0
    n = len(pts)
    for i in range(n):
        x0, z0 = pts[i]
        x1, z1 = pts[(i + 1) % n]
        c = x0 * z1 - x1 * z0
        a += c
        cx += (x0 + x1) * c
        cz += (z0 + z1) * c
    a *= 0.5
    return cx / (6 * a), cz / (6 * a)


# ---------------------------------------------------------------- desenho 2D
def faixa(pontos, larguras):
    """Contorno de uma faixa ao longo de uma linha aberta (x, z)."""
    esq, dir_ = [], []
    n = len(pontos)
    for i, (x, z) in enumerate(pontos):
        a = Vector(pontos[max(i - 1, 0)])
        b = Vector(pontos[min(i + 1, n - 1)])
        t = (b - a).normalized()
        nrm = Vector((-t.y, t.x))
        w = larguras[i] if isinstance(larguras, (list, tuple)) else larguras
        p = Vector((x, z))
        esq.append(tuple(p + nrm * w / 2))
        dir_.append(tuple(p - nrm * w / 2))
    return esq + list(reversed(dir_))


def suavizar(pts, voltas=2, fechado=True):
    """Chaikin: arredonda um contorno."""
    for _ in range(voltas):
        novo = []
        n = len(pts)
        lim = n if fechado else n - 1
        if not fechado:
            novo.append(pts[0])
        for i in range(lim):
            p0, p1 = Vector(pts[i]), Vector(pts[(i + 1) % n])
            novo.append(tuple(p0 * 0.75 + p1 * 0.25))
            novo.append(tuple(p0 * 0.25 + p1 * 0.75))
        if not fechado:
            novo.append(pts[-1])
        pts = novo
    return pts


def folha(cx, cz, comp, larg, ang, curva=0.25):
    pts = []
    for i in range(12):
        t = i / 11
        pts.append(((t - 0.5) * comp, math.sin(t * math.pi) * larg + curva * larg * math.sin(t * math.pi * 2) * 0.3))
    for i in range(10, 0, -1):
        t = i / 11
        pts.append(((t - 0.5) * comp, -math.sin(t * math.pi) * larg * 0.55))
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + x * c - z * s, cz + x * s + z * c) for x, z in pts]


def espiral(c, r0, r1, voltas, a0=0.0, n=60, sentido=1):
    return [(c[0] + math.cos(a0 + sentido * t * voltas * 2 * math.pi) * (r0 + (r1 - r0) * t),
             c[1] + math.sin(a0 + sentido * t * voltas * 2 * math.pi) * (r0 + (r1 - r0) * t))
            for t in [i / (n - 1) for i in range(n)]]


def estadio(cx, cz, comp, raio, ang, n=8):
    """Contorno de um elo de corrente (retangulo de pontas redondas)."""
    pts = []
    for lado, cxo in ((1, comp / 2), (-1, -comp / 2)):
        for i in range(n + 1):
            a = -math.pi / 2 + lado * 0 + (i / n) * math.pi
            a = a if lado == 1 else a + math.pi
            pts.append((cxo + math.cos(a) * raio, math.sin(a) * raio))
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + x * c - z * s, cz + x * s + z * c) for x, z in pts]


# Cada simbolo devolve listas de pecas: ("cheio", contorno) ou ("contorno", pontos_fechados, largura)
#                                       ou ("faixa", pontos_abertos, larguras)
def sim_fogo():
    base_redonda = [(math.cos(a) * 0.25, -0.06 + math.sin(a) * 0.25) for a in
                    [math.radians(d) for d in range(190, 351, 20)]]
    chama = [(0.25, -0.02), (0.235, 0.1), (0.29, 0.25), (0.16, 0.16), (0.11, 0.28), (0.07, 0.4), (0.04, 0.52),
             (-0.02, 0.37), (-0.08, 0.27), (-0.15, 0.22), (-0.19, 0.36), (-0.25, 0.17), (-0.265, 0.03)]
    chama = chama + base_redonda
    curva = espiral((0.0, -0.1), 0.015, 0.095, 1.2, a0=math.radians(90), n=26, sentido=-1)
    curva = curva + [(0.075, 0.02), (0.05, 0.12), (0.02, 0.2)]
    return [("contorno", chama, 0.075),
            ("faixa", curva, [0.03 + 0.035 * i / (len(curva) - 1) for i in range(len(curva))])]


def sim_agua():
    gota = [(0.0, 0.4), (0.09, 0.22), (0.2, 0.05), (0.25, -0.08), (0.21, -0.21), (0.11, -0.29), (0.0, -0.31),
            (-0.11, -0.29), (-0.21, -0.21), (-0.25, -0.08), (-0.2, 0.05), (-0.09, 0.22)]
    miolo = [(0.0, 0.07), (0.05, -0.03), (0.07, -0.11), (0.03, -0.17), (-0.03, -0.17), (-0.07, -0.11), (-0.05, -0.03)]
    return [("contorno", suavizar(gota, 1), 0.065), ("cheio", suavizar(miolo, 1))]


def sim_vida():
    caule = [(0.02, -0.34), (0.0, -0.2), (-0.01, -0.06), (0.0, 0.05), (0.02, 0.12)]
    return [("faixa", caule, [0.075, 0.07, 0.065, 0.055, 0.04]),
            ("cheio", folha(-0.14, 0.15, 0.32, 0.13, math.radians(145))),
            ("cheio", folha(0.15, 0.18, 0.34, 0.14, math.radians(38))),
            ("cheio", folha(0.11, -0.12, 0.17, 0.065, math.radians(28)))]


def sim_feroz():
    pecas = []
    for dx, comp in ((-0.15, 0.5), (0.0, 0.62), (0.15, 0.5)):
        pts, larg = [], []
        for i in range(14):
            t = i / 13
            x = dx - 0.13 * (1 - t) + 0.13 * t + 0.03 * math.sin(t * math.pi)
            z = (t - 0.5) * comp
            pts.append((x, z))
            larg.append(0.008 + 0.085 * math.sin(t * math.pi) ** 0.8)
        pecas.append(("faixa", pts, larg))
    return pecas


def sim_gravitacao():
    pts = espiral((0.0, -0.04), 0.02, 0.24, 2.05, a0=math.radians(200), n=80, sentido=-1)
    # rabo saindo para cima na ponta de fora
    fim = Vector(pts[-1])
    pts += [tuple(fim + Vector((0.03, 0.06))), tuple(fim + Vector((0.08, 0.1)))]
    larg = [0.035 + 0.05 * (i / (len(pts) - 1)) for i in range(len(pts))]
    larg[-1] = 0.02
    return [("faixa", pts, larg)]


def sim_prende():
    d = Vector((math.cos(math.radians(45)), math.sin(math.radians(45))))
    c1, c2 = d * 0.115, d * -0.115
    return [("contorno", estadio(c1.x, c1.y, 0.15, 0.105, math.radians(45)), 0.06),
            ("contorno", estadio(c2.x, c2.y, 0.15, 0.105, math.radians(45)), 0.06)]


def sim_arremesso():
    haste = []
    for i in range(16):
        t = i / 15
        x = -0.3 + 0.42 * t
        z = -0.3 + 0.42 * t - 0.11 * math.sin(t * math.pi)
        haste.append((x, z))
    larg = [0.02 + 0.07 * (i / 15) for i in range(16)]
    ponta = [(0.33, 0.33), (0.02, 0.24), (0.1, 0.14), (0.14, 0.1), (0.24, 0.02)]
    rastros = [("faixa", [(-0.3, -0.06), (-0.14, 0.07)], [0.008, 0.04]),
               ("faixa", [(-0.08, -0.32), (0.05, -0.18)], [0.008, 0.035])]
    return [("faixa", haste, larg), ("cheio", ponta)] + rastros


def sim_quebrar():
    pecas = []
    for i in range(8):
        a = math.radians(90 + 45 * i)
        longo = i % 2 == 0
        r0, r1 = (0.07, 0.37) if longo else (0.075, 0.25)
        w = 0.085 if longo else 0.07
        d = Vector((math.cos(a), math.sin(a)))
        n = Vector((-d.y, d.x))
        p0 = d * r0
        pecas.append(("cheio", [tuple(p0 + n * w), tuple(d * r1), tuple(p0 - n * w)]))
    centro = []
    for i in range(8):
        a = math.radians(90 + 45 * i + 22.5)
        r = 0.05 if i % 2 == 0 else 0.03
        centro.append((math.cos(a) * r, math.sin(a) * r))
    pecas.append(("cheio", centro))
    return pecas


import json as _json
TRACOS = _json.load(open(os.path.join(os.path.dirname(__file__), "..", "..", "piloto-modelagem", "tracos", "tracos.json")))
ALT_RUNA = 2.3    # escala do traco (normalizado pela altura da runa na referencia), ajustada comparando


def area_pol(pts):
    return abs(sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
                   for i in range(len(pts)))) / 2


TAM_SIMB = 0.8   # maior dimensao do simbolo, em unidades (a laje tem ~1 de largura)


def _centro(pts):
    return sum(x for x, _ in pts) / len(pts), sum(z for _, z in pts) / len(pts)


def pecas_validas(nome):
    """Tira pedacos soltos: fica o que e grande ou perto do centro de massa do simbolo."""
    cheios = [p for p in TRACOS[nome]["pecas"] if not p["buraco"]]
    areas = [area_pol(p["pts"]) for p in cheios]
    total = sum(areas)
    mx = sum(_centro(p["pts"])[0] * a for p, a in zip(cheios, areas)) / total
    mz = sum(_centro(p["pts"])[1] * a for p, a in zip(cheios, areas)) / total
    ok = []
    for p, a in zip(cheios, areas):
        cx, cz = _centro(p["pts"])
        if math.hypot(cx - mx, cz - mz) < 0.2:
            ok.append(p)
    return ok, total


def normalizacao(nome):
    """Centro e escala que levam o traco ao tamanho padrao."""
    validos, total = pecas_validas(nome)
    xs = [x for p in validos for x, _ in p["pts"]]
    zs = [z for p in validos for _, z in p["pts"]]
    cx, cz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
    esc = TAM_SIMB / max(max(xs) - min(xs), max(zs) - min(zs))
    return cx, cz, esc, total, (min(xs), max(xs), min(zs), max(zs))


def escalar_peca(p, k):
    pts = [(x * k, z * k) for x, z in p[1]]
    if p[0] in ("cheio", "buraco"):
        return (p[0], pts)
    if p[0] == "contorno":
        return ("contorno", pts, p[2] * k)
    larg = [w * k for w in p[2]] if isinstance(p[2], (list, tuple)) else p[2] * k
    return ("faixa", pts, larg)


DESENHO_MANUAL = {"arremesso"}   # o traco dessa saiu ruim; usa o desenho da v2


def sim_tracado(nome):
    if nome in DESENHO_MANUAL:
        return [escalar_peca(p, 1.2) for p in SIMBOLOS_V2[nome]()]
    cx, cz, esc, total, caixa = normalizacao(nome)
    validos = pecas_validas(nome)[0]
    pecas = []
    for p in TRACOS[nome]["pecas"]:
        if not p["buraco"] and p not in validos:
            continue
        pts = [((x - cx) * esc, (z - cz) * esc) for x, z in p["pts"]]
        pecas.append(("buraco" if p["buraco"] else "cheio", pts))
    return pecas


def miolos_tracados(nome):
    if nome in DESENHO_MANUAL:
        return []
    cx, cz, esc, total, (x0, x1, z0, z1) = normalizacao(nome)
    dentro = lambda m: all(x0 - 0.01 <= x <= x1 + 0.01 and z0 - 0.01 <= z <= z1 + 0.01 for x, z in m["pts"])  # noqa: E731
    return [("buraco" if m["buraco"] else "cheio", [((x - cx) * esc, (z - cz) * esc) for x, z in m["pts"]])
            for m in TRACOS[nome]["miolos"] if dentro(m) and (m["buraco"] or area_pol(m["pts"]) > total * 0.01)]


SIMBOLOS_V2 = None  # preenchido abaixo
SIMBOLOS = {"fogo": sim_fogo, "agua": sim_agua, "vida": sim_vida, "feroz": sim_feroz,
            "gravitacao": sim_gravitacao, "prende": sim_prende, "arremesso": sim_arremesso, "quebrar": sim_quebrar}
SIMBOLOS_V2 = SIMBOLOS


# ---------------------------------------------------------------- 2D -> 3D
def prisma_cheio(bm, contorno, y0, y1):
    vs = [bm.verts.new((x, y0, z)) for x, z in contorno]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.y = y1


def prisma_anel(bm, pts, w, y0, y1):
    """Faixa fechada (contorno de largura w) como um anel solido."""
    n = len(pts)
    fora, dentro = [], []
    for i in range(n):
        a, p, b = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % n])
        t = ((b - p).normalized() + (p - a).normalized()).normalized()
        nrm = Vector((t.y, -t.x))
        fora.append(p + nrm * w / 2)
        dentro.append(p - nrm * w / 2)
    camadas = []
    for y in (y0, y1):
        camadas.append(([bm.verts.new((q.x, y, q.y)) for q in fora], [bm.verts.new((q.x, y, q.y)) for q in dentro]))
    (f0, d0), (f1, d1) = camadas
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((f0[i], f0[j], d0[j], d0[i]))
        bm.faces.new((f1[i], d1[i], d1[j], f1[j]))
        bm.faces.new((f0[i], f1[i], f1[j], f0[j]))
        bm.faces.new((d0[i], d0[j], d1[j], d1[i]))


def objeto_de_bm(nome, bm, mat):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o


def cortador_simbolo(nome, pecas, centro, escala, mat, y0=None, y1=None):
    """Uniao das pecas do simbolo como solidos; pecas "buraco" sao tiradas do cortador."""
    y_frente = -ESP / 2
    y0 = y_frente - 0.02 if y0 is None else y0
    y1 = y_frente + FUNDO if y1 is None else y1
    objs, buracos = [], []
    tr = lambda pts: [(centro[0] + x * escala, centro[1] + z * escala) for x, z in pts]  # noqa: E731
    for k, p in enumerate(pecas):
        bm = bmesh.new()
        if p[0] in ("cheio", "buraco"):
            if p[0] == "buraco":
                prisma_cheio(bm, tr(p[1]), y0 - 0.005, y1 + 0.005)
            else:
                prisma_cheio(bm, tr(p[1]), y0, y1)
        elif p[0] == "contorno":
            prisma_anel(bm, tr(p[1]), p[2] * escala, y0, y1)
        else:
            larg = p[2]
            larg = [w * escala for w in larg] if isinstance(larg, (list, tuple)) else larg * escala
            prisma_cheio(bm, faixa(tr(p[1]), larg), y0, y1)
        o = objeto_de_bm(f"{nome}_{k}", bm, mat)
        (buracos if p[0] == "buraco" else objs).append(o)
    if buracos and objs:
        # junta as pecas cheias e tira os buracos
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        unido = objs[0]
        booleana(unido, buracos)
        for h in buracos:
            bpy.data.objects.remove(h)
        objs = [unido]
    return objs


def booleana(alvo, cortadores, autointersecao=True):
    bpy.context.view_layer.objects.active = alvo
    for c in cortadores:
        m = alvo.modifiers.new("corte", "BOOLEAN")
        m.operation = "DIFFERENCE"
        m.solver = "EXACT"
        m.object = c
        m.material_mode = "TRANSFER"
        m.use_self = autointersecao
        bpy.ops.object.modifier_apply(modifier="corte")
        c.hide_render = True
        c.hide_set(True)


# ---------------------------------------------------------------- materiais
# Pedra acesa: escura e saturada (tijolo, cobalto, musgo...), com o brilho
# so no simbolo (critica da v4: tons pastel pareciam "biscoito").
PEDRA_ACESA = {"fogo": "#7a3322", "agua": "#24418c", "vida": "#335a30", "feroz": "#7a2622",
               "gravitacao": "#4a2d86", "prende": "#7f5420", "arremesso": "#264c92", "quebrar": "#5a2c86"}


def mats_runa(nome, acesa):
    brilho, miolo, tom = ELEMENTOS[nome]
    tom = PEDRA_ACESA[nome]
    sfx = "acesa" if acesa else "apagada"
    if acesa:
        return {
            "frente": [base.material(f"R_{nome}_{sfx}_frente{i}", c, rugosidade=0.85) for i, c in
                       enumerate(misturas(tom, ("#000000", "#000000", "#000000"), (0.38, 0.46, 0.32)))],
            # Escura no arquivo de propósito: o sol do jogo clareia cerca de 1,7x
            # (medido no print: #7a3322 virava #dc724d, salmão). Assim a pedra
            # chega no jogo perto do tom escuro e saturado da folha.
            "borda": base.material(f"R_{nome}_{sfx}_borda", misturar(tom, "#000000", 0.18), rugosidade=0.6,
                                   emissao=brilho, forca=0.08),
            "lado": base.material(f"R_{nome}_{sfx}_lado", misturar(tom, "#000000", 0.45), rugosidade=0.9,
                                  emissao=brilho, forca=0.06),
            "fundo": base.material(f"R_{nome}_{sfx}_fundo", "#000000", rugosidade=1.0, emissao=brilho, forca=2.4),
            "parede": base.material(f"R_{nome}_{sfx}_parede", "#000000", rugosidade=1.0, emissao=miolo, forca=1.3),
            "aura": base.material(f"R_{nome}_{sfx}_aura", misturar(tom, brilho, 0.1), rugosidade=0.8,
                                  emissao=brilho, forca=0.05),
            "miolo": base.material(f"R_{nome}_{sfx}_miolo", "#000000", rugosidade=1.0, emissao=misturar(miolo, brilho, 0.55), forca=2.2),
            "racha": base.material(f"R_{nome}_{sfx}_racha", misturar(tom, "#000000", 0.6), rugosidade=0.9),
        }
    return {
        "frente": [base.material(f"R_{nome}_{sfx}_frente{i}", c, rugosidade=0.88) for i, c in
                   enumerate(("#4f4b60", "#474357", "#575368"))],
        "borda": base.material(f"R_{nome}_{sfx}_borda", "#8a849f", rugosidade=0.65),
        "lado": base.material(f"R_{nome}_{sfx}_lado", "#262232", rugosidade=0.9),
        "fundo": base.material(f"R_{nome}_{sfx}_fundo", "#0f0d16", rugosidade=0.95),
        "parede": base.material(f"R_{nome}_{sfx}_parede", "#1a1724", rugosidade=0.95),
        "racha": base.material(f"R_{nome}_{sfx}_racha", "#2a2732", rugosidade=0.9),
        "aura": base.material(f"R_{nome}_{sfx}_aura", "#6a6572", rugosidade=0.88),
    }


def misturar(a, b, t):
    ca, cb = a.lstrip("#"), b.lstrip("#")
    va = [int(ca[i:i + 2], 16) for i in (0, 2, 4)]
    vb = [int(cb[i:i + 2], 16) for i in (0, 2, 4)]
    return "#" + "".join(f"{int(x + (y - x) * t):02x}" for x, y in zip(va, vb))


def misturas(tom, alvos, ts):
    return [misturar(tom, a, t) for a, t in zip(alvos, ts)]


# ---------------------------------------------------------------- laje
def laje(nome, contorno, mats, seed):
    r = random.Random(seed)
    bm = bmesh.new()
    y_f, y_t = -ESP / 2, ESP / 2
    pts = [(x * U, z * U) for x, z in contorno]
    frente = bm.faces.new([bm.verts.new((x, y_f, z)) for x, z in pts])
    ext = bmesh.ops.extrude_face_region(bm, geom=[frente])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.y = y_t
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    # chanfro largo na borda da frente, fino atras
    arestas_frente = [e for e in bm.edges if all(abs(v.co.y - y_f) < 1e-6 for v in e.verts)]
    bmesh.ops.bevel(bm, geom=arestas_frente, offset=0.026, segments=2, profile=0.55, affect="EDGES")
    arestas_tras = [e for e in bm.edges if all(abs(v.co.y - y_t) < 1e-6 for v in e.verts)]
    bmesh.ops.bevel(bm, geom=arestas_tras, offset=0.008, segments=1, affect="EDGES")
    # face da frente: triangula e subdivide para facetar
    frentes = [f for f in bm.faces if f.normal.y < -0.99 and abs(f.calc_center_median().y - y_f) < 1e-5]
    bmesh.ops.triangulate(bm, faces=frentes, quad_method="BEAUTY", ngon_method="EAR_CLIP")
    frentes = [f for f in bm.faces if f.normal.y < -0.99 and abs(f.calc_center_median().y - y_f) < 1e-5]
    arestas = list({e for f in frentes for e in f.edges})
    bmesh.ops.subdivide_edges(bm, edges=arestas, cuts=1, use_grid_fill=True)
    borda_frente = set()
    for e in bm.edges:
        if all(abs(v.co.y - y_f) < 1e-5 for v in e.verts) and any(f.normal.y > -0.99 for f in e.link_faces):
            borda_frente.update(e.verts)
    for v in bm.verts:
        if abs(v.co.y - y_f) < 1e-5 and v not in borda_frente:
            v.co.y += r.uniform(-0.0004, 0.0006)
    # lascas: empurra alguns vertices do chanfro
    for v in bm.verts:
        if y_f < v.co.y < y_t - 0.004 and v not in borda_frente and r.random() < 0.25:
            v.co.x += r.uniform(-0.005, 0.005)
            v.co.z += r.uniform(-0.005, 0.005)
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return o


def rachaduras(nome, contorno, seed, mat):
    r = random.Random(seed + 7)
    objs = []
    xs = [p[0] for p in contorno]
    zs = [p[1] for p in contorno]
    for k in range(r.choice((3, 4))):
        # comeca numa borda e entra em zigue-zague
        lado = r.choice(("topo", "esq", "dir", "baixo"))
        if lado == "topo":
            p = Vector((r.uniform(-0.3, 0.3), max(zs) - 0.18))
            d = Vector((r.uniform(-0.3, 0.3), -1)).normalized()
        elif lado == "baixo":
            p = Vector((r.uniform(-0.3, 0.3), min(zs) + 0.2))
            d = Vector((r.uniform(-0.3, 0.3), 1)).normalized()
        elif lado == "esq":
            p = Vector((min(xs) + 0.12, r.uniform(-0.45, 0.4)))
            d = Vector((1, r.uniform(-0.4, 0.4))).normalized()
        else:
            p = Vector((max(xs) - 0.2, r.uniform(-0.45, 0.4)))
            d = Vector((-1, r.uniform(-0.4, 0.4))).normalized()
        pts = [tuple(p)]
        for i in range(4):
            d = (d + Vector((r.uniform(-0.6, 0.6), r.uniform(-0.6, 0.6)))).normalized()
            p = p + d * r.uniform(0.04, 0.08)
            pts.append(tuple(p))
        larg = [0.016 * (1 - i / 5) + 0.003 for i in range(len(pts))]
        bm = bmesh.new()
        prisma_cheio(bm, faixa([(x * U, z * U) for x, z in pts], [w * U for w in larg]), -ESP / 2 - 0.01, -ESP / 2 + 0.002)
        objs.append(objeto_de_bm(f"{nome}_racha{k}", bm, mat))
    return objs


def criar_runa(nome, acesa, local=(0, 0, 0), seed=0, rot=(0, 0, 0)):
    mats = mats_runa(nome, acesa)
    contorno = silhueta(seed)
    sfx = "acesa" if acesa else "apagada"
    pedra = laje(f"Runa_{nome}_{sfx}", contorno, mats, seed)
    # materiais na ordem: 0 frente(1o tom), 1 borda, 2 lado, 3 fundo, 4 parede, 5 racha, 6 e 7 tons extras da frente
    lista = [mats["frente"][0], mats["borda"], mats["lado"], mats["fundo"], mats["parede"], mats["racha"],
             mats["frente"][1], mats["frente"][2], mats["aura"]]
    for m in lista:
        pedra.data.materials.append(m)
    cx, cz = centroide(contorno)
    cz -= 0.02
    if USAR_TRACO:
        escala = U
        pecas_simbolo = sim_tracado(nome)
    else:
        escala = U * 1.2
        pecas_simbolo = SIMBOLOS[nome]()
    cort = cortador_simbolo(f"Corte_{nome}_{sfx}", pecas_simbolo, (cx * U, cz * U), escala, mats["fundo"])
    cort += rachaduras(f"Corte_{nome}_{sfx}", contorno, seed, mats["racha"])
    booleana(pedra, cort)
    for c in cort:
        bpy.data.objects.remove(c)
    # reclassifica faces por normal e posicao
    r = random.Random(seed + 3)
    y_f = -ESP / 2
    idx = {m.name: i for i, m in enumerate(pedra.data.materials)}
    for f in pedra.data.polygons:
        nome_mat = pedra.data.materials[f.material_index].name
        ny = f.normal.y
        if nome_mat == mats["fundo"].name:
            f.material_index = idx[mats["fundo"].name] if ny < -0.7 else idx[mats["parede"].name]
        elif nome_mat == mats["racha"].name:
            continue
        else:
            if ny < -0.9 and f.center.y < y_f + 0.0025:
                d = math.hypot(f.center.x - cx * U, f.center.z - cz * U)
                f.material_index = 8 if (acesa and d < 0.115) else r.choice((0, 6, 7))
            elif ny < -0.15:
                f.material_index = idx[mats["borda"].name]
            else:
                f.material_index = idx[mats["lado"].name]
    base.chapado(pedra)
    if acesa and USAR_TRACO:
        # brasa: o traco encolhido, encostado no fundo do sulco, bem mais claro
        y_fundo = -ESP / 2 + FUNDO
        brasa = cortador_simbolo(f"Brasa_{nome}", miolos_tracados(nome), (cx * U, cz * U), escala,
                                 mats["miolo"], y0=y_fundo - 0.0022, y1=y_fundo - 0.0004)
        for o in brasa:
            base.chapado(o)
            o.parent = pedra
        # luz propria: ilumina a pedra em volta e o que estiver perto
        bpy.ops.object.light_add(type="POINT", location=(cx * U, -ESP / 2 - 0.035, cz * U))
        luz = bpy.context.active_object
        luz.name = f"Luz_{nome}"
        luz.data.energy = LUZ_W
        luz.data.shadow_soft_size = 0.02
        luz.data.color = base.cor(ELEMENTOS[nome][0])[:3]
        luz.parent = pedra
    pedra.location = local
    pedra.rotation_euler = rot
    return pedra


# ---------------------------------------------------------------- render
def palco():
    cena = bpy.context.scene
    mundo = bpy.data.worlds.new("Cinza")
    cena.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = base.cor("#6c6c70")
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    bpy.ops.object.light_add(type="SUN", location=(0, 0, 5))
    sol = bpy.context.active_object
    sol.data.energy = 4.2
    sol.data.color = base.cor("#ffe6cc")[:3]
    sol.data.angle = math.radians(8)
    sol.rotation_euler = (math.radians(38), math.radians(-28), math.radians(-30))
    bpy.ops.object.light_add(type="AREA", location=(1.5, -2.5, 0.5))
    f = bpy.context.active_object
    f.data.energy = 60
    f.data.size = 4
    f.rotation_euler = (math.radians(80), 0, math.radians(30))
    bpy.ops.object.light_add(type="AREA", location=(0, 2, 2))
    c = bpy.context.active_object
    c.data.energy = 40
    c.data.size = 3
    c.rotation_euler = (math.radians(-45), 0, 0)
    cena.render.film_transparent = True
    if os.environ.get("COR") == "padrao":
        pass
    if os.environ.get("SEM_BRILHO") != "1":
        base.ativar_brilho(forca=0.45, limiar=1.0, tamanho=0.55)


def camera_orto(centro, escala, largura, altura):
    bpy.ops.object.camera_add(location=(centro[0], -3, centro[1]))
    cam = bpy.context.active_object
    cam.rotation_euler = (math.radians(90), 0, 0)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = escala
    bpy.context.scene.camera = cam
    return cam


GIRO = (math.radians(-12), math.radians(4), math.radians(-17))


def principal():
    base.limpar_cena()
    if MODO == "exportar":
        for acesa, arq in ((False, ""), (True, "_acesas")):
            base.limpar_cena()
            objs = [criar_runa(n, acesa, local=(i * 0.4, 0, 0), seed=i) for i, n in enumerate(ORDEM)]
            print("TRIANGULOS_RUNAS" + arq, base.contar_triangulos(objs))
            base.exportar_glb(SAIDA + arq + ".glb", objs, luzes=acesa)
        return
    palco()
    if MODO == "comparar":
        # cada par (apagada, acesa) num quadro proprio, para comparar com o recorte da referencia
        so = os.environ.get("NOMES")
        for i, nome in enumerate(ORDEM):
            if so and nome not in so.split(","):
                continue
            for o in list(bpy.data.objects):
                if o.type == "MESH":
                    bpy.data.objects.remove(o)
            criar_runa(nome, False, local=(-0.18, 0, 0), seed=i, rot=GIRO)
            criar_runa(nome, True, local=(0.18, 0, 0), seed=i, rot=GIRO)
            camera_orto((0.0, 0.0), 0.86, 670, 460)
            base.renderizar(f"{SAIDA}_{nome}.png", largura=670, altura=460, amostras=48, transparente=True)
        return
    # folha completa: 2 fileiras de 4 pares + 3 combinacoes encaixadas
    for i, nome in enumerate(ORDEM):
        col, fila = i % 4, i // 4
        x0 = (col - 1.5) * 0.8
        z0 = 0.62 - fila * 0.58
        criar_runa(nome, False, local=(x0 - 0.18, 0, z0), seed=i, rot=GIRO)
        criar_runa(nome, True, local=(x0 + 0.18, 0, z0), seed=i, rot=GIRO)
    combos = [("fogo", "prende", "arremesso"), ("vida", "gravitacao", "quebrar"), ("agua", "arremesso", "feroz")]
    for c, trio in enumerate(combos):
        xc = (c - 1) * 1.08
        for k, nome in enumerate(trio):
            criar_runa(nome, True, local=(xc + (k - 1) * PASSO * U, 0, -0.6), seed=ORDEM.index(nome),
                       rot=(math.radians(-8), 0, 0))
    camera_orto((0.0, 0.03), 3.35, 1536, 1024)
    base.renderizar(SAIDA + ".png", largura=1536, altura=1024, amostras=48, transparente=True)


principal()
