shader_type spatial;
render_mode blend_mix, depth_draw_never, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx, skip_vertex_transform;

// Mouth decal: the texture's red channel is the mouth mask, green mixes in
// teeth, blue mixes in tongue.
uniform vec4 Mouth_Colour : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 Tongue_Colour : source_color = vec4(0.705882, 0.070588, 0.070588, 1.0);
uniform sampler2D Texture : source_color;
uniform vec4 Teeth_Colour : source_color = vec4(0.698039, 0.698039, 0.698039, 1.0);
// How far the decal is pulled toward the camera. Poses that fold the face
// (looking up) can bury the decal inside the body where it fails the depth
// test; a view-space pull keeps it on top of the skin at any pose while
// leaving it correctly occluded by anything genuinely in front.
uniform float Camera_Pull = 0.18;


void vertex() {
	vec3 view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = length(view_pos);
	view_pos -= normalize(view_pos) * min(Camera_Pull, dist * 0.5);
	VERTEX = view_pos;
	NORMAL = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
}


void fragment() {
	vec4 tex = texture(Texture, UV);
	vec3 col = mix(Mouth_Colour.rgb, Tongue_Colour.rgb, tex.b);
	col = mix(col, Teeth_Colour.rgb, tex.g);
	ALBEDO = col;
	ALPHA = tex.r;
}
