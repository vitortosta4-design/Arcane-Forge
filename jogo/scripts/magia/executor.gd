extends RefCounted
class_name Executor
## Lê uma ficha de magia já validada e monta a magia no mundo. Nunca decide
## se algo é permitido (isso é o Validador) nem executa código vindo de fora:
## só sabe instanciar os componentes previstos (proposta técnica, seção 3).

const CenaProjetil := preload("res://cenas/magias/projetil.tscn")
const CenaInvocacao := preload("res://cenas/magias/invocacao.tscn")


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
