class_name MaosPrimeiraPessoa
extends Node3D
## O que o jogador vê de si mesmo em primeira pessoa, como na referência:
## a mão esquerda aberta à frente (de onde a magia sai) e a mão direita
## segurando o cajado com o cristal azul. Presas na câmera, sem sombra.
## Ao conjurar, a mão esquerda dá um tranco para a frente e solta um brilho.

const DURACAO_CONJURACAO_S := 0.3

var _esquerda: Node3D
var _direita: Node3D
var _brilho: MeshInstance3D
var _fase_passo := 0.0
var _conjurando := 0.0
var _base_esquerda := Vector3(-0.27, -0.27, -0.42)
var _base_direita := Vector3(0.3, -0.36, -0.5)


func _ready() -> void:
	var material := GeometriaLowPoly.material_toon(0.2, 3)
	_esquerda = _criar_mao_aberta(material)
	_esquerda.position = _base_esquerda
	_esquerda.rotation = Vector3(0.25, 0.35, 0.15)
	_direita = _criar_mao_cajado(material)
	_direita.position = _base_direita
	_direita.rotation = Vector3(-0.45, -0.1, -0.25)
	for m in find_children("*", "GeometryInstance3D", true, false):
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func animar(delta: float, velocidade_horizontal: float, no_chao: bool) -> void:
	var andando := clampf(velocidade_horizontal / 5.0, 0.0, 1.0) if no_chao else 0.0
	_fase_passo += delta * 9.0 * andando
	var balanco := Vector3(sin(_fase_passo * 0.5) * 0.012, absf(sin(_fase_passo * 0.5)) * -0.015, 0.0) * andando
	var tranco := 0.0
	if _conjurando > 0.0:
		_conjurando = maxf(0.0, _conjurando - delta)
		tranco = sin(_conjurando / DURACAO_CONJURACAO_S * PI)
		_brilho.scale = Vector3.ONE * (0.4 + tranco * 1.2)
		_brilho.visible = _conjurando > 0.0
	_esquerda.position = _base_esquerda + balanco + Vector3(0.05, 0.04, -0.1) * tranco
	_direita.position = _base_direita - balanco


func conjurar() -> void:
	_conjurando = DURACAO_CONJURACAO_S


## Ponto um pouco à frente da palma da mão esquerda, em coordenadas do mundo.
func ponto_da_magia() -> Vector3:
	return _esquerda.global_transform * Vector3(0, 0.02, -0.3)


## Mão aberta apontando para a frente (-z), com manga e punho dourado.
func _criar_mao_aberta(material: Material) -> Node3D:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	var deitado := Basis(Vector3.RIGHT, -PI / 2.0)
	G.anexar(st, G.cilindro(0.085, 0.055, 0.42, 7), Transform3D(deitado, Vector3(0, 0, 0.12)), VisualMago.COR_MANTO)
	G.anexar(st, G.cilindro(0.062, 0.062, 0.04, 7), Transform3D(deitado, Vector3(0, 0, -0.09)), VisualMago.COR_DOURADO)
	G.anexar(st, G.cubo(Vector3(0.095, 0.03, 0.1)), Transform3D(Basis(), Vector3(0, 0, -0.15)), VisualMago.COR_PELE)
	for i in 4:
		var x := -0.035 + i * 0.023
		var comprimento := 0.075 if i in [1, 2] else 0.062
		var abertura := Basis(Vector3.UP, (i - 1.5) * -0.12)
		G.anexar(st, G.cubo(Vector3(0.019, 0.019, comprimento)),
			Transform3D(abertura, Vector3(x * 1.15, 0.0, -0.2 - comprimento / 2.0)), VisualMago.COR_PELE)
	G.anexar(st, G.cubo(Vector3(0.02, 0.02, 0.06)), Transform3D(Basis(Vector3.UP, -0.8), Vector3(0.065, 0.0, -0.15)), VisualMago.COR_PELE)
	var no := Node3D.new()
	no.name = "MaoEsquerda"
	var malha := MeshInstance3D.new()
	malha.mesh = G.finalizar(st)
	malha.material_override = material
	no.add_child(malha)
	_brilho = MeshInstance3D.new()
	_brilho.name = "Brilho"
	_brilho.mesh = G.esfera(0.06, 6, 4)
	_brilho.position = Vector3(0, 0.02, -0.25)
	_brilho.material_override = VisualMago.material_cristal()
	_brilho.visible = false
	no.add_child(_brilho)
	add_child(no)
	return no


## Punho fechado segurando o cajado em pé, com o cristal no alto.
func _criar_mao_cajado(material: Material) -> Node3D:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	var deitado := Basis(Vector3.RIGHT, -PI / 2.0)
	G.anexar(st, G.cilindro(0.09, 0.06, 0.4, 7), Transform3D(Basis(Vector3.RIGHT, -PI / 2.0 + 0.45), Vector3(0, -0.1, 0.14)), VisualMago.COR_MANTO)
	G.anexar(st, G.cilindro(0.066, 0.066, 0.04, 7), Transform3D(deitado, Vector3(0, -0.02, -0.04)), VisualMago.COR_DOURADO)
	G.anexar(st, G.esfera(0.055, 6, 4), Transform3D(Basis().scaled(Vector3(1.0, 1.1, 1.0)), Vector3(0, -0.01, -0.08)), VisualMago.COR_PELE)
	G.anexar(st, G.cilindro(0.02, 0.024, 0.75, 6), Transform3D(Basis(), Vector3(0, 0.08, -0.08)), VisualMago.COR_MADEIRA)
	G.anexar(st, G.cilindro(0.034, 0.034, 0.04, 6), Transform3D(Basis(), Vector3(0, 0.44, -0.08)), VisualMago.COR_DOURADO)
	var no := Node3D.new()
	no.name = "MaoCajado"
	var malha := MeshInstance3D.new()
	malha.mesh = G.finalizar(st)
	malha.material_override = material
	no.add_child(malha)
	var cristal := MeshInstance3D.new()
	cristal.name = "Cristal"
	cristal.mesh = G.esfera(0.05, 4, 2)
	cristal.scale = Vector3(1.0, 1.7, 1.0)
	cristal.position = Vector3(0, 0.53, -0.08)
	cristal.material_override = VisualMago.material_cristal()
	no.add_child(cristal)
	add_child(no)
	return no
