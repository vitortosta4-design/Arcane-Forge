class_name GerenciadorEventosAmbientais
extends Node
## Sorteia os eventos ambientais raros (ADR-047) e decide quando e por onde
## cada um passa. Quem decide é sempre quem roda este nó (o host, regra de
## ouro da arquitetura, proposta técnica seção 2); hoje, jogando sozinho,
## "decidir" e "mostrar" são a mesma máquina. Quando o cooperativo chegar
## (Fase 3), esta classe continua sendo a única que sorteia e calcula a
## rota; só passa a precisar replicar o resultado para o outro jogador, em
## vez de cada PC sortear o seu.

## Janela da partida em que um evento pode começar a aparecer: nem logo na
## entrada (o jogador ainda está se situando) nem faltando pouco tempo para
## a expedição acabar. Ainda não existe um relógio de expedição no jogo
## (chega na Fase 4); até lá, esta janela é a aproximação decidida pelo
## Claude como gestor, sem pedido específico do Vitor.
const INICIO_MIN_S := 45.0
const INICIO_MAX_S := 9.0 * 60.0

## Onde a rota de um evento começa e termina, em relação ao ponto que ela
## cruza: fora da área de luta, dentro da neblina (pedido do Vitor).
const DISTANCIA_SURGIMENTO_M := 60.0
## Quanto a rota pode passar ao lado do ponto escolhido, em vez de bater
## exatamente nele (para não ficar sempre certinho demais).
const DESVIO_MAX_DO_CAMINHO_M := 7.0

var _clareira: Clareira
var _rng := RandomNumberGenerator.new()


## Chamado pela arena depois que a Clareira já existe, para a rota poder
## perguntar a altura do terreno (Clareira.altura_em).
func configurar(clareira: Clareira) -> void:
	_clareira = clareira
	_rng.randomize()
	_sortear_eventos_da_partida()


## Para cada evento cadastrado em EventosAmbientais.LISTA, sorteia se ele
## acontece nesta partida e, se sim, em que instante.
func _sortear_eventos_da_partida() -> void:
	for dados in EventosAmbientais.LISTA:
		if _rng.randf() > float(dados["chance_por_partida"]):
			continue
		var instante := _rng.randf_range(INICIO_MIN_S, INICIO_MAX_S)
		get_tree().create_timer(instante).timeout.connect(_disparar_evento.bind(dados))


func _disparar_evento(dados: Dictionary) -> void:
	var mundo := get_tree().current_scene
	if mundo == null:
		return
	var cena: PackedScene = load(dados["cena"])
	var instancia: Node3D = cena.instantiate()
	mundo.add_child(instancia)
	var rota := _calcular_rota()
	instancia.iniciar(rota[0], rota[1])


## Uma linha reta que atravessa, perto, um ponto que os jogadores
## provavelmente vão usar (na frente de um jogador, ou numa runa), com as
## duas pontas fora da área de luta, dentro da neblina.
func _calcular_rota() -> Array:
	var ponto_de_cruzamento := _escolher_ponto_de_cruzamento()
	var angulo := _rng.randf_range(0.0, TAU)
	var direcao := Vector2(cos(angulo), sin(angulo))
	var perpendicular := Vector2(-direcao.y, direcao.x)
	var desvio := _rng.randf_range(-DESVIO_MAX_DO_CAMINHO_M, DESVIO_MAX_DO_CAMINHO_M)
	var centro := ponto_de_cruzamento + perpendicular * desvio
	var origem_2d := centro - direcao * DISTANCIA_SURGIMENTO_M
	var destino_2d := centro + direcao * DISTANCIA_SURGIMENTO_M
	var origem := Vector3(origem_2d.x, 0.0, origem_2d.y)
	var destino := Vector3(destino_2d.x, 0.0, destino_2d.y)
	if _clareira != null:
		origem.y = _clareira.altura_em(origem.x, origem.z)
		destino.y = _clareira.altura_em(destino.x, destino.z)
	return [origem, destino]


func _escolher_ponto_de_cruzamento() -> Vector2:
	var candidatos: Array[Vector2] = []
	for mago in get_tree().get_nodes_in_group("mago"):
		if not is_instance_valid(mago) or not (mago is Node3D):
			continue
		var no3d := mago as Node3D
		var frente := -no3d.global_transform.basis.z
		var ponto_adiante := no3d.global_position + frente * _rng.randf_range(10.0, 25.0)
		candidatos.append(Vector2(ponto_adiante.x, ponto_adiante.z))
	for ponto in Clareira.PONTOS_RUNA:
		var p: Vector2 = ponto[1]
		candidatos.append(p)
	if candidatos.is_empty():
		return Vector2.ZERO
	return candidatos[_rng.randi() % candidatos.size()]
