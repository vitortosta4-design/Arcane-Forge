class_name LivrosVoadores
extends Node3D
## Livros encantados do posto da forja (pedido do Vitor, 13/11/2026): de
## tempos em tempos um livro levanta voo de cima de uma estante, bate as
## capas como asas e vai pousar em cima de outra estante.
##
## É só enfeite: não tem colisão, não entra em regra nenhuma e cada jogador
## vê a sua própria revoada (não é sincronizado no cooperativo).
##
## `pousos` vem do MoveisDaForja: lista de {"pos": Vector3, "estante": int},
## no espaço deste nó.

const QUANTOS := 6
const ESCALA := 1.7
## Pousado, o livro espera entre estes tempos antes de voar de novo.
const ESPERA_MIN_S := 2.5
const ESPERA_MAX_S := 7.0
const VELOCIDADE_MS := 4.5
const BATIDAS_POR_S := 3.2
const ALTURA_DO_ARCO_M := 2.6
const CAPAS := [Color(0.72, 0.22, 0.22), Color(0.22, 0.42, 0.75), Color(0.26, 0.6, 0.34), Color(0.62, 0.4, 0.8), Color(0.85, 0.62, 0.2)]

var pousos: Array = []
var _livros: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 13
	if pousos.size() < QUANTOS + 1:
		push_warning("LivrosVoadores: só %d lugares de pouso para %d livros; nenhum vai voar." % [pousos.size(), QUANTOS])
		return
	var material := GeometriaLowPoly.material_toon(0.2, 3)
	for k in QUANTOS:
		var livro := _criar_livro(CAPAS[k % CAPAS.size()], material)
		livro.name = "Livro%d" % k
		add_child(livro)
		var dados := {"no": livro, "pouso": k, "destino": -1, "espera": _rng.randf_range(0.5, ESPERA_MAX_S), "t": 0.0, "duracao": 1.0, "bate": _rng.randf() * TAU}
		pousos[k]["ocupado"] = true
		livro.position = pousos[k]["pos"]
		livro.rotation.y = _rng.randf_range(-0.6, 0.6)
		_livros.append(dados)
		_posar(dados, 0.0)


func _process(delta: float) -> void:
	avancar(delta)


## Anda o tempo dos livros (separado do _process para o teste poder acelerar).
func avancar(delta: float) -> void:
	for dados in _livros:
		var livro: Node3D = dados["no"]
		if dados["destino"] < 0:
			dados["espera"] -= delta
			if dados["espera"] <= 0.0:
				_decolar(dados)
			continue
		dados["t"] += delta / dados["duracao"]
		dados["bate"] += delta * BATIDAS_POR_S * TAU
		var f: float = clampf(dados["t"], 0.0, 1.0)
		var de: Vector3 = pousos[dados["pouso"]]["pos"]
		var ate: Vector3 = pousos[dados["destino"]]["pos"]
		# sobe ao decolar, cruza num arco e desce para pousar; balança um pouco
		var suave := f * f * (3.0 - 2.0 * f)
		var pos := de.lerp(ate, suave)
		pos.y += sin(f * PI) * ALTURA_DO_ARCO_M + sin(dados["bate"]) * 0.12 * sin(f * PI)
		var antes := livro.position
		livro.position = pos
		var rumo := pos - antes
		if Vector2(rumo.x, rumo.z).length() > 0.001:
			livro.rotation.y = lerp_angle(livro.rotation.y, atan2(rumo.x, rumo.z), minf(1.0, delta * 6.0))
		# aberto e batendo no ar; fecha e deita ao chegar
		_posar(dados, sin(f * PI))
		if f >= 1.0:
			pousos[dados["pouso"]]["ocupado"] = false
			dados["pouso"] = dados["destino"]
			dados["destino"] = -1
			dados["espera"] = _rng.randf_range(ESPERA_MIN_S, ESPERA_MAX_S)
			livro.position = ate
			_posar(dados, 0.0)


## Quantos livros estão no ar agora.
func voando() -> int:
	return _livros.filter(func(d): return d["destino"] >= 0).size()


func _decolar(dados: Dictionary) -> void:
	var de: Dictionary = pousos[dados["pouso"]]
	var livres: Array = []
	for i in pousos.size():
		if not pousos[i].get("ocupado", false) and pousos[i]["estante"] != de["estante"]:
			livres.append(i)
	if livres.is_empty():
		dados["espera"] = 1.0 # normal: todas as outras estantes cheias; tenta de novo já já
		return
	var destino: int = livres[_rng.randi() % livres.size()]
	pousos[destino]["ocupado"] = true
	dados["destino"] = destino
	dados["t"] = 0.0
	dados["duracao"] = maxf(1.2, (de["pos"] as Vector3).distance_to(pousos[destino]["pos"]) / VELOCIDADE_MS)


## `no_ar` de 0 (pousado: fechado e deitado) a 1 (em pleno voo: aberto, batendo as capas).
func _posar(dados: Dictionary, no_ar: float) -> void:
	var livro: Node3D = dados["no"]
	var corpo: Node3D = livro.get_node("Corpo")
	var abertura := lerpf(1.52, 0.35 + 0.45 * (0.5 + 0.5 * sin(dados["bate"])), clampf(no_ar * 3.0, 0.0, 1.0))
	(corpo.get_node("CapaE") as Node3D).rotation.z = -abertura
	(corpo.get_node("CapaD") as Node3D).rotation.z = abertura
	# pousado, o livro fechado (em pé na lombada) deita de lado
	corpo.rotation.z = lerpf(PI / 2.0, 0.0, clampf(no_ar * 3.0, 0.0, 1.0))
	corpo.position.y = lerpf(0.05, 0.0, clampf(no_ar * 3.0, 0.0, 1.0)) * ESCALA


## Livro de duas metades presas na lombada (eixo Z): cada metade é capa e miolo.
func _criar_livro(capa: Color, material: Material) -> Node3D:
	var G := GeometriaLowPoly
	var livro := Node3D.new()
	var corpo := Node3D.new()
	corpo.name = "Corpo"
	corpo.scale = Vector3.ONE * ESCALA
	livro.add_child(corpo)
	for lado: float in [-1.0, 1.0]:
		var st := G.nova()
		G.anexar(st, G.cubo(Vector3(0.24, 0.025, 0.34)), Transform3D(Basis(), Vector3(lado * 0.12, 0.0, 0.0)), capa)
		G.anexar(st, G.cubo(Vector3(0.21, 0.03, 0.31)), Transform3D(Basis(), Vector3(lado * 0.115, 0.027, 0.0)), Color(0.92, 0.86, 0.7))
		var metade := MeshInstance3D.new()
		metade.name = "CapaE" if lado < 0.0 else "CapaD"
		metade.mesh = G.finalizar(st)
		metade.material_override = material
		metade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		corpo.add_child(metade)
	return livro
