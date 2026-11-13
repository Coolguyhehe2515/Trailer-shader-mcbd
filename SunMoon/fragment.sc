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
      vec3 m = moon.rgb * SunMoonColor.rgb;
      float l = dot(m, vec3(0.299, 0.587, 0.114));
      m = mix(m, vec3(l, l, l), AURELIA_MOON_WHITEN);
      m *= AURELIA_MOON_BRIGHTNESS * (1.0 + l * AURELIA_MOON_HOT);
      moon.rgb = aureliaColorGrade(m);
      moon.a *= vis;
      gl_FragColor = moon;
    }
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
