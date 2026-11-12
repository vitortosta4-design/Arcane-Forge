class_name BigornaViva
extends Node3D
## A bigorna viva da forja: troca de expressão animada e luz que respira.
##
## O modelo (assets/modelos/forja/bigorna_viva.glb) traz os três rostos como nós
## separados (Rosto_neutro, Rosto_rindo, Rosto_raiva). Este script deixa só um
## visível e, na troca, faz uma pequena coreografia:
##   1. antecipação: a bigorna se encolhe, o rosto velho afunda no nicho e o fogo baixa;
##   2. troca: o rosto novo salta para fora com sobra, o corpo estica e o fogo dá um clarão;
##   3. acomodação: tudo volta ao lugar com um balanço elástico.
## Cada expressão tem sua luz: neutra respira devagar, rindo fica mais quente e
## pulsa mais, raiva fica vermelha, forte, tremida, e o anel de pedras acelera.

signal expressao_mudou(nova: String)
## O martelo acabou de bater (o som, o clarão e as faíscas saem neste instante).
signal martelou

const EXPRESSOES := ["neutro", "rindo", "raiva"]
const T_ANTECIPA := 0.12
const T_SALTA := 0.1
const T_ACOMODA := 0.3
const DURACAO_TROCA := T_ANTECIPA + T_SALTA + T_ACOMODA
## O rosto mora na frente do corpo (+Z no Godot); recuar é ir para -Z.
const RECUO := Vector3(0, 0, -0.22)
const SOBRA := Vector3(0, 0, 0.06)
const VOLTA_ANEL_S := 10.0
## Luzes próprias (energia, alcance em metros). O Blender exporta a potência em
## watts convertida para candela, o que no Godot vira milhares de "energia" e
## estoura a imagem; então a intensidade é decidida aqui, com o olho no jogo.
const LUZES_BASE := {
	"LuzBoca": [3.0, 5.0], "LuzNucleo": [3.5, 6.0], "LuzOlhos": [1.4, 3.0], "LuzBase": [2.0, 4.0],
}

const LUZ := {
	"neutro": {"brilho": 1.0, "cor": Color("ff7a1a"), "pulso_hz": 0.5, "pulso": 0.08, "tremido": 0.0, "anel": 1.0},
	"rindo": {"brilho": 1.25, "cor": Color("ffa232"), "pulso_hz": 0.9, "pulso": 0.12, "tremido": 0.0, "anel": 1.6},
	"raiva": {"brilho": 1.7, "cor": Color("ff4414"), "pulso_hz": 2.2, "pulso": 0.12, "tremido": 0.1, "anel": 2.6},
}

## Martelo fantasma (auditoria de animação, item 5). Visual PROVISÓRIO feito
## em código (cabeça de pedra com faixa de lava e cabo); a regra de forjar não
## depende dele. Tempos do golpe: aparece erguido, recua mais um pouco
## (antecipação), desce acelerando, quica e some.
const MARTELO_SURGE_S := 0.1
const MARTELO_RECUA_S := 0.12
const MARTELO_DESCE_S := 0.07
const TEMPO_ATE_BATER_S := MARTELO_SURGE_S + MARTELO_RECUA_S + MARTELO_DESCE_S
const MARTELO_ERGUIDO_GRAUS := 62.0
const MARTELO_RECUADO_GRAUS := 84.0
const MARTELO_QUIQUE_GRAUS := 14.0
## Onde a cabeça do martelo bate: na mesa da bigorna, ao lado da coluna
## (por dentro do anel de pedras, para não atravessar as pedras girando).
const PONTO_BATIDA := Vector3(1.1, 2.9, 0.2)
const CABO_M := 1.3
const FAISCAS := 8

@export var expressao_inicial := "neutro"

var expressao := ""
var trocando := false

var _rostos := {}
var _corpo: Node3D
var _anel: Node3D
var _luzes: Array[OmniLight3D] = []
var _energia_base := {}
var _materiais: Array[StandardMaterial3D] = []
var _emissao_base := {}
var _estilhacos: Array[Node3D] = []
var _pos_estilhaco := {}

var _brilho := 1.0
var _luz_nome := "neutro"
var _flare := 0.0
var _cor_luz := Color("ff7a1a")
var _vel_anel := 1.0
var _tremor := 0.0
var _t := 0.0
var _sorte := RandomNumberGenerator.new()
var _martelo: Node3D
var _golpe: Tween


func _ready() -> void:
	_sorte.seed = 7
	_corpo = find_child("Corpo", true, false)
	_anel = find_child("AnelPedras", true, false)
	for nome in EXPRESSOES:
		_rostos[nome] = find_child("Rosto_" + nome, true, false)
	# O glTF traz as animações "Orbita" e "Tremer", mas um AnimationPlayer toca uma
	# por vez; o giro do anel e o tremor são feitos aqui, para poderem acontecer juntos.
	for ap in find_children("*", "AnimationPlayer", true, false):
		(ap as AnimationPlayer).stop()
	for l in find_children("*", "OmniLight3D", true, false):
		var luz: OmniLight3D = l
		var ajuste: Array = LUZES_BASE.get(String(luz.name), [2.0, 4.0])
		luz.light_energy = ajuste[0]
		luz.omni_range = ajuste[1]
		luz.omni_attenuation = 1.0
		luz.shadow_enabled = false
		_luzes.append(luz)
		_energia_base[luz] = luz.light_energy
	_preparar_materiais()
	var raiva: Node3D = _rostos.get("raiva")
	if raiva:
		for filho in raiva.get_children():
			if filho.name.begins_with("Estilhaco_") or filho.name.begins_with("Fagulha_"):
				_estilhacos.append(filho)
				_pos_estilhaco[filho] = filho.position
	_criar_martelo()
	var inicial := expressao_inicial if expressao_inicial in EXPRESSOES else "neutro"
	for nome in EXPRESSOES:
		if _rostos[nome]:
			_rostos[nome].visible = nome == inicial
	expressao = inicial
	_luz_nome = inicial
	_brilho = LUZ[inicial]["brilho"]
	_cor_luz = LUZ[inicial]["cor"]
	_vel_anel = LUZ[inicial]["anel"]


## Cada material que brilha vira uma cópia só desta bigorna, para a luz de uma
## não mudar a de outra (e para não mexer no arquivo importado).
func _preparar_materiais() -> void:
	var copias := {}
	for mi in find_children("*", "MeshInstance3D", true, false):
		var malha: MeshInstance3D = mi
		if malha.mesh == null:
			continue
		for i in malha.mesh.get_surface_count():
			var mat := malha.get_active_material(i)
			if not (mat is StandardMaterial3D) or not mat.emission_enabled:
				continue
			if not copias.has(mat):
				var copia: StandardMaterial3D = mat.duplicate()
				copias[mat] = copia
				_materiais.append(copia)
				_emissao_base[copia] = copia.emission_energy_multiplier
			malha.set_surface_override_material(i, copias[mat])


## Pede uma nova expressão. Devolve false se ela não existe, já é a atual ou se
## uma troca ainda está acontecendo (a coreografia não é interrompida no meio).
func mudar_expressao(nova: String) -> bool:
	if not nova in EXPRESSOES or nova == expressao or trocando:
		return false
	var velho: Node3D = _rostos.get(expressao)
	var novo: Node3D = _rostos.get(nova)
	if velho == null or novo == null:
		return false
	trocando = true
	var repouso_velho := velho.position
	var repouso_novo := novo.position
	var tw := create_tween()
	# 1. antecipação
	tw.tween_property(_corpo, "scale", Vector3(1.03, 0.95, 1.03), T_ANTECIPA).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(velho, "position", repouso_velho + RECUO, T_ANTECIPA).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "_flare", -0.45, T_ANTECIPA)
	# 2. troca
	tw.tween_callback(func() -> void:
		velho.visible = false
		velho.position = repouso_velho
		novo.position = repouso_novo + RECUO
		novo.visible = true
		_luz_nome = nova
		_brilho = LUZ[nova]["brilho"]
		_cor_luz = LUZ[nova]["cor"]
		_vel_anel = LUZ[nova]["anel"]
		if nova == "raiva":
			_tremor = 0.08
			_explodir_estilhacos()
	)
	tw.tween_property(novo, "position", repouso_novo + SOBRA, T_SALTA).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_corpo, "scale", Vector3(0.97, 1.06, 0.97), T_SALTA).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(self, "_flare", 1.2, T_SALTA * 0.8)
	# 3. acomodação
	tw.tween_property(novo, "position", repouso_novo, T_ACOMODA * 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_corpo, "scale", Vector3.ONE, T_ACOMODA).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "_flare", 0.0, T_ACOMODA)
	tw.tween_callback(func() -> void:
		expressao = nova
		trocando = false
		expressao_mudou.emit(nova)
	)
	return true


## O eixo do martelo fica fora da bigorna, à direita; o cabo aponta para ela
## e a cabeça fica na ponta. Girar o eixo é o que ergue e desce o martelo.
func _criar_martelo() -> void:
	_martelo = Node3D.new()
	_martelo.name = "Martelo"
	_martelo.position = PONTO_BATIDA + Vector3(CABO_M, 0.25, 0.0)
	_martelo.scale = Vector3.ZERO
	_martelo.visible = false
	add_child(_martelo)
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color("6b4a2e")
	var pedra := StandardMaterial3D.new()
	pedra.albedo_color = Color("3d3852")
	var lava := StandardMaterial3D.new()
	lava.albedo_color = Color("ff7a1a")
	lava.emission_enabled = true
	lava.emission = Color("ff7a1a")
	lava.emission_energy_multiplier = 2.0
	var cabo := CylinderMesh.new()
	cabo.top_radius = 0.07
	cabo.bottom_radius = 0.09
	cabo.height = CABO_M
	cabo.radial_segments = 6
	cabo.rings = 0
	_peca_martelo("Cabo", cabo, madeira, Vector3(-CABO_M * 0.5, 0, 0), Vector3(0, 0, PI * 0.5))
	var cabeca := BoxMesh.new()
	cabeca.size = Vector3(0.5, 0.5, 0.82)
	_peca_martelo("Cabeca", cabeca, pedra, Vector3(-CABO_M, 0, 0), Vector3.ZERO)
	var faixa := BoxMesh.new()
	faixa.size = Vector3(0.56, 0.56, 0.14)
	_peca_martelo("FaixaA", faixa, lava, Vector3(-CABO_M, 0, 0.22), Vector3.ZERO)
	_peca_martelo("FaixaB", faixa, lava, Vector3(-CABO_M, 0, -0.22), Vector3.ZERO)
	var pomo := BoxMesh.new()
	pomo.size = Vector3.ONE * 0.22
	_peca_martelo("Pomo", pomo, pedra, Vector3(0.05, 0, 0), Vector3(PI * 0.25, 0, PI * 0.25))


func _peca_martelo(nome: String, malha: Mesh, mat: Material, pos: Vector3, giro: Vector3) -> void:
	var peca := MeshInstance3D.new()
	peca.name = nome
	peca.mesh = malha
	peca.material_override = mat
	peca.position = pos
	peca.rotation = giro
	_martelo.add_child(peca)


## Golpe de martelo e, na batida, a reação da bigorna (expressão e tremor).
## Só visual e som: quem decide o que foi forjado é a Forja, antes disto.
## Chamado de novo no meio de um golpe, recomeça (vale o pedido mais novo).
func martelar(expressao_depois: String, tremor: float) -> void:
	if _golpe and _golpe.is_valid():
		_golpe.kill()
	_martelo.visible = true
	_martelo.scale = Vector3.ZERO
	_martelo.rotation.z = -deg_to_rad(MARTELO_ERGUIDO_GRAUS)
	_golpe = create_tween()
	_golpe.tween_property(_martelo, "scale", Vector3.ONE, MARTELO_SURGE_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_golpe.tween_property(_martelo, "rotation:z", -deg_to_rad(MARTELO_RECUADO_GRAUS), MARTELO_RECUA_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_golpe.tween_property(_martelo, "rotation:z", 0.0, MARTELO_DESCE_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_golpe.tween_callback(_bater.bind(expressao_depois, tremor))
	_golpe.tween_property(_martelo, "rotation:z", -deg_to_rad(MARTELO_QUIQUE_GRAUS), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_golpe.tween_property(_martelo, "rotation:z", -deg_to_rad(4.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_golpe.tween_interval(0.2)
	_golpe.tween_property(_martelo, "scale", Vector3.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_golpe.tween_callback(func() -> void: _martelo.visible = false)


func _bater(expressao_depois: String, tremor: float) -> void:
	GerenciadorSom.tocar_martelo(to_global(PONTO_BATIDA))
	_tremor = tremor
	_flare = 1.0
	_soltar_faiscas()
	# Se a expressão não muda (ou outra troca está no meio), a bigorna ainda
	# acusa o golpe: afunda e volta, e o clarão apaga sozinho.
	if not mudar_expressao(expressao_depois) and not trocando:
		var tw := create_tween()
		_corpo.scale = Vector3(1.05, 0.93, 1.05)
		tw.tween_property(_corpo, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "_flare", 0.0, 0.3)
	martelou.emit()


## Faíscas da batida: cubinhos acesos em leque para cima, caindo em arco.
func _soltar_faiscas() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffd070")
	var malha := BoxMesh.new()
	malha.size = Vector3.ONE * 0.11
	for i in FAISCAS:
		var f := MeshInstance3D.new()
		f.name = "Faisca%d" % i
		f.mesh = malha
		f.material_override = mat
		f.position = PONTO_BATIDA
		f.rotation = Vector3(_sorte.randf(), _sorte.randf(), _sorte.randf()) * TAU
		add_child(f)
		var angulo := TAU * (float(i) + _sorte.randf() * 0.5) / FAISCAS
		var lado := Vector3(cos(angulo), 0.0, sin(angulo)) * _sorte.randf_range(0.7, 1.5)
		var sobe := _sorte.randf_range(0.6, 1.3)
		var dur := _sorte.randf_range(0.35, 0.5)
		var tw := f.create_tween().set_parallel(true)
		tw.tween_property(f, "position:x", PONTO_BATIDA.x + lado.x, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(f, "position:z", PONTO_BATIDA.z + lado.z, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(f, "position:y", PONTO_BATIDA.y + sobe, dur * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(f, "position:y", PONTO_BATIDA.y - 0.6, dur * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(dur * 0.4)
		tw.tween_property(f, "scale", Vector3.ONE * 0.1, dur).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(f.queue_free)


## Na raiva, as lascas e faíscas saem do meio do rosto voando até o lugar delas.
func _explodir_estilhacos() -> void:
	for e in _estilhacos:
		var destino: Vector3 = _pos_estilhaco[e]
		var centro := Vector3(0, destino.y * 0.3 + 1.3, 0.9)
		e.position = centro
		e.scale = Vector3.ONE * 0.2
		var tw := create_tween()
		tw.tween_property(e, "position", destino, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(e, "scale", Vector3.ONE, 0.25)


## Multiplicador de luz desejado para a expressão atual (sem pulso nem clarão).
func brilho_alvo() -> float:
	return _brilho


## Multiplicador de luz deste instante (o que realmente vai para as luzes).
func brilho_agora() -> float:
	var l: Dictionary = LUZ[_luz_nome]
	var pulso: float = 1.0 + l["pulso"] * sin(TAU * l["pulso_hz"] * _t)
	if l["tremido"] > 0.0:
		pulso += _sorte.randf_range(-l["tremido"], l["tremido"])
	return maxf(0.05, _brilho * pulso + _flare)


func _process(delta: float) -> void:
	_t += delta
	var k := brilho_agora()
	for l in _luzes:
		l.light_energy = _energia_base[l] * k
		l.light_color = l.light_color.lerp(_cor_luz, minf(1.0, delta * 6.0))
	for m in _materiais:
		m.emission_energy_multiplier = _emissao_base[m] * k
	if _anel:
		_anel.rotate_object_local(Vector3.UP, TAU / VOLTA_ANEL_S * _vel_anel * delta)
	if _corpo:
		if _tremor > 0.001:
			_corpo.position = Vector3(_sorte.randf_range(-1, 1), 0, _sorte.randf_range(-1, 1) * 0.5) * _tremor
			_tremor = move_toward(_tremor, 0.0, delta * 0.25)
		elif expressao == "raiva" and not trocando:
			# na raiva ela fica tremendo de leve o tempo todo
			_corpo.position = Vector3(_sorte.randf_range(-1, 1), 0, 0) * 0.012
		else:
			_corpo.position = Vector3.ZERO
