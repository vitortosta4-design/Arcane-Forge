class_name RunaColetavel
extends Area3D
## Runa largada no mapa (ADR-035): flutua, gira, brilha na cor dela e vai
## para a mochila de quem encostar. Visual: a runa acesa do lote 3c
## (assets/modelos/runas/runas_v4_acesas.glb), aumentada para dar para ver
## de longe; a luz pontual sem sombra é o "farol" que chama o jogador.

const MODELO := preload("res://assets/modelos/runas/runas_v4_acesas.glb")
const CORES := {
	"fogo": Color("ff7a1a"), "agua": Color("3aa0ff"), "feroz": Color("d8343c"),
	"vida": Color("5fd36a"), "prende": Color("b7a6ff"), "arremesso": Color("ffd23a"),
}
const ESCALA := 2.4
const ALTURA := 1.0

@export var nome := "fogo"

var _visual: Node3D = null
var _tempo := 0.0
var _coletada := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var forma := SphereShape3D.new()
	forma.radius = 1.1
	var c := CollisionShape3D.new()
	c.shape = forma
	c.position = Vector3.UP * ALTURA
	add_child(c)
	_tempo = randf() * TAU

	var todas := MODELO.instantiate()
	var no := todas.get_node_or_null("Runa_%s_acesa" % nome) as Node3D
	if no:
		todas.remove_child(no)
		# Solta o "dono" do arquivo .glb antes de mudar de pai (senão o Godot
		# avisa no console, uma vez por runa, que o dono ficou inconsistente).
		for parte in [no] + no.find_children("*", "", true, false):
			parte.owner = null
		no.position = Vector3.ZERO
		_visual = Node3D.new()
		_visual.add_child(no)
		_visual.scale = Vector3.ONE * ESCALA
		_garantir_cor_do_brilho(no)
		# A luz que vem dentro do .glb chega com força 16 e alcance de 4 km (o
		# Blender exporta em watts) e estourava a runa para branco. A luz da
		# runa é a OmniLight criada abaixo; a do modelo fica só como um toque.
		for luz_modelo in no.find_children("*", "OmniLight3D", true, false):
			(luz_modelo as OmniLight3D).light_energy = 0.3
			(luz_modelo as OmniLight3D).omni_range = 0.6
		add_child(_visual)
	else:
		push_warning("RunaColetavel: o modelo não tem o nó 'Runa_%s_acesa'; a runa fica invisível (só a coleta funciona)." % nome)
	todas.queue_free()

	var luz := OmniLight3D.new()
	luz.light_color = CORES.get(nome, Color.WHITE)
	# Fraca: forte, ela clareava a pedra acesa para salmão (a folha pede pedra
	# escura e saturada, com o brilho só no símbolo).
	luz.light_energy = 0.45
	luz.omni_range = 3.5
	# Na frente do símbolo, para iluminar a face entalhada, não as costas.
	luz.position = Vector3(0, 0.2, 0.35)
	if _visual:
		_visual.add_child(luz)
	else:
		add_child(luz)
	body_entered.connect(_ao_encostar)


func _process(delta: float) -> void:
	_tempo += delta
	if _visual and not _coletada:
		_visual.position.y = ALTURA + sin(_tempo * 2.0) * 0.12
		# A face entalhada sempre virada para quem olha, com um balanço leve
		# (girando, metade do tempo o jogador via só as costas lisas).
		var camera := get_viewport().get_camera_3d()
		if camera:
			var para_camera := camera.global_position - global_position
			_visual.rotation.y = atan2(para_camera.x, para_camera.z) + sin(_tempo * 1.3) * 0.35


func _ao_encostar(corpo: Node) -> void:
	if _coletada or not corpo.has_method("coletar_runa"):
		return
	_coletada = true
	corpo.coletar_runa(nome)
	# Some subindo e encolhendo, para o jogador ver que pegou.
	var tw := create_tween()
	if _visual:
		tw.tween_property(_visual, "position:y", ALTURA + 1.2, 0.25).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_visual, "scale", Vector3.ONE * 0.1, 0.25)
	tw.tween_callback(queue_free)


## As partes acesas do modelo têm cor de base preta e só brilho (emissão).
## No render sem brilho (Compatibility, prints da nuvem) elas viravam
## buracos pretos; com a cor de base igual à do brilho, a runa se lê nos
## dois renderizadores.
func _garantir_cor_do_brilho(raiz: Node) -> void:
	var lista: Array = [raiz]
	while not lista.is_empty():
		var n: Node = lista.pop_back()
		lista.append_array(n.get_children())
		if n is MeshInstance3D:
			for i in n.mesh.get_surface_count():
				var mat := n.get_active_material(i) as StandardMaterial3D
				if mat and mat.emission_enabled and mat.albedo_color.v < 0.1:
					var copia := mat.duplicate() as StandardMaterial3D
					copia.albedo_color = mat.emission
					n.set_surface_override_material(i, copia)
