#ifndef INSTANCING
  $input v_worldPos
#endif

#include <bgfx_shader.sh>
#include <main.sh>

#ifndef INSTANCING
  #ifdef AURELIA_CLOUD_TEXTURE
    SAMPLER2D_AUTOREG(s_CloudNoise);
  #endif

  uniform vec4 TimeOfDay;
  uniform vec4 FogColor;
  uniform vec4 FogAndDistanceControl;
  uniform vec4 ViewPositionAndTime;
  uniform vec4 CameraPosition;
#endif

void main() {
  #ifndef INSTANCING
    aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);

    vec3 dir = normalize(v_worldPos);
    vec3 sunDir = aureliaSunDir(TimeOfDay.x);

    vec3 sky = aureliaSkyColor(dir, FogColor.rgb, sunDir);
    bool underwater = aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz);

    if (underwater) {
      sky = aureliaUnderwaterFog(FogColor.rgb);

      #ifdef AURELIA_GODRAYS
        sky += aureliaUnderwaterRays(dir, sunDir, ViewPositionAndTime.w, 80.0);
      #endif

      sky *= AURELIA_UW_BRIGHTNESS;
    } else {
      #ifdef AURELIA_GODRAYS
        sky += aureliaGodrays(dir * AURELIA_GODRAY_SKY_SIGN, sunDir, CameraPosition.xz, ViewPositionAndTime.w);
      #endif
    }

    vec3 outCol = aureliaColorGrade(sky);

    if (!underwater) {
      vec3 horizonCol = aureliaSkyHorizon(vec3(0.45, 0.5, 0.56), sunDir);
      vec4 c = aureliaCloudsVolume(dir, CameraPosition.xz, ViewPositionAndTime.w, sunDir, horizonCol);
      outCol = mix(outCol, aureliaColorGrade(c.rgb), c.a);
    }

      #ifdef AURELIA_CLOUD_TEXTURE
        vec4 c = aureliaCloudsRawTex(s_CloudNoise, dir, CameraPosition.xz, ViewPositionAndTime.w, sunDir, horizonCol, 0.0);
      #else
        vec4 c = aureliaCloudsRaw(dir, CameraPosition.xz, ViewPositionAndTime.w, sunDir, horizonCol, 0.0);
      #endif

      outCol = mix(outCol, aureliaColorGrade(c.rgb), c.a);
    }

    gl_FragColor = vec4(outCol, 1.0);
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
