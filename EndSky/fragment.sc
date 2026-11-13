#define AURELIA_END_FRAG

#ifndef INSTANCING
$input v_texcoord0, v_posTime
#endif

#include <bgfx_shader.sh>

#ifndef INSTANCING
  #include <main.sh>

  SAMPLER2D_AUTOREG(s_SkyTexture);
  SAMPLER2D_AUTOREG(s_noisesmooth);
#endif

void main() {
  #ifndef INSTANCING
    vec3 dir = normalize(v_posTime.xyz);
    float dither = fract(sin(dot(dir.xy, vec2(12.9898, 78.233))) * 43758.5453);
    vec3 color = aureliaEndSky(s_SkyTexture, s_noisesmooth, dir, v_posTime.w, dither);
    gl_FragColor = vec4(color, 1.0);
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
