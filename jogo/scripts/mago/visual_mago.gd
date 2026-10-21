class_name VisualMago
extends Node3D
## Corpo do mago visto em terceira pessoa (e pelo parceiro no multiplayer).
## Tosco de propósito (ADR-019): cabeça e chapéu grandes demais, nariz de
## batata, chapéu torto. Cores da referência: manto e chapéu roxos com
## acabamento dourado, cajado com cristal azul brilhando.
## Animação toda em código, sem esqueleto: o corpo balança ao andar, os
## braços vão e voltam e o braço do cajado sobe ao conjurar.

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
var _fase_passo := 0.0
var _conjurando := 0.0


func _ready() -> void:
	var material := GeometriaLowPoly.material_toon(0.3, 3)
	_corpo = MeshInstance3D.new()
	_corpo.name = "Corpo"
	_corpo.mesh = _malha_corpo()
	_corpo.material_override = material
	add_child(_corpo)
	_braco_esquerdo = _criar_braco("BracoEsquerdo", -1.0, material)
	_braco_direito = _criar_braco("BracoDireito", 1.0, material)
	_criar_cajado(_braco_direito, material)


## Chamado pelo mago a cada quadro de física.
func animar(delta: float, velocidade_horizontal: float, no_chao: bool) -> void:
	var andando := clampf(velocidade_horizontal / 5.0, 0.0, 1.0) if no_chao else 0.0
	_fase_passo += delta * 9.0 * andando
	_corpo.position.y = absf(sin(_fase_passo)) * 0.06 * andando
	_corpo.rotation.z = sin(_fase_passo) * 0.05 * andando
	_braco_esquerdo.rotation.x = sin(_fase_passo) * 0.5 * andando
	var braco_direito_x := -sin(_fase_passo) * 0.35 * andando
	if _conjurando > 0.0:
		_conjurando = maxf(0.0, _conjurando - delta)
		# Sobe rápido e desce devagar: o cajado "aponta" para o alvo.
		var t := _conjurando / DURACAO_CONJURACAO_S
		braco_direito_x = lerpf(braco_direito_x, -1.5, sin(t * PI * 0.5))
	_braco_direito.rotation.x = braco_direito_x
	if not no_chao:
		_braco_esquerdo.rotation.z = -0.6
		_braco_direito.rotation.z = 0.6
	else:
		_braco_esquerdo.rotation.z = -0.12
		_braco_direito.rotation.z = 0.12


func conjurar() -> void:
	_conjurando = DURACAO_CONJURACAO_S


func _malha_corpo() -> ArrayMesh:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	# Botas aparecendo embaixo do manto.
	for lado in [-1.0, 1.0]:
		G.anexar(st, G.cubo(Vector3(0.15, 0.14, 0.26)), Transform3D(Basis(), Vector3(0.12 * lado, 0.07, -0.04)), COR_COURO)
	# Manto em forma de sino, com barra dourada.
	G.anexar(st, G.cilindro(0.42, 0.24, 0.85, 7), Transform3D(Basis(), Vector3(0, 0.55, 0)), COR_MANTO)
	G.anexar(st, G.cilindro(0.43, 0.41, 0.07, 7), Transform3D(Basis(), Vector3(0, 0.16, 0)), COR_DOURADO)
	# Cinto com bolsinha.
	G.anexar(st, G.cilindro(0.3, 0.29, 0.08, 7), Transform3D(Basis(), Vector3(0, 0.8, 0)), COR_COURO)
	G.anexar(st, G.cubo(Vector3(0.12, 0.14, 0.08)), Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.24, 0.74, -0.12)), COR_COURO * 1.15)
	G.anexar(st, G.cubo(Vector3(0.05, 0.05, 0.02)), Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.27, 0.78, -0.16)), COR_DOURADO)
	# Tronco e gola.
	G.anexar(st, G.cilindro(0.25, 0.19, 0.32, 7), Transform3D(Basis(), Vector3(0, 1.0, 0)), COR_MANTO_ESCURO)
	G.anexar(st, G.cilindro(0.21, 0.17, 0.06, 7), Transform3D(Basis(), Vector3(0, 1.17, 0)), COR_DOURADO)
	# Cabeça grande, nariz de batata, olhinhos.
	G.anexar(st, G.esfera(0.25, 7, 5), Transform3D(Basis(), Vector3(0, 1.42, 0)), COR_PELE)
	G.anexar(st, G.esfera(0.09, 5, 3), Transform3D(Basis().scaled(Vector3(1.0, 0.9, 1.3)), Vector3(0, 1.38, -0.26)), COR_PELE * 0.95)
	for lado in [-1.0, 1.0]:
		G.anexar(st, G.cubo(Vector3(0.045, 0.07, 0.02)), Transform3D(Basis(), Vector3(0.09 * lado, 1.47, -0.225)), Color(0.08, 0.06, 0.1))
	# Cabelo castanho saindo por baixo do chapéu, atrás e dos lados.
	G.anexar(st, G.cilindro(0.25, 0.27, 0.16, 7), Transform3D(Basis(), Vector3(0, 1.5, 0.04)), Color(0.4, 0.24, 0.13))
	# Chapéu: aba larga, faixa dourada e cone que entorta para trás.
	G.anexar(st, G.cilindro(0.52, 0.5, 0.05, 9), Transform3D(Basis(), Vector3(0, 1.6, 0)), COR_MANTO)
	G.anexar(st, G.cilindro(0.28, 0.26, 0.09, 9), Transform3D(Basis(), Vector3(0, 1.67, 0)), COR_DOURADO)
	G.anexar(st, G.cilindro(0.27, 0.16, 0.4, 9), Transform3D(Basis(), Vector3(0, 1.91, 0)), COR_MANTO)
	G.anexar(st, G.cilindro(0.16, 0.0, 0.45, 9), Transform3D(Basis(Vector3.RIGHT, 0.55), Vector3(0, 2.28, 0.11)), COR_MANTO)
	return G.finalizar(st)


func _criar_braco(nome: String, lado: float, material: Material) -> Node3D:
	var pivo := Node3D.new()
	pivo.name = nome
	pivo.position = Vector3(0.25 * lado, 1.12, 0)
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	G.anexar(st, G.cilindro(0.11, 0.07, 0.45, 6), Transform3D(Basis(), Vector3(0, -0.22, 0)), COR_MANTO)
	G.anexar(st, G.cilindro(0.115, 0.115, 0.05, 6), Transform3D(Basis(), Vector3(0, -0.43, 0)), COR_DOURADO)
	G.anexar(st, G.esfera(0.075, 6, 4), Transform3D(Basis(), Vector3(0, -0.5, 0)), COR_PELE)
	var malha := MeshInstance3D.new()
	malha.mesh = G.finalizar(st)
	malha.material_override = material
	pivo.add_child(malha)
	add_child(pivo)
	return pivo


func _criar_cajado(braco: Node3D, material: Material) -> void:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	G.anexar(st, G.cilindro(0.028, 0.034, 1.5, 6), Transform3D(Basis(), Vector3(0, -0.35, 0)), COR_MADEIRA)
	G.anexar(st, G.cilindro(0.05, 0.05, 0.06, 6), Transform3D(Basis(), Vector3(0, 0.33, 0)), COR_DOURADO)
	var cajado := MeshInstance3D.new()
	cajado.name = "Cajado"
	cajado.mesh = G.finalizar(st)
	cajado.material_override = material
	cajado.position = Vector3(0, -0.5, -0.05)
	braco.add_child(cajado)
	var cristal := MeshInstance3D.new()
	cristal.name = "Cristal"
	cristal.mesh = G.esfera(0.08, 4, 2)
	cristal.scale = Vector3(1.0, 1.7, 1.0)
	cristal.position = Vector3(0, 0.48, 0)
	cristal.material_override = material_cristal()
	cristal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cajado.add_child(cristal)


static func material_cristal() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COR_CRISTAL
	mat.emission_enabled = true
	mat.emission = COR_CRISTAL
	mat.emission_energy_multiplier = 1.3
	return mat
