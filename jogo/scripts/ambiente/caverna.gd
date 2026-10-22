class_name Caverna
extends Node3D
## Caverna provisória da forja (ADR-035, Fase 2): uma boca de pedra na
## encosta leste da clareira e uma câmara grande, com a bigorna viva no meio.
##
## A câmara fica longe, embaixo do mapa, e a boca leva até ela com um puf
## (como uma porta de casa em jogo de aventura). Escavar túnel de verdade no
## relevo exigiria mexer no terreno inteiro; isso fica para a caverna
## definitiva da Fase 5. Aqui o que importa é o ciclo: achar runas, entrar,
## forjar, sair e lutar.

const BOCA := Vector2(22.0, 2.0)
const CENTRO_CAMARA := Vector3(0.0, -80.0, 0.0)
const RAIO_CAMARA := 15.0
const COR_PEDRA := Color(0.36, 0.33, 0.4)
const COR_CHAO := Color(0.3, 0.27, 0.32)
const COR_BURACO := Color(0.03, 0.02, 0.05)
const CORES_CRISTAL := [Color(0.6, 0.35, 1.0), Color(0.3, 0.75, 1.0)]

var forja: Forja = null
var _boca_chao := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _material := GeometriaLowPoly.material_toon(0.2, 3)


func _ready() -> void:
	_rng.seed = 7
	var clareira := get_parent().get_node_or_null("Clareira") as Clareira
	var altura := clareira.altura_em(BOCA.x, BOCA.y) if clareira else 0.0
	_boca_chao = Vector3(BOCA.x, altura, BOCA.y)
	_criar_boca()
	_criar_camara()


## Para onde o mago vai ao entrar e ao sair (virado para a bigorna / para o
## centro da clareira).
func entrada_camara() -> Vector3:
	return CENTRO_CAMARA + Vector3(10.5, 1.0, 0.0)


func saida_clareira() -> Vector3:
	return _boca_chao + Vector3(-3.2, 1.0, 0.0)


# --- Boca na clareira -----------------------------------------------------

func _criar_boca() -> void:
	var G := GeometriaLowPoly
	var st := G.nova()
	var colisores := StaticBody3D.new()
	colisores.collision_layer = 1
	colisores.collision_mask = 0
	var b := _boca_chao
	# Morro de pedra atrás da boca e dois pilares tortos com uma laje em cima.
	_pedregulho(st, colisores, b + Vector3(3.5, 1.5, 0), Vector3(4.5, 4.5, 6.5))
	_pedregulho(st, colisores, b + Vector3(0.2, 1.4, -2.6), Vector3(1.6, 3.0, 1.6))
	_pedregulho(st, colisores, b + Vector3(0.2, 1.4, 2.6), Vector3(1.6, 3.2, 1.6))
	_pedregulho(st, colisores, b + Vector3(0.4, 4.2, 0.0), Vector3(2.2, 1.2, 4.2))
	var malha := MeshInstance3D.new()
	malha.name = "BocaCaverna"
	malha.mesh = G.finalizar(st)
	malha.material_override = _material
	add_child(malha)
	add_child(colisores)

	# O "buraco": uma placa escura com uma luz roxa fraca de dentro, que
	# chama o jogador ("tem algo ali").
	var buraco := MeshInstance3D.new()
	buraco.name = "Buraco"
	buraco.mesh = G.cubo(Vector3(0.2, 3.4, 3.2))
	buraco.position = b + Vector3(0.9, 1.7, 0.0)
	buraco.material_override = _material_escuro()
	add_child(buraco)
	var luz := OmniLight3D.new()
	luz.light_color = CORES_CRISTAL[0]
	luz.light_energy = 1.5
	luz.omni_range = 5.0
	luz.position = b + Vector3(-0.3, 1.8, 0.0)
	add_child(luz)
	_gatilho(b + Vector3(0.3, 1.5, 0.0), Vector3(1.2, 3.0, 3.0), true)


# --- Câmara ---------------------------------------------------------------

func _criar_camara() -> void:
	var G := GeometriaLowPoly
	var c := CENTRO_CAMARA
	var st := G.nova()
	# Cúpula facetada vista por dentro, achatada para o teto ficar a ~11 m.
	G.anexar_invertido(st, G.esfera(RAIO_CAMARA, 14, 7),
		Transform3D(Basis().scaled(Vector3(1.0, 0.75, 1.0)), c), COR_PEDRA)
	# Chão.
	G.anexar(st, G.cilindro(RAIO_CAMARA, RAIO_CAMARA, 1.0, 14), Transform3D(Basis(), c + Vector3.DOWN * 0.5), COR_CHAO)
	# Estalactites.
	for i in 14:
		var a := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(4.0, RAIO_CAMARA - 3.0)
		var comprimento := _rng.randf_range(1.2, 3.2)
		var topo := c + Vector3(cos(a) * r, sqrt(maxf(0.0, 1.0 - pow(r / RAIO_CAMARA, 2))) * RAIO_CAMARA * 0.75, sin(a) * r)
		G.anexar(st, G.cilindro(0.0, _rng.randf_range(0.4, 0.8), comprimento, 5),
			Transform3D(Basis(), topo + Vector3.DOWN * comprimento / 2.0), COR_PEDRA * 0.9)
	var malha := G.finalizar(st)
	var camara := StaticBody3D.new()
	camara.name = "Camara"
	camara.collision_layer = 1
	camara.collision_mask = 0
	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.material_override = _material
	# As faces da cúpula olham para dentro; sem sombra dos dois lados o sol
	# atravessava o teto e desenhava sombra no chão da caverna.
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	camara.add_child(visual)
	var forma := ConcavePolygonShape3D.new()
	forma.set_faces(malha.get_faces())
	forma.backface_collision = true
	var col := CollisionShape3D.new()
	col.shape = forma
	camara.add_child(col)
	add_child(camara)

	# Cristais que iluminam a câmara (a única luz além da bigorna).
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var p := c + Vector3(cos(a), 0, sin(a)) * (RAIO_CAMARA - 2.5)
		if p.x > c.x + 8.0 and absf(p.z - c.z) < 5.0:
			continue
		_cristais(p, CORES_CRISTAL[i % 2])

	# Saída: um buraco escuro na parede atrás de quem entra.
	var saida := MeshInstance3D.new()
	saida.name = "Saida"
	saida.mesh = G.cubo(Vector3(0.3, 3.4, 3.2))
	saida.position = c + Vector3(RAIO_CAMARA - 1.6, 1.7, 0.0)
	saida.material_override = _material_escuro()
	add_child(saida)
	_gatilho(c + Vector3(RAIO_CAMARA - 2.2, 1.5, 0.0), Vector3(1.0, 3.0, 3.0), false)

	forja = Forja.new()
	forja.name = "Forja"
	forja.position = c
	forja.rotation.y = PI / 2.0
	add_child(forja)


func _cristais(base: Vector3, cor: Color) -> void:
	var G := GeometriaLowPoly
	var st := G.nova()
	for k in 4:
		var altura := _rng.randf_range(1.0, 2.6)
		var inclinado := Basis(Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized(), _rng.randf_range(0.1, 0.5))
		G.anexar(st, G.cilindro(_rng.randf_range(0.18, 0.35), 0.0, altura, 5),
			Transform3D(inclinado, base + Vector3(_rng.randf_range(-0.6, 0.6), altura / 2.0, _rng.randf_range(-0.6, 0.6))), cor)
	var cristal := MeshInstance3D.new()
	cristal.mesh = G.finalizar(st)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = cor
	mat.emission_energy_multiplier = 2.0
	cristal.material_override = mat
	cristal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cristal)
	var luz := OmniLight3D.new()
	luz.light_color = cor
	luz.light_energy = 1.4
	luz.omni_range = 9.0
	luz.position = base + Vector3.UP * 1.6
	add_child(luz)


# --- Utilidades -------------------------------------------------------------

func _pedregulho(st: SurfaceTool, colisores: StaticBody3D, centro: Vector3, tamanho: Vector3) -> void:
	var giro := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
	var cor := GeometriaLowPoly.variar(Color(0.46, 0.43, 0.46), _rng)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.esfera(0.5, 6, 3), Transform3D(giro.scaled(tamanho), centro), cor)
	var forma := BoxShape3D.new()
	forma.size = tamanho * 0.8
	var c := CollisionShape3D.new()
	c.shape = forma
	c.transform = Transform3D(giro, centro)
	colisores.add_child(c)


func _material_escuro() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = COR_BURACO
	return mat


## Área que leva o mago para dentro (entrando) ou para fora (saindo).
func _gatilho(posicao: Vector3, tamanho: Vector3, entrando: bool) -> void:
	var area := Area3D.new()
	area.name = "Entrar" if entrando else "Sair"
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = posicao
	var forma := BoxShape3D.new()
	forma.size = tamanho
	var c := CollisionShape3D.new()
	c.shape = forma
	area.add_child(c)
	add_child(area)
	area.body_entered.connect(func(corpo: Node) -> void:
		if corpo.is_in_group("mago"):
			levar.call_deferred(corpo, entrando))


func levar(mago: Node3D, entrando: bool) -> void:
	mago.global_position = entrada_camara() if entrando else saida_clareira()
	mago.rotation.y = PI / 2.0
	mago.velocity = Vector3.ZERO
	mago.teleportou.emit()
