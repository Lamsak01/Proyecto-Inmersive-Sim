shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.5, 0.8, 1.0, 0.8);
uniform float line_thickness : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 current_color = texture(TEXTURE, UV);
	vec2 size = line_thickness * TEXTURE_PIXEL_SIZE;

	float neighbor_alpha = texture(TEXTURE, UV + vec2(size.x, 0.0)).a
	                     + texture(TEXTURE, UV - vec2(size.x, 0.0)).a
	                     + texture(TEXTURE, UV + vec2(0.0, size.y)).a
	                     + texture(TEXTURE, UV - vec2(0.0, size.y)).a;

	if (current_color.a > 0.01) {
		// Interior: tinte fantasmal
		COLOR = vec4(current_color.rgb * line_color.rgb, current_color.a * line_color.a);
	} else if (neighbor_alpha > 0.0) {
		// Borde: outline puro
		COLOR = line_color;
	} else {
		// Completamente transparente
		COLOR = vec4(0.0);
	}
}
