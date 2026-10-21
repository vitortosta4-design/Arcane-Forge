extends Area3D
## Projétil genérico. Qualquer magia com um componente "tipo": "projetil"
## vira uma instância disto, parametrizada pelo Executor.

var velocidade := 10.0
var ao_impactar: Array = []
var dono: Node = null
## Quem o projétil nunca atinge, nem no impacto nem na explosão: o dono e,
## no caso de uma criatura invocada, o mago que a invocou (achado testando o
## pombo bombardeiro: os ovos dele machucavam o próprio mago).
var aliados: Array = []
var tempo_de_vida_s := 5.0
var material := "fogo"

var _tempo_vivo := 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D


## O Executor chama isto logo depois de criar o projétil, para ele ficar
## com a cor do material da ficha em vez da cor fixa de fogo (ADR-007).
func definir_material(nome: String) -> void:
	material = nome
	var cor := Validador.cor_para_material(nome)
	var mat := (_mesh.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	mat.albedo_color = cor
	mat.emission = cor
	_mesh.set_surface_override_material(0, mat)


## O Executor chama isto para o projétil parecer com a "forma" da ficha
## (esfera, ovo ou cubo, ver Validador.FORMAS_VALIDAS), em vez de ser
## sempre uma bolinha não importa o que o jogador pediu.
func definir_forma(nome: String) -> void:
	_mesh.scale = Vector3.ONE
	match nome:
		"cubo":
			var malha := BoxMesh.new()
			malha.size = Vector3(0.32, 0.32, 0.32)
			_mesh.mesh = malha
		"ovo":
			# Sem malha de ovo pronta no Godot: alonga a esfera na direção
			# do voo, que já dá a silhueta de ovo (ADR-007, formas simples).
			_mesh.scale = Vector3(0.8, 0.8, 1.5)
		_:
			pass # esfera é a malha padrão da cena, nada a fazer


func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * velocidade * delta
	_tempo_vivo += delta
	if _tempo_vivo >= tempo_de_vida_s:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == dono or body in aliados:
		return
	_explodir(body)


func _explodir(alvo: Node) -> void:
	for efeito in ao_impactar:
		if efeito.get("tipo") == "explosao":
			Host.criar_explosao(
				global_position,
				efeito.get("raio_m", 2.0),
				efeito.get("dano", 5.0),
				efeito.get("empurrao", 0.0),
				efeito.get("etiquetas", []),
				[dono] + aliados,
				material
			)
		elif efeito.get("tipo") == "estado":
			_aplicar_estado(efeito, alvo)
	queue_free()


## Estados (proposta técnica, seção 3: queimando, molhado, eletrizado, cego,
## lento) são aplicados direto em quem o projétil atingiu, não numa área —
## diferente da explosão, que afeta todo mundo perto do ponto de impacto.
func _aplicar_estado(efeito: Dictionary, alvo: Node) -> void:
	if alvo and alvo.has_method("aplicar_estado"):
		alvo.aplicar_estado(efeito.get("nome_estado", ""), efeito.get("duracao_s", 0.0))
