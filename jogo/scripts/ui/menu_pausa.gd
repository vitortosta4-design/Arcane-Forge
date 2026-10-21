extends CanvasLayer
## Menu de pausa só para testar (pedido do Vitor, 21/10/2026): Esc abre e
## fecha, com Reiniciar e Sair. Ferramenta de desenvolvimento — visual
## simples de propósito, não precisa ser a UI final do jogo.

var _mago: Node = null
var _caixa_conjuracao: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Painel/Botoes/Continuar.pressed.connect(_fechar)
	$Painel/Botoes/Reiniciar.pressed.connect(_reiniciar)
	$Painel/Botoes/Sair.pressed.connect(_sair)


## Mesmo padrão do HUD/caixa de conjuração: liga ao mago (pra travar a
## entrada dele enquanto o menu está aberto) e à caixa de conjuração (pra
## Esc não abrir o menu por cima dela, só fechar a caixa primeiro).
func configurar(mago: Node, caixa_conjuracao: CanvasLayer) -> void:
	_mago = mago
	_caixa_conjuracao = caixa_conjuracao


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		return
	if _caixa_conjuracao and _caixa_conjuracao.visible:
		return
	get_viewport().set_input_as_handled()
	if visible:
		_fechar()
	else:
		_abrir()


func _abrir() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _mago:
		_mago.definir_entrada_bloqueada(true)


func _fechar() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _mago:
		_mago.definir_entrada_bloqueada(false)


func _reiniciar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _sair() -> void:
	get_tree().quit()
