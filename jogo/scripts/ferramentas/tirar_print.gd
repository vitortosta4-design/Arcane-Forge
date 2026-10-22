extends SceneTree
## Ferramenta de desenvolvimento, não faz parte do jogo: abre a arena, posiciona
## o mago, conjura uma frase (opcional) e salva um print. Chamada por
## ferramentas/tirar_print.sh, que explica os argumentos.
##
## Armadilhas já encontradas (não repetir):
## - Não citar classes globais (Executor, FichasPadrao...) nem autoloads
##   (Host, Porteiro...) pelo nome aqui: rodando com --script, isso quebra a
##   compilação em cascata ("Identifier not found: Host"). Usar get_node.
## - Definir current_scene, senão o Executor recebe mundo nulo ao conjurar.
## - look_at só funciona depois que o nó está na árvore: posicionar no
##   primeiro _process, não no _initialize.

var _args := {}
var _tempo := 0.0
var _etapa := 0
var _mago: Node = null


func _initialize() -> void:
	_args = _ler_args(OS.get_cmdline_user_args())
	var cena: PackedScene = load(_args.get("cena", "res://cenas/arena_teste.tscn"))
	var instancia := cena.instantiate()
	root.add_child(instancia)
	current_scene = instancia
	_mago = instancia.get_node_or_null("Mago")


func _process(delta: float) -> bool:
	_tempo += delta

	if _etapa == 0:
		_etapa = 1
		if _mago:
			if _args.has("posicao"):
				_mago.global_position = _vetor(_args["posicao"])
			if _args.has("olhar"):
				_mago.look_at(_vetor(_args["olhar"]), Vector3.UP)
			if _args.has("terceira"):
				_mago._trocar_camera()
			if _args.has("camera"):
				# Câmera livre (por exemplo para ver o mago de frente).
				var camera := Camera3D.new()
				current_scene.add_child(camera)
				camera.global_position = _vetor(_args["camera"])
				camera.look_at(_vetor(_args.get("alvo-camera", "0,1,0")), Vector3.UP)
				camera.fov = 50.0
				camera.current = true
		return false

	if _etapa == 1 and _tempo >= 0.5:
		_etapa = 2
		if _mago and _args.has("interagir"):
			_mago.interagir()
		if _mago and _args.has("frase"):
			root.get_node("/root/Porteiro").ativo = false
			_mago.conjurar_por_texto(_args["frase"])
		return false

	if _etapa == 2 and _args.has("frase2") and _tempo >= 0.5 + float(_args.get("intervalo", "1.0")):
		_etapa = 3
		_mago.conjurar_por_texto(_args["frase2"])
		return false

	if _etapa >= 2 and _tempo >= float(_args.get("espera", "2.5")):
		var saida: String = _args.get("saida", "/tmp/print.png")
		root.get_texture().get_image().save_png(saida)
		print("PRINT SALVO: ", saida)
		return true

	return false


func _ler_args(lista: PackedStringArray) -> Dictionary:
	var resultado := {}
	var i := 0
	while i < lista.size():
		var chave := lista[i].trim_prefix("--")
		if i + 1 < lista.size() and not lista[i + 1].begins_with("--"):
			resultado[chave] = lista[i + 1]
			i += 2
		else:
			resultado[chave] = "sim"
			i += 1
	return resultado


func _vetor(texto: String) -> Vector3:
	var partes := texto.split(",")
	return Vector3(float(partes[0]), float(partes[1]), float(partes[2]))
