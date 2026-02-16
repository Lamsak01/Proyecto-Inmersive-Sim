shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Color a eliminar (por defecto negro)
uniform float threshold : hint_range(0.0, 1.0) = 0.1; // Margen de error para colores similares

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	// Calcula la diferencia entre el color del pixel y el color clave
	float diff = distance(color.rgb, key_color.rgb);
	
	// Si la diferencia es menor al umbral, hazlo transparente
	if (diff < threshold) {
		color.a = 0.0;
	}
	
	COLOR = color;
}
