#version 460 core
#include <flutter/runtime_effect.glsl>

// ImageFilter provides the physical input size and premultiplied text layer.
uniform vec2 u_size;
uniform float u_exponent;
uniform sampler2D u_input;
out vec4 frag_color;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  // The tested Windows ImageFiltered input already has top-left coordinates.
  // A manual GLES flip in this path inverts each isolated text layer.
  vec4 source = texture(u_input, uv);
  if (source.a <= 0.0) {
    frag_color = vec4(0.0);
    return;
  }
  float coverage = pow(clamp(source.a, 0.0, 1.0), u_exponent);
  // Keep the unpremultiplied ink color; only fractional coverage changes.
  frag_color = vec4(source.rgb * (coverage / source.a), coverage);
}
