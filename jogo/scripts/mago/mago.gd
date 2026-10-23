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
var _reducao_escudo := 0.0
var estados := ControladorEstados.new()
## Runas carregadas na expedição (recomeçam a cada uma, ADR-034).
var runas: Array[String] = []
var barra := BarraMedalhoes.new()
var livro: LivroReceitas = null
## O botão do mouse repete o último medalhão usado pelas teclas 1 a 4.
var espaco_selecionado := 0

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
## Forja de Runas (ADR-032 a 035).
signal runas_mudaram(runas: Array)
signal medalhao_usado(espaco: int)


func _ready() -> void:
	add_to_group("recebe_dano")
	add_to_group("mago")
	add_child(estados)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_primeira_pessoa.current = true
	_corpo_visivel.visible = false
	_preparar_medalhoes_iniciais()


## A expedição começa com 2 medalhões padrão e 2 espaços vazios (ADR-035).
func _preparar_medalhoes_iniciais() -> void:
	livro = LivroReceitas.carregar()
	for id in livro.iniciais:
		var medalhao := livro.receita_por_id(str(id))
		if not medalhao.is_empty():
			barra.equipar(medalhao)


func _unhandled_input(event: InputEvent) -> void:
	if _entrada_bloqueada:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSIBILIDADE_MOUSE)
		_pivot_cabeca.rotate_x(-event.relative.y * SENSIBILIDADE_MOUSE)
		_pivot_cabeca.rotation.x = clampf(_pivot_cabeca.rotation.x, -LIMITE_OLHAR_CIMA_BAIXO, LIMITE_OLHAR_CIMA_BAIXO)
	elif event.is_action_pressed("trocar_camera"):
		_trocar_camera()
	elif event.is_action_pressed("conjurar_bola_de_fogo"):
		usar_medalhao(espaco_selecionado)
	else:
		for i in BarraMedalhoes.ESPACOS:
			if event.is_action_pressed("medalhao_%d" % (i + 1)):
				espaco_selecionado = i
				usar_medalhao(i)


func _physics_process(delta: float) -> void:
	_cooldown_restante = maxf(0.0, _cooldown_restante - delta)
	_regenerar_mana(delta)
	barra.avancar(delta)

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


## Usa o medalhão do espaço i: só se ele existir, estiver recarregado e o
## juiz aprovar a mana. A recarga só começa se a magia saiu de verdade.
func usar_medalhao(i: int) -> bool:
	if not barra.pronto(i):
		return false
	if not _conjurar_ficha(barra.medalhoes[i]["ficha"]):
		return false
	barra.iniciar_recarga(i)
	medalhao_usado.emit(i)
	return true


func coletar_runa(nome: String) -> void:
	runas.append(nome)
	runas_mudaram.emit(runas)


## Tira da mochila as runas gastas na bigorna. Só gasta se tiver todas.
func gastar_runas(usadas: Array) -> bool:
	var sobra := runas.duplicate()
	for r in usadas:
		var i := sobra.find(str(r))
		if i < 0:
			return false
		sobra.remove_at(i)
	runas = sobra
	runas_mudaram.emit(runas)
	return true


func _conjurar_ficha(ficha: Dictionary) -> bool:
	if _cooldown_restante > 0.0:
		return false
	var ficha_validada := Validador.validar_ficha(ficha)
	var custo := Validador.calcular_custo_mana(ficha_validada)
	if not Host.gastar_mana(self, custo):
		return false
	_cooldown_restante = COOLDOWN_CONJURACAO_S
	var mira := ponto_de_disparo()
	var origem: Vector3 = mira[0]
	var direcao: Vector3 = mira[1]
	GerenciadorSom.tocar_tiro(origem)
	_corpo_visivel.conjurar()
	_mao.conjurar()
	Executor.executar_ficha(ficha_validada, origem, direcao, self, get_tree().current_scene)
	conjurou.emit(ficha_validada.get("legenda", ""))
	return true


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
	if dano > 0.0:
		_corpo_visivel.reagir_dano()
	if empurrao != 0.0:
		# Empurrão negativo puxa para o centro em vez de afastar: a mesma
		# conta com o sinal invertido (proposta técnica, seção 3).
		var direcao := (global_position - origem_dano).normalized()
		velocity += direcao * empurrao
	if vida_atual <= 0.0:
		morreu.emit()
