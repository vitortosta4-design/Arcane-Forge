class_name PainelMago
extends Control
## Canto superior esquerdo do HUD (ADR-039, estilo da referência
## docs/referencias/hud-referencia-01.png): retrato redondo do mago numa
## moldura dourada, com a barra de vida e a de mana ao lado. Só LÊ o mago;
## nunca mexe em vida ou mana.
## O retrato é o próprio modelo do mago (mago.glb) fotografado uma vez por
## uma câmera numa "salinha" separada (SubViewport), então ele muda sozinho
## quando o modelo mudar, sem desenho à parte.

const CENTRO_RETRATO := Vector2(46, 46)
const RAIO_RETRATO := 44.0
const ARO := 7.0
const BARRA_X := 100.0
const VIDA_POS := Vector2(BARRA_X, 16)
const VIDA_TAMANHO := Vector2(236, 20)
const MANA_POS := Vector2(BARRA_X, 46)
const MANA_TAMANHO := Vector2(206, 15)
## Fundo quente atrás do mago azul (o crítico reprovou azul sobre azul):
## âmbar embaixo, roxo em cima, como a luz dourada da referência.
const COR_FUNDO_RETRATO := Color(0.85, 0.5, 0.22)
const COR_FUNDO_RETRATO_ALTO := Color(0.5, 0.26, 0.55)
## Câmera do retrato: de frente, na altura dos olhos (a aba larga do chapéu
## esconde o rosto se a câmera vier de cima), pegando o chapéu inteiro.
const CAMERA_RETRATO := Vector3(0.08, 0.42, 1.8)
const ALVO_RETRATO := Vector3(0.0, 0.7, 0.0)
const LADO_RETRATO_PX := 256

var mago: Node = null
var _avisou := false
## O HUD nasce e só depois o mago é ligado (no mesmo quadro ou no seguinte);
## só é problema se continuar sem mago depois de um tempinho.
var _vivo_s := 0.0
var _retrato: SubViewport = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_montar_retrato()


func _process(delta: float) -> void:
	_vivo_s += delta
	queue_redraw()


## Salinha do retrato: o modelo do mago parado, uma luz quente de frente e
## uma azulada de lado (o contraste quente e frio da referência). Desenha um
## quadro só e para (UPDATE_ONCE), então não pesa nada no jogo.
func _montar_retrato() -> void:
	_retrato = SubViewport.new()
	_retrato.size = Vector2i(LADO_RETRATO_PX, LADO_RETRATO_PX)
	_retrato.own_world_3d = true
	_retrato.transparent_bg = true
	_retrato.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_retrato)
	var modelo: Node3D = VisualMago.MODELO.instantiate()
	_retrato.add_child(modelo)
	var anim: AnimationPlayer = modelo.find_child("AnimationPlayer", true, false)
	if anim and anim.has_animation("Parado"):
		anim.play("Parado")
		anim.seek(0.0, true)
		anim.pause()
	elif anim:
		push_warning("PainelMago: mago.glb sem a animação 'Parado'; o retrato sai na pose de modelagem.")
	var camera := Camera3D.new()
	camera.fov = 30.0
	_retrato.add_child(camera)
	camera.look_at_from_position(CAMERA_RETRATO, ALVO_RETRATO)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(1.0, 0.86, 0.66)
	sol.light_energy = 1.3
	_retrato.add_child(sol)
	sol.look_at_from_position(Vector3(0.6, 1.4, 1.4), ALVO_RETRATO)
	var contorno := DirectionalLight3D.new()
	contorno.light_color = Color(0.55, 0.65, 1.0)
	contorno.light_energy = 0.9
	_retrato.add_child(contorno)
	contorno.look_at_from_position(Vector3(-1.2, 0.9, -0.6), ALVO_RETRATO)
	var ambiente := WorldEnvironment.new()
	ambiente.environment = Environment.new()
	ambiente.environment.background_mode = Environment.BG_CLEAR_COLOR
	ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.environment.ambient_light_color = Color(0.5, 0.55, 0.8)
	ambiente.environment.ambient_light_energy = 0.6
	_retrato.add_child(ambiente)


func _draw() -> void:
	if mago == null:
		if not _avisou and _vivo_s > 1.0:
			push_warning("PainelMago: nenhum mago configurado; retrato, vida e mana não aparecem.")
			_avisou = true
		return
	_desenhar_retrato()
	EstiloHud.barra(self, VIDA_POS, VIDA_TAMANHO, _fracao(mago.vida_atual, mago.vida_maxima), EstiloHud.VIDA, EstiloHud.VIDA_CLARA)
	EstiloHud.barra(self, MANA_POS, MANA_TAMANHO, _fracao(mago.mana_atual, mago.mana_maxima), EstiloHud.MANA, EstiloHud.MANA_CLARA)


func _fracao(atual, maxima) -> float:
	return clampf(float(atual) / float(maxima), 0.0, 1.0) if float(maxima) > 0.0 else 0.0


func _desenhar_retrato() -> void:
	var raio_dentro := RAIO_RETRATO - ARO
	# Fundo em degradê, roxo em cima e âmbar embaixo.
	var fundo := PackedVector2Array()
	var cores := PackedColorArray()
	for i in 48:
		var a := TAU * i / 48.0
		var p := CENTRO_RETRATO + Vector2(cos(a), sin(a)) * raio_dentro
		fundo.append(p)
		cores.append(COR_FUNDO_RETRATO_ALTO.lerp(COR_FUNDO_RETRATO, (sin(a) + 1.0) / 2.0))
	draw_polygon(fundo, cores)
	if _retrato:
		# A foto do modelo recortada em círculo: um polígono redondo que usa
		# a textura da salinha como "papel de parede".
		var pontos := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i in 48:
			var a := TAU * i / 48.0
			var d := Vector2(cos(a), sin(a))
			pontos.append(CENTRO_RETRATO + d * raio_dentro)
			uvs.append(Vector2(0.5, 0.5) + d * 0.5)
		draw_polygon(pontos, PackedColorArray([Color.WHITE]), uvs, _retrato.get_texture())
	EstiloHud.aro(self, CENTRO_RETRATO, RAIO_RETRATO, ARO, 4)
