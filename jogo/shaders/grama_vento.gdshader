// Mesmo visual toon + contorno do toon_contorno.gdshader, mais um balanço
// de vento barato (só desloca o topo da lâmina, a base fica presa no chão).
// Cada touceira balança fora de fase da vizinha, usando a posição dela no
// mundo, para não parecer tudo balançando igual feito soldadinho.
shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_disabled;

uniform vec4 cor_base : source_color = vec4(0.3, 0.6, 0.28, 1.0);
uniform float contorno_intensidade : hint_range(0.0, 1.0) = 0.3;
uniform float contorno_mistura : hint_range(0.0, 1.0) = 0.5;
uniform float vento_forca : hint_range(0.0, 0.3) = 0.1;
uniform float vento_velocidade : hint_range(0.0, 5.0) = 1.6;
uniform float meia_altura : hint_range(0.01, 2.0) = 0.225;

void vertex() {
	vec3 pos_mundo = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float fase = pos_mundo.x * 0.6 + pos_mundo.z * 0.6;
	float balanco = sin(TIME * vento_velocidade + fase) * vento_forca;
	float peso = clamp((VERTEX.y + meia_altura) / (meia_altura * 2.0), 0.0, 1.0);
	VERTEX.x += balanco * peso;
	VERTEX.z += balanco * 0.6 * peso;
}

void fragment() {
	ALBEDO = cor_base.rgb * COLOR.rgb;
	RIM = contorno_intensidade;
	RIM_TINT = contorno_mistura;
}
