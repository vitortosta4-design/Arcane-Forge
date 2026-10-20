extends Area3D
## Projétil genérico. Qualquer magia com um componente "tipo": "projetil"
## vira uma instância disto, parametrizada pelo Executor.

var velocidade := 10.0
var ao_impactar: Array = []
var dono: Node = null
var tempo_de_vida_s := 5.0

var _tempo_vivo := 0.0


func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * velocidade * delta
	_tempo_vivo += delta
	if _tempo_vivo >= tempo_de_vida_s:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == dono:
		return
	_explodir()


func _explodir() -> void:
	for efeito in ao_impactar:
		if efeito.get("tipo") == "explosao":
			Host.criar_explosao(
				global_position,
				efeito.get("raio_m", 2.0),
				efeito.get("dano", 5.0),
				efeito.get("empurrao", 0.0),
				efeito.get("etiquetas", []),
				[dono]
			)
	queue_free()
