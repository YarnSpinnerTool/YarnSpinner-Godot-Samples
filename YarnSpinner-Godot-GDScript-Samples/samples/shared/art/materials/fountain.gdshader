shader_type spatial;

// Scrolling fountain water: the albedo UV drifts along x at scroll_speed
// (-0.5 UV per second by default).

uniform sampler2D albedo_tex: source_color, filter_linear_mipmap, repeat_enable;
uniform float scroll_speed = -0.5;

void fragment() {
	vec2 uv = UV;
	uv.x += scroll_speed * TIME;
	vec4 c = texture(albedo_tex, uv);
	ALBEDO = c.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 0.0;
}
