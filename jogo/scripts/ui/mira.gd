extends Control
## Mira no centro da tela (ADR-039), no estilo da referência
## (docs/referencias/hud-referencia-01.png): quatro tracinhos com um vão no
## meio, branco com contorno escuro para aparecer sobre o céu
## claro e sobre a grama.

const VAO := 5.0
const TRACO := 7.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + d * VAO, c + d * (VAO + TRACO), Color(0, 0, 0, 0.7), 4.0)
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + d * VAO, c + d * (VAO + TRACO), Color(1, 1, 1, 0.95), 2.0)
