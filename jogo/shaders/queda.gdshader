// Queda de lava ou de água do fundo da caverna da forja: a cor de cada
// vértice com faixas mais claras descendo, como água correndo.
// Sem luz, sem névoa, dos dois lados. Barato: uma conta por pixel.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, shadows_disabled;

uniform float velocidade = 0.55;
uniform float faixas_por_metro = 0.11;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// A faixa desce com o tempo; o seno quebra a linha reta de lado a lado.
	float faixa = fract(mundo.y * faixas_por_metro + TIME * velocidade + sin(mundo.x * 0.9 + mundo.z * 0.7) * 0.35);
	float brilho = 0.55 + 0.5 * smoothstep(0.0, 0.25, faixa) * (1.0 - smoothstep(0.5, 1.0, faixa));
	ALBEDO = COLOR.rgb * brilho;
}
