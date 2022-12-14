attribute vec3 uv3;
attribute vec4 uv2;
attribute vec4 secondary_colour;
attribute vec4 colour;
attribute vec2 uv1;
attribute vec2 uv0;
attribute vec3 normal;
attribute vec4 vertex;
uniform vec4 WorldMatrixArray[216];
uniform mat4 ViewProjection;
uniform vec4 LightConfig1;
uniform vec4 LightConfig0;
uniform vec4 FogParams;
uniform vec2 FadeDistance;
uniform vec3 CameraPosition;
void main ()
{
  ivec4 tmpvar_1;
  tmpvar_1 = ivec4(secondary_colour);
  vec4 tmpvar_2;
  tmpvar_2 = WorldMatrixArray[(tmpvar_1.x * 3)];
  vec4 tmpvar_3;
  tmpvar_3 = WorldMatrixArray[((tmpvar_1.x * 3) + 1)];
  vec4 tmpvar_4;
  tmpvar_4 = WorldMatrixArray[((tmpvar_1.x * 3) + 2)];
  vec3 tmpvar_5;
  tmpvar_5.x = dot (tmpvar_2, vertex);
  tmpvar_5.y = dot (tmpvar_3, vertex);
  tmpvar_5.z = dot (tmpvar_4, vertex);
  vec3 tmpvar_6;
  tmpvar_6.x = dot (tmpvar_2.xyz, normal);
  tmpvar_6.y = dot (tmpvar_3.xyz, normal);
  tmpvar_6.z = dot (tmpvar_4.xyz, normal);
  vec4 tmpvar_7;
  tmpvar_7.w = 1.0;
  tmpvar_7.xyz = tmpvar_5;
  vec4 tmpvar_8;
  tmpvar_8 = (ViewProjection * tmpvar_7);
  vec4 tmpvar_9;
  tmpvar_9.xyz = (((tmpvar_5 + (tmpvar_6 * 6.0)).xzy * LightConfig0.xyz) + LightConfig1.xyz);
  tmpvar_9.w = ((FogParams.z - tmpvar_8.w) * FogParams.w);
  vec4 tmpvar_10;
  tmpvar_10.xyz = (CameraPosition - tmpvar_5);
  tmpvar_10.w = tmpvar_8.w;
  vec4 tmpvar_11;
  tmpvar_11.xyz = tmpvar_6;
  tmpvar_11.w = float(tmpvar_1.w);
  vec3 tmpvar_12;
  tmpvar_12.x = dot (tmpvar_2.xyz, uv3);
  tmpvar_12.y = dot (tmpvar_3.xyz, uv3);
  tmpvar_12.z = dot (tmpvar_4.xyz, uv3);
  vec4 tmpvar_13;
  tmpvar_13.xyz = tmpvar_12;
  tmpvar_13.w = (tmpvar_8.w * FadeDistance.y);
  gl_Position = tmpvar_8;
  vec4 tmpvar_14;
  tmpvar_14.zw = vec2(0.0, 1.0);
  tmpvar_14.xy = uv0;
  gl_TexCoord[0] = tmpvar_14;
  vec4 tmpvar_15;
  tmpvar_15.zw = vec2(0.0, 1.0);
  tmpvar_15.xy = uv1;
  gl_TexCoord[1] = tmpvar_15;
  gl_FrontColor = colour;
  gl_TexCoord[2] = tmpvar_9;
  gl_TexCoord[3] = tmpvar_10;
  gl_TexCoord[4] = tmpvar_11;
  gl_TexCoord[5] = uv2;
  gl_TexCoord[6] = tmpvar_13;
  gl_FogFragCoord = tmpvar_8.w;
}

