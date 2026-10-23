extends SceneTree
## Ferramenta de desenvolvimento, não faz parte do jogo: mede o FPS da arena
## sempre do mesmo jeito, para dar para comparar antes e depois de uma
## mudança (auditoria visual, seção F).
##
## Roteiro fixo:
##   1. aquecimento de 5 s, descartado (a clareira é gerada por código ao
##      abrir, e o contador de FPS do HUD mente nesses primeiros segundos:
##      é daí que vinham os prints com "FPS: 1" e "FPS: 2");
##   2. 30 s "passeio": o mago parado no centro, girando a câmera uma volta
##      completa a cada 15 s (enxerga o mapa inteiro);
##   3. 30 s "combate": o mesmo giro, conjurando bola de fogo sem parar,
##      com mana infinita (pior caso de magias simultâneas).
##
## Uso (Windows, PC de teste): ferramentas\medir_fps.bat
## Uso (Linux):                ferramentas/medir_fps.sh [--rapido]
## O relatório sai no console e em user://medicao_fps.txt (o caminho
## completo aparece no fim).
##
## Mesmas armadilhas do tirar_print.gd: nada de citar classes globais ou
## autoloads pelo nome; definir current_scene; posicionar no 1º _process.

const Medicao := preload("res://scripts/ferramentas/medicao_fps.gd")

var _mago: Node = null
var _medicao := Medicao.new()


func _initialize() -> void:
	_medicao.configurar("--rapido" in OS.get_cmdline_user_args())
	var cena: PackedScene = load("res://cenas/arena_teste.tscn")
	var instancia := cena.instantiate()
	root.add_child(instancia)
	current_scene = instancia
	_mago = instancia.get_node("Mago")
	# Sem vsync, para medir o que a placa aguenta, não a taxa do monitor.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _process(delta: float) -> bool:
	if not _medicao.passo(delta, _mago):
		return false
	Medicao.salvar(_medicao.relatorio(root.get_visible_rect().size))
	return true
