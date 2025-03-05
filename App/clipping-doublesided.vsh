#version 150

uniform mat4 u_modelTransform;
uniform mat4 u_modelViewTransform;
uniform mat4 u_modelViewProjectionTransform;
uniform vec4 clip_plane;

in vec4 in_position;
in vec3 in_normal;
in vec2 in_texCoord0;

// out vec3 position;
out vec3 view_position;
out vec3 view_normal;
out vec2 tex_coord;
out float clip_dist;
out vec3 clip_position;
out vec3 clip_normal;

void main(void)
{
//  vec4 out_position = u_modelViewProjectionTransform * in_position; 
  // position = out_position.xyz;
  view_position = (u_modelViewTransform * in_position).xyz;
  view_normal = (u_modelViewTransform * vec4(in_normal, 0.0)).xyz;
  
  tex_coord = in_texCoord0;
  
  clip_dist = dot(view_position, clip_plane.xyz) - clip_plane.w;
  
  // clip position
  clip_normal = clip_plane.xyz;
  vec3 plane_point = clip_normal * clip_plane.w;
  vec3 camera_dir = vec3(view_position.x, view_position.y, 0.0) - view_position;
  float ndotu = dot(clip_normal, camera_dir);
  float s = 0.0;
  if (ndotu != 0.0) {
    s = dot(clip_normal, plane_point - view_position) / ndotu;
  }
  clip_position = s * camera_dir + view_position;
  
  gl_ClipDistance[0] = -clip_dist;
  gl_Position = u_modelViewProjectionTransform * in_position;
}
