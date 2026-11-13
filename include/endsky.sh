#ifndef AURELIA_ENDSKY_H
#define AURELIA_ENDSKY_H

#include <tonemap.sh>
#include <noise.sh>
#include <config.sh>

vec3 aureliaEndSky(sampler2D tex, vec3 dir, highp float time) {
  float el = dir.y;
  float horizonGlow = pow(1.0 - saturate(abs(el)), AURELIA_END_GLOW_POWER);

  vec3 col = mix(AURELIA_END_SKY_HORIZON, AURELIA_END_SKY_ZENITH, smoothstep(0.0, 0.8, el));
  col = mix(col, AURELIA_END_SKY_NADIR, 1.0 - smoothstep(-0.6, 0.0, el));
  col += AURELIA_END_GLOW_COLOR * horizonGlow * AURELIA_END_GLOW_AMOUNT;

  highp float az = atan2(dir.z, dir.x) * 0.15915494 + 0.5;
  highp float azq = floor(az * AURELIA_END_AURORA_CELLS) / AURELIA_END_AURORA_CELLS;
  highp float elq = floor(max(el, 0.0) * AURELIA_END_AURORA_ROWS) / AURELIA_END_AURORA_ROWS;
  highp float t = time * AURELIA_END_AURORA_SPEED;

  highp float edge = 0.10 + 0.14 * aureliaNoise(vec2(azq * 6.0, t));
  float above = elq - edge;
  float curtain = smoothstep(0.0, 0.05, above) * (1.0 - smoothstep(0.05, 0.65, above));

  float streak = aureliaNoise(vec2(azq * 48.0, t * 1.5));
  streak = 0.35 + 0.65 * smoothstep(0.25, 0.75, streak);

  float shaft = aureliaNoise(vec2(azq * 9.0 + 3.0, t * 0.6));
  shaft = smoothstep(0.35, 0.8, shaft) * (1.0 - smoothstep(0.0, 0.9, max(el, 0.0)));

  float base = (1.0 - smoothstep(0.0, 0.25, above)) * smoothstep(0.0, 0.05, above);

  vec3 aurora = AURELIA_END_AURORA_A * curtain * streak;
  aurora += AURELIA_END_AURORA_B * base * streak;
  aurora += AURELIA_END_AURORA_A * shaft * AURELIA_END_SHAFT_AMOUNT;

  col += aurora * AURELIA_END_AURORA_AMOUNT * step(0.0, el);

  col *= AURELIA_END_BRIGHTNESS;

  #ifdef AURELIA_END_GRADE
    col = aureliaColorGrade(col);
  #endif

  return col;
}

#endif
