extends Node3D
## Feedback visual de uma explosão: uma esfera que cresce rápido e some.
## Sem isso a explosão causa dano de verdade mas o jogador não vê nada
## acontecer (achado ao testar a Fase 2 com o Vitor).

@export var duracao_s := 0.25

var raio_m := 2.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	_mesh.scale = Vector3.ONE * 0.05
	# Duplica o material: sem isso, explosões ao mesmo tempo compartilhariam o
	# mesmo recurso e uma roubaria o desaparecimento da outra.
	var material := (_mesh.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	_mesh.set_surface_override_material(0, material)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mesh, "scale", Vector3.ONE * raio_m, duracao_s)
	tween.tween_property(material, "albedo_color:a", 0.0, duracao_s)
	tween.finished.connect(queue_free)
