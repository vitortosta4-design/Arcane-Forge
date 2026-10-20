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
var conjurando := false
var modo_camera_primeira_pessoa := true

var _cooldown_restante := 0.0
var _entrada_bloqueada := false

@onready var _pivot_cabeca: Node3D = $PivotCabeca
@onready var _camera_primeira_pessoa: Camera3D = $PivotCabeca/CameraPrimeiraPessoa
@onready var _camera_terceira_pessoa: Camera3D = $PivotCabeca/BracoCameraTerceiraPessoa/CameraTerceiraPessoa
@onready var _mao: Node3D = $PivotCabeca/CameraPrimeiraPessoa/Mao
@onready var _corpo_visivel: Node3D = $CorpoVisivel

signal vida_mudou(atual: float, maxima: float)
signal mana_mudou(atual: float, maxima: float)
signal conjurou(legenda: String)
signal morreu


func _ready() -> void:
	add_to_group("recebe_dano")
	add_to_group("mago")
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
		velocity.x = direcao.x * VELOCIDADE_ANDAR
		velocity.z = direcao.z * VELOCIDADE_ANDAR

	move_and_slide()


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
## frase. O Interpretador ainda não tem IA (Fase 2 vai ligar o porteiro no
## Supabase); por enquanto só reconhece algumas palavras-chave (ADR-002).
func conjurar_por_texto(frase: String) -> void:
	if _cooldown_restante > 0.0:
		return
	var ficha := Interpretador.interpretar(frase)
	if ficha.is_empty():
		conjurou.emit("a magia está instável agora, use seu grimório")
		return
	_conjurar_ficha(ficha)


func _conjurar_ficha(ficha: Dictionary) -> void:
	if _cooldown_restante > 0.0:
		return
	var ficha_validada := Validador.validar_ficha(ficha)
	var custo := Validador.calcular_custo_mana(ficha_validada)
	if not Host.gastar_mana(self, custo):
		return
	_cooldown_restante = COOLDOWN_CONJURACAO_S
	conjurando = true
	var camera := _camera_ativa()
	var origem := camera.global_position + -camera.global_transform.basis.z * 0.5
	var direcao := -camera.global_transform.basis.z
	Executor.executar_ficha(ficha_validada, origem, direcao, self, get_tree().current_scene)
	conjurou.emit(ficha_validada.get("legenda", ""))
	conjurando = false


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


func receber_dano(dano: float, origem_dano: Vector3, empurrao: float) -> void:
	vida_atual = maxf(0.0, vida_atual - dano)
	vida_mudou.emit(vida_atual, vida_maxima)
	if empurrao > 0.0:
		var direcao := (global_position - origem_dano).normalized()
		velocity += direcao * empurrao
	if vida_atual <= 0.0:
		morreu.emit()
