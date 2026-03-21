shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.65;
uniform float vignette_softness : hint_range(0.01, 2.0) = 0.45;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.25;
uniform vec4 darkness_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 2.0;
	float vignette = smoothstep(inner_radius, inner_radius + vignette_softness, dist);
	float alpha = clamp(vignette * vignette_intensity, 0.0, 1.0);
	COLOR = vec4(darkness_color.rgb, alpha);
}
