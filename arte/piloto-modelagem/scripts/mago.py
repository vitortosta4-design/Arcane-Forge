"""Mago chibi do Arcane Forge, modelado pela folha de referencia do Vitor.

~1 m de altura com o chapeu. Pecas rigidas presas aos ossos (padrao low poly).
Animacoes: Parado, Andar, Conjurar, ErguerCajado.

Uso: python mago.py -- SAIDA folha|rapido|exportar
Frente olha para -Y.
"""
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix, Euler

sys.path.insert(0, os.path.dirname(__file__))
import base  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else "/tmp/mago"
MODO = args[1] if len(args) > 1 else "folha"


def criar_materiais():
    global AZUL, AZUL_ESC, BEGE, COURO, COURO_ESC, ROSTO, OLHO, CRISTAL, CALCA, MADEIRA, CABELO, DOURADO
    AZUL = base.material("MantoAzul", "#2f45c8", rugosidade=0.8)
    AZUL_ESC = base.material("MantoAzulEscuro", "#1f2c86", rugosidade=0.85)
    BEGE = base.material("Acabamento", "#e2a05e", rugosidade=0.7)
    COURO = base.material("Couro", "#7a4a30", rugosidade=0.75)
    COURO_ESC = base.material("CouroEscuro", "#4f2e1d", rugosidade=0.8)
    ROSTO = base.material("RostoSombra", "#2a1c19", rugosidade=0.9)
    OLHO = base.material("Olho", "#000000", rugosidade=1.0, emissao="#ff9a26", forca=1.5)
    CRISTAL = base.material("Cristal", "#3fc4ff", rugosidade=0.2, emissao="#36b8ff", forca=2.4)
    CALCA = base.material("Calca", "#2b2448", rugosidade=0.85)
    MADEIRA = base.material("Madeira", "#6e4430", rugosidade=0.8)
    CABELO = base.material("Cabelo", "#5a3424", rugosidade=0.85)
    DOURADO = base.material("Fivela", "#d9a24f", rugosidade=0.4, metal=0.6)


# ---------------------------------------------------------------- utilitarios
def nomear(o, nome):
    o.name = nome
    if o.data:
        o.data.name = nome
    return o


def fim(o, mat):
    base.aplicar(o, mat)
    base.chapado(o)
    return o


def caixa(nome, centro, tam, mat, rot=(0, 0, 0), chanfro=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=centro, rotation=rot)
    o = nomear(bpy.context.active_object, nome)
    o.scale = tam
    base.aplicar_transformacoes(o)
    if chanfro:
        m = o.modifiers.new("chanfro", "BEVEL")
        m.width = chanfro
        m.segments = 1
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier="chanfro")
    return fim(o, mat)


def esfera(nome, centro, escala, mat, seg=10, aneis=7, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=aneis, radius=1, location=centro, rotation=rot)
    o = nomear(bpy.context.active_object, nome)
    o.scale = escala
    base.aplicar_transformacoes(o)
    return fim(o, mat)


def torno(nome, perfil, mat, lados=10, achatar=1.0, fechar=(True, True), centro=(0, 0, 0)):
    """Gira um perfil (raio, z) em volta de Z; achatar < 1 deixa mais fino na profundidade (Y)."""
    bm = bmesh.new()
    aneis = []
    for r, z in perfil:
        aneis.append([bm.verts.new((centro[0] + r * math.cos(2 * math.pi * i / lados),
                                    centro[1] + r * math.sin(2 * math.pi * i / lados) * achatar,
                                    centro[2] + z)) for i in range(lados)])
    for k in range(len(aneis) - 1):
        for i in range(lados):
            j = (i + 1) % lados
            bm.faces.new((aneis[k][i], aneis[k][j], aneis[k + 1][j], aneis[k + 1][i]))
    if fechar[0]:
        bm.faces.new(list(reversed(aneis[0])))
    if fechar[1]:
        bm.faces.new(aneis[-1])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return fim(o, mat)


def deformar(o, func):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        v.co = func(v.co.copy())
    bm.to_mesh(o.data)
    bm.free()


def tubo(nome, pontos, raio, mat, lados=6):
    """Tubo seguindo uma lista de pontos (cajado, alcas)."""
    bm = bmesh.new()
    aneis = []
    n = len(pontos)
    for i, p in enumerate(pontos):
        p = Vector(p)
        t = (Vector(pontos[min(i + 1, n - 1)]) - Vector(pontos[max(i - 1, 0)])).normalized()
        a = t.cross(Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))).normalized()
        b = t.cross(a).normalized()
        r = raio[i] if isinstance(raio, (list, tuple)) else raio
        aneis.append([bm.verts.new(p + (a * math.cos(2 * math.pi * j / lados) + b * math.sin(2 * math.pi * j / lados)) * r)
                      for j in range(lados)])
    for k in range(n - 1):
        for j in range(lados):
            jj = (j + 1) % lados
            bm.faces.new((aneis[k][j], aneis[k][jj], aneis[k + 1][jj], aneis[k + 1][j]))
    bm.faces.new(list(reversed(aneis[0])))
    bm.faces.new(aneis[-1])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
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


def cristal(nome, centro, alto, raio, mat):
    pts = [Vector((0, 0, alto * 0.55)), Vector((0, 0, -alto * 0.45))]
    for i in range(6):
        a = 2 * math.pi * i / 6
        r = raio * (1.0 if i % 2 else 0.8)
        pts.append(Vector((math.cos(a) * r, math.sin(a) * r, alto * (0.05 if i % 2 else -0.05))))
    o = casco(nome, pts, mat)
    o.location = centro
    return o


# ---------------------------------------------------------------- partes
def chapeu():
    p = []
    # aba larga, caindo nas pontas
    aba = torno("ChapeuAba", [(0.0, 0.0), (0.16, 0.0), (0.34, -0.035), (0.34, -0.055), (0.16, -0.025), (0.0, -0.025)],
                AZUL, lados=14)
    deformar(aba, lambda c: Vector((c.x, c.y, c.z - 0.025 * (c.x ** 2 + c.y ** 2) / 0.1 + 0.012 * math.sin(math.atan2(c.y, c.x) * 2))))
    aba.location = (0, 0, 0.665)
    p.append(aba)
    # copa conica com a ponta torta para o lado e para tras
    copa = torno("ChapeuCopa", [(0.175, 0.0), (0.16, 0.08), (0.12, 0.18), (0.08, 0.27), (0.045, 0.33), (0.015, 0.38)],
                 AZUL, lados=10)

    def entortar(c):
        t = max(0.0, c.z - 0.15) / 0.23
        c.x += 0.13 * t ** 2.2
        c.y += 0.04 * t ** 2
        c.z -= 0.05 * t ** 3
        return c
    deformar(copa, entortar)
    copa.location = (0, 0, 0.67)
    p.append(copa)
    # faixa bege com placas e losango dourado na frente
    faixa = torno("ChapeuFaixa", [(0.178, 0.0), (0.172, 0.06)], BEGE, lados=10, fechar=(False, False))
    m = faixa.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.012
    faixa.location = (0, 0, 0.675)
    p.append(faixa)
    p.append(casco("ChapeuLosango", [Vector(v) for v in ((0, -0.19, 0.72), (0.03, -0.19, 0.705), (0, -0.19, 0.685),
                                                          (-0.03, -0.19, 0.705), (0, -0.172, 0.705))], DOURADO))
    for k, a in enumerate((-0.9, 0.9, 2.2, -2.2)):
        p.append(caixa(f"ChapeuPlaca{k}", (math.sin(a) * 0.18, -math.cos(a) * 0.18, 0.705), (0.04, 0.012, 0.05),
                       COURO_ESC, rot=(0, 0, a)))
    return p


def cabeca():
    p = []
    p.append(esfera("Rosto", (0, -0.005, 0.565), (0.14, 0.13, 0.13), ROSTO, seg=10, aneis=7))
    for s in (-1, 1):
        p.append(esfera(f"Olho{s}", (s * 0.05, -0.128, 0.57), (0.027, 0.014, 0.045), OLHO, seg=8, aneis=6))
        # tufos de cabelo saindo por baixo do chapeu
        for k in range(2):
            p.append(casco(f"Cabelo{s}{k}", [Vector(v) for v in (
                (s * (0.1 + k * 0.02), -0.06 + k * 0.05, 0.62), (s * (0.13 + k * 0.02), -0.04 + k * 0.05, 0.6),
                (s * (0.135 + k * 0.015), -0.05 + k * 0.05, 0.53), (s * (0.115 + k * 0.02), -0.02 + k * 0.05, 0.6))], CABELO))
    # cachecol/capuz que cobre o queixo
    gola = torno("Cachecol", [(0.1, 0.0), (0.135, 0.02), (0.14, 0.06), (0.12, 0.09), (0.1, 0.095)], AZUL_ESC,
                 lados=10, fechar=(False, False))
    gola.location = (0, -0.005, 0.44)
    p.append(gola)
    p.append(casco("CachecolFrente", [Vector(v) for v in (
        (-0.11, -0.13, 0.51), (0.11, -0.13, 0.51), (-0.12, -0.12, 0.45), (0.12, -0.12, 0.45),
        (-0.09, -0.09, 0.515), (0.09, -0.09, 0.515), (0, -0.155, 0.48))], AZUL_ESC))
    return p


def corpo():
    p = []
    # tronco/manto: tronco de cone achatado
    manto = torno("Manto", [(0.12, 0.46), (0.145, 0.4), (0.165, 0.3), (0.19, 0.2), (0.215, 0.11), (0.22, 0.095)],
                  AZUL, lados=12, achatar=0.82)
    p.append(manto)
    # barra bege da saia
    barra = torno("MantoBarra", [(0.222, 0.09), (0.224, 0.12)], BEGE, lados=12, achatar=0.83, fechar=(False, False))
    m = barra.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.012
    p.append(barra)
    # abertura da frente com acabamento bege
    for s in (-1, 1):
        p.append(tubo(f"FrenteAcab{s}", [(s * 0.01, -0.152, 0.37), (s * 0.04, -0.165, 0.24), (s * 0.075, -0.182, 0.1)],
                      0.013, BEGE, lados=4))
    p.append(casco("FrenteFenda", [Vector(v) for v in ((-0.06, -0.183, 0.095), (0.06, -0.183, 0.095), (0, -0.168, 0.2),
                                                       (0, -0.16, 0.095))], AZUL_ESC))
    # triangulos bege perto da barra
    for k, a in enumerate((-2.2, -1.2, 1.2, 2.2, 0.0)):
        if abs(a) < 0.1:
            continue
        x, y = math.sin(a) * 0.215, -math.cos(a) * 0.215 * 0.83
        p.append(casco(f"MantoTri{k}", [Vector(v) for v in ((x - 0.02, y - 0.006, 0.13), (x + 0.02, y - 0.006, 0.13),
                                                           (x, y - 0.006, 0.16), (x, y + 0.01, 0.14))], BEGE))
    # capinha nos ombros com borda bege
    capa = torno("Capinha", [(0.115, 0.47), (0.16, 0.42), (0.19, 0.36), (0.19, 0.35)], AZUL, lados=12, achatar=0.85,
                 fechar=(False, False))
    m = capa.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.014
    p.append(capa)
    borda = torno("CapinhaBorda", [(0.193, 0.345), (0.193, 0.365)], BEGE, lados=12, achatar=0.86, fechar=(False, False))
    m = borda.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.01
    p.append(borda)
    # broche de losango no peito
    p.append(casco("Broche", [Vector(v) for v in ((0, -0.15, 0.43), (0.025, -0.15, 0.4), (0, -0.15, 0.37), (-0.025, -0.15, 0.4),
                                                  (0, -0.13, 0.4))], DOURADO))
    # alca cruzada do peito ao cinto
    p.append(tubo("Alca", [(-0.1, -0.15, 0.355), (-0.06, -0.158, 0.34), (0.04, -0.16, 0.3), (0.13, -0.13, 0.26)], 0.012, COURO_ESC, lados=4))
    # cinto, fivela e bolsas
    cinto = torno("Cinto", [(0.162, 0.27), (0.168, 0.3)], COURO, lados=12, achatar=0.82, fechar=(False, False))
    m = cinto.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.014
    p.append(cinto)
    p.append(caixa("Fivela", (0, -0.148, 0.285), (0.045, 0.012, 0.035), DOURADO, chanfro=0.004))
    for s in (-1, 1):
        p.append(caixa(f"Bolsa{s}", (s * 0.12, -0.115, 0.235), (0.075, 0.04, 0.07), COURO, chanfro=0.008))
        p.append(caixa(f"BolsaTampa{s}", (s * 0.12, -0.137, 0.26), (0.078, 0.012, 0.032), COURO_ESC))
        p.append(caixa(f"BolsaBotao{s}", (s * 0.12, -0.145, 0.245), (0.012, 0.008, 0.016), DOURADO))
    # pernas curtas e botas
    pernas = {}
    for s, nome in ((-1, "E"), (1, "D")):
        x = s * 0.065
        perna = torno(f"Perna{nome}", [(0.038, 0.05), (0.044, 0.15)], CALCA, lados=8, centro=(x, 0, 0))
        bota = casco(f"Bota{nome}", [Vector(v) for v in (
            (x - 0.052, -0.1, 0.0), (x + 0.052, -0.1, 0.0), (x - 0.052, 0.055, 0.0), (x + 0.052, 0.055, 0.0),
            (x - 0.046, -0.09, 0.045), (x + 0.046, -0.09, 0.045), (x - 0.052, 0.05, 0.085), (x + 0.052, 0.05, 0.085),
            (x - 0.046, -0.02, 0.085), (x + 0.046, -0.02, 0.085))], COURO)
        cano = torno(f"BotaCano{nome}", [(0.054, 0.07), (0.058, 0.1)], COURO_ESC, lados=8, centro=(x, 0, 0))
        pernas[nome] = [perna, bota, cano]
    return p, pernas


def braco(lado):
    """Manga larga com punho bege e luva de couro com dedos abertos. lado: -1 esquerda, 1 direita."""
    s = lado
    p_manga, p_mao = [], []
    # manga desce do ombro, levemente para fora (pose neutra da referencia)
    ombro = Vector((s * 0.15, -0.01, 0.42))
    punho = Vector((s * 0.29, -0.03, 0.3))
    eixo = punho - ombro
    manga = torno(f"Manga{s}", [(0.045, 0.0), (0.055, eixo.length * 0.6), (0.065, eixo.length)], AZUL, lados=8)
    manga.matrix_world = Matrix.Translation(ombro) @ Vector((0, 0, 1)).rotation_difference(eixo.normalized()).to_matrix().to_4x4()
    p_manga.append(manga)
    punho_o = torno(f"Punho{s}", [(0.068, 0.0), (0.068, 0.03)], BEGE, lados=8)
    punho_o.matrix_world = Matrix.Translation(ombro + eixo * 0.93) @ Vector((0, 0, 1)).rotation_difference(eixo.normalized()).to_matrix().to_4x4()
    p_manga.append(punho_o)
    # luva
    mao = punho + eixo.normalized() * 0.04
    p_mao.append(esfera(f"Palma{s}", mao, (0.05, 0.04, 0.052), COURO, seg=8, aneis=6))
    for k in range(3):
        abre = -1 + k
        d = Vector((s * (0.3 + abre * 0.38), -0.2, -1.0)).normalized()
        base_dedo = mao + d * 0.03
        p_mao.append(tubo(f"Dedo{s}{k}", [base_dedo, base_dedo + d * 0.03, base_dedo + d * 0.052],
                          [0.019, 0.017, 0.013], COURO, lados=5))
    polegar = mao + Vector((s * -0.02, -0.035, 0.0))
    p_mao.append(tubo(f"Polegar{s}", [polegar, polegar + Vector((s * -0.02, -0.03, -0.025))], [0.018, 0.013], COURO, lados=5))
    return p_manga, p_mao, ombro, mao


def cajado():
    """Cajado retorcido, comprimento ~0.95 m, com garras segurando um cristal."""
    random.seed(4)
    pts, raios = [], []
    for i in range(9):
        t = i / 8
        pts.append((math.sin(t * 9) * 0.008 + random.uniform(-0.004, 0.004), math.cos(t * 7) * 0.006, -0.4 + t * 0.85))
        raios.append(0.016 + 0.004 * math.sin(t * 13))
    p = [tubo("CajadoHaste", pts, raios, MADEIRA, lados=6)]
    for k, z in enumerate((0.05, 0.33)):
        p.append(torno(f"CajadoFaixa{k}", [(0.021, z), (0.021, z + 0.035)], BEGE, lados=6))
    topo = Vector(pts[-1])
    # garras
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.4
        d = Vector((math.cos(a), math.sin(a), 0))
        p.append(tubo(f"CajadoGarra{k}", [topo, topo + d * 0.03 + Vector((0, 0, 0.04)), topo + d * 0.035 + Vector((0, 0, 0.1)),
                                         topo + d * 0.012 + Vector((0, 0, 0.13))], [0.01, 0.009, 0.007, 0.004], MADEIRA, lados=4))
    p.append(cristal("CajadoCristal", topo + Vector((0, 0, 0.11)), 0.13, 0.035, CRISTAL))
    p.append(cristal("CajadoCristalBase", Vector((0.0, 0.0, -0.42)), 0.04, 0.012, CRISTAL))
    return p


# ---------------------------------------------------------------- esqueleto e poses
def prender(objs, arm, osso):
    bpy.context.view_layer.update()
    for o in objs:
        mw = o.matrix_world.copy()
        o.parent = arm
        o.parent_type = "BONE"
        o.parent_bone = osso
        o.matrix_world = mw


def montar():
    p_chapeu = chapeu()
    p_cabeca = cabeca()
    # chibi: cabeca e chapeu maiores, crescendo a partir do pescoco
    bpy.context.view_layer.update()
    pescoco = Vector((0, 0, 0.45))
    escala = Matrix.Translation(pescoco) @ Matrix.Scale(1.2, 4) @ Matrix.Translation(-pescoco)
    for o in p_chapeu + p_cabeca:
        o.matrix_world = escala @ o.matrix_world
    p_corpo, pernas = corpo()
    braco_e = braco(-1)
    braco_d = braco(1)
    p_cajado = cajado()
    # cajado na mao direita, em pe ao lado do corpo
    mao_d = braco_d[3]
    bpy.context.view_layer.update()
    for o in p_cajado:
        o.matrix_world = Matrix.Translation(mao_d + Vector((0.0, -0.02, 0.0))) @ Matrix.Rotation(math.radians(6), 4, "Y") @ o.matrix_world

    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = nomear(bpy.context.active_object, "MagoEsqueleto")
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    raiz = eb[0]
    raiz.name = "Raiz"
    raiz.head, raiz.tail = (0, 0, 0), (0, 0, 0.08)

    def osso(nome, h, t, pai):
        b = eb.new(nome)
        b.head, b.tail = h, t
        b.parent = eb[pai]
        b.roll = 0
        return b
    osso("Quadril", (0, 0, 0.14), (0, 0, 0.26), "Raiz")
    osso("Tronco", (0, 0, 0.26), (0, 0, 0.42), "Quadril")
    osso("Cabeca", (0, 0, 0.44), (0, 0, 0.62), "Tronco")
    for nome, (pm, pmao) in (("E", (braco_e[2], braco_e[3])), ("D", (braco_d[2], braco_d[3]))):
        osso(f"Braco{nome}", tuple(pm), (pm.x, pm.y, pm.z - 0.13), "Tronco")
        osso(f"Mao{nome}", (pm.x, pm.y, pm.z - 0.13), (pm.x, pm.y, pm.z - 0.2), f"Braco{nome}")
    for nome, x in (("E", -0.065), ("D", 0.065)):
        osso(f"Perna{nome}", (x, 0, 0.16), (x, 0, 0.02), "Quadril")
    bpy.ops.object.mode_set(mode="OBJECT")

    prender(p_corpo, arm, "Quadril")
    prender(p_cabeca + p_chapeu, arm, "Cabeca")
    prender(braco_e[0], arm, "BracoE")
    prender(braco_e[1], arm, "MaoE")
    prender(braco_d[0], arm, "BracoD")
    prender(braco_d[1] + p_cajado, arm, "MaoD")
    prender(pernas["E"], arm, "PernaE")
    prender(pernas["D"], arm, "PernaD")
    todas = [o for o in bpy.data.objects if o.type == "MESH"]
    print("TRIANGULOS_MAGO", base.contar_triangulos(todas))
    return arm


def pose(arm, **rot):
    """rot: osso=(x, y, z) em graus; loc_<osso>=(x, y, z) em metros."""
    for b in arm.pose.bones:
        b.rotation_mode = "XYZ"
        b.rotation_euler = (0, 0, 0)
        b.location = (0, 0, 0)
    for k, v in rot.items():
        if k.startswith("loc_"):
            arm.pose.bones[k[4:]].location = v
        else:
            arm.pose.bones[k].rotation_euler = tuple(math.radians(a) for a in v)


POSES = {
    "neutra": {},
    # braco esquerdo para frente com a mao aberta; corpo inclinado
    "conjurando": {"BracoE": (-80, 0, 25), "MaoE": (-10, 0, 0), "BracoD": (-20, 0, 0), "Tronco": (8, 0, 10),
                   "Cabeca": (-5, 0, -8), "PernaE": (-15, 0, 0), "PernaD": (15, 0, 0)},
    # braco direito para cima com o cajado
    "erguendo": {"BracoD": (-10, 0, -150), "MaoD": (0, 0, 135), "BracoE": (-20, 0, 20), "Tronco": (-6, 0, 0),
                 "Cabeca": (-8, 0, 0), "PernaE": (0, 0, -8), "PernaD": (0, 0, 8)},
    "andando": {"PernaE": (-40, 0, 0), "PernaD": (35, 0, 0), "BracoE": (40, 0, 0), "BracoD": (-30, 0, 0),
                "Tronco": (10, 0, -6), "Cabeca": (-6, 0, 4), "loc_Raiz": (0, 0, 0.02)},
}


def animar(arm):
    cena = bpy.context.scene
    cena.render.fps = 24
    if not arm.animation_data:
        arm.animation_data_create()
    acoes = {}

    def gravar(nome, quadros):
        act = bpy.data.actions.new(nome)
        arm.animation_data.action = act
        for f, kw in quadros:
            pose(arm, **kw)
            for b in arm.pose.bones:
                b.keyframe_insert("rotation_euler", frame=f)
                b.keyframe_insert("location", frame=f)
        trilha = arm.animation_data.nla_tracks.new()
        trilha.name = nome
        trilha.strips.new(nome, 1, act)
        arm.animation_data.action = None
        acoes[nome] = act

    gravar("Parado", [(1, {}), (25, {"Tronco": (3, 0, 0), "Cabeca": (-4, 0, 0), "BracoE": (0, 0, -5), "BracoD": (0, 0, 5),
                                    "loc_Raiz": (0, 0, -0.006)}), (49, {})])
    lado_a = POSES["andando"]
    lado_b = {"PernaE": (30, 0, 0), "PernaD": (-30, 0, 0), "BracoE": (-25, 0, 0), "BracoD": (30, 0, 0),
              "Tronco": (6, 0, 0), "loc_Raiz": (0, 0, 0.015)}
    meio = {"Tronco": (6, 0, 0), "loc_Raiz": (0, 0, 0.0)}
    gravar("Andar", [(1, lado_a), (7, meio), (13, lado_b), (19, meio), (25, lado_a)])
    gravar("Conjurar", [(1, {}), (6, POSES["conjurando"]), (14, POSES["conjurando"]), (20, {})])
    gravar("ErguerCajado", [(1, {}), (7, POSES["erguendo"]), (15, POSES["erguendo"]), (22, {})])
    return acoes


# ---------------------------------------------------------------- render
def palco():
    cena = bpy.context.scene
    mundo = bpy.data.worlds.new("Cinza")
    cena.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = base.cor("#6e6e72")
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    bpy.ops.object.empty_add(location=(0, 0, 0))
    rig = nomear(bpy.context.active_object, "RigLuz")
    bpy.ops.object.light_add(type="SUN", location=(2, -4, 6))
    sol = bpy.context.active_object
    sol.data.energy = 3.4
    sol.data.angle = math.radians(20)
    sol.rotation_euler = (math.radians(45), 0, math.radians(25))
    sol.parent = rig
    bpy.ops.object.light_add(type="AREA", location=(-1.5, -1.5, 1.2))
    f = bpy.context.active_object
    f.data.energy = 40
    f.data.size = 2
    f.data.color = base.cor("#e6e0ff")[:3]
    f.rotation_euler = (math.radians(60), 0, math.radians(-45))
    f.parent = rig
    bpy.ops.object.light_add(type="AREA", location=(0.5, 1.5, 1.3))
    c = bpy.context.active_object
    c.data.energy = 25
    c.data.size = 1.5
    c.rotation_euler = (math.radians(-60), 0, math.radians(15))
    c.parent = rig
    return rig


def camera_em(pos, alvo, lente=60):
    bpy.ops.object.camera_add(location=pos)
    cam = bpy.context.active_object
    cam.data.lens = lente
    cam.rotation_euler = (Vector(alvo) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


def principal():
    base.limpar_cena()
    criar_materiais()
    arm = montar()
    animar(arm)
    if MODO == "exportar":
        pose(arm)
        base.exportar_glb(SAIDA + ".glb", [arm], animacoes=True)
        return
    for t in arm.animation_data.nla_tracks:
        t.mute = True
    rig = palco()
    alvo = (0, 0, 0.52)
    vistas = [("frente", (0, -2.8, 0.75), 0), ("lado", (2.8, 0, 0.75), 90), ("costas", (0, 2.8, 0.75), 180)]
    if MODO == "rapido":
        vistas = vistas[:1]
    cajado_objs = [o for o in bpy.data.objects if o.name.startswith("Cajado")]

    def mostrar_cajado(v):
        for o in cajado_objs:
            o.hide_render = not v
    mostrar_cajado(False)
    for nome, pos, giro in vistas:
        pose(arm)
        rig.rotation_euler = (0, 0, math.radians(giro))
        camera_em(pos, alvo)
        base.renderizar(f"{SAIDA}_{nome}.png", largura=560, altura=640, amostras=40)
    if MODO == "rapido":
        return
    mostrar_cajado(True)
    for nome in ("conjurando", "erguendo", "andando"):
        pose(arm, **POSES[nome])
        rig.rotation_euler = (0, 0, math.radians(-30))
        camera_em((1.35, -2.5, 0.85), (0, 0, 0.55))
        base.renderizar(f"{SAIDA}_{nome}.png", largura=560, altura=640, amostras=40)


principal()
