// Sombreamento toon (degraus de cor) + luz de contorno (rim light), barato
// o bastante para o hardware mínimo (ADR-025). Usa os modos embutidos do
// Godot (diffuse_toon/specular_toon) em vez de calcular luz na mão.
shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_back;

uniform vec4 cor_base : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float contorno_intensidade : hint_range(0.0, 1.0) = 0.45;
uniform float contorno_mistura : hint_range(0.0, 1.0) = 0.55;
uniform float aspereza : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	ALBEDO = cor_base.rgb * COLOR.rgb;
	ROUGHNESS = aspereza;
	RIM = contorno_intensidade;
	RIM_TINT = contorno_mistura;
}
