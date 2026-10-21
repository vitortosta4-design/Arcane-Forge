"""Piloto: correntes arcanas saindo do chao (runa 'prende' + essencia 'arcano')."""
import math
import random
import sys
import os
import bpy
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(__file__))
import base  # noqa: E402

SAIDA = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/tmp/corrente"


def elo(nome, comprimento=0.36, largura=0.22, espessura=0.036, lados_tubo=6, lados_curva=5):
    """Elo de corrente: anel em forma de pista de corrida, secao hexagonal."""
    reto = comprimento - largura
    r = largura / 2
    caminho = []
    for i in range(lados_curva + 1):
        a = math.pi * i / lados_curva
        caminho.append(Vector((r * math.cos(a), reto / 2 + r * math.sin(a), 0)))
    for i in range(lados_curva + 1):
        a = math.pi + math.pi * i / lados_curva
        caminho.append(Vector((r * math.cos(a), -reto / 2 + r * math.sin(a), 0)))
    bm = bmesh.new()
    aneis = []
    n = len(caminho)
    for i, p in enumerate(caminho):
        tang = (caminho[(i + 1) % n] - caminho[i - 1]).normalized()
        lado = tang.cross(Vector((0, 0, 1))).normalized()
        anel = []
        for j in range(lados_tubo):
            b = 2 * math.pi * j / lados_tubo
            off = lado * math.cos(b) * espessura + Vector((0, 0, 1)) * math.sin(b) * espessura
            anel.append(bm.verts.new(p + off))
        aneis.append(anel)
    for i in range(n):
        a1, a2 = aneis[i], aneis[(i + 1) % n]
        for j in range(lados_tubo):
            bm.faces.new((a1[j], a1[(j + 1) % lados_tubo], a2[(j + 1) % lados_tubo], a2[j]))
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(obj)
    return obj


def curva(t, base_pos, altura, curvatura, giro):
    """Corrente sobe do chao e curva para frente, como uma cobra pronta pra dar o bote."""
    x = base_pos.x + math.sin(t * math.pi * 0.9) * curvatura * math.cos(giro)
    y = base_pos.y + math.sin(t * math.pi * 0.9) * curvatura * math.sin(giro)
    z = base_pos.z + altura * math.sin(t * math.pi * 0.55)
    return Vector((x, y, z))


def corrente(nome, base_pos, n_elos, altura, curvatura, giro, mat, mat_brilho):
    elos = []
    passo = 0.27
    pontos = [curva(i / 200, base_pos, altura, curvatura, giro) for i in range(201)]
    # distribui elos por distancia ao longo da curva
    acumulado, alvo, idx = 0.0, 0.0, 0
    posicoes = []
    for i in range(1, len(pontos)):
        seg = (pontos[i] - pontos[i - 1]).length
        acumulado += seg
        if acumulado >= alvo:
            posicoes.append((pontos[i], (pontos[min(i + 1, 200)] - pontos[i - 1]).normalized()))
            alvo += passo
            if len(posicoes) >= n_elos:
                break
    for k, (p, tang) in enumerate(posicoes):
        e = elo(f"{nome}_elo{k}")
        # elo comprido no eixo Y local -> alinhar com a tangente
        rot = Vector((0, 1, 0)).rotation_difference(tang).to_matrix().to_4x4()
        giro_elo = Matrix.Rotation(math.radians(90 * (k % 2) + 8), 4, "Y")
        e.matrix_world = Matrix.Translation(p) @ rot @ giro_elo
        base.aplicar(e, mat_brilho if k == len(posicoes) - 1 else mat)
        base.chapado(e)
        elos.append(e)
    # gancho na ponta (garra que prende)
    ponta, tang = posicoes[-1]
    bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.09, depth=0.28,
                                    location=ponta + tang * 0.22)
    gancho = bpy.context.active_object
    gancho.rotation_euler = Vector((0, 0, 1)).rotation_difference(tang).to_euler()
    base.aplicar(gancho, mat_brilho)
    base.chapado(gancho)
    elos.append(gancho)
    return elos


def entulho(centro, raio, mat_pedra, n=9, seed=1):
    random.seed(seed)
    pedras = []
    for i in range(n):
        a = 2 * math.pi * i / n + random.uniform(-0.2, 0.2)
        d = raio * random.uniform(0.8, 1.15)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.08, 0.16),
                                              location=centro + Vector((math.cos(a) * d, math.sin(a) * d, 0.02)))
        p = bpy.context.active_object
        p.scale = (1, random.uniform(0.7, 1.2), random.uniform(0.5, 0.8))
        p.rotation_euler = (random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), random.uniform(0, 3))
        base.aplicar(p, mat_pedra)
        base.chapado(p)
        pedras.append(p)
    return pedras


def cristal(pos, altura, inclina, mat):
    bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.07, depth=altura, location=pos)
    c = bpy.context.active_object
    c.location.z += altura / 2 - 0.05
    c.rotation_euler = inclina
    base.aplicar(c, mat)
    base.chapado(c)
    return c


def principal():
    base.limpar_cena()
    base.palco(raio=2.0)
    ferro = base.material("Ferro", "#5a5e68", rugosidade=0.5, metal=0.55)
    ferro_brilho = base.material("FerroRuna", "#3d6fb0", rugosidade=0.4, metal=0.3,
                                 emissao="#3aa6ff", forca=1.3)
    pedra = base.material("Pedra", "#7a7266", rugosidade=0.9)
    cristal_m = base.material("Cristal", "#3f8fe0", rugosidade=0.2,
                              emissao="#2f8fff", forca=0.9)
    runa = base.material("Runa", "#1b2a55", rugosidade=0.6, emissao="#2f9bff", forca=2.2)

    # circulo de runa no chao (buraco de onde saem as correntes)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.75, depth=0.02, location=(0, 0, 0.012))
    anel = bpy.context.active_object
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.62, depth=0.05, location=(0, 0, 0.012))
    furo = bpy.context.active_object
    mod = anel.modifiers.new("furo", "BOOLEAN")
    mod.object = furo
    mod.operation = "DIFFERENCE"
    bpy.context.view_layer.objects.active = anel
    bpy.ops.object.modifier_apply(modifier="furo")
    bpy.data.objects.remove(furo)
    base.aplicar(anel, runa)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.6, depth=0.02, location=(0, 0, 0.005))
    buraco = bpy.context.active_object
    base.aplicar(buraco, base.material("Fenda", "#05081a", 0.9, emissao="#0c2a9a", forca=0.5))
    glifo = base.material("Glifo", "#9fe0ff", 0.5, emissao="#7fd4ff", forca=4.0)
    for i in range(10):
        a = 2 * math.pi * i / 10
        bpy.ops.mesh.primitive_cube_add(size=1, location=(math.cos(a) * 0.685, math.sin(a) * 0.685, 0.03))
        g = bpy.context.active_object
        g.scale = (0.03, 0.09 if i % 2 else 0.05, 0.01)
        g.rotation_euler = (0, 0, a)
        base.aplicar(g, glifo)

    pecas = []
    pecas += corrente("A", Vector((0.25, 0.15, -0.1)), 10, 1.8, 0.95, math.radians(-75), ferro, ferro_brilho)
    pecas += corrente("B", Vector((-0.3, 0.2, -0.1)), 9, 1.4, 0.9, math.radians(200), ferro, ferro_brilho)
    entulho(Vector((0, 0, 0)), 0.8, pedra)
    random.seed(7)
    for i in range(6):
        a = 2 * math.pi * i / 6 + 0.4
        cristal(Vector((math.cos(a) * 0.95, math.sin(a) * 0.95, 0)), random.uniform(0.25, 0.45),
                (math.cos(a) * 0.45, math.sin(a) * -0.45, 0), cristal_m)

    bpy.ops.object.light_add(type="POINT", location=(0, 0, 0.35))
    luz = bpy.context.active_object
    luz.data.energy = 60
    luz.data.color = base.cor("#4fb8ff")[:3]

    print("TRIANGULOS_CORRENTES", base.contar_triangulos(pecas))
    base.camera((0.1, 0, 0.75), distancia=4.2, altura=2.2, angulo=-20)
    if os.environ.get("EXPORTAR"):
        base.exportar_glb(SAIDA + ".glb")
        return
    base.renderizar(SAIDA + ".png")


principal()
