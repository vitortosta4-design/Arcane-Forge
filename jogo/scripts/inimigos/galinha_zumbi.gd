extends CharacterBody3D
## Primeiro inimigo absurdo (ADR-019): persegue o mago mais próximo e bica.

const VELOCIDADE := 3.0
const GRAVIDADE := 9.8
const ALCANCE_ATAQUE := 1.2
const DANO_BICADA := 5.0
const INTERVALO_ATAQUE_S := 1.0

@export var vida := 30.0

var _vida_atual: float
## Segundos desde o último dano recebido. O HUD usa para mostrar a barra de
## vida só depois que alguém acerta a galinha (escolha 3b do Vitor).
var segundos_desde_dano := INF
## Altura da barra de vida acima dos pés.
const ALTURA_BARRA_VIDA := 1.0
var _cooldown_ataque := 0.0
var _morta := false
var estados := ControladorEstados.new()

@onready var _mesh: Node3D = $CorpoVisivel


func _ready() -> void:
	_vida_atual = vida
	add_to_group("recebe_dano")
	add_to_group("inimigo")
	add_child(estados)


func aplicar_estado(nome_estado: String, duracao_s: float) -> void:
	estados.aplicar(nome_estado, duracao_s)


func _physics_process(delta: float) -> void:
	segundos_desde_dano += delta
	if _morta:
		return

	_cooldown_ataque = maxf(0.0, _cooldown_ataque - delta)

	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	else:
		velocity.y = 0.0

	var alvo := _encontrar_mago_mais_proximo()
	# Cego não acha ninguém: fica parado, sem perseguir nem atacar.
	if estados.esta_cego():
		alvo = null
	if alvo == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var distancia := global_position.distance_to(alvo.global_position)
	if distancia <= ALCANCE_ATAQUE:
		velocity.x = 0.0
		velocity.z = 0.0
		if _cooldown_ataque <= 0.0:
			_cooldown_ataque = INTERVALO_ATAQUE_S
			GerenciadorSom.tocar_galinha(global_position)
			Host.aplicar_dano(alvo, DANO_BICADA, global_position, 1.0)
	else:
		var direcao := (alvo.global_position - global_position)
		direcao.y = 0.0
		direcao = direcao.normalized()
		velocity.x = direcao.x * VELOCIDADE * estados.multiplicador_velocidade()
		velocity.z = direcao.z * VELOCIDADE * estados.multiplicador_velocidade()
		look_at(global_position + direcao, Vector3.UP)

	move_and_slide()


func _encontrar_mago_mais_proximo() -> Node3D:
	var magos := get_tree().get_nodes_in_group("mago")
	var mais_proximo: Node3D = null
	var menor_distancia := INF
	for mago in magos:
		if not is_instance_valid(mago):
			continue
		var distancia := global_position.distance_to(mago.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			mais_proximo = mago
	return mais_proximo


func receber_dano(dano: float, origem_dano: Vector3, empurrao: float) -> void:
	if _morta:
		return
	_vida_atual -= dano
	segundos_desde_dano = 0.0
	if empurrao != 0.0:
		var direcao := (global_position - origem_dano).normalized()
		velocity += direcao * empurrao
	if _vida_atual <= 0.0:
		_morrer()


## Fração da vida que sobra (0 a 1), só para leitura do HUD.
func fracao_vida() -> float:
	return clampf(_vida_atual / vida, 0.0, 1.0) if vida > 0.0 and not _morta else 0.0


func _morrer() -> void:
	_morta = true
	remove_from_group("recebe_dano")
	var tween := create_tween()
	tween.tween_property(_mesh, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)
