class_name Clareira
extends Node3D
## Módulo "clareira" (ADR-018), feito no padrão visual final para servir de
## molde aos outros módulos da Fase 7 e, até lá, de arena de testes.
## Pedido do Vitor em 21/10/2026: "igual à referência"
## (docs/referencias/arte-conceito-01.png): trilha de terra alaranjada,
## grama saturada, pinheiros, ruínas de pedra com estandartes azuis, morros
## em volta e um castelo sobre um penhasco no fundo, com cachoeira e ilhas
## flutuantes no céu.
##
## Tudo é gerado em código a partir de uma semente fixa, então o resultado é
## sempre o mesmo. O centro (raio RAIO_PLANO) é plano de propósito: é onde se
## luta, e a física e a mira ficam previsíveis.

const SEMENTE := 20261021
const TAMANHO := 140.0
const DIVISOES := 100
const RAIO_PLANO := 20.0
const LARGURA_SUBIDA := 9.0
const LARGURA_TRILHA := 2.2
## Até onde os pinheiros ganham colisão (mais longe ninguém chega).
const RAIO_COLISAO_ARVORES := 34.0

const COR_GRAMA := Color(0.35, 0.5, 0.2)
const COR_GRAMA_ESCURA := Color(0.2, 0.36, 0.15)
const COR_TERRA := Color(0.66, 0.46, 0.29)
const COR_TERRA_ESCURA := Color(0.5, 0.35, 0.24)
const COR_ROCHA := Color(0.46, 0.44, 0.42)
const COR_PEDRA_RUINA := Color(0.58, 0.54, 0.48)
const COR_MUSGO := Color(0.33, 0.47, 0.2)
const COR_TRONCO := Color(0.42, 0.27, 0.16)
const COR_PINHEIRO := Color(0.14, 0.34, 0.22)
const COR_COPA := Color(0.32, 0.5, 0.2)
const COR_ESTANDARTE := Color(0.16, 0.26, 0.7)
const COR_DOURADO := Color(0.95, 0.72, 0.25)
const COR_TELHADO := Color(0.36, 0.3, 0.72)
## Fundo (camada 0 da paleta): puxa para o azul da névoa, não para o verde
## do chão, para o fundo "descansar" e o perto ganhar destaque.
const COR_MONTANHA := Color(0.36, 0.46, 0.52)
const COR_NEVE := Color(0.72, 0.74, 0.8)
## Tochas no muro de arcos (ADR-036, escolha 3c do Vitor): com o sol vindo de
## oeste-sudoeste o muro fica em contraluz, e a luz quente das tochas devolve
## o foco às ruínas, como na referência.
const COR_TOCHA := Color(1.0, 0.6, 0.28)
const ENERGIA_TOCHA := 2.6
const ALCANCE_TOCHA := 7.5
## Pontos fixos de runa (ADR-035, Fase 2). Na Fase 7 o gerador de mapas
## sorteia estes pontos; por enquanto são sempre os mesmos.
const PONTOS_RUNA := [
	["fogo", Vector2(6, -6)], ["agua", Vector2(-8, 6)], ["feroz", Vector2(12, 4)],
	["vida", Vector2(-10, -8)], ["arremesso", Vector2(3, 12)], ["prende", Vector2(15, -12)],
	["fogo", Vector2(-3, -14)],
]

var _ruido := FastNoiseLite.new()
var _ruido_morros := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _material := GeometriaLowPoly.material_toon(0.25, 3)
var _ilhas: Array[Node3D] = []
var _luzes_tocha: Array[OmniLight3D] = []
var _tempo := 0.0


func _init() -> void:
	_ruido.seed = SEMENTE
	_ruido.frequency = 0.05
	_ruido_morros.seed = SEMENTE + 1
	_ruido_morros.frequency = 0.025


func _ready() -> void:
	_rng.seed = SEMENTE
	_criar_terreno()
	_criar_arvores()
	_criar_rochas()
	_criar_grama()
	_criar_ruinas()
	_criar_tochas()
	_criar_runas()
	_criar_fundo()


func _process(delta: float) -> void:
	_tempo += delta
	for i in _ilhas.size():
		var ilha := _ilhas[i]
		ilha.position.y = ilha.get_meta("altura_base") + sin(_tempo * 0.4 + i * 2.1) * 1.2
	# Chama tremulando: duas ondas fora de compasso, para não parecer pisca-pisca.
	for i in _luzes_tocha.size():
		var luz := _luzes_tocha[i]
		luz.light_energy = ENERGIA_TOCHA * (1.0 + sin(_tempo * 9.0 + i * 1.7) * 0.07 + sin(_tempo * 23.0 + i) * 0.04)


# --- Relevo ---------------------------------------------------------------

## Centro da trilha de terra para um dado z: uma curva suave de sul a norte.
static func centro_trilha(z: float) -> float:
	return 2.5 * sin(z * 0.07)


## 0 longe da trilha, 1 em cima dela.
func faixa_trilha(x: float, z: float) -> float:
	var distancia := absf(x - centro_trilha(z)) + _ruido.get_noise_2d(x * 3.0, z * 3.0) * 0.6
	return 1.0 - smoothstep(LARGURA_TRILHA * 0.6, LARGURA_TRILHA, distancia)


## Altura do chão em (x, z). Zero exato dentro do raio de luta.
func altura_em(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var borda := RAIO_PLANO + _ruido.get_noise_2d(x, z) * 2.5
	var subida := smoothstep(0.0, 1.0, clampf((r - borda) / LARGURA_SUBIDA, 0.0, 1.0))
	if subida <= 0.0:
		return 0.0
	var morro := 4.0 + (_ruido_morros.get_noise_2d(x, z) * 0.5 + 0.5) * 10.0
	# Ao norte, um vale por onde a trilha segue até a borda, para o castelo
	# aparecer no fundo; na ponta do vale o chão sobe um pouco e esconde a
	# borda do terreno.
	var no_vale := smoothstep(-RAIO_PLANO + 2.0, -RAIO_PLANO - 8.0, z)
	var largura_vale := smoothstep(7.0, 16.0, absf(x - centro_trilha(z)))
	var fim_vale := smoothstep(58.0, 66.0, -z)
	var fator_vale := lerpf(1.0, maxf(largura_vale, 0.15), no_vale)
	var altura := subida * morro * fator_vale
	altura = maxf(altura, fim_vale * 4.5 * no_vale)
	return altura


func _cor_do_solo(x: float, z: float, altura: float, normal: Vector3) -> Color:
	var mancha := _ruido.get_noise_2d(x * 2.0 + 50.0, z * 2.0)
	var cor := COR_GRAMA.lerp(COR_GRAMA_ESCURA, clampf(mancha * 0.5 + 0.5, 0.0, 1.0) * 0.6)
	# Terra também no miolo da clareira, como o chão batido da referência.
	var miolo := 1.0 - smoothstep(4.0, 7.5, Vector2(x, z + 1.0).length() + mancha * 2.0)
	var terra := maxf(faixa_trilha(x, z), miolo) if altura < 1.0 else 0.0
	if terra > 0.5:
		cor = COR_TERRA.lerp(COR_TERRA_ESCURA, clampf(mancha + 0.3, 0.0, 1.0) * 0.5)
	var inclinacao := 1.0 - normal.y
	if inclinacao > 0.42:
		cor = COR_ROCHA.lerp(COR_ROCHA * 0.8, clampf(mancha * 0.5 + 0.5, 0.0, 1.0))
	elif altura > 9.0:
		cor = cor.lerp(COR_GRAMA_ESCURA, 0.5)
	return cor


func _criar_terreno() -> void:
	var passo := TAMANHO / DIVISOES
	var inicio := -TAMANHO / 2.0
	var alturas := PackedFloat32Array()
	alturas.resize((DIVISOES + 1) * (DIVISOES + 1))
	for j in DIVISOES + 1:
		for i in DIVISOES + 1:
			alturas[j * (DIVISOES + 1) + i] = altura_em(inicio + i * passo, inicio + j * passo)

	var st := GeometriaLowPoly.nova()
	for j in DIVISOES:
		for i in DIVISOES:
			var x0 := inicio + i * passo
			var z0 := inicio + j * passo
			var p00 := Vector3(x0, alturas[j * (DIVISOES + 1) + i], z0)
			var p10 := Vector3(x0 + passo, alturas[j * (DIVISOES + 1) + i + 1], z0)
			var p01 := Vector3(x0, alturas[(j + 1) * (DIVISOES + 1) + i], z0 + passo)
			var p11 := Vector3(x0 + passo, alturas[(j + 1) * (DIVISOES + 1) + i + 1], z0 + passo)
			_triangulo_do_chao(st, p00, p10, p11)
			_triangulo_do_chao(st, p00, p11, p01)
	var malha := GeometriaLowPoly.finalizar(st)

	var corpo := StaticBody3D.new()
	corpo.name = "Terreno"
	corpo.collision_layer = 1
	corpo.collision_mask = 0
	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.material_override = GeometriaLowPoly.material_toon(0.08, 3)
	corpo.add_child(visual)
	var forma := ConcavePolygonShape3D.new()
	forma.set_faces(malha.get_faces())
	forma.backface_collision = true
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	corpo.add_child(colisao)
	add_child(corpo)


func _triangulo_do_chao(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c - a).cross(b - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	var centro := (a + b + c) / 3.0
	# Cada face com um tom levemente diferente: é o "facetado" da referência
	# e evita grandes manchas de uma cor só no chão plano.
	var cor := _cor_do_solo(centro.x, centro.z, centro.y, normal)
	var faceta := 1.0 + (fposmod(sin(centro.x * 12.9898 + centro.z * 78.233) * 43758.5453, 1.0) - 0.5) * 0.12
	cor = Color(cor.r * faceta, cor.g * faceta, cor.b * faceta)
	GeometriaLowPoly.triangulo(st, a, b, c, cor)


func _no_chao(x: float, z: float) -> Vector3:
	return Vector3(x, altura_em(x, z), z)


# --- Vegetação e pedras ---------------------------------------------------

func _criar_arvores() -> void:
	var pinheiros := GeometriaLowPoly.nova()
	var colisores := StaticBody3D.new()
	colisores.name = "TroncosColisao"
	colisores.collision_layer = 1
	colisores.collision_mask = 0
	var plantadas := 0
	var tentativas := 0
	while plantadas < 150 and tentativas < 3000:
		tentativas += 1
		var angulo := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(RAIO_PLANO - 3.0, 66.0)
		var x := cos(angulo) * r
		var z := sin(angulo) * r
		if absf(x) > TAMANHO / 2.0 - 2.0 or absf(z) > TAMANHO / 2.0 - 2.0:
			continue
		if absf(x - centro_trilha(z)) < 5.0:
			continue
		# Ruínas e canto da tocha ficam a noroeste; não plantar em cima.
		if Vector2(x + 15.0, z + 12.0).length() < 10.0 or Vector2(x - 16.0, z + 12.0).length() < 5.0:
			continue
		# Boca da caverna da forja (Caverna.BOCA).
		if Vector2(x - 22.0, z - 2.0).length() < 7.0:
			continue
		var base := _no_chao(x, z)
		var escala := _rng.randf_range(0.8, 1.5)
		if _rng.randf() < 0.8:
			_pinheiro(pinheiros, base, escala)
		else:
			_arvore_redonda(pinheiros, base, escala)
		if r < RAIO_COLISAO_ARVORES:
			var forma := CylinderShape3D.new()
			forma.radius = 0.35 * escala
			forma.height = 3.0
			var c := CollisionShape3D.new()
			c.shape = forma
			c.position = base + Vector3.UP * 1.5
			colisores.add_child(c)
		plantadas += 1
	_adicionar_malha("Arvores", GeometriaLowPoly.finalizar(pinheiros))
	add_child(colisores)


func _pinheiro(st: SurfaceTool, base: Vector3, escala: float) -> void:
	var giro := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(0.22, 0.16, 1.4, 5),
		Transform3D(giro.scaled(Vector3.ONE * escala), base + Vector3.UP * 0.6 * escala), COR_TRONCO)
	var andares := [[1.6, 2.0, 1.5], [1.25, 1.8, 2.6], [0.85, 1.6, 3.6]]
	for k in andares.size():
		var a: Array = andares[k]
		var cor := GeometriaLowPoly.variar(COR_PINHEIRO.lerp(COR_COPA, k * 0.22), _rng, 0.1)
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(a[0], 0.0, a[1], 7),
			Transform3D(giro.scaled(Vector3.ONE * escala), base + Vector3.UP * a[2] * escala), cor)


func _arvore_redonda(st: SurfaceTool, base: Vector3, escala: float) -> void:
	var giro := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(0.25, 0.18, 2.2, 5),
		Transform3D(giro.scaled(Vector3.ONE * escala), base + Vector3.UP * 1.0 * escala), COR_TRONCO)
	for k in 3:
		var desvio := Vector3(_rng.randf_range(-0.7, 0.7), 2.5 + k * 0.45, _rng.randf_range(-0.7, 0.7))
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.esfera(1.1 - k * 0.15, 6, 4),
			Transform3D(giro.scaled(Vector3.ONE * escala), base + desvio * escala),
			GeometriaLowPoly.variar(COR_COPA, _rng, 0.12))


func _criar_rochas() -> void:
	var st := GeometriaLowPoly.nova()
	var colisores := StaticBody3D.new()
	colisores.name = "PedrasColisao"
	colisores.collision_layer = 1
	colisores.collision_mask = 0
	# Pedras grandes que servem de obstáculo na área de luta (substituem os
	# cubos coloridos da arena antiga) e algumas na borda.
	var grandes := [Vector3(4.5, 0, -3.5), Vector3(-5.5, 0, 2.0), Vector3(9.0, 0, 6.0),
		Vector3(-9.5, 0, -6.5), Vector3(12.0, 0, -11.0), Vector3(-3.0, 0, 13.0)]
	for p in grandes:
		var raio := _rng.randf_range(0.8, 1.2)
		_pedra(st, _no_chao(p.x, p.z), raio)
		var forma := SphereShape3D.new()
		forma.radius = raio * 0.95
		var c := CollisionShape3D.new()
		c.shape = forma
		c.position = _no_chao(p.x, p.z) + Vector3.UP * raio * 0.35
		colisores.add_child(c)
	for i in 70:
		var angulo := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(3.0, 60.0)
		var x := cos(angulo) * r
		var z := sin(angulo) * r
		if faixa_trilha(x, z) > 0.3:
			continue
		_pedra(st, _no_chao(x, z), _rng.randf_range(0.15, 0.5) * (1.0 + r / 30.0))
	_adicionar_malha("Pedras", GeometriaLowPoly.finalizar(st))
	add_child(colisores)


func _pedra(st: SurfaceTool, base: Vector3, raio: float) -> void:
	var forma := Basis(Vector3.UP, _rng.randf_range(0.0, TAU)) \
		.scaled(Vector3(_rng.randf_range(0.9, 1.4), _rng.randf_range(0.6, 0.85), _rng.randf_range(0.8, 1.2)) * raio)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.esfera(1.0, 6, 3),
		Transform3D(forma, base + Vector3.UP * raio * 0.3), GeometriaLowPoly.variar(COR_ROCHA, _rng))


func _criar_grama() -> void:
	var lamina := GeometriaLowPoly.cilindro(0.07, 0.0, 0.5, 3)
	lamina.cap_top = false
	lamina.cap_bottom = false
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/grama_vento.gdshader")
	material.set_shader_parameter("cor_base", Color.WHITE)
	material.set_shader_parameter("meia_altura", 0.25)
	lamina.surface_set_material(0, material)
	var posicoes: Array[Transform3D] = []
	var cores: Array[Color] = []
	var tentativas := 0
	while posicoes.size() < 2400 and tentativas < 9000:
		tentativas += 1
		var x := _rng.randf_range(-42.0, 42.0)
		var z := _rng.randf_range(-42.0, 42.0)
		if faixa_trilha(x, z) > 0.2 or Vector2(x, z + 1.0).length() < 7.0:
			continue
		# Touceira: 3 lâminas inclinadas saindo do mesmo ponto.
		var base := _no_chao(x, z)
		var cor := COR_GRAMA.lerp(Color(0.48, 0.6, 0.27), _rng.randf()) if _rng.randf() < 0.7 else COR_GRAMA_ESCURA
		for k in 3:
			var giro := Basis(Vector3.UP, _rng.randf_range(0.0, TAU)) * Basis(Vector3.RIGHT, _rng.randf_range(0.1, 0.35))
			var escala := _rng.randf_range(0.6, 1.2)
			posicoes.append(Transform3D(giro.scaled(Vector3.ONE * escala), base + Vector3.UP * 0.22 * escala))
			cores.append(cor)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = lamina
	multi.instance_count = posicoes.size()
	for i in posicoes.size():
		multi.set_instance_transform(i, posicoes[i])
		multi.set_instance_color(i, cores[i])
	var instancia := MultiMeshInstance3D.new()
	instancia.name = "Grama"
	instancia.multimesh = multi
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instancia)


# --- Ruínas ---------------------------------------------------------------

func _criar_ruinas() -> void:
	var st := GeometriaLowPoly.nova()
	var colisores := StaticBody3D.new()
	colisores.name = "RuinasColisao"
	colisores.collision_layer = 1
	colisores.collision_mask = 0
	# Muro de arcos a noroeste, como o lado esquerdo da referência.
	_muro_de_arcos(st, colisores, Vector3(-20.0, 0, -3.0), Vector3(-9.0, 0, -19.0), 4, true)
	# Arco solitário a nordeste, meio caído.
	_muro_de_arcos(st, colisores, Vector3(14.0, 0, -15.0), Vector3(19.0, 0, -10.0), 1, false)
	_adicionar_malha("Ruinas", GeometriaLowPoly.finalizar(st))
	add_child(colisores)


func _muro_de_arcos(st: SurfaceTool, colisores: StaticBody3D, de: Vector3, ate: Vector3, arcos: int, inteiro: bool) -> void:
	var direcao := (ate - de).normalized()
	var base_giro := Basis(direcao, Vector3.UP, direcao.cross(Vector3.UP))
	var vao := (ate - de).length() / arcos
	# Topo comum a todos os pilares: em chão torto o pilar mais baixo só
	# afunda mais, e os arcos continuam encaixados.
	var chao_mais_alto := 0.0
	for k in arcos + 1:
		var p := de + direcao * vao * k
		chao_mais_alto = maxf(chao_mais_alto, altura_em(p.x, p.z))
	var topo := chao_mais_alto + 4.2
	for k in arcos + 1:
		var p := de + direcao * vao * k
		var pe := Vector3(p.x, minf(altura_em(p.x, p.z), altura_em(p.x + 1.0, p.z + 1.0)) - 1.0, p.z)
		var altura := topo - pe.y
		if not inteiro and k == arcos:
			altura *= 0.55
		_bloco(st, colisores, Vector3(1.1, altura, 1.1), Transform3D(base_giro, pe + Vector3.UP * altura / 2.0), COR_PEDRA_RUINA)
		_bloco(st, colisores, Vector3(1.4, 0.35, 1.4), Transform3D(base_giro, pe + Vector3.UP * (altura + 0.17)), COR_PEDRA_RUINA * 0.92)
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.cubo(Vector3(1.42, 0.12, 1.42)),
			Transform3D(base_giro, pe + Vector3.UP * (altura + 0.38)), COR_MUSGO)
		if inteiro or k < arcos:
			_estandarte(st, pe + Vector3.UP * (altura - 1.0), base_giro)
		if k == arcos:
			break
		if not inteiro:
			# Pedaço do arco caído no chão.
			var resto := de + direcao * vao * 0.6
			_bloco(st, colisores, Vector3(1.2, 0.7, 0.9),
				Transform3D(base_giro.rotated(Vector3.UP, 0.5), _no_chao(resto.x, resto.z) + Vector3(0.0, 0.3, 1.5)), COR_PEDRA_RUINA * 0.9)
			continue
		# Arco: aduelas em meio círculo entre os dois pilares.
		var raio := vao / 2.0 - 0.55
		var centro := Vector3(p.x, topo, p.z) + direcao * vao / 2.0
		var pedras := 9
		var largura_pedra := PI * raio / pedras + 0.06
		for a in pedras:
			var t := PI * (a + 0.5) / pedras
			var ponto := centro - direcao * cos(t) * raio + Vector3.UP * sin(t) * raio
			var giro := base_giro * Basis(Vector3(0, 0, 1), PI / 2.0 - t)
			var cor := COR_PEDRA_RUINA * _rng.randf_range(0.88, 1.05)
			_bloco(st, colisores, Vector3(largura_pedra, 0.5, 1.0), Transform3D(giro, ponto), cor)


func _bloco(st: SurfaceTool, colisores: StaticBody3D, tamanho: Vector3, transformada: Transform3D, cor: Color) -> void:
	cor.a = 1.0
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cubo(tamanho), transformada, cor)
	var forma := BoxShape3D.new()
	forma.size = tamanho
	var c := CollisionShape3D.new()
	c.shape = forma
	c.transform = transformada
	colisores.add_child(c)


func _estandarte(st: SurfaceTool, topo: Vector3, giro: Basis) -> void:
	# Pendurado na face do pilar virada para o centro da clareira.
	var frente := giro.z
	if frente.dot(-topo) < 0.0:
		frente = -frente
	var pos := topo + frente * 0.58
	var cloth := Transform3D(giro, pos + Vector3.DOWN * 0.7)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cubo(Vector3(0.7, 1.5, 0.05)), cloth, COR_ESTANDARTE)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cubo(Vector3(0.8, 0.08, 0.1)), Transform3D(giro, pos), COR_DOURADO)
	var losango := Transform3D(giro * Basis(Vector3(0, 0, 1), PI / 4.0), pos + Vector3.DOWN * 0.7 + frente * 0.04)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cubo(Vector3(0.3, 0.3, 0.04)), losango, COR_DOURADO)


func _criar_tochas() -> void:
	# Em frente aos pilares 1 e 3 do muro de arcos, virado para o centro.
	var de := Vector3(-20.0, 0, -3.0)
	var ate := Vector3(-9.0, 0, -19.0)
	var direcao := (ate - de).normalized()
	var para_centro := Vector3(-direcao.z, 0, direcao.x)
	if para_centro.dot(-(de + ate) / 2.0) < 0.0:
		para_centro = -para_centro
	var vao := (ate - de).length() / 4.0
	for k in [1, 3]:
		var p: Vector3 = de + direcao * vao * k + para_centro * 1.3
		_tocha(_no_chao(p.x, p.z))


func _tocha(base: Vector3) -> void:
	var G := GeometriaLowPoly
	var tocha := Node3D.new()
	tocha.name = "TochaRuina"
	tocha.position = base
	add_child(tocha)

	var st := G.nova()
	G.anexar(st, G.cilindro(0.1, 0.07, 1.7, 6), Transform3D(Basis(), Vector3.UP * 0.85), COR_TRONCO * 0.85)
	G.anexar(st, G.cilindro(0.1, 0.1, 0.08, 6), Transform3D(Basis(), Vector3.UP * 1.25), Color(0.28, 0.27, 0.29))
	G.anexar(st, G.cilindro(0.3, 0.12, 0.22, 7), Transform3D(Basis(), Vector3.UP * 1.78), Color(0.28, 0.27, 0.29))
	var suporte := MeshInstance3D.new()
	suporte.mesh = G.finalizar(st)
	suporte.material_override = _material
	tocha.add_child(suporte)

	# Chama: cone laranja por fora e cone amarelo por dentro, com brilho
	# próprio acima de 1,0 (camada 4 da paleta: o glow pega só nela).
	var chama_st := G.nova()
	# Labareda: cone grande + duas línguas tortas dos lados + miolo amarelo.
	G.anexar(chama_st, G.cilindro(0.24, 0.0, 0.62, 6), Transform3D(Basis(), Vector3.UP * 2.12), Color(1.0, 0.58, 0.14))
	for lado in [-1.0, 1.0]:
		var torto := Basis(Vector3(0, 0, 1), -lado * 0.35)
		G.anexar(chama_st, G.cilindro(0.12, 0.0, 0.42, 5), Transform3D(torto, Vector3(lado * 0.16, 2.02, 0.03)), Color(1.0, 0.7, 0.2))
	G.anexar(chama_st, G.cilindro(0.13, 0.0, 0.4, 6), Transform3D(Basis(Vector3.UP, 0.5), Vector3.UP * 2.02), Color(1.0, 0.97, 0.7))
	var chama := MeshInstance3D.new()
	chama.name = "Chama"
	chama.mesh = G.finalizar(chama_st)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.12)
	mat.emission_energy_multiplier = 4.0
	chama.material_override = mat
	chama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tocha.add_child(chama)

	# Sem sombra de propósito: luz pontual com sombra redesenha a cena em
	# volta várias vezes (auditoria, seção B).
	var luz := OmniLight3D.new()
	luz.position = Vector3.UP * 2.2
	luz.light_color = COR_TOCHA
	luz.light_energy = ENERGIA_TOCHA
	luz.omni_range = ALCANCE_TOCHA
	luz.omni_attenuation = 1.2
	tocha.add_child(luz)
	_luzes_tocha.append(luz)

	var corpo := StaticBody3D.new()
	corpo.collision_layer = 1
	corpo.collision_mask = 0
	var forma := CylinderShape3D.new()
	forma.radius = 0.2
	forma.height = 1.9
	var c := CollisionShape3D.new()
	c.shape = forma
	c.position = Vector3.UP * 0.95
	corpo.add_child(c)
	tocha.add_child(corpo)


func _criar_runas() -> void:
	for ponto in PONTOS_RUNA:
		var runa := RunaColetavel.new()
		runa.nome = ponto[0]
		runa.name = "Runa_%s" % ponto[0]
		var p: Vector2 = ponto[1]
		runa.position = _no_chao(p.x, p.y)
		add_child(runa)


# --- Fundo: montanhas, castelo, cachoeira, ilhas e nuvens --------------------

func _criar_fundo() -> void:
	var st := GeometriaLowPoly.nova()
	for i in 16:
		var angulo := TAU * i / 16.0 + _rng.randf_range(-0.1, 0.1)
		var distancia := _rng.randf_range(150.0, 230.0)
		var centro := Vector3(cos(angulo) * distancia, -8.0, sin(angulo) * distancia)
		# Atrás do castelo as montanhas ficam mais longe, para ele aparecer.
		if sin(angulo) < -0.9:
			centro *= 1.35
		var altura := _rng.randf_range(55.0, 105.0)
		var raio := _rng.randf_range(35.0, 60.0)
		var giro := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(raio, raio * 0.12, altura, 7),
			Transform3D(giro, centro + Vector3.UP * altura / 2.0), GeometriaLowPoly.variar(COR_MONTANHA, _rng))
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(raio * 0.3, 0.0, altura * 0.25, 7),
			Transform3D(giro, centro + Vector3.UP * altura * 0.95), COR_NEVE)
	_castelo(st, Vector3(-8.0, 0.0, -175.0))
	for i in 9:
		var angulo := _rng.randf_range(0.0, TAU)
		var distancia := _rng.randf_range(160.0, 300.0)
		_nuvem(st, Vector3(cos(angulo) * distancia, _rng.randf_range(55.0, 95.0), sin(angulo) * distancia))
	var fundo := _adicionar_malha("Fundo", GeometriaLowPoly.finalizar(st))
	fundo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for dados in [[Vector3(-70.0, 48.0, -120.0), 1.0], [Vector3(55.0, 60.0, -140.0), 1.4], [Vector3(95.0, 40.0, -60.0), 0.7]]:
		_ilha_flutuante(dados[0], dados[1])


func _castelo(st: SurfaceTool, base: Vector3) -> void:
	# Penhasco onde o castelo fica.
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(40.0, 30.0, 45.0, 8),
		Transform3D(Basis(), base + Vector3.UP * 12.0), Color(0.48, 0.44, 0.42))
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(30.5, 30.5, 1.5, 8),
		Transform3D(Basis(), base + Vector3.UP * 35.0), COR_GRAMA_ESCURA)
	var topo := base + Vector3.UP * 35.5
	var pedra := Color(0.66, 0.6, 0.62)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cubo(Vector3(18.0, 16.0, 14.0)), Transform3D(Basis(), topo + Vector3.UP * 8.0), pedra)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cubo(Vector3(32.0, 6.0, 1.5)), Transform3D(Basis(), topo + Vector3(0, 3.0, 14.0)), pedra * 0.92)
	var torres := [Vector3(-14, 0, 14), Vector3(14, 0, 14), Vector3(-9, 0, -6), Vector3(9, 0, -6), Vector3(0, 0, 2), Vector3(-4, 0, 9)]
	var alturas := [16.0, 18.0, 24.0, 22.0, 34.0, 26.0]
	for k in torres.size():
		var h: float = alturas[k]
		var raio := 2.4 if k != 4 else 3.2
		var p: Vector3 = topo + torres[k]
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(raio, raio, h, 8), Transform3D(Basis(), p + Vector3.UP * h / 2.0), pedra)
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(raio * 1.35, 0.0, raio * 3.2, 8),
			Transform3D(Basis(), p + Vector3.UP * (h + raio * 1.6)), COR_TELHADO)
	# Janelas acesas e cachoeira brilham sozinhas (material próprio, com
	# emissão, para o glow pegar).
	var luzes := GeometriaLowPoly.nova()
	for k in torres.size():
		var p: Vector3 = topo + torres[k]
		var h: float = alturas[k]
		for andar in 2:
			GeometriaLowPoly.anexar(luzes, GeometriaLowPoly.cubo(Vector3(0.9, 1.6, 0.4)),
				Transform3D(Basis(), p + Vector3(0, h * (0.55 + andar * 0.25), 2.5 if k != 4 else 3.3)), Color(1.0, 0.75, 0.35))
	var malha_luzes := MeshInstance3D.new()
	malha_luzes.name = "JanelasCastelo"
	malha_luzes.mesh = GeometriaLowPoly.finalizar(luzes)
	var mat_luz := StandardMaterial3D.new()
	mat_luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_luz.vertex_color_use_as_albedo = true
	mat_luz.emission_enabled = true
	mat_luz.emission = Color(1.0, 0.7, 0.3)
	mat_luz.emission_energy_multiplier = 3.0
	malha_luzes.material_override = mat_luz
	malha_luzes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(malha_luzes)

	var agua := MeshInstance3D.new()
	agua.name = "Cachoeira"
	agua.mesh = GeometriaLowPoly.cubo(Vector3(6.0, 44.0, 0.5))
	agua.position = base + Vector3(16.0, 13.0, 36.5)
	agua.rotation.y = 0.4
	var mat_agua := StandardMaterial3D.new()
	mat_agua.albedo_color = Color(0.6, 0.85, 1.0)
	mat_agua.emission_enabled = true
	mat_agua.emission = Color(0.55, 0.8, 1.0)
	mat_agua.emission_energy_multiplier = 0.8
	agua.material_override = mat_agua
	agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(agua)


func _nuvem(st: SurfaceTool, centro: Vector3) -> void:
	# Mais bolhas, mais sobrepostas e com leve sombra por baixo: silhueta de
	# cúmulo, não uma fileira reta de esferas (pedido do Vitor, "mais fofa").
	for k in 8:
		var desvio := Vector3(_rng.randf_range(-13.0, 13.0), _rng.randf_range(-1.5, 4.0), _rng.randf_range(-6.0, 6.0))
		var raio := _rng.randf_range(5.0, 10.0)
		var cor := Color(1.0, 1.0, 1.0) if desvio.y > 0.0 else Color(0.88, 0.89, 0.93)
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.esfera(raio, 7, 4),
			Transform3D(Basis().scaled(Vector3(1.3, 0.8, 1.1)), centro + desvio), cor)


func _ilha_flutuante(posicao: Vector3, escala: float) -> void:
	var st := GeometriaLowPoly.nova()
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(0.0, 9.0, 12.0, 7),
		Transform3D(Basis(), Vector3.DOWN * 6.0), Color(0.5, 0.44, 0.4))
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(9.3, 9.3, 1.2, 7), Transform3D(Basis(), Vector3(0, 0.4, 0)), COR_GRAMA)
	_pinheiro(st, Vector3(2.0, 1.0, 1.0), 1.6)
	_pinheiro(st, Vector3(-3.0, 1.0, -2.0), 1.2)
	var ilha := MeshInstance3D.new()
	ilha.name = "IlhaFlutuante"
	ilha.mesh = GeometriaLowPoly.finalizar(st)
	ilha.material_override = _material
	ilha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ilha.position = posicao
	ilha.scale = Vector3.ONE * escala
	ilha.set_meta("altura_base", posicao.y)
	add_child(ilha)
	_ilhas.append(ilha)


func _adicionar_malha(nome: String, malha: ArrayMesh) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	instancia.name = nome
	instancia.mesh = malha
	instancia.material_override = _material
	add_child(instancia)
	return instancia
