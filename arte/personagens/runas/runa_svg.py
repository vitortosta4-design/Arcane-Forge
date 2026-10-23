"""Runa a partir dos vetores desenhados pelo Vitor no Illustrator (23/10/2026).

Le tres SVGs de vetores/ (mesma prancheta 1000x1000):
- contorno.svg: silhueta de fora da pedra (comum a todas as runas, e o encaixe).
- borda_interna.svg: onde termina o chanfro e comeca a face da frente.
- simbolo_<nome>.svg: o desenho entalhado.

O chanfro e a faixa entre o contorno (mais para tras) e a borda interna (na
frente), triangulada direto entre as duas linhas: fica facetado, no estilo low
poly. O simbolo e cortado por booleana, como na v4 (runas.py), e os materiais
sao os mesmos da v4.

Encaixe: com o contorno do Vitor, a aba da esquerda de uma runa entra no
encaixe da direita da vizinha com passo de PASSO_PX pixels (medido: abaixo de
655 as pecas se sobrepoem). A escala faz esse passo valer PASSO * U metros,
o mesmo da v4, para nada mudar no jogo.

Uso: python runa_svg.py -- SAIDA comparar|exportar [nome]
"""
import math
import os
import random
import re
import sys

import bpy
import bmesh

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import runas as R  # noqa: E402
base = R.base

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else "/tmp/runa_svg"
MODO = args[1] if len(args) > 1 else "comparar"
NOME = args[2] if len(args) > 2 else "prende"

PASSO_PX = 655
K = R.PASSO * R.U / PASSO_PX       # metros por pixel da prancheta
CHANFRO = 0.014                    # quanto o contorno fica atras da borda interna (m)
FUNDO_SIMB = 0.009                 # profundidade do entalhe (m)


# ---------------------------------------------------------------- leitura do SVG
def _bezier(p0, p1, p2, p3, n=6):
    def dist(p, a, b):
        L = math.hypot(b[0] - a[0], b[1] - a[1]) or 1e-9
        return abs((b[0] - a[0]) * (a[1] - p[1]) - (a[0] - p[0]) * (b[1] - a[1])) / L
    if max(dist(p1, p0, p3), dist(p2, p0, p3)) < 1.5:   # curva que e reta
        return [p3]
    pts = []
    for i in range(1, n + 1):
        t = i / n
        u = 1 - t
        pts.append(tuple(u ** 3 * p0[k] + 3 * u * u * t * p1[k] + 3 * u * t * t * p2[k] + t ** 3 * p3[k]
                         for k in (0, 1)))
    return pts


def _caminho(d):
    tk = re.findall(r"[MLCZ]|-?\d+\.?\d*", d)
    i, cmd, pts = 0, None, []
    while i < len(tk):
        if tk[i] in "MLCZ":
            cmd = tk[i]
            i += 1
        if cmd == "Z":
            break
        if cmd in "ML":
            pts.append((float(tk[i]), float(tk[i + 1])))
            i += 2
        elif cmd == "C":
            c = [(float(tk[i + k]), float(tk[i + k + 1])) for k in (0, 2, 4)]
            i += 6
            pts += _bezier(pts[-1], *c)
        else:
            raise ValueError(f"comando de SVG nao suportado: {cmd}")
    if pts[0] == pts[-1]:
        pts.pop()
    return pts


def _cor_do_caminho(tag, classes):
    m = re.search(r'fill="(#[0-9a-fA-F]{6})"', tag)
    if m:
        return m.group(1).lower()
    m = re.search(r'class="([^"]+)"', tag)
    return classes.get(m.group(1), "") if m else ""


def ler_svg(arquivo, so_coloridos=False):
    """Caminhos dentro da prancheta 1000x1000. O Illustrator exporta tambem o
    que esta fora da prancheta (as outras camadas arrastadas para o lado);
    isso e ignorado. Com so_coloridos, ignora preto e cinza (contorno e borda
    que tenham vindo junto no arquivo do simbolo)."""
    texto = open(os.path.join(AQUI, "vetores", arquivo)).read()
    texto = re.sub(r'<image[^>]*>', "", texto)
    classes = {c: v.lower() for c, v in re.findall(r'\.(cls-\d+)\s*\{\s*fill:\s*(#[0-9a-fA-F]{6})', texto)}
    caminhos = []
    for tag, d in re.findall(r'(<path\b[^>]*\bd="([^"]+)"[^>]*>)', texto):
        cor = _cor_do_caminho(tag, classes)
        if so_coloridos and cor:
            rgb = [int(cor[i:i + 2], 16) for i in (1, 3, 5)]
            if max(rgb) - min(rgb) < 30:      # preto, cinza ou branco
                continue
        c = _caminho(d)
        cx = sum(x for x, _ in c) / len(c)
        cy = sum(y for _, y in c) / len(c)
        if 0 <= cx <= 1000 and 0 <= cy <= 1000:
            caminhos.append(c)
    if not caminhos:
        raise ValueError(f"{arquivo}: nenhum caminho dentro da prancheta")
    # prancheta -> metros, centrado no meio da prancheta, z para cima
    return [[((x - 500) * K, (500 - y) * K) for x, y in c] for c in caminhos]


def area_assinada(pts):
    return sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
               for i in range(len(pts))) / 2


# ---------------------------------------------------------------- pedra
def laje_svg(nome, contorno, borda, seed):
    r = random.Random(seed)
    y_f, y_t = -R.ESP / 2, R.ESP / 2
    bm = bmesh.new()
    vb = [bm.verts.new((x, y_f, z)) for x, z in borda]
    vc = [bm.verts.new((x, y_f, z)) for x, z in contorno]
    arestas = [bm.edges.new((vb[i], vb[(i + 1) % len(vb)])) for i in range(len(vb))]
    arestas += [bm.edges.new((vc[i], vc[(i + 1) % len(vc)])) for i in range(len(vc))]
    # faixa do chanfro: triangula a regiao entre as duas linhas
    feito = bmesh.ops.triangle_fill(bm, use_beauty=True, use_dissolve=False, edges=arestas, normal=(0, -1, 0))
    anel = [f for f in feito["geom"] if isinstance(f, bmesh.types.BMFace)]
    area_anel = sum(f.calc_area() for f in anel)
    esperado = abs(area_assinada(contorno)) - abs(area_assinada(borda))
    if abs(area_anel - esperado) > esperado * 0.02:
        raise RuntimeError(f"chanfro mal preenchido: area {area_anel:.5f}, esperado {esperado:.5f}")
    # face da frente
    bm.faces.new(vb)
    for v in vc:
        v.co.y = y_f + CHANFRO
    # lateral e costas
    ext = bmesh.ops.extrude_edge_only(bm, edges=arestas[len(vb):])
    novos = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
    for v in novos:
        v.co.y = y_t
    bmesh.ops.contextual_create(bm, geom=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMEdge)
                                          and all(abs(v.co.y - y_t) < 1e-6 for v in e.verts)])
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    # frente facetada (igual a v4): triangula, subdivide e mexe de leve
    frentes = [f for f in bm.faces if f.normal.y < -0.99 and abs(f.calc_center_median().y - y_f) < 1e-5]
    bmesh.ops.triangulate(bm, faces=frentes, quad_method="BEAUTY", ngon_method="BEAUTY")
    frentes = [f for f in bm.faces if f.normal.y < -0.99 and abs(f.calc_center_median().y - y_f) < 1e-5]
    bmesh.ops.subdivide_edges(bm, edges=list({e for f in frentes for e in f.edges}), cuts=1, use_grid_fill=True)
    borda_set = {v for v in bm.verts if abs(v.co.y - y_f) < 1e-5
                 and any(f.normal.y > -0.99 for f in v.link_faces)}
    for v in bm.verts:
        if abs(v.co.y - y_f) < 1e-5 and v not in borda_set:
            v.co.y += r.uniform(-0.0004, 0.0006)
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="BEAUTY", ngon_method="BEAUTY")
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return o


def prisma(nome, pts, y0, y1, mat):
    bm = bmesh.new()
    f = bm.faces.new([bm.verts.new((x, y0, z)) for x, z in pts])
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.y = y1
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="BEAUTY", ngon_method="BEAUTY")
    return R.objeto_de_bm(nome, bm, mat)


def brasa(nome, pts, y0, y1, mat, recuo=0.0035):
    """Miolo claro no fundo do sulco: o desenho encolhido para dentro."""
    bm = bmesh.new()
    f = bm.faces.new([bm.verts.new((x, y0, z)) for x, z in pts])
    bmesh.ops.triangulate(bm, faces=[f], quad_method="BEAUTY", ngon_method="BEAUTY")
    res = bmesh.ops.inset_region(bm, faces=bm.faces[:], thickness=recuo, use_even_offset=True)
    bmesh.ops.delete(bm, geom=res["faces"], context="FACES")
    ext = bmesh.ops.extrude_face_region(bm, geom=bm.faces[:])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.y = y1
    return R.objeto_de_bm(nome, bm, mat)


def mats_svg(nome, acesa):
    """Materiais da v4 com tres ajustes pedidos na comparacao com a folha:
    simbolo aceso com cor viva (antes saia bege) e quina do chanfro mais clara.
    A pedra acesa continua escura de proposito (o sol do jogo clareia ~1,7x)."""
    mats = R.mats_runa(nome, acesa)
    brilho, miolo, tom = R.ELEMENTOS[nome]
    sfx = "acesa" if acesa else "apagada"
    if acesa:
        mats["fundo"] = base.material(f"RS_{nome}_fundo", "#000000", rugosidade=1.0, emissao=brilho, forca=2.0)
        mats["parede"] = base.material(f"RS_{nome}_parede", "#000000", rugosidade=1.0,
                                       emissao=R.misturar(brilho, miolo, 0.15), forca=1.3)
        mats["miolo"] = base.material(f"RS_{nome}_miolo", "#000000", rugosidade=1.0,
                                      emissao=R.misturar(brilho, miolo, 0.3), forca=1.5)
        mats["borda"] = base.material(f"RS_{nome}_borda", R.misturar(R.PEDRA_ACESA[nome], "#e8c39a", 0.45),
                                      rugosidade=0.55, emissao=brilho, forca=0.04)
    else:
        mats["borda"] = base.material(f"RS_{nome}_{sfx}_borda", "#a8a2bf", rugosidade=0.55)
    return mats


def criar_runa(nome, acesa, local=(0, 0, 0), seed=0, rot=(0, 0, 0)):
    contorno = ler_svg("contorno.svg")[0]
    borda = ler_svg("borda_interna.svg")[0]
    simbolo = ler_svg(f"simbolo_{nome}.svg", so_coloridos=True)
    mats = mats_svg(nome, acesa)
    sfx = "acesa" if acesa else "apagada"
    pedra = laje_svg(f"Runa_{nome}_{sfx}", contorno, borda, seed)
    lista = [mats["frente"][0], mats["borda"], mats["lado"], mats["fundo"], mats["parede"], mats["racha"],
             mats["frente"][1], mats["frente"][2], mats["aura"]]
    for m in lista:
        pedra.data.materials.append(m)
    y_f = -R.ESP / 2
    cort = [prisma(f"Corte_{nome}_{sfx}_{k}", p, y_f - 0.02, y_f + FUNDO_SIMB, mats["fundo"])
            for k, p in enumerate(simbolo)]
    cort += R.rachaduras(f"Corte_{nome}_{sfx}", [(x / R.U, z / R.U) for x, z in borda], seed, mats["racha"])
    R.booleana(pedra, cort)
    for c in cort:
        bpy.data.objects.remove(c)
    # centro do simbolo (para a aura e a luz)
    xs = [x for p in simbolo for x, _ in p]
    zs = [z for p in simbolo for _, z in p]
    cx, cz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
    r = random.Random(seed + 3)
    idx = {m.name: i for i, m in enumerate(pedra.data.materials)}
    for f in pedra.data.polygons:
        nome_mat = pedra.data.materials[f.material_index].name
        ny = f.normal.y
        if nome_mat == mats["fundo"].name:
            f.material_index = idx[mats["fundo"].name] if ny < -0.7 else idx[mats["parede"].name]
        elif nome_mat == mats["racha"].name:
            continue
        elif ny < -0.9 and f.center.y < y_f + 0.0025:
            f.material_index = r.choice((0, 6, 7))  # sem a aura em disco da v4 (lia como um circulo duro)
        elif ny < -0.15:
            f.material_index = idx[mats["borda"].name]
        else:
            f.material_index = idx[mats["lado"].name]
    base.chapado(pedra)
    if acesa:
        y_fundo = y_f + FUNDO_SIMB
        for k, p in enumerate(simbolo):
            o = brasa(f"Brasa_{nome}_{k}", p, y_fundo - 0.0022, y_fundo - 0.0004, mats["miolo"])
            base.chapado(o)
            o.parent = pedra
        bpy.ops.object.light_add(type="POINT", location=(cx, y_f - 0.035, cz))
        luz = bpy.context.active_object
        luz.name = f"Luz_{nome}"
        luz.data.energy = R.LUZ_W
        luz.data.shadow_soft_size = 0.02
        luz.data.color = base.cor(R.ELEMENTOS[nome][0])[:3]
        luz.parent = pedra
    pedra.location = local
    pedra.rotation_euler = rot
    return pedra


def principal():
    base.limpar_cena()
    if MODO == "exportar":
        for acesa, arq in ((False, ""), (True, "_acesas")):
            base.limpar_cena()
            objs = [criar_runa(NOME, acesa)]
            print("TRIANGULOS", NOME + arq, base.contar_triangulos(objs))
            base.exportar_glb(f"{SAIDA}{arq}.glb", objs, luzes=acesa)
        return
    R.palco()
    passo = PASSO_PX * K
    if MODO == "comparar":
        criar_runa(NOME, False, local=(-0.18, 0, 0), rot=R.GIRO)
        criar_runa(NOME, True, local=(0.18, 0, 0), seed=1, rot=R.GIRO)
        R.camera_orto((0.0, 0.0), 0.86, 670, 460)
        base.renderizar(f"{SAIDA}_par.png", largura=670, altura=460, amostras=48, transparente=True)
        return
    if MODO == "encaixe":
        for k in range(3):
            criar_runa(NOME, True, local=((k - 1) * passo, 0, 0), seed=k, rot=(math.radians(-8), 0, 0))
        R.camera_orto((0.0, 0.0), 1.05, 900, 460)
        base.renderizar(f"{SAIDA}_encaixe.png", largura=900, altura=460, amostras=48, transparente=True)
        return
    raise ValueError(f"modo desconhecido: {MODO}")


if __name__ == "__main__":
    principal()
