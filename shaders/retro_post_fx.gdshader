shader_type canvas_item;
// Etalonaje (color grading) de todo el mundo del juego, bajo la interfaz.
// Día: nostálgico (cálido, algo desvaído, como una foto vieja). Noche: fría, oscura e inquietante,
// con charcos de luz cálida alrededor de farolas, ventanas encendidas y el propio jugador.
// Siempre: viñeta, grano y paleta reducida con tramado ordenado (dither) a tamaño de píxel del juego,
// el «toque PS1» que une el 2D y el 3D.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float night : hint_range(0.0, 1.0) = 0.0;
uniform float dusk : hint_range(0.0, 1.0) = 0.0;
uniform float time_s = 0.0;
uniform float pixel_size = 4.0;      // tamaño de un píxel del juego en píxeles de pantalla
uniform float color_levels = 32.0;   // niveles por canal (32 = color de 15 bits, como la PS1)
uniform int light_count = 0;
uniform vec4 lights[24];             // xy = posición en pantalla (px), z = radio (px), w = intensidad
uniform vec3 light_tint = vec3(1.0, 0.78, 0.48);

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.5;
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));

	// --- Día nostálgico ---
	vec3 day = mix(vec3(l), c, 0.84);
	day = day * vec3(1.05, 1.00, 0.90) + vec3(0.035, 0.025, 0.0);

	// --- Atardecer: dorado ---
	vec3 gold = c * vec3(1.12, 0.92, 0.74) + vec3(0.04, 0.01, 0.0);
	day = mix(day, gold, dusk);

	// --- Noche inquietante ---
	vec2 frag = FRAGCOORD.xy;
	float lit = 0.0;
	for (int i = 0; i < 24; i++) {
		if (i >= light_count) { break; }
		vec4 L = lights[i];
		float d = distance(frag, L.xy) / max(1.0, L.z);
		// Borde de la luz «escalonado» en anillos, más retro que un degradado suave
		float f = clamp(1.0 - d, 0.0, 1.0);
		f = floor(f * 6.0 + 0.5) / 6.0;
		lit = max(lit, f * f * L.w);
	}
	lit = clamp(lit, 0.0, 1.0);
	vec3 cold = mix(vec3(l), c, 0.45);
	cold = pow(max(cold, vec3(0.0)), vec3(1.18)) * vec3(0.66, 0.80, 0.95) * 0.60;
	vec3 warm = c * light_tint * 1.35;
	vec3 nite = mix(cold, warm, lit);
	vec3 col = mix(day, nite, night);

	// --- Viñeta (más cerrada de noche) ---
	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= 1.25;
	float v = dot(uv, uv);
	col *= clamp(1.0 - v * mix(0.45, 1.25, night), 0.0, 1.0);

	// --- Grano de película, a tamaño de píxel del juego ---
	vec2 cell = floor(frag / pixel_size);
	float n = fract(sin(dot(cell + floor(time_s * 12.0) * 7.13, vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * mix(0.022, 0.05, night);

	// --- Paleta reducida con tramado ordenado (PS1) ---
	float b = bayer4(cell);
	col = floor(col * (color_levels - 1.0) + 0.5 + b) / (color_levels - 1.0);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
