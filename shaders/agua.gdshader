shader_type spatial;
render_mode cull_disabled;
// Agua con movimiento (2026-11-11, petición del usuario: «el agua no tiene animación»). Vale para el río y el lago.
// La textura pixelada del agua se desplaza en dos capas cruzadas y la superficie ondula un poco (sin mover vértices,
// solo la normal), así los brillos de la luz se mueven. Mismo aspecto retro que el resto: textura sin suavizar.

uniform sampler2D tex : filter_nearest_mipmap, repeat_enable;
uniform vec4 tinte : source_color = vec4(0.2, 0.5, 0.8, 0.9);
uniform float escala = 0.28;    // repeticiones de la textura por metro (como el resto del suelo: una cada ~3,6 m)
uniform float velocidad = 0.12; // metros por segundo que corre el agua
uniform float oleaje = 0.35;    // cuánto se inclinan las olas (0 = espejo quieto)

varying vec3 pos_mundo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = pos_mundo.xz * escala;
	vec2 corriente_1 = vec2(TIME * velocidad, TIME * velocidad * 0.6) * escala;
	vec2 corriente_2 = vec2(-TIME * velocidad * 0.7, TIME * velocidad * 0.4) * escala;
	vec3 capa_1 = texture(tex, uv + corriente_1).rgb;
	vec3 capa_2 = texture(tex, uv * 1.7 + corriente_2).rgb;
	ALBEDO = mix(tinte.rgb, mix(capa_1, capa_2, 0.5), 0.45);
	ALPHA = tinte.a;
	float ola = sin(pos_mundo.x * 2.1 + TIME * 1.3) * cos(pos_mundo.z * 1.7 - TIME * 1.1);
	NORMAL = normalize(NORMAL + TANGENT * ola * oleaje * 0.3 + BINORMAL * (1.0 - ola) * oleaje * 0.2);
	ROUGHNESS = 0.15;
	METALLIC = 0.1;
	SPECULAR = 0.6;
}
