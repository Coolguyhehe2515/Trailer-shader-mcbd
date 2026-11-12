$input v_texcoord0, v_isSun

#include <bgfx_shader.sh>

#ifndef INSTANCING
  #include <main.sh>

  uniform vec4 SunMoonColor;
  uniform vec4 TimeOfDay;

  SAMPLER2D_AUTOREG(s_SunMoonTexture);
#endif

void main() {
  #ifndef INSTANCING
    float tr = 1.0 - SunMoonColor.a;
    float vis = 1.0 - tr * tr;

    if (v_isSun > 0.5) {
      vec4 sun = texture2D(s_SunMoonTexture, v_texcoord0);
      float sunY = aureliaSunDir(TimeOfDay.x).y;
      vec3 sunTint = mix(vec3(1.0, 0.6, 0.35), vec3(1.0, 1.0, 1.0), smoothstep(0.0, 0.35, sunY));
      sun.rgb *= SunMoonColor.rgb * sunTint * AURELIA_SUN_BRIGHTNESS;
      sun.rgb = aureliaColorGrade(sun.rgb);
      sun.a *= vis;
      gl_FragColor = sun;
    } else {
      vec4 moon = texture2D(s_SunMoonTexture, v_texcoord0);
      moon.rgb *= SunMoonColor.rgb * AURELIA_MOON_BRIGHTNESS;
      moon.rgb = aureliaColorGrade(moon.rgb);
      moon.a *= vis;
      gl_FragColor = moon;
    }
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
