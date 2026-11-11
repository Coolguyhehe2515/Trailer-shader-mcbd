#ifndef AURELIA_ENDSKY_H
#define AURELIA_ENDSKY_H

#include <tonemap.sh>
#include <noise.sh>
#include <config.sh>

vec3 aureliaEndSky(sampler2D tex, vec3 dir, highp float time) {
  float below = 1.0 - smoothstep(-0.6, 0.0, dir.y);
  vec3 col = mix(AURELIA_END_SKY_HORIZON, AURELIA_END_SKY_ZENITH, smoothstep(0.0, 0.75, dir.y));
  col = mix(col, AURELIA_END_SKY_NADIR, below);

  vec3 glowDir = normalize(vec3(0.5, 0.55, -0.6));
  float g = max(dot(dir, glowDir), 0.0);
  col = mix(col, AURELIA_END_SKY_GLOW, pow(g, 2.5) * 0.85);

  highp vec2 p = dir.xz / (abs(dir.y) + 0.5) * AURELIA_END_NEBULA_SCALE;
  highp float t = time * AURELIA_END_NEBULA_SPEED;
  float n = aureliaNoise(p + vec2(t, -t * 0.6)) * 0.65 + aureliaNoise(p * 2.3 - vec2(t * 0.7, t)) * 0.35;
  vec3 neb = mix(AURELIA_END_NEBULA_A, AURELIA_END_NEBULA_B, aureliaNoise(p * 0.6 + 11.0));
  col = mix(col, neb, smoothstep(0.45, 0.85, n) * AURELIA_END_NEBULA_AMOUNT);

  col *= AURELIA_END_BRIGHTNESS;

  #ifdef AURELIA_END_GRADE
    col = aureliaColorGrade(col);
  #endif

  return col;
}

#endif
