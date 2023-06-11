#version 300 es

precision highp float;     // required precision declaration

in vec3 fColor;            // input color for fragment
out vec4 final_color;      // output color to frame buffer

void main() {
  final_color = vec4(fColor, 1.0);
}
