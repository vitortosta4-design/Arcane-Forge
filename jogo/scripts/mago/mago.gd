extends CharacterBody3D
## O mago jogável. Movimento, mira, troca de câmera, vida, mana e a
## conjuração da bola de fogo (ADR-009, ADR-010, ADR-011).

const VELOCIDADE_ANDAR := 4.5
const FORCA_PULO := 4.5
const GRAVIDADE := 9.8
const SENSIBILIDADE_MOUSE := 0.0025
const LIMITE_OLHAR_CIMA_BAIXO := deg_to_rad(85)
const COOLDOWN_CONJURACAO_S := 0.5
const REGEN_MANA_POR_S := 5.0

@export var vida_maxima := 100.0
@export var mana_maxima := 100.0

var vida_atual := vida_maxima
var mana_atual := mana_maxima
var modo_camera_primeira_pessoa := true
## Até onde a mira procura o alvo, e o que ela enxerga (cenário, galinha,
## props). Sem alvo, mira num ponto a essa distância.
const ALCANCE_MIRA_M := 80.0
const MASCARA_MIRA := 1 | 4 | 16

var _cooldown_restante := 0.0
var _entrada_bloqueada := false
var _aguardando_interpretacao := false
var _reducao_escudo := 0.0
var estados := ControladorEstados.new()
## Runas que o mago carrega (Forja de Runas). Só o Host mexe aqui.
var runas: Array[String] = []
## Objeto perto com que o mago pode interagir (baú, bigorna...).
var _interacao: Node = null

@onready var _pivot_cabeca: Node3D = $PivotCabeca
@onready var _camera_primeira_pessoa: Camera3D = $PivotCabeca/CameraPrimeiraPessoa
@onready var _camera_terceira_pessoa: Camera3D = $PivotCabeca/BracoCameraTerceiraPessoa/CameraTerceiraPessoa
@onready var _mao: MaosPrimeiraPessoa = $PivotCabeca/CameraPrimeiraPessoa/Mao
@onready var _corpo_visivel: VisualMago = $CorpoVisivel

signal vida_mudou(atual: float, maxima: float)
signal mana_mudou(atual: float, maxima: float)
signal conjurou(legenda: String)
signal morreu
signal teleportou
signal runas_mudaram(runas: Array)
## Texto do que dá para fazer com E agora ("Abrir baú"); vazio quando nada.
signal interacao_mudou(texto: String)


func _ready() -> void:
	add_to_group("recebe_dano")
	add_to_group("mago")
	add_child(estados)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_primeira_pessoa.current = true
	_corpo_visivel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _entrada_bloqueada:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSIBILIDADE_MOUSE)
		_pivot_cabeca.rotate_x(-event.relative.y * SENSIBILIDADE_MOUSE)
		_pivot_cabeca.rotation.x = clampf(_pivot_cabeca.rotation.x, -LIMITE_OLHAR_CIMA_BAIXO, LIMITE_OLHAR_CIMA_BAIXO)
	elif event.is_action_pressed("interagir"):
		interagir()
	elif event.is_action_pressed("trocar_camera"):
		_trocar_camera()
	elif event.is_action_pressed("conjurar_bola_de_fogo"):
		_tentar_conjurar_bola_de_fogo()


func _physics_process(delta: float) -> void:
	_cooldown_restante = maxf(0.0, _cooldown_restante - delta)
	_regenerar_mana(delta)

	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	elif not _entrada_bloqueada and Input.is_action_just_pressed("pular"):
		velocity.y = FORCA_PULO

	if _entrada_bloqueada:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var entrada := Vector2(
			Input.get_action_strength("mover_direita") - Input.get_action_strength("mover_esquerda"),
			Input.get_action_strength("mover_tras") - Input.get_action_strength("mover_frente")
		)
		var direcao := (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()
		var velocidade := VELOCIDADE_ANDAR * _multiplicador_velocidade()
		velocity.x = direcao.x * velocidade
		velocity.z = direcao.z * velocidade

	move_and_slide()
	var velocidade_horizontal := Vector2(velocity.x, velocity.z).length()
	_corpo_visivel.animar(delta, velocidade_horizontal, is_on_floor())
	_mao.animar(delta, velocidade_horizontal, is_on_floor())


func _multiplicador_velocidade() -> float:
	return estados.multiplicador_velocidade()


## Chamado pela caixa de conjuração (ADR-010) enquanto o jogador digita,
## para não andar nem olhar em volta escrevendo ao mesmo tempo.
func definir_entrada_bloqueada(valor: bool) -> void:
	_entrada_bloqueada = valor


func _trocar_camera() -> void:
	modo_camera_primeira_pessoa = not modo_camera_primeira_pessoa
	_camera_primeira_pessoa.current = modo_camera_primeira_pessoa
	_camera_terceira_pessoa.current = not modo_camera_primeira_pessoa
	_corpo_visivel.visible = not modo_camera_primeira_pessoa
	_mao.visible = modo_camera_primeira_pessoa


func _camera_ativa() -> Camera3D:
	return _camera_primeira_pessoa if modo_camera_primeira_pessoa else _camera_terceira_pessoa


func _tentar_conjurar_bola_de_fogo() -> void:
	_conjurar_ficha(FichasPadrao.bola_de_fogo())


## Chamado pela caixa de conjuração (ADR-010) quando o jogador confirma uma
## frase. Primeiro tenta o porteiro de verdade (Supabase + Groq); se a IA
## estiver fora do ar, cai para o Interpretador local, que só reconhece
## algumas palavras-chave sem precisar de internet (ADR-002). Se nenhum
## dos dois entender, avisa o jogador.
func conjurar_por_texto(frase: String) -> void:
	if _cooldown_restante > 0.0 or _aguardando_interpretacao:
		return
	_aguardando_interpretacao = true
	var ficha := await Porteiro.interpretar(frase)
	if _ficha_sem_componentes(ficha):
		ficha = Interpretador.interpretar(frase)
	_aguardando_interpretacao = false
	if _ficha_sem_componentes(ficha):
		conjurou.emit("a magia está instável agora, use seu grimório")
		return
	_conjurar_ficha(ficha)


## A IA às vezes pode devolver uma ficha "educada" (com nome e legenda) mas
## sem nenhum componente de verdade, ou um componente "fantasma" com dano e
## empurrão zerados (aconteceu de verdade testando com o Vitor: frase sem
## sentido virou uma bola de fogo que não fazia nada). As duas coisas fariam
## o jogador gastar a tentativa e não ver nada acontecer, então contam como
## "não entendi" (ADR-002).
##
## Passa a ficha pelo Validador antes de olhar os campos: achado numa
## revisão de segurança que ler "componentes" direto da ficha crua (ex.: a
## IA manda "componentes": null) quebra o tipo fixo de Array no meio e faz
## esta função devolver `false` (o padrão do tipo de retorno) sem avisar
## ninguém — ou seja, o exato "passar sem ser entendido" que ela existe
## para barrar. O Validador já sabe devolver sempre uma Array de verdade,
## não importa o que a IA mande.
func _ficha_sem_componentes(ficha: Dictionary) -> bool:
	if ficha.is_empty():
		return true
	var componentes: Array = Validador.validar_ficha(ficha).get("componentes", [])
	if componentes.is_empty():
		return true
	for componente in componentes:
		if _componente_tem_efeito_real(componente):
			return false
	return true


## Confere se um componente (ou algum efeito dentro do seu "ao_impactar")
## faz alguma coisa de verdade, independente do tipo. Generalizado para
## incluir "cura" (proposta técnica, seção 3) sem repetir a regra de
## "projétil fantasma" (dano/empurrão zerados) achada com o Vitor na
## Fase 2: um componente sem efeito real também conta como "não entendi".
func _componente_tem_efeito_real(componente: Dictionary) -> bool:
	var tipo = componente.get("tipo")
	if tipo == "explosao" and (componente.get("dano", 0.0) > 0.0 or componente.get("empurrao", 0.0) != 0.0):
		return true
	if tipo == "cura" and componente.get("quantidade", 0.0) > 0.0:
		return true
	if tipo == "escudo" and componente.get("reducao", 0.0) > 0.0 and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "estado" and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "invocacao" and componente.get("vida", 0.0) > 0.0 and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "lancador" and _componente_tem_efeito_real(componente.get("projetil", {})):
		return true
	if tipo == "parede" and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "teleporte" and componente.get("distancia_m", 0.0) > 0.0:
		return true
	if tipo == "area" and componente.get("duracao_s", 0.0) > 0.0 and (componente.get("dano_por_s", 0.0) > 0.0 or componente.get("nome_estado", "") != ""):
		return true
	for efeito in (componente.get("ao_impactar", []) as Array):
		if _componente_tem_efeito_real(efeito):
			return true
	return false


func _conjurar_ficha(ficha: Dictionary) -> void:
	if _cooldown_restante > 0.0:
		return
	var ficha_validada := Validador.validar_ficha(ficha)
	var custo := Validador.calcular_custo_mana(ficha_validada)
	if not Host.gastar_mana(self, custo):
		return
	_cooldown_restante = COOLDOWN_CONJURACAO_S
	var mira := ponto_de_disparo()
	var origem: Vector3 = mira[0]
	var direcao: Vector3 = mira[1]
	GerenciadorSom.tocar_tiro(origem)
	_corpo_visivel.conjurar()
	_mao.conjurar()
	Executor.executar_ficha(ficha_validada, origem, direcao, self, get_tree().current_scene)
	conjurou.emit(ficha_validada.get("legenda", ""))


## De onde a magia sai e para onde vai: sai da mão (primeira pessoa) ou do
## cristal do cajado (terceira pessoa), como na referência, mas mira no
## ponto exato que o centro da tela aponta, para a mira continuar honesta.
## Se houver parede entre a câmera e a mão, sai da câmera mesmo (senão a
## magia nasceria do outro lado da parede).
func ponto_de_disparo() -> Array:
	var camera := _camera_ativa()
	var frente := -camera.global_transform.basis.z
	var saida_camera := camera.global_position + frente * 0.5
	var espaco := get_world_3d().direct_space_state
	var alvo := camera.global_position + frente * ALCANCE_MIRA_M
	var consulta := PhysicsRayQueryParameters3D.create(camera.global_position, alvo, MASCARA_MIRA, [get_rid()])
	var acerto := espaco.intersect_ray(consulta)
	if not acerto.is_empty():
		alvo = acerto["position"]
	var origem := _mao.ponto_da_magia() if modo_camera_primeira_pessoa else _corpo_visivel.ponto_da_magia()
	var bloqueio := PhysicsRayQueryParameters3D.create(camera.global_position, origem, 1 | 16, [get_rid()])
	if not espaco.intersect_ray(bloqueio).is_empty() or alvo.distance_to(camera.global_position) < 1.5:
		return [saida_camera, frente]
	return [origem, (alvo - origem).normalized()]


func gastar_mana(custo: float) -> bool:
	if mana_atual < custo:
		return false
	mana_atual -= custo
	mana_mudou.emit(mana_atual, mana_maxima)
	return true


func _regenerar_mana(delta: float) -> void:
	if mana_atual < mana_maxima:
		mana_atual = minf(mana_maxima, mana_atual + REGEN_MANA_POR_S * delta)
		mana_mudou.emit(mana_atual, mana_maxima)


## Chamado pelo Executor quando uma ficha tem um componente "cura" (proposta
## técnica, seção 3). Simétrico a receber_dano: nunca passa do teto de vida.
func curar(quantidade: float) -> void:
	vida_atual = minf(vida_maxima, vida_atual + quantidade)
	vida_mudou.emit(vida_atual, vida_maxima)


## Chamado pelo Executor quando uma ficha tem um componente "escudo"
## (proposta técnica, seção 3). Guarda só a redução mais forte entre as
## que já estão ativas, em vez de somar (senão duas magias fracas juntas
## virariam imunidade total, o que a proposta técnica não prevê).
func aplicar_escudo(reducao: float, duracao_s: float) -> void:
	if duracao_s <= 0.0 or reducao <= _reducao_escudo:
		return
	_reducao_escudo = reducao
	var timer := get_tree().create_timer(duracao_s)
	timer.timeout.connect(_remover_escudo.bind(reducao))


## Só zera se o escudo que está expirando ainda for o mais forte: uma
## magia de escudo mais nova e mais forte, conjurada por cima, não pode
## ser apagada pela expiração da mais antiga e mais fraca.
func _remover_escudo(reducao_que_expirou: float) -> void:
	if _reducao_escudo == reducao_que_expirou:
		_reducao_escudo = 0.0


func aplicar_estado(nome_estado: String, duracao_s: float) -> void:
	estados.aplicar(nome_estado, duracao_s)


func receber_dano(dano: float, origem_dano: Vector3, empurrao: float) -> void:
	dano *= (1.0 - _reducao_escudo)
	vida_atual = maxf(0.0, vida_atual - dano)
	vida_mudou.emit(vida_atual, vida_maxima)
	if empurrao != 0.0:
		# Empurrão negativo puxa para o centro em vez de afastar: a mesma
		# conta com o sinal invertido (proposta técnica, seção 3).
		var direcao := (global_position - origem_dano).normalized()
		velocity += direcao * empurrao
	if vida_atual <= 0.0:
		morreu.emit()


func adicionar_runa(nome: String) -> void:
	runas.append(nome)
	runas_mudaram.emit(runas.duplicate())


func definir_interacao(alvo: Node, texto: String) -> void:
	_interacao = alvo
	interacao_mudou.emit(texto)


func limpar_interacao(alvo: Node) -> void:
	if _interacao == alvo:
		_interacao = null
		interacao_mudou.emit("")


## Tecla E: age sobre o objeto que está perto (abrir baú, usar a bigorna).
func interagir() -> void:
	if is_instance_valid(_interacao) and _interacao.has_method("interagir"):
		_interacao.interagir(self)
