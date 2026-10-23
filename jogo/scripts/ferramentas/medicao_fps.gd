extends RefCounted
## Roteiro fixo de medição de FPS, usado por dois caminhos:
## - medir_fps.gd (ferramenta de desenvolvimento, `godot --script`, só no editor);
## - medidor_fps.gd (autoload), quando o jogo exportado abre com `-- --medir-fps`
##   (a versão exportada não aceita `--script`; achado ao gerar o .exe do Matheus).
## Veja o roteiro em medir_fps.gd.

const AQUECIMENTO_S := 5.0
const PASSEIO_S := 30.0
const COMBATE_S := 30.0
const VOLTA_CAMERA_S := 15.0
const INTERVALO_TIRO_S := 0.15

var _tempo := 0.0
var _tempo_tiro := 0.0
var _fator := 1.0
var _passeio: Array[float] = []
var _combate: Array[float] = []
var _draw_calls: Array[float] = []
var _primitivas: Array[float] = []
var _tiros := 0

func configurar(rapido: bool) -> void:
	_fator = 0.2 if rapido else 1.0

## Avança um quadro do roteiro. Devolve true quando terminou.
func passo(delta: float, mago: Node) -> bool:
	_tempo += delta
	var aquecimento := AQUECIMENTO_S * _fator
	var fim_passeio := aquecimento + PASSEIO_S * _fator
	var fim_combate := fim_passeio + COMBATE_S * _fator

	if mago:
		mago.global_position = Vector3(0, 1.0, 3.0)
		mago.rotation.y = TAU * _tempo / VOLTA_CAMERA_S

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
		if _tempo_tiro <= 0.0 and mago:
			_tempo_tiro = INTERVALO_TIRO_S
			mago.mana_atual = mago.mana_maxima
			mago._cooldown_restante = 0.0
			mago._tentar_conjurar_bola_de_fogo()
			_tiros += 1
		return false

	return true

func relatorio(resolucao: Vector2) -> String:
	var linhas := PackedStringArray()
	linhas.append("=== MEDIÇÃO DE FPS · Arcane Forge ===")
	linhas.append("Data: %s" % Time.get_datetime_string_from_system(false, true))
	linhas.append("Placa de vídeo: %s" % RenderingServer.get_video_adapter_name())
	linhas.append("Fabricante da placa: %s" % RenderingServer.get_video_adapter_vendor())
	linhas.append("Processador: %s (%d núcleos lógicos)" % [OS.get_processor_name(), OS.get_processor_count()])
	linhas.append("Sistema: %s" % OS.get_name())
	linhas.append("Renderizador: %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	linhas.append("Resolução: %s" % str(resolucao))
	linhas.append("")
	linhas.append(_resumo("Passeio (sem magias)", _passeio))
	linhas.append(_resumo("Combate (%d bolas de fogo)" % _tiros, _combate))
	linhas.append("")
	linhas.append("Chamadas de desenho por quadro: média %.0f, máximo %.0f" % [_media(_draw_calls), _maximo(_draw_calls)])
	linhas.append("Triângulos por quadro: média %.0f, máximo %.0f" % [_media(_primitivas), _maximo(_primitivas)])
	linhas.append("")
	linhas.append("Meta (auditoria, seção G): média >= 60 e 1% pior >= 45 no combate, numa RTX 2060 em 1080p.")
	return "\n".join(linhas)

## Mostra no console e grava em user://medicao_fps.txt.
static func salvar(texto: String) -> void:
	print(texto)
	var arquivo := FileAccess.open("user://medicao_fps.txt", FileAccess.WRITE)
	if arquivo == null:
		push_error("MedicaoFps: não deu para gravar user://medicao_fps.txt (%s)." % error_string(FileAccess.get_open_error()))
		return
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
