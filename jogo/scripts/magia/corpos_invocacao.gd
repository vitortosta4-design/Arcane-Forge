class_name CorposInvocacao
extends RefCounted
## Corpo visível das criaturas invocadas, pelo campo "corpo" da ficha
## (Validador.CORPOS_VALIDOS). Antes todas eram a mesma bola colorida.
##
## - ave: a galinha v4 com esqueleto e animações (VisualGalinha), a mesma
##   da galinha zumbi;
## - quadrupede, bolha, verme: provisórios montados em código, com silhueta
##   própria (juba, braços de pedra, gomos) e olhos esbugalhados (ADR-019),
##   até o Vitor mandar as folhas de referência e a skill personagem-low-poly
##   fazer os modelos de verdade (leão, golem).
## A frente é -Z, igual ao look_at da criatura.

const COR_OLHO := Color(1, 1, 1)
const COR_PUPILA := Color(0.05, 0.05, 0.07)


const COR_LEAO := Color(0.86, 0.62, 0.3)


static func criar(corpo: String, cor: Color, material := "") -> Node3D:
	match corpo:
		"ave":
			return _ave()
		"quadrupede":
			# Madeira não tem cara de leão: o quadrúpede "comum" fica dourado.
			return _malha(_quadrupede(COR_LEAO if material == "madeira" else cor))
		"verme":
			return _malha(_verme(cor))
		_:
			var golem := _malha(_bolha(cor))
			golem.position.y = 0.12
			return golem


static func _ave() -> Node3D:
	return VisualGalinha.criar(false)


static func _malha(st: SurfaceTool) -> Node3D:
	var m := MeshInstance3D.new()
	m.mesh = GeometriaLowPoly.finalizar(st)
	m.material_override = GeometriaLowPoly.material_toon(0.3, 3)
	return m


static func _olhos(st: SurfaceTool, centro: Vector3, afastamento: float, tamanho: float) -> void:
	var G := GeometriaLowPoly
	for lado in [-1.0, 1.0]:
		var p := centro + Vector3(lado * afastamento, 0, 0)
		G.anexar(st, G.esfera(tamanho, 6, 4), Transform3D(Basis(), p), COR_OLHO)
		G.anexar(st, G.esfera(tamanho * 0.45, 5, 3), Transform3D(Basis(), p + Vector3(lado * 0.02, 0.02, -tamanho * 0.8)), COR_PUPILA)


## Leão: corpo comprido, juba grande em volta da cabeça, rabo com tufo.
static func _quadrupede(cor: Color) -> SurfaceTool:
	var G := GeometriaLowPoly
	var st := G.nova()
	var escuro := Color(0.62, 0.3, 0.12) if cor == COR_LEAO else cor.darkened(0.35)
	G.anexar(st, G.cubo(Vector3(0.55, 0.45, 1.0)), Transform3D(Basis(), Vector3(0, 0.05, 0.05)), cor)
	for x in [-0.2, 0.2]:
		for z in [-0.35, 0.4]:
			G.anexar(st, G.cilindro(0.09, 0.08, 0.45, 5), Transform3D(Basis(), Vector3(x, -0.32, z)), cor.darkened(0.1))
	G.anexar(st, G.esfera(0.42, 7, 4), Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.7)), Vector3(0, 0.38, -0.5)), escuro)
	G.anexar(st, G.cubo(Vector3(0.38, 0.36, 0.34)), Transform3D(Basis(), Vector3(0, 0.36, -0.68)), cor)
	G.anexar(st, G.cubo(Vector3(0.2, 0.14, 0.16)), Transform3D(Basis(), Vector3(0, 0.27, -0.88)), cor.lightened(0.2))
	_olhos(st, Vector3(0, 0.46, -0.84), 0.1, 0.07)
	G.anexar(st, G.cilindro(0.03, 0.03, 0.55, 4), Transform3D(Basis(Vector3.RIGHT, -1.0), Vector3(0, 0.25, 0.75)), cor)
	G.anexar(st, G.esfera(0.09, 5, 3), Transform3D(Basis(), Vector3(0, 0.45, 0.98)), escuro)
	return st


## Golem: bolotão de pedra/fogo com braços pesados e olhos pequenos.
static func _bolha(cor: Color) -> SurfaceTool:
	var G := GeometriaLowPoly
	var st := G.nova()
	G.anexar(st, G.esfera(0.5, 7, 5), Transform3D(Basis().scaled(Vector3(1.0, 0.9, 0.85)), Vector3(0, 0.0, 0)), cor)
	G.anexar(st, G.esfera(0.24, 6, 4), Transform3D(Basis(), Vector3(0, 0.48, -0.1)), cor.darkened(0.15))
	for lado in [-1.0, 1.0]:
		G.anexar(st, G.esfera(0.2, 6, 4), Transform3D(Basis().scaled(Vector3(1, 1.6, 1)), Vector3(lado * 0.55, -0.05, -0.05)), cor.darkened(0.25))
	_olhos(st, Vector3(0, 0.52, -0.3), 0.09, 0.06)
	return st


## Verme: gomos que diminuem para trás.
static func _verme(cor: Color) -> SurfaceTool:
	var G := GeometriaLowPoly
	var st := G.nova()
	for k in 4:
		var r := 0.3 - k * 0.05
		G.anexar(st, G.esfera(r, 6, 4), Transform3D(Basis(), Vector3(0, -0.25 + r, -0.2 + k * 0.32)), cor if k % 2 == 0 else cor.darkened(0.15))
	_olhos(st, Vector3(0, 0.18, -0.42), 0.1, 0.07)
	return st
