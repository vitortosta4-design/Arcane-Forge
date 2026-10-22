"""Bigorna viva, versao 2: refeita a partir da analise lado a lado com a folha do Vitor.

Medidas tiradas da referencia (grade): pontas dos chifres a 3,8 unidades,
topo da laje em z = 2,16, base ate z = 0,42, coluna com 0,6 de largura e topo
em z = 5,45, anel de pedras com raio 1,75 inclinado ~17 graus.

O rosto e uma PLACA de pedra encaixada num nicho do corpo. Olhos e boca sao
furos tracados da referencia (tracos/bigorna/rostos.json) que atravessam a
placa e mostram o fundo de lava do nicho, com luz de verdade la dentro. Cada
expressao e uma placa (Rosto_neutro, Rosto_rindo, Rosto_raiva): o jogo liga uma.

Uso: python bigorna2.py -- SAIDA folha|rapido|exportar
"""
import json
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(__file__))
import base  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else "/tmp/bigorna2"
MODO = args[1] if len(args) > 1 else "folha"
AQUI = os.path.dirname(os.path.abspath(__file__))
ROSTOS = json.load(open(os.path.join(AQUI, "..", "tracos", "bigorna", "rostos.json")))

Z_LAJE = 2.16
Z_BASE = 0.42
FRENTE = -0.8         # face da frente do corpo (y)
SOBE = 0.38           # a base da referencia e mais alta: o corpo inteiro sobe isso
ESTICA = 1.17         # a cintura da referencia e mais alta que a medida inicial
DELTA = (Z_LAJE - Z_BASE) * (ESTICA - 1)


def criar_materiais():
    global PEDRA, PEDRA_ESC, PEDRA_CLARA, PEDRA_BORDA, METAL, LAVA, LAVA_CLARA, LAVA_FUNDO, RUNA, BRASA
    global NUCLEO, LAVA_ESCURA
    LAVA_ESCURA = base.material("LavaEscura", "#1a0503", rugosidade=1.0, emissao="#7a1508", forca=1.4)
    NUCLEO = base.material("NucleoLava", "#000000", rugosidade=1.0, emissao="#ff8410", forca=2.6)
    PEDRA = base.material("Pedra", "#4a4858", rugosidade=0.85)
    PEDRA_ESC = base.material("PedraEscura", "#2c2b36", rugosidade=0.9)
    PEDRA_CLARA = base.material("PedraClara", "#5d5a6c", rugosidade=0.85)
    PEDRA_BORDA = base.material("PedraBorda", "#6a5d66", rugosidade=0.7)
    METAL = base.material("MetalTravessa", "#8c8a72", rugosidade=0.5, metal=0.4)
    LAVA = base.material("Lava", "#000000", rugosidade=1.0, emissao="#ff4a00", forca=2.4)
    LAVA_CLARA = base.material("LavaClara", "#000000", rugosidade=1.0, emissao="#ffa010", forca=1.8)
    LAVA_FUNDO = base.material("LavaFundo", "#000000", rugosidade=1.0, emissao="#ff6a08", forca=2.3)
    RUNA = base.material("Runa", "#000000", rugosidade=1.0, emissao="#ff4210", forca=3.0)
    BRASA = base.material("Brasa", "#000000", rugosidade=1.0, emissao="#ffc840", forca=2.6)


# ---------------------------------------------------------------- utilitarios
def nomear(o, nome):
    o.name = nome
    if o.data:
        o.data.name = nome
    return o


def chanfrar(o, largura, segmentos=1):
    m = o.modifiers.new("chanfro", "BEVEL")
    m.width = largura
    m.segments = segmentos
    m.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier="chanfro")


def lascar(o, forca=0.02, chance=0.35, seed=0):
    """Empurra alguns vertices para dar cara de pedra lascada."""
    r = random.Random(seed)
    for v in o.data.vertices:
        if r.random() < chance:
            v.co.x += r.uniform(-forca, forca)
            v.co.y += r.uniform(-forca, forca)
            v.co.z += r.uniform(-forca, forca)


def fim(o, mat):
    if mat is not None:
        o.data.materials.clear()
        o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = False
    return o


def caixa(nome, centro, tam, mat, chanfro=0.0, rot=(0, 0, 0), lascas=0.0, seed=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    o = nomear(bpy.context.active_object, nome)
    o.scale = tam
    base.aplicar_transformacoes(o)
    if chanfro:
        chanfrar(o, chanfro)
    if lascas:
        lascar(o, lascas, seed=seed)
    o.location = centro
    o.rotation_euler = rot
    return fim(o, mat)


def casco(nome, pontos, mat):
    bm = bmesh.new()
    for p in pontos:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts[:])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return fim(o, mat)


def prisma(nome, contorno_xz, y0, y1, mat):
    """Extruda um contorno (x, z) entre y0 e y1."""
    bm = bmesh.new()
    vs = [bm.verts.new((x, y0, z)) for x, z in contorno_xz]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.y = y1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return fim(o, mat)


def booleana(alvo, cortadores, op="DIFFERENCE"):
    bpy.context.view_layer.objects.active = alvo
    for c in cortadores:
        m = alvo.modifiers.new("b", "BOOLEAN")
        m.operation = op
        m.solver = "EXACT"
        m.object = c
        m.use_self = True
        m.material_mode = "TRANSFER"
        bpy.ops.object.modifier_apply(modifier="b")
    for c in cortadores:
        bpy.data.objects.remove(c)


def losango(nome, centro, tam, mat, plano="XZ", esp=0.024):
    bpy.ops.mesh.primitive_torus_add(major_radius=tam, minor_radius=esp, major_segments=4, minor_segments=4,
                                     location=(0, 0, 0))
    o = nomear(bpy.context.active_object, nome)
    if plano == "XZ":
        o.rotation_euler = (math.radians(90), 0, 0)
    elif plano == "YZ":
        o.rotation_euler = (math.radians(90), 0, math.radians(90))
    base.aplicar_transformacoes(o)
    o.location = centro
    return fim(o, mat)


def runa_oito(prefixo, centro, tam, mat, plano="XZ"):
    return [losango(prefixo + "A", (centro[0], centro[1], centro[2] + tam * 0.75), tam * 0.55, mat, plano, 0.022),
            losango(prefixo + "B", (centro[0], centro[1], centro[2] - tam * 0.75), tam * 0.55, mat, plano, 0.022)]


def traco(nome, p1, p2, mat, grossura=0.035):
    p1, p2 = Vector(p1), Vector(p2)
    d = p2 - p1
    o = caixa(nome, (p1 + p2) / 2, (grossura, grossura, d.length), mat)
    o.rotation_euler = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_euler()
    return o


def chama(nome, pos, altura, raio, mat, seed=0, inclina=(0, 0, 0), lados=5):
    r = random.Random(seed)
    perfil = [(0.0, 0.0), (raio * 0.85, altura * 0.1), (raio, altura * 0.28), (raio * 0.72, altura * 0.52),
              (raio * 0.32, altura * 0.78), (0.0, altura)]
    bm = bmesh.new()
    aneis = []
    for rr, z in perfil:
        aneis.append([bm.verts.new((rr * math.cos(2 * math.pi * i / lados), rr * math.sin(2 * math.pi * i / lados), z))
                      for i in range(lados)])
    for k in range(len(aneis) - 1):
        for i in range(lados):
            j = (i + 1) % lados
            bm.faces.new((aneis[k][i], aneis[k][j], aneis[k + 1][j], aneis[k + 1][i]))
    bm.faces.new(list(reversed(aneis[0])))
    giro = r.uniform(0.9, 1.7)
    for v in bm.verts:
        t = v.co.z / altura
        x, y = v.co.x, v.co.y
        v.co.x = x * math.cos(t * giro) - y * math.sin(t * giro) + math.sin(t * 3 + seed) * raio * 0.5 * t
        v.co.y = x * math.sin(t * giro) + y * math.cos(t * giro)
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    o.location = pos
    o.rotation_euler = inclina
    return fim(o, mat)


def pedra_pontuda(nome, centro, alto, larg, mat, seed=0):
    """Pedra facetada em losango comprido (as pedras do anel)."""
    r = random.Random(seed)
    pts = [Vector((r.uniform(-0.03, 0.03), r.uniform(-0.03, 0.03), alto * 0.5)),
           Vector((r.uniform(-0.03, 0.03), r.uniform(-0.03, 0.03), -alto * 0.55))]
    for i in range(6):
        a = 2 * math.pi * i / 6 + r.uniform(-0.25, 0.25)
        rr = larg * r.uniform(0.7, 1.0)
        zz = r.uniform(-0.05, 0.12) * alto
        pts.append(Vector((math.cos(a) * rr, math.sin(a) * rr, zz)))
    for i in range(3):
        a = 2 * math.pi * i / 3 + 0.5
        pts.append(Vector((math.cos(a) * larg * 0.6, math.sin(a) * larg * 0.6, alto * 0.3)))
    o = casco(nome, pts, mat)
    o.location = centro
    return o


def pedrisco(nome, centro, raio, mat, seed=0, achatar=0.7):
    r = random.Random(seed)
    pts = []
    for i in range(10):
        a = 2 * math.pi * i / 10 + r.uniform(-0.2, 0.2)
        for z in (-0.5, 0.5):
            rr = raio * r.uniform(0.7, 1.05)
            pts.append(Vector((math.cos(a) * rr, math.sin(a) * rr, z * raio * achatar * r.uniform(0.8, 1.2))))
    o = casco(nome, pts, mat)
    o.location = centro
    o.rotation_euler = (r.uniform(-0.4, 0.4), r.uniform(-0.4, 0.4), r.uniform(0, 3))
    return o


def esticar(objs):
    """Estica na vertical a partir do topo da base (malha recebe a transformacao)."""
    bpy.context.view_layer.update()
    for o in objs:
        if o.type == "MESH":
            o.data.transform(o.matrix_world)
            o.matrix_world = Matrix.Identity(4)
            for v in o.data.vertices:
                v.co.z = Z_BASE + (v.co.z - Z_BASE) * ESTICA
        else:
            o.location.z = Z_BASE + (o.location.z - Z_BASE) * ESTICA


def vazio(nome, loc=(0, 0, 0)):
    bpy.ops.object.empty_add(location=loc)
    return nomear(bpy.context.active_object, nome)


def pais(filhos, pai):
    bpy.context.view_layer.update()
    for f in filhos:
        mw = f.matrix_world.copy()
        f.parent = pai
        f.matrix_world = mw


def luz(nome, loc, energia, cor, raio=0.05):
    bpy.ops.object.light_add(type="POINT", location=loc)
    l = nomear(bpy.context.active_object, nome)
    l.data.energy = energia
    l.data.color = base.cor(cor)[:3]
    l.data.shadow_soft_size = raio
    return l


# ---------------------------------------------------------------- base
def dente(nome, x, y, z, larg, alto, mat, seed=0):
    """Pedra pontuda em pe (os 'dentes' da base que aparecem contra o fogo da boca)."""
    r = random.Random(seed)
    pts = [Vector((r.uniform(-0.04, 0.04), r.uniform(-0.04, 0.04), alto))]
    for i in range(5):
        a = 2 * math.pi * i / 5 + r.uniform(-0.3, 0.3)
        pts.append(Vector((math.cos(a) * larg * r.uniform(0.8, 1.1), math.sin(a) * larg * 0.7, 0)))
        pts.append(Vector((math.cos(a) * larg * 0.6, math.sin(a) * larg * 0.45, alto * r.uniform(0.35, 0.55))))
    o = casco(nome, pts, mat)
    o.location = (x, y, z)
    o.rotation_euler = (r.uniform(-0.15, 0.15), r.uniform(-0.2, 0.2), r.uniform(0, 3))
    return o


def montar_base():
    r = random.Random(3)
    p = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=1.9, depth=0.05, location=(0, 0, 0.03))
    p.append(fim(nomear(bpy.context.active_object, "BaseLava"), LAVA))
    n = 18
    for i in range(n):
        a = 2 * math.pi * i / n + r.uniform(-0.03, 0.03)
        alt = r.uniform(0.38, 0.46)
        p.append(caixa(f"BlocoBaixo{i}", (math.cos(a) * 1.98, math.sin(a) * 1.8, alt / 2),
                       (r.uniform(0.66, 0.76), 0.56, alt), PEDRA_ESC if i % 3 else PEDRA, chanfro=0.04,
                       rot=(0, 0, a + math.pi / 2), lascas=0.018, seed=i))
    p.append(caixa("MioloBaixo", (0, 0, 0.2), (3.6, 3.3, 0.38), PEDRA_ESC))
    n = 14
    for i in range(n):
        a = 2 * math.pi * i / n + 0.11
        alt = r.uniform(0.4, 0.46)
        p.append(caixa(f"BlocoCima{i}", (math.cos(a) * 1.32, math.sin(a) * 1.2, 0.36 + alt / 2),
                       (r.uniform(0.6, 0.7), 0.56, alt), PEDRA if i % 2 else PEDRA_CLARA, chanfro=0.04,
                       rot=(0, 0, a + math.pi / 2), lascas=0.018, seed=40 + i))
    p.append(caixa("MioloCima", (0, 0, 0.58), (2.7, 2.4, 0.44), PEDRA))
    # bloco da frente com a runa em losango
    p.append(caixa("BlocoRuna", (0, -1.78, 0.44), (0.95, 0.42, 0.88), PEDRA_CLARA, chanfro=0.045, lascas=0.012, seed=7))
    p.append(losango("RunaBase", (0, -2.0, 0.46), 0.15, RUNA))
    # dentes de pedra na frente da boca e em volta
    for k in range(13):
        a = math.radians(205 + k * 130 / 12) + r.uniform(-0.05, 0.05)
        rr = r.uniform(0.98, 1.08)
        p.append(dente(f"Dente{k}", math.cos(a) * rr, math.sin(a) * rr * 0.95, 0.78, r.uniform(0.17, 0.24),
                       r.uniform(0.34, 0.52), PEDRA if k % 2 else PEDRA_CLARA, seed=600 + k))
    for k in range(9):
        a = math.radians(-15 + k * 210 / 8)
        p.append(dente(f"DenteCostas{k}", math.cos(a) * 1.08, math.sin(a) * 1.0, 0.78, r.uniform(0.13, 0.18),
                       r.uniform(0.22, 0.36), PEDRA_ESC if k % 2 else PEDRA, seed=650 + k))
    # entulho em cima dos degraus, encostado no corpo
    for i in range(18):
        a = (math.radians(r.choice((200, 225, 315, 340))) + r.uniform(-0.25, 0.25)) if i < 10 else 2 * math.pi * i / 8
        rr = r.uniform(1.1, 1.45)
        p.append(pedrisco(f"Entulho{i}", (math.cos(a) * rr, math.sin(a) * rr * 0.9, 0.86), r.uniform(0.13, 0.24),
                          PEDRA_ESC if i % 2 else PEDRA_CLARA, seed=100 + i))
    return p


# ---------------------------------------------------------------- corpo
PERFIL_D = [(0.9, Z_LAJE), (1.4, 2.14), (1.9, 2.07), (2.3, 1.95), (2.12, 1.8), (1.62, 1.62),
            (1.15, 1.45), (0.92, 1.28), (0.8, 1.02), (0.84, 0.72), (1.02, Z_BASE)]
SILHUETA_ROSTO = [(-0.78, Z_LAJE), (0.78, Z_LAJE), (0.78, 1.32), (0.68, 1.02), (0.72, 0.72), (0.84, Z_BASE),
                  (-0.84, Z_BASE), (-0.72, 0.72), (-0.68, 1.02), (-0.78, 1.32)]


def montar_corpo():
    p = []
    contorno = [(-x, z) for x, z in reversed(PERFIL_D)] + PERFIL_D
    corpo = prisma("Corpo", contorno, FRENTE, -FRENTE, PEDRA)
    for v in corpo.data.vertices:
        ax = abs(v.co.x)
        if ax > 0.95:
            t = min(1.0, (ax - 0.95) / 1.33)
            v.co.y *= 1.0 - 0.6 * t
            if v.co.z > 2.0:
                v.co.z -= 0.08 * t
    chanfrar(corpo, 0.05)
    nicho = caixa("Nicho", (0, FRENTE + 0.13, (Z_BASE + 1.98) / 2), (1.5, 0.52, 1.98 - Z_BASE + 0.04), None)
    nicho.location.z -= 0.02
    booleana(corpo, [nicho])
    lascar(corpo, 0.012, 0.25, seed=5)
    p.append(corpo)
    # fundo de lava e fogo dentro da garganta
    p.append(caixa("LavaNicho", (0, FRENTE + 0.37, (Z_BASE + 1.98) / 2), (1.48, 0.04, 1.56), LAVA_FUNDO))
    p.append(caixa("BrilhoOlhos", (0, FRENTE + 0.3, 1.62), (1.3, 0.03, 0.42), LAVA_CLARA))
    p.append(caixa("BrilhoGarganta", (0, FRENTE + 0.33, 0.78), (1.4, 0.03, 0.75), LAVA_CLARA))
    r = random.Random(31)
    for k in range(20):
        x = -0.62 + 1.24 * k / 19 + r.uniform(-0.03, 0.03)
        alto = r.uniform(0.4, 0.75) * (1.0 - 0.3 * abs(x))
        p.append(chama(f"FogoGarganta{k}", (x, FRENTE + r.uniform(0.12, 0.3), Z_BASE - 0.02), alto,
                       r.uniform(0.11, 0.16), LAVA_CLARA if k % 3 else LAVA, seed=700 + k))
    # testa pesada com o losango
    p.append(caixa("Testa", (0, FRENTE - 0.2, 1.9), (0.6, 0.3, 0.38), PEDRA_CLARA, chanfro=0.05, lascas=0.015, seed=9))
    p.append(losango("RunaTesta", (0, FRENTE - 0.355, 1.9), 0.12, RUNA))
    p.append(losango("RunaTestaMiolo", (0, FRENTE - 0.355, 1.9), 0.055, RUNA, esp=0.018))
    # placas laterais com a runa "8"
    for s, nome in ((-1, "E"), (1, "D")):
        p.append(caixa(f"Placa{nome}", (s * 0.95, 0.0, 1.76), (0.27, -2 * FRENTE + 0.36, 0.82), PEDRA_CLARA, chanfro=0.05,
                       lascas=0.015, seed=11 + s))
        p += runa_oito(f"RunaPlaca{nome}", (s * 0.95, FRENTE - 0.185, 1.76), 0.13, RUNA)
        p += runa_oito(f"RunaPlacaC{nome}", (s * 0.95, -FRENTE + 0.185, 1.76), 0.13, RUNA)
        # runa tambem na face de fora da placa (aparece na vista de lado)
        p += runa_oito(f"RunaPlacaL{nome}", (s * 1.088, 0.0, 1.76), 0.15, RUNA, plano="YZ")
        # fenda acesa embaixo do chifre (o "olho" do chifre)
        def yh(x):
            return FRENTE * (1 - 0.6 * min(1.0, (abs(x) - 0.95) / 1.33))
        p.append(casco(f"Fenda{nome}", [Vector(v) for v in (
            (s * 1.14, yh(1.14) - 0.01, 1.6), (s * 1.55, yh(1.55) - 0.01, 1.68), (s * 1.3, yh(1.3) - 0.01, 1.5),
            (s * 1.14, yh(1.14) + 0.06, 1.6), (s * 1.55, yh(1.55) + 0.06, 1.68), (s * 1.3, yh(1.3) + 0.06, 1.5))], LAVA_CLARA))
    for k, (a, b) in enumerate((((-1.5, FRENTE * 0.62, 2.0), (-1.25, FRENTE * 0.7, 1.98)),
                                ((1.3, FRENTE * 0.68, 1.99), (1.6, FRENTE * 0.6, 1.95)))):
        p.append(traco(f"Racha{k}", a, b, LAVA, 0.022))
    # labaredas subindo pelos lados da cintura
    for k in range(6):
        lado = -1 if k % 2 else 1
        x = lado * r.uniform(0.75, 0.95)
        p.append(chama(f"LabaredaPe{k}", (x, r.uniform(FRENTE + 0.3, FRENTE + 0.7), Z_BASE - 0.02), r.uniform(0.3, 0.55),
                       r.uniform(0.09, 0.15), LAVA_CLARA if k % 3 == 0 else LAVA, seed=300 + k,
                       inclina=(r.uniform(-0.2, 0.1), lado * r.uniform(0.05, 0.3), 0)))
    # costas: parede de blocos com uma boca de fogo embaixo (como na vista de costas)
    nicho_c = caixa("NichoCostas", (0, -FRENTE - 0.1, 0.7), (1.2, 0.5, 0.6), None)
    booleana(corpo, [nicho_c])
    costas = blocos("PlacaCostas", +1, seed=29)
    abertura = [(-0.55, 0.3), (0.55, 0.3), (0.5, 0.74), (0.34, 0.6), (0.18, 0.8), (0.0, 0.64),
                (-0.18, 0.82), (-0.34, 0.6), (-0.5, 0.76)]
    booleana(costas, [prisma("CorteCostas", abertura, -FRENTE - 0.5, -FRENTE + 0.5, None)])
    p.append(costas)
    p.append(caixa("LavaCostas", (0, -FRENTE - 0.33, 0.66), (1.18, 0.04, 0.55), LAVA_CLARA))
    for k in range(8):
        x = -0.48 + 0.96 * k / 7
        p.append(chama(f"FogoCostas{k}", (x, -FRENTE - 0.15, Z_BASE - 0.02), r.uniform(0.3, 0.55), 0.1,
                       LAVA if k % 2 else LAVA_CLARA, seed=900 + k))
    return p


def afastar(pts, d):
    """Engorda um contorno em d (offset simples pela bissetriz)."""
    area = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts)))
    sinal = 1 if area > 0 else -1
    novos = []
    n = len(pts)
    for i in range(n):
        p0, p1, p2 = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % n])
        e1, e2 = (p1 - p0), (p2 - p1)
        if e1.length < 1e-6 or e2.length < 1e-6:
            novos.append(tuple(p1))
            continue
        n1 = Vector((e1.y, -e1.x)).normalized() * sinal
        n2 = Vector((e2.y, -e2.x)).normalized() * sinal
        m = n1 + n2
        if m.length < 1e-4:
            m = n1
        m.normalize()
        k = d / max(0.4, m.dot(n1))
        novos.append(tuple(p1 + m * k))
    return novos


# Bocas desenhadas a mao sobre a grade da referencia (pixels do recorte de cada expressao).
# No rindo e na raiva o interior da boca e vermelho-escuro e o traco por cor nao separa ele
# da pedra iluminada; entao a abertura e os dentes de baixo foram medidos na grade ampliada.
ANCORAS = {"neutro": (150, 330, 40, 245), "rindo": (130, 315, 40, 240), "raiva": (165, 355, 35, 245)}
BOCAS = {
    "rindo": {
        "abertura": [(172, 116), (190, 113), (195, 113), (201, 131), (208, 113), (245, 112), (250, 112), (255, 125),
                     (260, 112), (274, 113), (281, 130), (288, 114), (297, 117), (293, 132), (287, 150), (283, 160),
                     (286, 175), (287, 200), (296, 218), (302, 240), (176, 240), (180, 218), (182, 200), (183, 175),
                     (185, 160), (181, 148), (176, 130)],
        "escuro_ate": 162,
        "dentes": [(200, 168, 158), (228, 166, 159), (256, 168, 158), (276, 166, 159)],
    },
    "raiva": {
        "abertura": [(200, 150), (205, 150), (210, 168), (217, 150), (228, 150), (233, 166), (240, 150), (250, 150),
                     (253, 163), (258, 150), (268, 150), (273, 165), (280, 150), (292, 150), (300, 167), (306, 150),
                     (315, 150), (318, 163), (322, 152), (325, 165), (327, 185), (330, 200), (334, 215), (340, 245),
                     (184, 245), (188, 215), (193, 200), (197, 185), (199, 165)],
        "escuro_ate": 192,
        "dentes": [(225, 197, 181), (246, 197, 182), (268, 197, 180), (289, 197, 182), (308, 197, 181)],
    },
}


def px_para_modelo(tipo, px, py):
    x0, x1, yt, yb = ANCORAS[tipo]
    xc = (x0 + x1) / 2
    return ((px - xc) * 2 * 0.76 / (x1 - x0), Z_BASE + (yb - py) * (2.15 - Z_BASE) / (yb - yt))


def pecas_rosto(tipo):
    """Contornos a cortar: olhos tracados (+ boca tracada no neutro) ou boca desenhada a mao."""
    out = []
    for pc in ROSTOS[tipo]["pecas"]:
        pts = pc["pts"]
        if pc["buraco"] or len(pts) < 3:
            continue
        xs = [p[0] for p in pts]
        cz = sum(p[1] for p in pts) / len(pts)
        if max(xs) - min(xs) < 0.07:
            continue          # brilho solto na beira (nao e olho)
        if tipo in BOCAS:
            topo_boca = max(px_para_modelo(tipo, *p)[1] for p in BOCAS[tipo]["abertura"])
            if cz < topo_boca + 0.05:
                continue      # boca vem do desenho manual
        if tipo == "rindo":
            pts = afastar(pts, 0.025)   # os arcos dos olhos rindo sao mais grossos na referencia
        out.append(pts)
    if tipo in BOCAS:
        out.append([px_para_modelo(tipo, *p) for p in BOCAS[tipo]["abertura"]])
    return out


def casca_convexa(pts):
    pts = sorted(set((round(x, 4), round(z, 4)) for x, z in pts))
    def cruz(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    baixo, cima = [], []
    for p in pts:
        while len(baixo) >= 2 and cruz(baixo[-2], baixo[-1], p) <= 0:
            baixo.pop()
        baixo.append(p)
    for p in reversed(pts):
        while len(cima) >= 2 and cruz(cima[-2], cima[-1], p) <= 0:
            cima.pop()
        cima.append(p)
    return baixo[:-1] + cima[:-1]


def aros(tipo):
    """Sobrancelha pesada (metade de cima de cada olho), saltada para fora: da o volume
    esculpido do rosto da referencia. No rosto rindo os olhos ja sao arcos: sem sobrancelha."""
    pcs = []
    if tipo == "rindo":
        return pcs
    for idx, pts in enumerate(pecas_rosto(tipo)):
        cz = sum(p[1] for p in pts) / len(pts)
        if cz < 1.3:
            continue
        casca = casca_convexa(pts)
        aro = prisma(f"Aro_{tipo}_{idx}", afastar(casca, 0.12), FRENTE - 0.3, FRENTE - 0.05, PEDRA_CLARA)
        miolo = prisma(f"AroMiolo_{tipo}_{idx}", afastar(pts, 0.012), FRENTE - 0.8, FRENTE + 0.3, None)
        baixo = caixa(f"AroBaixo_{tipo}_{idx}", (0, FRENTE, cz - 2.0), (6.0, 2.0, 4.0), None)
        booleana(aro, [miolo, baixo])
        if len(aro.data.vertices) == 0:
            bpy.data.objects.remove(aro)
            continue
        chanfrar(aro, 0.018)
        lascar(aro, 0.008, 0.3, seed=idx)
        pcs.append(aro)
    return pcs


def blocos(nome, sentido, seed=13):
    """Parede de blocos de pedra (rosto na frente, costas atras). sentido -1 = frente, +1 = costas."""
    r = random.Random(seed)
    xs = [-0.95, -0.5, 0.0, 0.5, 0.95]
    zs = [0.36, 0.78, 1.2, 1.6, 2.25]
    grade = {}
    for i, x in enumerate(xs):
        for j, z in enumerate(zs):
            borda_x = i in (0, len(xs) - 1)
            borda_z = j in (0, len(zs) - 1)
            grade[i, j] = (x + (0 if borda_x else r.uniform(-0.1, 0.1)), z + (0 if borda_z else r.uniform(-0.09, 0.09)))
    lista = []
    face = FRENTE if sentido < 0 else -FRENTE
    for i in range(len(xs) - 1):
        for j in range(len(zs) - 1):
            q = [Vector(grade[i, j]), Vector(grade[i + 1, j]), Vector(grade[i + 1, j + 1]), Vector(grade[i, j + 1])]
            c = sum(q, Vector((0, 0))) / 4
            q = [v + (c - v).normalized() * 0.03 for v in q]
            sai = 0.15 + r.uniform(0.0, 0.09)
            b = prisma(f"{nome}_{i}{j}", [tuple(v) for v in q], face + sentido * sai, face - sentido * 0.02, PEDRA)
            chanfrar(b, 0.028)
            lascar(b, 0.012, 0.4, seed=i * 7 + j + seed)
            lista.append(b)
    pl = base.juntar(lista, nome)
    fim(pl, PEDRA)
    sil = prisma(f"Sil_{nome}", SILHUETA_ROSTO, face - 0.5, face + 0.5, PEDRA)
    booleana(pl, [sil], op="INTERSECT")
    return pl


def placa_rosto(tipo):
    """Rosto montado em blocos de pedra (mesmo desenho nas 3 expressoes), com olhos e boca
    furados pelo traco da referencia, deixando ver o fogo do nicho."""
    pl = blocos(f"Placa_{tipo}", -1)
    fundo = prisma(f"FundoPlaca_{tipo}", SILHUETA_ROSTO, FRENTE - 0.06, FRENTE + 0.04, PEDRA_ESC)

    def cortadores():
        cs = []
        for pts in pecas_rosto(tipo):
            cs.append(prisma(f"Corte_{tipo}_{len(cs)}", afastar(pts, 0.015), FRENTE - 0.5, FRENTE + 0.3, LAVA))
        return cs
    booleana(pl, cortadores())
    booleana(fundo, cortadores())
    pecas = [pl, fundo] + aros(tipo)
    if tipo in BOCAS:
        b = BOCAS[tipo]
        # interior escuro da boca (em cima) e dentes de baixo, de pedra
        esc = prisma(f"BocaEscura_{tipo}", [px_para_modelo(tipo, *p) for p in b["abertura"]],
                     FRENTE + 0.02, FRENTE + 0.06, LAVA_ESCURA)
        zcorte = px_para_modelo(tipo, 0, b["escuro_ate"])[1]
        baixo = caixa(f"BocaEscuraCorte_{tipo}", (0, FRENTE, zcorte - 2.0), (6.0, 2.0, 4.0), None)
        booleana(esc, [baixo])
        pecas.append(esc)
        for k, (xc, yb_, yp) in enumerate(b["dentes"]):
            tri = [px_para_modelo(tipo, xc - 8, yb_ + 3), px_para_modelo(tipo, xc + 8, yb_ + 3), px_para_modelo(tipo, xc, yp)]
            d = prisma(f"DenteBoca_{tipo}{k}", tri, FRENTE - 0.14, FRENTE + 0.05, PEDRA_CLARA)
            chanfrar(d, 0.012)
            pecas.append(d)
    if tipo == "raiva":
        r = random.Random(77)
        for k in range(10):
            a = 2 * math.pi * k / 10 + 0.2
            pecas.append(pedrisco(f"Estilhaco_{tipo}{k}", (math.cos(a) * 2.0, FRENTE - 0.3 + r.uniform(-0.2, 0.2),
                                                         1.3 + math.sin(a) * 0.9), r.uniform(0.07, 0.13),
                                  PEDRA_CLARA, seed=500 + k, achatar=0.9))
        for k in range(14):
            a = r.uniform(0, 2 * math.pi)
            c = Vector((math.cos(a) * r.uniform(1.0, 2.1), FRENTE - 0.3, 1.3 + math.sin(a) * r.uniform(0.5, 1.0)))
            pecas.append(casco(f"Fagulha_{tipo}{k}", [c + Vector(v) for v in (
                (0, 0, 0.03), (0.015, 0, -0.01), (-0.015, 0, -0.01), (0, 0.015, 0))], BRASA))
    return pecas



# ---------------------------------------------------------------- coluna-martelo
# faces da coluna: nome, normal (x, y), direcao "direita" de quem olha, plano da runa
FACES = (("F", (0, -1), (1, 0), "XZ"), ("C", (0, 1), (-1, 0), "XZ"),
         ("E", (-1, 0), (0, -1), "YZ"), ("D", (1, 0), (0, 1), "YZ"))


def montar_coluna():
    p = []
    w = 0.6
    z0 = Z_LAJE
    p.append(caixa("Nucleo", (0, 0, z0 + 0.73), (w * 0.86, w * 0.86, 1.46), NUCLEO))
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.append(caixa(f"Quina{sx}{sy}", (sx * w * 0.42, sy * w * 0.42, z0 + 0.73), (0.12, 0.12, 1.46),
                           PEDRA_ESC, chanfro=0.02, lascas=0.01, seed=sx * 3 + sy))
    for k, z in enumerate((z0 + 0.05, z0 + 1.48)):
        p.append(caixa(f"Cinta{k}", (0, 0, z), (w * 1.12, w * 1.12, 0.12), PEDRA, chanfro=0.03, lascas=0.01, seed=k))
    for lado, d, h, pl in FACES:
        p.append(losango(f"RunaNucleo{lado}", (d[0] * w * 0.44, d[1] * w * 0.44, z0 + 0.78), 0.13, BRASA, plano=pl))
    zf0, zf1 = z0 + 1.54, z0 + 2.5
    p.append(caixa("Fuste", (0, 0, (zf0 + zf1) / 2), (w, w, zf1 - zf0), PEDRA, chanfro=0.04, lascas=0.012, seed=31))
    for k, z in enumerate((zf0 + 0.48,)):
        p.append(caixa(f"Junta{k}", (0, 0, z), (w * 1.04, w * 1.04, 0.035), PEDRA_ESC))
    for lado, d, h, pl in FACES:
        zA = zf0 + 0.72
        o = Vector((d[0], d[1], 0)) * (w / 2 + 0.012)
        hv = Vector((h[0], h[1], 0))
        for k, (a, b) in enumerate((((-0.08, -0.17), (-0.08, 0.17)), ((-0.08, 0.17), (0.08, 0.12)),
                                    ((0.08, 0.12), (0.08, 0.03)), ((0.08, 0.03), (-0.08, 0.0)),
                                    ((-0.03, 0.0), (0.1, -0.17)))):
            p.append(traco(f"RunaR{k}{lado}", o + hv * a[0] + Vector((0, 0, zA + a[1])),
                           o + hv * b[0] + Vector((0, 0, zA + b[1])), RUNA, 0.028))
        p += runa_oito(f"RunaFuste8{lado}", tuple(o + Vector((0, 0, zf0 + 0.24))), 0.14, RUNA, plano=pl)
    zt = zf1 + 0.2
    p.append(caixa("Travessa", (0, 0, zt), (w * 1.24, w * 1.24, 0.4), METAL, chanfro=0.04, lascas=0.008, seed=41))
    for i in range(4):
        for sx in (-1, 1):
            p.append(caixa(f"Rebite{i}{sx}", (sx * 0.31, -w * 0.62 - 0.01, zt - 0.12 + i * 0.08), (0.04, 0.03, 0.04), PEDRA_ESC))
    for lado, d, h, pl in FACES[:2]:
        p.append(losango(f"RunaTrav{lado}", (0, d[1] * (w * 0.62 + 0.005), zt), 0.09, RUNA))
    for s, nome in ((-1, "E"), (1, "D")):
        p.append(caixa(f"Braco{nome}", (s * 0.72, 0, zt), (0.78, 0.24, 0.24), PEDRA, chanfro=0.03, lascas=0.01, seed=s))
        p.append(caixa(f"Cabeca{nome}", (s * 1.4, 0, zt), (0.72, 0.7, 0.68), PEDRA, chanfro=0.13,
                       lascas=0.035, seed=50 + s))
    zc0 = zt + 0.2
    p.append(caixa("Topo", (0, 0, zc0 + 0.4), (w * 1.02, w * 1.02, 0.8), PEDRA, chanfro=0.04, lascas=0.012, seed=61))
    p.append(caixa("Tampa", (0, 0, zc0 + 0.85), (w * 1.12, w * 1.12, 0.12), PEDRA_CLARA, chanfro=0.03))
    for lado, d, h, pl in FACES:
        p.append(losango(f"RunaTopo{lado}", (d[0] * w * 0.52, d[1] * w * 0.52, zc0 + 0.42), 0.13, RUNA, plano=pl))
    r = random.Random(17)
    for k in range(22):
        a = 2 * math.pi * k / 22 + r.uniform(-0.12, 0.12)
        d = r.uniform(0.3, 0.6)
        p.append(chama(f"Labareda{k}", (math.cos(a) * d, math.sin(a) * d * 0.9, Z_LAJE - 0.04),
                       r.uniform(0.5, 1.2), r.uniform(0.11, 0.19), LAVA_CLARA if k % 4 == 0 else LAVA,
                       seed=400 + k, inclina=(math.sin(a) * r.uniform(0.3, 0.75), -math.cos(a) * r.uniform(0.3, 0.75), 0)))
    return p


def pedra_orbita(nome, alto, larg, mat, seed=0):
    """Pedra grossa e facetada, com a ponta para baixo (as pedras do anel na referencia)."""
    r = random.Random(seed)
    pts = [Vector((r.uniform(-0.05, 0.05), r.uniform(-0.05, 0.05), -alto * 0.5))]
    for i in range(4):
        a = 2 * math.pi * i / 4 + r.uniform(-0.3, 0.3)
        pts.append(Vector((math.cos(a) * larg * 0.5, math.sin(a) * larg * 0.45, -alto * 0.32)))
    for i in range(6):
        a = 2 * math.pi * i / 6 + r.uniform(-0.25, 0.25)
        pts.append(Vector((math.cos(a) * larg * r.uniform(0.85, 1.05), math.sin(a) * larg * r.uniform(0.75, 0.95),
                           r.uniform(-0.05, 0.08) * alto)))
    for i in range(5):
        a = 2 * math.pi * i / 5 + r.uniform(-0.3, 0.3)
        pts.append(Vector((math.cos(a) * larg * 0.75, math.sin(a) * larg * 0.65, alto * r.uniform(0.3, 0.42))))
    return casco(nome, pts, mat)


def fita(nome, a0, a1, raio, grossura, mat, fase=0.0, dz=0.0, cauda=False):
    """Lingua de fogo seguindo o anel entre a0 e a1, grossa no meio e fina nas pontas."""
    bm = bmesh.new()
    seg, lados = 18, 5
    aneis = []
    for i in range(seg + 1):
        t = i / seg
        a = a0 + (a1 - a0) * t
        c = Vector((math.cos(a) * raio, math.sin(a) * raio, dz + 0.09 * math.sin(t * math.pi * 2 + fase) * (1 - t if cauda else 1)))
        tang = Vector((-math.sin(a), math.cos(a), 0))
        lado = tang.cross(Vector((0, 0, 1)))
        g = (grossura * t ** 1.3 if cauda else grossura * math.sin(math.pi * t) ** 0.8) + 0.002
        aneis.append([bm.verts.new(c + lado * math.cos(2 * math.pi * j / lados) * g * 0.6
                                   + Vector((0, 0, 1)) * math.sin(2 * math.pi * j / lados) * g * 1.3) for j in range(lados)])
    for i in range(seg):
        for j in range(lados):
            bm.faces.new((aneis[i][j], aneis[i][(j + 1) % lados], aneis[i + 1][(j + 1) % lados], aneis[i + 1][j]))
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return fim(o, mat)


def montar_anel():
    p = []
    r = random.Random(23)
    n, raio = 8, 2.15
    angs = [2 * math.pi * i / n + 0.15 for i in range(n)]
    for i, a in enumerate(angs):
        pd = pedra_orbita(f"PedraOrbita{i}", r.uniform(0.7, 0.82), r.uniform(0.32, 0.37),
                          PEDRA_CLARA if i % 2 else PEDRA, seed=30 + i)
        pd.location = (math.cos(a) * raio, math.sin(a) * raio, r.uniform(-0.06, 0.06))
        pd.rotation_euler = (r.uniform(-0.2, 0.2), r.uniform(-0.2, 0.2), a)
        p.append(pd)
    passo = 2 * math.pi / n
    for i, a in enumerate(angs):
        # cauda de cometa: fina longe da pedra, grossa encostada nela (o anel gira no sentido +z)
        p.append(fita(f"FitaFogo{i}", a - passo * 0.85, a - 0.06, raio, r.uniform(0.09, 0.11), LAVA,
                      fase=r.uniform(0, 6), cauda=True))
        p.append(fita(f"FitaMiolo{i}", a - passo * 0.5, a - 0.08, raio * 1.005, 0.05, LAVA_CLARA,
                      fase=r.uniform(0, 6), dz=0.01, cauda=True))

    for k in range(34):
        a = r.uniform(0, 2 * math.pi)
        c = Vector((math.cos(a) * raio * r.uniform(0.92, 1.08), math.sin(a) * raio * r.uniform(0.92, 1.08), r.uniform(-0.2, 0.3)))
        t = r.uniform(0.012, 0.025)
        p.append(casco(f"Fagulha{k}", [c + Vector(v) for v in ((0, 0, t * 1.6), (t, 0, -t), (-t, t, -t), (-t, -t, -t))],
                       BRASA if k % 2 else LAVA))
    return p


# ---------------------------------------------------------------- animacao e montagem
def animar(corpo, giro):
    cena = bpy.context.scene
    cena.render.fps = 24
    giro.rotation_mode = "XYZ"
    giro.rotation_euler = (0, 0, 0)
    giro.keyframe_insert("rotation_euler", frame=1)
    giro.rotation_euler = (0, 0, 2 * math.pi)
    giro.keyframe_insert("rotation_euler", frame=241)
    giro.animation_data.action.name = "Orbita"
    r = random.Random(5)
    for f in range(1, 13):
        k = (1 - (f - 1) / 12) * 0.05
        corpo.location = (r.uniform(-1, 1) * k, r.uniform(-1, 1) * k * 0.5, 0)
        corpo.rotation_euler = (0, r.uniform(-1, 1) * k, 0)
        corpo.keyframe_insert("location", frame=f)
        corpo.keyframe_insert("rotation_euler", frame=f)
    corpo.location = (0, 0, 0)
    corpo.rotation_euler = (0, 0, 0)
    corpo.keyframe_insert("location", frame=13)
    corpo.keyframe_insert("rotation_euler", frame=13)
    corpo.animation_data.action.name = "Tremer"


def montar():
    raiz = vazio("BigornaViva")
    corpo_v = vazio("Corpo")
    inclina = vazio("AnelInclinado", (0, 0, Z_LAJE + 1.4 + DELTA))
    inclina.rotation_euler = (math.radians(-30), 0, 0)
    giro = vazio("AnelPedras", (0, 0, Z_LAJE + 1.4 + DELTA))
    p_base = montar_base()
    p_cint = montar_corpo()
    esticar(p_cint)
    p_col = montar_coluna()
    for o in p_col:
        o.location.z += DELTA
    p_corpo = p_cint + p_col
    rostos = {}
    for t in ("neutro", "rindo", "raiva"):
        g = vazio(f"Rosto_{t}")
        pecas = placa_rosto(t)
        esticar(pecas)
        pais(pecas, g)
        rostos[t] = g
    anel = montar_anel()
    for o in anel:
        o.location += Vector((0, 0, Z_LAJE + 1.4 + DELTA))
    pais(anel, giro)
    pais([giro], inclina)
    # luzes proprias: boca, olhos, nucleo e fendas
    luzes = [luz("LuzBoca", (0, FRENTE + 0.05, 0.9), 120, "#ff7a1a", 0.2),
             luz("LuzOlhos", (0, FRENTE + 0.1, 1.82), 60, "#ffa030", 0.15),
             luz("LuzNucleo", (0, -0.5, Z_LAJE + 0.6 + DELTA), 160, "#ff7020", 0.2),
             luz("LuzBase", (0, -1.0, 0.45), 50, "#ff6010", 0.3)]
    pais(p_base, raiz)
    for o in p_corpo + list(rostos.values()) + [inclina] + luzes:
        if o.parent is None:
            o.location.z += SOBE
    pais(p_corpo + list(rostos.values()) + [inclina] + luzes, corpo_v)
    corpo_v.parent = raiz
    animar(corpo_v, giro)
    todas = [o for o in bpy.data.objects if o.type == "MESH"]
    print("TRIANGULOS_BIGORNA2", base.contar_triangulos(todas))
    return raiz, corpo_v, rostos


def mostrar_rosto(rostos, qual):
    for t, g in rostos.items():
        for o in g.children_recursive:
            o.hide_render = (t != qual)
            o.hide_set(t != qual)


def palco():
    cena = bpy.context.scene
    mundo = bpy.data.worlds.new("Cinza")
    cena.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = base.cor("#6c6c70")
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45
    rig = vazio("RigLuz")
    bpy.ops.object.light_add(type="SUN", location=(2, -4, 6))
    sol = bpy.context.active_object
    sol.data.energy = 4.2
    sol.data.angle = math.radians(15)
    sol.data.color = base.cor("#fff1e2")[:3]
    sol.rotation_euler = (math.radians(42), 0, math.radians(30))
    sol.parent = rig
    bpy.ops.object.light_add(type="AREA", location=(-5, -4, 4))
    f = bpy.context.active_object
    f.data.energy = 240
    f.data.size = 6
    f.data.color = base.cor("#d8d2ec")[:3]
    f.rotation_euler = (Vector((0, 0, 2)) - f.location).to_track_quat("-Z", "Y").to_euler()
    f.parent = rig
    cena.render.film_transparent = True
    base.ativar_brilho(forca=0.5, limiar=1.0, tamanho=0.6)
    return rig


def camera_em(pos, alvo, lente=60):
    bpy.ops.object.camera_add(location=pos)
    cam = bpy.context.active_object
    cam.data.lens = lente
    cam.rotation_euler = (Vector(alvo) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam


def principal():
    base.limpar_cena()
    criar_materiais()
    raiz, corpo, rostos = montar()
    if MODO == "exportar":
        mostrar_rosto(rostos, "neutro")
        for g in rostos.values():
            for o in g.children_recursive:
                o.hide_set(False)
        base.exportar_glb(SAIDA + ".glb", [raiz], animacoes=True, luzes=True)
        return
    rig = palco()
    bpy.context.scene.frame_set(13)
    vistas = {"frente": ((0, -14, 5.1), (0, 0, 3.15), 0), "lado": ((-12.1, -7.0, 5.1), (0, 0, 3.15), -60),
              "costas": ((0, 14, 5.1), (0, 0, 3.15), 180), "cima": ((0, -6.0, 24.0), (0, 0, 2.6), 0)}
    if MODO == "rapido":
        vistas = {"frente": vistas["frente"]}
    mostrar_rosto(rostos, "neutro")
    for nome, (pos, alvo, g) in vistas.items():
        rig.rotation_euler = (0, 0, math.radians(g))
        camera_em(pos, alvo, lente=110 if nome == "cima" else 60)
        base.renderizar(f"{SAIDA}_{nome}.png", largura=640, altura=800, amostras=40, transparente=True)
    tipos = ("neutro",) if MODO == "rapido" else ("neutro", "rindo", "raiva")
    for t in tipos:
        mostrar_rosto(rostos, t)
        rig.rotation_euler = (0, 0, 0)
        camera_em((0, -11.5, 2.9), (0, 0, 1.55), lente=70)
        base.renderizar(f"{SAIDA}_rosto_{t}.png", largura=760, altura=520, amostras=40, transparente=True)


principal()
