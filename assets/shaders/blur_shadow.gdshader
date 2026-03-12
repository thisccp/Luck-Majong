shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 20.0) = 8.0;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
	float alpha = 0.0;
	float total_weight = 0.0;
	
	// Analisa 25 pontos em volta do pixel (5x5) com peso Gaussiano
	for (float x = -2.0; x <= 2.0; x += 1.0) {
		for (float y = -2.0; y <= 2.0; y += 1.0) {
			float weight = exp(-(x*x + y*y) / 4.0);
			alpha += texture(TEXTURE, UV + vec2(x, y) * ps).a * weight;
			total_weight += weight;
		}
	}
	
	alpha /= total_weight;
	
	COLOR = vec4(COLOR.rgb, alpha * COLOR.a);
}

