class_name VisualMago
extends Node3D
## Corpo do mago visto em terceira pessoa (e pelo parceiro no multiplayer).
## Tosco de propósito (ADR-019): cabeça e chapéu grandes demais, nariz de
## batata, chapéu torto. Cores da referência: manto e chapéu roxos com
## acabamento dourado, cajado com cristal azul brilhando.
## Proporção ajustada em 21/10/2026 a pedido do Vitor (jogou de verdade e
## achou o boneco alto/cabeça pequena demais): corpo mais baixo e atarracado,
## cabeça maior. Braço ganhou cotovelo (dois segmentos) para animar de
## verdade, em vez de um taco rígido girando no ombro. Capa, botões e broche
## dourado são o "acabamento de roupa" que ele pediu.
## Animação toda em código, sem esqueleto.

const COR_MANTO := Color(0.3, 0.22, 0.58)
const COR_MANTO_ESCURO := Color(0.22, 0.16, 0.44)
const COR_DOURADO := Color(0.95, 0.72, 0.25)
const COR_PELE := Color(0.88, 0.63, 0.48)
const COR_COURO := Color(0.42, 0.26, 0.15)
const COR_MADEIRA := Color(0.5, 0.32, 0.18)
const COR_CRISTAL := Color(0.3, 0.62, 1.0)

const DURACAO_CONJURACAO_S := 0.35

var _corpo: MeshInstance3D
var _braco_esquerdo: Node3D
var _braco_direito: Node3D
var _cotovelo_esquerdo: Node3D
var _cotovelo_direito: Node3D
var _cristal: Node3D
var _fase_passo := 0.0
var _tempo_idle := 0.0
var _conjurando := 0.0


func _ready() -> void:
	var material := GeometriaLowPoly.material_toon(0.3, 3)
	_corpo = MeshInstance3D.new()
	_corpo.name = "Corpo"
	_corpo.mesh = _malha_corpo()
	_corpo.material_override = material
	add_child(_corpo)
	var par_esquerdo := _criar_braco("BracoEsquerdo", -1.0, material)
	_braco_esquerdo = par_esquerdo[0]
	_cotovelo_esquerdo = par_esquerdo[1]
	var par_direito := _criar_braco("BracoDireito", 1.0, material)
	_braco_direito = par_direito[0]
	_cotovelo_direito = par_direito[1]
	_criar_cajado(_cotovelo_direito, material)


## Chamado pelo mago a cada quadro de física.
func animar(delta: float, velocidade_horizontal: float, no_chao: bool) -> void:
	var andando := clampf(velocidade_horizontal / 5.0, 0.0, 1.0) if no_chao else 0.0
	_fase_passo += delta * 9.0 * andando
	_tempo_idle += delta
	_corpo.position.y = absf(sin(_fase_passo)) * 0.05 * andando
	_corpo.rotation.z = sin(_fase_passo) * 0.05 * andando

	# Balanço de respiração, sempre ligado (mais forte parado), para o
	# boneco nunca ficar completamente congelado parado.
	var balanco_ocioso := sin(_tempo_idle * 1.3) * 0.035 * (1.0 - andando)

	_braco_esquerdo.rotation.x = sin(_fase_passo) * 0.6 * andando + balanco_ocioso
	_cotovelo_esquerdo.rotation.x = -(0.12 + absf(sin(_fase_passo)) * 0.35) * andando - 0.08

	var braco_direito_x := -sin(_fase_passo) * 0.42 * andando + balanco_ocioso
	var cotovelo_direito_x := -(0.12 + absf(sin(_fase_passo)) * 0.35) * andando - 0.08

	if _conjurando > 0.0:
		_conjurando = maxf(0.0, _conjurando - delta)
		# Sobe rápido e desce devagar: o ombro levanta e o cotovelo estica,
		# como se o cajado "apontasse" para o alvo.
		var t := _conjurando / DURACAO_CONJURACAO_S
		var impulso := sin(t * PI * 0.5)
		braco_direito_x = lerpf(braco_direito_x, -1.7, impulso)
		cotovelo_direito_x = lerpf(cotovelo_direito_x, -0.25, impulso)

	_braco_direito.rotation.x = braco_direito_x
	_cotovelo_direito.rotation.x = cotovelo_direito_x

	if not no_chao:
		_braco_esquerdo.rotation.z = -0.6
		_braco_direito.rotation.z = 0.6
	else:
		_braco_esquerdo.rotation.z = -0.12
		_braco_direito.rotation.z = 0.12


func conjurar() -> void:
	_conjurando = DURACAO_CONJURACAO_S


## Ponto um pouco à frente do cristal do cajado, em coordenadas do mundo.
func ponto_da_magia() -> Vector3:
	return _cristal.global_position + -global_transform.basis.z * 0.3


func _malha_corpo() -> ArrayMesh:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	# Botas aparecendo embaixo do manto.
	for lado in [-1.0, 1.0]:
		G.anexar(st, G.cubo(Vector3(0.16, 0.12, 0.28)), Transform3D(Basis(), Vector3(0.13 * lado, 0.06, -0.04)), COR_COURO)
	# Manto em forma de sino, mais curto e mais largo (corpo baixo e atarracado).
	G.anexar(st, G.cilindro(0.46, 0.26, 0.66, 7), Transform3D(Basis(), Vector3(0, 0.43, 0)), COR_MANTO)
	G.anexar(st, G.cilindro(0.47, 0.44, 0.06, 7), Transform3D(Basis(), Vector3(0, 0.13, 0)), COR_DOURADO)
	# Cinto com bolsinha.
	G.anexar(st, G.cilindro(0.33, 0.32, 0.07, 7), Transform3D(Basis(), Vector3(0, 0.62, 0)), COR_COURO)
	G.anexar(st, G.cubo(Vector3(0.13, 0.15, 0.09)), Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.26, 0.577, -0.13)), COR_COURO * 1.15)
	G.anexar(st, G.cubo(Vector3(0.055, 0.055, 0.022)), Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.29, 0.605, -0.17)), COR_DOURADO)
	# Tronco e gola.
	G.anexar(st, G.cilindro(0.28, 0.22, 0.27, 7), Transform3D(Basis(), Vector3(0, 0.80, 0)), COR_MANTO_ESCURO)
	G.anexar(st, G.cilindro(0.24, 0.20, 0.055, 7), Transform3D(Basis(), Vector3(0, 0.935, 0)), COR_DOURADO)
	# Botões dourados descendo pela frente do manto (acabamento da roupa).
	for altura in [0.70, 0.56, 0.42]:
		G.anexar(st, G.esfera(0.025, 5, 3), Transform3D(Basis(), Vector3(0, altura, -0.27)), COR_DOURADO)
	# Broche em losango no peito, por baixo da gola.
	G.anexar(st, G.cubo(Vector3(0.1, 0.1, 0.02)), Transform3D(Basis(Vector3.FORWARD, 0.785), Vector3(0, 0.87, -0.225)), COR_DOURADO)
	# Capa: dois painéis atrás dos ombros, descendo e abrindo (visível dos
	# dois lados, já que o jogador gira a câmera em volta do boneco).
	_capa(st, G)
	# Cabeça grande, nariz de batata, olhinhos (proporção mais cabeçuda).
	G.anexar(st, G.esfera(0.30, 7, 5), Transform3D(Basis(), Vector3(0, 1.26, 0)), COR_PELE)
	G.anexar(st, G.esfera(0.108, 5, 3), Transform3D(Basis().scaled(Vector3(1.0, 0.9, 1.3)), Vector3(0, 1.212, -0.312)), COR_PELE * 0.95)
	for lado in [-1.0, 1.0]:
		G.anexar(st, G.cubo(Vector3(0.054, 0.084, 0.024)), Transform3D(Basis(), Vector3(0.108 * lado, 1.32, -0.27)), Color(0.08, 0.06, 0.1))
	# Cabelo castanho saindo por baixo do chapéu, atrás e dos lados.
	G.anexar(st, G.cilindro(0.30, 0.324, 0.192, 7), Transform3D(Basis(), Vector3(0, 1.356, 0.048)), Color(0.4, 0.24, 0.13))
	# Chapéu: aba larga, faixa dourada e cone que entorta para trás.
	G.anexar(st, G.cilindro(0.624, 0.6, 0.06, 9), Transform3D(Basis(), Vector3(0, 1.476, 0)), COR_MANTO)
	G.anexar(st, G.cilindro(0.336, 0.312, 0.108, 9), Transform3D(Basis(), Vector3(0, 1.56, 0)), COR_DOURADO)
	G.anexar(st, G.cilindro(0.324, 0.192, 0.48, 9), Transform3D(Basis(), Vector3(0, 1.848, 0)), COR_MANTO)
	G.anexar(st, G.cilindro(0.192, 0.0, 0.54, 9), Transform3D(Basis(Vector3.RIGHT, 0.55), Vector3(0, 2.292, 0.132)), COR_MANTO)
	return G.finalizar(st)


## Dois painéis de capa saindo de trás da gola, abrindo para os lados e
## descendo até perto da altura do cinto. Desenhados nos dois sentidos
## (frente e verso) para não sumir quando vistos por trás.
func _capa(st: SurfaceTool, G) -> void:
	var cor := COR_MANTO_ESCURO
	for lado in [-1.0, 1.0]:
		var topo_interno := Vector3(0.05 * lado, 0.95, 0.17)
		var topo_externo := Vector3(0.24 * lado, 0.92, 0.1)
		var base := Vector3(0.30 * lado, 0.38, 0.32)
		G.triangulo(st, topo_interno, base, topo_externo, cor)
		G.triangulo(st, topo_interno, topo_externo, base, cor)


## Cria um braço com ombro e cotovelo. Devolve [pivô do ombro, pivô do
## cotovelo], os dois são nós na árvore (o cotovelo é filho do ombro).
func _criar_braco(nome: String, lado: float, material: Material) -> Array:
	var ombro := Node3D.new()
	ombro.name = nome
	ombro.position = Vector3(0.27 * lado, 0.90, 0)
	add_child(ombro)

	var st_superior := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	G.anexar(st_superior, G.esfera(0.1, 6, 4), Transform3D(Basis(), Vector3.ZERO), COR_MANTO)
	G.anexar(st_superior, G.cilindro(0.115, 0.085, 0.20, 6), Transform3D(Basis(), Vector3(0, -0.10, 0)), COR_MANTO)
	var malha_superior := MeshInstance3D.new()
	malha_superior.mesh = G.finalizar(st_superior)
	malha_superior.material_override = material
	ombro.add_child(malha_superior)

	var cotovelo := Node3D.new()
	cotovelo.name = "Cotovelo"
	cotovelo.position = Vector3(0, -0.20, 0)
	ombro.add_child(cotovelo)

	var st_inferior := GeometriaLowPoly.nova()
	G.anexar(st_inferior, G.cilindro(0.085, 0.065, 0.19, 6), Transform3D(Basis(), Vector3(0, -0.095, 0)), COR_MANTO)
	G.anexar(st_inferior, G.cilindro(0.075, 0.075, 0.03, 6), Transform3D(Basis(), Vector3(0, -0.185, 0)), COR_DOURADO)
	G.anexar(st_inferior, G.esfera(0.08, 6, 4), Transform3D(Basis(), Vector3(0, -0.21, 0)), COR_PELE)
	var malha_inferior := MeshInstance3D.new()
	malha_inferior.mesh = G.finalizar(st_inferior)
	malha_inferior.material_override = material
	cotovelo.add_child(malha_inferior)

	return [ombro, cotovelo]


func _criar_cajado(cotovelo: Node3D, material: Material) -> void:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	G.anexar(st, G.cilindro(0.024, 0.029, 1.28, 6), Transform3D(Basis(), Vector3(0, -0.30, 0)), COR_MADEIRA)
	G.anexar(st, G.cilindro(0.043, 0.043, 0.05, 6), Transform3D(Basis(), Vector3(0, 0.28, 0)), COR_DOURADO)
	var cajado := MeshInstance3D.new()
	cajado.name = "Cajado"
	cajado.mesh = G.finalizar(st)
	cajado.material_override = material
	cajado.position = Vector3(0, -0.21, -0.04)
	cotovelo.add_child(cajado)
	var cristal := MeshInstance3D.new()
	cristal.name = "Cristal"
	cristal.mesh = G.esfera(0.07, 4, 2)
	cristal.scale = Vector3(1.0, 1.7, 1.0)
	cristal.position = Vector3(0, 0.41, 0)
	cristal.material_override = material_cristal()
	cristal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cajado.add_child(cristal)
	_cristal = cristal


static func material_cristal() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COR_CRISTAL
	mat.emission_enabled = true
	mat.emission = COR_CRISTAL
	mat.emission_energy_multiplier = 1.3
	return mat
