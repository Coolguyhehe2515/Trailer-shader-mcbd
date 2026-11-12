#ifndef AURELIA_CLOUDS_H
#define AURELIA_CLOUDS_H

#include <noise.sh>
#include <tonemap.sh>
#include <env.sh>
#include <config.sh>


vec3 aureliaSunDir(float timeOfDay) {
  float a = 6.2831853 * timeOfDay;
  return vec3(sin(a), cos(a), 0.0);
}

highp float aureliaNoiseTile(highp vec2 p, highp float period) {
  highp vec2 i = floor(p);
  highp vec2 f = fract(p);
  highp vec2 u = f * f * (3.0 - 2.0 * f);
  highp float a = aureliaHash(mod(i, period));
  highp float b = aureliaHash(mod(i + vec2(1.0, 0.0), period));
  highp float c = aureliaHash(mod(i + vec2(0.0, 1.0), period));
  highp float d = aureliaHash(mod(i + vec2(1.0, 1.0), period));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

highp float aureliaCloudWeather(highp vec2 p, highp float time) {
  return aureliaNoiseTile(p * 0.2 + vec2(time * 0.003, time * 0.002), 16.0);
}

highp float aureliaCloudBase(highp vec2 p, highp float w) {
  return 0.65 * aureliaNoiseTile(p, 16.0) + 0.35 * aureliaNoiseTile(p * 2.0 + vec2(17.0, 9.0), 32.0) + 0.55 * (w - 0.5);
}

float aureliaCloudCover(highp float shape) {
  float cover = AURELIA_CLOUD_COVERAGE - aureliaRain * AURELIA_CLOUD_RAIN_GROW;
  float soft = AURELIA_CLOUD_SOFTNESS + aureliaRain * AURELIA_CLOUD_RAIN_SOFT;
  return smoothstep(cover, cover + soft, shape);
}

float aureliaCloudDensityCoarse(highp vec2 p, highp float time) {
  return aureliaCloudCover(aureliaCloudBase(p, aureliaCloudWeather(p, time)));
}

float aureliaCloudShadow(highp vec3 worldPos, highp vec2 camXZ, highp float time, vec3 sunDir, float skyLight) {
  return 1.0;
}

vec4 aureliaCloudsVolume(vec3 dir, highp vec2 camXZ, highp float time, vec3 sunDir, vec3 fogColor) {
  float up = dir.y;
  float viewLift = smoothstep(0.01, 0.1, up);
  if (viewLift <= 0.0) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  float wStart = 0.2;
  float wEnd = 0.6;
  highp vec2 dxz = dir.xz / max(up, 0.01);
  float invCell = 1.0 / AURELIA_VCLOUD_CELL;
  float windowLen = (wEnd - wStart) * AURELIA_VCLOUD_THICKNESS;

  float nf = clamp(ceil(windowLen * length(dxz) * invCell * AURELIA_VCLOUD_SAMPLES), 3.0, float(AURELIA_VCLOUD_STEPS));
  int n = int(nf);

  float stepsOld = (wEnd - wStart) * 64.0;
  float alphaStep = 1.0 - pow(max(1.0 - viewLift, 0.0001), stepsOld / nf);

  float jitter = aureliaHash(dir.xz * 1733.0 + vec2(17.0, 31.0));
  highp vec2 wind = vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED;

    float thr = AURELIA_VCLOUD_COVERAGE - aureliaRain * AURELIA_CLOUD_RAIN_GROW;

  float cloudAccum = 0.0;
  float alphaAccum = 0.0;

  for (int i = 0; i < AURELIA_VCLOUD_STEPS; i++) {
    if (i >= n) {
      break;
    }

    float hn = wStart + (wEnd - wStart) * (float(i) + jitter) / nf;
    float height = AURELIA_CLOUD_ALTITUDE + AURELIA_VCLOUD_THICKNESS * hn;
    highp vec2 cell = floor((camXZ + dxz * height + wind) * invCell);
    float shape = mix(aureliaNoise(cell * AURELIA_VCLOUD_CLUMP_SCALE), aureliaHash(cell), AURELIA_VCLOUD_ROUGH);
    float density = step(thr, shape);
    float alpha = density * (1.0 - alphaAccum) * alphaStep;

    cloudAccum += smoothstep(0.2, 0.9, hn) * alpha;
    alphaAccum += alpha;

    if (alphaAccum > 0.98) {
      break;
    }
  }

  if (alphaAccum < 0.003) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  float top = clamp(cloudAccum / alphaAccum / 0.6, 0.0, 1.0);

  float dayF = smoothstep(-0.06, 0.28, sunDir.y);
  float twi = dayF * (1.0 - smoothstep(0.1, 0.45, sunDir.y));
  vec3 sunCol = mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.97, 0.9), smoothstep(0.0, 0.45, sunDir.y));

  vec3 col = AURELIA_CLOUD_FLAT_COLOR * mix(AURELIA_VCLOUD_SHADE, 1.0, top);
  col *= mix(0.08, 1.0, dayF);
  col *= mix(vec3_splat(1.0), sunCol, twi * 0.7);
  col *= 1.0 - AURELIA_CLOUD_RAIN_DARK * aureliaRain * 0.6;
  col = mix(fogColor, col, 0.4 + 0.6 * smoothstep(0.0, 0.35, up));

  float a = alphaAccum * mix(AURELIA_CLOUD_OPACITY, 1.0, aureliaRain);
  return vec4(col, a);
}

#endif
