#ifndef AURELIA_STARS_H
#define AURELIA_STARS_H

#include <config.sh>

float aureliaStarTwinkle(vec3 pos, highp float time) {
  float p = dot(pos, vec3(0.9, 1.2, 0.6));
  float a = sin(time * AURELIA_STAR_SPEED + p);
  float b = sin(time * AURELIA_STAR_SPEED * 1.7 + p * 2.3);
  return max(1.0 + AURELIA_STAR_TWINKLE * 0.5 * (a + b), 0.0);
}

float aureliaShootOne(highp vec2 uv, highp float time, float seed) {
  highp float st = time / AURELIA_SHOOT_PERIOD + seed * 0.37;
  highp float id = floor(st);
  float f = fract(st) * AURELIA_SHOOT_PERIOD / AURELIA_SHOOT_DURATION;
  if (f > 1.0) {
    return 0.0;
  }

  vec2 r = vec2(aureliaHash(vec2(id, seed)), aureliaHash(vec2(id + 7.0, seed + 3.0)));
  float ang = aureliaHash(vec2(id + 13.0, seed)) * 6.2831853;
  vec2 d = vec2(cos(ang), sin(ang));

  vec2 head = (r - 0.5) * 3.0 + d * (f * 1.4);
  vec2 tailPt = head - d * AURELIA_SHOOT_TAIL;

  float t = clamp(dot(uv - tailPt, d) / AURELIA_SHOOT_TAIL, 0.0, 1.0);
  float dist = length(uv - (tailPt + d * AURELIA_SHOOT_TAIL * t));

  float width = AURELIA_SHOOT_WIDTH * (0.4 + 0.6 * t);
  float streak = 1.0 - smoothstep(0.0, width, dist);
  return streak * t * t * sin(f * 3.14159265);
}

vec3 aureliaShootingStars(vec3 dir, highp float time, vec3 sunDir) {
  float night = 1.0 - smoothstep(-0.12, 0.06, sunDir.y);
  float vis = night * smoothstep(0.12, 0.3, dir.y) * (1.0 - aureliaRain);
  if (vis <= 0.0) {
    return vec3(0.0, 0.0, 0.0);
  }

  highp vec2 uv = dir.xz / (dir.y + 0.25);

  float s = aureliaShootOne(uv, time, 1.0) + aureliaShootOne(uv, time, 2.0);
  return AURELIA_SHOOT_COLOR * s * vis * AURELIA_SHOOT_BRIGHTNESS;
}
#endif
