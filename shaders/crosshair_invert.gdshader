shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		discard;
	}
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = vec4(1.0 - screen.rgb, tex.a);
}
