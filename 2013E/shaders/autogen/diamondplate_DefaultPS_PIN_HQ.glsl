uniform sampler2D StudsMap;
uniform sampler2D NormalMap;
uniform sampler3D LightMap;
uniform vec4 LightConfig1;
uniform vec4 LightBorder;
uniform vec3 Lamp1Color;
uniform vec3 Lamp0Dir;
uniform vec3 Lamp0Color;
uniform vec3 FogColor;
uniform vec3 AmbientColor;
void main ()
{
  vec4 tmpvar_1;
  tmpvar_1 = gl_TexCoord[2];
  vec4 tmpvar_2;
  tmpvar_2 = gl_TexCoord[4];
  vec4 tmpvar_3;
  tmpvar_3 = gl_TexCoord[6];
  vec4 oColor0_4;
  vec4 albedo_5;
  vec3 tmpvar_6;
  vec4 tmpvar_7;
  tmpvar_7 = texture2D (StudsMap, gl_TexCoord[1].xy);
  vec3 normal_8;
  vec3 tmpvar_9;
  tmpvar_9 = ((2.0 * texture2D (NormalMap, (gl_TexCoord[0].xy * 1.2)).xyz) - 1.0);
  normal_8.z = tmpvar_9.z;
  normal_8.xy = (tmpvar_9.xy * 0.3);
  tmpvar_6.z = normal_8.z;
  float tmpvar_10;
  tmpvar_10 = clamp (tmpvar_3.w, 0.0, 1.0);
  tmpvar_6.xy = (normal_8.xy * (1.0 - tmpvar_10));
  vec3 tmpvar_11;
  tmpvar_11 = mix (mix (gl_Color.xyz, gl_Color.xyz, vec3(tmpvar_10)), tmpvar_7.xyz, tmpvar_7.www);
  vec4 tmpvar_12;
  tmpvar_12.xyz = tmpvar_11;
  tmpvar_12.w = gl_Color.w;
  albedo_5.w = tmpvar_12.w;
  vec3 tmpvar_13;
  tmpvar_13 = normalize((((tmpvar_6.x * tmpvar_3.xyz) + (tmpvar_6.y * ((tmpvar_2.yzx * tmpvar_3.zxy) - (tmpvar_2.zxy * tmpvar_3.yzx)))) + (tmpvar_9.z * tmpvar_2.xyz)));
  float tmpvar_14;
  tmpvar_14 = dot (tmpvar_13, -(Lamp0Dir));
  vec4 tmpvar_15;
  tmpvar_15.xyz = ((clamp (tmpvar_14, 0.0, 1.0) * Lamp0Color) + (max (-(tmpvar_14), 0.0) * Lamp1Color));
  tmpvar_15.w = (float((tmpvar_14 >= 0.0)) * 0.9);
  vec3 tmpvar_16;
  tmpvar_16 = clamp (tmpvar_1.xyz, 0.0, 1.0);
  vec3 tmpvar_17;
  tmpvar_17 = abs((tmpvar_16 - 0.5));
  vec4 tmpvar_18;
  tmpvar_18 = mix (LightBorder, texture3D (LightMap, (tmpvar_16 - LightConfig1.xyz)), vec4(float((0.49 >= max (tmpvar_17.x, max (tmpvar_17.y, tmpvar_17.z))))));
  albedo_5.xyz = tmpvar_11;
  oColor0_4.xyz = ((((AmbientColor + (tmpvar_15.xyz * tmpvar_18.w)) + tmpvar_18.xyz) * tmpvar_11) + (Lamp0Color * ((tmpvar_18.w * tmpvar_15.w) * pow (clamp (dot (tmpvar_13, normalize((-(Lamp0Dir) + normalize(gl_TexCoord[3].xyz)))), 0.0, 1.0), tmpvar_2.w))));
  oColor0_4.w = albedo_5.w;
  oColor0_4.xyz = mix (FogColor, oColor0_4.xyz, vec3(clamp (tmpvar_1.w, 0.0, 1.0)));
  gl_FragData[0] = oColor0_4;
}

