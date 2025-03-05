#version 150

uniform mat4 u_modelTransform;
uniform mat4 u_modelViewTransform;
uniform mat4 u_modelViewProjectionTransform;

in vec4 in_position;
in vec3 in_normal;
in vec2 in_texCoord0;

// out vec3 position;
out vec3 view_position;
out vec3 view_normal;
out vec2 tex_coord;

void main(void)
{
  //  vec4 out_position = u_modelViewProjectionTransform * in_position; 
  // position = out_position.xyz;
  view_position = (u_modelViewTransform * in_position).xyz;
  view_normal = (u_modelViewTransform * vec4(in_normal, 0.0)).xyz;
  
  tex_coord = in_texCoord0;
  
  gl_Position = u_modelViewProjectionTransform * in_position;
}
