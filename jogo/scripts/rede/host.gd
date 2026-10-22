extends Node
## O "juiz" da partida (ADR-004). Toda decisão de dano, mana e criação de
## entidades passa por aqui, mesmo jogando sozinho, para a Fase 5 (multiplayer
## real) não exigir reescrever o combate.

const LIMITE_PROJETEIS_ATIVOS := 40
const LIMITE_CRIATURAS_INVOCADAS := 6
const LIMITE_MAGIAS_ATIVAS_POR_DONO := 3
## Até onde o mago pode estar da runa para a coleta valer (proteção para o
## cooperativo: o convidado não pega runa do outro lado do mapa).
const DISTANCIA_COLETA_RUNA_M := 2.5
const DISTANCIA_ABRIR_BAU_M := 3.0
const CenaEfeitoExplosao := preload("res://cenas/efeitos/explosao_visual.tscn")

var projeteis_ativos: Array[Node] = []
var criaturas_invocadas: Array[Node] = []
var magias_ativas: Array[Node] = []


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
	GerenciadorSom.tocar_explosao(pos)

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


## Eletricidade em algo molhado se espalha num raio (proposta técnica,
## seção 3). Só um salto: quem recebe o choque espalhado não espalha de novo,
## para não virar uma corrente infinita entre dois alvos molhados.
func espalhar_eletricidade(pos: Vector3, raio_m: float, dano: float, excluir: Array = []) -> void:
	for alvo in get_tree().get_nodes_in_group("recebe_dano"):
		if alvo in excluir or not is_instance_valid(alvo) or not (alvo is Node3D):
			continue
		if (alvo as Node3D).global_position.distance_to(pos) <= raio_m:
			aplicar_dano(alvo, dano, pos, 0.0)


## Um tick de área persistente: dano e/ou estado em quem estiver dentro do
## disco (distância no plano do chão, com tolerância de altura). Área de
## fogo também acende o que for inflamável, igual à explosão com etiqueta
## "fogo" (interação por etiquetas, proposta técnica, seção 3).
func aplicar_area(pos: Vector3, raio_m: float, dano: float, nome_estado: String, duracao_estado_s: float, material: String, excluir: Array = []) -> void:
	for alvo in get_tree().get_nodes_in_group("recebe_dano"):
		if alvo in excluir or not is_instance_valid(alvo) or not (alvo is Node3D):
			continue
		if not _dentro_do_disco((alvo as Node3D).global_position, pos, raio_m):
			continue
		if dano > 0.0:
			aplicar_dano(alvo, dano, pos, 0.0)
		if nome_estado != "" and is_instance_valid(alvo) and alvo.has_method("aplicar_estado"):
			alvo.aplicar_estado(nome_estado, duracao_estado_s)
	if material == "fogo" or nome_estado == "queimando":
		for obj in get_tree().get_nodes_in_group("inflamavel"):
			if is_instance_valid(obj) and obj is Node3D and _dentro_do_disco(obj.global_position, pos, raio_m) and obj.has_method("pegar_fogo"):
				obj.pegar_fogo()


func _dentro_do_disco(ponto: Vector3, centro: Vector3, raio_m: float) -> bool:
	var plano := Vector2(ponto.x - centro.x, ponto.z - centro.z)
	return plano.length() <= raio_m and absf(ponto.y - centro.y) <= 2.0


## Proposta técnica, seção 5: no máximo 3 magias ativas por jogador. Vale
## para as magias que ficam no mundo por vários segundos e têm um dono
## (áreas persistentes e paredes). Projéteis e criaturas têm limites próprios.
func pode_criar_magia_ativa(dono: Node) -> bool:
	magias_ativas = magias_ativas.filter(func(m): return is_instance_valid(m))
	return magias_ativas.filter(func(m): return m.dono == dono).size() < LIMITE_MAGIAS_ATIVAS_POR_DONO


func registrar_magia_ativa(magia: Node) -> void:
	magias_ativas.append(magia)


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


## Coleta de runa (Fase 2, ADR-035). Quem pega leva; o juiz confere que a
## runa existe, ainda não foi pega, é de um tipo conhecido e está perto.
func coletar_runa(mago: Node, runa: Node) -> bool:
	if not is_instance_valid(runa) or not is_instance_valid(mago) or runa.coletada:
		return false
	if LivroDeReceitas.runa(runa.nome_runa).is_empty():
		return false
	if (mago as Node3D).global_position.distance_to((runa as Node3D).global_position) > DISTANCIA_COLETA_RUNA_M:
		return false
	mago.adicionar_runa(runa.nome_runa)
	runa.ao_ser_coletada()
	return true


## Abrir baú de runa (Fase 2): o juiz confere que o baú ainda está fechado,
## guarda uma runa conhecida e que o mago está perto. A runa vai direto
## para o inventário; o voo da runa até o mago é só visual.
func abrir_bau(mago: Node, bau: Node) -> bool:
	if not is_instance_valid(bau) or not is_instance_valid(mago) or bau.aberto:
		return false
	if LivroDeReceitas.runa(bau.nome_runa).is_empty():
		return false
	if (mago as Node3D).global_position.distance_to((bau as Node3D).global_position) > DISTANCIA_ABRIR_BAU_M:
		return false
	mago.adicionar_runa(bau.nome_runa)
	bau.abrir(mago)
	if mago.has_method("limpar_interacao"):
		mago.limpar_interacao(bau)
	return true
