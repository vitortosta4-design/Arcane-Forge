extends SceneTree
## Ferramenta de desenvolvimento, não faz parte do jogo: monta um palco escuro
## (caverna da forja), põe a bigorna viva no meio, troca as expressões e salva
## quadros da animação. Rodar com --fixed-fps para os quadros caírem sempre no
## mesmo instante, mesmo com o OpenGL por software sendo lento:
##   godot --rendering-driver opengl3 --fixed-fps 30 --path . \
##     --script res://scripts/ferramentas/print_bigorna.gd -- --saida /tmp/quadros [--perto] [--filme]
## Gera /tmp/quadros/q_<segundos>_<rotulo>.png.
## --perto: câmera no rosto. --filme: salva um quadro a cada 2 (15 por segundo) para virar GIF.
##
## Não cita a classe BigornaViva pelo nome (em --script isso quebra a compilação).

var _saida := "/tmp/quadros"
var _bigorna: Node = null
var _tempo := 0.0
var _quadros := []          # [tempo, rotulo]
var _acoes := []            # [tempo, expressao]
var _perto := false
var _filme := false
var _n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--saida")
	if i >= 0 and i + 1 < args.size():
		_saida = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_saida)
	_perto = args.has("--perto")
	_filme = args.has("--filme")
	var palco := Node3D.new()
	root.add_child(palco)
	current_scene = palco

	var amb := Environment.new()
	amb.background_mode = Environment.BG_COLOR
	amb.background_color = Color("1d1a26")
	amb.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	amb.ambient_light_color = Color("5a5878")
	amb.ambient_light_energy = 0.9
	amb.background_energy_multiplier = 0.4
	amb.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	amb.tonemap_white = 8.0
	amb.glow_enabled = true
	amb.glow_intensity = 1.2
	amb.glow_strength = 1.2
	amb.glow_bloom = 0.15
	amb.glow_hdr_threshold = 0.9
	var we := WorldEnvironment.new()
	we.environment = amb
	palco.add_child(we)

	var lua := DirectionalLight3D.new()
	lua.light_color = Color("a9a4d8")
	lua.light_energy = 0.8
	lua.rotation_degrees = Vector3(-40, 30, 0)
	palco.add_child(lua)

	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(14, 14)
	chao.mesh = plano
	var mat_chao := StandardMaterial3D.new()
	mat_chao.albedo_color = Color("2e2a36")
	chao.material_override = mat_chao
	palco.add_child(chao)

	_bigorna = load("res://cenas/forja/bigorna_viva.tscn").instantiate()
	palco.add_child(_bigorna)

	var cam := Camera3D.new()
	palco.add_child(cam)
	cam.position = Vector3(0, 2.3, 6.2) if _perto else Vector3(0, 3.6, 10.5)
	cam.fov = 42.0
	cam.current = true

	_acoes = [[1.0, "raiva"], [2.6, "rindo"], [4.2, "neutro"]]
	_quadros = [[0.9, "neutro"]]
	for a in _acoes:
		for dt in [0.06, 0.12, 0.17, 0.24, 0.4, 0.9]:
			_quadros.append([a[0] + dt, "%s_%+.2f" % [a[1], dt]])


func _process(delta: float) -> bool:
	if _tempo == 0.0:
		var cam: Camera3D = current_scene.get_viewport().get_camera_3d()
		cam.look_at(Vector3(0, 1.75, 0) if _perto else Vector3(0, 2.6, 0), Vector3.UP)
	_tempo += delta
	while not _acoes.is_empty() and _tempo >= _acoes[0][0]:
		_bigorna.mudar_expressao(_acoes.pop_front()[1])
	if _filme:
		_n += 1
		if _tempo >= 0.8 and _n % 2 == 0:
			root.get_viewport().get_texture().get_image().save_png("%s/f_%04d.png" % [_saida, _n])
		return _tempo > 5.3
	while not _quadros.is_empty() and _tempo >= _quadros[0][0]:
		var q = _quadros.pop_front()
		var img := root.get_viewport().get_texture().get_image()
		var nome := "%s/q_%05.2f_%s.png" % [_saida, q[0], q[1]]
		img.save_png(nome)
		print("QUADRO SALVO ", nome)
	return _quadros.is_empty() and _acoes.is_empty()
