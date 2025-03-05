#version 150

// in vec3 position;
in vec3 view_position;
in vec3 view_normal;
in vec2 tex_coord;

// Texture
uniform sampler2D diffuseTexture;

// Lighting
uniform vec3 light_position;
uniform vec3 direct_color;
uniform vec3 ambient_color;

// Material
uniform vec3 frontColor;
uniform vec2 frontProps;
uniform vec2 frontFlags;

// Out
out vec4 frag_color;

void main(void) {
  vec3 lightVector = light_position - view_position;
  vec3 viewVector = normalize(-view_position);
  vec3 surfaceNormal = normalize(view_normal);
  
  float s = dot(surfaceNormal, viewVector) < 0.3 ? 0.0 : 1.0;
  
  frag_color = vec4(s, s, s, 1.0);
}
