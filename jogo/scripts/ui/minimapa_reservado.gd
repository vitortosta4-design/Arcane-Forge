class_name MinimapaReservado
extends Control
## Espaço reservado do minimapa no canto inferior direito (ADR-039): só a
## círculo liso com o N e a seta do jogador (visual provisório de propósito). O minimapa de verdade entra
## quando houver mapa para mostrar (Fase 4 ou 7).

const COR_FUNDO := Color(0.15, 0.15, 0.17, 0.55)

var _fonte: Font = null


func _ready() -> void:
	_fonte = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centro := size / 2.0
	var raio := minf(size.x, size.y) / 2.0
	draw_circle(centro, raio, COR_FUNDO)
	var n := "N"
	var largura := _fonte.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var base := centro + Vector2(-largura / 2.0, -raio + 20.0)
	draw_string_outline(_fonte, base, n, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.7))
	draw_string(_fonte, base, n, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	# Seta do jogador no meio, apontando para cima.
	draw_colored_polygon(PackedVector2Array([centro + Vector2(0, -9), centro + Vector2(7, 7), centro + Vector2(0, 3), centro + Vector2(-7, 7)]), Color.WHITE)
