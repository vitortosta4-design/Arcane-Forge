"""Runas de quebra-cabeca da forja (Arcane Forge), pela folha de referencia do Vitor.

Cada runa: placa de pedra com encaixe de verdade (dente na direita e em cima,
fenda na esquerda e embaixo) e um simbolo entalhado. Duas versoes de material:
apagada (simbolo escuro) e acesa (simbolo brilhando e pedra tingida na cor do
elemento). O dente da direita de uma runa entra na fenda da esquerda da proxima.

Uso: python runas.py -- SAIDA folha|exportar
A runa fica em pe, no plano XZ, olhando para -Y. Lado da peca: TAM metros.
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
SAIDA = args[0] if args else "/tmp/runas"
MODO = args[1] if len(args) > 1 else "folha"

TAM = 0.3          # lado da peca (sem os dentes)
ESP = 0.1          # espessura

# nome: (cor do brilho, tom da pedra acesa)
ELEMENTOS = {
    "fogo": ("#ff5a00", "#8a5648"),
    "agua": ("#1f86ff", "#4a5fa6"),
    "vida": ("#5cff2a", "#5b7552"),
    "feroz": ("#ff2a2a", "#8a4842"),
    "gravitacao": ("#a63cff", "#6449a3"),
    "prende": ("#ffb000", "#94744a"),
    "arremesso": ("#2aa2ff", "#4a67ae"),
    "quebrar": ("#d84aff", "#7a4a9e"),
}

# contorno da peca em unidades (lado 1), sentido anti-horario
CONTORNO = [
    (-0.5, -0.5), (-0.13, -0.5), (-0.17, -0.38), (-0.08, -0.32), (0.08, -0.32), (0.17, -0.38), (0.13, -0.5),
    (0.5, -0.5), (0.5, -0.13), (0.62, -0.17), (0.68, -0.05), (0.68, 0.08), (0.62, 0.17), (0.5, 0.13),
    (0.5, 0.5), (0.13, 0.5), (0.17, 0.62), (0.08, 0.68), (-0.08, 0.68), (-0.17, 0.62), (-0.13, 0.5),
    (-0.5, 0.5), (-0.5, 0.13), (-0.38, 0.17), (-0.32, 0.05), (-0.32, -0.08), (-0.38, -0.17), (-0.5, -0.13),
]


def nomear(o, nome):
    o.name = nome
    if o.data:
        o.data.name = nome
    return o


def contorno_rochoso(seed):
    """Contorno da peca com bordas irregulares de pedra (pontos extras com leve deslocamento)."""
    random.seed(100 + seed)
    pts = []
    n = len(CONTORNO)
    for i in range(n):
        a = Vector(CONTORNO[i])
        b = Vector(CONTORNO[(i + 1) % n])
        pts.append(tuple(a))
        if (b - a).length > 0.2:
            t = (b - a)
            nrm = Vector((-t.y, t.x)).normalized()
            for f in (0.35, 0.7):
                p = a + t * f + nrm * random.uniform(-0.025, 0.02)
                pts.append(tuple(p))
    return pts


# ---------------------------------------------------------------- geometria 2D -> 3D
def placa(nome, contorno, espessura, seed=0, aspereza=0.0):
    """Extruda um contorno (x, z) em Y, com a frente em -espessura/2."""
    random.seed(seed)
    bm = bmesh.new()
    vs = []
    for x, z in contorno:
        jx = random.uniform(-aspereza, aspereza)
        jz = random.uniform(-aspereza, aspereza)
        vs.append(bm.verts.new((x + jx, -espessura / 2, z + jz)))
    face = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[face])
    novos = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
    for v in novos:
        v.co.y += espessura
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return o


def faixa(pontos, larguras):
    """Contorno fechado de uma faixa grossa ao longo de uma linha (x, z)."""
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


def elipse(cx, cz, rx, rz, n=10, giro=0.0):
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, z = math.cos(a) * rx, math.sin(a) * rz
        pts.append((cx + x * math.cos(giro) - z * math.sin(giro), cz + x * math.sin(giro) + z * math.cos(giro)))
    return pts


def anel(cx, cz, rx, rz, w, n=12, giro=0.0):
    """Anel como varias faixas curtas (contornos convexos)."""
    pts = elipse(cx, cz, rx, rz, n, giro)
    partes = []
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        partes.append(faixa([a, b], w))
    return partes


# ---------------------------------------------------------------- simbolos (cada um: lista de (contorno, papel))
# papel "principal" = parte que brilha; "miolo" = detalhe por cima (outra cor quando acesa)
def sim_fogo():
    chama = [(0.0, 0.3), (0.06, 0.2), (0.15, 0.08), (0.19, -0.06), (0.15, -0.18), (0.06, -0.25), (-0.06, -0.25),
             (-0.15, -0.18), (-0.19, -0.06), (-0.15, 0.06), (-0.08, 0.12), (-0.06, 0.02), (-0.02, 0.16)]
    miolo = [(0.0, 0.08), (0.06, -0.04), (0.07, -0.12), (0.0, -0.17), (-0.07, -0.12), (-0.05, -0.04)]
    return [(chama, "principal"), (miolo, "miolo")]


def sim_agua():
    gota = [(0.0, 0.3), (0.08, 0.15), (0.16, 0.0), (0.18, -0.1), (0.13, -0.21), (0.0, -0.26), (-0.13, -0.21),
            (-0.18, -0.1), (-0.16, 0.0), (-0.08, 0.15)]
    return [(gota, "principal"), (elipse(0.0, -0.09, 0.07, 0.07, 10), "miolo")]


def folha(cx, cz, comp, larg, ang):
    """Folha pontuda nas duas pontas, apontando no angulo dado."""
    pts = []
    for i in range(10):
        t = i / 9
        x = (t - 0.5) * comp
        w = math.sin(t * math.pi) * larg
        pts.append((x, w))
    for i in range(8, 0, -1):
        t = i / 9
        x = (t - 0.5) * comp
        w = -math.sin(t * math.pi) * larg * 0.6
        pts.append((x, w))
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + x * c - z * s, cz + x * s + z * c) for x, z in pts]


def sim_vida():
    partes = [(faixa([(0.0, -0.27), (0.0, -0.08), (0.0, 0.04)], [0.065, 0.055, 0.045]), "principal")]
    partes.append((folha(-0.12, 0.09, 0.26, 0.09, math.radians(150)), "principal"))
    partes.append((folha(0.12, 0.13, 0.28, 0.1, math.radians(35)), "principal"))
    return partes


def sim_feroz():
    partes = []
    for k, dx in enumerate((-0.12, 0.0, 0.12)):
        pts = [(dx - 0.1, -0.24), (dx - 0.03, -0.08), (dx + 0.03, 0.08), (dx + 0.08, 0.26)]
        partes.append((faixa(pts, [0.01, 0.055, 0.05, 0.005]), "principal"))
    return partes


def sim_gravitacao():
    pts = []
    for i in range(46):
        t = i / 45
        a = t * 2.6 * 2 * math.pi
        r = 0.02 + 0.24 * t
        pts.append((math.cos(a) * r, math.sin(a) * r))
    larg = [0.03 + 0.04 * (i / 45) for i in range(46)]
    # quebra a espiral em pedacos curtos (contornos simples)
    partes = []
    for i in range(0, 45, 3):
        seg = pts[i:i + 4]
        partes.append((faixa(seg, larg[i:i + 4]), "principal"))
    return partes


def sim_prende():
    partes = []
    for c, g in (((-0.08, -0.08), 45), ((0.08, 0.08), 45)):
        for f in anel(c[0], c[1], 0.15, 0.08, 0.05, n=12, giro=math.radians(g)):
            partes.append((f, "principal"))
    return partes


def sim_arremesso():
    partes = [(faixa([(-0.22, -0.2), (-0.08, -0.08), (0.1, 0.1)], [0.03, 0.06, 0.06]), "principal")]
    partes.append(([(0.22, 0.22), (0.02, 0.17), (0.17, 0.02)], "principal"))
    for k, (dx, dz) in enumerate(((-0.06, 0.04), (0.04, -0.07))):
        partes.append((faixa([(-0.2 + dx, -0.12 + dz), (-0.08 + dx, 0.0 + dz)], [0.01, 0.03]), "miolo"))
    return partes


def sim_quebrar():
    pts = []
    for i in range(12):
        a = 2 * math.pi * i / 12 + math.pi / 2
        r = 0.27 if i % 2 == 0 else 0.1
        pts.append((math.cos(a) * r, math.sin(a) * r))
    miolo = []
    for i in range(12):
        a = 2 * math.pi * i / 12 + math.pi / 2
        r = 0.1 if i % 2 == 0 else 0.04
        miolo.append((math.cos(a) * r, math.sin(a) * r))
    return [(pts, "principal"), (miolo, "miolo")]


SIMBOLOS = {"fogo": sim_fogo, "agua": sim_agua, "vida": sim_vida, "feroz": sim_feroz,
            "gravitacao": sim_gravitacao, "prende": sim_prende, "arremesso": sim_arremesso, "quebrar": sim_quebrar}


# ---------------------------------------------------------------- materiais
def materiais_runa(nome):
    brilho, tom = ELEMENTOS[nome]
    return {
        "pedra_apagada": base.material(f"Pedra_{nome}_apagada", "#5d5866", rugosidade=0.85),
        "simbolo_apagado": base.material(f"Simbolo_{nome}_apagado", "#26222c", rugosidade=0.9),
        "miolo_apagado": base.material(f"Miolo_{nome}_apagado", "#5d5866", rugosidade=0.85),
        "pedra_acesa": base.material(f"Pedra_{nome}_acesa", tom, rugosidade=0.8, emissao=brilho, forca=0.08),
        "simbolo_aceso": base.material(f"Simbolo_{nome}_aceso", "#000000", rugosidade=1.0, emissao=brilho, forca=1.7),
        "miolo_aceso": base.material(f"Miolo_{nome}_aceso", "#000000", rugosidade=1.0, emissao="#ffe9a0", forca=1.4),
    }


def criar_runa(nome, acesa, local=(0, 0, 0), seed=0):
    """Cria a runa e devolve o objeto raiz (vazio) com Pedra e Simbolo como filhos."""
    mats = materiais_runa(nome) if nome not in criar_runa.cache else criar_runa.cache[nome]
    criar_runa.cache[nome] = mats
    sufixo = "acesa" if acesa else "apagada"
    pts = [(x * TAM, z * TAM) for x, z in contorno_rochoso(seed)]
    pedra = placa(f"Runa_{nome}_{sufixo}_Pedra", pts, ESP, seed=seed, aspereza=0.0)
    m = pedra.modifiers.new("chanfro", "BEVEL")
    m.width = 0.018
    m.segments = 1
    m.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = pedra
    bpy.ops.object.modifier_apply(modifier="chanfro")
    base.aplicar(pedra, mats["pedra_acesa" if acesa else "pedra_apagada"])
    base.chapado(pedra)
    pecas_simbolo = []
    for k, (cont, papel) in enumerate(SIMBOLOS[nome]()):
        c = [(x * TAM * 1.2, z * TAM * 1.2) for x, z in cont]
        s = placa(f"Runa_{nome}_{sufixo}_Simbolo{k}", c, 0.006)
        s.location.y = -ESP / 2 - 0.002 - (0.001 if papel == "miolo" else 0.0)
        chave = ("simbolo_aceso" if acesa else "simbolo_apagado") if papel == "principal" else \
                ("miolo_aceso" if acesa else "miolo_apagado")
        base.aplicar(s, mats[chave])
        base.chapado(s)
        pecas_simbolo.append(s)
    bpy.ops.object.empty_add(location=(0, 0, 0))
    raiz = nomear(bpy.context.active_object, f"Runa_{nome}" + ("_acesa" if acesa else ""))
    for o in [pedra] + pecas_simbolo:
        o.parent = raiz
    raiz.location = local
    return raiz


criar_runa.cache = {}


def contar(raizes):
    objs = []
    for r in raizes:
        objs += [o for o in r.children_recursive if o.type == "MESH"]
    return base.contar_triangulos(objs)


# ---------------------------------------------------------------- render
def palco():
    cena = bpy.context.scene
    mundo = bpy.data.worlds.new("Cinza")
    cena.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = base.cor("#6e6e72")
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    bpy.ops.object.light_add(type="SUN", location=(0, 0, 5))
    sol = bpy.context.active_object
    sol.data.energy = 3.0
    sol.data.angle = math.radians(15)
    sol.rotation_euler = (math.radians(55), 0, math.radians(-20))
    bpy.ops.object.light_add(type="AREA", location=(2, -3, 1))
    f = bpy.context.active_object
    f.data.energy = 120
    f.data.size = 6
    f.rotation_euler = (math.radians(70), 0, math.radians(30))


def principal():
    base.limpar_cena()
    ordem = ["fogo", "agua", "vida", "feroz", "gravitacao", "prende", "arremesso", "quebrar"]
    if MODO == "exportar":
        raizes = []
        for i, nome in enumerate(ordem):
            raizes.append(criar_runa(nome, False, local=(i * 0.5, 0, 0), seed=i))
        print("TRIANGULOS_8_RUNAS", contar(raizes))
        base.exportar_glb(SAIDA + ".glb", raizes)
        base.limpar_cena()
        criar_runa.cache = {}
        raizes = [criar_runa(n, True, local=(i * 0.5, 0, 0), seed=i) for i, n in enumerate(ordem)]
        base.exportar_glb(SAIDA + "_acesas.glb", raizes)
        return
    palco()
    # duas fileiras de 4 pares (apagada | acesa), como na folha
    passo_par, passo_fila = 1.0, 0.85
    for i, nome in enumerate(ordem):
        col, fila = i % 4, i // 4
        x0 = (col - 1.5) * 0.9
        z0 = 0.95 - fila * 0.8
        for acesa, dx in ((False, -0.21), (True, 0.21)):
            r = criar_runa(nome, acesa, local=(x0 + dx, 0, z0), seed=i)
            r.rotation_euler = (math.radians(-12), 0, math.radians(-14))
    # combinacoes encaixadas (o dente entra na fenda: passo = TAM)
    combos = [("fogo", "prende", "arremesso"), ("vida", "gravitacao", "quebrar"), ("agua", "arremesso", "feroz")]
    for c, trio in enumerate(combos):
        xc = (c - 1) * 1.2
        for k, nome in enumerate(trio):
            r = criar_runa(nome, True, local=(xc + (k - 1) * TAM, 0, -0.75), seed=10 + c * 3 + k)
            r.rotation_euler = (math.radians(-10), 0, 0)
    bpy.ops.object.camera_add(location=(0, -6, 0.05))
    cam = bpy.context.active_object
    cam.rotation_euler = (math.radians(90), 0, 0)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 3.75
    bpy.context.scene.camera = cam
    base.renderizar(SAIDA + ".png", largura=1536, altura=1024, amostras=48)


principal()
