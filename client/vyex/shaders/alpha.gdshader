shader_type spatial;

uniform float alpha : hint_range(0.0, 1.0);

void fragment() {
    ALBEDO = vec3(1.0);  // 기본 색상 흰색
    ALPHA = alpha;       // 투명도
}