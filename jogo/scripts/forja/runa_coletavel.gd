class_name RunaColetavel
extends Area3D
## Runa solta no mapa (Fase 2, ADR-035): flutua girando devagar, com a luz
## da cor do elemento, e vai para o inventário de quem encostar nela.
## Quem decide se a coleta vale é o Host (juiz), mesmo jogando sozinho, para
## o cooperativo da Fase 3 já nascer certo ("quem pega leva").
## Modelo: runas_acesas.glb do piloto de modelagem (lote 3c, v3).

const CenaRunas := preload("res://assets/modelos/forja/runas_acesas.glb")
const CenaPuf := preload("res://cenas/efeitos/explosao_visual.tscn")
const ALTURA_M := 1.0
const ESCALA_MODELO := 2.2

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
	var todas := CenaRunas.instantiate()
	var original := todas.get_node_or_null("Runa_%s_acesa" % nome_runa)
	_visual = Node3D.new()
	_visual.name = "Visual"
	_visual.position.y = ALTURA_M
	add_child(_visual)
	if original:
		todas.remove_child(original)
		original.position = Vector3.ZERO
		original.scale = Vector3.ONE * ESCALA_MODELO
		_visual.add_child(original)
		# O Blender exporta a luz em watts e no Godot ela estoura a imagem;
		# a intensidade é decidida aqui (mesmo cuidado da bigorna).
		for luz in original.find_children("*", "OmniLight3D", true, false):
			(luz as OmniLight3D).light_energy = 2.5
			(luz as OmniLight3D).omni_range = 3.0
			(luz as OmniLight3D).shadow_enabled = false
	todas.queue_free()
	# Brilho no chão embaixo, para achar a runa de longe.
	var marca := MeshInstance3D.new()
	marca.name = "Marca"
	var disco := CylinderMesh.new()
	disco.top_radius = 0.55
	disco.bottom_radius = 0.55
	disco.height = 0.02
	marca.mesh = disco
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var cor := Color(LivroDeReceitas.runa(nome_runa).get("cor", "#ffffff"))
	mat.albedo_color = Color(cor.r, cor.g, cor.b, 0.45)
	mat.emission_enabled = true
	mat.emission = cor
	mat.emission_energy_multiplier = 1.5
	marca.material_override = mat
	marca.position.y = 0.03
	marca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marca)
	# Feixe de luz subindo, para enxergar a runa do outro lado da clareira
	# (achado no primeiro print: de longe ela sumia na grama).
	var feixe := MeshInstance3D.new()
	feixe.name = "Feixe"
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.02
	cilindro.bottom_radius = 0.12
	cilindro.height = 5.0
	cilindro.cap_top = false
	cilindro.cap_bottom = false
	feixe.mesh = cilindro
	var mat_feixe := mat.duplicate() as StandardMaterial3D
	mat_feixe.albedo_color = Color(cor.r, cor.g, cor.b, 0.35)
	mat_feixe.cull_mode = BaseMaterial3D.CULL_DISABLED
	feixe.material_override = mat_feixe
	feixe.position.y = ALTURA_M + 3.6
	feixe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(feixe)


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
	get_node("Feixe").visible = false
	get_node("Marca").visible = false
	var t := create_tween()
	t.tween_property(_visual, "scale", Vector3.ONE * 0.01, 0.25)
	t.tween_callback(queue_free)
