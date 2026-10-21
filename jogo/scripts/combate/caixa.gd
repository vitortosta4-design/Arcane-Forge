extends RigidBody3D
## Caixa quebrável. Entra no grupo "recebe_dano" para o Host conseguir
## encontrá-la quando uma explosão acontece perto.

@export var vida := 15.0

var _vida_atual: float


func _ready() -> void:
	_vida_atual = vida
	add_to_group("recebe_dano")


func receber_dano(dano: float, origem_dano: Vector3, empurrao: float) -> void:
	_vida_atual -= dano
	if empurrao != 0.0:
		var direcao := (global_position - origem_dano).normalized()
		apply_central_impulse(direcao * empurrao)
	if _vida_atual <= 0.0:
		_quebrar()


func _quebrar() -> void:
	queue_free()
