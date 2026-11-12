"""Gigante da arvore do Arcane Forge (piloto ADR-047), modelado pela folha do
Vitor (docs/referencias/gigante_arvore.png, 2a versao: sorriso calmo em V,
olhos com brilho suave, bracos retos e curtos, ninho pequeno no topo da copa).

Humanoide de casca e galhos: tronco e membros facetados, copa de blocos
facetados (icosferas), musgo so nas manchas da folha (peito, coxas,
antebracos, canelas), em placas deitadas que abracam o membro; maos em luva
unica (palma e dedos fundidos numa malha so, sem ossos por dedo: giram em
bloco com a mao), pes meio-raiz. Rosto simples e tranquilo.

~26 m de altura (ALTURA_TOTAL_M, igual ao jogo em arvore_gigante.gd).
So anda: nao ataca nem reage a dano (ADR-047, "solida mas indiferente"),
entao so tem Parado e Andar (sem Atacar/Dano).

Uso: blender --background --python gigante_arvore.py -- SAIDA vistas|exportar
Frente olha para -Y.
"""
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "piloto-modelagem", "scripts"))
import base  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else "/tmp/gigante_arvore"
MODO = args[1] if len(args) > 1 else "vistas"

ALTURA_TOTAL_M = 26.0

# 6a rodada (12/11/2026): corpo refeito pelas medidas tiradas por pixel da
# folha (frente; fracao da altura total a partir do chao, x a partir do eixo):
#   pe: largura 0,20 | vao das pernas fecha em 0,33 (com o saiote) | quadril 0,40
#   cintura 0,45 (meia largura 0,05) | ombros 0,63 (meia largura 0,12)
#   olhos 0,75 | copa de 0,69 a 0,98, largura 0,47
#   braco: fino no ombro (0,05), cotovelo em 0,43 a 0,17 do eixo, antebraco
#   grosso (0,13), ponta dos dedos em 0,09 a 0,22 do eixo
TORNOZELO_Z = 1.9
JOELHO_Z = 5.9
QUADRIL_Z = 10.4
CINTURA_Z = 11.7
PEITO_Z = 15.3
OMBRO_Z = 16.5
PESCOCO_Z = 17.6
OLHOS_Z = 19.5
TOPO_TRONCO_Z = 22.0
COPA_Z = 21.7
QUADRIL_X = 1.15
JOELHO_X = 2.45
PE_X = 3.45
OMBRO_X = 3.1
COTOVELO_X = 4.95
COTOVELO_Z = 11.1
PULSO_X = 6.55
PULSO_Z = 6.5


def criar_materiais():
    global TRONCO, TRONCO_CLARO, TRONCO_ESCURO, MUSGO, MUSGO_CLARO, COPA, COPA_CLARA, COPA_ESCURA
    global OLHO, OLHO_BRILHO, BOCA, NINHO, NINHO_CLARO, PASSARO, PASSARO_BARRIGA, PASSARO_BICO, PASSARO_OLHO, ROSTO
    TRONCO = base.material("Tronco", "#97633a", rugosidade=0.88)
    TRONCO_CLARO = base.material("TroncoClaro", "#b47a48", rugosidade=0.82)
    TRONCO_ESCURO = base.material("TroncoEscuro", "#724629", rugosidade=0.9)
    MUSGO = base.material("Musgo", "#5f922c", rugosidade=0.85)
    MUSGO_CLARO = base.material("MusgoClaro", "#76a836", rugosidade=0.8)
    COPA = base.material("Copa", "#68a030", rugosidade=0.8)
    COPA_CLARA = base.material("CopaClara", "#86c13a", rugosidade=0.75)
    COPA_ESCURA = base.material("CopaEscura", "#4f8527", rugosidade=0.85)
    # Olhos suaves (folha v2: "menos acesos, mais serenos" - emissao baixa,
    # licao do mago: emissao alta + glow do jogo estourava a cor).
    OLHO = base.material("Olho", "#ffd23a", rugosidade=0.6, emissao="#ffc21a", forca=3.0)
    BOCA = base.material("Boca", "#2e1b0e", rugosidade=0.9)
    # 7a rodada: brilho no olho (ponto quase branco) e madeira do rosto mais
    # clara, com material proprio: o jogo da mais luz propria a ele, porque o
    # rosto vive na sombra da copa (arvore_gigante.gd, LUZ_PROPRIA_ROSTO).
    OLHO_BRILHO = base.material("OlhoBrilho", "#fff6c4", rugosidade=0.5, emissao="#fff1a8", forca=4.0)
    ROSTO = base.material("TroncoRosto", "#a56c3e", rugosidade=0.85)
    NINHO = base.material("Ninho", "#7a4a24", rugosidade=0.9)
    NINHO_CLARO = base.material("NinhoClaro", "#a8743c", rugosidade=0.9)
    PASSARO = base.material("Passaro", "#8fc4ec", rugosidade=0.6)
    PASSARO_BARRIGA = base.material("PassaroBarriga", "#eef7ff", rugosidade=0.6)
    PASSARO_BICO = base.material("PassaroBico", "#f08a1e", rugosidade=0.5)
    PASSARO_OLHO = base.material("PassaroOlho", "#1c1c22", rugosidade=0.4)


# ---------------------------------------------------------------- utilitarios (padrao mago.py)
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


def esfera(nome, centro, escala, mat, seg=8, aneis=6, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=aneis, radius=1, location=centro, rotation=rot)
    o = nomear(bpy.context.active_object, nome)
    o.scale = escala
    base.aplicar_transformacoes(o)
    return fim(o, mat)


def icosfera(nome, centro, escala, mat, subdiv=0, rot=(0, 0, 0)):
    """Esfera de poucas facetas grandes (bloco "lapidado"), para a copa."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=centro, rotation=rot)
    o = nomear(bpy.context.active_object, nome)
    o.scale = escala
    base.aplicar_transformacoes(o)
    return fim(o, mat)


def torno(nome, perfil, mat, lados=8, achatar=1.0, fechar=(True, True), centro=(0, 0, 0), ruido=0.0, semente=0, desvio=None):
    """Gira um perfil (raio, z) em volta de Z. ruido mexe cada vertice (casca
    lapidada). desvio: quanto cada anel anda em Y (perfil de lado com peito e
    barriga, em vez de um poste reto)."""
    rnd = random.Random(semente)
    bm = bmesh.new()
    aneis = []
    for k, (r, z) in enumerate(perfil):
        dy = desvio[k] if desvio else 0.0
        anel = []
        for i in range(lados):
            a = 2 * math.pi * i / lados
            rr = r * (1 + rnd.uniform(-ruido, ruido))
            anel.append(bm.verts.new((centro[0] + rr * math.cos(a),
                                      centro[1] + dy + rr * math.sin(a) * achatar,
                                      centro[2] + z + rnd.uniform(-ruido, ruido) * 0.2 * r)))
        aneis.append(anel)
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


def tubo(nome, pontos, raio, mat, lados=6, achatar=1.0, fechar=True):
    bm = bmesh.new()
    aneis = []
    n = len(pontos)
    for i, p in enumerate(pontos):
        p = Vector(p)
        t = (Vector(pontos[min(i + 1, n - 1)]) - Vector(pontos[max(i - 1, 0)])).normalized()
        a = t.cross(Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))).normalized()
        b = t.cross(a).normalized()
        r = raio[i] if isinstance(raio, (list, tuple)) else raio
        aneis.append([bm.verts.new(p + (a * math.cos(2 * math.pi * j / lados) + b * achatar * math.sin(2 * math.pi * j / lados)) * r)
                      for j in range(lados)])
    for k in range(n - 1):
        for j in range(lados):
            jj = (j + 1) % lados
            bm.faces.new((aneis[k][j], aneis[k][jj], aneis[k + 1][jj], aneis[k + 1][j]))
    if fechar:
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


def mancha_musgo(nome, centro, normal, cima, largura, altura, mat, espessura=0.03):
    """Mancha de musgo "colada" numa superficie curva (mesma ideia do triangulo
    de relevo do mago, só com 5 pontos para ficar irregular como na folha)."""
    n = Vector(normal).normalized()
    u = Vector(cima).normalized()
    lado = u.cross(n).normalized()
    c = Vector(centro)
    rnd = random.Random(hash(nome) % 997)
    pts = []
    for ang, r in ((0.3, 0.5), (1.3, 1.0), (2.5, 0.85), (3.6, 1.0), (4.9, 0.55)):
        r *= 1 + rnd.uniform(-0.12, 0.12)
        pts.append(c + (lado * math.cos(ang) * largura / 2 + u * (math.sin(ang) * 0.5 + 0.5) * altura) * r)
    pts = [p + n * espessura for p in pts] + [p for p in pts]
    return casco(nome, pts, mat)


def arvores_bvh(objs):
    from mathutils.bvhtree import BVHTree
    arvs = []
    for o in objs:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        arvs.append(BVHTree.FromBMesh(bm))
        bm.free()
    return arvs


def placa_musgo(nome, alvos, a, b, centro_dir, abertura, mat, contorno=(0.55, 1.0, 0.95, 0.6, 0.14),
                esp=0.26, colunas=4, torcer=0.0, semente=0, alcance=7.0):
    """Placa de musgo DEITADA na peca, abracando o membro (7a rodada: o
    critico reprovou os blocos espetados, "cristal"). Monta uma grade em volta
    do eixo a->b e projeta cada ponto na superficie dos alvos (raio na direcao
    do eixo); o miolo sobe `esp` e a borda afunda na madeira, entao a placa
    acompanha qualquer curva. abertura: quantos graus da volta ela cobre;
    contorno: largura de cada fileira ao longo do eixo; torcer: graus que o
    meio da placa gira ao longo do eixo (faixa em diagonal)."""
    rnd = random.Random(semente)
    arvs = arvores_bvh(alvos)
    a, b = Vector(a), Vector(b)
    t = (b - a).normalized()
    u = Vector(centro_dir)
    u = (u - t * u.dot(t)).normalized()
    v = t.cross(u)
    n = len(contorno)
    passo = (b - a).length / (n - 1)
    bm = bmesh.new()
    grade = []
    for i, larg in enumerate(contorno):
        f = i / (n - 1)
        linha = []
        for j in range(colunas + 1):
            c = -1 + 2 * j / colunas
            borda = j in (0, colunas) or i in (0, n - 1)
            lado = j in (0, colunas)
            # borda em ziguezague (recorte de folha, nao regua)
            zig = (0.86 if i % 2 else 1.1) if lado else 1.0
            ang = math.radians(torcer) * f + math.radians(abertura) / 2 * larg * c * zig
            radial = u * math.cos(ang) + v * math.sin(ang)
            eixo = a.lerp(b, f) + t * (rnd.uniform(-0.22, 0.22) * passo if not lado or 0 < i < n - 1 else 0.0)
            origem = eixo + radial * alcance
            melhor = None
            for arv in arvs:
                loc, nor, _, dist = arv.ray_cast(origem, -radial, alcance)
                if loc is not None and (melhor is None or dist < melhor[2]):
                    melhor = (loc, nor, dist)
            if melhor is None:
                # normal: a placa passou da ponta da peca; cola no ponto mais proximo
                for arv in arvs:
                    loc, nor, _, dist = arv.find_nearest(eixo + radial * 1.0)
                    if loc is not None and (melhor is None or dist < melhor[2]):
                        melhor = (loc, nor, dist)
            loc, nor = melhor[0], melhor[1]
            if nor.dot(radial) < 0:
                nor = -nor
            alt = -0.12 if borda else esp * (1 + rnd.uniform(-0.3, 0.4))
            linha.append(bm.verts.new(loc + (nor + radial).normalized() * alt))
        grade.append(linha)
    for i in range(n - 1):
        for j in range(colunas):
            bm.faces.new((grade[i][j], grade[i][j + 1], grade[i + 1][j + 1], grade[i + 1][j]))
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return fim(o, mat)


def fundir(objs, nome, mat, voxel=0.2, triangulos=300):
    """Funde varias pecas numa malha so, sem emenda (a "luva unica" da mao):
    refaz a superficie por fora (remesh por voxel) e reduz ate `triangulos`,
    o que devolve as facetas grandes do estilo."""
    o = base.juntar(objs, nome)
    o.data.name = nome
    bpy.context.view_layer.objects.active = o
    m = o.modifiers.new("fundir", "REMESH")
    m.mode = "VOXEL"
    m.voxel_size = voxel
    m.adaptivity = 0.0
    bpy.ops.object.modifier_apply(modifier="fundir")
    atuais = sum(len(p.vertices) - 2 for p in o.data.polygons)
    d = o.modifiers.new("reduzir", "DECIMATE")
    d.ratio = min(1.0, triangulos / max(1, atuais))
    bpy.ops.object.modifier_apply(modifier="reduzir")
    return fim(o, mat)


def deformar(o, func):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        v.co = func(v.co.copy())
    bm.to_mesh(o.data)
    bm.free()


# ---------------------------------------------------------------- pecas (6a e 7a rodadas)
def lapidar(o, amp, semente):
    """Mexe cada vertice um pouco (casca talhada a machado, nao tubo de PVC)."""
    rnd = random.Random(semente)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=0.001)
    for v in bm.verts:
        v.co += Vector((rnd.uniform(-amp, amp), rnd.uniform(-amp, amp), rnd.uniform(-amp, amp) * 0.6))
    bm.to_mesh(o.data)
    bm.free()
    base.chapado(o)
    return o


def folha(nome, raiz, ponta, largura, normal, mat, espessura=0.12, barriga=0.5):
    """Losango gordinho: folha de galho ou tufo de musgo. raiz e ponta sao as
    duas pontas; a parte mais larga fica a `barriga` do caminho."""
    raiz, ponta = Vector(raiz), Vector(ponta)
    eixo = ponta - raiz
    n = Vector(normal).normalized()
    lado = eixo.cross(n).normalized()
    n = lado.cross(eixo).normalized()
    meio = raiz + eixo * barriga
    pts = [raiz, ponta, meio + lado * largura / 2, meio - lado * largura / 2,
           meio + n * espessura, meio - n * espessura * 0.4]
    return casco(nome, pts, mat)


def tufo(nome, centro, escala, mat, semente=0, rot=(0, 0, 0)):
    """Bloco de musgo gordinho e facetado, achatado contra a peca (na folha o
    musgo e em placas grossas, nao em lascas)."""
    o = icosfera(nome, centro, escala, mat, subdiv=0, rot=rot)
    return lapidar(o, min(escala) * 0.16, semente)


def galhinho(nome, origem, direcao, comprimento, raio, n_folhas=2, semente=0):
    """Galho fino com folhas na ponta (detalhe da folha: ombro, antebraco, joelho, topo)."""
    rnd = random.Random(semente)
    o, d = Vector(origem), Vector(direcao).normalized()
    fim_g = o + d * comprimento
    p = [tubo(nome, [o, o + d * comprimento * 0.55 + Vector((0, 0, 0.1 * comprimento)), fim_g],
              [raio, raio * 0.75, raio * 0.45], TRONCO, lados=4)]
    for i in range(n_folhas):
        desvio = Vector((rnd.uniform(-0.6, 0.6), rnd.uniform(-0.4, 0.4), rnd.uniform(0.2, 0.9)))
        dir_f = (d + desvio * (0.5 + 0.5 * i)).normalized()
        base_f = fim_g - d * comprimento * 0.25 * i
        p.append(folha(f"{nome}Folha{i}", base_f, base_f + dir_f * comprimento * 0.75, comprimento * 0.42,
                       (0, -1, 0.3), COPA_CLARA if i == 0 else COPA, espessura=comprimento * 0.05))
    return p


def perna(s):
    """Perna fina e comprida que abre para fora e termina num pe de raizes
    (folha: cada pe tem 0,20 da altura de largura, com 5 raizes)."""
    nome = "E" if s < 0 else "D"
    quadril = Vector((s * QUADRIL_X, 0.0, QUADRIL_Z))
    joelho = Vector((s * JOELHO_X, -0.25, JOELHO_Z))
    tornozelo = Vector((s * PE_X, 0.0, TORNOZELO_Z))
    pts = [quadril + Vector((0, 0, 0.6)), quadril.lerp(joelho, 0.5), joelho, joelho.lerp(tornozelo, 0.55),
           tornozelo, Vector((s * PE_X, 0.0, 0.75))]
    p = [lapidar(tubo(f"Perna{nome}", pts, [1.0, 0.92, 0.85, 0.9, 1.3, 2.0], TRONCO, lados=7), 0.07, 11 + s)]
    centro = Vector((s * PE_X, 0.0, 0.0))
    # 7a rodada: base cheia do pe (o tronco se abre em saia ate o chao, mais
    # comprida para a frente), para o pe nao ser "palitos" visto de lado.
    saia = []
    for i in range(8):
        a = 2 * math.pi * i / 8
        d = Vector((math.cos(a), math.sin(a), 0))
        alcance = 2.0 + (0.75 if d.y < -0.3 else 0.0) - (0.25 if d.y > 0.3 else 0.0)
        saia.append(centro + d * 1.25 + Vector((0, 0, 2.7)))
        saia.append(centro + d * alcance * 0.72 + Vector((0, 0, 1.0)))
        saia.append(centro + d * alcance + Vector((0, 0, 0.04)))
    p.append(lapidar(casco(f"PeBase{nome}", saia, TRONCO), 0.06, 15 + s))
    # raizes do pe: 3 na frente, 1 de cada lado e 1 atras, cada uma um tubo que afina
    for i, (ang, comp) in enumerate(((-90, 3.6), (-90 + s * 48, 3.4), (-90 - s * 42, 3.1), (-90 + s * 100, 2.9), (-90 - s * 105, 2.3), (90, 2.2))):
        a = math.radians(ang)
        d = Vector((math.cos(a), math.sin(a), 0))
        mat = TRONCO if i % 2 == 0 else TRONCO_ESCURO
        p.append(lapidar(tubo(f"Raiz{nome}{i}", [centro + d * 0.3 + Vector((0, 0, 1.25)), centro + d * comp * 0.5 + Vector((0, 0, 0.62)),
                                                  centro + d * comp + Vector((0, 0, 0.16))],
                              [1.2, 0.85, 0.32], mat, lados=5), 0.05, 20 + i + s))
    # musgo da canela (folha): placa deitada que sobe do pe em ponta, abracando
    # a canela por fora e pela frente
    madeira = list(p)
    if s < 0:
        p.append(placa_musgo(f"MusgoCanela{nome}", madeira, joelho.lerp(tornozelo, 0.3), centro + Vector((s * 0.3, -0.2, 0.9)),
                             (s * 0.8, -0.6, 0), 160, MUSGO, contorno=(0.1, 0.4, 0.7, 0.95, 1.0, 0.7), colunas=5, semente=100))
    else:
        p.append(placa_musgo(f"MusgoCanela{nome}", madeira, joelho.lerp(tornozelo, 0.45), centro + Vector((0.0, -0.3, 0.9)),
                             (s * 0.25, -1, 0), 145, MUSGO_CLARO, contorno=(0.1, 0.45, 0.8, 1.0, 0.7), colunas=5, semente=101))
    return p


def tronco_e_bracos():
    p = {"Tronco": [], "BracoE": [], "BracoD": [], "MaoE": [], "MaoD": []}
    # Tronco em V: cintura fina, peito largo (folha: ombros com 0,27 da altura).
    # 7a rodada: de lado o peito vai para a frente e a barriga tem volume
    # (desvio em Y por anel), em vez do perfil reto de tabua.
    perfil = [(1.45, QUADRIL_Z - 1.3), (1.8, QUADRIL_Z - 0.2), (1.6, CINTURA_Z - 0.6), (1.3, CINTURA_Z + 0.2), (1.75, CINTURA_Z + 1.9),
              (2.55, PEITO_Z), (2.95, OMBRO_Z - 0.2), (2.5, OMBRO_Z + 0.5), (1.6, PESCOCO_Z)]
    desvio = [0.0, -0.1, -0.4, -0.15, -0.3, -0.6, -0.4, -0.15, 0.0]
    tronco = torno("Tronco", [(r, z) for r, z in perfil], TRONCO, lados=8, achatar=0.72, ruido=0.07, semente=3, desvio=desvio)
    p["Tronco"].append(tronco)
    # peitoral talhado (o "V" claro do peito da folha): escudo que salta para a frente
    y_peito = -0.6 - 2.55 * 0.72
    peitoral = lapidar(casco("Peitoral", [(-2.0, y_peito + 0.45, OMBRO_Z - 0.3), (2.0, y_peito + 0.45, OMBRO_Z - 0.3),
                                          (-1.6, y_peito - 0.16, PEITO_Z - 0.2), (1.6, y_peito - 0.16, PEITO_Z - 0.2),
                                          (0.0, y_peito - 0.24, PEITO_Z + 0.5), (0.0, y_peito - 0.1, PEITO_Z - 1.6),
                                          (-0.9, y_peito + 0.35, CINTURA_Z + 1.5), (0.9, y_peito + 0.35, CINTURA_Z + 1.5),
                                          (-1.6, y_peito + 1.3, PEITO_Z), (1.6, y_peito + 1.3, PEITO_Z)], TRONCO_CLARO), 0.05, 5)
    p["Tronco"].append(peitoral)
    ombros = {}
    bracos = {}
    for s, nome in ((-1, "E"), (1, "D")):
        ombro = Vector((s * OMBRO_X, 0.0, OMBRO_Z - 0.2))
        cotovelo = Vector((s * COTOVELO_X, -0.2, COTOVELO_Z))
        pulso = Vector((s * PULSO_X, -0.5, PULSO_Z))
        bracos[nome] = (ombro, pulso)
        ombros[s] = lapidar(icosfera(f"Ombro{nome}", ombro, (1.05, 0.95, 0.95), TRONCO), 0.06, 30 + s)
        p[f"Braco{nome}"].append(ombros[s])
        # Braco fino no ombro que engrossa muito no antebraco (folha: de 0,05
        # para 0,13 da altura de largura) e entra na luva sem degrau: o ultimo
        # anel tem o tamanho do punho da luva.
        # O ultimo anel passa do pulso e afina DENTRO da luva: a ponta do
        # antebraco some na palma em vez de terminar em tampa (o degrau).
        pts = [ombro, ombro.lerp(cotovelo, 0.5), cotovelo, cotovelo.lerp(pulso, 0.35), cotovelo.lerp(pulso, 0.72), pulso,
               pulso + (pulso - cotovelo).normalized() * 0.9]
        braco = lapidar(tubo(f"Braco{nome}", pts, [0.72, 0.82, 0.98, 1.3, 1.5, 1.46, 1.05], TRONCO, lados=8), 0.05, 40 + s)
        p[f"Braco{nome}"].append(braco)
        luva = mao(nome, pulso, cotovelo, s)
        p[f"Mao{nome}"].append(luva)
        # musgo do antebraco: placa comprida deitada por fora, abracando o braco
        # (na folha, um braco tem a faixa inteira e o outro so perto da mao)
        if s < 0:
            p[f"Braco{nome}"].append(placa_musgo(f"MusgoBraco{nome}", [braco, luva], cotovelo.lerp(ombro, 0.1), pulso + (pulso - cotovelo) * 0.12,
                                                 (s, -0.45, 0), 205, MUSGO, contorno=(0.4, 0.8, 1.0, 1.0, 0.85, 0.35), colunas=5, semente=110))
            p[f"Braco{nome}"] += galhinho("GalhoBraco", cotovelo + Vector((s * 0.5, 0, -0.6)), (s * 0.8, -0.1, 0.7), 1.9, 0.2, semente=4)
        else:
            p[f"Braco{nome}"].append(placa_musgo(f"MusgoBraco{nome}", [braco, luva], cotovelo.lerp(pulso, 0.42), pulso + Vector((0, 0, -1.7)),
                                                 (s, -0.3, 0), 175, MUSGO_CLARO, contorno=(0.3, 0.9, 1.0, 0.8, 0.3), colunas=5, semente=111))
            p[f"Braco{nome}"].append(placa_musgo(f"MusgoBraco{nome}Tras", [braco], cotovelo.lerp(pulso, 0.02), cotovelo.lerp(pulso, 0.55),
                                                 (s * 0.6, 1, 0), 120, MUSGO, contorno=(0.3, 1.0, 0.8, 0.25), colunas=3, semente=112))
    madeira = [tronco, peitoral, ombros[-1], ombros[1]]
    # manto de musgo deitado por cima do ombro (grande num, pequeno no outro)
    x = -(OMBRO_X - 0.55)
    p["Tronco"].append(placa_musgo("MusgoOmbroE", madeira, (x, -2.5, OMBRO_Z - 0.4), (x, 2.3, OMBRO_Z - 0.4), (-0.45, 0, 1), 215, MUSGO,
                                   contorno=(0.45, 0.95, 1.0, 1.0, 0.55), colunas=5, esp=0.3, semente=120))
    x = OMBRO_X - 0.45
    p["Tronco"].append(placa_musgo("MusgoOmbroD", madeira, (x, -1.9, OMBRO_Z - 0.3), (x, 1.6, OMBRO_Z - 0.3), (0.6, 0, 1), 140, MUSGO_CLARO,
                                   contorno=(0.4, 1.0, 0.9, 0.4), colunas=4, semente=121))
    # manto da frente (folha): cobre a frente do ombro e desce em diagonal
    # ate o meio do peito, em duas placas de tons diferentes
    p["Tronco"].append(placa_musgo("MusgoPeito", madeira, (0, -0.3, OMBRO_Z + 0.9), (0, -0.3, PEITO_Z - 1.5), (-1, -0.8, 0), 122, MUSGO,
                                   contorno=(0.75, 1.0, 0.9, 0.6, 0.16), colunas=5, torcer=-34, esp=0.3, semente=130))
    p["Tronco"].append(placa_musgo("MusgoPeitoPonta", madeira, (0, -0.3, PEITO_Z + 0.4), (0, -0.3, CINTURA_Z + 1.9), (-0.45, -1, 0), 60, MUSGO_CLARO,
                                   contorno=(0.5, 1.0, 0.7, 0.15), colunas=3, torcer=-22, esp=0.42, semente=132))
    # e a ponta do manto caindo pelas costas
    p["Tronco"].append(placa_musgo("MusgoCostas", madeira, (0, 0, OMBRO_Z + 0.2), (0, 0, PEITO_Z - 2.4), (-0.75, 1, 0), 85, MUSGO,
                                   contorno=(1.0, 0.9, 0.6, 0.15), colunas=4, semente=131))
    p["Tronco"] += galhinho("GalhoOmbro", (OMBRO_X - 0.3, 0.2, OMBRO_Z + 0.4), (0.6, 0, 0.8), 1.7, 0.2, semente=7)
    # saiote de musgo: cinta fechada em volta do quadril e folhas largas e
    # gordas penduradas nela (a do meio da frente e a mais comprida, como na folha)
    p["Tronco"].append(torno("SaioteCinta", [(1.45, QUADRIL_Z + 1.0), (2.0, QUADRIL_Z + 0.55), (2.12, QUADRIL_Z - 0.35), (1.6, QUADRIL_Z - 0.9)],
                             MUSGO, lados=8, achatar=0.74, ruido=0.08, semente=140, desvio=[-0.25, -0.2, -0.1, -0.05]))
    for i in range(8):
        a = -math.pi / 2 + 2 * math.pi * i / 8
        d = Vector((math.cos(a), math.sin(a) * 0.72, 0))
        topo = d * 1.95 + Vector((0, -0.12, QUADRIL_Z + 0.45))
        ponta = d * 2.1 + Vector((0, -0.1, QUADRIL_Z - (2.1 if i == 0 else 1.75 if i % 2 == 0 else 1.35)))
        p["Tronco"].append(folha(f"Saiote{i}", topo, ponta, 2.3, d, MUSGO_CLARO if i % 2 == 0 else MUSGO, espessura=0.42, barriga=0.38))
    return p, bracos


def mao(nome, pulso, cotovelo, s):
    """Maozona em LUVA UNICA (7a rodada; o critico reprovou "pilha de caixotes
    e toquinhos soltos"): punho que continua o antebraco sem degrau, palma que
    alarga ate os nos dos dedos, 3 dedos grossos por fora que descem em curva
    e fecham para dentro, e o polegar por dentro, oposto (garra em C da
    folha). Tudo e fundido numa malha so. A ponta dos dedos fica a uns 9% da
    altura, acima do pe."""
    partes = []
    sobe = (cotovelo - pulso).normalized()
    # punho e palma: raio em Y; em X fica 1,22 vez mais largo (mao chata de
    # frente). Afunila do punho para os nos dos dedos.
    partes.append(tubo(f"LuvaPalma{nome}", [pulso + sobe * 1.2, pulso, pulso + Vector((s * 0.08, -0.05, -0.9)), pulso + Vector((s * 0.1, -0.1, -1.75))],
                       [1.05, 1.38, 1.38, 1.16], TRONCO, lados=10, achatar=1.15))
    for i, (dy, k) in enumerate(((-0.72, 0.93), (0.0, 1.0), (0.72, 0.9))):
        b = pulso + Vector((s * 0.6, dy - 0.1, -1.45))
        partes.append(tubo(f"LuvaDedo{nome}{i}", [b, b + Vector((s * 0.25, dy * 0.06, -0.85 * k)), b + Vector((s * 0.3, dy * 0.1, -1.6 * k)),
                                                  b + Vector((s * 0.08, dy * 0.12, -2.15 * k)), b + Vector((-s * 0.42, dy * 0.12, -2.45 * k))],
                           [0.72, 0.7, 0.63, 0.52, 0.34], TRONCO, lados=8))
    b = pulso + Vector((-s * 0.95, -0.45, -0.85))
    partes.append(tubo(f"LuvaPolegar{nome}", [b, b + Vector((-s * 0.35, -0.05, -0.8)), b + Vector((-s * 0.32, -0.1, -1.5)),
                                              b + Vector((s * 0.12, -0.1, -1.95))],
                       [0.7, 0.66, 0.56, 0.36], TRONCO, lados=8))
    return fundir(partes, f"Luva{nome}", TRONCO, voxel=0.15, triangulos=340)


def cabeca_e_rosto():
    """A cabeca e a continuacao do tronco (folha): o rosto e talhado na
    madeira, com olhos amarelos acesos e sorriso calmo."""
    p = []
    perfil = [(1.55, PESCOCO_Z - 0.5), (1.3, PESCOCO_Z + 0.5), (1.22, OLHOS_Z - 0.6), (1.28, OLHOS_Z + 0.5), (1.05, OLHOS_Z + 1.7), (0.7, TOPO_TRONCO_Z)]
    p.append(torno("Cabeca", perfil, ROSTO, lados=8, achatar=0.9, ruido=0.05, semente=8))
    frente = -1.16
    # nariz curto em quilha (sem a quilha comprida, que junto das palpebras
    # dava cara de bravo)
    p.append(folha("Nariz", (0, frente - 0.02, OLHOS_Z + 0.25), (0, frente - 0.16, OLHOS_Z - 0.55), 0.38, (0, -1, 0), TRONCO_CLARO, espessura=0.14, barriga=0.7))
    for s in (-1, 1):
        # 7a rodada: olho em MEIA-LUA CHEIA (reta em cima, barriga para baixo),
        # com um ponto de brilho; antes era um risco fino que sumia na sombra
        # da copa. O canto de fora cai um pouco (manso, sonolento).
        c = Vector((s * 0.56, frente - 0.1, OLHOS_Z + 0.08))
        pts = []
        for ang in (0, 28, 58, 90, 122, 152, 180):
            x = 0.41 * math.cos(math.radians(ang))
            z = -0.36 * math.sin(math.radians(ang)) - 0.07 * s * x / 0.41
            pts.append(c + Vector((x, 0.03 * abs(x), z)))
            pts.append(c + Vector((x * 0.9, 0.42, z)))
        pts.append(c + Vector((0, -0.05, -0.16)))
        p.append(casco(f"Olho{s}", pts, OLHO))
        b = c + Vector((-s * 0.13, -0.07, -0.1))
        p.append(casco(f"Brilho{s}", [b + Vector((0.09, 0, 0)), b + Vector((-0.09, 0, 0)), b + Vector((0, 0, 0.07)),
                                      b + Vector((0, 0, -0.07)), b + Vector((0, 0.1, 0))], OLHO_BRILHO))
        # palpebra fina e reta por cima (sono, nao raiva)
        p.append(folha(f"Palpebra{s}", c + Vector((s * 0.5, -0.02, 0.0)), c + Vector((-s * 0.46, -0.04, 0.09)), 0.16, (0, -1, 0.5), TRONCO, espessura=0.07))
    # sorriso largo e calmo: arco para cima nas pontas
    p.append(tubo("Sorriso", [(-0.6, frente + 0.05, OLHOS_Z - 0.75), (-0.32, frente - 0.05, OLHOS_Z - 0.98), (0.0, frente - 0.08, OLHOS_Z - 1.05),
                              (0.32, frente - 0.05, OLHOS_Z - 0.98), (0.6, frente + 0.05, OLHOS_Z - 0.75)], 0.065, BOCA, lados=4))
    # galhos que saem do pescoco e somem dentro da copa
    for i, (ang, comp) in enumerate(((20, 4.3), (160, 4.3), (-150, 3.2), (-30, 3.2), (90, 3.6))):
        a = math.radians(ang)
        d = Vector((math.cos(a), math.sin(a), 0))
        o = Vector((0, 0, OLHOS_Z + 0.6)) + d * 0.9
        p.append(lapidar(tubo(f"GalhoCopa{i}", [o, o + d * comp * 0.5 + Vector((0, 0, 0.5)), o + d * comp + Vector((0, 0, 1.6))],
                              [0.5, 0.36, 0.2], TRONCO if i % 2 else TRONCO_ESCURO, lados=5), 0.04, 80 + i))
    return p


def copa():
    """Copa larga em cachos facetados (folha: 0,47 da altura de largura, bem
    mais larga que os ombros), aberta na frente para o rosto aparecer."""
    p = []
    c = Vector((0, 0.3, COPA_Z))
    rnd = random.Random(21)
    blocos = []
    # anel de fora, sem cacho na frente do rosto (frente = -90 graus)
    for ang in (-28, 18, 62, 108, 150, 195, -152):
        a = math.radians(ang)
        blocos.append((Vector((math.cos(a) * 4.8, math.sin(a) * 3.4, rnd.uniform(-1.1, -0.3))), rnd.uniform(2.5, 2.9)))
    # miolo de cima e o cacho da frente, mais alto (sombra na testa)
    blocos += [(Vector((-2.2, -1.6, 1.5)), 2.7), (Vector((2.3, -1.4, 1.3)), 2.6), (Vector((0.1, 1.6, 1.8)), 2.8),
               (Vector((0.2, -0.8, 2.6)), 2.5)]
    mats = [COPA, COPA_CLARA, COPA, COPA_ESCURA, COPA, COPA_CLARA, COPA_ESCURA, COPA_CLARA, COPA, COPA, COPA_CLARA]
    for i, (pos, r) in enumerate(blocos):
        o = icosfera(f"Copa{i}", c + pos, (r, r * 0.95, r * 0.88), mats[i % len(mats)], subdiv=1,
                     rot=(rnd.uniform(0, 3), rnd.uniform(0, 3), rnd.uniform(0, 3)))
        p.append(lapidar(o, 0.16, 90 + i))
    # galho com folhas espetado no topo (lado direito da folha)
    p += galhinho("GalhoTopo", c + Vector((2.2, 0.0, 3.2)), (0.45, 0, 1.0), 2.6, 0.26, n_folhas=3, semente=2)
    return p, c


def ninho(centro_copa):
    """Ninho com passarinho em cima da copa, do lado esquerdo da folha.
    7a rodada (critico: "tampa de panela com bolha cinza"): tigela com borda
    TRANCADA (duas voltas de gravetos cruzados, claro e escuro), passaro de
    corpo azul claro, peito branco e bico laranja."""
    p = []
    k = 1.4
    base_ninho = centro_copa + Vector((-2.5, -2.2, 3.15))
    p.append(torno("Ninho", [(0.5 * k, 0.0), (0.92 * k, 0.2 * k), (1.0 * k, 0.46 * k), (0.72 * k, 0.4 * k)], NINHO, lados=8,
                   ruido=0.08, semente=99, centro=tuple(base_ninho)))
    n = 8
    for volta, (sobe, mat) in enumerate(((1, NINHO_CLARO), (-1, NINHO))):
        for i in range(n):
            a0 = 2 * math.pi * (i + 0.5 * volta) / n
            pts = []
            for f in (-0.55, 0.0, 0.55):
                a = a0 + f * 2 * math.pi / n * 1.25
                r = (1.0 + (0.1 if f == 0 else 0.0)) * k
                pts.append(base_ninho + Vector((math.cos(a) * r, math.sin(a) * r, (0.45 + sobe * f * 0.32) * k)))
            p.append(tubo(f"NinhoTranca{volta}_{i}", pts, [0.1 * k, 0.14 * k, 0.1 * k], mat, lados=3))
    corpo = base_ninho + Vector((0.05, 0.0, 0.4 * k + 0.5))
    p.append(esfera("PassaroCorpo", corpo, (0.56, 0.68, 0.54), PASSARO, seg=6, aneis=4))
    p.append(esfera("PassaroPeito", corpo + Vector((0, -0.26, -0.08)), (0.44, 0.48, 0.44), PASSARO_BARRIGA, seg=6, aneis=4))
    cabeca = corpo + Vector((0, -0.4, 0.6))
    p.append(esfera("PassaroCabeca", cabeca, (0.37, 0.37, 0.35), PASSARO, seg=6, aneis=4))
    p.append(casco("PassaroBico", [cabeca + Vector((0, -0.72, -0.02)), cabeca + Vector((0.13, -0.3, -0.08)),
                                   cabeca + Vector((-0.13, -0.3, -0.08)), cabeca + Vector((0, -0.3, 0.1))], PASSARO_BICO))
    for s in (-1, 1):
        o = cabeca + Vector((s * 0.3, -0.2, 0.08))
        p.append(casco(f"PassaroOlho{s}", [o + Vector((s * 0.06, 0, 0)), o + Vector((0, -0.05, 0.05)), o + Vector((0, 0.05, 0.03)),
                                           o + Vector((0, 0, -0.06))], PASSARO_OLHO))
    p.append(folha("PassaroRabo", corpo + Vector((0, 0.35, 0.05)), corpo + Vector((0, 0.95, 0.4)), 0.34, (0, 0, 1), PASSARO, espessura=0.06))
    return p


# ---------------------------------------------------------------- esqueleto
def prender(objs, arm, osso):
    bpy.context.view_layer.update()
    for o in objs:
        mw = o.matrix_world.copy()
        o.parent = arm
        o.parent_type = "BONE"
        o.parent_bone = osso
        o.matrix_world = mw


def montar_tudo():
    pernas_p = {}
    for s, nome in ((-1, "E"), (1, "D")):
        pernas_p[nome] = perna(s)
    p_tronco_bracos, bracos = tronco_e_bracos()
    p_cabeca = cabeca_e_rosto()
    p_copa, centro_copa = copa()
    p_ninho = ninho(centro_copa)

    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = nomear(bpy.context.active_object, "GiganteEsqueleto")
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    raiz = eb[0]
    raiz.name = "Raiz"
    raiz.head, raiz.tail = (0, 0, 0), (0, 0, 0.6)

    def osso(nm, h, t, pai):
        b = eb.new(nm)
        b.head, b.tail = h, t
        b.parent = eb[pai]
        b.roll = 0
        return b

    osso("Quadril", (0, 0, QUADRIL_Z), (0, 0, CINTURA_Z), "Raiz")
    osso("Tronco", (0, 0, CINTURA_Z), (0, 0, OMBRO_Z), "Quadril")
    osso("Cabeca", (0, 0, PESCOCO_Z), (0, 0, OLHOS_Z + 1.0), "Tronco")
    osso("Copa", (0, 0, OLHOS_Z + 1.0), (0, 0, OLHOS_Z + 3.0), "Cabeca")
    for nome in ("E", "D"):
        ombro, pulso = bracos[nome]
        osso(f"Braco{nome}", tuple(ombro), tuple(pulso), "Tronco")
        osso(f"Mao{nome}", tuple(pulso), tuple(pulso + Vector((0, -0.7, -0.4))), f"Braco{nome}")
    for nome, sx in (("E", -1), ("D", 1)):
        osso(f"Perna{nome}", (sx * QUADRIL_X, 0, QUADRIL_Z), (sx * PE_X, 0, TORNOZELO_Z), "Quadril")
    bpy.ops.object.mode_set(mode="OBJECT")

    prender(p_tronco_bracos["Tronco"], arm, "Quadril")
    prender(p_cabeca, arm, "Cabeca")
    prender(p_copa + p_ninho, arm, "Copa")
    for nome in ("E", "D"):
        prender(p_tronco_bracos[f"Braco{nome}"], arm, f"Braco{nome}")
        prender(p_tronco_bracos[f"Mao{nome}"], arm, f"Mao{nome}")
        prender(pernas_p[nome], arm, f"Perna{nome}")
    # O musgo vai junto com a peca em que esta grudado (antebraco, canela,
    # ombro), entao acompanha o braco e a perna no andar.

    todas = [o for o in bpy.data.objects if o.type == "MESH"]
    print("TRIANGULOS_GIGANTE", base.contar_triangulos(todas))
    return arm


# ---------------------------------------------------------------- pose e animacao
def pose(arm, **rot):
    for b in arm.pose.bones:
        b.rotation_mode = "XYZ"
        b.rotation_euler = (0, 0, 0)
        b.location = (0, 0, 0)
    for k, v in rot.items():
        if k.startswith("loc_"):
            arm.pose.bones[k[4:]].location = v
        else:
            r = [math.radians(a) for a in v]
            arm.pose.bones[k].rotation_euler = r


POSES = {
    "neutra": {},
    "andando_a": {"PernaE": (-28, 0, 0), "PernaD": (24, 0, 0), "BracoE": (18, 0, 0), "BracoD": (-16, 0, 0),
                  "Tronco": (5, 0, 3), "Cabeca": (-3, 0, -2), "Copa": (-4, 0, 2), "loc_Raiz": (0, 0, -0.18)},
    "andando_b": {"PernaE": (24, 0, 0), "PernaD": (-28, 0, 0), "BracoE": (-16, 0, 0), "BracoD": (18, 0, 0),
                  "Tronco": (5, 0, -3), "Cabeca": (-3, 0, 2), "Copa": (-4, 0, -2), "loc_Raiz": (0, 0, -0.18)},
    "andando_meio": {"loc_Raiz": (0, 0, 0.0), "Tronco": (2, 0, 0)},
}


def gravar(arm, nome, quadros, acoes):
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


def animar(arm):
    cena = bpy.context.scene
    cena.render.fps = 24
    if not arm.animation_data:
        arm.animation_data_create()
    acoes = {}
    # Parado (3 s, bem lento - e uma arvore): respira, copa e bracos balancam
    # devagar e com atraso, como peso de madeira pesada.
    quadros = []
    for f in range(0, 73, 6):
        fase = 2 * math.pi * f / 72
        quadros.append((f + 1, {
            "Tronco": (1.2 * math.sin(fase), 0, 0.6 * math.sin(fase * 0.7)),
            "Cabeca": (-1.0 * math.sin(fase - 0.5), 0, 0),
            "Copa": (-2.0 * math.sin(fase - 1.0), 0, 1.5 * math.sin(fase * 0.5)),
            "BracoE": (0.6 * math.sin(fase), 0, -1.5 * math.sin(fase - 0.3)),
            "BracoD": (0.6 * math.sin(fase + 0.4), 0, 1.5 * math.sin(fase + 0.1)),
            "loc_Raiz": (0, 0, -0.03 * (1 - math.cos(fase)) / 2),
        }))
    gravar(arm, "Parado", quadros, acoes)
    # Andar (passo lento e pesado, cadencia de gigante): 2 extremos + 2 meios,
    # braco oposto a perna, tronco e copa seguindo com atraso (peso de madeira).
    gravar(arm, "Andar", [(1, POSES["andando_a"]), (13, POSES["andando_meio"]), (25, POSES["andando_b"]),
                          (37, POSES["andando_meio"]), (49, POSES["andando_a"])], acoes)
    return acoes


# ---------------------------------------------------------------- render e export
def palco():
    cena = bpy.context.scene
    mundo = bpy.data.worlds.new("Cinza")
    cena.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = base.cor("#6e6e72")
    mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    bpy.ops.object.empty_add(location=(0, 0, 0))
    rig = nomear(bpy.context.active_object, "RigLuz")
    bpy.ops.object.light_add(type="SUN", location=(10, -20, 30))
    sol = bpy.context.active_object
    sol.data.energy = 3.4
    sol.data.angle = math.radians(20)
    sol.rotation_euler = (math.radians(45), 0, math.radians(25))
    sol.parent = rig
    bpy.ops.object.light_add(type="AREA", location=(-8, -8, 12))
    f = bpy.context.active_object
    f.data.energy = 400
    f.data.size = 10
    f.data.color = base.cor("#e6e0ff")[:3]
    f.rotation_euler = (math.radians(60), 0, math.radians(-45))
    f.parent = rig
    return rig


def camera_em(pos, alvo, lente=50):
    bpy.ops.object.camera_add(location=pos)
    cam = bpy.context.active_object
    cam.data.lens = lente
    cam.rotation_euler = (Vector(alvo) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


def principal():
    base.limpar_cena()
    criar_materiais()
    if MODO == "exportar":
        arm = montar_tudo()
        animar(arm)
        pose(arm, **POSES["neutra"])
        base.exportar_glb(SAIDA + ".glb", [arm], animacoes=True)
        return
    arm = montar_tudo()
    rig = palco()
    alvo = (0, 0, 10.0)
    for nome, pos, giro in [("frente", (0, -40, 11), 0), ("lado", (40, 0, 11), 90), ("costas", (0, 40, 11), 180)]:
        pose(arm, **POSES["neutra"])
        rig.rotation_euler = (0, 0, math.radians(giro))
        camera_em(pos, alvo, lente=35)
        base.renderizar(f"{SAIDA}_{nome}.png", largura=700, altura=1100, amostras=48)


if __name__ == "__main__":
    principal()
