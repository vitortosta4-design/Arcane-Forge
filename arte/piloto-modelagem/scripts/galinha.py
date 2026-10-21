"""Piloto: galinha low poly com esqueleto e animacao (andar bicando).

Estilo: rechonchuda e expressiva, como a galinha da referencia de magias.
Pecas rigidas presas aos ossos (padrao comum em low poly; anima bem e e leve).
"""
import math
import random
import sys
import os
import bpy
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(__file__))
import base  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else "/tmp/galinha"
MODO = args[1] if len(args) > 1 else "heroi"  # heroi | poses | exportar


def esfera(nome, pos, escala, mat, seg=10, aneis=7, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=aneis, radius=1, location=pos)
    o = bpy.context.active_object
    o.name = nome
    o.scale = escala
    o.rotation_euler = rot
    base.aplicar_transformacoes(o)
    base.aplicar(o, mat)
    base.chapado(o)
    return o


def cone(nome, pos, r, altura, mat, lados=5, rot=(0, 0, 0), r2=0.0):
    bpy.ops.mesh.primitive_cone_add(vertices=lados, radius1=r, radius2=r2, depth=altura, location=pos)
    o = bpy.context.active_object
    o.name = nome
    o.rotation_euler = rot
    base.aplicar_transformacoes(o)
    base.aplicar(o, mat)
    base.chapado(o)
    return o


def deformar(o, func):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        v.co = func(v.co.copy())
    bm.to_mesh(o.data)
    bm.free()


def montar():
    pena = base.material("Pena", "#f4f0e6", rugosidade=0.85)
    pena_sombra = base.material("PenaAsa", "#dcd5c6", rugosidade=0.85)
    crista = base.material("Crista", "#e02a22", rugosidade=0.6)
    bico = base.material("Bico", "#f6a51c", rugosidade=0.5)
    perna = base.material("Perna", "#f08a1c", rugosidade=0.6)
    olho_b = base.material("OlhoBranco", "#ffffff", rugosidade=0.3)
    olho_p = base.material("Pupila", "#141414", rugosidade=0.2)

    p = {}
    # corpo: ovo inclinado, peito estufado na frente, traseira subindo pro rabo
    corpo = esfera("Corpo", (0, 0, 0.62), (0.36, 0.48, 0.36), pena, seg=12, aneis=8)

    def forma_corpo(c):
        y = c.y - 0.0
        if c.y > 0.15:      # traseira sobe
            c.z += (c.y - 0.15) * 0.55
        if c.y < -0.2 and c.z < 0.62:  # peito estufado
            c.y -= 0.05
        if c.z < 0.4:
            c.z += 0.03
        return c
    deformar(corpo, forma_corpo)
    p["corpo"] = corpo

    # cabeca e pescoco
    cabeca = esfera("Cabeca", (0, -0.36, 1.08), (0.2, 0.21, 0.22), pena, seg=10, aneis=7)
    pescoco = esfera("Pescoco", (0, -0.29, 0.9), (0.19, 0.21, 0.24), pena, seg=10, aneis=6)
    p["cabeca"] = [cabeca, pescoco]

    # crista: tres gomos
    gomos = []
    for k, (dy, h, s) in enumerate(((-0.1, 1.31, 0.075), (0.0, 1.35, 0.085), (0.1, 1.3, 0.07))):
        g = esfera(f"Crista{k}", (0, -0.36 + dy, h), (0.045, s, s * 1.15), crista, seg=6, aneis=4)
        gomos.append(g)
    # bico (cima e baixo) e barbela
    bico_c = cone("BicoCima", (0, -0.6, 1.07), 0.065, 0.16, bico, lados=4,
                  rot=(math.radians(-95), 0, math.radians(45)))
    bico_b = cone("BicoBaixo", (0, -0.58, 1.03), 0.045, 0.11, bico, lados=4,
                  rot=(math.radians(-80), 0, math.radians(45)))
    barbela = esfera("Barbela", (0, -0.53, 0.95), (0.045, 0.04, 0.075), crista, seg=6, aneis=4)
    # olhos grandes e expressivos
    olhos = []
    for lado in (-1, 1):
        ob = esfera(f"Olho{lado}", (lado * 0.155, -0.46, 1.13), (0.035, 0.06, 0.065), olho_b, seg=8, aneis=6)
        pu = esfera(f"Pupila{lado}", (lado * 0.172, -0.475, 1.135), (0.02, 0.03, 0.038), olho_p, seg=6, aneis=5)
        olhos += [ob, pu]
    p["cabeca"] += gomos + [bico_c, bico_b, barbela] + olhos

    # asas: gota achatada com pontas de pena
    for lado, nome in ((-1, "asaE"), (1, "asaD")):
        asa = esfera(f"Asa{nome}", (0, 0, 0), (0.05, 0.28, 0.15), pena_sombra, seg=10, aneis=6)

        def gota(c, lado=lado):
            t = min(1.0, max(0.0, (c.y + 0.05) / 0.33))
            c.z = c.z * (1 - 0.75 * t) + 0.12 * t * t      # afina e sobe para tras
            c.x = c.x * (1 - 0.5 * t)
            if c.z < -0.05 and t > 0.3:                    # recorte de penas na borda de baixo
                c.z += 0.025 * math.sin(c.y * 60) ** 2
            return c
        deformar(asa, gota)
        asa.location = (lado * 0.33, 0.1, 0.68)
        asa.rotation_euler = (math.radians(-8), 0, math.radians(lado * -5))
        base.aplicar_transformacoes(asa)
        pontas = []
        p[nome] = [asa] + pontas

    # rabo em leque
    rabo = []
    for k in range(5):
        a = math.radians(-36 + k * 18)
        r = esfera(f"Rabo{k}", (math.sin(a) * 0.12, 0.5, 1.02 + math.cos(a) * 0.05), (0.035, 0.08, 0.2), pena,
                   seg=6, aneis=5, rot=(math.radians(-28), a * 0.9, 0))
        rabo.append(r)
    p["rabo"] = rabo

    # pernas e pes de tres dedos
    for lado, nome in ((-1, "pernaE"), (1, "pernaD")):
        x = lado * 0.13
        coxa = esfera(f"Coxa{nome}", (x, 0.02, 0.36), (0.1, 0.11, 0.1), pena, seg=8, aneis=5)
        canela = cone(f"Canela{nome}", (x, 0.02, 0.17), 0.028, 0.3, perna, lados=5, r2=0.022)
        dedos = []
        for k, ang in enumerate((-30, 0, 30)):
            d = cone(f"Dedo{nome}{k}", (x + math.sin(math.radians(ang)) * 0.06, -0.06, 0.02), 0.022, 0.16, perna,
                     lados=4, rot=(math.radians(-90), 0, math.radians(ang)))
            dedos.append(d)
        tras = cone(f"DedoTras{nome}", (x, 0.08, 0.02), 0.018, 0.09, perna, lados=4, rot=(math.radians(90), 0, 0))
        p[nome] = [coxa, canela, tras] + dedos
    return p


def esqueleto(p):
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = bpy.context.active_object
    arm.name = "GalinhaEsqueleto"
    bpy.ops.object.mode_set(mode="EDIT")
    ossos = arm.data.edit_bones
    raiz = ossos[0]
    raiz.name = "Raiz"
    raiz.head, raiz.tail = (0, 0, 0), (0, 0, 0.2)

    def osso(nome, cabeca, cauda, pai):
        b = ossos.new(nome)
        b.head, b.tail = cabeca, cauda
        b.parent = ossos[pai]
        return b
    osso("Corpo", (0, 0.05, 0.42), (0, 0.05, 0.75), "Raiz")
    osso("Cabeca", (0, -0.28, 0.85), (0, -0.36, 1.15), "Corpo")
    osso("AsaE", (-0.3, -0.1, 0.75), (-0.33, 0.3, 0.7), "Corpo")
    osso("AsaD", (0.3, -0.1, 0.75), (0.33, 0.3, 0.7), "Corpo")
    osso("Rabo", (0, 0.4, 0.85), (0, 0.55, 1.15), "Corpo")
    osso("PernaE", (-0.13, 0.02, 0.4), (-0.13, 0.02, 0.0), "Raiz")
    osso("PernaD", (0.13, 0.02, 0.4), (0.13, 0.02, 0.0), "Raiz")
    bpy.ops.object.mode_set(mode="OBJECT")

    mapa = {"corpo": "Corpo", "cabeca": "Cabeca", "asaE": "AsaE", "asaD": "AsaD",
            "rabo": "Rabo", "pernaE": "PernaE", "pernaD": "PernaD"}
    for chave, nome_osso in mapa.items():
        pecas = p[chave] if isinstance(p[chave], list) else [p[chave]]
        for o in pecas:
            mw = o.matrix_world.copy()
            o.parent = arm
            o.parent_type = "BONE"
            o.parent_bone = nome_osso
            o.matrix_world = mw
    return arm


def animar(arm, quadros=24):
    """Ciclo de andar: pernas alternam, corpo balanca, cabeca vai e volta (o 'tranco' da galinha)."""
    cena = bpy.context.scene
    cena.frame_start, cena.frame_end = 1, quadros
    cena.render.fps = 24
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm.pose.bones
    for b in pb:
        b.rotation_mode = "XYZ"
    for f in range(1, quadros + 1, 2):
        t = (f - 1) / quadros * 2 * math.pi
        pb["PernaE"].rotation_euler = (math.sin(t) * 0.5, 0, 0)
        pb["PernaD"].rotation_euler = (-math.sin(t) * 0.5, 0, 0)
        pb["Corpo"].location = (0, abs(math.sin(t)) * 0.035, 0)
        pb["Corpo"].rotation_euler = (0, math.sin(t) * 0.06, 0)
        # cabeca: avanca e trava (movimento tipico de galinha)
        avanco = max(0.0, math.sin(t * 2)) ** 0.5
        pb["Cabeca"].location = (0, avanco * 0.06, 0)
        pb["Cabeca"].rotation_euler = (-0.15 * avanco, 0, 0)
        pb["AsaE"].rotation_euler = (0, -abs(math.sin(t * 2)) * 0.25, 0)
        pb["AsaD"].rotation_euler = (0, abs(math.sin(t * 2)) * 0.25, 0)
        pb["Rabo"].rotation_euler = (math.sin(t) * 0.12, 0, 0)
        for nome in ("PernaE", "PernaD", "Corpo", "Cabeca", "AsaE", "AsaD", "Rabo"):
            pb[nome].keyframe_insert("rotation_euler", frame=f)
            pb[nome].keyframe_insert("location", frame=f)
    bpy.ops.object.mode_set(mode="OBJECT")
    arm.animation_data.action.name = "Andar"


def principal():
    base.limpar_cena()
    p = montar()
    todas = []
    for v in p.values():
        todas += v if isinstance(v, list) else [v]
    print("TRIANGULOS_GALINHA", base.contar_triangulos(todas))
    arm = esqueleto(p)
    animar(arm)

    if MODO == "exportar":
        bpy.context.scene.frame_set(1)
        base.exportar_glb(SAIDA + ".glb", [arm], animacoes=True)
        return

    base.palco(raio=1.6, cor_chao="#6a9a3c")
    for o in bpy.data.objects:
        if o.type == "LIGHT" and o.data.type == "AREA" and o.data.energy == 120:
            o.data.energy = 60
    if MODO == "heroi":
        bpy.context.scene.frame_set(1)
        base.camera((0, -0.1, 0.62), distancia=3.0, altura=1.25, angulo=-38)
        base.renderizar(SAIDA + ".png", amostras=64)
    else:
        for f in (1, 7, 13, 19):
            bpy.context.scene.frame_set(f)
            base.camera((0, -0.1, 0.6), distancia=3.0, altura=0.9, angulo=-90)
            base.renderizar(f"{SAIDA}_q{f:02d}.png", largura=600, altura=600, amostras=32)


principal()
