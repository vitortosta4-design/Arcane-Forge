extends CanvasLayer
## Caixa de conjuração por texto (ADR-010): Q abre, Enter confirma, Esc
## cancela. Visual próprio (borda e cor roxas), diferente do chat — que
## ainda não existe, porque não há parceiro para conversar antes da Fase 5.

signal frase_confirmada(frase: String)

@onready var _campo: LineEdit = $Painel/CampoTexto

var _mago: Node = null


func _ready() -> void:
	visible = false
	_campo.text_submitted.connect(_ao_confirmar)


## Liga a caixa ao mago (mesmo padrão do HUD): ela avisa o mago quando o
## jogador começa e termina de digitar, para ele não andar nem olhar em
## volta enquanto escreve.
func configurar(mago: Node) -> void:
	_mago = mago


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		if event.is_action_pressed("abrir_conjuracao"):
			_abrir()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_fechar()


func _abrir() -> void:
	visible = true
	_campo.text = ""
	_campo.grab_focus()
	get_viewport().set_input_as_handled()
	if _mago:
		_mago.definir_entrada_bloqueada(true)


func _fechar() -> void:
	visible = false
	_campo.release_focus()
	if _mago:
		_mago.definir_entrada_bloqueada(false)


func _ao_confirmar(texto: String) -> void:
	var frase := texto.strip_edges()
	_fechar()
	if frase != "":
		frase_confirmada.emit(frase)
