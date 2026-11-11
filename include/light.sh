#ifndef AURELIA_LIGHT_H
#define AURELIA_LIGHT_H

#include <config.sh>

float aureliaLuma(vec3 c) {
  return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

bool aureliaIsNether(vec3 fogColor, vec2 fogControl) {
  float expectedFogX = 0.029 + 0.09 * fogControl.y * fogControl.y;
  bool netherFogCtrl = fogControl.x < 0.14 && abs(fogControl.x - expectedFogX) < 0.02;
  bool netherFogCol = (fogColor.r + fogColor.g) > 0.0;
  bool underLava = fogControl.x == 0.0 && fogColor.b == 0.0 && fogColor.g < 0.18 && fogColor.r - fogColor.g > 0.1;
  return (netherFogCtrl && netherFogCol) || underLava;
}

bool aureliaIsEnd(vec3 fogColor) {
  return fogColor.r == fogColor.b && (fogColor.r - fogColor.g > 0.24 || (fogColor.g == 0.0 && fogColor.r > 0.1));
}

vec4 aureliaTorchSetup(bool isEnd, bool isNether, bool underwater) {
  vec4 t = vec4(AURELIA_TORCH_COLOR, AURELIA_TORCH_INTENSITY);
  if (underwater) {
    t = vec4(AURELIA_TORCH_COLOR_UW, AURELIA_TORCH_INTENSITY_UW);
  }
  if (isNether) {
    t = vec4(AURELIA_TORCH_COLOR_NETHER, AURELIA_TORCH_INTENSITY_NETHER);
  }
  if (isEnd) {
    t = vec4(AURELIA_TORCH_COLOR_END, AURELIA_TORCH_INTENSITY_END);
  }
  return t;
}

vec3 aureliaTorch(float uvx, vec4 torch) {
  float lit = uvx * uvx;
  float atten = torch.w * uvx / (0.5 - 0.45 * lit);
  return torch.rgb * atten;
}

vec3 aureliaLighting(sampler2D lm, vec2 uv, float sunUp, vec4 torch) {
  vec3 light = texture2D(lm, vec2(0.0, uv.y)).rgb;

  float skyShare = smoothstep(0.3, 1.0, uv.y);
  light *= mix(1.0, AURELIA_SUN_INTENSITY, skyShare * sunUp);
  light *= mix(vec3_splat(1.0), AURELIA_SUN_WARMTH, skyShare * sunUp);

  light += aureliaTorch(uv.x, torch) / (1.0 + aureliaLuma(light));

  return light;
}

vec3 aureliaEndLighting(float uvx, vec4 torch) {
  vec3 light = AURELIA_END_AMBIENT;
  light += aureliaTorch(uvx, torch) / (1.0 + aureliaLuma(light));
  return light;
}

#endif
