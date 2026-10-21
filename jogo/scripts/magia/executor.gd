extends RefCounted
class_name Executor
## Lê uma ficha de magia já validada e monta a magia no mundo. Nunca decide
## se algo é permitido (isso é o Validador) nem executa código vindo de fora:
## só sabe instanciar os componentes previstos (proposta técnica, seção 3).

const CenaProjetil := preload("res://cenas/magias/projetil.tscn")


static func executar_ficha(ficha: Dictionary, origem: Vector3, direcao: Vector3, dono: Node, mundo: Node) -> void:
	var ficha_validada := Validador.validar_ficha(ficha)
	for componente in ficha_validada.get("componentes", []):
		if componente.get("tipo") == "projetil":
			_criar_projetil(componente, origem, direcao, dono, mundo)
		elif componente.get("tipo") == "cura":
			_aplicar_cura(componente, dono)
		elif componente.get("tipo") == "escudo":
			_aplicar_escudo(componente, dono)


static func _criar_projetil(componente: Dictionary, origem: Vector3, direcao: Vector3, dono: Node, mundo: Node) -> void:
	if not Host.pode_criar_projetil():
		return
	var projetil := CenaProjetil.instantiate()
	mundo.add_child(projetil)
	projetil.global_position = origem
	projetil.look_at(origem + direcao, Vector3.UP)
	projetil.velocidade = componente.get("velocidade", 10.0)
	projetil.ao_impactar = componente.get("ao_impactar", [])
	projetil.dono = dono
	projetil.definir_material(componente.get("material", "fogo"))
	projetil.definir_forma(componente.get("forma", "esfera"))
	Host.registrar_projetil(projetil)


## Cura (proposta técnica, seção 3): efeito direto em quem conjurou, sem
## projétil nem alvo, igual à bola de fogo não precisa de projétil para
## existir. Se "dono" não souber se curar (ex.: chamado direto num teste
## sem um mago de verdade), não faz nada em vez de quebrar.
static func _aplicar_cura(componente: Dictionary, dono: Node) -> void:
	if dono and dono.has_method("curar"):
		dono.curar(componente.get("quantidade", 0.0))


## Escudo (proposta técnica, seção 3): reduz o dano recebido por quem
## conjurou, por um tempo, igual à cura não precisa de projétil.
static func _aplicar_escudo(componente: Dictionary, dono: Node) -> void:
	if dono and dono.has_method("aplicar_escudo"):
		dono.aplicar_escudo(componente.get("reducao", 0.0), componente.get("duracao_s", 0.0))
