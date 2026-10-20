extends Node
## O "juiz" da partida (ADR-004). Toda decisão de dano, mana e criação de
## entidades passa por aqui, mesmo jogando sozinho, para a Fase 5 (multiplayer
## real) não exigir reescrever o combate.

const LIMITE_PROJETEIS_ATIVOS := 40
const LIMITE_CRIATURAS_INVOCADAS := 6
const CenaEfeitoExplosao := preload("res://cenas/efeitos/explosao_visual.tscn")

var projeteis_ativos: Array[Node] = []
var criaturas_invocadas: Array[Node] = []


func aplicar_dano(entidade: Node, dano: float, origem_dano: Vector3 = Vector3.ZERO, empurrao: float = 0.0) -> void:
	if not is_instance_valid(entidade):
		return
	if entidade.has_method("receber_dano"):
		entidade.receber_dano(dano, origem_dano, empurrao)


func criar_explosao(pos: Vector3, raio_m: float, dano: float, empurrao: float, etiquetas: Array, excluir: Array = [], material: String = "fogo") -> void:
	var mundo := get_tree().current_scene
	if mundo == null:
		return

	var efeito := CenaEfeitoExplosao.instantiate()
	mundo.add_child(efeito)
	efeito.global_position = pos
	efeito.iniciar(raio_m, material)

	var alvos := get_tree().get_nodes_in_group("recebe_dano")
	for alvo in alvos:
		if alvo in excluir:
			continue
		if not is_instance_valid(alvo) or not (alvo is Node3D):
			continue
		var alvo3d := alvo as Node3D
		var distancia: float = alvo3d.global_position.distance_to(pos)
		if distancia <= raio_m:
			aplicar_dano(alvo3d, dano, pos, empurrao)
	if "fogo" in etiquetas:
		var inflamaveis := get_tree().get_nodes_in_group("inflamavel")
		for obj in inflamaveis:
			if not is_instance_valid(obj) or not (obj is Node3D):
				continue
			var obj3d := obj as Node3D
			if obj3d.global_position.distance_to(pos) <= raio_m and obj3d.has_method("pegar_fogo"):
				obj3d.pegar_fogo()


func gastar_mana(mago: Node, custo: float) -> bool:
	if not is_instance_valid(mago):
		return false
	return mago.gastar_mana(custo)


func pode_criar_projetil() -> bool:
	projeteis_ativos = projeteis_ativos.filter(func(p): return is_instance_valid(p))
	return projeteis_ativos.size() < LIMITE_PROJETEIS_ATIVOS


func registrar_projetil(p: Node) -> void:
	projeteis_ativos.append(p)


func pode_invocar_criatura() -> bool:
	criaturas_invocadas = criaturas_invocadas.filter(func(c): return is_instance_valid(c))
	return criaturas_invocadas.size() < LIMITE_CRIATURAS_INVOCADAS


func registrar_criatura(c: Node) -> void:
	criaturas_invocadas.append(c)
