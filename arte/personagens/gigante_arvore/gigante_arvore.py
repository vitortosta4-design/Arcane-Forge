"""Gigante da arvore do Arcane Forge (piloto ADR-047), modelado pela folha do
Vitor (docs/referencias/gigante_arvore.png, 2a versao: sorriso calmo em V,
olhos com brilho suave, bracos retos e curtos, ninho pequeno no topo da copa).

Humanoide de casca e galhos: tronco e membros facetados, copa de blocos
facetados (icosferas), musgo so nas manchas da folha (peito, coxas,
antebracos), maos como aglomerados de dedos grossos (sem ossos por dedo:
giram em bloco com a mao), pes meio-raiz. Rosto simples e tranquilo.

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
    global OLHO, BOCA, NINHO, PASSARO, PASSARO_BICO
    TRONCO = base.material("Tronco", "#97633a", rugosidade=0.88)
    TRONCO_CLARO = base.material("TroncoClaro", "#b47a48", rugosidade=0.82)
    TRONCO_ESCURO = base.material("TroncoEscuro", "#724629", rugosidade=0.9)
    MUSGO = base.material("Musgo", "#74ac34", rugosidade=0.85)
    MUSGO_CLARO = base.material("MusgoClaro", "#8fc43f", rugosidade=0.8)
    COPA = base.material("Copa", "#68a030", rugosidade=0.8)
    COPA_CLARA = base.material("CopaClara", "#86c13a", rugosidade=0.75)
    COPA_ESCURA = base.material("CopaEscura", "#4f8527", rugosidade=0.85)
    # Olhos suaves (folha v2: "menos acesos, mais serenos" - emissao baixa,
    # licao do mago: emissao alta + glow do jogo estourava a cor).
    OLHO = base.material("Olho", "#ffd23a", rugosidade=0.6, emissao="#ffc21a", forca=1.6)
    BOCA = base.material("Boca", "#2e1b0e", rugosidade=0.9)
    NINHO = base.material("Ninho", "#8a5a2e", rugosidade=0.9)
    PASSARO = base.material("Passaro", "#cfe6f2", rugosidade=0.6)
    PASSARO_BICO = base.material("PassaroBico", "#e8a93c", rugosidade=0.5)


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


def torno(nome, perfil, mat, lados=8, achatar=1.0, fechar=(True, True), centro=(0, 0, 0), ruido=0.0, semente=0):
    """Gira um perfil (raio, z) em volta de Z. ruido mexe cada vertice (casca lapidada)."""
    rnd = random.Random(semente)
    bm = bmesh.new()
    aneis = []
    for r, z in perfil:
        anel = []
        for i in range(lados):
            a = 2 * math.pi * i / lados
            rr = r * (1 + rnd.uniform(-ruido, ruido))
            anel.append(bm.verts.new((centro[0] + rr * math.cos(a),
                                      centro[1] + rr * math.sin(a) * achatar,
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


def deformar(o, func):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        v.co = func(v.co.copy())
    bm.to_mesh(o.data)
    bm.free()


# ---------------------------------------------------------------- pecas (6a rodada)
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
    return lapidar(o, min(escala) * 0.35, semente)


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
    p = [lapidar(tubo(f"Perna{nome}", pts, [0.95, 0.88, 0.74, 0.62, 0.8, 1.35], TRONCO, lados=7), 0.07, 11 + s)]
    # raizes do pe: 3 na frente, 1 de cada lado e 1 atras, cada uma um tubo que afina
    centro = Vector((s * PE_X, 0.0, 0.0))
    for i, (ang, comp) in enumerate(((-90, 3.6), (-90 + s * 48, 3.4), (-90 - s * 42, 3.1), (-90 + s * 100, 2.9), (-90 - s * 105, 2.3), (90, 2.2))):
        a = math.radians(ang)
        d = Vector((math.cos(a), math.sin(a), 0))
        mat = TRONCO if i % 2 == 0 else TRONCO_ESCURO
        p.append(lapidar(tubo(f"Raiz{nome}{i}", [centro + d * 0.3 + Vector((0, 0, 1.25)), centro + d * comp * 0.5 + Vector((0, 0, 0.62)),
                                                  centro + d * comp + Vector((0, 0, 0.16))],
                              [0.85, 0.62, 0.24], mat, lados=5), 0.05, 20 + i + s))
    # musgo da canela (folha: placa que sobe do pe pelo lado de fora e pela frente)
    canela = joelho.lerp(tornozelo, 0.7)
    p.append(tufo(f"MusgoCanela{nome}A", canela + Vector((s * 0.45, -0.4, 0.1)), (0.75, 0.7, 1.9), MUSGO, 100 + s))
    p.append(tufo(f"MusgoCanela{nome}B", canela + Vector((s * 0.7, 0.1, -1.3)), (0.8, 0.85, 1.3), MUSGO_CLARO, 102 + s))
    p.append(tufo(f"MusgoCanela{nome}C", canela + Vector((-s * 0.1, -0.6, -1.5)), (0.7, 0.6, 1.0), MUSGO, 104 + s))
    return p


def tronco_e_bracos():
    p = {"Tronco": [], "BracoE": [], "BracoD": [], "MaoE": [], "MaoD": []}
    # Tronco em V: cintura fina, peito largo (folha: ombros com 0,27 da altura).
    perfil = [(1.45, QUADRIL_Z - 1.3), (1.8, QUADRIL_Z - 0.2), (1.5, CINTURA_Z - 0.6), (1.3, CINTURA_Z), (1.75, CINTURA_Z + 1.9),
              (2.55, PEITO_Z), (2.95, OMBRO_Z - 0.2), (2.5, OMBRO_Z + 0.5), (1.6, PESCOCO_Z)]
    p["Tronco"].append(torno("Tronco", [(r, z) for r, z in perfil], TRONCO, lados=8, achatar=0.62, ruido=0.07, semente=3))
    # veio claro no peito (o "V" talhado da folha) e sombra do umbigo
    bracos = {}
    for s, nome in ((-1, "E"), (1, "D")):
        ombro = Vector((s * OMBRO_X, 0.0, OMBRO_Z - 0.2))
        cotovelo = Vector((s * COTOVELO_X, -0.2, COTOVELO_Z))
        pulso = Vector((s * PULSO_X, -0.5, PULSO_Z))
        bracos[nome] = (ombro, pulso)
        p[f"Braco{nome}"].append(lapidar(icosfera(f"Ombro{nome}", ombro, (1.05, 0.95, 0.95), TRONCO), 0.06, 30 + s))
        # Braco fino no ombro que engrossa muito no antebraco (folha: de 0,05
        # para 0,13 da altura de largura).
        pts = [ombro, ombro.lerp(cotovelo, 0.5), cotovelo, cotovelo.lerp(pulso, 0.35), cotovelo.lerp(pulso, 0.72), pulso]
        p[f"Braco{nome}"].append(lapidar(tubo(f"Braco{nome}", pts, [0.72, 0.62, 0.72, 1.2, 1.62, 1.5], TRONCO, lados=7), 0.08, 40 + s))
        # musgo do antebraco: placas grossas do lado de fora
        ante = cotovelo.lerp(pulso, 0.5)
        p[f"Braco{nome}"].append(tufo(f"MusgoBraco{nome}A", ante + Vector((s * 1.05, -0.2, 0.9)), (0.75, 1.0, 2.0), MUSGO, 110 + s))
        p[f"Braco{nome}"].append(tufo(f"MusgoBraco{nome}B", ante + Vector((s * 1.35, 0.3, -1.3)), (0.8, 1.15, 1.7), MUSGO_CLARO, 112 + s))
        p[f"Braco{nome}"].append(tufo(f"MusgoBraco{nome}C", ante + Vector((s * 0.9, -0.9, -0.6)), (0.7, 0.6, 1.3), MUSGO, 114 + s))
        if s < 0:
            p[f"Braco{nome}"] += galhinho("GalhoBraco", cotovelo + Vector((s * 0.5, 0, -0.6)), (s * 0.8, -0.1, 0.7), 1.9, 0.2, semente=4)
        p[f"Mao{nome}"] += mao(nome, pulso, s)
    # ombreira de musgo: grande num ombro, descendo pelo peito; menor no outro
    for s, tam in ((-1, 1.0), (1, 0.7)):
        o = Vector((s * (OMBRO_X - 0.3), -0.2, OMBRO_Z + 0.35))
        p["Tronco"].append(tufo(f"MusgoOmbro{s}A", o + Vector((s * 0.3, 0, 0.25)), (1.7 * tam, 1.25, 0.8), MUSGO, 120 + s))
        p["Tronco"].append(tufo(f"MusgoOmbro{s}B", o + Vector((-s * 1.2 * tam, -0.75, -0.9 * tam)), (1.25 * tam, 0.7, 1.5 * tam), MUSGO_CLARO, 122 + s))
        p["Tronco"].append(tufo(f"MusgoOmbro{s}C", o + Vector((s * 0.2, 0.9, -0.5)), (1.4 * tam, 0.7, 1.2 * tam), MUSGO, 124 + s))
        p["Tronco"].append(folha(f"MusgoOmbro{s}D", o + Vector((-s * 1.3 * tam, -1.0, -1.2 * tam)), o + Vector((-s * 2.1 * tam, -1.25, -4.0 * tam)), 1.7 * tam,
                                 (0, -1, 0.2), MUSGO, espessura=0.4, barriga=0.3))
    p["Tronco"] += galhinho("GalhoOmbro", (OMBRO_X - 0.3, 0.2, OMBRO_Z + 0.4), (0.6, 0, 0.8), 1.7, 0.2, semente=7)
    # saiote de musgo: tufos em ponta pendurados em volta do quadril
    for i in range(8):
        a = 2 * math.pi * i / 8 + 0.2
        d = Vector((math.cos(a), math.sin(a) * 0.62, 0))
        topo = d * 1.75 + Vector((0, 0, QUADRIL_Z + 0.5))
        ponta = d * 2.05 + Vector((0, 0, QUADRIL_Z - (2.7 if i % 2 == 0 else 2.0)))
        p["Tronco"].append(folha(f"Saiote{i}", topo, ponta, 2.5, d, MUSGO if i % 2 == 0 else MUSGO_CLARO, espessura=0.55, barriga=0.3))
    return p, bracos


def mao(nome, pulso, s):
    """Maozona: palma em bloco e 3 dedos grossos mais o polegar, meio fechados
    (folha: a ponta dos dedos fica a uns 9% da altura, acima do pe)."""
    p = []
    palma = pulso + Vector((0, -0.1, -1.5))
    # palma: comeca dentro do antebraco (sem vao no pulso) e alarga para baixo
    pts = []
    for dx in (-1.0, 1.0):
        for dy in (-0.8, 0.8):
            pts.append(palma + Vector((dx * 1.2, dy * 1.1, 2.1)))
            pts.append(palma + Vector((dx * 1.6, dy * 1.15, 0.2)))
            pts.append(palma + Vector((dx * 1.45, dy, -0.95)))
    p.append(lapidar(casco(f"Palma{nome}", pts, TRONCO), 0.08, 50 + s))
    # dedos: saem da base da palma, descem e fecham para a frente
    for i, dx in enumerate((-0.95, 0.0, 0.95)):
        b = palma + Vector((dx, -0.15, -0.8))
        p.append(lapidar(tubo(f"Dedo{nome}{i}", [b, b + Vector((dx * 0.12, -0.35, -1.1)), b + Vector((dx * 0.1, -0.2, -2.0 - 0.15 * (1 - abs(dx)))),
                                                 b + Vector((0, 0.35, -2.5))],
                              [0.52, 0.5, 0.42, 0.26], TRONCO_CLARO if i == 1 else TRONCO, lados=5), 0.04, 60 + i + s))
    # polegar do lado de dentro (virado para o corpo)
    b = palma + Vector((-s * 1.3, -0.35, 0.1))
    p.append(lapidar(tubo(f"Polegar{nome}", [b, b + Vector((-s * 0.45, -0.35, -0.9)), b + Vector((-s * 0.25, -0.2, -1.9))],
                          [0.5, 0.46, 0.26], TRONCO, lados=5), 0.04, 70 + s))
    return p


def cabeca_e_rosto():
    """A cabeca e a continuacao do tronco (folha): o rosto e talhado na
    madeira, com olhos amarelos acesos e sorriso calmo."""
    p = []
    perfil = [(1.55, PESCOCO_Z - 0.5), (1.3, PESCOCO_Z + 0.5), (1.22, OLHOS_Z - 0.6), (1.28, OLHOS_Z + 0.5), (1.05, OLHOS_Z + 1.7), (0.7, TOPO_TRONCO_Z)]
    p.append(torno("Cabeca", perfil, TRONCO, lados=8, achatar=0.9, ruido=0.05, semente=8))
    frente = -1.16
    # sobrancelha/testa talhada e nariz em quilha (da volume ao rosto)
    p.append(folha("Testa", (0, frente - 0.02, OLHOS_Z + 1.3), (0, frente - 0.12, OLHOS_Z - 1.1), 0.5, (0, -1, 0), TRONCO_CLARO, espessura=0.16, barriga=0.55))
    for s in (-1, 1):
        # olho amendoado inclinado (calmo), aceso
        c = Vector((s * 0.52, frente + 0.03, OLHOS_Z))
        p.append(casco(f"Olho{s}", [c + Vector((s * 0.34, 0.05, 0.1)), c + Vector((-s * 0.3, -0.02, -0.06)), c + Vector((0, -0.09, 0.13)),
                                    c + Vector((0, -0.09, -0.1)), c + Vector((0, 0.1, 0))], OLHO))
        p.append(folha(f"Palpebra{s}", c + Vector((s * 0.46, -0.06, 0.24)), c + Vector((-s * 0.38, -0.1, 0.13)), 0.2, (0, -1, 0.4), TRONCO_ESCURO, espessura=0.07))
    # sorriso: arco fino e escuro
    p.append(tubo("Sorriso", [(-0.46, frente + 0.02, OLHOS_Z - 0.82), (-0.2, frente - 0.06, OLHOS_Z - 0.98), (0.2, frente - 0.06, OLHOS_Z - 0.98),
                              (0.46, frente + 0.02, OLHOS_Z - 0.82)], 0.06, BOCA, lados=4))
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
    """Ninho com passarinho em cima da copa, do lado esquerdo da folha e bem
    a vista (na folha ele tem uns 3 m de largura; antes era minusculo e
    ficava escondido atras dos cachos)."""
    p = []
    k = 2.3
    base_ninho = centro_copa + Vector((-2.3, -1.9, 3.3))
    p.append(torno("Ninho", [(0.55 * k, 0.0), (0.66 * k, 0.12 * k), (0.52 * k, 0.26 * k)], NINHO, lados=8, fechar=(True, False),
                   ruido=0.12, semente=99, centro=tuple(base_ninho)))
    corpo_passaro = base_ninho + Vector((0.0, 0.0, 0.34 * k))
    p.append(esfera("PassaroCorpo", corpo_passaro, (0.22 * k, 0.26 * k, 0.2 * k), PASSARO, seg=6, aneis=5))
    p.append(esfera("PassaroCabeca", corpo_passaro + Vector((0, -0.22, 0.12)) * k, (0.13 * k,) * 3, PASSARO, seg=6, aneis=5))
    p.append(casco("PassaroBico", [corpo_passaro + Vector((0, -0.36, 0.1)) * k, corpo_passaro + Vector((0.04, -0.3, 0.08)) * k,
                                   corpo_passaro + Vector((-0.04, -0.3, 0.08)) * k, corpo_passaro + Vector((0, -0.3, 0.14)) * k], PASSARO_BICO))
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
