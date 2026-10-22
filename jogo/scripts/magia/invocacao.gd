extends CharacterBody3D
## Criatura invocada (proposta técnica, seção 3: "invocação"). Confiada ao
## Executor/Validador: só sabe perseguir o inimigo mais próximo e bater nele,
## sem decidir sozinha quanto de dano causa nem quanto tempo vive — isso vem
## sempre da ficha já validada.

const GRAVIDADE := 9.8
const ALCANCE_ATAQUE := 1.0
const VELOCIDADE := 3.0
const INTERVALO_ATAQUE_S := 1.0

var vida := 20.0
var dano_contato := 5.0
var duracao_s := 6.0
## Lançador (proposta técnica, seção 3, "Pombo de Pedra" que solta ovos):
## o Executor preenche quando a ficha tem um componente "lancador" anexado a
## esta criatura. Intervalo zero = sem lançador.
var lancador_projetil: Dictionary = {}
var lancador_intervalo_s := 0.0
var invocador: Node = null
var estados := ControladorEstados.new()

var _vida_atual: float
var _cooldown_ataque := 0.0
var _tempo_ate_disparo := 0.0
var _morta := false

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	_vida_atual = vida
	if _vida_atual <= 0.0:
		_morrer()
		return
	add_to_group("recebe_dano")
	add_to_group("criatura_invocada")
	add_child(estados)
	get_tree().create_timer(maxf(duracao_s, 0.01)).timeout.connect(_expirar)


func aplicar_estado(nome_estado: String, duracao_s_estado: float) -> void:
	estados.aplicar(nome_estado, duracao_s_estado)


## Ligado pelo Executor depois de criar a criatura. O primeiro disparo
## espera um intervalo inteiro, para o ovo não sair grudado no mago.
func anexar_lancador(projetil: Dictionary, intervalo_s: float) -> void:
	lancador_projetil = projetil
	lancador_intervalo_s = intervalo_s
	_tempo_ate_disparo = intervalo_s


## O Executor chama isto para a criatura ficar com a cor do material da
## ficha (ADR-007), igual ao projétil.
func definir_material(nome: String) -> void:
	var cor := Validador.cor_para_material(nome)
	var mat := (_mesh.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	mat.albedo_color = cor
	mat.emission = cor
	_mesh.set_surface_override_material(0, mat)


## Troca a bola provisória pelo corpo da ficha (CorposInvocacao).
func definir_corpo(corpo: String, material: String) -> void:
	_mesh.visible = false
	var visual := CorposInvocacao.criar(corpo, Validador.cor_para_material(material), material)
	visual.name = "Corpo"
	add_child(visual)


func _physics_process(delta: float) -> void:
	if _morta:
		return

	_cooldown_ataque = maxf(0.0, _cooldown_ataque - delta)

	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	else:
		velocity.y = 0.0

	var alvo := _encontrar_inimigo_mais_proximo()
	# Cego não acha ninguém: fica parado, sem perseguir nem atacar.
	if estados.esta_cego():
		alvo = null
	if alvo == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	_talvez_disparar(alvo, delta)

	var distancia := global_position.distance_to(alvo.global_position)
	if distancia <= ALCANCE_ATAQUE:
		velocity.x = 0.0
		velocity.z = 0.0
		if _cooldown_ataque <= 0.0:
			_cooldown_ataque = INTERVALO_ATAQUE_S
			Host.aplicar_dano(alvo, dano_contato, global_position, 1.0)
	else:
		var direcao := (alvo.global_position - global_position)
		direcao.y = 0.0
		direcao = direcao.normalized()
		velocity.x = direcao.x * VELOCIDADE * estados.multiplicador_velocidade()
		velocity.z = direcao.z * VELOCIDADE * estados.multiplicador_velocidade()
		look_at(global_position + direcao, Vector3.UP)

	move_and_slide()


func _talvez_disparar(alvo: Node3D, delta: float) -> void:
	if lancador_intervalo_s <= 0.0:
		return
	_tempo_ate_disparo -= delta
	if _tempo_ate_disparo > 0.0:
		return
	_tempo_ate_disparo = lancador_intervalo_s
	var origem := global_position + Vector3.UP * 0.8
	var direcao := (alvo.global_position + Vector3.UP * 0.3 - origem).normalized()
	var aliados := [invocador] if is_instance_valid(invocador) else []
	Executor.criar_projetil(lancador_projetil, origem, direcao, self, get_parent(), aliados)


## Comportamento "perseguir_inimigo_proximo" (único implementado por
## enquanto, ver Validador.COMPORTAMENTOS_VALIDOS): mesma lógica da galinha
## zumbi, só que mirando no grupo "inimigo" em vez de "mago".
func _encontrar_inimigo_mais_proximo() -> Node3D:
	var inimigos := get_tree().get_nodes_in_group("inimigo")
	var mais_proximo: Node3D = null
	var menor_distancia := INF
	for inimigo in inimigos:
		if not is_instance_valid(inimigo):
			continue
		var distancia := global_position.distance_to(inimigo.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			mais_proximo = inimigo
	return mais_proximo


func receber_dano(dano: float, origem_dano: Vector3, empurrao: float) -> void:
	if _morta:
		return
	_vida_atual -= dano
	if empurrao != 0.0:
		var direcao := (global_position - origem_dano).normalized()
		velocity += direcao * empurrao
	if _vida_atual <= 0.0:
		_morrer()


func _expirar() -> void:
	if not _morta:
		_morrer()


func _morrer() -> void:
	_morta = true
	remove_from_group("recebe_dano")
	queue_free()
