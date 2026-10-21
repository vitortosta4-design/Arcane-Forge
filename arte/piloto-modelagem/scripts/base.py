"""Base comum do piloto de modelagem do Arcane Forge.

Cena, materiais, luz e render, para todas as pecas ficarem com a mesma cara
(low poly, faces chapadas, cores saturadas, luz quente + sombra azulada, como
nas referencias).
"""
import math
import bpy
import bmesh
from mathutils import Vector


def limpar_cena():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def cor(hexa):
    hexa = hexa.lstrip("#")
    r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (0, 2, 4))
    # sRGB -> linear
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (lin(r), lin(g), lin(b), 1.0)


def material(nome, hexa, rugosidade=0.7, metal=0.0, emissao=None, forca=0.0,
             transmissao=0.0, alfa=1.0):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = cor(hexa)
    p.inputs["Roughness"].default_value = rugosidade
    p.inputs["Metallic"].default_value = metal
    if emissao:
        p.inputs["Emission Color"].default_value = cor(emissao)
        p.inputs["Emission Strength"].default_value = forca
    if transmissao:
        p.inputs["Transmission Weight"].default_value = transmissao
    if alfa < 1.0:
        p.inputs["Alpha"].default_value = alfa
    return m


def aplicar(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def chapado(obj):
    """Faces chapadas (visual low poly)."""
    for p in obj.data.polygons:
        p.use_smooth = False


def aplicar_transformacoes(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def juntar(objs, nome):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = nome
    return objs[0]


def contar_triangulos(objs):
    total = 0
    for o in objs:
        if o.type != "MESH":
            continue
        dg = bpy.context.evaluated_depsgraph_get()
        me = o.evaluated_get(dg).to_mesh()
        total += sum(len(p.vertices) - 2 for p in me.polygons)
        o.evaluated_get(dg).to_mesh_clear()
    return total


def palco(chao=True, raio=2.2, cor_chao="#5f8f3a"):
    """Chao de grama low poly, ceu crepuscular, sol quente e preenchimento azul."""
    cena = bpy.context.scene
    mundo = bpy.data.worlds.new("Mundo")
    cena.world = mundo
    mundo.use_nodes = True
    fundo = mundo.node_tree.nodes["Background"]
    fundo.inputs["Color"].default_value = cor("#3b4f8a")
    fundo.inputs["Strength"].default_value = 0.55

    if chao:
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=raio, depth=0.25,
                                            location=(0, 0, -0.125))
        disco = bpy.context.active_object
        disco.name = "Chao"
        bm = bmesh.new()
        bm.from_mesh(disco.data)
        import random
        random.seed(3)
        for v in bm.verts:
            if v.co.z > 0:
                v.co.z += random.uniform(-0.03, 0.03)
        bm.to_mesh(disco.data)
        bm.free()
        aplicar(disco, material("Grama", cor_chao, 0.9))
        chapado(disco)

    bpy.ops.object.light_add(type="SUN", location=(3, -3, 5))
    sol = bpy.context.active_object
    sol.data.energy = 3.2
    sol.data.color = cor("#ffd9a8")[:3]
    sol.data.angle = math.radians(4)
    sol.rotation_euler = (math.radians(50), 0, math.radians(35))

    bpy.ops.object.light_add(type="AREA", location=(-3, 2, 2.5))
    fill = bpy.context.active_object
    fill.data.energy = 120
    fill.data.size = 4
    fill.data.color = cor("#8fa8ff")[:3]
    fill.rotation_euler = (math.radians(60), 0, math.radians(-120))

    bpy.ops.object.light_add(type="AREA", location=(0, 3, 1.8))
    contra = bpy.context.active_object
    contra.data.energy = 90
    contra.data.size = 2
    contra.data.color = cor("#c9b6ff")[:3]
    contra.rotation_euler = (math.radians(-70), 0, 0)


def camera(alvo, distancia=4.0, altura=1.6, angulo=-35, lente=50):
    a = math.radians(angulo)
    pos = Vector((math.sin(a) * distancia, -math.cos(a) * distancia, altura)) + Vector(alvo)
    bpy.ops.object.camera_add(location=pos)
    cam = bpy.context.active_object
    cam.data.lens = lente
    direcao = Vector(alvo) - cam.location
    cam.rotation_euler = direcao.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


def renderizar(caminho, largura=900, altura=900, amostras=48):
    cena = bpy.context.scene
    cena.render.engine = "CYCLES"
    cena.cycles.device = "CPU"
    cena.cycles.samples = amostras
    cena.cycles.use_denoising = True
    cena.render.resolution_x = largura
    cena.render.resolution_y = altura
    cena.render.film_transparent = False
    cena.view_settings.view_transform = "AgX"
    cena.view_settings.look = "AgX - Punchy"
    cena.render.filepath = caminho
    bpy.ops.render.render(write_still=True)


def exportar_glb(caminho, objs=None, animacoes=False):
    bpy.ops.object.select_all(action="DESELECT")
    alvos = objs if objs else [o for o in bpy.data.objects if o.type in ("MESH", "ARMATURE")
                               and o.name != "Chao"]
    for o in alvos:
        o.select_set(True)
        for filho in o.children_recursive:
            filho.select_set(True)
    bpy.ops.export_scene.gltf(filepath=caminho, use_selection=True,
                              export_animations=animacoes, export_apply=True)
