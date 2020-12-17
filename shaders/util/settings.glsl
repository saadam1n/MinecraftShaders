#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL 1

#include "formats.glsl"

const int shadowMapResolution = 1024;
const float shadowDistance = 180.0f;
const float ShadowDistanceFadePercentage = 0.9f;
const float ShadowDistanceFade = shadowDistance * ShadowDistanceFadePercentage;
const float ShadowDistanceFadeLength = shadowDistance - ShadowDistanceFade;
const float sunPathRotation = -40.0f;
const bool 	shadowHardwareFiltering = true;

const int colortex1Format = RGBA16;

#define SHADOW_MAP_BIAS 0.9	

const float SoftShadowScale = 1.0f / shadowMapResolution;
#define SHADOW_SAMPLES 1.0f
const float ShadowSamplesTotal = 4 * SHADOW_SAMPLES * SHADOW_SAMPLES;

const int noiseTextureResolution = 64;

//#define SOFT_SHADOW_ROTATION

const bool generateShadowMipmap = false;
const float shadowIntervalSize 	= 8.0f;

const vec3 TorchEmitColor = vec3(0.9, 0.8, 0.6);

#endif