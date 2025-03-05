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

float computeSpecularBRDF(float R0, float specExp, vec3 V, vec3 L) {
  vec3 H = normalize(V + L);
  float hDotV = dot(H, V);
  float exponential = pow(1.0-hDotV, 5.0);
  float fresnel = exponential + R0 * (1.0 - exponential);
  //  return clamp(fresnel * pow(hDotV, specExp), 0.0, 1.0);
  return fresnel * pow(hDotV, specExp);
}

vec3 computeColor(vec3 color, vec2 prop, vec3 N, vec3 V, vec3 L) {
  vec3 brdf = color + computeSpecularBRDF(prop.x, prop.y, V, L) * vec3(1.0, 1.0, 1.0);
  //  return brdf * clamp(dot(N, L), 0.0, 1.0);
  return brdf * dot(N, L);
}

void main(void) {
  vec3 out_color;
  vec3 lightVector = light_position - view_position;
  vec3 viewVector = -view_position;
  vec3 surfaceNormal = view_normal;
  
  vec2 materialProps = frontProps;
  vec3 diffuseColor;
  
  if (frontFlags.y == 1.0) {
    diffuseColor = texture(diffuseTexture, tex_coord).xyz;
  } else {
    diffuseColor = frontColor;
  }
  
  float distAtten = 1.0 + dot(lightVector, lightVector) / 10;
  vec3 directLight = direct_color / distAtten;
  vec3 ambientLight = ambient_color / distAtten;
  
  out_color = ambientLight * diffuseColor +
  directLight * computeColor(diffuseColor,
                             materialProps,
                             normalize(surfaceNormal),
                             normalize(viewVector),
                             normalize(lightVector));
  
  frag_color = vec4(out_color, 1.0);
}
