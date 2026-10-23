"""Mago do Arcane Forge, versão 2 (23/10/2026), modelado pela folha do Vitor
(docs/referencias/mago_folha_vitor.png), seguindo-a peça por peça.

Parte do mago do piloto (arte/piloto-modelagem/scripts/mago.py) e corrige o
que a comparação com a folha mostrou: aba do chapéu lisa e fina, faixa sem
tachas, barra do casaco sem zigue-zague, alça e bolsas fracas, mangas finas e
luvas pequenas sem dedos que mexem.

~1 m de altura com o chapéu (o jogo aumenta por igual para os olhos ficarem
na altura da câmera). Peças rígidas presas aos ossos (padrão low poly do
projeto). Cada dedo da luva tem dois ossos, para o jogo animar os dedinhos.

Saídas:
  mago.glb     corpo inteiro: Parado, Andar, Conjurar, ErguerCajado, Dano
  mago_1p.glb  braços de primeira pessoa (mesmas luvas): Parado1P, Conjurar1P

Uso: python mago.py -- SAIDA vistas|poses|maos|exportar
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
SAIDA = args[0] if args else "/tmp/mago"
MODO = args[1] if len(args) > 1 else "vistas"

DEDOS = ("Indicador", "Medio", "Anelar", "Minimo")


def criar_materiais():
    global AZUL, AZUL_ESC, AZUL_CLARO, BEGE, COURO, COURO_ESC, LUVA, ROSTO, OLHO, CRISTAL, CALCA, MADEIRA, CABELO, DOURADO
    # Paleta tirada dos quadradinhos da folha (canto superior esquerdo).
    AZUL = base.material("MantoAzul", "#2a3bb8", rugosidade=0.8)
    AZUL_ESC = base.material("MantoAzulEscuro", "#1b2478", rugosidade=0.85)
    AZUL_CLARO = base.material("MantoAzulClaro", "#3447cc", rugosidade=0.8)
    BEGE = base.material("Acabamento", "#e0a462", rugosidade=0.7)
    COURO = base.material("Couro", "#7b4a2e", rugosidade=0.75)
    COURO_ESC = base.material("CouroEscuro", "#4c2b1b", rugosidade=0.8)
    LUVA = base.material("Luva", "#a26a42", rugosidade=0.75)
    ROSTO = base.material("RostoSombra", "#3a2416", rugosidade=0.9)
    OLHO = base.material("Olho", "#000000", rugosidade=1.0, emissao="#ff7414", forca=0.9)
    CRISTAL = base.material("Cristal", "#3fc4ff", rugosidade=0.2, emissao="#36b8ff", forca=2.4)
    CALCA = base.material("Calca", "#262043", rugosidade=0.85)
    MADEIRA = base.material("Madeira", "#6b412b", rugosidade=0.8)
    CABELO = base.material("Cabelo", "#6a3c24", rugosidade=0.85)
    DOURADO = base.material("Fivela", "#d9a24f", rugosidade=0.4, metal=0.6)


# ---------------------------------------------------------------- utilitários
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


def torno(nome, perfil, mat, lados=10, achatar=1.0, fechar=(True, True), centro=(0, 0, 0), ruido=0.0, semente=0):
    """Gira um perfil (raio, z) em volta de Z. achatar < 1 afina na profundidade (Y).
    ruido mexe cada vértice um pouco (faceta "lapidada" da folha)."""
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
                                      centro[2] + z + rnd.uniform(-ruido, ruido) * 0.15 * r)))
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


def deformar(o, func):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for v in bm.verts:
        v.co = func(v.co.copy())
    bm.to_mesh(o.data)
    bm.free()


def tubo(nome, pontos, raio, mat, lados=6, achatar=1.0):
    """Tubo seguindo uma lista de pontos (cajado, alças, dedos)."""
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
        r = raio * (1.0 if i % 2 else 0.78)
        pts.append(Vector((math.cos(a) * r, math.sin(a) * r, alto * (0.06 if i % 2 else -0.04))))
    o = casco(nome, pts, mat)
    o.location = centro
    return o


def triangulo_na_superficie(nome, centro, normal, cima, largura, altura, mat, espessura=0.006):
    """Triângulo bege "pintado em relevo" sobre uma superfície (barra, aba)."""
    n = Vector(normal).normalized()
    u = Vector(cima).normalized()
    lado = u.cross(n).normalized()
    c = Vector(centro)
    pts = [c - lado * largura / 2, c + lado * largura / 2, c + u * altura,
           c - lado * largura / 2 + n * espessura, c + lado * largura / 2 + n * espessura, c + u * altura + n * espessura]
    return casco(nome, pts, mat)


# ---------------------------------------------------------------- peças
def chapeu():
    p = []
    # Aba larga e grossa, caindo nas laterais e na frente, com facetas
    # irregulares (folha: aba "mole" de chapéu de feiticeiro).
    aba = torno("ChapeuAba", [(0.0, 0.0), (0.18, 0.004), (0.34, -0.036), (0.43, -0.07), (0.43, -0.09),
                              (0.34, -0.06), (0.18, -0.022), (0.0, -0.02)], AZUL, lados=16, ruido=0.0, semente=11)

    def cair(c):
        r = math.hypot(c.x, c.y)
        a = math.atan2(c.y, c.x)
        # cai mais nas laterais e um pouco na frente; atrás fica mais reta
        queda = 0.06 * (r / 0.43) ** 2 * (0.7 + 0.4 * math.cos(2 * a) + 0.25 * math.sin(a))
        return Vector((c.x, c.y, c.z - queda))
    deformar(aba, cair)
    aba.location = (0, 0, 0.705)
    p.append(aba)
    # Faixa bege fina perto da beirada de cima da aba (folha: acabamento bege
    # na borda). Mesma queda da aba, um pouco acima dela.
    borda = torno("ChapeuAbaBorda", [(0.36, -0.03), (0.4, -0.055)], BEGE, lados=16, fechar=(False, False))
    m = borda.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.006
    deformar(borda, lambda c: cair(c) + Vector((0, 0, 0.012)))
    borda.location = (0, 0, 0.705)
    p.append(borda)
    # Copa cônica facetada, com a ponta torta para o lado e para trás.
    copa = torno("ChapeuCopa", [(0.19, 0.0), (0.18, 0.09), (0.148, 0.2), (0.108, 0.3), (0.07, 0.38), (0.036, 0.44),
                                (0.009, 0.485)], AZUL, lados=9, ruido=0.05, semente=5)

    def entortar(c):
        t = max(0.0, c.z - 0.19) / 0.295
        c.x += 0.22 * t ** 2.0
        c.y += 0.06 * t ** 2
        c.z -= 0.11 * t ** 3
        return c
    deformar(copa, entortar)
    copa.location = (0, 0, 0.705)
    p.append(copa)
    # Faixa bege larga, com tachas escuras e losango dourado na frente.
    faixa = torno("ChapeuFaixa", [(0.196, 0.0), (0.188, 0.075)], BEGE, lados=9, fechar=(False, False))
    m = faixa.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.014
    faixa.location = (0, 0, 0.71)
    p.append(faixa)
    p.append(casco("ChapeuLosango", [Vector(v) for v in ((0, -0.198, 0.775), (0.034, -0.198, 0.748), (0, -0.198, 0.721),
                                                          (-0.034, -0.198, 0.748), (0, -0.178, 0.748))], DOURADO))
    for k, a in enumerate((-0.75, 0.75, -1.6, 1.6, 2.4, -2.4, 3.14)):
        p.append(caixa(f"ChapeuTacha{k}", (math.sin(a) * 0.19, -math.cos(a) * 0.19, 0.748), (0.032, 0.014, 0.034),
                       COURO, rot=(0, 0, a)))
    return p


def cabeca():
    p = []
    p.append(esfera("Rosto", (0, -0.01, 0.575), (0.158, 0.15, 0.15), ROSTO, seg=10, aneis=7))
    for s in (-1, 1):
        # olhos grandes, ovais em pé (folha)
        p.append(esfera(f"Olho{s}", (s * 0.056, -0.152, 0.592), (0.032, 0.014, 0.052), OLHO, seg=8, aneis=6))
        # tufos de cabelo castanho saindo por baixo do chapéu
        for k in range(3):
            p.append(casco(f"Cabelo{s}{k}", [Vector(v) for v in (
                (s * (0.1 + k * 0.016), -0.075 + k * 0.045, 0.635), (s * (0.135 + k * 0.012), -0.05 + k * 0.045, 0.615),
                (s * (0.14 + k * 0.01), -0.06 + k * 0.045, 0.53 - k * 0.012), (s * (0.118 + k * 0.016), -0.03 + k * 0.045, 0.62))], CABELO))
    # Cachecol grosso que cobre queixo e boca, com dobra na frente.
    gola = torno("Cachecol", [(0.11, 0.0), (0.155, 0.018), (0.165, 0.06), (0.146, 0.095), (0.118, 0.105)], AZUL,
                 lados=11, fechar=(False, False), ruido=0.03, semente=3)
    gola.location = (0, -0.005, 0.43)
    p.append(gola)
    p.append(casco("CachecolFrente", [Vector(v) for v in (
        (-0.12, -0.13, 0.525), (0.12, -0.13, 0.525), (-0.135, -0.12, 0.45), (0.135, -0.12, 0.45),
        (-0.1, -0.09, 0.53), (0.1, -0.09, 0.53), (0, -0.165, 0.49), (0, -0.15, 0.53))], AZUL))
    # ponta do cachecol caindo nas costas
    p.append(casco("CachecolPonta", [Vector(v) for v in (
        (0.02, 0.12, 0.49), (0.09, 0.115, 0.49), (0.03, 0.15, 0.38), (0.1, 0.14, 0.4), (0.06, 0.16, 0.33))], AZUL_ESC))
    return p


def corpo():
    p = []
    # Casaco em sino, mais longo e aberto na barra (folha: quase até as botas).
    manto = torno("Manto", [(0.13, 0.46), (0.162, 0.4), (0.19, 0.3), (0.228, 0.2), (0.262, 0.13), (0.268, 0.115)],
                  AZUL, lados=12, achatar=0.84, ruido=0.02, semente=7)
    p.append(manto)
    # Barra bege com zigue-zague de triângulos subindo (folha).
    barra = torno("MantoBarra", [(0.27, 0.105), (0.268, 0.15)], BEGE, lados=12, achatar=0.85, fechar=(False, False))
    m = barra.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.012
    p.append(barra)
    for k in range(12):
        a = 2 * math.pi * (k + 0.5) / 12
        if abs(math.sin(a) + 1) < 0.05:
            continue
        x, y = math.cos(a) * 0.272, math.sin(a) * 0.272 * 0.85
        n = Vector((math.cos(a), math.sin(a) * 0.85, 0.15)).normalized()
        p.append(triangulo_na_superficie(f"MantoZigue{k}", (x, y, 0.148), n, (0, 0, 1), 0.06, 0.05, BEGE))
    # Abertura da frente: forro escuro e acabamento bege dos dois lados.
    for s in (-1, 1):
        p.append(tubo(f"FrenteAcab{s}", [(s * 0.012, -0.165, 0.4), (s * 0.03, -0.18, 0.27), (s * 0.065, -0.205, 0.18),
                                         (s * 0.095, -0.225, 0.12)], 0.026, BEGE, lados=4))
    p.append(casco("FrenteFenda", [Vector(v) for v in ((-0.085, -0.222, 0.12), (0.085, -0.222, 0.12), (0, -0.185, 0.26),
                                                       (0, -0.17, 0.12))], AZUL_ESC))
    # Capinha nos ombros com bicos e borda bege (folha: capelete pontudo).
    capa = torno("Capinha", [(0.118, 0.475), (0.168, 0.43), (0.2, 0.37), (0.205, 0.355)], AZUL_CLARO, lados=12,
                 achatar=0.86, fechar=(False, False))
    m = capa.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.016
    p.append(capa)
    for k in range(10):
        a = 2 * math.pi * k / 10
        if abs(a - 4.71) < 0.3:   # sem bico bem no meio da frente
            continue
        x, y = math.cos(a) * 0.206, math.sin(a) * 0.206 * 0.86
        n = Vector((math.cos(a), math.sin(a) * 0.86, -0.3)).normalized()
        p.append(triangulo_na_superficie(f"CapinhaBico{k}", (x, y, 0.37), n, (0, 0, -1), 0.06, 0.032, AZUL_CLARO, espessura=0.01))
        p.append(triangulo_na_superficie(f"CapinhaBorda{k}", (x * 1.01, y * 1.01, 0.366), n, (0, 0, -1), 0.045, 0.022, BEGE,
                                         espessura=0.006))
    # Broche de losango na gola.
    p.append(casco("Broche", [Vector(v) for v in ((0, -0.175, 0.44), (0.04, -0.175, 0.4), (0, -0.175, 0.36),
                                                  (-0.04, -0.175, 0.4), (0, -0.15, 0.4))], DOURADO))
    # Alça cruzada do ombro esquerdo à bolsa direita, com fivela.
    p.append(tubo("Alca", [(-0.13, -0.11, 0.43), (-0.07, -0.158, 0.38), (0.03, -0.17, 0.32), (0.13, -0.142, 0.26)],
                  0.03, COURO, lados=4, achatar=0.45))
    p.append(caixa("AlcaFivela", (-0.045, -0.166, 0.365), (0.03, 0.01, 0.028), DOURADO, rot=(0, 0.6, 0)))
    # Cinto largo com fivela grande.
    cinto = torno("Cinto", [(0.172, 0.27), (0.178, 0.31)], COURO, lados=12, achatar=0.84, fechar=(False, False))
    m = cinto.modifiers.new("esp", "SOLIDIFY")
    m.thickness = 0.016
    p.append(cinto)
    p.append(caixa("Fivela", (0, -0.158, 0.29), (0.055, 0.014, 0.045), DOURADO, chanfro=0.005))
    p.append(caixa("FivelaMiolo", (0, -0.166, 0.29), (0.03, 0.006, 0.022), COURO_ESC))
    # Duas bolsas grandes na frente, com tampa e botão.
    for s in (-1, 1):
        cx = s * 0.13
        p.append(caixa(f"Bolsa{s}", (cx, -0.15, 0.225), (0.105, 0.058, 0.1), COURO, chanfro=0.012))
        p.append(caixa(f"BolsaTampa{s}", (cx, -0.181, 0.256), (0.11, 0.016, 0.046), COURO_ESC, chanfro=0.004))
        p.append(caixa(f"BolsaBotao{s}", (cx, -0.191, 0.24), (0.02, 0.01, 0.024), DOURADO))
    # Bolsinha de lado, atrás (costas da folha).
    p.append(caixa("BolsaCostas", (0.0, 0.15, 0.24), (0.1, 0.045, 0.075), COURO, chanfro=0.008))
    p.append(caixa("BolsaCostasLosango", (0.0, 0.175, 0.245), (0.018, 0.006, 0.026), AZUL_CLARO, rot=(0, 0.78, 0)))
    # Pernas curtas e botas robustas com dobra bege no cano.
    pernas = {}
    for s, nome in ((-1, "E"), (1, "D")):
        x = s * 0.068
        perna = torno(f"Perna{nome}", [(0.04, 0.05), (0.046, 0.15)], CALCA, lados=8, centro=(x, 0, 0))
        bota = casco(f"Bota{nome}", [Vector(v) for v in (
            (x - 0.056, -0.11, 0.0), (x + 0.056, -0.11, 0.0), (x - 0.056, 0.058, 0.0), (x + 0.056, 0.058, 0.0),
            (x - 0.05, -0.1, 0.05), (x + 0.05, -0.1, 0.05), (x - 0.055, 0.052, 0.09), (x + 0.055, 0.052, 0.09),
            (x - 0.05, -0.025, 0.09), (x + 0.05, -0.025, 0.09))], COURO)
        sola = caixa(f"BotaSola{nome}", (x, -0.026, 0.008), (0.116, 0.172, 0.016), COURO_ESC)
        cano = torno(f"BotaCano{nome}", [(0.058, 0.075), (0.062, 0.105)], COURO_ESC, lados=8, centro=(x, 0, 0))
        pernas[nome] = [perna, bota, sola, cano]
    return p, pernas


# ---------------------------------------------------------------- luva com dedos
def luva(prefixo, pulso, frente, cima, lado, escala=1.0, abertura=1.0, curva=0.25):
    """Luva de couro fofinha: palma gordinha, 4 dedos curtos e roliços em leque
    (dois gomos cada, a ponta arredondada) e um polegar bem separado.

    pulso: ponto do punho; frente: direção para onde os dedos apontam; cima:
    costas da mão; lado: do indicador para o mínimo. Devolve as peças da palma
    e, para cada dedo, (gomo1, gomo2, base, meio, ponta) para montar os ossos.
    Lição da crítica de 23/10/2026: dedos compridos e paralelos viravam
    "tábuas com frestas pretas"; aqui eles são curtos, grossos e abertos em
    leque a partir de uma palma arredondada.
    """
    f = Vector(frente).normalized()
    # costas e lado sempre perpendiculares aos dedos (senão a mão "deita")
    c = Vector(cima) - f * Vector(cima).dot(f)
    c.normalize()
    l = Vector(lado) - f * Vector(lado).dot(f) - c * Vector(lado).dot(c)
    l.normalize()
    e = escala
    p_palma = []
    centro = Vector(pulso) + f * 0.042 * e
    # Palma arredondada: dois anéis de octógono (base e nó dos dedos).
    pts = []
    for a_f, larg, alt in ((-0.035, 0.036, 0.022), (0.0, 0.044, 0.026), (0.034, 0.042, 0.02)):
        for k in range(8):
            ang = 2 * math.pi * k / 8
            pts.append(centro + f * a_f * e + l * math.cos(ang) * larg * e + c * math.sin(ang) * alt * e)
    p_palma.append(casco(f"{prefixo}Palma", pts, LUVA))
    # Punho da luva (cano) mais largo, como na folha.
    cano = tubo(f"{prefixo}LuvaCano", [Vector(pulso) - f * 0.032 * e, Vector(pulso) + f * 0.01 * e], [0.05 * e, 0.045 * e], LUVA, lados=8)
    p_palma.append(cano)
    dedos = {}
    for i, nome in enumerate(DEDOS):
        t = (i - 1.5) / 1.5           # -1 indicador ... +1 mínimo
        comp = (0.024, 0.027, 0.025, 0.021)[i] * e
        raio = (0.0155, 0.016, 0.0155, 0.014)[i] * e
        base_dedo = centro + f * (0.03 - abs(t) * 0.006) * e + l * t * 0.03 * e
        d1 = (f + l * t * 0.42 * abertura - c * curva * 0.4).normalized()
        meio = base_dedo + d1 * comp
        d2 = (f + l * t * 0.5 * abertura - c * curva).normalized()
        ponta = meio + d2 * comp * 0.9
        g1 = tubo(f"{prefixo}{nome}1", [base_dedo - d1 * raio * 0.6, meio], [raio * 1.05, raio], LUVA, lados=6)
        g2 = tubo(f"{prefixo}{nome}2", [meio - d2 * raio * 0.5, ponta - d2 * raio * 0.5, ponta + d2 * raio * 0.1],
                  [raio, raio * 0.92, raio * 0.5], LUVA, lados=6)
        dedos[nome] = (g1, g2, base_dedo, meio, ponta)
    # Polegar: sai da lateral da palma, perto do pulso, bem afastado dos dedos.
    base_pol = centro - l * 0.038 * e - f * 0.012 * e - c * 0.004 * e
    d1 = (f * 0.35 - l * 0.85 - c * 0.2).normalized()
    meio = base_pol + d1 * 0.03 * e
    d2 = (f * 0.75 - l * 0.55 - c * 0.25).normalized()
    ponta = meio + d2 * 0.026 * e
    g1 = tubo(f"{prefixo}Polegar1", [base_pol, meio], [0.016 * e, 0.0145 * e], LUVA, lados=6)
    g2 = tubo(f"{prefixo}Polegar2", [meio - d2 * 0.006 * e, ponta - d2 * 0.006 * e, ponta + d2 * 0.002 * e],
              [0.0145 * e, 0.013 * e, 0.007 * e], LUVA, lados=6)
    dedos["Polegar"] = (g1, g2, base_pol, meio, ponta)
    return p_palma, dedos


def braco(lado):
    """Manga larga em sino com punho bege e luva com dedos. lado: -1 esquerda, 1 direita."""
    s = lado
    ombro = Vector((s * 0.16, -0.01, 0.43))
    punho = Vector((s * 0.335, -0.05, 0.335))
    eixo = punho - ombro
    giro = Vector((0, 0, 1)).rotation_difference(eixo.normalized()).to_matrix().to_4x4()
    manga = torno(f"Manga{s}", [(0.055, 0.0), (0.072, eixo.length * 0.55), (0.092, eixo.length)], AZUL, lados=9,
                  ruido=0.03, semente=20 + s)
    manga.matrix_world = Matrix.Translation(ombro) @ giro
    punho_o = torno(f"Punho{s}", [(0.097, 0.0), (0.094, 0.05)], BEGE, lados=9)
    punho_o.matrix_world = Matrix.Translation(ombro + eixo * 0.86) @ giro
    pulso = punho + eixo.normalized() * 0.015
    # Mão aberta e relaxada como na folha: costas para cima, dedos para fora.
    frente = (eixo.normalized() + Vector((s * 0.3, -0.25, 0.25))).normalized()
    cima = Vector((s * 0.25, -0.15, 1.0)).normalized()
    lado_v = frente.cross(cima).normalized() * (-s)
    palma, dedos = luva(f"Mao{'E' if s < 0 else 'D'}", pulso, frente, cima, lado_v, escala=1.3, abertura=1.0, curva=0.35)
    return [manga, punho_o], palma, dedos, ombro, pulso


def cajado():
    """Cajado retorcido com faixas bege e uma coroa de garras segurando o cristal."""
    random.seed(4)
    pts, raios = [], []
    for i in range(10):
        t = i / 9
        pts.append((math.sin(t * 9) * 0.01 + random.uniform(-0.005, 0.005), math.cos(t * 7) * 0.008, -0.42 + t * 0.88))
        raios.append(0.017 + 0.005 * math.sin(t * 13) + 0.003 * (1 - t))
    p = [tubo("CajadoHaste", pts, raios, MADEIRA, lados=6)]
    for k, z in enumerate((-0.2, 0.06, 0.34)):
        p.append(torno(f"CajadoFaixa{k}", [(0.024, z), (0.024, z + 0.04)], BEGE, lados=6))
    topo = Vector(pts[-1])
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.4
        d = Vector((math.cos(a), math.sin(a), 0))
        p.append(tubo(f"CajadoGarra{k}", [topo, topo + d * 0.035 + Vector((0, 0, 0.04)), topo + d * 0.042 + Vector((0, 0, 0.11)),
                                         topo + d * 0.014 + Vector((0, 0, 0.15))], [0.012, 0.01, 0.008, 0.004], MADEIRA, lados=4))
    p.append(cristal("CajadoCristal", topo + Vector((0, 0, 0.12)), 0.15, 0.04, CRISTAL))
    p.append(cristal("CajadoCristalBase", Vector((0.0, 0.0, -0.44)), 0.045, 0.014, CRISTAL))
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


def ossos_da_mao(eb, lado, pulso, dedos, cima, pai):
    """Mão e dois ossos por dedo, com o eixo X de cada osso deitado na largura
    da mão: girar em X dobra o dedo, girar em Z abre e fecha o leque."""
    m = eb.new(f"Mao{lado}")
    m.head, m.tail = pulso, pulso + (Vector(dedos["Medio"][2]) - Vector(pulso)).normalized() * 0.05
    m.parent = eb[pai]
    # Z do osso para o lado da PALMA: girar X positivo fecha o dedo para a
    # palma (com Z para as costas, os dedos dobravam para trás; achado do
    # Vitor em 23/10/2026: "as mãos estão invertidas").
    palma = -Vector(cima)
    m.align_roll(palma)
    for nome, (g1, g2, b, meio, ponta) in dedos.items():
        o1 = eb.new(f"{nome}1{lado}")
        o1.head, o1.tail = b, meio
        o1.parent = m
        o1.align_roll(palma)
        o2 = eb.new(f"{nome}2{lado}")
        o2.head, o2.tail = meio, ponta
        o2.parent = o1
        o2.use_connect = True
        o2.align_roll(palma)


def montar():
    p_chapeu = chapeu()
    p_cabeca = cabeca()
    # Chibi: cabeça e chapéu maiores, crescendo a partir do pescoço.
    bpy.context.view_layer.update()
    pescoco = Vector((0, 0, 0.45))
    escala = Matrix.Translation(pescoco) @ Matrix.Scale(1.2, 4) @ Matrix.Translation(-pescoco)
    for o in p_chapeu + p_cabeca:
        o.matrix_world = escala @ o.matrix_world
    p_corpo, pernas = corpo()
    braco_e = braco(-1)
    braco_d = braco(1)
    p_cajado = cajado()
    pulso_d = braco_d[4]
    bpy.context.view_layer.update()
    for o in p_cajado:
        o.matrix_world = Matrix.Translation(pulso_d + Vector((0.035, -0.045, -0.01))) @ Matrix.Rotation(math.radians(6), 4, "Y") @ o.matrix_world

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
    osso("Chapeu", (0, 0, 0.8), (0, 0, 1.0), "Cabeca")
    for nome, b in (("E", braco_e), ("D", braco_d)):
        ombro, pulso = b[3], b[4]
        osso(f"Braco{nome}", tuple(ombro), tuple(pulso), "Tronco")
        ossos_da_mao(eb, nome, pulso, b[2], Vector((-1 if nome == "E" else 1, 0, 0.4)), f"Braco{nome}")
    for nome, x in (("E", -0.068), ("D", 0.068)):
        osso(f"Perna{nome}", (x, 0, 0.16), (x, 0, 0.02), "Quadril")
    bpy.ops.object.mode_set(mode="OBJECT")

    arm["leque_E"], arm["leque_D"] = 1, -1
    copa_e_aba = [o for o in p_chapeu]
    prender(p_corpo, arm, "Quadril")
    prender(p_cabeca, arm, "Cabeca")
    prender(copa_e_aba, arm, "Chapeu")
    for nome, b in (("E", braco_e), ("D", braco_d)):
        prender(b[0], arm, f"Braco{nome}")
        prender(b[1], arm, f"Mao{nome}")
        for dedo, (g1, g2, *_r) in b[2].items():
            prender([g1], arm, f"{dedo}1{nome}")
            prender([g2], arm, f"{dedo}2{nome}")
    prender(p_cajado, arm, "MaoD")
    prender(pernas["E"], arm, "PernaE")
    prender(pernas["D"], arm, "PernaD")
    todas = [o for o in bpy.data.objects if o.type == "MESH"]
    print("TRIANGULOS_MAGO", base.contar_triangulos(todas))
    return arm


# ---------------------------------------------------------------- poses e animação
def pose(arm, **rot):
    """rot: osso=(x, y, z) em graus; loc_<osso>=(x, y, z) em metros;
    dir_<osso>=(x, y, z) para onde o osso deve apontar (no espaço do corpo,
    frente -Y, cima +Z). A direção é o jeito seguro de posar braços, cujos
    ossos saem inclinados do ombro."""
    for b in arm.pose.bones:
        b.rotation_mode = "XYZ"
        b.rotation_euler = (0, 0, 0)
        b.location = (0, 0, 0)
    for k, v in rot.items():
        if k.startswith("loc_"):
            arm.pose.bones[k[4:]].location = v
        elif not k.startswith(("dir_", "mundo_")):
            r = [math.radians(a) for a in v]
            # Leque (giro em Z do primeiro gomo): mão esquerda e direita são
            # espelhadas, então o mesmo número abre uma e fecha a outra. Cada
            # esqueleto guarda o sinal de cada mão (medido: abrir = pontas do
            # indicador e do mínimo se afastam).
            if k[-1] in "ED" and k[:-1].endswith("1") and k[:-2] in DEDOS:
                r[2] *= arm.get("leque_" + k[-1], 1)
            arm.pose.bones[k].rotation_euler = r
    # Direções por último, do pai para o filho, já com a pose do pai aplicada
    # (senão a mão gira em cima do giro do braço e o cajado sai deitado).
    bpy.context.view_layer.update()
    for b in arm.pose.bones:
        if rot.get("mundo_" + b.name):
            # mesma orientação de repouso no espaço do corpo (ex.: o cajado
            # continua em pé mesmo com o braço erguido)
            atual = b.matrix.copy()
            b.matrix = Matrix.Translation(atual.translation) @ b.bone.matrix_local.to_3x3().to_4x4()
            bpy.context.view_layer.update()
            continue
        alvo = rot.get("dir_" + b.name)
        if alvo is None:
            continue
        atual = b.matrix.copy()
        giro = atual.col[1].to_3d().normalized().rotation_difference(Vector(alvo).normalized()).to_matrix().to_4x4()
        b.matrix = Matrix.Translation(atual.translation) @ giro @ Matrix.Translation(-atual.translation) @ atual
        bpy.context.view_layer.update()


def dedos(lado, curva=0.0, leque=0.0, onda=None, polegar=None):
    """Pose dos dedos de uma mão. curva em graus (positivo fecha), leque abre.
    onda: lista de 4 curvas extras, uma por dedo (indicador ao mínimo)."""
    r = {}
    for i, nome in enumerate(DEDOS):
        extra = onda[i] if onda else 0.0
        t = (i - 1.5) / 1.5
        r[f"{nome}1{lado}"] = (curva + extra, 0, leque * t)
        r[f"{nome}2{lado}"] = ((curva + extra) * 1.15, 0, 0)
    pc = curva * 0.6 if polegar is None else polegar
    r[f"Polegar1{lado}"] = (pc, 0, 0)
    r[f"Polegar2{lado}"] = (pc * 1.1, 0, 0)
    return r


def junta(*poses):
    saida = {}
    for p in poses:
        saida.update(p)
    return saida


# Mão direita segura o cajado: dedos fechados em volta da haste.
SEGURA_D = dedos("D", curva=70, polegar=40)

POSES = {
    "neutra": junta(SEGURA_D, dedos("E", curva=20, leque=24, polegar=-6)),
    # mão esquerda esticada à frente, dedos bem abertos (folha "conjurando")
    "conjurando": junta(SEGURA_D, dedos("E", curva=-12, leque=22, polegar=-10),
                        {"dir_BracoE": (-0.25, -1.0, 0.12), "dir_MaoE": (-0.05, -0.7, 0.7), "dir_BracoD": (0.45, -0.35, -0.6),
                         "Tronco": (0, 0, 12), "Cabeca": (-5, 0, -8), "Chapeu": (0, 0, 4), "PernaE": (-15, 0, 0), "PernaD": (15, 0, 0)}),
    # cajado lá no alto (folha "erguendo o cajado")
    "erguendo": junta(SEGURA_D, dedos("E", curva=35),
                      {"dir_BracoD": (0.35, -0.2, 1.0), "mundo_MaoD": True, "dir_BracoE": (-0.7, -0.2, -0.45),
                       "Tronco": (-6, 0, 0), "Cabeca": (-8, 0, 0), "Chapeu": (-6, 0, 0), "PernaE": (0, 0, -8), "PernaD": (0, 0, 8)}),
    "andando": junta(SEGURA_D, dedos("E", curva=25),
                     {"PernaE": (-40, 0, 0), "PernaD": (35, 0, 0), "dir_BracoE": (-0.45, 0.45, -0.75), "dir_BracoD": (0.5, -0.5, -0.7),
                      "Tronco": (10, 0, -6), "Cabeca": (-6, 0, 4), "Chapeu": (-8, 0, -4), "loc_Raiz": (0, 0, 0.02)}),
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


def onda_dos_dedos(fase, forca=1.0):
    """Os quatro dedos dobrando um depois do outro, como quem tamborila no ar."""
    return [forca * (7 + 9 * math.sin(fase - i * 0.7)) for i in range(4)]


def animar(arm):
    cena = bpy.context.scene
    cena.render.fps = 24
    if not arm.animation_data:
        arm.animation_data_create()
    acoes = {}
    # Parado (2 s): respira, o chapéu balança atrasado e os dedos da mão livre
    # fazem uma ondinha lenta (o "movimento fofo" pedido pelo Vitor).
    quadros = []
    for f in range(0, 49, 4):
        fase = 2 * math.pi * f / 48
        quadros.append((f + 1, junta(SEGURA_D, dedos("E", curva=10, leque=6, onda=onda_dos_dedos(fase), polegar=8 + 4 * math.sin(fase)),
                                     {"Tronco": (2.5 * math.sin(fase), 0, 0), "Cabeca": (-3 * math.sin(fase - 0.6), 0, 0),
                                      "Chapeu": (-3 * math.sin(fase - 1.2), 0, 2 * math.sin(fase * 0.5)),
                                      "BracoE": (0, 0, -4 * math.sin(fase)), "BracoD": (0, 0, 3 * math.sin(fase)),
                                      "loc_Raiz": (0, 0, -0.005 * (1 - math.cos(fase)) / 2)})))
    gravar(arm, "Parado", quadros, acoes)
    # Andar (1 s): passada, braço oposto à perna, chapéu atrasado.
    lado_a = POSES["andando"]
    lado_b = junta(SEGURA_D, dedos("E", curva=25), {"PernaE": (30, 0, 0), "PernaD": (-30, 0, 0), "dir_BracoE": (-0.5, -0.5, -0.7),
                                                    "dir_BracoD": (0.45, 0.45, -0.75), "Tronco": (6, 0, 6), "Chapeu": (-4, 0, 6),
                                                    "loc_Raiz": (0, 0, 0.015)})
    meio = junta(SEGURA_D, dedos("E", curva=20), {"Tronco": (6, 0, 0), "Chapeu": (4, 0, 0), "loc_Raiz": (0, 0, -0.008)})
    gravar(arm, "Andar", [(1, lado_a), (7, meio), (13, lado_b), (19, meio), (25, lado_a)], acoes)
    # Conjurar (0,6 s): antecipa (recolhe a mão fechando os dedos), estica a mão
    # com os dedos abertos em leque, segura e volta.
    recolhe = junta(SEGURA_D, dedos("E", curva=60, polegar=40),
                    {"dir_BracoE": (-0.6, 0.35, -0.5), "Tronco": (0, 0, -8), "Cabeca": (4, 0, 0), "Chapeu": (6, 0, 0)})
    gravar(arm, "Conjurar", [(1, POSES["neutra"]), (4, recolhe), (7, POSES["conjurando"]), (11, POSES["conjurando"]),
                             (15, junta(POSES["neutra"], dedos("E", curva=20))), (15, POSES["neutra"])], acoes)
    gravar(arm, "ErguerCajado", [(1, POSES["neutra"]), (7, POSES["erguendo"]), (15, POSES["erguendo"]), (22, POSES["neutra"])], acoes)
    # Dano (0,4 s): tranco para trás, chapéu atrasado, mãos abrem de susto.
    susto = junta(SEGURA_D, dedos("E", curva=-15, leque=20), {"Tronco": (-14, 0, 0), "Cabeca": (-10, 0, 0), "Chapeu": (-12, 0, 0),
                                                              "dir_BracoE": (-1.0, 0.1, 0.1), "dir_BracoD": (1.0, 0.1, 0.0),
                                                              "loc_Raiz": (0, 0.03, 0)})
    gravar(arm, "Dano", [(1, POSES["neutra"]), (3, susto), (10, POSES["neutra"])], acoes)
    return acoes


# ---------------------------------------------------------------- braços de primeira pessoa
def bracos_1p():
    """Braços vistos da câmera, em metros do jogo. Câmera na origem olhando
    para +Y do Blender (que vira -Z no Godot, a frente da câmera), cima +Z,
    direita +X. Mesma manga, punho bege e luva com dedos do mago."""
    p = {}
    for s, nome in ((-1, "E"), (1, "D")):
        # antebraço entrando pela borda de baixo da tela
        if s < 0:
            cotovelo, pulso = Vector((-0.46, 0.1, -0.38)), Vector((-0.36, 0.45, -0.2))
            # mão esquerda aberta e em pé: costas da mão para quem joga, palma
            # para a frente (para o alvo), dedos para cima (arte conceito)
            cima = Vector((0.05, -1.0, -0.1)).normalized()
        else:
            cotovelo, pulso = Vector((0.48, 0.1, -0.44)), Vector((0.41, 0.46, -0.3))
            cima = Vector((0.85, -0.2, 0.45)).normalized()
        eixo = pulso - cotovelo
        giro = Vector((0, 0, 1)).rotation_difference(eixo.normalized()).to_matrix().to_4x4()
        manga = torno(f"Manga1P{nome}", [(0.085, 0.0), (0.078, eixo.length * 0.6), (0.072, eixo.length * 0.92)], AZUL, lados=9,
                      ruido=0.03, semente=30 + s)
        manga.matrix_world = Matrix.Translation(cotovelo) @ giro
        punho = torno(f"Punho1P{nome}", [(0.082, 0.0), (0.08, 0.04)], BEGE, lados=9)
        punho.matrix_world = Matrix.Translation(cotovelo + eixo * 0.86) @ giro
        frente = (eixo.normalized() + Vector((0.05, 0.0, 1.2)) if s < 0 else eixo.normalized() + Vector((0, 0.2, 0.1))).normalized()
        # lado: do indicador para o mínimo (na mão esquerda o indicador fica à direita)
        # do indicador para o mínimo: o polegar fica do lado de dentro
        # (centro da tela) na mão aberta e por cima na mão do cajado
        lado_v = frente.cross(cima).normalized() * s
        palma, d = luva(f"Mao1P{nome}", pulso, frente, cima, lado_v, escala=1.05, abertura=1.25, curva=0.12)
        p[nome] = ([manga, punho], palma, d, cotovelo, pulso, cima)
    # cajado na mão direita, inclinado para a frente
    caj = cajado()
    pulso_d = p["D"][4]
    bpy.context.view_layer.update()
    for o in caj:
        o.matrix_world = (Matrix.Translation(pulso_d + Vector((0.03, 0.09, 0.03))) @ Matrix.Rotation(math.radians(12), 4, "X")
                          @ Matrix.Rotation(math.radians(-10), 4, "Y") @ Matrix.Scale(0.85, 4) @ o.matrix_world)
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = nomear(bpy.context.active_object, "Bracos1P")
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    raiz = eb[0]
    raiz.name = "Raiz"
    raiz.head, raiz.tail = (0, 0.05, -0.5), (0, 0.05, -0.45)
    for nome in ("E", "D"):
        _m, _palma, d, cotovelo, pulso, cima = p[nome]
        b = eb.new(f"Braco{nome}")
        b.head, b.tail = cotovelo, pulso
        b.parent = raiz
        ossos_da_mao(eb, nome, pulso, d, cima, f"Braco{nome}")
    bpy.ops.object.mode_set(mode="OBJECT")
    arm["leque_E"], arm["leque_D"] = -1, 1
    for nome in ("E", "D"):
        mangas, palma, d, *_r = p[nome]
        prender(mangas, arm, f"Braco{nome}")
        prender(palma, arm, f"Mao{nome}")
        for dedo, (g1, g2, *_x) in d.items():
            prender([g1], arm, f"{dedo}1{nome}")
            prender([g2], arm, f"{dedo}2{nome}")
    prender(caj, arm, "MaoD")
    objs = [o for o in bpy.data.objects if o.type == "MESH" and (o.name.startswith(("Manga1P", "Punho1P", "Mao1P")) or o in caj)]
    print("TRIANGULOS_1P", base.contar_triangulos(objs))
    return arm


def animar_1p(arm):
    if not arm.animation_data:
        arm.animation_data_create()
    acoes = {}
    segura = dedos("D", curva=75, polegar=45)
    quadros = []
    for f in range(0, 73, 4):
        fase = 2 * math.pi * f / 72
        quadros.append((f + 1, junta(segura, dedos("E", curva=8, leque=8, onda=onda_dos_dedos(fase, 1.0), polegar=6 + 4 * math.sin(fase)),
                                     {"MaoE": (6 * math.sin(fase), 0, 4 * math.sin(fase * 2)), "BracoE": (2 * math.sin(fase), 0, 0), "MaoD": (0, 0, 2 * math.sin(fase))})))
    gravar(arm, "Parado1P", quadros, acoes)
    aberta = dedos("E", curva=-14, leque=26, polegar=-12)
    gravar(arm, "Conjurar1P", [(1, junta(segura, dedos("E", curva=8, leque=8))),
                               (3, junta(segura, dedos("E", curva=55, polegar=35), {"BracoE": (12, 0, 0)})),
                               (6, junta(segura, aberta, {"BracoE": (-14, 0, 0), "MaoE": (-12, 0, 0)})),
                               (10, junta(segura, aberta, {"BracoE": (-10, 0, 0)})),
                               (16, junta(segura, dedos("E", curva=8, leque=8)))], acoes)
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
    if MODO == "exportar":
        arm = montar()
        animar(arm)
        pose(arm, **POSES["neutra"])
        base.exportar_glb(SAIDA + ".glb", [arm], animacoes=True)
        base.limpar_cena()
        criar_materiais()
        arm1 = bracos_1p()
        animar_1p(arm1)
        pose(arm1, **junta(dedos("D", curva=75, polegar=45), dedos("E", curva=8, leque=8)))
        base.exportar_glb(SAIDA + "_1p.glb", [arm1], animacoes=True)
        return
    if MODO == "maos":
        arm1 = bracos_1p()
        pose(arm1, **junta(dedos("D", curva=75, polegar=45), dedos("E", curva=12, leque=16, onda=onda_dos_dedos(1.0))))
        palco()
        camera_em((0, 0, 0), (0, 1, -0.3), lente=22)
        base.renderizar(f"{SAIDA}_1p.png", largura=800, altura=450, amostras=32)
        return
    arm = montar()
    rig = palco()
    alvo = (0, 0, 0.52)
    if MODO == "vistas":
        cajado_objs = [o for o in bpy.data.objects if o.name.startswith("Cajado")]
        for o in cajado_objs:
            o.hide_render = True
        for nome, pos, giro in [("frente", (0, -2.8, 0.75), 0), ("lado", (2.8, 0, 0.75), 90), ("costas", (0, 2.8, 0.75), 180)]:
            pose(arm, **POSES["neutra"])
            rig.rotation_euler = (0, 0, math.radians(giro))
            camera_em(pos, alvo)
            base.renderizar(f"{SAIDA}_{nome}.png", largura=560, altura=640, amostras=32)
        # mão de perto
        pose(arm, **POSES["neutra"])
        camera_em((-0.6, -0.75, 0.36), (-0.3, -0.06, 0.27), lente=70)
        base.renderizar(f"{SAIDA}_mao.png", largura=480, altura=480, amostras=32)
    if MODO == "poses":
        for nome in ("conjurando", "erguendo", "andando"):
            pose(arm, **POSES[nome])
            rig.rotation_euler = (0, 0, math.radians(-30))
            camera_em((1.35, -2.5, 0.85), (0, 0, 0.55))
            base.renderizar(f"{SAIDA}_{nome}.png", largura=560, altura=640, amostras=32)


if __name__ == "__main__":
    principal()
