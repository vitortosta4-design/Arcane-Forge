// Sombreamento toon (degraus de cor) + luz de contorno (rim light), barato
// o bastante para o hardware mínimo (ADR-025). Calcula a luz na mão (em vez
// de usar os modos embutidos diffuse_toon/specular_toon do Godot): aquele
// jeito estava deixando a cor da pedra "estourar" para a cor da luz em vez
// de preservar a cor do material (achado testando com o Vitor).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

uniform vec4 cor_base : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float contorno_intensidade : hint_range(0.0, 1.0) = 0.3;
uniform int faixas : hint_range(1, 4) = 2;

void fragment() {
	ALBEDO = cor_base.rgb * COLOR.rgb;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float nivel = ceil(ndotl * float(faixas)) / float(faixas);
	if (ndotl <= 0.0001) {
		nivel = 0.0;
	}
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * nivel * ATTENUATION;

	float contorno = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * contorno_intensidade;
	DIFFUSE_LIGHT += contorno * LIGHT_COLOR * ATTENUATION;
}
