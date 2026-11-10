#ifndef AURELIA_TONEMAP_H
#define AURELIA_TONEMAP_H

#include <config.sh>

vec3 aureliaTonemap(vec3 x) {
  return clamp(x * (1.0 + x * AURELIA_WHITE_SCALE) / (1.0 + x), 0.0, 1.0);
}

vec3 aureliaSaturate(vec3 c, float s) {
  float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
  return mix(vec3_splat(l), c, s);
}

vec3 aureliaColorGrade(vec3 c) {
  c *= c;
  c *= AURELIA_EXPOSURE;
  c = aureliaTonemap(c);
  c = sqrt(c);

  float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
  c *= mix(AURELIA_GRADE_SHADOW, AURELIA_GRADE_HIGHLIGHT, smoothstep(0.2, 0.8, l));

  float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
  c = mix(vec3_splat(l), c, 1.0 + AURELIA_VIBRANCE * (1.0 - clamp(sat, 0.0, 1.0)));

  c = clamp(c, 0.0, 1.0);
  c = mix(c, c * c * (3.0 - 2.0 * c), AURELIA_GRADE_CONTRAST);

  return aureliaSaturate(c, AURELIA_SATURATION);
}

#endif
