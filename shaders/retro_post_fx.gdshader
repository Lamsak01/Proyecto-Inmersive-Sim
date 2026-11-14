shader_type canvas_item;
// Acabado retro (viñeta suave, grano de película y paleta con tramado Bayer ordenado estilo PS1).
// Toda la luz de día/atardecer/noche, farolas, lluvia y niebla vive en el mundo 3D real.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float time_s = 0.0;
uniform float pixel_size = 2.0;
uniform float color_levels = 64.0;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.5;
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	vec2 frag = FRAGCOORD.xy;

	// Viñeta suave en bordes
	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= 1.22;
	float v = dot(uv, uv);
	col *= clamp(1.0 - v * 0.42, 0.0, 1.0);

	// Grano de película discreto
	vec2 cell = floor(frag / pixel_size);
	float n = fract(sin(dot(cell + floor(time_s * 12.0) * 7.13, vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * 0.018;

	// Paleta reducida con tramado ordenado (toque PS1)
	float b = bayer4(cell);
	col = floor(col * (color_levels - 1.0) + 0.5 + b) / (color_levels - 1.0);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
