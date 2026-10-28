extends SceneTree
## Ferramenta de desenvolvimento, não faz parte do jogo: abre a arena, posiciona
## o mago, encena uma ação (opcional) e salva um print. Também é a encenação
## da gravação quadro a quadro (ferramentas/gravar_quadros.sh). Chamada por
## ferramentas/tirar_print.sh, que explica os argumentos.
##
## Armadilhas já encontradas (não repetir):
## - Não citar classes globais (Executor, FichasPadrao...) nem autoloads
##   (Host, GerenciadorSom...) pelo nome aqui: rodando com --script, isso quebra a
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
			if _args.has("runas"):
				for nome in str(_args["runas"]).split(","):
					_mago.coletar_runa(nome)
			if _args.has("barra-cheia"):
				# Só para o print: equipa dois medalhões forjados de verdade pelo
				# livro nos espaços vazios (os 2 padrão já vêm na barra).
				for soma in [["vida", "fogo"], ["arremesso", "agua"]]:
					var resultado: Dictionary = _mago.livro.forjar(soma)
					if resultado.get("ok", false):
						_mago.barra.equipar(resultado)
					else:
						push_warning("tirar_print: não forjou %s: %s" % [soma, resultado.get("motivo", "?")])
			if _args.has("estados"):
				for nome in str(_args["estados"]).split(","):
					_mago.aplicar_estado(nome, 30.0)
			if _args.has("galinha"):
				var galinha := current_scene.get_node_or_null("GalinhaZumbi") as Node3D
				if galinha:
					galinha.global_position = _vetor(_args["galinha"])
					if _args.has("ferir-galinha"):
						# Dano direto (sem magia) só para a barra de vida dela aparecer no print.
						galinha.receber_dano(float(_args["ferir-galinha"]), galinha.global_position + Vector3.BACK, 0.0)
				else:
					push_warning("tirar_print: --galinha pedido, mas a cena não tem GalinhaZumbi.")
			if _args.has("arvore_gigante"):
				# Evento ambiental raro (ADR-047): só para a evidência visual,
				# sem esperar o sorteio de verdade. Formato: 6 números
				# "ox,oy,oz,dx,dy,dz" (origem e destino da rota).
				var numeros := str(_args["arvore_gigante"]).split(",")
				var arvore: Node3D = load("res://cenas/eventos/arvore_gigante.tscn").instantiate()
				current_scene.add_child(arvore)
				arvore.iniciar(
					Vector3(float(numeros[0]), float(numeros[1]), float(numeros[2])),
					Vector3(float(numeros[3]), float(numeros[4]), float(numeros[5])))
		if _args.has("camera"):
			# Câmera livre (por exemplo para ver o mago de frente, ou cenas sem mago).
			var camera := Camera3D.new()
			current_scene.add_child(camera)
			camera.global_position = _vetor(_args["camera"])
			camera.look_at(_vetor(_args.get("alvo-camera", "0,1,0")), Vector3.UP)
			camera.fov = 50.0
			camera.current = true
		return false

	if _etapa == 1 and _tempo >= 0.5:
		_etapa = 2
		if _args.has("andar"):
			# Segura W por --andar segundos (o mago lê a ação como um jogador).
			Input.action_press("mover_frente")
		if _mago and _args.has("martelar"):
			# Martela na bigorna as runas dadas (precisam estar na mochila, --runas).
			var caverna := current_scene.get_node_or_null("Caverna")
			if caverna and caverna.get("forja"):
				var saida: Dictionary = caverna.forja.martelar(_mago, str(_args["martelar"]).split(","))
				print("MARTELOU: ", saida.get("mensagem", "?"))
			else:
				push_warning("tirar_print: --martelar pedido, mas a cena não tem Caverna com forja.")
		# Depois de martelar, para dar para usar o medalhão recém-forjado.
		if _mago and _args.has("usar"):
			_mago.usar_medalhao(int(_args["usar"]) - 1)
		return false

	if _args.has("andar") and _etapa >= 2 and _tempo >= 0.5 + float(_args["andar"]) and Input.is_action_pressed("mover_frente"):
		Input.action_release("mover_frente")

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
