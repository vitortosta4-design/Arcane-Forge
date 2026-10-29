"""Galinha v4 do Arcane Forge com esqueleto e animacoes (29/10/2026).

Parte do modelo pronto jogo/assets/modelos/galinha_v4.glb (feito no piloto MCP,
1.148 triangulos, cor quente) e so acrescenta o esqueleto e as animacoes:
forma, cores e triangulos ficam iguais. Cada peca vai inteira para um osso
(rigida, sem pintura de peso). A unica peca dividida e o G_Corpo, que vinha
com corpo e cabeca na mesma malha: as faces acima da coleira vao para a
cabeca (as faces ja eram soltas, entao nada e criado nem apagado).

Ossos: Raiz, Corpo, Pescoco, Cabeca, AsaE/D, CoxaE/D, PeE/D, Cauda.
As coxas sao filhas da Raiz (nao do Corpo) para o pe apoiado nao sair do
lugar quando o corpo agacha ou inclina.

Animacoes: Parado, Andar, Bicar, Dano, Morrer.
- Andar foi gravado para VELOCIDADE_ANDAR m/s (no tamanho do .glb): no apoio o
  pe recua exatamente nessa velocidade, entao no jogo, com a animacao tocando
  na proporcao da velocidade real, o pe fica parado no chao. Perna curta nao
  alcanca 3,5 m/s andando: e uma corridinha aos pulinhos (apoio curto, voo).
- Bicar: 0,4 s de aviso (recua a cabeca e agacha, com tremidinha), bote ate
  0,47 s (instante do dano no jogo) e volta.

Uso: python3 galinha.py [SAIDA.glb]
Frente olha para -Y (o .glb importado olha para +Z no Godot).
"""
import math
import os
import sys

import bpy
from mathutils import Vector

RAIZ_REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
ENTRADA = os.path.join(RAIZ_REPO, "jogo", "assets", "modelos", "galinha_v4.glb")
SAIDA = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    RAIZ_REPO, "jogo", "assets", "modelos", "galinha", "galinha.glb")

FPS = 120   # apoio do Andar dura ~46 ms: precisa de chave a cada 8 ms
VELOCIDADE_ANDAR = 3.5        # m/s no tamanho do .glb (igual a VisualGalinha)
CICLO_ANDAR_S = 0.4           # dois pulinhos por ciclo
PE_FRENTE, PE_TRAS = 0.08, -0.08   # onde o tornozelo toca e solta o chao (em relacao ao quadril)
AVISO_BICADA_S = 0.4
ACERTO_BICADA_S = 0.47

Z_COLEIRA = 0.49              # faces do G_Corpo acima disso sao cabeca
QUADRIL_Z, TORNOZELO_Z = 0.17, 0.02
PERNA = QUADRIL_Z - TORNOZELO_Z
PERNA_X, PERNA_Y = 0.123, -0.03

PIVOS = {   # cabeca do osso (pivo); todos apontam para cima (+Z)
    "Raiz": (0, 0, 0),
    "Corpo": (0, 0.02, 0.26),
    "Pescoco": (0, -0.10, 0.47),
    "Cabeca": (0, -0.13, 0.56),
    "AsaE": (0.20, -0.06, 0.40),
    "AsaD": (-0.20, -0.06, 0.40),
    "Cauda": (0, 0.20, 0.40),
    "CoxaE": (PERNA_X, PERNA_Y, QUADRIL_Z),
    "CoxaD": (-PERNA_X, PERNA_Y, QUADRIL_Z),
    "PeE": (PERNA_X, PERNA_Y, TORNOZELO_Z),
    "PeD": (-PERNA_X, PERNA_Y, TORNOZELO_Z),
}
PAIS = {"Corpo": "Raiz", "Pescoco": "Corpo", "Cabeca": "Pescoco", "AsaE": "Corpo", "AsaD": "Corpo",
        "Cauda": "Corpo", "CoxaE": "Raiz", "CoxaD": "Raiz", "PeE": "CoxaE", "PeD": "CoxaD"}


def osso_da_peca(nome):
    """Qual osso leva cada peca do galinha_v4.glb (lado 1 = +X = esquerda dela)."""
    lado = "E" if "_1" in nome and "_-1" not in nome else "D"
    if nome.startswith(("G_Cabeca", "G_Olho", "G_Pupila", "G_Brilho", "G_Bico", "G_Barbela", "G_Crista")):
        return "Cabeca"
    if nome.startswith("G_Coleira"):
        return "Pescoco"
    if nome.startswith("G_Asa"):
        return "Asa" + lado
    if nome.startswith("G_Pena"):
        return "Cauda"
    if nome.startswith("G_Perna"):
        return "Coxa" + lado
    if nome.startswith("G_Dedo"):
        return "Pe" + lado
    return "Corpo"   # G_Corpo (parte de baixo), G_Medalhao*, G_Runa_*, G_Alca


# ---------------------------------------------------------------- montagem
def importar():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=ENTRADA)
    for o in list(bpy.data.objects):
        if o.type == "MESH":
            mw = o.matrix_world.copy()
            o.parent = None
            o.matrix_world = mw
    for o in list(bpy.data.objects):
        if o.type == "EMPTY":
            bpy.data.objects.remove(o)


def contar_triangulos():
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in bpy.data.objects if o.type == "MESH")


def separar_cabeca():
    """Faces do G_Corpo acima da coleira viram a peca G_CorpoCabeca."""
    corpo = bpy.data.objects["G_Corpo"]
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = corpo
    corpo.select_set(True)
    for p in corpo.data.polygons:
        p.select = (corpo.matrix_world @ p.center).z > Z_COLEIRA
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    cabeca = [o for o in bpy.context.selected_objects if o != corpo][0]
    cabeca.name = "G_Cabeca"
    return cabeca


def juntar(objs, nome):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = nome
    return o


def montar():
    importar()
    antes = contar_triangulos()
    separar_cabeca()
    bpy.ops.object.armature_add(location=(0, 0, 0))
    arm = bpy.context.active_object
    arm.name = "GalinhaEsqueleto"
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    eb[0].name = "Raiz"
    for nome, h in PIVOS.items():
        b = eb["Raiz"] if nome == "Raiz" else eb.new(nome)
        b.head = h
        b.tail = (h[0], h[1], h[2] + 0.08)
        b.roll = 0
    for nome, pai in PAIS.items():
        eb[nome].parent = eb[pai]
    bpy.ops.object.mode_set(mode="OBJECT")

    # Junta as pecas por osso (menos chamadas de desenho); as penas da cauda
    # ficam separadas para a galinha zumbi poder esconder algumas.
    grupos = {}
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        if o.name.startswith("G_Pena"):
            o.name = o.name[2:]          # Pena_0 .. Pena_3
            grupos.setdefault(o.name, ("Cauda", [o]))
            continue
        osso = osso_da_peca(o.name)
        grupos.setdefault(osso, (osso, []))[1].append(o)
    bpy.context.view_layer.update()
    for nome, (osso, objs) in grupos.items():
        peca = juntar(objs, nome if nome.startswith("Pena") else "Malha" + osso)
        mw = peca.matrix_world.copy()
        peca.parent = arm
        peca.parent_type = "BONE"
        peca.parent_bone = osso
        peca.matrix_world = mw
    depois = contar_triangulos()
    assert antes == depois, f"triangulos mudaram: {antes} -> {depois}"
    print("TRIANGULOS_GALINHA", depois)
    return arm


# ---------------------------------------------------------------- poses
# Ossos em pe com roll 0: rotacao X positiva inclina o topo para a frente,
# Y positiva vira para a esquerda dela (+X), Z positiva tomba para a direita.
# location = (lado, cima, frente). Angulos em graus.
def pose(arm, p):
    for b in arm.pose.bones:
        b.rotation_mode = "XYZ"
        r = p.get(b.name, (0, 0, 0))
        b.rotation_euler = [math.radians(a) for a in r]
        b.location = p.get("loc_" + b.name, (0, 0, 0))


def gravar(arm, nome, duracao_s, func_pose):
    act = bpy.data.actions.new(nome)
    arm.animation_data.action = act
    quadros = round(duracao_s * FPS)
    for f in range(quadros + 1):
        pose(arm, func_pose(f / FPS))
        for b in arm.pose.bones:
            b.keyframe_insert("rotation_euler", frame=f)
            b.keyframe_insert("location", frame=f)
    trilha = arm.animation_data.nla_tracks.new()
    trilha.name = nome
    trilha.strips.new(nome, 0, act)
    arm.animation_data.action = None


def suave(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def misturar(a, b, u):
    return tuple(x + (y - x) * u for x, y in zip(a, b))


def curva(t, chaves):
    """Interpola tuplas por chaves [(t, valor)] com suavizacao."""
    if t <= chaves[0][0]:
        return chaves[0][1]
    for (t0, v0), (t1, v1) in zip(chaves, chaves[1:]):
        if t <= t1:
            return misturar(v0, v1, suave((t - t0) / (t1 - t0)))
    return chaves[-1][1]


def pose_parado(t):
    resp = math.sin(2 * math.pi * t / 1.6)
    # Galinha mexe a cabeca aos trancos: vira rapido e congela.
    cabeca = curva(t, [(0.0, (0, 0, 0)), (0.5, (0, 0, 0)), (0.6, (0, 38, 0)), (1.3, (0, 38, 0)),
                       (1.42, (-6, -32, 0)), (2.2, (-6, -32, 0)), (2.32, (4, -8, 16)), (2.9, (4, -8, 16)),
                       (3.05, (0, 0, 0)), (3.2, (0, 0, 0))])
    return {
        "Corpo": (1.5 * resp, 0, 0), "loc_Corpo": (0, 0.006 * resp, 0),
        "Pescoco": (-2 * resp, 0, 0), "Cabeca": cabeca,
        "AsaE": (0, 0, -3 - 2 * resp), "AsaD": (0, 0, 3 + 2 * resp),
        "Cauda": (4 * math.sin(2 * math.pi * t / 1.6 - 0.8), 3 * math.sin(2 * math.pi * t / 3.2), 0),
    }


DURACAO_APOIO_S = (PE_FRENTE - PE_TRAS) / VELOCIDADE_ANDAR
ANG_TOQUE = math.degrees(math.asin(PE_FRENTE / PERNA))     # perna a frente ao tocar o chao
ANG_SOLTA = math.degrees(math.asin(-PE_TRAS / PERNA))      # perna atras ao soltar
ANG_ESPERA = 45.0   # no apoio da outra perna esta fica bem a frente, longe do chao


def perna_no_ciclo(fase):
    """Angulo da coxa (graus, + = pe a frente) e se o pe esta apoiado, fase 0..1.

    Apoio [0, a]: o pe recua no chao na velocidade do Andar. Voo ate 0,5: a
    perna passa para a frente com o corpo no alto. Apoio da outra perna: esta
    espera a frente (ANG_ESPERA). Voo ate 1: recua um pouco ate o angulo de
    toque, como a galinha de verdade antes de pisar.
    """
    a = DURACAO_APOIO_S / CICLO_ANDAR_S
    if fase < a:
        frente = PE_FRENTE - (PE_FRENTE - PE_TRAS) * fase / a
        return math.degrees(math.asin(frente / PERNA)), True
    if fase < 0.5:
        return -ANG_SOLTA + (ANG_ESPERA + ANG_SOLTA) * suave((fase - a) / (0.5 - a)), False
    if fase < 0.5 + a:
        return ANG_ESPERA, False
    return ANG_ESPERA + (ANG_TOQUE - ANG_ESPERA) * suave((fase - 0.5 - a) / (0.5 - a)), False


def altura_raiz_apoio(ang):
    return -PERNA * (1 - math.cos(math.radians(ang)))


def pose_andar(t):
    fase = (t / CICLO_ANDAR_S) % 1.0
    p = {}
    apoiado = None
    for lado, deslocamento in (("E", 0.0), ("D", 0.5)):
        fase_perna = (fase + 1 - deslocamento) % 1.0
        ang, no_chao = perna_no_ciclo(fase_perna)
        # X negativo leva o pe para a frente. Pe reto no chao no apoio e ao
        # pousar; logo depois de soltar, os dedos dobram para tras.
        p["Coxa" + lado] = (-ang, 0, 0)
        dobra = 40 * math.sin(math.pi * min(1.0, fase_perna * 2)) if not no_chao and fase_perna < 0.5 else 0
        p["Pe" + lado] = (ang + dobra, 0, 0)
        if no_chao:
            apoiado = ang
    meio = (fase % 0.5) / 0.5   # 0..1 dentro de cada pulinho
    apoio = DURACAO_APOIO_S / (CICLO_ANDAR_S / 2)
    if apoiado is not None:
        z = altura_raiz_apoio(apoiado)
    else:
        u = (meio - apoio) / (1 - apoio)
        z0, z1 = altura_raiz_apoio(ANG_SOLTA), altura_raiz_apoio(ANG_TOQUE)
        z = z0 + (z1 - z0) * u + 0.07 * math.sin(math.pi * u)
    lado = 1 if fase < 0.5 else -1
    ginga = math.sin(2 * math.pi * fase)
    p["loc_Raiz"] = (0, z, 0)
    p["Corpo"] = (12 + 3 * math.cos(4 * math.pi * fase), 4 * ginga, 6 * ginga)
    p["loc_Corpo"] = (0, -0.012 * math.cos(4 * math.pi * fase), 0)
    # Cabeca firme (galinha estabiliza a cabeca) com um leve bate-cabeca.
    p["Pescoco"] = (-8 + 6 * math.sin(4 * math.pi * fase), -4 * ginga, -5 * ginga)
    p["Cabeca"] = (-2 - 3 * math.sin(4 * math.pi * fase + 1), 0, 0)
    bater = 22 * max(0.0, math.sin(4 * math.pi * fase - 0.6))
    p["AsaE"] = (0, 0, 4 + bater)     # Z positivo na AsaE abre para fora
    p["AsaD"] = (0, 0, -4 - bater)
    p["Cauda"] = (10 * math.sin(4 * math.pi * fase - 1.5), 8 * lado, 0)
    return p


def pose_bicar(t):
    # Aviso (ate 0,4 s): agacha, recolhe o pescoco no peito, abre asas e cauda
    # e treme (10 Hz, legivel a 30 FPS). Bote ate 0,47 s: o pescoco avanca
    # para a frente e para baixo; a cabeca quase nao gira (crista em cima).
    tremer = math.sin(t * 2 * math.pi * 10) if 0.2 < t < AVISO_BICADA_S else 0.0
    agachar = [(0.0, (0, 0, 0)), (0.22, (1, 1, 1)), (AVISO_BICADA_S, (1, 1, 1)),
               (ACERTO_BICADA_S, (0, 0, 0)), (0.9, (0, 0, 0))]
    bote = [(0.0, (0, 0, 0)), (AVISO_BICADA_S, (0, 0, 0)), (ACERTO_BICADA_S, (1, 1, 1)),
            (0.56, (1, 1, 1)), (0.9, (0, 0, 0))]
    a = curva(t, agachar)[0]
    b = curva(t, bote)[0]
    return {
        "Corpo": (-15 * a + 3 * tremer + 24 * b, 0, 0),
        "loc_Corpo": (0, -0.06 * a - 0.04 * b, -0.03 * a + 0.12 * b),
        "Pescoco": (-40 * a + 6 * tremer + 36 * b, 0, 0),
        "Cabeca": (-8 * a - 6 * b, 0, 0),
        "AsaE": (0, 0, 45 * a + 10 * b), "AsaD": (0, 0, -45 * a - 10 * b),
        "Cauda": (35 * a - 10 * b, 0, 0),
        "CoxaE": (6 * a - 8 * b, 0, 0), "CoxaD": (6 * a - 8 * b, 0, 0),
        "PeE": (-6 * a + 8 * b, 0, 0), "PeD": (-6 * a + 8 * b, 0, 0),
    }


def pose_dano(t):
    # Tranco: joga para tras em 0,05 s e volta balancando ate 0,35 s.
    u = t / 0.033 if t < 0.033 else math.exp(-(t - 0.033) * 11) * math.cos((t - 0.033) * 30)
    return {
        "Corpo": (-20 * u, 0, 5 * u), "loc_Corpo": (0, 0.03 * u, -0.05 * u),
        "Pescoco": (-30 * u, 0, -8 * u), "Cabeca": (-10 * u, 12 * u, 0),
        "AsaE": (0, 0, 45 * abs(u)), "AsaD": (0, 0, -45 * abs(u)),
        "Cauda": (30 * u, 0, 0),
    }


def pose_morrer(t):
    # Pulinho de susto, tomba de lado ate quase de costas (140 graus) e fica de
    # pernas abertas para o ceu: perna curta (15 cm) so aparece acima do corpo
    # assim. Quique ao bater no chao e um chute no fim.
    susto = curva(t, [(0.0, (0,)), (0.12, (1,)), (0.3, (0,))])[0]
    tombo = curva(t, [(0.0, (0,)), (0.18, (0,)), (0.5, (1.06,)), (0.62, (0.98,)), (0.72, (1,))])[0]
    pernas = curva(t, [(0.0, (0,)), (0.35, (0,)), (0.6, (1,))])[0]
    chute = curva(t, [(0.0, (0,)), (0.95, (0,)), (1.02, (1,)), (1.12, (0,)), (1.18, (0.5,)), (1.25, (0,))])[0]
    rolar = 140 * tombo
    return {
        "Raiz": (0, 0, rolar),
        "loc_Raiz": (0, 0.12 * susto, 0),
        "Corpo": (-8 * susto, 0, 0),
        "Pescoco": (-25 * susto + 10 * tombo, 0, -20 * tombo),
        "Cabeca": (0, -15 * tombo, -15 * tombo),
        "AsaE": (0, 0, 60 * susto + 35 * tombo), "AsaD": (0, 0, -60 * susto - 35 * tombo),
        "Cauda": (25 * susto, 0, 0),
        "CoxaE": (25 * chute, 0, 52 * pernas), "CoxaD": (0, 0, 28 * pernas),
        "PeE": (-35 * pernas - 30 * chute, 0, 0), "PeD": (-35 * pernas, 0, 0),
    }


def corrigir_chao_morrer(arm):
    """Depois de tombar, sobe a Raiz para a galinha deitar no chao (sem afundar)."""
    malhas = [o for o in bpy.data.objects if o.type == "MESH"]
    trilhas = arm.animation_data.nla_tracks
    for tr in trilhas:
        tr.mute = True
    arm.animation_data.action = trilhas["Morrer"].strips[0].action
    cena = bpy.context.scene
    for f in range(round(0.3 * FPS), round(1.3 * FPS) + 1):
        cena.frame_set(f)
        dg = bpy.context.evaluated_depsgraph_get()
        menor = min((o.evaluated_get(dg).matrix_world @ v.co).z for o in malhas for v in o.data.vertices)
        # Quique pequeno logo depois de bater no chao (0,5 a 0,64 s).
        t = f / FPS
        quique = 0.045 * math.sin(math.pi * (t - 0.5) / 0.14) if 0.5 < t < 0.64 else 0.0
        b = arm.pose.bones["Raiz"]
        b.location[1] += max(0.0, -menor) + quique
        b.keyframe_insert("location", frame=f)
    arm.animation_data.action = None
    for tr in trilhas:
        tr.mute = False


def animar(arm):
    bpy.context.preferences.edit.keyframe_new_interpolation_type = "LINEAR"
    cena = bpy.context.scene
    cena.render.fps = FPS
    arm.animation_data_create()
    gravar(arm, "Parado", 3.2, pose_parado)
    gravar(arm, "Andar", CICLO_ANDAR_S, pose_andar)
    gravar(arm, "Bicar", 0.9, pose_bicar)
    gravar(arm, "Dano", 0.35, pose_dano)
    gravar(arm, "Morrer", 1.3, pose_morrer)
    corrigir_chao_morrer(arm)
    pose(arm, {})


def exportar(arm):
    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    for o in arm.children_recursive:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=SAIDA, use_selection=True, export_animations=True,
                              export_animation_mode="NLA_TRACKS", export_apply=True)
    print("EXPORTADO", SAIDA)


if __name__ == "__main__":
    esqueleto = montar()
    animar(esqueleto)
    exportar(esqueleto)
