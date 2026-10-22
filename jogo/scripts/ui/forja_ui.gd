class_name ForjaUI
extends CanvasLayer
## Tela da bigorna (ADR-035, Fase 2), provisória até a Fase 5: escolher
## runas da mochila, martelar, ver o que saiu e quebrar medalhão para abrir
## espaço. Não mostra o resultado antes de martelar (descobrir faz parte da
## graça); só avisa quando a combinação quebra as regras e, se a receita já
## está no grimório, diz o nome dela.

var mago: Node = null
var forja: Forja = null
var hud: Node = null

var _selecao: Array[String] = []
var _botoes_runa: Array[Button] = []
var _caixa_runas: HFlowContainer
var _label_bigorna: Label
var _label_resultado: Label
var _caixa_medalhoes: VBoxContainer
var _label_grimorio: Label
var _botao_martelar: Button


func _ready() -> void:
	layer = 5
	visible = false
	_montar()


func configurar(o_mago: Node, a_forja: Forja, o_hud: Node) -> void:
	mago = o_mago
	forja = a_forja
	hud = o_hud
	mago.runas_mudaram.connect(func(_r): if visible: _atualizar())


func _process(_delta: float) -> void:
	if mago == null or forja == null or hud == null:
		return
	if visible:
		hud.mostrar_aviso("")
	elif forja.perto(mago):
		hud.mostrar_aviso("E: usar a bigorna")
	else:
		hud.mostrar_aviso("")


func _unhandled_input(event: InputEvent) -> void:
	if mago == null or forja == null:
		return
	if not visible and event.is_action_pressed("interagir") and forja.perto(mago):
		abrir()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir"):
		fechar()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pular"):
		martelar()
		get_viewport().set_input_as_handled()


func abrir() -> void:
	_selecao.clear()
	_label_resultado.text = ""
	visible = true
	mago.definir_entrada_bloqueada(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_atualizar()


func fechar() -> void:
	visible = false
	mago.definir_entrada_bloqueada(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func martelar() -> void:
	var resultado := forja.martelar(mago, _selecao)
	_label_resultado.text = resultado["mensagem"]
	_label_resultado.modulate = Color(1.0, 0.9, 0.5) if resultado["ok"] else Color(1.0, 0.5, 0.45)
	if resultado["ok"]:
		_selecao.clear()
	_atualizar()


# --- Montagem e atualização ----------------------------------------------

func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.06, 0.45)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var painel := PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_CENTER)
	painel.custom_minimum_size = Vector2(620, 0)
	# À esquerda, para a bigorna (no meio da tela) aparecer reagindo.
	painel.position = Vector2(-560, -250)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.13, 0.1, 0.16, 1.0)
	estilo.border_color = Color(1.0, 0.55, 0.2)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(18)
	painel.add_theme_stylebox_override("panel", estilo)
	fundo.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	painel.add_child(coluna)

	coluna.add_child(_titulo("Bigorna viva"))
	coluna.add_child(_texto("Escolha até 3 runas: 1 de forma e até 2 de elemento.", 14, Color(0.85, 0.82, 0.9)))
	coluna.add_child(_texto("Sua mochila:", 16, Color.WHITE))
	_caixa_runas = HFlowContainer.new()
	coluna.add_child(_caixa_runas)
	_label_bigorna = _texto("", 17, Color(1.0, 0.85, 0.55))
	coluna.add_child(_label_bigorna)
	_botao_martelar = Button.new()
	_botao_martelar.text = "Martelar! (Espaço)"
	_botao_martelar.custom_minimum_size = Vector2(0, 40)
	_botao_martelar.pressed.connect(martelar)
	coluna.add_child(_botao_martelar)
	_label_resultado = _texto("", 17, Color.WHITE)
	_label_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(_label_resultado)
	coluna.add_child(_texto("Medalhões:", 16, Color.WHITE))
	_caixa_medalhoes = VBoxContainer.new()
	coluna.add_child(_caixa_medalhoes)
	_label_grimorio = _texto("", 13, Color(0.8, 0.78, 0.9))
	_label_grimorio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(_label_grimorio)
	coluna.add_child(_texto("Esc ou E: sair", 12, Color(0.7, 0.7, 0.75)))


func _atualizar() -> void:
	for b in _botoes_runa:
		b.queue_free()
	_botoes_runa.clear()
	# Uma runa por botão; selecionar marca a primeira cópia ainda livre.
	var usadas := {}
	for r in _selecao:
		usadas[r] = usadas.get(r, 0) + 1
	var vistas := {}
	for r in mago.runas:
		vistas[r] = vistas.get(r, 0) + 1
		var marcada: bool = vistas[r] <= usadas.get(r, 0)
		var b := Button.new()
		b.text = ("✔ " if marcada else "") + _nome_runa(r)
		b.toggle_mode = true
		b.button_pressed = marcada
		b.custom_minimum_size = Vector2(96, 34)
		b.modulate = RunaColetavel.CORES.get(r, Color.WHITE).lightened(0.3)
		b.toggled.connect(_alternar.bind(r))
		_caixa_runas.add_child(b)
		_botoes_runa.append(b)
	if mago.runas.is_empty():
		var vazio := Button.new()
		vazio.text = "(nenhuma runa: explore a clareira)"
		vazio.disabled = true
		_caixa_runas.add_child(vazio)
		_botoes_runa.append(vazio)

	var livro: LivroReceitas = mago.livro
	if _selecao.is_empty():
		_label_bigorna.text = "Na bigorna: nada"
	else:
		var nomes := PackedStringArray()
		for r in _selecao:
			nomes.append(_nome_runa(r))
		var linha := "Na bigorna: " + " + ".join(nomes)
		var motivo := livro.motivo_invalida(_selecao)
		if motivo != "":
			linha += "   (%s)" % motivo
		else:
			var previsto := livro.forjar(_selecao)
			if previsto["especial"] and forja.grimorio.conhece(previsto["id"]):
				linha += "   = %s" % previsto["nome"]
		_label_bigorna.text = linha

	for f in _caixa_medalhoes.get_children():
		f.queue_free()
	for i in BarraMedalhoes.ESPACOS:
		var linha := HBoxContainer.new()
		var m = mago.barra.medalhoes[i]
		var nome := "%d. %s" % [i + 1, m["nome"] if m != null else "(vazio)"]
		var rotulo := _texto(nome, 15, Color(m["cor"]).lightened(0.3) if m != null else Color(0.6, 0.6, 0.65))
		rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(rotulo)
		if m != null:
			var quebrar := Button.new()
			quebrar.text = "Quebrar"
			quebrar.pressed.connect(func() -> void:
				mago.barra.quebrar(i)
				_atualizar())
			linha.add_child(quebrar)
		_caixa_medalhoes.add_child(linha)

	var conhecidas := PackedStringArray()
	for id in forja.grimorio.descobertas:
		var r := livro.receita_por_id(id)
		if not r.is_empty():
			conhecidas.append(r["nome"])
	_label_grimorio.text = "Grimório: %d de %d receitas%s" % [conhecidas.size(), livro.total_receitas(),
		(": " + ", ".join(conhecidas)) if not conhecidas.is_empty() else ""]


func _alternar(ligado: bool, runa: String) -> void:
	if ligado:
		if _selecao.size() < LivroReceitas.MAXIMO_RUNAS:
			_selecao.append(runa)
	else:
		var i := _selecao.find(runa)
		if i >= 0:
			_selecao.remove_at(i)
	_atualizar.call_deferred()


func _nome_runa(id: String) -> String:
	var livro: LivroReceitas = mago.livro
	if livro.formas.has(id):
		return livro.formas[id]["nome"]
	if livro.elementos.has(id):
		return livro.elementos[id]["nome"]
	return id


func _titulo(texto: String) -> Label:
	var l := _texto(texto, 26, Color(1.0, 0.7, 0.3))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _texto(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l
