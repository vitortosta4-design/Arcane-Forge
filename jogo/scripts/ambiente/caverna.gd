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
## 2ª etapa (13/11/2026, o Vitor achou as proporções erradas): a caverna da
## folha é bem maior, os cipós são detalhe pequeno e a bigorna tem de 3 a 4
## vezes a altura do mago (o mago tem 2,9 m com o chapéu; a bigorna ficou
## com uns 10 m).
const RAIO_CAMARA := 26.0
const ESCALA_BIGORNA := 1.5
## Fundo aberto (folha): do lado oposto à entrada a parede some e a câmara dá
## para uma caverna funda, azul e roxa, com ilhas flutuantes, cachoeiras e
## quedas de lava. É só paisagem: a colisão da casca continua fechada ali
## (parede invisível), então ninguém cai.
const FUNDO_MEIA_ABERTURA := 0.75   # radianos para cada lado (uns 43 graus)
const COR_FUNDO := Color(0.1, 0.11, 0.36)
const COR_AGUA := Color(0.3, 0.62, 1.0)
const COR_LAVA := Color(1.0, 0.5, 0.12)
## Ar da caverna. A câmara fica embaixo do mapa e herdava o céu, a luz
## ambiente e a névoa azul-clara da clareira: de longe tudo virava cinza
## azulado e o fundo parecia gelo. Quando a câmera está aqui embaixo ela
## troca para um ar próprio: escuro, roxo, com névoa fraca e arroxeada.
const ALTURA_DO_AR_DA_CAVERNA := -40.0
const COR_AR := Color(0.05, 0.04, 0.14)
const COR_AMBIENTE_CAVERNA := Color(0.42, 0.3, 0.7)
const COR_NEVOA_CAVERNA := Color(0.2, 0.1, 0.36)
const COR_PEDRA := Color(0.36, 0.33, 0.4)
const COR_CHAO := Color(0.42, 0.34, 0.37)
const COR_BURACO := Color(0.03, 0.02, 0.05)
const CORES_CRISTAL := [Color(0.6, 0.35, 1.0), Color(0.3, 0.75, 1.0)]
## Câmara (1ª passada da caverna definitiva, pedido do Vitor em 12/11/2026).
## Quem manda é a folha `docs/referencias/lote02/lote02_09_caverna_forja.png`:
## posto avançado quente, piso de pedra em anéis com linhas de runa acesas,
## pedestal em degraus com lava sob a bigorna, lanternas em pedestais e em
## postes com corrente, cristais roxos, laranja contra roxo e azul.
## A abertura no teto com feixe de luz veio só do texto do conceito e não
## aparece na folha: fica desligada até o Vitor decidir.
const COM_ABERTURA_NO_TETO := false
const ACHATAMENTO := 0.75        # cúpula achatada: teto a uns 11 m
const ANEIS_CASCA := 7
const LADOS_CASCA := 20
const POLAR_ABERTURA := 0.25     # ângulo do buraco no topo (raio de uns 3,7 m)
const ALTURA_CHAMINE := 7.0
const COR_PEDRA_BAIXA := Color(0.48, 0.31, 0.32)
const COR_PEDRA_ALTA := Color(0.24, 0.19, 0.44)
const COR_CHAO_QUENTE := Color(0.7, 0.5, 0.33)
const COR_CEU_ABERTURA := Color(0.78, 0.9, 1.0)
const COR_RAIZ := Color(0.4, 0.46, 0.22)   # cipó (na folha pendem cipós e correntes do teto)
const COR_METAL := Color(0.2, 0.2, 0.27)
const COR_VEIO := Color(1.0, 0.55, 0.16)
const QUANTAS_RAIZES := 16
const QUANTAS_RAIZES_METALICAS := 6
## Pedestal em dois degraus sob a bigorna. As subidas são rampas curtas (40
## graus), não degraus retos: o mago sobe andando, sem travar na quina.
const PEDESTAL := [[8.0, 0.0], [7.46, 0.45], [6.5, 0.45], [5.96, 0.9], [0.0, 0.9]]
const ALTURA_PEDESTAL := 0.9
const RAIO_ANEL_DE_RUNAS := 11.4
const COR_PEDESTAL := Color(0.62, 0.48, 0.36)
const RAIO_CERCA := 19.5
const COR_MADEIRA := Color(0.5, 0.3, 0.18)
const COR_LANTERNA := Color(1.0, 0.72, 0.28)
const COR_CORRENTE := Color(0.2, 0.17, 0.2)

var forja: Forja = null
var _boca_chao := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _material := GeometriaLowPoly.material_toon(0.2, 3)
var _ar_da_caverna: Environment
## Os móveis do posto (etapa 3); guarda as contagens de livros e velas.
var moveis: MoveisDaForja = null


func _ready() -> void:
	_rng.seed = 7
	var clareira := get_parent().get_node_or_null("Clareira") as Clareira
	var altura := clareira.altura_em(BOCA.x, BOCA.y) if clareira else 0.0
	_boca_chao = Vector3(BOCA.x, altura, BOCA.y)
	_criar_boca()
	_criar_camara()
	_ar_da_caverna = _criar_ar_da_caverna()


## Troca o ar da câmera que estiver desenhando (1ª pessoa, 3ª, câmera livre
## dos prints): dentro da caverna, o ar dela; fora, o do mundo.
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return # normal: sem câmera (testes sem tela)
	var dentro := camera.global_position.y < ALTURA_DO_AR_DA_CAVERNA
	if dentro and camera.environment != _ar_da_caverna:
		camera.environment = _ar_da_caverna
	elif not dentro and camera.environment == _ar_da_caverna:
		camera.environment = null


func _criar_ar_da_caverna() -> Environment:
	# Parte do ar do mundo (mesmo ajuste de tons e brilho) e muda só o que é da caverna.
	var mundo := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment if get_parent() else null
	var ar: Environment = mundo.environment.duplicate() if mundo and mundo.environment else Environment.new()
	ar.background_mode = Environment.BG_COLOR
	ar.background_color = COR_AR
	ar.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ar.ambient_light_color = COR_AMBIENTE_CAVERNA
	ar.ambient_light_energy = 0.3
	ar.fog_enabled = true
	ar.fog_light_color = COR_NEVOA_CAVERNA
	ar.fog_density = 0.004
	ar.fog_sun_scatter = 0.0
	ar.fog_aerial_perspective = 0.0
	ar.fog_sky_affect = 0.0
	ar.volumetric_fog_enabled = false
	return ar


## Para onde o mago vai ao entrar e ao sair (virado para a bigorna / para o
## centro da clareira).
func entrada_camara() -> Vector3:
	return CENTRO_CAMARA + Vector3(RAIO_CAMARA - 4.5, 1.0, 0.0)


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
	var colisores := StaticBody3D.new()
	colisores.name = "PedrasDaCamara"
	colisores.collision_layer = 1
	colisores.collision_mask = 0
	_casca(st, c)
	_chao(st, c)
	_pedestal(st, c)
	# Costelas de pedra encostadas na parede (quebram a cúpula lisa). O setor
	# da saída (ângulo zero) fica livre.
	for i in 13:
		var a := TAU * (i + 0.5) / 13.0
		# sem costela atrás dos dois blocos de móveis (o andaime encosta na parede)
		var atras_dos_moveis := absf(wrapf(a - deg_to_rad(96.0), -PI, PI)) < 0.5 or absf(wrapf(a - deg_to_rad(-92.0), -PI, PI)) < 0.5
		if absf(wrapf(a, -PI, PI)) < 0.3 or _no_fundo_aberto(a) or atras_dos_moveis:
			continue
		var pe := c + Vector3(cos(a), 0, sin(a)) * (RAIO_CAMARA - 1.3)
		var para_dentro := (c - pe).normalized()
		var largura := _rng.randf_range(3.8, 5.6)
		for andar in 3:
			var encolhe := 1.0 - andar * 0.24
			_pedregulho(st, colisores, pe + para_dentro * andar * 0.8 + Vector3.UP * (2.2 + andar * 4.0),
				Vector3(largura * encolhe, 5.6, largura * encolhe), _cor_pedra(0.15 + andar * 0.2))
	# Estalactites no teto e estalagmites no pé da parede.
	for i in 44:
		var a := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(6.0, RAIO_CAMARA - 3.0)
		var comprimento := _rng.randf_range(1.5, 6.0)
		var topo := c + Vector3(cos(a) * r, _altura_do_teto(r) - 0.2, sin(a) * r)
		G.anexar(st, G.cilindro(0.0, _rng.randf_range(0.5, 1.3), comprimento, 5),
			Transform3D(Basis(), topo + Vector3.DOWN * comprimento / 2.0), _cor_pedra(0.7))
	for i in 16:
		var a := _rng.randf_range(0.4, TAU - 0.4)
		if _no_fundo_aberto(a):
			continue
		var r := _rng.randf_range(RAIO_CAMARA - 4.5, RAIO_CAMARA - 2.2)
		var altura := _rng.randf_range(1.0, 3.0)
		var base := c + Vector3(cos(a) * r, 0, sin(a) * r)
		var raio := _rng.randf_range(0.4, 0.9)
		G.anexar(st, G.cilindro(raio, 0.0, altura, 5), Transform3D(Basis(), base + Vector3.UP * altura / 2.0), _cor_pedra(0.1))
		var forma_pedra := CylinderShape3D.new()
		forma_pedra.radius = raio * 0.8
		forma_pedra.height = altura
		var col_pedra := CollisionShape3D.new()
		col_pedra.shape = forma_pedra
		col_pedra.position = base + Vector3.UP * altura / 2.0
		colisores.add_child(col_pedra)
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
	# Colisão só da casca e do chão lisos (os enfeites têm as formas deles).
	var st_colisao := G.nova()
	_casca(st_colisao, c, false)
	_pedestal(st_colisao, c)
	G.anexar(st_colisao, G.cilindro(RAIO_CAMARA + 1.0, RAIO_CAMARA + 1.0, 1.0, 14), Transform3D(Basis(), c + Vector3.DOWN * 0.5), COR_CHAO)
	var forma := ConcavePolygonShape3D.new()
	forma.set_faces(G.finalizar(st_colisao).get_faces())
	forma.backface_collision = true
	var col := CollisionShape3D.new()
	col.shape = forma
	camara.add_child(col)
	add_child(camara)
	add_child(colisores)
	if COM_ABERTURA_NO_TETO:
		_abertura_no_teto(c)
	_raizes_do_teto(c)
	_raizes_metalicas(c)
	_linhas_de_runa(c)
	_lanternas_e_cerca(c, colisores)
	_fundo_aberto(c, colisores)
	moveis = MoveisDaForja.montar(self, c, RAIO_CAMARA, _altura_do_teto, _material, colisores)
	var voadores := LivrosVoadores.new()
	voadores.name = "LivrosVoadores"
	voadores.pousos = moveis.pousos
	add_child(voadores)
	# Luz quente da forja alcançando as paredes (a bigorna cuida das luzes
	# dela; esta é só o banho alaranjado do ambiente: quente no meio, frio e
	# arroxeado nas bordas, como no conceito).
	var brasa := OmniLight3D.new()
	brasa.name = "LuzQuenteDaForja"
	brasa.light_color = Color(1.0, 0.46, 0.12)
	brasa.light_energy = 9.0
	brasa.omni_range = 44.0
	brasa.omni_attenuation = 1.3
	brasa.position = c + Vector3.UP * 6.0
	add_child(brasa)
	# Preenchimento roxo vindo do alto: sem ele, o que a luz quente não
	# alcança cai no azul acinzentado da névoa de fora, e a folha é roxa.
	var roxo := OmniLight3D.new()
	roxo.name = "LuzRoxaDoTeto"
	roxo.light_color = Color(0.72, 0.42, 1.0)
	roxo.light_energy = 0.3
	roxo.omni_range = 52.0
	roxo.omni_attenuation = 0.6
	roxo.position = c + Vector3.UP * 15.0
	add_child(roxo)

	# Cristais arroxeados que iluminam as bordas da câmara: 6 grupos grandes
	# com luz e grupos pequenos sem luz espalhados na parede.
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var p := c + Vector3(cos(a), 0, sin(a)) * (RAIO_CAMARA - 4.0)
		if p.x > c.x + 14.0 and absf(p.z - c.z) < 6.0:
			continue
		# nada de cristal grande atravessando os andaimes dos móveis
		if absf(wrapf(a - deg_to_rad(96.0), -PI, PI)) < 0.62 or absf(wrapf(a - deg_to_rad(-92.0), -PI, PI)) < 0.62:
			continue
		# Só 3 grupos têm luz de verdade (as lanternas gastam as outras).
		_cristais(p, CORES_CRISTAL[1] if i == 3 else CORES_CRISTAL[0], 2.6, i % 2 == 1)
	for i in 14:
		var a := _rng.randf_range(0.5, TAU - 0.5)
		var subida := _rng.randf_range(0.0, 8.0)
		var r := sqrt(maxf(0.0, 1.0 - pow(subida / (RAIO_CAMARA * 0.75), 2))) * RAIO_CAMARA - 1.4
		_cristais(c + Vector3(cos(a) * r, subida, sin(a) * r), CORES_CRISTAL[0] if i % 4 else CORES_CRISTAL[1], 1.2, false)

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
	forja.position = c + Vector3.UP * ALTURA_PEDESTAL
	forja.scale = Vector3.ONE * ESCALA_BIGORNA
	forja.rotation.y = PI / 2.0
	add_child(forja)


func _cristais(base: Vector3, cor: Color, tamanho := 1.0, com_luz := true) -> void:
	var G := GeometriaLowPoly
	var st := G.nova()
	for k in 5:
		var altura := _rng.randf_range(1.0, 2.6) * tamanho
		var inclinado := Basis(Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized(), _rng.randf_range(0.1, 0.55))
		# Cada ponta num tom (mais claro ou mais escuro), para ler como cristal lapidado.
		G.anexar(st, G.cilindro(_rng.randf_range(0.18, 0.35) * tamanho, 0.0, altura, 5),
			Transform3D(inclinado, base + Vector3(_rng.randf_range(-0.6, 0.6) * tamanho, altura / 2.0 - 0.1, _rng.randf_range(-0.6, 0.6) * tamanho)),
			cor.lerp(Color.WHITE, _rng.randf_range(0.0, 0.3)) * _rng.randf_range(0.75, 1.0))
	var cristal := MeshInstance3D.new()
	cristal.name = "Cristais"
	cristal.mesh = G.finalizar(st)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = cor
	mat.emission_energy_multiplier = 2.0
	cristal.material_override = mat
	cristal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cristal, true)
	if not com_luz:
		return # normal: grupo pequeno de parede, só enfeite (menos luzes = mais FPS)
	var luz := OmniLight3D.new()
	luz.light_color = cor
	luz.light_energy = 2.0
	luz.omni_range = 9.0 * tamanho
	luz.position = base + Vector3.UP * 1.8 * tamanho
	add_child(luz)


# --- Peças da câmara --------------------------------------------------------

## O ângulo cai no setor do fundo aberto (oposto à entrada, que fica no ângulo zero)?
func _no_fundo_aberto(angulo: float) -> bool:
	return absf(wrapf(angulo - PI, -PI, PI)) < FUNDO_MEIA_ABERTURA


## Paisagem do fundo (folha): céu de caverna azul, colunas distantes, ilhas
## flutuantes com cristais, cachoeiras azuis e quedas de lava. Sem luzes de
## verdade: tudo que brilha é só cor acesa, pelo FPS.
func _fundo_aberto(c: Vector3, colisores: StaticBody3D) -> void:
	var G := GeometriaLowPoly
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# Céu da caverna: meia casca achatada (não pode furar o chão da clareira lá em cima).
	var st_ceu := G.nova()
	G.anexar_invertido(st_ceu, G.esfera(95.0, 16, 8), Transform3D(Basis().scaled(Vector3(1.0, 0.45, 1.0)), c + Vector3(-50.0, 6.0, 0.0)), COR_FUNDO)
	var ceu := MeshInstance3D.new()
	ceu.name = "FundoDaCaverna"
	ceu.mesh = G.finalizar(st_ceu)
	var mat_ceu := StandardMaterial3D.new()
	mat_ceu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_ceu.vertex_color_use_as_albedo = true
	mat_ceu.disable_fog = true
	ceu.material_override = mat_ceu
	ceu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ceu)

	var st := G.nova()        # pedra (ilhas, colunas, beirada)
	var st_brilho := G.nova() # água, lava e cristais acesos
	var fita_em_pe := func(topo: Vector3, altura: float, largura: float, cor: Color) -> void:
		# duas fitas cruzadas, para ler de qualquer lado
		for giro in [0.0, PI / 2.0]:
			var lado := Vector3(cos(giro), 0, sin(giro)) * largura / 2.0
			var base := topo + Vector3.DOWN * altura
			var claro := cor.lerp(Color.WHITE, 0.25)
			var olho := topo + Vector3(sin(giro), 0, -cos(giro)) * 9.0 + Vector3.DOWN * altura / 2.0
			_face(st_brilho, topo + lado, topo - lado, base - lado * 1.3, claro, olho)
			_face(st_brilho, topo + lado, base - lado * 1.3, base + lado * 1.3, cor, olho)
			_face(st_brilho, topo + lado, base - lado * 1.3, topo - lado, claro, topo + (topo - olho))
			_face(st_brilho, topo + lado, base + lado * 1.3, base - lado * 1.3, cor, topo + (topo - olho))
	# Colunas distantes (do teto ao fundo), para dar profundidade.
	for k in 7:
		var x := rng.randf_range(-95.0, -55.0)
		var z := rng.randf_range(-55.0, 55.0)
		var grossura := rng.randf_range(5.0, 9.0)
		G.anexar(st, G.cilindro(grossura * 0.55, grossura, 70.0, 7), Transform3D(Basis(), c + Vector3(x, 0.0, z)), Color(0.2, 0.17, 0.4) * rng.randf_range(0.8, 1.1))
		if k % 3 == 0:
			fita_em_pe.call(c + Vector3(x + grossura * 0.9, 18.0, z), 50.0, 3.0, COR_LAVA)
	# Ilhas flutuantes: pedra em cunha, tampo mais claro, cristais em cima.
	var ilhas := [[-38.0, 4.0, -14.0, 5.5], [-46.0, 11.0, 9.0, 4.0], [-58.0, 2.0, 24.0, 7.0], [-64.0, 15.0, -22.0, 5.0],
		[-74.0, 7.0, 2.0, 8.0], [-52.0, -4.0, -32.0, 4.5], [-41.0, 15.5, 27.0, 3.2]]
	for k in ilhas.size():
		var p := c + Vector3(ilhas[k][0], ilhas[k][1], ilhas[k][2])
		var r: float = ilhas[k][3]
		var giro := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		G.anexar(st, G.cilindro(r * 0.15, r, r * 1.3, 7), Transform3D(giro, p + Vector3.DOWN * r * 0.65), _cor_pedra(0.5))
		G.anexar(st, G.cilindro(r, r * 0.92, r * 0.18, 7), Transform3D(giro, p + Vector3.UP * r * 0.09), _cor_pedra(0.0) * 1.15)
		for q in 3:
			var altura := r * rng.randf_range(0.35, 0.7)
			var pe := p + Vector3(rng.randf_range(-0.5, 0.5) * r, r * 0.18, rng.randf_range(-0.5, 0.5) * r)
			G.anexar(st_brilho, G.cilindro(altura * 0.22, 0.0, altura, 5), Transform3D(Basis(Vector3(1, 0, 0.3).normalized(), rng.randf_range(-0.3, 0.3)), pe + Vector3.UP * altura / 2.0),
				CORES_CRISTAL[0].lerp(Color.WHITE, rng.randf_range(0.0, 0.25)))
		if k % 2 == 0:
			fita_em_pe.call(p + Vector3(r * 0.8, r * 0.1, 0.0), 30.0 + r * 2.0, r * 0.35, COR_AGUA)
	# Beirada do abismo: pedras baixas ao longo da borda aberta.
	for k in 9:
		var a := PI + lerpf(-FUNDO_MEIA_ABERTURA, FUNDO_MEIA_ABERTURA, k / 8.0)
		var p := c + Vector3(cos(a), 0, sin(a)) * (RAIO_CAMARA - 0.6)
		_pedregulho(st, colisores, p + Vector3.UP * 0.5, Vector3(rng.randf_range(2.6, 4.2), rng.randf_range(1.2, 2.2), rng.randf_range(2.2, 3.4)), _cor_pedra(0.1))
	var pedras := MeshInstance3D.new()
	pedras.name = "IlhasFlutuantes"
	pedras.mesh = G.finalizar(st)
	pedras.material_override = _material
	pedras.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pedras)
	var brilhos := MeshInstance3D.new()
	brilhos.name = "BrilhosDoFundo"
	brilhos.mesh = G.finalizar(st_brilho)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.disable_fog = true
	brilhos.material_override = mat
	brilhos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(brilhos)


## Pedra da caverna: arroxeada e fria; `altura` 0 = pé da parede (um pouco
## mais clara e quente, perto da luz da forja), 1 = teto (escura e azulada).
func _cor_pedra(altura: float) -> Color:
	return GeometriaLowPoly.variar(COR_PEDRA_BAIXA.lerp(COR_PEDRA_ALTA, clampf(altura, 0.0, 1.0)), _rng, 0.1)


## Altura do teto (cúpula achatada) a `r` metros do centro.
func _altura_do_teto(r: float) -> float:
	return sqrt(maxf(0.0, 1.0 - pow(r / RAIO_CAMARA, 2))) * RAIO_CAMARA * ACHATAMENTO


## Triângulo com a frente virada para `olho` (quem está dentro da caverna).
func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, cor: Color, olho: Vector3) -> void:
	if (c - a).cross(b - a).dot(olho - a) >= 0.0:
		GeometriaLowPoly.triangulo(st, a, b, c, cor)
	else:
		GeometriaLowPoly.triangulo(st, a, c, b, cor)


## Cúpula facetada vista por dentro, com a pedra amassada (cada ponto sai um
## pouco do lugar) e cor por faceta. No topo fica um buraco: a abertura.
## `enfeitada` falsa = versão lisa, usada só para a colisão.
func _casca(st: SurfaceTool, c: Vector3, enfeitada := true) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var pontos: Array = []
	for i in ANEIS_CASCA + 1:
		var polar := lerpf(POLAR_ABERTURA if COM_ABERTURA_NO_TETO else 0.001, PI / 2.0, float(i) / ANEIS_CASCA)
		var anel: Array[Vector3] = []
		for j in LADOS_CASCA:
			var giro := TAU * (j + (0.5 if i % 2 else 0.0)) / LADOS_CASCA
			var amassado := rng.randf_range(-0.07, 0.05) if enfeitada and i > 0 and i < ANEIS_CASCA else 0.0
			var raio := RAIO_CAMARA * (1.0 + amassado)
			anel.append(c + Vector3(sin(polar) * cos(giro) * raio, cos(polar) * raio * ACHATAMENTO, sin(polar) * sin(giro) * raio))
		pontos.append(anel)
	var olho := c + Vector3.UP * 2.0
	for i in ANEIS_CASCA:
		var altura := 1.0 - float(i + 0.5) / ANEIS_CASCA
		for j in LADOS_CASCA:
			var jj := (j + 1) % LADOS_CASCA
			# No fundo aberto a parede some (do 3º anel para baixo); o teto fica.
			if enfeitada and i >= 2 and _no_fundo_aberto(TAU * (j + 0.75) / LADOS_CASCA):
				continue
			var a: Vector3 = pontos[i][j]
			var b: Vector3 = pontos[i][jj]
			var d: Vector3 = pontos[i + 1][j]
			var e: Vector3 = pontos[i + 1][jj]
			if i % 2:
				_face(st, a, b, e, _cor_pedra(altura), olho)
				_face(st, a, e, d, _cor_pedra(altura), olho)
			else:
				_face(st, a, b, d, _cor_pedra(altura), olho)
				_face(st, b, e, d, _cor_pedra(altura), olho)


## Piso de lajotas em anéis (folha): cada lajota num tom, mais quente e
## clara perto da forja, roxa e fria na borda. É plano: a colisão do chão é
## um disco liso à parte.
func _chao(st: SurfaceTool, c: Vector3) -> void:
	var raios := [0.0, 8.0, 10.6, 13.4, 16.4, 19.6, 23.0, RAIO_CAMARA + 1.0]
	var olho := c + Vector3.UP * 5.0
	for i in raios.size() - 1:
		var dentro: float = raios[i]
		var fora: float = raios[i + 1]
		var lajotas := 14 + i * 6
		var perto := 1.0 - float(i) / (raios.size() - 2)
		for j in lajotas:
			var a0 := TAU * (j + (0.5 if i % 2 else 0.0)) / lajotas
			var a1 := a0 + TAU / lajotas
			var cor := GeometriaLowPoly.variar(COR_CHAO.lerp(COR_CHAO_QUENTE, clampf(perto, 0.0, 1.0)), _rng, 0.2)
			var p0 := c + Vector3(cos(a0), 0, sin(a0)) * dentro
			var p1 := c + Vector3(cos(a1), 0, sin(a1)) * dentro
			var p2 := c + Vector3(cos(a0), 0, sin(a0)) * fora
			var p3 := c + Vector3(cos(a1), 0, sin(a1)) * fora
			if i > 0:
				_face(st, p0, p1, p3, cor, olho)
			_face(st, p0, p3, p2, cor, olho)


## Pedestal da bigorna (folha): dois degraus redondos de pedra.
func _pedestal(st: SurfaceTool, c: Vector3) -> void:
	var lados := 12
	for n in PEDESTAL.size() - 1:
		var r0: float = PEDESTAL[n][0]
		var y0: float = PEDESTAL[n][1]
		var r1: float = PEDESTAL[n + 1][0]
		var y1: float = PEDESTAL[n + 1][1]
		for j in lados:
			var a0 := TAU * (j + n * 0.5) / lados
			var a1 := a0 + TAU / lados
			var subida := not is_equal_approx(y0, y1)
			var cor := GeometriaLowPoly.variar(COR_PEDESTAL * (0.78 if subida else 1.0), _rng, 0.12)
			var p0 := c + Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p1 := c + Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p2 := c + Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var p3 := c + Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			var olho := c + Vector3(cos(a0), 0.6, sin(a0)) * 9.0
			_face(st, p0, p1, p3, cor, olho)
			if r1 > 0.0:
				_face(st, p0, p3, p2, cor, olho)


## Fita plana acesa no chão ou nos degraus, entre dois pontos.
func _fita(st: SurfaceTool, a: Vector3, b: Vector3, largura: float, cor: Color) -> void:
	var lado := (b - a).cross(Vector3.UP).normalized() * largura / 2.0
	var olho := (a + b) / 2.0 + Vector3.UP * 4.0
	_face(st, a + lado, a - lado, b - lado, cor, olho)
	_face(st, a + lado, b - lado, b + lado, cor, olho)


## Linhas de runa acesas no piso (folha): um anel em volta do pedestal, outro
## maior, losangos de runa no anel e lava nas subidas dos degraus.
func _linhas_de_runa(c: Vector3) -> void:
	var st := GeometriaLowPoly.nova()
	var y := Vector3.UP * 0.03
	for anel in [[8.25, 0.26, 36, 1.0], [RAIO_ANEL_DE_RUNAS, 0.16, 48, 0.8], [17.6, 0.12, 60, 0.45]]:
		var raio: float = anel[0]
		var partes: int = anel[2]
		for j in partes:
			if j % 9 == 8:
				continue # anel quebrado aqui e ali: linha antiga, gasta
			var a0 := TAU * j / partes
			var a1 := TAU * (j + 1) / partes
			_fita(st, c + y + Vector3(cos(a0), 0, sin(a0)) * raio, c + y + Vector3(cos(a1), 0, sin(a1)) * raio, anel[1], COR_VEIO * anel[3])
	# losangos de runa no anel do meio (como os da bigorna e dos estandartes)
	for k in 6:
		var a := TAU * k / 6.0
		var m := c + y + Vector3(cos(a), 0, sin(a)) * RAIO_ANEL_DE_RUNAS
		var para_fora := Vector3(cos(a), 0, sin(a)) * 0.9
		var de_lado := Vector3(-sin(a), 0, cos(a)) * 0.6
		var pontas := [m + para_fora, m + de_lado, m - para_fora, m - de_lado]
		for q in 4:
			_fita(st, pontas[q], pontas[(q + 1) % 4], 0.14, COR_VEIO)
	# lava nas subidas do pedestal
	for k in 16:
		var a := TAU * (k + 0.3) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for n in [0, 2]:
			var baixo: Array = PEDESTAL[n]
			var alto: Array = PEDESTAL[n + 1]
			var p0: Vector3 = c + d * (float(baixo[0]) + 0.02) + Vector3.UP * (float(baixo[1]) + 0.03)
			var p1: Vector3 = c + d * (float(alto[0]) + 0.02) + Vector3.UP * (float(alto[1]) + 0.03)
			_fita(st, p0, p1, 0.3 if (k + n) % 3 else 0.7, COR_VEIO * 1.0)
	var linhas := MeshInstance3D.new()
	linhas.name = "LinhasDeRuna"
	linhas.mesh = GeometriaLowPoly.finalizar(st)
	linhas.material_override = _material_aceso(COR_VEIO, 0.8)
	linhas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(linhas)


func _material_aceso(cor: Color, energia: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = cor
	mat.emission_energy_multiplier = energia
	return mat


## Lanternas (folha): 4 pedestais de pedra com lanterna em volta da bigorna
## (com luz de verdade) e uma cerca de postes de madeira com lanterna e
## corrente na borda da praça (lanterna só acesa, sem luz, pelo FPS). O
## setor da saída fica sem cerca.
func _lanternas_e_cerca(c: Vector3, colisores: StaticBody3D) -> void:
	var G := GeometriaLowPoly
	var st := G.nova()
	var st_aceso := G.nova()
	var colidir := func(centro: Vector3, raio: float, altura: float) -> void:
		var forma := CylinderShape3D.new()
		forma.radius = raio
		forma.height = altura
		var col := CollisionShape3D.new()
		col.shape = forma
		col.position = centro + Vector3.UP * altura / 2.0
		colisores.add_child(col)
	var lanterna := func(base: Vector3, tamanho: float) -> void:
		# gaiola escura (base e teto) com o miolo aceso
		G.anexar(st, G.cubo(Vector3(0.34, 0.06, 0.34) * tamanho), Transform3D(Basis(), base + Vector3.UP * 0.03 * tamanho), COR_CORRENTE)
		G.anexar(st_aceso, G.cubo(Vector3(0.24, 0.3, 0.24) * tamanho), Transform3D(Basis(), base + Vector3.UP * 0.21 * tamanho), COR_LANTERNA)
		G.anexar(st, G.cilindro(0.24 * tamanho, 0.0, 0.16 * tamanho, 4), Transform3D(Basis(Vector3.UP, PI / 4.0), base + Vector3.UP * 0.44 * tamanho), COR_CORRENTE)
	# pedestais de pedra perto da bigorna
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 9.6
		G.anexar(st, G.cubo(Vector3(0.7, 0.3, 0.7)), Transform3D(Basis(Vector3.UP, a), p + Vector3.UP * 0.15), _cor_pedra(0.0))
		G.anexar(st, G.cubo(Vector3(0.5, 0.6, 0.5)), Transform3D(Basis(Vector3.UP, a), p + Vector3.UP * 0.6), _cor_pedra(0.05))
		lanterna.call(p + Vector3.UP * 0.9, 2.0)
		colidir.call(p, 0.4, 1.4)
		var luz := OmniLight3D.new()
		luz.name = "LuzDaLanterna%d" % k
		luz.light_color = Color(1.0, 0.58, 0.2)
		luz.light_energy = 4.6
		luz.omni_range = 14.0
		luz.position = p + Vector3.UP * 1.5
		add_child(luz)
	# cerca de postes com lanterna e corrente
	var postes: Array[Vector3] = []
	var quantos := 22
	for k in quantos:
		var a := TAU * k / quantos
		# A cerca fica só na frente (lado da entrada, menos o vão da saída) e
		# na beira do abismo (menos onde sobe a rampa do mirante). Nas
		# laterais ficam os móveis do posto, como na folha.
		var na_frente := absf(wrapf(a, -PI, PI)) < 0.75 and absf(wrapf(a, -PI, PI)) >= 0.3
		var no_abismo := absf(wrapf(a - PI, -PI, PI)) < FUNDO_MEIA_ABERTURA + 0.1 and absf(wrapf(a - deg_to_rad(152.0), -PI, PI)) > 0.22
		if not (na_frente or no_abismo):
			postes.append(Vector3.INF)
			continue
		var p := c + Vector3(cos(a), 0, sin(a)) * RAIO_CERCA
		postes.append(p)
		G.anexar(st, G.cubo(Vector3(0.3, 1.3, 0.3)), Transform3D(Basis(Vector3.UP, a), p + Vector3.UP * 0.65), G.variar(COR_MADEIRA, _rng, 0.12))
		G.anexar(st, G.cubo(Vector3(0.38, 0.1, 0.38)), Transform3D(Basis(Vector3.UP, a), p + Vector3.UP * 1.33), G.variar(COR_MADEIRA * 0.8, _rng, 0.1))
		colidir.call(p, 0.22, 1.4)
		if k % 2 == 0:
			lanterna.call(p + Vector3.UP * 1.38, 1.6)
	for k in quantos:
		var p0: Vector3 = postes[k]
		var p1: Vector3 = postes[(k + 1) % quantos]
		if p0 == Vector3.INF or p1 == Vector3.INF:
			continue
		var pontos: Array = []
		var raios: Array = []
		for q in 5:
			var f := q / 4.0
			pontos.append(p0.lerp(p1, f) + Vector3.UP * (1.05 - sin(f * PI) * 0.4))
			raios.append(0.05)
		_tubo(st, pontos, raios, 4, COR_CORRENTE)
	var cerca := MeshInstance3D.new()
	cerca.name = "LanternasECerca"
	cerca.mesh = G.finalizar(st)
	cerca.material_override = _material
	add_child(cerca)
	var aceso := MeshInstance3D.new()
	aceso.name = "LanternasAcesas"
	aceso.mesh = G.finalizar(st_aceso)
	aceso.material_override = _material_aceso(COR_LANTERNA, 1.4)
	aceso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(aceso)


## A abertura (conceito: "uma abertura que sugere conexão com o exterior"):
## uma chaminé de pedra acima do buraco do teto, o céu lá em cima e um feixe
## de luz fria que cai bem em cima da bigorna.
func _abertura_no_teto(c: Vector3) -> void:
	var G := GeometriaLowPoly
	var raio_buraco := sin(POLAR_ABERTURA) * RAIO_CAMARA
	var base := c + Vector3.UP * cos(POLAR_ABERTURA) * RAIO_CAMARA * ACHATAMENTO
	var st := G.nova()
	var lados := 10
	var niveis := [[raio_buraco * 1.02, -0.3], [raio_buraco * 0.86, 2.6], [raio_buraco * 0.74, ALTURA_CHAMINE]]
	for n in niveis.size() - 1:
		for j in lados:
			var a0 := TAU * j / lados
			var a1 := TAU * (j + 1) / lados
			var r0: float = niveis[n][0]
			var y0: float = niveis[n][1]
			var r1: float = niveis[n + 1][0]
			var y1: float = niveis[n + 1][1]
			var p0 := base + Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p1 := base + Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p2 := base + Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var p3 := base + Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			# A pedra clareia subindo: lá em cima bate a luz de fora.
			var cor := G.variar(COR_PEDRA_ALTA.lerp(Color(0.5, 0.56, 0.72), 0.25 + n * 0.45), _rng, 0.08)
			_face(st, p0, p1, p3, cor, base)
			_face(st, p0, p3, p2, cor, base)
	var chamine := MeshInstance3D.new()
	chamine.name = "Chamine"
	chamine.mesh = G.finalizar(st)
	chamine.material_override = _material
	chamine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(chamine)

	var ceu := MeshInstance3D.new()
	ceu.name = "CeuDaAbertura"
	ceu.mesh = G.cilindro(raio_buraco * 0.8, raio_buraco * 0.8, 0.1, lados)
	ceu.position = base + Vector3.UP * ALTURA_CHAMINE
	var mat_ceu := StandardMaterial3D.new()
	mat_ceu.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_ceu.albedo_color = COR_CEU_ABERTURA
	mat_ceu.disable_fog = true
	ceu.material_override = mat_ceu
	ceu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ceu)

	# Feixe: um cone quase transparente que soma luz (como poeira no ar).
	var feixe := MeshInstance3D.new()
	feixe.name = "FeixeDeLuz"
	var altura_feixe := base.y - c.y + 1.0
	feixe.mesh = G.cilindro(raio_buraco * 1.25, raio_buraco * 0.8, altura_feixe, 12)
	feixe.position = c + Vector3.UP * altura_feixe / 2.0
	var mat_feixe := StandardMaterial3D.new()
	mat_feixe.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_feixe.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_feixe.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat_feixe.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_feixe.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat_feixe.albedo_color = Color(COR_CEU_ABERTURA.r, COR_CEU_ABERTURA.g, COR_CEU_ABERTURA.b, 0.035)
	mat_feixe.disable_fog = true
	feixe.material_override = mat_feixe
	feixe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(feixe)

	var luz := SpotLight3D.new()
	luz.name = "LuzDaAbertura"
	luz.light_color = COR_CEU_ABERTURA
	luz.light_energy = 2.2
	luz.spot_range = base.y - c.y + ALTURA_CHAMINE + 2.0
	luz.spot_angle = 17.0
	luz.spot_attenuation = 0.4
	luz.position = base + Vector3.UP * (ALTURA_CHAMINE - 0.5)
	luz.rotation.x = -PI / 2.0
	add_child(luz)


## Tubo que afina seguindo uma lista de pontos (raiz, cipó).
func _tubo(st: SurfaceTool, pontos: Array, raios: Array, lados: int, cor: Color) -> void:
	var aneis: Array = []
	for i in pontos.size():
		var p: Vector3 = pontos[i]
		var t: Vector3 = ((pontos[mini(i + 1, pontos.size() - 1)] as Vector3) - (pontos[maxi(i - 1, 0)] as Vector3)).normalized()
		var u := t.cross(Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.FORWARD).normalized()
		var v := t.cross(u)
		var anel: Array[Vector3] = []
		for j in lados:
			var a := TAU * j / lados
			anel.append(p + (u * cos(a) + v * sin(a)) * raios[i])
		aneis.append(anel)
	for i in pontos.size() - 1:
		var meio: Vector3 = ((pontos[i] as Vector3) + (pontos[i + 1] as Vector3)) / 2.0
		for j in lados:
			var jj := (j + 1) % lados
			var fora: Vector3 = ((aneis[i][j] as Vector3) + (aneis[i + 1][jj] as Vector3)) / 2.0
			var olho: Vector3 = meio + (fora - meio) * 4.0
			var tom := GeometriaLowPoly.variar(cor, _rng, 0.1)
			_face(st, aneis[i][j], aneis[i][jj], aneis[i + 1][jj], tom, olho)
			_face(st, aneis[i][j], aneis[i + 1][jj], aneis[i + 1][j], tom, olho)


## Raízes descendo do teto (conceito): grossas em volta da abertura, mais
## finas espalhadas. Nenhuma chega à altura da cabeça do mago.
func _raizes_do_teto(c: Vector3) -> void:
	var st := GeometriaLowPoly.nova()
	for i in QUANTAS_RAIZES:
		var perto_da_abertura := i < 5
		var a := TAU * i / 5.0 + 0.4 if perto_da_abertura else _rng.randf_range(0.0, TAU)
		var r := 7.0 if perto_da_abertura else _rng.randf_range(9.0, RAIO_CAMARA - 5.0)
		var comprimento := _rng.randf_range(2.0, 4.0)
		var grossura := _rng.randf_range(0.08, 0.14)
		var topo := c + Vector3(cos(a) * r, _altura_do_teto(r) + 0.4, sin(a) * r)
		var pontos: Array = []
		var raios: Array = []
		var torto := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)) * 0.5
		for k in 6:
			var f := k / 5.0
			pontos.append(topo + Vector3.DOWN * comprimento * f + torto * sin(f * PI * 1.5) + Vector3(cos(a), 0, sin(a)) * -0.6 * f)
			raios.append(grossura * (1.0 - f * 0.85))
		_tubo(st, pontos, raios, 5, COR_RAIZ)
	var raizes := MeshInstance3D.new()
	raizes.name = "RaizesDoTeto"
	raizes.mesh = GeometriaLowPoly.finalizar(st)
	raizes.material_override = _material
	add_child(raizes)


## Raízes metálicas da Forja (conceito: "estruturas metálicas e rúnicas que
## continuam para além da área acessível"): saem do pé da bigorna pelo chão,
## com um veio de brasa em cima, e sobem pela parede até sumir no escuro.
func _raizes_metalicas(c: Vector3) -> void:
	var G := GeometriaLowPoly
	var st_metal := G.nova()
	var st_veio := G.nova()
	for i in QUANTAS_RAIZES_METALICAS:
		var a := TAU * (i + 0.5) / QUANTAS_RAIZES_METALICAS
		var desvio := _rng.randf_range(-0.35, 0.35)
		var pontos: Array[Vector3] = []
		for k in 8:
			var f := k / 7.0
			var r := lerpf(8.2, RAIO_CAMARA - 0.8, f)
			var giro := a + desvio * 0.35 * sin(f * PI) + 0.04 * sin(f * 9.0 + i)
			pontos.append(c + Vector3(cos(giro) * r, 0.0, sin(giro) * r))
		# sobe pela parede
		var fim: Vector3 = pontos[-1]
		pontos.append(fim + Vector3.UP * 1.6 + (c - fim).normalized() * 0.2)
		pontos.append(fim + Vector3.UP * 3.6 + (c - fim).normalized() * 0.7)
		for k in pontos.size() - 1:
			var p0 := pontos[k]
			var p1 := pontos[k + 1]
			var f0 := float(k) / (pontos.size() - 1)
			var f1 := float(k + 1) / (pontos.size() - 1)
			var frente := (p1 - p0).normalized()
			var lado := frente.cross(Vector3.UP).normalized() if absf(frente.y) < 0.7 else frente.cross((c - p0).normalized()).normalized()
			var cima := lado.cross(frente).normalized()
			if cima.dot(Vector3.UP if absf(frente.y) < 0.7 else (c - p0)) < 0.0:
				cima = -cima
			var l0 := lerpf(0.34, 0.14, f0)
			var l1 := lerpf(0.34, 0.14, f1)
			var olho := (p0 + p1) / 2.0 + cima * 3.0
			# barra de metal: topo e duas abas inclinadas
			var cor := G.variar(COR_METAL, _rng, 0.12)
			var t0a := p0 + lado * l0 * 0.55 + cima * 0.12
			var t0b := p0 - lado * l0 * 0.55 + cima * 0.12
			var t1a := p1 + lado * l1 * 0.55 + cima * 0.12
			var t1b := p1 - lado * l1 * 0.55 + cima * 0.12
			_face(st_metal, t0a, t0b, t1b, cor, olho)
			_face(st_metal, t0a, t1b, t1a, cor, olho)
			_face(st_metal, t0a, t1a, p1 + lado * l1 - cima * 0.03, cor * 0.8, olho + lado * 4.0)
			_face(st_metal, t0a, p1 + lado * l1 - cima * 0.03, p0 + lado * l0 - cima * 0.03, cor * 0.8, olho + lado * 4.0)
			_face(st_metal, t0b, t1b, p1 - lado * l1 - cima * 0.03, cor * 0.8, olho - lado * 4.0)
			_face(st_metal, t0b, p1 - lado * l1 - cima * 0.03, p0 - lado * l0 - cima * 0.03, cor * 0.8, olho - lado * 4.0)
			# veio de brasa: fita fina no meio do topo, que vai apagando longe da bigorna
			var brilho0 := COR_VEIO * lerpf(1.0, 0.25, f0)
			var v := 0.42
			_face(st_veio, p0 + lado * l0 * v + cima * 0.135, p0 - lado * l0 * v + cima * 0.135, p1 - lado * l1 * v + cima * 0.135, brilho0, olho)
			_face(st_veio, p0 + lado * l0 * v + cima * 0.135, p1 - lado * l1 * v + cima * 0.135, p1 + lado * l1 * v + cima * 0.135, brilho0, olho)
	var metal := MeshInstance3D.new()
	metal.name = "RaizesMetalicas"
	metal.mesh = G.finalizar(st_metal)
	metal.material_override = _material
	metal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(metal)
	var veio := MeshInstance3D.new()
	veio.name = "VeiosDeBrasa"
	veio.mesh = G.finalizar(st_veio)
	veio.material_override = _material_aceso(COR_VEIO, 0.6)
	veio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(veio)


# --- Utilidades -------------------------------------------------------------

func _pedregulho(st: SurfaceTool, colisores: StaticBody3D, centro: Vector3, tamanho: Vector3, cor_pedido := Color(0, 0, 0, 0)) -> void:
	var giro := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
	var cor := cor_pedido if cor_pedido.a > 0.0 else GeometriaLowPoly.variar(Color(0.46, 0.43, 0.46), _rng)
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
