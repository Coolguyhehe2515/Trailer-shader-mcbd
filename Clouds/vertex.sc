$input a_color0, a_position
#ifdef INSTANCING
  $input i_data0, i_data1, i_data2, i_data3
#endif
$output v_color0

#include <bgfx_shader.sh>
#include <main.sh>

uniform vec4 FogColor;
uniform vec4 FogAndDistanceControl;
uniform vec4 TimeOfDay;

void main() {
  #ifdef INSTANCING
    mat4 model = mtxFromCols(i_data0, i_data1, i_data2, i_data3);
  #else
    mat4 model = u_model[0];
  #endif

  aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);
  float rain = aureliaRain;

  vec3 pos = a_position;
  pos.y *= mix(AURELIA_CLOUD0_THICKNESS, AURELIA_CLOUD0_RAIN_THICKNESS, rain);
  vec3 worldPos = mul(model, vec4(pos, 1.0)).xyz;

  vec3 sunDir = aureliaSunDir(TimeOfDay.x);
  vec3 zenith = aureliaSkyColor(vec3(0.0, 1.0, 0.0), FogColor.rgb, sunDir);
  vec3 horizonEdge = aureliaSkyHorizon(FogColor.rgb, sunDir);

  float cloudFadeY = smoothstep(0.0, 1.0, a_position.y);
  vec3 col = zenith + horizonEdge;
  col += dot(col, vec3(0.3, 0.4, 0.3)) * a_position.y;
  col *= 1.0 - 0.6 * rain;
  col = aureliaColorGrade(col);

  float fade = clamp(2.0 - length(worldPos * vec3(0.005, 0.002, 0.005)), 0.0, 1.0);
  float alpha = AURELIA_CLOUD0_OPACITY * (1.0 - cloudFadeY) * fade;

  bool isL2 = a_color0.g > 0.5 * a_color0.b;
  if (isL2) {
    #ifdef AURELIA_CLOUD0_MULTILAYER
      worldPos.y += 64.0;
    #else
      worldPos = vec3(0.0, 0.0, 0.0);
      alpha = 0.0;
    #endif
  }

  v_color0 = vec4(col, alpha);
  gl_Position = mul(u_viewProj, vec4(worldPos, 1.0));
}
