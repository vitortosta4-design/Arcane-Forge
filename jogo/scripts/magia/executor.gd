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
	Host.registrar_projetil(projetil)
