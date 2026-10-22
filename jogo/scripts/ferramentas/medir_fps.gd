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

const AQUECIMENTO_S := 5.0
const PASSEIO_S := 30.0
const COMBATE_S := 30.0
const VOLTA_CAMERA_S := 15.0
const INTERVALO_TIRO_S := 0.15

var _mago: Node = null
var _tempo := 0.0
var _tempo_tiro := 0.0
var _fator := 1.0
var _passeio: Array[float] = []
var _combate: Array[float] = []
var _draw_calls: Array[float] = []
var _primitivas: Array[float] = []
var _tiros := 0


func _initialize() -> void:
	if "--rapido" in OS.get_cmdline_user_args():
		_fator = 0.2
	var cena: PackedScene = load("res://cenas/arena_teste.tscn")
	var instancia := cena.instantiate()
	root.add_child(instancia)
	current_scene = instancia
	_mago = instancia.get_node("Mago")
	# Sem vsync, para medir o que a placa aguenta, não a taxa do monitor.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _process(delta: float) -> bool:
	_tempo += delta
	var aquecimento := AQUECIMENTO_S * _fator
	var fim_passeio := aquecimento + PASSEIO_S * _fator
	var fim_combate := fim_passeio + COMBATE_S * _fator

	if _mago:
		_mago.global_position = Vector3(0, 1.0, 3.0)
		_mago.rotation.y = TAU * _tempo / VOLTA_CAMERA_S

	if _tempo < aquecimento:
		return false

	_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_primitivas.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

	if _tempo < fim_passeio:
		_passeio.append(delta)
		return false

	if _tempo < fim_combate:
		_combate.append(delta)
		_tempo_tiro -= delta
		if _tempo_tiro <= 0.0 and _mago:
			_tempo_tiro = INTERVALO_TIRO_S
			_mago.mana_atual = _mago.mana_maxima
			_mago._cooldown_restante = 0.0
			_mago._tentar_conjurar_bola_de_fogo()
			_tiros += 1
		return false

	_relatar()
	return true


func _relatar() -> void:
	var linhas := PackedStringArray()
	linhas.append("=== MEDIÇÃO DE FPS · Arcane Forge ===")
	linhas.append("Data: %s" % Time.get_datetime_string_from_system(false, true))
	linhas.append("Placa de vídeo: %s" % RenderingServer.get_video_adapter_name())
	linhas.append("Renderizador: %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	linhas.append("Resolução: %s" % str(root.get_visible_rect().size))
	linhas.append("")
	linhas.append(_resumo("Passeio (sem magias)", _passeio))
	linhas.append(_resumo("Combate (%d bolas de fogo)" % _tiros, _combate))
	linhas.append("")
	linhas.append("Chamadas de desenho por quadro: média %.0f, máximo %.0f" % [_media(_draw_calls), _maximo(_draw_calls)])
	linhas.append("Triângulos por quadro: média %.0f, máximo %.0f" % [_media(_primitivas), _maximo(_primitivas)])
	linhas.append("")
	linhas.append("Meta (auditoria, seção G): média >= 60 e 1% pior >= 45 no combate, numa RTX 2060 em 1080p.")
	var texto := "\n".join(linhas)
	print(texto)
	var arquivo := FileAccess.open("user://medicao_fps.txt", FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(texto + "\n")
		arquivo.close()
		print("Relatório salvo em: ", ProjectSettings.globalize_path("user://medicao_fps.txt"))


func _resumo(nome: String, tempos: Array[float]) -> String:
	if tempos.is_empty():
		return "%s: sem amostras" % nome
	var ordenados: Array[float] = tempos.duplicate()
	ordenados.sort()
	var total := 0.0
	for t in tempos:
		total += t
	var media_fps := tempos.size() / total
	# "1% pior": FPS médio do 1% de quadros mais lentos (o que dá a sensação de travada).
	var quantidade := maxi(1, int(ordenados.size() * 0.01))
	var soma_lentos := 0.0
	for i in quantidade:
		soma_lentos += ordenados[ordenados.size() - 1 - i]
	var pior_1: float = quantidade / soma_lentos
	var minimo: float = 1.0 / ordenados[ordenados.size() - 1]
	return "%s: média %.1f FPS | 1%% pior %.1f FPS | quadro mais lento %.1f FPS | %d quadros" % [nome, media_fps, pior_1, minimo, tempos.size()]


func _media(lista: Array[float]) -> float:
	if lista.is_empty():
		return 0.0
	var total := 0.0
	for v in lista:
		total += v
	return total / lista.size()


func _maximo(lista: Array[float]) -> float:
	var m := 0.0
	for v in lista:
		m = maxf(m, v)
	return m
