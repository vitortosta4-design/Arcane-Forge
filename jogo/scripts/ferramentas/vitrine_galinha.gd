extends SceneTree
## Vitrine da galinha v4 na luz da clareira: invocada (esquerda) e zumbi
## (direita), no tamanho do jogo. Gera os prints de cada animação e o vídeo.
##
## Print:  --acao Parado|Andar|Bicar|Dano|Morrer --tempo s --vista frente|34 --saida X.png
##         (dispara a ação pelo VisualGalinha e fotografa depois de --tempo s)
## Vídeo:  --video (rodar com --write-movie e --fixed-fps 30): parado, entram
##         andando, bicam, apanham e morrem; termina sozinho.

const CENA := "res://cenas/testes/teste_galinhas.tscn"
const ESCALA_INVOCADA := 0.6   # Galinha Kamikaze (receitas.json)
const POS_INVOCADA := Vector3(-0.6, 0, 5)
const POS_ZUMBI := Vector3(0.6, 0, 5)
const VISTAS := {
	"frente": [Vector3(0, 0.55, 7.4), Vector3(0, 0.38, 5)],
	"34": [Vector3(1.9, 1.05, 6.9), Vector3(0, 0.35, 5)],
	"video": [Vector3(-0.6, 0.95, 8.8), Vector3(-0.6, 0.4, 5.0)],
}

var _args := {}
var _galinhas: Array[VisualGalinha] = []


func _init() -> void:
	_ler_argumentos()
	var cena: Node3D = (load(CENA) as PackedScene).instantiate()
	root.add_child(cena)
	for antiga in ["GalinhaAtual", "GalinhaNova"]:
		cena.get_node(antiga).queue_free()
	for zumbi in [false, true]:
		var g := VisualGalinha.criar(zumbi)
		g.scale = Vector3.ONE * (0.62 if zumbi else ESCALA_INVOCADA)
		cena.add_child(g)
		g.position = POS_ZUMBI if zumbi else POS_INVOCADA
		g.rotation.y = PI   # frente da criatura (-Z) para a câmera
		_galinhas.append(g)
	var camera := Camera3D.new()
	camera.fov = 50
	cena.add_child(camera)
	var vista: Array = VISTAS["video" if _args.has("video") else _args.get("vista", "frente")]
	camera.look_at_from_position(vista[0], vista[1])
	camera.make_current()
	if _args.has("video"):
		await _video()
	else:
		await _print()
	quit()


func _print() -> void:
	await _esperar(0.4)
	var acao: String = _args.get("acao", "Parado")
	for g in _galinhas:
		match acao:
			"Andar": g.set_meta("andando", true)
			"Bicar": g.bicar()
			"Dano": g.levar_dano()
			"Morrer": g.morrer()
	await _esperar(float(_args.get("tempo", "0.5")))
	await RenderingServer.frame_post_draw
	var saida: String = _args.get("saida", "/tmp/vitrine_galinha.png")
	root.get_viewport().get_texture().get_image().save_png(saida)
	print("PRINT SALVO ", saida)


func _video() -> void:
	await _esperar(1.5)
	# Entram andando da esquerda, em velocidade de jogo (3 m/s).
	for g in _galinhas:
		g.position.x -= 4.5
		g.rotation.y = -PI / 2   # frente (-Z) para +X
		g.set_meta("andando", true)
	await _esperar(1.5)
	for g in _galinhas:
		g.remove_meta("andando")
		g.rotation.y = PI
	await _esperar(1.0)
	for g in _galinhas:
		g.bicar()
	await _esperar(1.3)
	for g in _galinhas:
		g.levar_dano()
	await _esperar(1.0)
	for g in _galinhas:
		g.morrer()
	await _esperar(2.2)


## Espera em quadros, movendo quem anda. No vídeo (--fixed-fps 30) cada quadro
## vale 1/30 s; no print, o tempo real entre quadros.
func _esperar(segundos: float) -> void:
	var restante := segundos
	var antes := Time.get_ticks_usec()
	while restante > 0.0:
		await process_frame
		var agora := Time.get_ticks_usec()
		var dt := 1.0 / 30.0 if _args.has("video") else (agora - antes) / 1e6
		antes = agora
		restante -= dt
		for g in _galinhas:
			var andando := g.has_meta("andando")
			if andando and _args.has("video"):
				g.position.x += 3.0 * dt
			g.atualizar_andar(3.0 if andando else 0.0)


func _ler_argumentos() -> void:
	var lista := OS.get_cmdline_user_args()
	for i in lista.size():
		if lista[i].begins_with("--"):
			var chave := lista[i].trim_prefix("--")
			_args[chave] = lista[i + 1] if i + 1 < lista.size() and not lista[i + 1].begins_with("--") else ""
