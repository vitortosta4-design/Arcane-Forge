class_name BauDeRuna
extends StaticBody3D
## Baú com uma runa dentro (pedido do Vitor em 22/10/2026: nada de runa
## flutuando com feixe de luz gritando "estou aqui"). O baú é discreto: só um
## brilho fraco escapando pela fresta da tampa, na cor da runa, e um som
## mágico baixinho em volta, que se ouve chegando perto (como o baú do
## Fortnite). Perto dele, "[E] Abrir baú": a tampa abre, a runa sobe de
## dentro e voa para o mago. Quem decide se abriu é o Host (juiz).
## Visual provisório feito em código; o definitivo é da Fase 5.

const SomBrilho := preload("res://assets/som/bau_brilho.wav")
const SomAbrir := preload("res://assets/som/bau_abrir.wav")
const COR_MADEIRA := Color(0.5, 0.32, 0.17)
const COR_MADEIRA_ESCURA := Color(0.36, 0.22, 0.12)
const COR_METAL := Color(0.35, 0.34, 0.36)
const COR_DOURADO := Color(0.95, 0.72, 0.25)
const ALCANCE_M := 2.2
const TEXTO_INTERACAO := "Abrir baú"

@export var nome_runa := "fogo"

var aberto := false
var _tampa: Node3D
var _luz: OmniLight3D
var _som: AudioStreamPlayer3D
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(0.92, 0.72, 0.6)
	forma.shape = caixa
	forma.position.y = 0.36
	add_child(forma)
	_montar_visual()

	var cor := Color(LivroDeReceitas.runa(nome_runa).get("cor", "#ffffff"))
	_luz = OmniLight3D.new()
	_luz.name = "LuzFresta"
	_luz.light_color = cor
	_luz.light_energy = 0.35
	_luz.omni_range = 1.4
	_luz.position = Vector3(0, 0.5, -0.15)
	add_child(_luz)

	_som = AudioStreamPlayer3D.new()
	_som.name = "SomBrilho"
	_som.stream = SomBrilho
	_som.bus = "Efeitos"
	_som.volume_db = -8.0
	_som.unit_size = 1.5
	_som.max_distance = 14.0
	_som.position.y = 0.4
	add_child(_som)
	_som.finished.connect(func(): if not aberto: _som.play())
	_som.play()

	var alcance := Area3D.new()
	alcance.name = "Alcance"
	alcance.collision_layer = 0
	alcance.collision_mask = 2
	var esfera := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = ALCANCE_M
	esfera.shape = s
	alcance.add_child(esfera)
	add_child(alcance)
	alcance.body_entered.connect(_ao_chegar)
	alcance.body_exited.connect(_ao_sair)
	_tempo = fmod(global_position.x + global_position.z, TAU)


func _process(delta: float) -> void:
	if aberto:
		return
	_tempo += delta
	_luz.light_energy = 0.3 + sin(_tempo * 1.7) * 0.08


func _ao_chegar(corpo: Node) -> void:
	if not aberto and corpo.has_method("definir_interacao"):
		corpo.definir_interacao(self, TEXTO_INTERACAO)


func _ao_sair(corpo: Node) -> void:
	if corpo.has_method("limpar_interacao"):
		corpo.limpar_interacao(self)


## O mago apertou E perto deste baú.
func interagir(mago: Node) -> void:
	Host.abrir_bau(mago, self)


## Chamado pelo Host quando a abertura valeu: só a parte visual e sonora.
func abrir(mago: Node3D) -> void:
	aberto = true
	_som.stop()
	GerenciadorSom.tocar(SomAbrir, global_position + Vector3.UP * 0.5, "Efeitos", 0.03)
	var t := create_tween()
	t.tween_property(_tampa, "rotation:x", deg_to_rad(105), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var luz := create_tween()
	luz.tween_property(_luz, "light_energy", 2.0, 0.2)
	luz.tween_property(_luz, "light_energy", 0.0, 1.2)
	_runa_saindo(mago)


## A runa sobe de dentro do baú, para um instante girando e voa até o mago.
func _runa_saindo(mago: Node3D) -> void:
	var runa := RunaColetavel.criar_visual(nome_runa)
	add_child(runa)
	runa.position = Vector3(0, 0.3, 0)
	runa.scale = Vector3.ONE * 0.3
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(runa, "position:y", 1.3, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(runa, "scale", Vector3.ONE, 0.5)
	t.tween_property(runa, "rotation:y", TAU, 0.9)
	t.set_parallel(false)
	t.tween_interval(0.35)
	t.tween_method(func(p: float):
		if is_instance_valid(mago):
			var alvo := mago.global_position + Vector3.UP * 1.3
			runa.global_position = runa.global_position.lerp(alvo, p)
			runa.scale = Vector3.ONE * (1.0 - p * 0.85), 0.0, 1.0, 0.35)
	t.tween_callback(runa.queue_free)


func _montar_visual() -> void:
	var G := GeometriaLowPoly
	var material := G.material_toon(0.2, 3)
	var st := G.nova()
	G.anexar(st, G.cubo(Vector3(0.9, 0.45, 0.56)), Transform3D(Basis(), Vector3(0, 0.225, 0)), COR_MADEIRA)
	for x in [-0.3, 0.3]:
		G.anexar(st, G.cubo(Vector3(0.07, 0.47, 0.58)), Transform3D(Basis(), Vector3(x, 0.225, 0)), COR_METAL)
	G.anexar(st, G.cubo(Vector3(0.92, 0.05, 0.58)), Transform3D(Basis(), Vector3(0, 0.025, 0)), COR_MADEIRA_ESCURA)
	G.anexar(st, G.cubo(Vector3(0.13, 0.17, 0.05)), Transform3D(Basis(), Vector3(0, 0.4, -0.29)), COR_DOURADO)
	var corpo := MeshInstance3D.new()
	corpo.name = "Corpo"
	corpo.mesh = G.finalizar(st)
	corpo.material_override = material
	add_child(corpo)

	# Tampa presa na quina de trás de cima: gira para trás ao abrir.
	_tampa = Node3D.new()
	_tampa.name = "Tampa"
	_tampa.position = Vector3(0, 0.45, 0.28)
	add_child(_tampa)
	var tampa := G.nova()
	G.anexar(tampa, G.cubo(Vector3(0.92, 0.1, 0.58)), Transform3D(Basis(), Vector3(0, 0.05, -0.28)), COR_MADEIRA)
	G.anexar(tampa, G.cilindro(0.29, 0.29, 0.92, 8),
		Transform3D(Basis(Vector3(0, 0, 1), PI / 2.0).scaled(Vector3(1.0, 0.45, 1.0)), Vector3(0, 0.1, -0.28)), COR_MADEIRA)
	for x in [-0.3, 0.3]:
		G.anexar(tampa, G.cilindro(0.3, 0.3, 0.07, 8),
			Transform3D(Basis(Vector3(0, 0, 1), PI / 2.0).scaled(Vector3(1.0, 0.47, 1.0)), Vector3(x, 0.1, -0.28)), COR_METAL)
	var malha_tampa := MeshInstance3D.new()
	malha_tampa.mesh = G.finalizar(tampa)
	malha_tampa.material_override = material
	_tampa.add_child(malha_tampa)
