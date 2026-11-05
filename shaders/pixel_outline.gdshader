shader_type canvas_item;
// Contorno de 1 píxel alrededor de los personajes 3D (dibujados a baja resolución), como en el pixel art:
// separa la figura del suelo y le da una silueta clara, al estilo de Signalis.

uniform vec4 outline_color : source_color = vec4(0.06, 0.05, 0.07, 0.85);

varying vec4 tint; // color de «modulate» (destellos de daño, transparencia en sigilo…)

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
		a = max(a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
		a = max(a, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
		COLOR = a > 0.5 ? vec4(outline_color.rgb, outline_color.a * tint.a) : vec4(0.0);
	} else {
		COLOR = vec4(c.rgb, 1.0) * tint;
	}
}
