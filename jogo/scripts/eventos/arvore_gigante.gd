class_name ArvoreGigante
extends Node3D
## Primeiro evento ambiental raro (ADR-047): uma árvore-gigante humanoide,
## pela referência do Vitor (`docs/referencias/gigante_arvore.png`), que
## atravessa o mapa andando devagar e desaparece na neblina do outro lado.
##
## Quem decide quando e por onde ela passa é o GerenciadorEventosAmbientais
## (o host); este nó só sabe andar de `_origem` a `_destino` e existir
## fisicamente no caminho, para o jogador que estiver olhando ver exatamente
## a mesma coisa.
##
## Sólida, mas indiferente: empurra quem estiver no caminho (jogador,
## inimigo, caixa) só por estar lá, sem reagir a nada: não entra em nenhum
## grupo de "recebe_dano" e não tem `receber_dano`, então nem o Host nem o
## Validador acham o que fazer com ela e nada acontece (igual a uma pedra do
## cenário). As raízes dos pés, baixas e largas, são andáveis; pernas e
## tronco, verticais, acima delas, não são chão em nenhum ângulo, então não
## há como escalar além delas sem precisar de nenhuma regra especial.

const ALTURA_TOTAL_M := 26.0
const VELOCIDADE_MS := 1.1
## Pé/raiz: largo e baixo, para subir. Perna: estreita e vertical, acima.
const RAIO_PE_M := 2.5
const ALTURA_PE_M := 1.7
const RAIO_PERNA_M := 1.25
const ALTURA_PERNA_M := 8.5
const ALTURA_TORSO_M := 6.3
const RAIO_TORSO_BASE_M := 2.0
const RAIO_TORSO_TOPO_M := 2.7
const ALTURA_CABECA_M := 2.2
## Metade da distância entre os dois pés/pernas (postura humanoide).
const AFASTAMENTO_PERNAS_M := 1.9
## Últimos metros da rota em que ela desaparece, encolhendo e afundando,
## dentro da neblina (ADR-031, distância de névoa da arena).
const DISTANCIA_DESAPARECER_M := 14.0
## Raio em que o jogador sente o tremor de câmera e ouve o rangido grave.
const RAIO_PERCEPCAO_M := 22.0
const INTERVALO_PASSO_S := 2.2
## Além desta distância, troca o visual detalhado por uma silhueta barata
## (GTX 1050, pedido do Vitor).
const DISTANCIA_LOD_M := 52.0

## Uma casca só, com variação de ruído por peça (GeometriaLowPoly.variar),
## nunca duas cores constantes bem diferentes encostando uma na outra: foi
## exatamente isso que o crítico reprovou na 1ª versão ("corte de cor que
## parece bug de UV").
## Usadas só pela silhueta distante (abaixo); o visual de perto vem do .glb.
const COR_CASCA := Color(0.34, 0.21, 0.13)
## Verde musgoso e envelhecido, de propósito diferente do verde-pinheiro
## comum da Clareira (pedido do crítico: "não pode ler como pinheiro
## ampliado").
const COR_COPA := Color(0.24, 0.34, 0.16)

## Modelo de verdade pela folha do Vitor (docs/referencias/gigante_arvore.png,
## sorriso calmo e olhos suaves na 2ª versão), feito pela skill
## personagem-low-poly: arte/personagens/gigante_arvore/gigante_arvore.py.
## Tem esqueleto e duas animações (Parado, Andar); sem Atacar nem Dano porque
## a árvore não ataca nem reage a dano (ADR-047, "sólida mas indiferente").
## O visual distante (silhueta, abaixo) continua procedural: é barato e já
## lê bem de longe, não vale o custo de outro modelo só para o LOD.
const MODELO_DETALHADO := preload("res://assets/modelos/gigante_arvore/gigante_arvore.glb")

var _origem := Vector3.ZERO
var _destino := Vector3.ZERO
var _distancia_total := 0.0
var _percorrido := 0.0
var _tempo_desde_passo := 0.0
var _desaparecendo := false

var _corpo: AnimatableBody3D
var _visual_perto: Node3D
var _visual_longe: Node3D
var _anim: AnimationPlayer
var _rng := RandomNumberGenerator.new()


## Chamado pelo GerenciadorEventosAmbientais assim que o nó já está na
## árvore (depois do add_child), com os dois pontos da rota.
func iniciar(origem: Vector3, destino: Vector3) -> void:
	_origem = origem
	_destino = destino
	_distancia_total = origem.distance_to(destino)
	global_position = origem
	if _distancia_total > 0.01:
		look_at(destino, Vector3.UP)
	_rng.randomize()
	_montar()


func _montar() -> void:
	_corpo = AnimatableBody3D.new()
	_corpo.name = "Corpo"
	_corpo.sync_to_physics = true
	_corpo.collision_layer = 1
	_corpo.collision_mask = 0
	add_child(_corpo)

	for lado: float in [-1.0, 1.0]:
		var x := lado * AFASTAMENTO_PERNAS_M
		var colisao_pe := CollisionShape3D.new()
		var forma_pe := CylinderShape3D.new()
		forma_pe.radius = RAIO_PE_M
		forma_pe.height = ALTURA_PE_M
		colisao_pe.shape = forma_pe
		colisao_pe.position = Vector3(x, ALTURA_PE_M / 2.0, 0.0)
		_corpo.add_child(colisao_pe)

		var colisao_perna := CollisionShape3D.new()
		var forma_perna := CylinderShape3D.new()
		forma_perna.radius = RAIO_PERNA_M
		forma_perna.height = ALTURA_PERNA_M
		colisao_perna.shape = forma_perna
		colisao_perna.position = Vector3(x, ALTURA_PE_M + ALTURA_PERNA_M / 2.0, 0.0)
		_corpo.add_child(colisao_perna)

	var colisao_torso := CollisionShape3D.new()
	var forma_torso := CylinderShape3D.new()
	forma_torso.radius = RAIO_TORSO_TOPO_M
	forma_torso.height = ALTURA_TORSO_M + ALTURA_CABECA_M
	colisao_torso.shape = forma_torso
	colisao_torso.position = Vector3.UP * (ALTURA_PE_M + ALTURA_PERNA_M + (ALTURA_TORSO_M + ALTURA_CABECA_M) / 2.0)
	_corpo.add_child(colisao_torso)

	_visual_perto = _montar_visual_detalhado()
	add_child(_visual_perto)
	for malha in _visual_perto.find_children("*", "MeshInstance3D", true, false):
		(malha as MeshInstance3D).visibility_range_end = DISTANCIA_LOD_M

	_visual_longe = _montar_visual_distante()
	add_child(_visual_longe)
	for malha in _visual_longe.find_children("*", "MeshInstance3D", true, false):
		(malha as MeshInstance3D).visibility_range_begin = DISTANCIA_LOD_M


func _montar_visual_detalhado() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "VisualDetalhado"
	var modelo := MODELO_DETALHADO.instantiate() as Node3D
	raiz.add_child(modelo)
	_anim = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null or not _anim.has_animation("Andar"):
		push_warning("ArvoreGigante: gigante_arvore.glb sem animação 'Andar'; fica parada em pose.")
		return raiz
	_anim.get_animation("Andar").loop_mode = Animation.LOOP_LINEAR
	# O ciclo de "Andar" tem 2 passos (modelado a 24 fps); o ritmo do jogo é
	# INTERVALO_PASSO_S por passo, então a velocidade de reprodução casa um
	# ciclo completo (2 passos) com 2 * INTERVALO_PASSO_S.
	var duracao_ciclo := _anim.get_animation("Andar").length
	_anim.speed_scale = duracao_ciclo / (2.0 * INTERVALO_PASSO_S) if INTERVALO_PASSO_S > 0.0 else 1.0
	_anim.play("Andar")
	return raiz


## Silhueta barata para quando ela está longe: só 4 formas, mas já lendo
## como figura humanoide (pernas separadas + torso + copa), não um palito
## genérico (GTX 1050, pedido do Vitor).
func _montar_visual_distante() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "VisualDistante"
	var material := GeometriaLowPoly.material_toon(0.18, 2)
	var st := GeometriaLowPoly.nova()
	var y_quadril := ALTURA_PE_M + ALTURA_PERNA_M
	for lado: float in [-1.0, 1.0]:
		GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(RAIO_PERNA_M * 1.2, RAIO_PERNA_M, ALTURA_PERNA_M + ALTURA_PE_M, 5),
			Transform3D(Basis(), Vector3(lado * AFASTAMENTO_PERNAS_M, (ALTURA_PERNA_M + ALTURA_PE_M) / 2.0, 0.0)), COR_CASCA)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.cilindro(RAIO_TORSO_BASE_M, RAIO_TORSO_TOPO_M, ALTURA_TORSO_M + ALTURA_CABECA_M, 6),
		Transform3D(Basis(), Vector3.UP * (y_quadril + (ALTURA_TORSO_M + ALTURA_CABECA_M) / 2.0)), COR_CASCA)
	GeometriaLowPoly.anexar(st, GeometriaLowPoly.esfera(7.5, 6, 4),
		Transform3D(Basis(), Vector3.UP * (y_quadril + ALTURA_TORSO_M + ALTURA_CABECA_M + 1.0)), COR_COPA)
	var malha := MeshInstance3D.new()
	malha.mesh = GeometriaLowPoly.finalizar(st)
	malha.material_override = material
	malha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(malha)
	return raiz


func _physics_process(delta: float) -> void:
	if _distancia_total <= 0.0:
		return
	if _percorrido >= _distancia_total:
		queue_free()
		return

	_percorrido = minf(_distancia_total, _percorrido + VELOCIDADE_MS * delta)
	global_position = _origem.lerp(_destino, _percorrido / _distancia_total)

	_tempo_desde_passo += delta
	var fase_passo := fmod(_tempo_desde_passo, INTERVALO_PASSO_S) / INTERVALO_PASSO_S
	_animar_passo(fase_passo)
	if fmod(_tempo_desde_passo, INTERVALO_PASSO_S) < delta:
		_passo_pesado()

	if not _desaparecendo and _distancia_total - _percorrido <= DISTANCIA_DESAPARECER_M:
		_desaparecendo = true
		_comecar_a_desaparecer()


## A passada em si é a animação "Andar" do esqueleto (tocando no
## AnimationPlayer desde _montar_visual_detalhado); aqui só sobra o balanço
## leve do corpo inteiro, inclusive na silhueta distante, que não tem
## esqueleto.
func _animar_passo(fase: float) -> void:
	var balanco := sin(fase * TAU) * 0.02
	if _visual_perto:
		_visual_perto.rotation.z = balanco
	if _visual_longe:
		_visual_longe.rotation.z = balanco


## A cada passo, quem estiver perto sente um tremor de câmera (proporcional
## à distância) e ouve o rangido grave de madeira; bem longe, nenhum dos
## dois (pedido do Vitor).
func _passo_pesado() -> void:
	for mago in get_tree().get_nodes_in_group("mago"):
		if not is_instance_valid(mago) or not (mago is Node3D):
			continue
		var distancia := global_position.distance_to((mago as Node3D).global_position)
		if distancia > RAIO_PERCEPCAO_M:
			continue
		if mago.has_method("tremor_camera"):
			mago.tremor_camera((1.0 - distancia / RAIO_PERCEPCAO_M) * 0.35)
	GerenciadorSom.tocar_arvore(global_position)


## Encolhe e afunda devagar pelos últimos metros da rota, como se a neblina
## a estivesse engolindo, e para de empurrar enquanto isso acontece (pedido
## do Vitor: "surge e desaparece dentro da neblina"). Depois, o nó some de
## verdade quando `_physics_process` detecta que a rota terminou.
func _comecar_a_desaparecer() -> void:
	if _corpo:
		_corpo.collision_layer = 0
	var duracao := DISTANCIA_DESAPARECER_M / VELOCIDADE_MS
	var tween := create_tween()
	if _visual_perto:
		tween.parallel().tween_property(_visual_perto, "scale", Vector3.ZERO, duracao)
	if _visual_longe:
		tween.parallel().tween_property(_visual_longe, "scale", Vector3.ZERO, duracao)
	tween.parallel().tween_property(self, "position:y", position.y - 3.0, duracao)
