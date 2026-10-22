class_name RunaColetavel
extends Area3D
## Runa solta no chão (Fase 2, ADR-035): flutua de frente para quem olha,
## com a luz da cor do elemento, e vai para o inventário de quem encostar.
## No mapa as runas ficam dentro de baús (pedido do Vitor, 22/10/2026); a
## runa solta fica para quando um jogador largar uma para o parceiro (Fase 3).
## Quem decide se a coleta vale é o Host (juiz), mesmo jogando sozinho, para
## o cooperativo da Fase 3 já nascer certo ("quem pega leva").
## Modelo: runas_acesas.glb do piloto de modelagem (lote 3c, v3).

const CenaRunas := preload("res://assets/modelos/forja/runas_acesas.glb")
const CenaPuf := preload("res://cenas/efeitos/explosao_visual.tscn")
const ALTURA_M := 1.0
const ESCALA_MODELO := 1.8

@export var nome_runa := "fogo"

var coletada := false
var _visual: Node3D
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # só o mago
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.0
	forma.shape = esfera
	forma.position.y = ALTURA_M
	add_child(forma)
	_tempo = fmod(global_position.x * 0.37 + global_position.z * 0.53, TAU)
	_montar_visual()
	body_entered.connect(_ao_encostar)


func _montar_visual() -> void:
	_visual = RunaColetavel.criar_visual(nome_runa)
	_visual.position.y = ALTURA_M
	add_child(_visual)


## Só o modelo aceso da runa, com a luz própria já domada. Usado pela runa
## solta no chão e pela runa que sai do baú.
static func criar_visual(nome: String) -> Node3D:
	var todas := CenaRunas.instantiate()
	var original := todas.get_node_or_null("Runa_%s_acesa" % nome)
	var visual := Node3D.new()
	visual.name = "Visual"
	if original:
		todas.remove_child(original)
		original.position = Vector3.ZERO
		original.scale = Vector3.ONE * ESCALA_MODELO
		visual.add_child(original)
		# O Blender exporta a luz em watts e no Godot ela estoura a imagem;
		# a intensidade é decidida aqui (mesmo cuidado da bigorna).
		for luz in original.find_children("*", "OmniLight3D", true, false):
			(luz as OmniLight3D).light_energy = 1.2
			(luz as OmniLight3D).omni_range = 2.5
			(luz as OmniLight3D).shadow_enabled = false
	todas.queue_free()
	return visual


func _process(delta: float) -> void:
	if coletada:
		return
	_tempo += delta
	# De frente para quem olha (o símbolo só existe na face da frente; girando
	# sem parar, metade do tempo aparecia a costa lisa), balançando de leve.
	var camera := get_viewport().get_camera_3d()
	if camera:
		var para_camera := camera.global_position - _visual.global_position
		_visual.rotation.y = atan2(para_camera.x, para_camera.z) + sin(_tempo * 1.3) * 0.35
	_visual.position.y = ALTURA_M + sin(_tempo * 2.0) * 0.12


func _ao_encostar(corpo: Node) -> void:
	if corpo.is_in_group("mago"):
		Host.coletar_runa(corpo, self)


## Chamado pelo Host quando a coleta valeu.
func ao_ser_coletada() -> void:
	coletada = true
	set_deferred("monitoring", false)
	var puf := CenaPuf.instantiate()
	get_parent().add_child(puf)
	puf.global_position = _visual.global_position
	puf.iniciar(0.7, LivroDeReceitas.runa(nome_runa).get("material", "agua"))
	var t := create_tween()
	t.tween_property(_visual, "scale", Vector3.ONE * 0.01, 0.25)
	t.tween_callback(queue_free)
