"""Piloto: molotov arcano (forma 'arremesso em arco' + essencia 'fogo arcano')."""
import math
import random
import sys
import os
import bpy
import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(__file__))
import base  # noqa: E402

SAIDA = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/tmp/molotov"


def torno(nome, perfil, lados=10, fechar_topo=False):
    """Gira um perfil (raio, altura) em volta do eixo Z, como num torno de oleiro."""
    bm = bmesh.new()
    aneis = []
    for r, z in perfil:
        anel = []
        for i in range(lados):
            a = 2 * math.pi * i / lados
            anel.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z)))
        aneis.append(anel)
    for k in range(len(aneis) - 1):
        for i in range(lados):
            j = (i + 1) % lados
            bm.faces.new((aneis[k][i], aneis[k][j], aneis[k + 1][j], aneis[k + 1][i]))
    bm.faces.new(list(reversed(aneis[0])))
    if fechar_topo:
        bm.faces.new(aneis[-1])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(obj)
    return obj


def chama(nome, pos, altura, raio, mat, seed=0, inclina=(0, 0, 0)):
    """Labareda low poly: gota torcida, larga embaixo e pontuda em cima."""
    random.seed(seed)
    perfil = [(0.0, 0.0), (raio * 0.8, altura * 0.12), (raio, altura * 0.3),
              (raio * 0.75, altura * 0.55), (raio * 0.35, altura * 0.8), (0.02, altura)]
    obj = torno(nome, perfil, lados=6, fechar_topo=True)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for v in bm.verts:
        t = v.co.z / altura
        torcao = t * 1.4
        x, y = v.co.x, v.co.y
        v.co.x = x * math.cos(torcao) - y * math.sin(torcao) + math.sin(t * 3 + seed) * 0.03 * t
        v.co.y = x * math.sin(torcao) + y * math.cos(torcao)
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = pos
    obj.rotation_euler = inclina
    base.aplicar(obj, mat)
    base.chapado(obj)
    return obj


def principal():
    base.limpar_cena()
    base.palco(raio=1.4, cor_chao="#6a8f3c")

    vidro = base.material("Vidro", "#3e8a4a", rugosidade=0.15, transmissao=0.35)
    liquido = base.material("LiquidoArcano", "#9a2cff", rugosidade=0.2,
                            emissao="#a030ff", forca=2.4)
    pano = base.material("Pano", "#c9a77a", rugosidade=0.95)
    pano_sujo = base.material("PanoQueimado", "#5a3a26", rugosidade=0.95)
    corda = base.material("Corda", "#8a5a2b", rugosidade=0.9)
    fogo_ext = base.material("FogoExterno", "#000000", rugosidade=1.0, emissao="#ff3c00", forca=2.6)
    fogo_int = base.material("FogoInterno", "#000000", rugosidade=1.0, emissao="#ffa000", forca=3.6)
    faisca = base.material("Faisca", "#c060ff", emissao="#b040ff", forca=3.0)

    pecas = []
    # garrafa: corpo bojudo, ombro, gargalo e boca
    perfil = [(0.15, 0.0), (0.17, 0.03), (0.175, 0.1), (0.175, 0.4), (0.16, 0.47), (0.1, 0.55),
              (0.06, 0.62), (0.052, 0.8), (0.062, 0.83), (0.065, 0.86), (0.056, 0.88)]
    garrafa = torno("Garrafa", perfil, lados=10)
    base.aplicar(garrafa, vidro)
    base.chapado(garrafa)
    pecas.append(garrafa)

    # liquido arcano ate pouco mais da metade
    perfil_liq = [(0.13, 0.025), (0.155, 0.05), (0.16, 0.12), (0.16, 0.3)]
    liq = torno("Liquido", perfil_liq, lados=10, fechar_topo=True)
    base.aplicar(liq, liquido)
    base.chapado(liq)
    pecas.append(liq)

    # corda enrolada no gargalo
    for k, z in enumerate((0.7, 0.74)):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.062, minor_radius=0.014,
                                         major_segments=10, minor_segments=4, location=(0, 0, z))
        c = bpy.context.active_object
        c.rotation_euler = (0.08 * (1 if k else -1), 0.05, 0)
        base.aplicar(c, corda)
        base.chapado(c)
        pecas.append(c)

    # trapo enfiado na boca: tampao + pontas penduradas
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.05, depth=0.1, location=(0, 0, 0.92))
    tampao = bpy.context.active_object
    base.aplicar(tampao, pano)
    base.chapado(tampao)
    pecas.append(tampao)
    random.seed(4)
    for i, (ang, comp) in enumerate(((0.3, 0.22), (2.4, 0.16), (4.3, 0.19))):
        bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 0, 0))
        ponta = bpy.context.active_object
        bm = bmesh.new()
        bm.from_mesh(ponta.data)
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)
        for v in bm.verts:
            v.co.z += random.uniform(-0.04, 0.04)
        bm.to_mesh(ponta.data)
        bm.free()
        ponta.scale = (0.05, comp * 0.6, 1)
        ponta.location = (math.cos(ang) * 0.085, math.sin(ang) * 0.085, 0.93 - comp * 0.25)
        ponta.rotation_euler = (math.radians(35), 0, ang - math.pi / 2)
        mod = ponta.modifiers.new("esp", "SOLIDIFY")
        mod.thickness = 0.012
        base.aplicar(ponta, pano if i != 1 else pano_sujo)
        base.chapado(ponta)
        pecas.append(ponta)

    # chama no trapo, com miolo claro
    pecas.append(chama("ChamaA", (0, 0, 0.94), 0.4, 0.07, fogo_ext, seed=1, inclina=(0.1, -0.06, 0)))
    pecas.append(chama("ChamaB", (0.0, -0.03, 0.95), 0.24, 0.04, fogo_int, seed=2, inclina=(0.05, -0.05, 0.6)))
    for k in range(5):
        a = 2 * math.pi * k / 5
        pecas.append(chama(f"Lingua{k}", (math.cos(a) * 0.035, math.sin(a) * 0.035, 0.93),
                           random.uniform(0.16, 0.26), 0.035, fogo_ext, seed=10 + k,
                           inclina=(math.sin(a) * -0.45, math.cos(a) * 0.45, a)))

    # faiscas arcanas subindo
    random.seed(9)
    for i in range(7):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.012, 0.022),
                                              location=(random.uniform(-0.15, 0.15), random.uniform(-0.12, 0.12),
                                                        random.uniform(1.15, 1.6)))
        f = bpy.context.active_object
        base.aplicar(f, faisca)
        base.chapado(f)

    bpy.ops.object.light_add(type="POINT", location=(0, -0.1, 1.15))
    luz = bpy.context.active_object
    luz.data.energy = 35
    luz.data.color = base.cor("#ff9a40")[:3]
    bpy.ops.object.light_add(type="POINT", location=(0, -0.3, 0.2))
    luz2 = bpy.context.active_object
    luz2.data.energy = 12
    luz2.data.color = base.cor("#c060ff")[:3]

    # garrafa levemente inclinada, como se fosse ser arremessada
    bpy.ops.object.empty_add(location=(0, 0, 0))
    pivo = bpy.context.active_object
    pivo.name = "Molotov"
    for p in pecas:
        p.parent = pivo
    pivo.rotation_euler.y = math.radians(-8)

    print("TRIANGULOS_MOLOTOV", base.contar_triangulos(pecas))
    base.camera((0, 0, 0.68), distancia=2.1, altura=1.0, angulo=-28)
    if os.environ.get("EXPORTAR"):
        base.exportar_glb(SAIDA + ".glb")
        return
    base.renderizar(SAIDA + ".png", amostras=64)


principal()
