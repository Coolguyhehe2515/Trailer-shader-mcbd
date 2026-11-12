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
  float horizon = smoothstep(0.02, 0.3, up);
  if (horizon <= 0.0) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  highp vec2 world = camXZ + dir.xz / max(up, 0.02) * AURELIA_CLOUD_ALTITUDE + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED;

  float blockMix = smoothstep(0.12, 0.35, up);
  highp vec2 snapped = (floor(world / AURELIA_VCLOUD_CELL) + 0.5) * AURELIA_VCLOUD_CELL;
  highp vec2 p = mix(world, snapped, blockMix) * AURELIA_VCLOUD_SCALE;

  float shape = aureliaNoise(p) * (1.0 - AURELIA_VCLOUD_DETAIL) + aureliaNoise(p * 3.1 + vec2(13.0, 7.0)) * AURELIA_VCLOUD_DETAIL;

  float thr = AURELIA_VCLOUD_COVERAGE - aureliaRain * AURELIA_CLOUD_RAIN_GROW;
  float soft = mix(0.06, 0.002, blockMix);
  float density = smoothstep(thr, thr + soft, shape);

  if (density < 0.003) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  float edge = 1.0 - smoothstep(thr, thr + 0.1, shape);

  float dayF = smoothstep(-0.06, 0.28, sunDir.y);
  float twi = dayF * (1.0 - smoothstep(0.1, 0.45, sunDir.y));
  vec3 sunCol = mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.97, 0.9), smoothstep(0.0, 0.45, sunDir.y));

  vec3 col = AURELIA_CLOUD_FLAT_COLOR * mix(1.0, AURELIA_VCLOUD_SHADE, edge);
  col *= mix(0.08, 1.0, dayF);
  col *= mix(vec3_splat(1.0), sunCol, twi * 0.7);
  col *= 1.0 - AURELIA_CLOUD_RAIN_DARK * aureliaRain * 0.6;
  col = mix(fogColor, col, 0.4 + 0.6 * horizon);

  float a = density * horizon * mix(AURELIA_CLOUD_OPACITY, 1.0, aureliaRain);
  return vec4(col, a);
}

#endif
