extends Node
## Autoload. Na versão exportada (o .exe), `--script` não existe; então a
## medição de FPS é ligada abrindo o jogo com `-- --medir-fps`
## (`-- --medir-fps --rapido` para a versão curta). Sem esse argumento, o nó
## se remove logo ao abrir: é o caso normal de quem só vai jogar.

const Medicao := preload("res://scripts/ferramentas/medicao_fps.gd")

var _medicao = null
var _mago: Node = null


func _ready() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if not "--medir-fps" in argumentos:
		queue_free()   # jogo normal: nada a medir
		return
	_medicao = Medicao.new()
	_medicao.configurar("--rapido" in argumentos)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _process(delta: float) -> void:
	if _mago == null:
		var cena := get_tree().current_scene
		_mago = cena.get_node_or_null("Mago") if cena else null
		if _mago == null:
			if cena:
				push_error("MedidorFps: a cena principal '%s' não tem o nó 'Mago'; medição cancelada." % cena.name)
				get_tree().quit(1)
			return
	if _medicao.passo(delta, _mago):
		Medicao.salvar(_medicao.relatorio(get_viewport().get_visible_rect().size))
		get_tree().quit()
