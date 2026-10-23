class_name MinimapaReservado
extends Control
## Minimapa no canto inferior direito (ADR-039), no estilo da referência
## (docs/referencias/hud-referencia-01.png): aro dourado, plaquinha do N e,
## dentro, a clareira vista de cima com o mago, as runas no chão, os inimigos
## e a boca da caverna da forja.
##
## Como funciona: uma câmera de cima tira UMA foto do mundo (o mesmo mundo do
## jogo, sem névoa) logo que a arena termina de montar, e o minimapa recorta
## o pedaço em volta do mago. O norte fica sempre para cima e a seta gira
## com o mago. Os pontinhos são desenhados por cima a cada quadro (não
## precisam de foto nova). Dentro da caverna, que fica embaixo do mapa, o
## minimapa mostra só a câmara.
## (O nome da classe ficou do tempo em que era só o espaço reservado.)

const ARO := 7.0
const COR_FORA := Color(0.12, 0.2, 0.2, 0.92)
const COR_CAVERNA := Color(0.14, 0.09, 0.2, 0.95)
## Pedaço do mundo fotografado (quadrado, centrado na origem).
const LADO_MUNDO_M := 140.0
const LADO_FOTO_PX := 512
## Quantos metros cabem do centro até a borda do minimapa.
const ALCANCE_M := 30.0
const ALTURA_CAMERA_M := 120.0
## Abaixo disto o mago está na câmara da caverna (Caverna.CENTRO_CAMARA).
const ALTURA_CAVERNA_M := -40.0
## Segundos até a foto: a clareira e a caverna montam o cenário no _ready.
const FOTO_APOS_S := 0.4

var _fonte: Font = null
var _foto: SubViewport = null
var _vivo_s := 0.0
var _fotografou := false


func _ready() -> void:
	_fonte = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_vivo_s += delta
	if not _fotografou and _vivo_s >= FOTO_APOS_S:
		_fotografou = true
		_tirar_foto()
	queue_redraw()


func _tirar_foto() -> void:
	var mundo := get_viewport().world_3d
	# Sem mundo 3D (HUD aberto sozinho numa tela de teste): normal, fica só o
	# disco com o aro.
	if mundo == null or get_viewport().get_camera_3d() == null:
		return
	_foto = SubViewport.new()
	_foto.size = Vector2i(LADO_FOTO_PX, LADO_FOTO_PX)
	_foto.world_3d = mundo
	_foto.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_foto)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = LADO_MUNDO_M
	camera.far = ALTURA_CAMERA_M + 60.0
	# Ambiente próprio sem névoa: a névoa de distância deixaria a foto lavada.
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = COR_FORA
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.75, 0.8, 0.9)
	ambiente.ambient_light_energy = 0.55
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	camera.environment = ambiente
	_foto.add_child(camera)
	# Olhando para baixo, com o norte (-Z) para cima na foto.
	camera.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, ALTURA_CAMERA_M, 0))


func _draw() -> void:
	var centro := size / 2.0
	var raio := minf(size.x, size.y) / 2.0
	var raio_dentro := raio - ARO
	var mago := _mago()
	var na_caverna := mago != null and mago.global_position.y < ALTURA_CAVERNA_M
	draw_circle(centro, raio_dentro, COR_CAVERNA if na_caverna else COR_FORA)
	if mago and not na_caverna and _foto:
		_desenhar_foto(centro, raio_dentro, mago.global_position)
	if mago and not na_caverna:
		_desenhar_pontos(centro, raio_dentro, mago.global_position)
	elif na_caverna:
		_bigorna(centro + Vector2(0, -raio_dentro * 0.35), 7.0)
	_seta(centro, mago)
	EstiloHud.aro(self, centro, raio, ARO, 0)
	EstiloHud.placa(self, centro + Vector2(0, -raio + 2.0), 20.0, "N", _fonte, 13)


func _mago() -> Node3D:
	# O minimapa é do jogador local: o mago do grupo "mago" (só um por PC).
	var magos := get_tree().get_nodes_in_group("mago")
	return magos[0] as Node3D if not magos.is_empty() else null


## Recorte redondo da foto, em volta do mago: um polígono redondo que usa a
## foto como "papel de parede", com a janela de UV seguindo o mago.
func _desenhar_foto(centro: Vector2, raio: float, pos: Vector3) -> void:
	var meio_uv := Vector2(pos.x, pos.z) / LADO_MUNDO_M + Vector2(0.5, 0.5)
	var raio_uv := ALCANCE_M / LADO_MUNDO_M
	var pontos := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		var d := Vector2(cos(a), sin(a))
		pontos.append(centro + d * raio)
		uvs.append(meio_uv + d * raio_uv)
	draw_polygon(pontos, PackedColorArray([Color(1, 1, 1, 0.95)]), uvs, _foto.get_texture())
	# Véu escuro por cima: a foto do sol a pino fica mais viva que o cenário
	# e gritava no canto; assim os pontinhos saltam.
	draw_circle(centro, raio, Color(0.1, 0.12, 0.18, 0.38))


func _no_minimapa(centro: Vector2, raio: float, origem: Vector3, ponto: Vector3) -> Vector2:
	var d := Vector2(ponto.x - origem.x, ponto.z - origem.z) / ALCANCE_M * raio
	# Quem está fora do alcance fica preso na borda, para o jogador saber a direção.
	if d.length() > raio - 5.0:
		d = d.normalized() * (raio - 5.0)
	return centro + d


func _desenhar_pontos(centro: Vector2, raio: float, origem: Vector3) -> void:
	_bigorna(_no_minimapa(centro, raio, origem, Vector3(Caverna.BOCA.x, 0, Caverna.BOCA.y)), 5.5)
	for runa in get_tree().get_nodes_in_group("runa_no_mapa"):
		var p := _no_minimapa(centro, raio, origem, (runa as Node3D).global_position)
		draw_circle(p, 2.9, Color(0, 0, 0, 0.7))
		draw_circle(p, 2.0, RunaColetavel.CORES.get(str(runa.get("nome")), Color.WHITE))
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not (inimigo is Node3D) or (inimigo.has_method("fracao_vida") and inimigo.fracao_vida() <= 0.0):
			continue
		# Inimigo é losango vermelho com contorno grosso: lê como ameaça, não
		# como mais uma runa (o crítico achou que tudo virava confete).
		var p := _no_minimapa(centro, raio, origem, inimigo.global_position)
		EstiloHud.losango(self, p, 7.0, Color(0, 0, 0, 0.85), Color(0, 0, 0, 0))
		EstiloHud.losango(self, p, 5.0, EstiloHud.VIDA, Color(1, 0.85, 0.8))


## Marca da forja: uma bigorna roxa pequena.
func _bigorna(p: Vector2, t: float) -> void:
	var corpo := PackedVector2Array([p + Vector2(-t, -t * 0.5), p + Vector2(t * 1.1, -t * 0.5), p + Vector2(t * 0.4, t * 0.05),
		p + Vector2(t * 0.35, t * 0.5), p + Vector2(t * 0.7, t * 0.75), p + Vector2(-t * 0.7, t * 0.75),
		p + Vector2(-t * 0.35, t * 0.5), p + Vector2(-t * 0.4, t * 0.05)])
	draw_circle(p, t + 3.0, Color(0, 0, 0, 0.55))
	draw_colored_polygon(corpo, Color(0.78, 0.55, 1.0))


## Seta do jogador no meio, apontando para onde o mago olha (norte em cima).
func _seta(centro: Vector2, mago: Node3D) -> void:
	var angulo := 0.0
	if mago:
		# O mago olha para -Z do próprio corpo; no minimapa, -Z é para cima.
		var frente := -mago.global_transform.basis.z
		angulo = atan2(frente.x, -frente.z)
	var seta := PackedVector2Array([Vector2(0, -10), Vector2(8, 8), Vector2(0, 3), Vector2(-8, 8)])
	for i in seta.size():
		seta[i] = centro + seta[i].rotated(angulo)
	var sombra := seta.duplicate()
	for i in sombra.size():
		sombra[i] += Vector2(0, 2)
	draw_colored_polygon(sombra, EstiloHud.SOMBRA)
	draw_colored_polygon(seta, Color.WHITE)
