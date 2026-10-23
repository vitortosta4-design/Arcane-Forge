class_name VidaInimigos
extends Control
## Barrinha de vida em cima dos inimigos, só depois que alguém acerta o
## inimigo (escolha 3b do Vitor, 23/10/2026), como a da galinha na
## referência docs/referencias/hud-referencia-01.png. Some sozinha alguns
## segundos depois do último acerto, para a tela não encher de barras.
## Só lê os inimigos (grupo "inimigo" com fracao_vida e segundos_desde_dano).

const VISIVEL_POR_S := 4.0
const SUMINDO_S := 0.5
const TAMANHO := Vector2(58, 8)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	# Sem câmera (tela de teste, troca de cena) não há onde projetar: normal.
	if camera == null:
		return
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not (inimigo is Node3D) or not inimigo.has_method("fracao_vida"):
			continue
		var desde: float = inimigo.get("segundos_desde_dano") if inimigo.get("segundos_desde_dano") != null else INF
		var fracao: float = inimigo.fracao_vida()
		if desde > VISIVEL_POR_S or fracao <= 0.0:
			continue
		var altura: float = inimigo.get("ALTURA_BARRA_VIDA") if inimigo.get("ALTURA_BARRA_VIDA") != null else 1.3
		var ponto: Vector3 = inimigo.global_position + Vector3.UP * altura
		if camera.is_position_behind(ponto):
			continue
		var tela := camera.unproject_position(ponto)
		var alfa := clampf((VISIVEL_POR_S - desde) / SUMINDO_S, 0.0, 1.0)
		# Mais longe, barra menor, mas nunca ilegível.
		var escala := clampf(10.0 / maxf(camera.global_position.distance_to(ponto), 0.1), 0.6, 1.3)
		var t := TAMANHO * escala
		var pos := tela - Vector2(t.x / 2.0, t.y)
		EstiloHud.barra(self, pos, t, fracao, EstiloHud.VIDA, EstiloHud.VIDA_CLARA, alfa, true)
