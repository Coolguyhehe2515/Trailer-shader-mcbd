#ifndef AURELIA_ENDSKY_H
#define AURELIA_ENDSKY_H

#include <tonemap.sh>
#include <noise.sh>
#include <config.sh>

#ifdef AURELIA_END_FRAG

float aureliaEndAuroraNoise(sampler2D noiseTex, highp vec2 p) {
  highp vec2 q = floor(p * 1000.0) / 1000.0 + 0.000003;
  return texture2D(noiseTex, q).r;
}

vec3 aureliaEndAurora(sampler2D noiseTex, vec3 dir, highp float time, float dither) {
  float up = clamp(dir.y, 0.0, 1.0);
  float vis = sqrt(max(clamp(up * 4.5 - 0.25, 0.0, 1.0), 0.0));
  vis *= 8.0 - up * 0.9;
  if (vis <= 1.0) {
    return vec3(0.0, 0.0, 0.0);
  }

  highp vec2 wpos = dir.xz / max(dir.y, 0.1);
  highp vec2 drift = vec2(time * AURELIA_END_AURORA_SPEED, 0.0);
  float hz = 1.0 - smoothstep(0.1, 0.55, up);
  float ditherM = dither + 10.0;
  vec3 aurora = vec3(0.0, 0.0, 0.0);

  for (int i = 0; i < AURELIA_END_AURORA_STEPS; i++) {
    float cur = (float(i) + ditherM) / (float(AURELIA_END_AURORA_STEPS) + 10.0);
    cur *= cur;
    float curM = 1.0 - cur;

    highp vec2 planePos = wpos * (0.9 + cur) * 0.075 + drift * 0.003;

    float n = aureliaEndAuroraNoise(noiseTex, planePos);
    n = pow(clamp(1.0 - abs(n - AURELIA_END_AURORA_CENTER), 0.0, 1.0), AURELIA_END_AURORA_SHARP);

    float a1 = aureliaEndAuroraNoise(noiseTex, planePos * 0.5);
    float a2 = aureliaEndAuroraNoise(noiseTex, planePos * 0.8);
    n *= mix(a1, a2, 0.5);

    float w = clamp(curM * curM + 0.6 * hz, 0.0, 1.0);
    vec3 c1 = AURELIA_END_AURORA_COL1 * pow(max(curM, 0.001), 0.4);
    vec3 c2 = AURELIA_END_AURORA_COL2 * curM;
    aurora += n * mix(c1, c2, w);
  }

  aurora *= 0.8;
  return aurora * vis / float(AURELIA_END_AURORA_STEPS);
}

vec3 aureliaEndSky(sampler2D tex, sampler2D noiseTex, vec3 dir, highp float time, float dither) {
  float h = exp(-abs(dir.y) * AURELIA_END_HORIZON_FALLOFF);
  vec3 edge = mix(AURELIA_END_SKY_NADIR, AURELIA_END_SKY_ZENITH, step(0.0, dir.y));
  vec3 col = mix(edge, AURELIA_END_SKY_HORIZON, h);

  col += aureliaEndAurora(noiseTex, dir, time, dither) * AURELIA_END_AURORA_AMOUNT;

  col *= AURELIA_END_BRIGHTNESS;

  #ifdef AURELIA_END_GRADE
    col = aureliaColorGrade(col);
  #endif

  return col;
}

#endif

#endif
