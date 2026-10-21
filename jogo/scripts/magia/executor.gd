extends RefCounted
class_name Executor
## Lê uma ficha de magia já validada e monta a magia no mundo. Nunca decide
## se algo é permitido (isso é o Validador) nem executa código vindo de fora:
## só sabe instanciar os componentes previstos (proposta técnica, seção 3).

const CenaProjetil := preload("res://cenas/magias/projetil.tscn")
const CenaInvocacao := preload("res://cenas/magias/invocacao.tscn")
const CenaArea := preload("res://cenas/magias/area_persistente.tscn")


static func executar_ficha(ficha: Dictionary, origem: Vector3, direcao: Vector3, dono: Node, mundo: Node) -> void:
	var ficha_validada := Validador.validar_ficha(ficha)
	var criaturas_por_id := {}
	var ultima_criatura: Node = null
	for componente in ficha_validada.get("componentes", []):
		match componente.get("tipo"):
			"projetil":
				criar_projetil(componente, origem, direcao, dono, mundo)
			"cura":
				_aplicar_cura(componente, dono)
			"escudo":
				_aplicar_escudo(componente, dono)
			"area":
				# No topo da ficha, a área nasce aos pés de quem conjurou
				# (ex.: "um círculo de fogo ao meu redor").
				if dono is Node3D:
					criar_area(componente, ponto_no_chao(dono, (dono as Node3D).global_position), dono, [], mundo)
				else:
					criar_area(componente, origem, dono, [], mundo)
			"invocacao":
				var criatura := _criar_invocacao(componente, origem, dono, mundo)
				if criatura:
					ultima_criatura = criatura
					if componente.has("id"):
						criaturas_por_id[componente["id"]] = criatura
	# Lançadores numa segunda volta: a ficha pode listar o lançador antes da
	# criatura a que ele está anexado.
	for componente in ficha_validada.get("componentes", []):
		if componente.get("tipo") == "lancador":
			var alvo: Node = criaturas_por_id.get(componente.get("anexado_a", ""), ultima_criatura)
			if alvo and alvo.has_method("anexar_lancador"):
				alvo.anexar_lancador(componente["projetil"], componente["intervalo_s"])


static func criar_projetil(componente: Dictionary, origem: Vector3, direcao: Vector3, dono: Node, mundo: Node, aliados: Array = []) -> void:
	if not Host.pode_criar_projetil():
		return
	var projetil := CenaProjetil.instantiate()
	mundo.add_child(projetil)
	projetil.global_position = origem
	projetil.look_at(origem + direcao, Vector3.UP)
	projetil.velocidade = componente.get("velocidade", 10.0)
	projetil.ao_impactar = componente.get("ao_impactar", [])
	projetil.dono = dono
	projetil.aliados = aliados
	projetil.definir_material(componente.get("material", "fogo"))
	projetil.definir_forma(componente.get("forma", "esfera"))
	Host.registrar_projetil(projetil)


## Área persistente (proposta técnica, seção 3). Respeita o limite de 3
## magias ativas por jogador (seção 5). Nunca afeta quem a criou nem os
## aliados dele.
static func criar_area(componente: Dictionary, posicao: Vector3, dono: Node, aliados: Array, mundo: Node) -> Node:
	if not Host.pode_criar_area(dono):
		return null
	var area := CenaArea.instantiate()
	area.raio_m = componente.get("raio_m", 2.0)
	area.duracao_s = componente.get("duracao_s", 4.0)
	area.dano_por_s = componente.get("dano_por_s", 0.0)
	area.nome_estado = componente.get("nome_estado", "")
	area.material_nome = componente.get("material", "pedra")
	area.dono = dono
	area.excluir = ([dono] if dono else []) + aliados
	mundo.add_child(area)
	area.global_position = posicao
	Host.registrar_area(area)
	return area


## Ponto no chão logo abaixo de "ponto" (até 10 m): a área nasce no chão
## mesmo se o mago estiver no meio de um pulo ou o projétil bater no alto de
## uma caixa. Sem chão embaixo, fica onde está.
static func ponto_no_chao(referencia: Node3D, ponto: Vector3) -> Vector3:
	var consulta := PhysicsRayQueryParameters3D.create(ponto + Vector3.UP * 0.2, ponto + Vector3.DOWN * 10.0, 1)
	var resultado := referencia.get_world_3d().direct_space_state.intersect_ray(consulta)
	return resultado["position"] if resultado else ponto


## Cura (proposta técnica, seção 3): efeito direto em quem conjurou, sem
## projétil nem alvo. Se "dono" não souber se curar (ex.: chamado direto num
## teste sem um mago de verdade), não faz nada em vez de quebrar.
static func _aplicar_cura(componente: Dictionary, dono: Node) -> void:
	if dono and dono.has_method("curar"):
		dono.curar(componente.get("quantidade", 0.0))


## Escudo (proposta técnica, seção 3): reduz o dano recebido por quem
## conjurou, por um tempo, igual à cura não precisa de projétil.
static func _aplicar_escudo(componente: Dictionary, dono: Node) -> void:
	if dono and dono.has_method("aplicar_escudo"):
		dono.aplicar_escudo(componente.get("reducao", 0.0), componente.get("duracao_s", 0.0))


## Invocação (proposta técnica, seção 3, exemplo do "Pombo de Pedra"):
## respeita o limite de criaturas no mapa (ADR-004).
static func _criar_invocacao(componente: Dictionary, origem: Vector3, invocador: Node, mundo: Node) -> Node:
	if not Host.pode_invocar_criatura():
		return null
	var criatura := CenaInvocacao.instantiate()
	criatura.invocador = invocador
	# Precisa ser antes do add_child: _ready() da criatura já lê vida e
	# duracao_s para começar o timer de expirar e a vida atual. Lido depois,
	# a ficha seria ignorada e a criatura nasceria sempre com os padrões.
	criatura.vida = componente.get("vida", 10.0)
	criatura.dano_contato = componente.get("dano_contato", 0.0)
	criatura.duracao_s = componente.get("duracao_s", 6.0)
	mundo.add_child(criatura)
	criatura.global_position = origem
	criatura.scale = Vector3.ONE * componente.get("escala", 1.0)
	criatura.definir_material(componente.get("material", "pedra"))
	Host.registrar_criatura(criatura)
	return criatura
