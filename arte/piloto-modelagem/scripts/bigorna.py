"""Bigorna viva da forja (Arcane Forge), modelada pela folha de referencia do Vitor.

Partes: base em degraus de blocos, bigorna de pedra com chifres e rosto de lava,
placas laterais com runas, coluna-martelo com nucleo derretido e runas, travessa
com cabecas de martelo, anel de pedras flutuando com arcos de fogo.
Tres rostos (neutro, rindo, raiva) como pecas separadas: o jogo liga um por vez.
Animacoes: Orbita (pedras girando, em loop) e Tremer (bigorna sacode ao errar).

Uso: python bigorna.py -- SAIDA folha|exportar
Unidades em metros; frente da bigorna olha para -Y.
"""
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(__file__))
import base  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else "/tmp/bigorna"
MODO = args[1] if len(args) > 1 else "folha"

random.seed(11)

# ---------------------------------------------------------------- materiais
def criar_materiais():
    global PEDRA, PEDRA_ESCURA, PEDRA_CLARA, METAL, LAVA, LAVA_CLARA, RUNA, BOCA_FUNDO
    PEDRA = base.material("PedraForja", "#5b5363", rugosidade=0.85)
    PEDRA_ESCURA = base.material("PedraForjaEscura", "#463f4e", rugosidade=0.9)
    PEDRA_CLARA = base.material("PedraForjaClara", "#6c6474", rugosidade=0.85)
    METAL = base.material("MetalTravessa", "#7d7768", rugosidade=0.55, metal=0.4)
    LAVA = base.material("Lava", "#000000", rugosidade=1.0, emissao="#ff5a00", forca=2.0)
    LAVA_CLARA = base.material("LavaClara", "#000000", rugosidade=1.0, emissao="#ffa000", forca=2.4)
    RUNA = base.material("Runa", "#000000", rugosidade=1.0, emissao="#ff7000", forca=2.6)
    BOCA_FUNDO = base.material("BocaFundo", "#000000", rugosidade=1.0, emissao="#ff4800", forca=1.6)


# ---------------------------------------------------------------- utilitarios
def nomear(o, nome):
    o.name = nome
    if o.data:
        o.data.name = nome
    return o


def caixa(nome, centro, tam, mat, chanfro=0.0, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=centro, rotation=rot)
    o = nomear(bpy.context.active_object, nome)
    o.scale = tam
    base.aplicar_transformacoes(o)
    if chanfro:
        m = o.modifiers.new("chanfro", "BEVEL")
        m.width = chanfro
        m.segments = 1
        m.limit_method = "NONE"
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier="chanfro")
    base.aplicar(o, mat)
    base.chapado(o)
    return o


def casco(nome, pontos, mat):
    """Malha convexa a partir de uma lista de pontos (bom para pecas facetadas)."""
    bm = bmesh.new()
    for p in pontos:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts[:])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    base.aplicar(o, mat)
    base.chapado(o)
    return o


def pedra(nome, centro, raio, mat, alto=1.0, seed=0):
    random.seed(seed)
    pts = []
    for i in range(9):
        a = 2 * math.pi * i / 9 + random.uniform(-0.2, 0.2)
        for z in (-0.5, 0.5):
            r = raio * random.uniform(0.75, 1.05)
            pts.append(Vector((math.cos(a) * r, math.sin(a) * r, z * raio * alto * random.uniform(0.8, 1.1))))
    pts.append(Vector((0, 0, raio * alto * 0.75)))
    pts.append(Vector((0, 0, -raio * alto * 0.75)))
    o = casco(nome, pts, mat)
    o.location = centro
    return o


def losango(nome, centro, tam, mat, plano="XZ", espessura=0.035, giro=0.0):
    """Runa em losango vazado (contorno), usada na testa, na base e na coluna."""
    bpy.ops.mesh.primitive_torus_add(major_radius=tam, minor_radius=espessura,
                                     major_segments=4, minor_segments=4, location=centro)
    o = nomear(bpy.context.active_object, nome)
    if plano == "XZ":
        o.rotation_euler = (math.radians(90), 0, 0)
    elif plano == "YZ":
        o.rotation_euler = (math.radians(90), 0, math.radians(90))
    o.rotation_euler.z += giro
    base.aplicar_transformacoes(o)
    base.aplicar(o, mat)
    base.chapado(o)
    return o


def runa_oito(prefixo, centro, tam, mat, plano="XZ"):
    """Runa em forma de '8' (dois losangos empilhados), como nas placas laterais."""
    a = losango(prefixo + "A", (centro[0], centro[1], centro[2] + tam * 0.75), tam * 0.55, mat, plano, 0.026)
    b = losango(prefixo + "B", (centro[0], centro[1], centro[2] - tam * 0.75), tam * 0.55, mat, plano, 0.026)
    return [a, b]


def traco(nome, p1, p2, mat, grossura=0.03):
    """Traco reto de runa entre dois pontos (no plano da face)."""
    p1, p2 = Vector(p1), Vector(p2)
    meio = (p1 + p2) / 2
    d = p2 - p1
    o = caixa(nome, meio, (grossura, grossura, d.length), mat)
    o.rotation_euler = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_euler()
    base.aplicar_transformacoes(o)
    return o


def chama(nome, pos, altura, raio, mat, seed=0, inclina=(0, 0, 0)):
    random.seed(seed)
    perfil = [(0.0, 0.0), (raio * 0.8, altura * 0.12), (raio, altura * 0.3),
              (raio * 0.7, altura * 0.55), (raio * 0.3, altura * 0.8), (0.01, altura)]
    bm = bmesh.new()
    lados = 5
    aneis = []
    for r, z in perfil:
        aneis.append([bm.verts.new((r * math.cos(2 * math.pi * i / lados), r * math.sin(2 * math.pi * i / lados), z))
                      for i in range(lados)])
    for k in range(len(aneis) - 1):
        for i in range(lados):
            j = (i + 1) % lados
            bm.faces.new((aneis[k][i], aneis[k][j], aneis[k + 1][j], aneis[k + 1][i]))
    bm.faces.new(list(reversed(aneis[0])))
    bm.faces.new(aneis[-1])
    for v in bm.verts:
        t = v.co.z / altura
        x, y = v.co.x, v.co.y
        v.co.x = x * math.cos(t * 1.3) - y * math.sin(t * 1.3)
        v.co.y = x * math.sin(t * 1.3) + y * math.cos(t * 1.3)
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    o.location = pos
    o.rotation_euler = inclina
    base.aplicar(o, mat)
    base.chapado(o)
    return o


def pais(filhos, pai):
    bpy.context.view_layer.update()
    for f in filhos:
        mw = f.matrix_world.copy()
        f.parent = pai
        f.matrix_world = mw


def vazio(nome, loc=(0, 0, 0)):
    bpy.ops.object.empty_add(location=loc)
    return nomear(bpy.context.active_object, nome)


# ---------------------------------------------------------------- base
def montar_base():
    pecas = []
    # disco de lava escondido sob os blocos (aparece nas frestas)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=1.35, depth=0.06, location=(0, 0, 0.03))
    pecas.append(nomear(bpy.context.active_object, "BaseLava"))
    base.aplicar(pecas[-1], LAVA)
    # degrau de baixo: anel de blocos
    n = 14
    for i in range(n):
        a = 2 * math.pi * i / n
        r = 1.3
        alt = random.uniform(0.3, 0.38)
        b = caixa(f"BlocoBaixo{i}", (math.cos(a) * r, math.sin(a) * r, alt / 2), (0.62, 0.42, alt),
                  PEDRA_ESCURA if i % 3 else PEDRA, chanfro=0.03, rot=(0, 0, a + math.pi / 2))
        pecas.append(b)
    caixa("MioloBaixo", (0, 0, 0.16), (2.1, 2.1, 0.3), PEDRA_ESCURA)
    pecas.append(bpy.context.active_object)
    # degrau de cima
    n = 10
    for i in range(n):
        a = 2 * math.pi * i / n + 0.15
        r = 0.92
        alt = random.uniform(0.3, 0.34)
        b = caixa(f"BlocoCima{i}", (math.cos(a) * r, math.sin(a) * r, 0.33 + alt / 2), (0.62, 0.4, alt),
                  PEDRA if i % 2 else PEDRA_CLARA, chanfro=0.03, rot=(0, 0, a + math.pi / 2))
        pecas.append(b)
    pecas.append(caixa("MioloCima", (0, 0, 0.48), (1.5, 1.5, 0.3), PEDRA))
    # bloco da frente com runa
    pecas.append(caixa("BlocoRuna", (0, -1.0, 0.5), (0.62, 0.3, 0.36), PEDRA_CLARA, chanfro=0.03))
    pecas.append(losango("RunaBase", (0, -1.17, 0.5), 0.1, RUNA))
    pecas.append(caixa("BlocoRunaBaixo", (0, -1.48, 0.17), (0.7, 0.3, 0.34), PEDRA_CLARA, chanfro=0.03))
    pecas.append(losango("RunaBaseBaixo", (0, -1.645, 0.17), 0.09, RUNA))
    # entulho em volta
    for i in range(12):
        a = 2 * math.pi * i / 12 + random.uniform(-0.2, 0.2)
        r = random.uniform(1.55, 1.75)
        pecas.append(pedra(f"Entulho{i}", (math.cos(a) * r, math.sin(a) * r, 0.1),
                           random.uniform(0.12, 0.2), PEDRA_ESCURA, alto=0.9, seed=30 + i))
    return pecas


# ---------------------------------------------------------------- corpo da bigorna
def montar_corpo():
    pecas = []
    z_topo, z_laje = 1.86, 1.42
    # laje de cima com chifres pontudos dos dois lados
    meia = 0.5
    pts = []
    for y in (-meia, meia):
        pts += [(-0.95, y, z_topo), (0.95, y, z_topo), (-0.95, y, z_laje), (0.95, y, z_laje)]
    for s in (-1, 1):
        pts += [(s * 1.8, -0.1, 1.76), (s * 1.8, 0.1, 1.76), (s * 1.05, -0.4, 1.42), (s * 1.05, 0.4, 1.42),
                (s * 1.45, -0.28, 1.86), (s * 1.45, 0.28, 1.86)]
    pecas.append(casco("Laje", [Vector(p) for p in pts], PEDRA))
    # cintura e pes (afina e abre de novo, como uma bigorna)
    pts = []
    for y in (-0.44, 0.44):
        pts += [(-0.95, y, z_laje), (0.95, y, z_laje), (-0.7, y * 0.92, 1.0), (0.7, y * 0.92, 1.0)]
    pecas.append(casco("Cintura", [Vector(p) for p in pts], PEDRA))
    pts = []
    for y in (-0.5, 0.5):
        pts += [(-0.7, y * 0.81, 1.0), (0.7, y * 0.81, 1.0), (-1.05, y * 1.05, 0.62), (1.05, y * 1.05, 0.62)]
    pecas.append(casco("Pes", [Vector(p) for p in pts], PEDRA_ESCURA))
    # placa do rosto (frente) e placa de tras
    pecas.append(caixa("PlacaCostas", (0, 0.47, 1.4), (1.1, 0.12, 0.78), PEDRA, chanfro=0.04))
    # placas laterais de metal com runa '8'
    for s, nome in ((-1, "E"), (1, "D")):
        pecas.append(caixa(f"Placa{nome}", (s * 0.86, -0.02, 1.62), (0.2, 1.12, 0.6), PEDRA_CLARA, chanfro=0.03))
        pecas += runa_oito(f"RunaPlaca{nome}", (s * 0.86, -0.59, 1.62), 0.11, RUNA)
    # testa: sobrancelha de pedra com losango
    pecas.append(caixa("Testa", (0, -0.56, 1.77), (0.5, 0.16, 0.18), PEDRA_CLARA, chanfro=0.03))
    pecas.append(losango("RunaTesta", (0, -0.65, 1.77), 0.07, RUNA))
    # rachaduras com lava (detalhe)
    pecas.append(traco("Racha1", (-0.62, -0.43, 1.3), (-0.55, -0.42, 1.1), LAVA, 0.02))
    pecas.append(traco("Racha2", (0.6, -0.43, 1.25), (0.66, -0.42, 1.08), LAVA, 0.02))
    # lava escorrendo da boca ate a base, entre os pes
    pecas.append(casco("CascataLava", [Vector(v) for v in (
        (-0.32, -0.47, 0.98), (0.32, -0.47, 0.98), (-0.55, -0.6, 0.6), (0.55, -0.6, 0.6),
        (-0.32, -0.38, 0.98), (0.32, -0.38, 0.98), (-0.55, -0.48, 0.6), (0.55, -0.48, 0.6))], LAVA))
    # chamas saindo do topo, onde o martelo encontra a bigorna
    for i in range(14):
        a = 2 * math.pi * i / 14
        pecas.append(chama(f"ChamaTopo{i}", (math.cos(a) * 0.34, math.sin(a) * 0.34, z_topo - 0.02),
                           random.uniform(0.6, 1.2), 0.09, LAVA if i % 2 else LAVA_CLARA, seed=50 + i,
                           inclina=(math.sin(a) * 0.55, -math.cos(a) * 0.55, 0)))
    for i in range(6):
        a = 2 * math.pi * i / 6 + 0.3
        pecas.append(chama(f"Labareda{i}", (math.cos(a) * 0.3, math.sin(a) * 0.3, z_topo - 0.05),
                           random.uniform(0.7, 1.0), 0.15, LAVA_CLARA, seed=120 + i,
                           inclina=(math.sin(a) * 0.75, -math.cos(a) * 0.75, 0)))
    # chamas na boca/pes (frente)
    for i in range(8):
        x = -0.63 + i * 0.18
        pecas.append(chama(f"ChamaPe{i}", (x, -0.66, 0.6), random.uniform(0.25, 0.5), 0.08,
                           LAVA_CLARA if i % 2 else LAVA, seed=70 + i))
    return pecas


def placa_lava(nome, contorno, mat, yf, prof=0.05):
    """Peca chapada (convexa) desenhada por um contorno (x, z) na face da bigorna."""
    pts = []
    for x, z in contorno:
        pts += [Vector((x, yf, z)), Vector((x, yf + prof, z))]
    return casco(nome, pts, mat)


def dente(nome, x, z, larg, alt, mat, yf, para_baixo=True):
    sinal = -1 if para_baixo else 1
    return casco(nome, [Vector(v) for v in (
        (x - larg, yf - 0.035, z), (x + larg, yf - 0.035, z), (x, yf - 0.035, z + sinal * alt),
        (x - larg, yf + 0.03, z), (x + larg, yf + 0.03, z), (x, yf + 0.03, z + sinal * alt))], mat)


def rosto(tipo):
    """Olhos e boca de lava na placa do rosto. tipo: neutro | rindo | raiva."""
    p = []
    yf = -0.51
    if tipo == "neutro":
        # olhos firmes, levemente inclinados; boca media com dentes de cima e de baixo
        for s in (-1, 1):
            p.append(placa_lava(f"Olho{tipo}{s}", [(s * 0.1, 1.6), (s * 0.44, 1.64), (s * 0.42, 1.48), (s * 0.13, 1.47)],
                                LAVA_CLARA, yf, 0.04))
        yf = -0.46
        p.append(placa_lava(f"Boca{tipo}", [(-0.34, 1.34), (0.34, 1.34), (0.3, 1.04), (-0.3, 1.04)], BOCA_FUNDO, yf, 0.06))
        for k, x in enumerate((-0.22, -0.07, 0.07, 0.22)):
            p.append(dente(f"DenteCima{tipo}{k}", x, 1.35, 0.06, 0.12, PEDRA_CLARA, yf))
        for k, x in enumerate((-0.15, 0.0, 0.15)):
            p.append(dente(f"DenteBaixo{tipo}{k}", x, 1.03, 0.055, 0.1, PEDRA_CLARA, yf, para_baixo=False))
    elif tipo == "rindo":
        # olhos fechados em arco (felizes) e boca larga em U, de canto a canto
        for s in (-1, 1):
            cx = s * 0.27
            arco = [(cx - 0.17, 1.5), (cx - 0.1, 1.6), (cx, 1.64), (cx + 0.1, 1.6), (cx + 0.17, 1.5)]
            for k in range(4):
                p.append(traco(f"OlhoArco{tipo}{s}{k}", (arco[k][0], yf - 0.01, arco[k][1]),
                               (arco[k + 1][0], yf - 0.01, arco[k + 1][1]), LAVA_CLARA, 0.05))
        u = [(-0.48, 1.4), (0.48, 1.4)] + [(0.46 * math.cos(t), 1.36 - 0.36 * math.sin(t))
                                            for t in [math.radians(a) for a in range(15, 170, 15)]]
        yf = -0.46
        p.append(placa_lava(f"Boca{tipo}", u, BOCA_FUNDO, yf, 0.06))
        for k, x in enumerate((-0.3, 0.3)):
            p.append(dente(f"DenteCima{tipo}{k}", x, 1.41, 0.06, 0.1, PEDRA_CLARA, yf))
        p.append(placa_lava(f"Lingua{tipo}", [(-0.16, 1.06), (0.16, 1.06), (0.12, 1.15), (-0.12, 1.15)], LAVA_CLARA, yf - 0.02, 0.03))
    else:  # raiva
        # olhos bem inclinados para o centro, sobrancelhas de pedra, boca enorme cheia de dentes
        for s in (-1, 1):
            p.append(placa_lava(f"Olho{tipo}{s}", [(s * 0.08, 1.5), (s * 0.46, 1.68), (s * 0.44, 1.52), (s * 0.12, 1.43)],
                                LAVA_CLARA, yf, 0.04))
            p.append(casco(f"Sobrancelha{tipo}{s}", [Vector(v) for v in (
                (s * 0.04, yf - 0.06, 1.56), (s * 0.5, yf - 0.06, 1.76), (s * 0.5, yf - 0.06, 1.68), (s * 0.06, yf - 0.06, 1.5),
                (s * 0.04, yf + 0.02, 1.56), (s * 0.5, yf + 0.02, 1.76), (s * 0.5, yf + 0.02, 1.68), (s * 0.06, yf + 0.02, 1.5))],
                PEDRA_CLARA))
        yf = -0.46
        p.append(placa_lava(f"Boca{tipo}", [(-0.46, 1.36), (0.46, 1.36), (0.4, 0.9), (-0.4, 0.9)], BOCA_FUNDO, yf, 0.06))
        for k, x in enumerate((-0.33, -0.2, -0.07, 0.07, 0.2, 0.33)):
            p.append(dente(f"DenteCima{tipo}{k}", x, 1.37, 0.06, 0.18 if k % 2 else 0.12, PEDRA_CLARA, yf))
        for k, x in enumerate((-0.27, -0.09, 0.09, 0.27)):
            p.append(dente(f"DenteBaixo{tipo}{k}", x, 0.89, 0.06, 0.15, PEDRA_CLARA, yf, para_baixo=False))
        # pedrinhas pulando de raiva
        for k in range(8):
            a = 2 * math.pi * k / 8 + 0.3
            p.append(pedra(f"Estilhaco{tipo}{k}", (math.cos(a) * 1.15, -0.55, 1.4 + math.sin(a) * 0.65),
                           0.06, PEDRA, alto=1.3, seed=200 + k))
    # labaredas dentro da boca
    for k in range(3):
        p.append(chama(f"ChamaBoca{tipo}{k}", (-0.14 + k * 0.14, yf + 0.03, 1.05 if tipo != "raiva" else 0.95),
                       0.2, 0.06, LAVA_CLARA, seed=90 + k))
    return p


# ---------------------------------------------------------------- coluna-martelo
def montar_coluna():
    pecas = []
    w = 0.38
    # nucleo derretido na parte de baixo
    pecas.append(caixa("NucleoLava", (0, 0, 2.25), (w * 0.96, w * 0.96, 0.8), LAVA))
    for k, (z0, z1) in enumerate(((1.86, 1.96), (2.52, 2.6))):
        pecas.append(caixa(f"AnelBaixo{k}", (0, 0, (z0 + z1) / 2), (w * 1.08, w * 1.08, z1 - z0), PEDRA, chanfro=0.02))
    # fuste de pedra
    pecas.append(caixa("Fuste", (0, 0, 3.05), (w, w, 1.1), PEDRA, chanfro=0.03))
    for k, z in enumerate((2.62, 3.05, 3.48)):
        pecas.append(caixa(f"Junta{k}", (0, 0, z), (w * 1.06, w * 1.06, 0.05), PEDRA_ESCURA))
    # runas da coluna (frente e costas)
    for lado, y in (("F", -w / 2 - 0.012), ("C", w / 2 + 0.012)):
        pecas.append(traco(f"RunaColA{lado}", (-0.08, y, 2.78), (0.0, y, 2.95), RUNA, 0.026))
        pecas.append(traco(f"RunaColB{lado}", (0.0, y, 2.95), (0.08, y, 2.78), RUNA, 0.026))
        pecas.append(traco(f"RunaColC{lado}", (-0.06, y, 2.84), (0.06, y, 2.84), RUNA, 0.026))
        pecas += runa_oito(f"RunaCol8{lado}", (0, y, 3.22), 0.09, RUNA)
        pecas.append(losango(f"RunaColL{lado}", (0, y, 2.25), 0.07, LAVA_CLARA))
    # travessa de metal e bracos com cabecas de martelo
    pecas.append(caixa("Travessa", (0, 0, 3.72), (0.62, 0.48, 0.24), METAL, chanfro=0.03))
    for s, nome in ((-1, "E"), (1, "D")):
        pecas.append(caixa(f"Braco{nome}", (s * 0.6, 0, 3.72), (0.6, 0.16, 0.16), PEDRA, chanfro=0.02))
        pecas.append(caixa(f"Cabeca{nome}", (s * 0.98, 0, 3.72), (0.38, 0.38, 0.36), PEDRA_CLARA, chanfro=0.05))
        pecas.append(losango(f"RunaTrav{nome}", (s * 0.18, -0.25, 3.72), 0.06, RUNA))
    # topo
    pecas.append(caixa("Topo", (0, 0, 4.1), (w * 1.05, w * 1.05, 0.52), PEDRA, chanfro=0.03))
    pecas.append(caixa("Tampa", (0, 0, 4.39), (w * 1.18, w * 1.18, 0.08), PEDRA_CLARA, chanfro=0.02))
    pecas.append(losango("RunaTopoF", (0, -w * 0.53 - 0.012, 4.12), 0.085, RUNA))
    pecas.append(losango("RunaTopoC", (0, w * 0.53 + 0.012, 4.12), 0.085, RUNA))
    pecas.append(losango("RunaTampa", (0, 0, 4.44), 0.12, RUNA, plano="XY"))
    return pecas


def montar_anel():
    """Pedras flutuando em volta da coluna, ligadas por arcos de fogo."""
    pecas = []
    n, r, z = 8, 1.3, 2.95
    for i in range(n):
        a = 2 * math.pi * i / n + 0.2
        zz = z + math.sin(a) * 0.18  # anel levemente inclinado
        p = pedra(f"PedraOrbita{i}", (math.cos(a) * r, math.sin(a) * r, zz),
                  random.uniform(0.19, 0.25), PEDRA_CLARA if i % 2 else PEDRA, alto=1.7, seed=10 + i)
        p.rotation_euler = (random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), a)
        pecas.append(p)
    # arcos de fogo: anel fino emissivo ondulado
    bm = bmesh.new()
    seg, lados = 64, 4
    aneis = []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        c = Vector((math.cos(a) * r, math.sin(a) * r, z + math.sin(a) * 0.18 + math.sin(a * 8) * 0.05))
        tang = Vector((-math.sin(a), math.cos(a), 0))
        lado = tang.cross(Vector((0, 0, 1)))
        grossura = 0.016 + 0.022 * (0.5 + 0.5 * math.sin(a * 8 + 1.0))
        aneis.append([bm.verts.new(c + lado * math.cos(2 * math.pi * j / lados) * grossura
                                   + Vector((0, 0, 1)) * math.sin(2 * math.pi * j / lados) * grossura)
                      for j in range(lados)])
    for i in range(seg):
        a1, a2 = aneis[i], aneis[(i + 1) % seg]
        for j in range(lados):
            bm.faces.new((a1[j], a1[(j + 1) % lados], a2[(j + 1) % lados], a2[j]))
    me = bpy.data.meshes.new("ArcoFogo")
    bm.to_mesh(me)
    bm.free()
    arco = bpy.data.objects.new("ArcoFogo", me)
    bpy.context.collection.objects.link(arco)
    base.aplicar(arco, LAVA)
    pecas.append(arco)
    return pecas


# ---------------------------------------------------------------- animacoes
def animar(raiz_corpo, anel):
    cena = bpy.context.scene
    cena.render.fps = 24
    # Orbita: pedras dao uma volta em 8 s (192 quadros), loop perfeito
    anel.rotation_mode = "XYZ"
    anel.rotation_euler = (0, 0, 0)
    anel.keyframe_insert("rotation_euler", frame=1)
    anel.rotation_euler = (0, 0, 2 * math.pi)
    anel.keyframe_insert("rotation_euler", frame=193)
    for fc in anel.animation_data.action.fcurves if hasattr(anel.animation_data.action, "fcurves") else []:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    anel.animation_data.action.name = "Orbita"
    # Tremer: sacode 0,5 s e volta ao lugar
    random.seed(5)
    for f in range(1, 13):
        forca = (1 - (f - 1) / 12) * 0.05
        raiz_corpo.location = (random.uniform(-1, 1) * forca, random.uniform(-1, 1) * forca * 0.5, 0)
        raiz_corpo.rotation_euler = (0, random.uniform(-1, 1) * forca, 0)
        raiz_corpo.keyframe_insert("location", frame=f)
        raiz_corpo.keyframe_insert("rotation_euler", frame=f)
    raiz_corpo.location = (0, 0, 0)
    raiz_corpo.rotation_euler = (0, 0, 0)
    raiz_corpo.keyframe_insert("location", frame=13)
    raiz_corpo.keyframe_insert("rotation_euler", frame=13)
    raiz_corpo.animation_data.action.name = "Tremer"


def interpolacao_linear(obj):
    """Blender 5: as curvas ficam dentro de camadas/canais da action."""
    act = obj.animation_data.action
    curvas = []
    if hasattr(act, "fcurves"):
        try:
            curvas = list(act.fcurves)
        except Exception:
            curvas = []
    if not curvas and hasattr(act, "layers"):
        for camada in act.layers:
            for faixa in camada.strips:
                for cb in faixa.channelbags:
                    curvas += list(cb.fcurves)
    for fc in curvas:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"


# ---------------------------------------------------------------- montagem
def montar():
    raiz = vazio("BigornaViva")
    corpo = vazio("Corpo")  # tudo que treme junto
    anel_vazio = vazio("AnelPedras", (0, 0, 0))
    pecas_base = montar_base()
    pecas_corpo = montar_corpo() + montar_coluna()
    rostos = {}
    for t in ("neutro", "rindo", "raiva"):
        g = vazio(f"Rosto_{t}")
        pais(rosto(t), g)
        rostos[t] = g
    pais(montar_anel(), anel_vazio)
    pais(pecas_base, raiz)
    pais(pecas_corpo + list(rostos.values()) + [anel_vazio], corpo)
    corpo.parent = raiz
    animar(corpo, anel_vazio)
    interpolacao_linear(anel_vazio)
    todas = [o for o in bpy.data.objects if o.type == "MESH"]
    print("TRIANGULOS_BIGORNA_TOTAL", base.contar_triangulos(todas))
    for t, g in rostos.items():
        print(f"TRIANGULOS_ROSTO_{t}", base.contar_triangulos(list(g.children)))
    return raiz, corpo, anel_vazio, rostos


def mostrar_rosto(rostos, qual):
    for t, g in rostos.items():
        for o in g.children:
            o.hide_render = (t != qual)
            o.hide_set(t != qual)


def palco_cinza():
    cena = bpy.context.scene
    mundo = bpy.data.worlds.new("Cinza")
    cena.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = base.cor("#6e6e72")
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    rig = vazio("RigLuz")
    bpy.ops.object.light_add(type="SUN", location=(2, -4, 6))
    sol = bpy.context.active_object
    sol.parent = rig
    sol.data.energy = 3.4
    sol.data.angle = math.radians(20)
    sol.rotation_euler = (math.radians(40), 0, math.radians(25))
    bpy.ops.object.light_add(type="AREA", location=(-4, -3, 3))
    f = bpy.context.active_object
    f.data.energy = 300
    f.data.size = 5
    f.data.color = base.cor("#e6e0ff")[:3]
    f.rotation_euler = (math.radians(60), 0, math.radians(-55))
    f.parent = rig
    # luz da lava
    for loc, e in (((0, -0.9, 1.2), 60), ((0, 0, 2.2), 80), ((0, -0.9, 0.5), 30)):
        bpy.ops.object.light_add(type="POINT", location=loc)
        l = bpy.context.active_object
        l.data.energy = e
        l.data.color = base.cor("#ff8a2a")[:3]


def camera_em(nome, pos, alvo, lente=70, orto=None):
    bpy.ops.object.camera_add(location=pos)
    cam = nomear(bpy.context.active_object, nome)
    cam.data.lens = lente
    if orto:
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = orto
    cam.rotation_euler = (Vector(alvo) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


def principal():
    base.limpar_cena()
    criar_materiais()
    raiz, corpo, anel, rostos = montar()
    if MODO == "exportar":
        mostrar_rosto(rostos, "neutro")
        for g in rostos.values():
            for o in g.children:
                o.hide_set(False)
        base.exportar_glb(SAIDA + ".glb", [raiz], animacoes=True)
        return
    palco_cinza()
    bpy.context.scene.frame_set(13)
    vistas = {
        "frente": ((0, -9.6, 2.5), (0, 0, 2.2), 0),
        "lado": ((9.6, -1.0, 2.5), (0, 0, 2.2), 90),
        "costas": ((0, 9.6, 2.5), (0, 0, 2.2), 180),
        "cima": ((0, -0.5, 9.5), (0, 0, 1.0), 0),
    }
    rig = bpy.data.objects["RigLuz"]
    mostrar_rosto(rostos, "neutro")
    if MODO == "rapido":
        vistas = {"frente": vistas["frente"]}
    for nome, (pos, alvo, giro) in vistas.items():
        rig.rotation_euler = (0, 0, math.radians(giro))
        camera_em("Cam_" + nome, pos, alvo, lente=60)
        base.renderizar(f"{SAIDA}_{nome}.png", largura=640, altura=760, amostras=40)
    for t in (() if MODO == "rapido" else ("neutro", "rindo", "raiva")):
        mostrar_rosto(rostos, t)
        rig.rotation_euler = (0, 0, 0)
        camera_em("Cam_rosto_" + t, (0, -7.6, 1.7), (0, 0, 1.3), lente=70)
        base.renderizar(f"{SAIDA}_rosto_{t}.png", largura=760, altura=560, amostras=40)


principal()
