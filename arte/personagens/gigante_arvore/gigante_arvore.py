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

# Alturas em metros, medidas pela folha (silhueta: pernas ~50% da altura,
# tronco curto, cabeca+copa ocupando o resto; bracos retos e um pouco
# abaixo da cintura na 2a versao da folha, nao mais ate o joelho).
PE_Z = 0.0
TORNOZELO_Z = 1.0
JOELHO_Z = 6.8
QUADRIL_Z = 12.8
CINTURA_Z = 14.2
PEITO_Z = 16.6
OMBRO_Z = 18.0
PESCOCO_Z = 18.8
QUEIXO_Z = 19.3
TOPO_CABECA_Z = 20.3
PULSO_Z = 10.2            # braco reto e curto (folha v2): maos perto do quadril, nao do joelho

MEIA_LARGURA_QUADRIL = 2.1
MEIA_LARGURA_CINTURA = 1.55
MEIA_LARGURA_PEITO = 2.3
MEIA_LARGURA_OMBRO = 3.0
SEPARACAO_PERNAS = 2.3     # distancia do centro a cada quadril (postura bem aberta, como a folha)


def criar_materiais():
    global TRONCO, TRONCO_CLARO, TRONCO_ESCURO, MUSGO, MUSGO_CLARO, COPA, COPA_CLARA, COPA_ESCURA
    global OLHO, BOCA, NINHO, PASSARO, PASSARO_BICO
    TRONCO = base.material("Tronco", "#4a2e18", rugosidade=0.88)
    TRONCO_CLARO = base.material("TroncoClaro", "#6b4423", rugosidade=0.82)
    TRONCO_ESCURO = base.material("TroncoEscuro", "#2e1b0e", rugosidade=0.9)
    MUSGO = base.material("Musgo", "#6fae3a", rugosidade=0.85)
    MUSGO_CLARO = base.material("MusgoClaro", "#8bc653", rugosidade=0.8)
    COPA = base.material("Copa", "#4f8a2e", rugosidade=0.8)
    COPA_CLARA = base.material("CopaClara", "#74b847", rugosidade=0.75)
    COPA_ESCURA = base.material("CopaEscura", "#386019", rugosidade=0.85)
    # Olhos suaves (folha v2: "menos acesos, mais serenos" - emissao baixa,
    # licao do mago: emissao alta + glow do jogo estourava a cor).
    OLHO = base.material("Olho", "#3a2410", rugosidade=0.9, emissao="#ffcf7a", forca=0.35)
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


# ---------------------------------------------------------------- pecas
def perna(lado):
    """Perna facetada com pe meio-raiz (2 "dedos-raiz" grossos se abrindo),
    como na folha. lado: -1 esquerda (+X no Blender, que vira direita no
    jogo... aqui so interessa simetria, a árvore nao tem "mao do cajado")."""
    s = lado
    # Quadril bem afastado do centro e pe ainda mais aberto (postura estavel
    # de gigante, como a folha); perna fica mais grossa (coxa 1.9->1.95
    # contra os antigos 1.55, para nao ficar "fina" perto do tronco largo).
    x_quadril = s * SEPARACAO_PERNAS
    x_pe = s * (SEPARACAO_PERNAS + 0.9)
    p = []
    p.append(torno(f"Coxa{s}", [(1.95, QUADRIL_Z), (1.55, 9.6), (1.25, JOELHO_Z)], TRONCO, lados=8,
                    centro=(x_quadril, 0, 0), ruido=0.05, semente=10 + s))
    p.append(torno(f"Canela{s}", [(1.25, JOELHO_Z + 0.3), (1.05, 3.6), (0.85, TORNOZELO_Z)], TRONCO_CLARO, lados=8,
                    centro=(x_pe, 0, 0), ruido=0.05, semente=20 + s))
    # Pe: base larga achatada (sola) de onde saem 2 raizes-dedo grossas, uma
    # para a frente e outra ligeiramente de lado, como a folha (vista de
    # perfil mostra 1 clara + 1 atras).
    p.append(torno(f"PeBase{s}", [(0.85, TORNOZELO_Z), (1.3, 0.5), (1.45, 0.15)], TRONCO_ESCURO, lados=8,
                    centro=(x_pe, 0, 0), ruido=0.06, semente=30 + s))
    for k, (dx, dy, comp) in enumerate(((0.4, -1.7, 2.1), (-0.6, -1.0, 1.7))):
        base_pt = Vector((x_pe, 0, 0.6))
        ponta = base_pt + Vector((dx, dy, -0.5))
        p.append(tubo(f"PeDedo{s}_{k}", [base_pt, base_pt + (ponta - base_pt) * 0.5, ponta],
                       [0.68, 0.55, 0.3], TRONCO_ESCURO, lados=6))
    return p


def tronco_e_bracos():
    """Tronco (quadril->ombro) e os 2 bracos retos e curtos, com maos de
    dedos grossos na ponta (folha v2: bracos nao alcancam mais o joelho)."""
    p = {}
    p["Tronco"] = [torno("TroncoCorpo", [(MEIA_LARGURA_QUADRIL, QUADRIL_Z), (MEIA_LARGURA_CINTURA, CINTURA_Z),
                                         (MEIA_LARGURA_PEITO, PEITO_Z), (MEIA_LARGURA_PEITO * 0.92, OMBRO_Z)],
                         TRONCO, lados=10, achatar=0.82, ruido=0.045, semente=1)]
    # Pescoco curto, mesma casca.
    p["Tronco"].append(torno("Pescoco", [(MEIA_LARGURA_PEITO * 0.92, OMBRO_Z), (1.15, PESCOCO_Z)], TRONCO,
                             lados=10, achatar=0.85, ruido=0.03, semente=2))

    bracos = {}
    for s, nome in ((-1, "E"), (1, "D")):
        ombro = Vector((s * MEIA_LARGURA_OMBRO, 0, OMBRO_Z))
        # Braco reto (folha v2: "bracos mais retos"), descendo quase na
        # vertical ate perto da cintura, com um leve chegamento ao corpo
        # (a folha nao mostra um "T" aberto, o cotovelo fica mais perto).
        pulso = Vector((s * (MEIA_LARGURA_OMBRO - 0.15), -0.1, PULSO_Z))
        eixo = pulso - ombro
        giro = Vector((0, 0, 1)).rotation_difference(eixo.normalized()).to_matrix().to_4x4()
        braco_o = torno(f"Braco{nome}", [(1.15, 0.0), (0.95, eixo.length * 0.55), (0.78, eixo.length)], TRONCO,
                        lados=8, ruido=0.05, semente=40 + s)
        braco_o.matrix_world = Matrix.Translation(ombro) @ giro
        mao = mao_grossa(f"Mao{nome}", pulso, eixo.normalized(), Vector((0, 0, 1)), s)
        p[f"Braco{nome}"] = [braco_o]
        p[f"Mao{nome}"] = mao
        bracos[nome] = (ombro, pulso)
    return p, bracos


def mao_grossa(prefixo, pulso, frente, cima, lado_sinal):
    """Mao sem ossos de dedo: punho largo e 4 "toquinhos" grossos em leque,
    rigidos (giram juntos com a mao - pedido: "maos de dedos grossos",
    sem precisar de articulacao fina, ja que a arvore so anda)."""
    f = Vector(frente).normalized()
    c = Vector(cima) - f * Vector(cima).dot(f)
    c.normalize()
    l = f.cross(c).normalized() * lado_sinal
    centro = Vector(pulso) + f * 0.45
    p = [casco(f"{prefixo}Punho", [centro + f * ex * 0.45 + l * math.cos(a) * 0.82 + c * math.sin(a) * 0.65
                                   for ex in (-1, 1) for a in (0, 1.26, 2.51, 3.77, 5.03)], TRONCO_CLARO)]
    for i in range(4):
        t = (i - 1.5) / 1.5
        base_dedo = centro + f * 0.4 + l * t * 0.72
        direcao = (f * 1.1 + l * t * 0.6 - c * 0.2).normalized()
        meio = base_dedo + direcao * 0.75
        ponta = meio + direcao * 0.6
        p.append(tubo(f"{prefixo}Dedo{i}", [base_dedo, meio, ponta], [0.4, 0.36, 0.18], TRONCO_CLARO, lados=6))
    return p


def cabeca_e_rosto():
    p = []
    centro = Vector((0, 0, QUEIXO_Z + (TOPO_CABECA_Z - QUEIXO_Z) * 0.5))
    p.append(esfera("Cabeca", centro, (1.35, 1.25, (TOPO_CABECA_Z - QUEIXO_Z) / 2 + 0.15), TRONCO, seg=9, aneis=7))
    # Olhos: ovais deitados, suaves (folha v2), levados um pouco para a
    # frente para nao sumir dentro da cabeca facetada.
    for s in (-1, 1):
        p.append(esfera(f"Olho{s}", (s * 0.55, -1.15, centro.z + 0.15), (0.3, 0.1, 0.17), OLHO, seg=7, aneis=5))
    # Boca em V curvo (sorriso calmo, folha v2) - feita com um tubo fino
    # curvado em vez de reta, para ler como sorriso de longe.
    pts_boca = [Vector((-0.6, -1.1, centro.z - 0.5)), Vector((-0.25, -1.24, centro.z - 0.72)),
                Vector((0.0, -1.28, centro.z - 0.8)), Vector((0.25, -1.24, centro.z - 0.72)),
                Vector((0.6, -1.1, centro.z - 0.5))]
    p.append(tubo("Boca", pts_boca, 0.14, BOCA, lados=6, fechar=False))
    return p


def copa():
    """Copa de blocos facetados (icosferas de poucos lados), em cacho acima
    e ao redor do topo da cabeca, como a folha (nao cobre o rosto)."""
    p = []
    rnd = random.Random(7)
    centro_copa = Vector((0, 0.1, TOPO_CABECA_Z + 1.6))
    posicoes = [
        (-1.7, 0.3, 0.2, 1.7), (1.7, 0.3, 0.2, 1.7), (0.0, -0.2, 0.9, 1.55),
        (-1.0, 0.6, -0.3, 1.45), (1.0, 0.6, -0.3, 1.45), (0.0, 0.8, 1.3, 1.4),
        (-0.5, -0.1, 1.7, 1.25), (0.5, -0.1, 1.7, 1.25), (0.0, 0.3, 2.5, 1.15),
        (-2.0, 0.9, -0.9, 1.1), (2.0, 0.9, -0.9, 1.1),
    ]
    for i, (dx, dy, dz, r) in enumerate(posicoes):
        subdiv = 1 if r > 1.5 else 0
        centro = centro_copa + Vector((dx, dy, dz))
        cor = (COPA, COPA_CLARA, COPA_ESCURA)[rnd.randint(0, 2)]
        p.append(icosfera(f"Copa{i}", centro, (r, r, r), cor, subdiv=subdiv,
                          rot=(rnd.uniform(0, math.pi), rnd.uniform(0, math.pi), rnd.uniform(0, math.pi))))
    # Um galho fino com 2 folhas saindo do topo (como a folha mostra).
    topo = centro_copa + Vector((0.3, -0.2, 2.6))
    p.append(tubo("GalhoTopo", [centro_copa + Vector((0, 0, 1.8)), topo], [0.09, 0.03], TRONCO, lados=5))
    for k, d in enumerate(((0.35, -0.1, 0.3), (-0.15, 0.25, 0.4))):
        p.append(casco(f"FolhaTopo{k}", [topo, topo + Vector(d) + Vector((0, 0, -0.05)),
                                         topo + Vector(d) * 0.5 + Vector((0, 0, 0.2))], COPA_CLARA))
    return p, centro_copa


def ninho(centro_copa):
    """Detalhe pequeno e barato (folha v2): ninho com um passarinho no topo
    da copa. Poucos triangulos (menos de 40 ao todo); se um dia pesar,
    e o primeiro candidato a cortar (nao e o foco do personagem)."""
    p = []
    base_ninho = centro_copa + Vector((1.1, 0.5, 2.0))
    p.append(torno("Ninho", [(0.55, 0.0), (0.62, 0.1), (0.5, 0.22)], NINHO, lados=8, fechar=(True, False),
                   ruido=0.12, semente=99, centro=tuple(base_ninho)))
    corpo_passaro = base_ninho + Vector((0.0, 0.0, 0.3))
    p.append(esfera("PassaroCorpo", corpo_passaro, (0.22, 0.26, 0.2), PASSARO, seg=6, aneis=5))
    p.append(esfera("PassaroCabeca", corpo_passaro + Vector((0, -0.22, 0.12)), (0.13, 0.13, 0.13), PASSARO, seg=6, aneis=5))
    p.append(casco("PassaroBico", [corpo_passaro + Vector((0, -0.34, 0.1)), corpo_passaro + Vector((0.04, -0.3, 0.08)),
                                   corpo_passaro + Vector((-0.04, -0.3, 0.08)), corpo_passaro + Vector((0, -0.3, 0.14))], PASSARO_BICO))
    return p


def musgo_manchas(pernas_pos):
    """Manchas de musgo so onde a folha mostra: peito, coxas e antebracos -
    nao cobre o corpo inteiro (pedido do Vitor)."""
    p = []
    p.append(mancha_musgo("MusgoPeito", (0, -MEIA_LARGURA_PEITO * 0.78, PEITO_Z - 0.3), (0, -1, 0.15), (0, 0, 1),
                          1.6, 2.0, MUSGO))
    p.append(mancha_musgo("MusgoOmbroE", (-MEIA_LARGURA_PEITO * 0.5, -MEIA_LARGURA_PEITO * 0.55, OMBRO_Z - 0.4),
                          (-0.6, -0.7, 0.2), (0, 0, 1), 1.1, 1.3, MUSGO_CLARO))
    for nome, x in pernas_pos:
        sinal = -1.0 if x < 0 else 1.0
        p.append(mancha_musgo(f"MusgoCoxa{nome}", (x, -1.75, QUADRIL_Z - 1.2), (0, -1, 0.1), (0, 0, 1), 2.1, 3.2, MUSGO))
        p.append(mancha_musgo(f"MusgoCoxaLado{nome}", (x + sinal * 1.5, -0.3, 9.0), (sinal * 0.8, -0.3, 0.1), (0, 0, 1), 1.5, 2.2, MUSGO_CLARO))
    for s in (-1, 1):
        p.append(mancha_musgo(f"MusgoBraco{s}", (s * (MEIA_LARGURA_OMBRO + 0.15), -0.3, 13.5), (s * 0.5, -0.8, 0.1),
                              (s * 0.3, 0, 1), 1.0, 1.5, MUSGO))
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
    p_musgo = musgo_manchas([("E", -SEPARACAO_PERNAS), ("D", SEPARACAO_PERNAS)])

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
    osso("Cabeca", (0, 0, PESCOCO_Z), (0, 0, TOPO_CABECA_Z), "Tronco")
    osso("Copa", (0, 0, TOPO_CABECA_Z), (0, 0, TOPO_CABECA_Z + 2.0), "Cabeca")
    for nome in ("E", "D"):
        ombro, pulso = bracos[nome]
        osso(f"Braco{nome}", tuple(ombro), tuple(pulso), "Tronco")
        osso(f"Mao{nome}", tuple(pulso), tuple(pulso + Vector((0, -0.7, -0.4))), f"Braco{nome}")
    for nome, x in (("E", -SEPARACAO_PERNAS), ("D", SEPARACAO_PERNAS)):
        osso(f"Perna{nome}", (x, 0, QUADRIL_Z), (x, 0, TORNOZELO_Z), "Quadril")
    bpy.ops.object.mode_set(mode="OBJECT")

    prender(p_tronco_bracos["Tronco"], arm, "Quadril")
    prender(p_cabeca, arm, "Cabeca")
    prender(p_copa + p_ninho, arm, "Copa")
    for nome in ("E", "D"):
        prender(p_tronco_bracos[f"Braco{nome}"], arm, f"Braco{nome}")
        prender(p_tronco_bracos[f"Mao{nome}"], arm, f"Mao{nome}")
        prender(pernas_p[nome], arm, f"Perna{nome}")
    prender(p_musgo, arm, "Quadril")  # musgo do peito/braco gruda no bloco rigido do tronco (simples: nao segue braco/perna)

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
