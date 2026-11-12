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

float aureliaCloudShape(highp vec2 cell) {
  highp vec2 p = (cell + 0.5) * (AURELIA_VCLOUD_CELL * AURELIA_VCLOUD_SCALE);
  return aureliaNoise(p) * (1.0 - AURELIA_VCLOUD_DETAIL) + aureliaNoise(p * 3.1 + vec2(13.0, 7.0)) * AURELIA_VCLOUD_DETAIL;
}

vec4 aureliaCloudsVolume(vec3 dir, highp vec2 camXZ, highp float time, vec3 sunDir, vec3 fogColor) {
  #ifdef AURELIA_GEO_CLOUDS
    return vec4(0.0, 0.0, 0.0, 0.0);
  #endif
  float up = dir.y;
  float horizon = smoothstep(0.03, 0.3, up);
  if (horizon <= 0.0) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  float cellSize = AURELIA_VCLOUD_CELL;
  float tMax = AURELIA_VCLOUD_THICKNESS;
  float thr = AURELIA_VCLOUD_COVERAGE - aureliaRain * AURELIA_CLOUD_RAIN_GROW;

  highp vec2 dxz = dir.xz / max(up, 0.03);
  highp vec2 pc = (camXZ + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED + dxz * AURELIA_CLOUD_ALTITUDE) / cellSize;
  highp vec2 cell = floor(pc);

  vec2 stp = vec2(dxz.x >= 0.0 ? 1.0 : -1.0, dxz.y >= 0.0 ? 1.0 : -1.0);
  vec2 rate = abs(dxz) / cellSize + vec2(0.00001, 0.00001);
  vec2 dist = mix(pc - cell, cell + 1.0 - pc, step(0.0, stp));
  vec2 tNext = dist / rate;
  vec2 tStep = 1.0 / rate;

  float hit = 0.0;
  float shade = 1.0;

  float s0 = aureliaCloudShape(cell);
  if (s0 > thr) {
    hit = 1.0;
    shade = AURELIA_VCLOUD_BOTTOM;
  } else {
    for (int i = 0; i < AURELIA_VCLOUD_STEPS; i++) {
      bool useX = tNext.x < tNext.y;
      float t = useX ? tNext.x : tNext.y;
      if (t >= tMax) {
        break;
      }

      if (useX) {
        cell.x += stp.x;
        tNext.x += tStep.x;
      } else {
        cell.y += stp.y;
        tNext.y += tStep.y;
      }

      float s = aureliaCloudShape(cell);
      float thick = tMax * clamp(0.35 + (s - thr) * AURELIA_VCLOUD_DOME, 0.35, 1.0);

      if (s > thr && t < thick) {
        vec2 n = useX ? vec2(-stp.x, 0.0) : vec2(0.0, -stp.y);
        float lit = dot(n, vec2(0.7071, 0.7071)) * 0.5 + 0.5;
        shade = mix(AURELIA_VCLOUD_SHADE, 1.0, lit) * mix(0.88, 1.0, t / thick);
        hit = 1.0;
        break;
      }
    }
  }

  if (hit < 0.5) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  float dayF = smoothstep(-0.06, 0.28, sunDir.y);
  float twi = dayF * (1.0 - smoothstep(0.1, 0.45, sunDir.y));
  vec3 sunCol = mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.97, 0.9), smoothstep(0.0, 0.45, sunDir.y));

  vec3 col = AURELIA_CLOUD_FLAT_COLOR * shade;
  col *= mix(0.08, 1.0, dayF);
  col *= mix(vec3_splat(1.0), sunCol, twi * 0.7);
  col *= 1.0 - AURELIA_CLOUD_RAIN_DARK * aureliaRain * 0.6;
  col = mix(fogColor, col, 0.4 + 0.6 * horizon);

  float a = horizon * mix(AURELIA_CLOUD_OPACITY, 1.0, aureliaRain);
  return vec4(col, a);
}

#endif
