class_name VisualGalinha
extends Node3D
## Corpo visível da galinha v4 (arte/personagens/galinha/galinha.py): esqueleto
## com peças rígidas e as animações Parado, Andar, Bicar, Dano e Morrer.
## O mesmo modelo serve a galinha invocada e a galinha zumbi; a zumbi é uma
## variante pintada aqui (verde acinzentado, olhos brilhando, penas faltando,
## andar torto). Só mostra: quem decide bicar, apanhar e morrer é o dono
## (galinha_zumbi.gd, invocacao.gd), que chama as funções abaixo.

const MODELO := preload("res://assets/modelos/galinha/galinha.glb")
## O .glb tem 1,02 m do pé à crista. 1,426 deixa com 1,45 m, a altura da
## galinha antiga em espaço global (medida em 29/10/2026).
const ESCALA_MODELO := 1.426
## Velocidade (m/s, no tamanho do .glb) em que o Andar foi gravado com o pé
## parado no chão. A animação acelera e freia na proporção da velocidade real.
const VELOCIDADE_ANDAR_MODELO := 3.5
## Fases do ciclo de Andar (0 a 1) em que cada pé está apoiado. Fora delas a
## zumbi pode mancar (mudar o ritmo) sem o pé patinar.
const APOIOS_ANDAR: Array[Vector2] = [Vector2(0.0, 0.16), Vector2(0.5, 0.66)]
## Instante, desde o início da Bicar, em que o bico chega no alvo. O aviso
## (recua a cabeça e agacha) dura 0,4 s; o bote leva mais 0,07 s.
const AVISO_BICADA_S := 0.4
const TEMPO_ACERTO_BICADA_S := 0.47
## Quanto tempo o corpo fica deitado (Morrer dura 1,3 s) antes de sumir.
const TEMPO_CORPO_NO_CHAO_S := 2.2

## Pálida e fria (crítico, 12/11/2026: o verde oliva sumia na grama verde).
const COR_ZUMBI := Color(0.74, 0.88, 0.8)
const COR_OLHO_ZUMBI := Color(0.75, 1.0, 0.35)
## Penas da cauda que a zumbi já perdeu.
## Tirar a de cima e uma do meio deixa o recorte da cauda "mordido".
const PENAS_FALTANDO_ZUMBI := ["Pena_0", "Pena_2"]
## Penas soltas da cor do corpo de quem apanhou.
const COR_PENA_SOLTA := Color(0.98, 0.8, 0.56)
const COR_PENA_SOLTA_ZUMBI := Color(0.74, 0.8, 0.76)
## Congelada rápida ao levar o golpe, para o impacto ter peso.
const PAUSA_IMPACTO_S := 0.05
const PICO_DANO_S := 0.033
## Clarão branco ao apanhar (ressalva do crítico, 12/11/2026: "falta um
## piscar branco de 2 ou 3 quadros"). A galinha inteira vira silhueta branca
## por este tempo. Troca o material das superfícies, não o `material_overlay`,
## que é da camada de cor dos estados (ControladorEstados): os dois convivem.
const CLARAO_S := 0.08
## Aviso da bicada da zumbi (ressalva do crítico: ela anda rebolando, então o
## aviso mexia menos que o andar). Só nela, durante o aviso, o corpo incha,
## tomba para trás e treme; no bote volta ao normal de uma vez.
const INCHACO_AVISO_ZUMBI := 0.25
const TOMBO_AVISO_ZUMBI := 0.3
const TREMOR_AVISO_ZUMBI := 0.16
const TREMOR_AVISO_HZ := 10.0

var zumbi := false

var _modelo: Node3D
var _anim: AnimationPlayer
## Ação de uma vez só (Bicar, Dano, Morrer) tocando: o andar não a interrompe.
var _acao := ""
var _morta := false
var _tempo := 0.0
var _material_clarao: StandardMaterial3D
## [malha, superfície, material que estava] de cada superfície durante o clarão.
var _antes_do_clarao: Array = []
var _fim_do_clarao: Tween
## 0 a 1: quanto do aviso da zumbi está armado.
var _aviso_zumbi := 0.0


static func criar(e_zumbi: bool) -> VisualGalinha:
	var visual := VisualGalinha.new()
	visual.zumbi = e_zumbi
	return visual


func _ready() -> void:
	_modelo = MODELO.instantiate()
	# O modelo do Blender olha para +Z; a criatura anda para -Z.
	_modelo.rotation.y = PI
	_modelo.scale = Vector3.ONE * ESCALA_MODELO
	add_child(_modelo)
	_anim = _modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_error("VisualGalinha: galinha.glb sem AnimationPlayer.")
		return
	for nome in ["Parado", "Andar"]:
		_anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	_anim.animation_finished.connect(_ao_terminar_acao)
	_anim.play("Parado")
	if zumbi:
		_virar_zumbi()


## Chamado todo quadro pelo dono com a velocidade horizontal real (m/s).
func atualizar_andar(velocidade: float) -> void:
	if _anim == null or _morta or _acao != "":
		return
	var escala := global_transform.basis.get_scale().y * ESCALA_MODELO
	if velocidade < 0.1:
		_tocar_ciclo("Parado", 1.0)
		return
	var ritmo := velocidade / (VELOCIDADE_ANDAR_MODELO * escala)
	_tocar_ciclo("Andar", ritmo * _fator_manco())


func bicar() -> void:
	_tocar_acao("Bicar")


## interrompe_bicada: a regra cancelou a bicada (ADR-048), então a animação
## Bicar é trocada pela Dano; senão o que se vê não bateria com a regra.
func levar_dano(interrompe_bicada := false) -> void:
	if _morta:
		return
	_soltar_penas(9)
	_piscar_branco()
	# No meio da bicada o dano dela ainda vai sair: a Bicar continua na tela
	# para o que se vê bater com a regra; só as penas e a pausa mostram o golpe.
	if _acao != "Bicar" or interrompe_bicada:
		_tocar_acao("Dano")
		# A pausa do golpe congela a galinha já jogada para trás (o pico do
		# tranco fica aos 0,033 s da animação). Congelar no quadro zero era
		# congelar a pose neutra: o golpe não aparecia.
		# Sem mistura: com a animação parada a mistura também não anda.
		_anim.play("Dano", 0.0)
		_anim.seek(PICO_DANO_S, true)
	_anim.speed_scale = 0.0
	var pausa := create_tween()
	pausa.tween_interval(PAUSA_IMPACTO_S)
	pausa.tween_callback(func(): _anim.speed_scale = 1.0)


func morrer() -> void:
	if _morta:
		return
	_morta = true
	create_tween().tween_property(self, "rotation:z", 0.0, 0.1)
	_tocar_acao("Morrer")
	_soltar_penas(16)
	# Nos últimos 0,3 s deitada, encolhe acelerando e solta um punhado de penas.
	var sumir := create_tween()
	sumir.tween_interval(TEMPO_CORPO_NO_CHAO_S - 0.3)
	sumir.tween_callback(_soltar_penas.bind(6))
	sumir.tween_property(self, "scale", Vector3.ZERO, 0.28).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_tempo += delta
	if not zumbi or _morta:
		return
	# Aviso da bicada: arma em 60% do tempo do aviso e desarma rápido no bote.
	var no_aviso := _anim != null and _acao == "Bicar" and _anim.current_animation == "Bicar" \
		and _anim.current_animation_position < AVISO_BICADA_S
	if no_aviso:
		_aviso_zumbi = clampf(_anim.current_animation_position / (AVISO_BICADA_S * 0.6), 0.0, 1.0)
	else:
		_aviso_zumbi = move_toward(_aviso_zumbi, 0.0, delta * 12.0)
	var armado := ease(_aviso_zumbi, 0.4)
	_modelo.scale = Vector3.ONE * ESCALA_MODELO * (1.0 + INCHACO_AVISO_ZUMBI * armado)
	# O modelo olha para +Z dele: X negativo joga o topo para trás.
	_modelo.rotation.x = -TOMBO_AVISO_ZUMBI * armado
	# Andar torto da zumbi: corpo caído para um lado, balançando fora do passo.
	var andando := _anim != null and _anim.current_animation == "Andar"
	var alvo := 0.2 + 0.1 * sin(_tempo * 3.1) if andando else 0.07
	rotation.z = lerpf(rotation.z, alvo, minf(1.0, delta * 6.0))
	if _aviso_zumbi > 0.0:
		rotation.z = 0.07 + sin(_tempo * TAU * TREMOR_AVISO_HZ) * TREMOR_AVISO_ZUMBI * armado


## Silhueta branca por CLARAO_S. Um golpe em cima do outro só renova o tempo.
func _piscar_branco() -> void:
	if _modelo == null:
		return # normal: dano antes do _ready (o visual ainda não montou)
	if _material_clarao == null:
		_material_clarao = StandardMaterial3D.new()
		_material_clarao.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material_clarao.albedo_color = Color.WHITE
		# Na nuvem (Compatibility) o branco sai 214 de 255 por causa do ajuste
		# de tons da câmera, com ou sem luz própria. A luz própria fica para o
		# Forward+ do PC do Vitor, onde o brilho (glow) pode pegar nela: conferir lá.
		_material_clarao.emission_enabled = true
		_material_clarao.emission = Color.WHITE
		_material_clarao.emission_energy_multiplier = 1.0
	if _antes_do_clarao.is_empty():
		for no in _modelo.find_children("*", "MeshInstance3D", true, false):
			var malha := no as MeshInstance3D
			if malha.mesh == null:
				push_warning("VisualGalinha: malha '%s' vazia no galinha.glb." % malha.name)
				continue
			for s in malha.mesh.get_surface_count():
				_antes_do_clarao.append([malha, s, malha.get_surface_override_material(s)])
				malha.set_surface_override_material(s, _material_clarao)
	if _fim_do_clarao:
		_fim_do_clarao.kill()
	_fim_do_clarao = create_tween()
	_fim_do_clarao.tween_interval(CLARAO_S)
	_fim_do_clarao.tween_callback(_apagar_clarao)


func _apagar_clarao() -> void:
	for item in _antes_do_clarao:
		if is_instance_valid(item[0]):
			(item[0] as MeshInstance3D).set_surface_override_material(item[1], item[2])
	_antes_do_clarao.clear()


func _tocar_ciclo(nome: String, ritmo: float) -> void:
	if _anim.current_animation != nome:
		_anim.play(nome, 0.12)
	_anim.speed_scale = ritmo


func _tocar_acao(nome: String) -> void:
	if _anim == null or (_morta and nome != "Morrer"):
		return
	_acao = nome
	_anim.speed_scale = 1.0
	_anim.play(nome, 0.05)
	_anim.seek(0.0, true)


func _ao_terminar_acao(nome: String) -> void:
	# Morrer fica parada na última pose (deitada com as pernas para cima).
	if nome == _acao and nome != "Morrer":
		_acao = ""
		_anim.play("Parado", 0.15)


## Zumbi manca: um salto apressado e outro arrastado. Só muda o ritmo com os
## dois pés no ar, então o pé apoiado continua parado no chão.
func _fator_manco() -> float:
	if not zumbi or _anim.current_animation != "Andar":
		return 1.0
	var fase := fmod(_anim.current_animation_position / _anim.current_animation_length, 1.0)
	for apoio in APOIOS_ANDAR:
		if fase >= apoio.x and fase <= apoio.y:
			return 1.0
	return 1.5 if fase < 0.5 else 0.7


func _virar_zumbi() -> void:
	for nome in PENAS_FALTANDO_ZUMBI:
		var pena := _modelo.find_child(nome, true, false) as Node3D
		if pena == null:
			push_error("VisualGalinha: pena %s não existe no galinha.glb." % nome)
			continue
		pena.visible = false
	for no in _modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := no as MeshInstance3D
		for s in malha.mesh.get_surface_count():
			var original := malha.mesh.surface_get_material(s) as StandardMaterial3D
			if original == null:
				continue
			var mat := original.duplicate() as StandardMaterial3D
			if original.resource_name == "G_Branco":
				# Olho aceso (brilho próprio é permitido em olhos mágicos); a
				# pupila fica escura para o olhar continuar legível.
				mat.albedo_color = COR_OLHO_ZUMBI
				mat.emission_enabled = true
				mat.emission = COR_OLHO_ZUMBI
				mat.emission_energy_multiplier = 0.7
			elif original.resource_name == "G_Preto":
				pass
			else:
				mat.albedo_color = (original.albedo_color * COR_ZUMBI).lerp(Color(0.74, 0.76, 0.84), 0.35)
			malha.set_surface_override_material(s, mat)


func _soltar_penas(quantidade: int) -> void:
	var penas := CPUParticles3D.new()
	penas.one_shot = true
	penas.emitting = false
	penas.amount = quantidade
	penas.lifetime = 1.3
	penas.explosiveness = 0.95
	penas.mesh = _malha_pena()
	penas.color = COR_PENA_SOLTA_ZUMBI if zumbi else COR_PENA_SOLTA
	penas.hue_variation_min = -0.03
	penas.hue_variation_max = 0.03
	penas.scale_amount_min = 0.6
	penas.scale_amount_max = 1.3
	penas.direction = Vector3.UP
	penas.spread = 70.0
	penas.initial_velocity_min = 1.2
	penas.initial_velocity_max = 2.4
	penas.gravity = Vector3(0, -2.0, 0)
	# Amortecimento alto: sobem rápido e descem flutuando, girando no ar.
	penas.damping_min = 2.5
	penas.damping_max = 4.0
	penas.angular_velocity_min = -300.0
	penas.angular_velocity_max = 300.0
	penas.angle_min = 0.0
	penas.angle_max = 360.0
	penas.particle_flag_rotate_y = true
	penas.local_coords = false
	add_child(penas)
	penas.position = Vector3(0, 0.55, 0)
	penas.emitting = true
	penas.finished.connect(penas.queue_free)


## Pena em losango alongado (ponta fina embaixo), dos dois lados.
static func _malha_pena() -> ArrayMesh:
	var pontos := PackedVector3Array([
		Vector3(0, 0.09, 0), Vector3(0.028, 0.03, 0), Vector3(0, -0.07, 0),
		Vector3(0, 0.09, 0), Vector3(0, -0.07, 0), Vector3(-0.028, 0.03, 0),
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pontos
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	malha.surface_set_material(0, mat)
	return malha
