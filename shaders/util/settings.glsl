#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL 1

#include "formats.glsl"

#define HARDWARE_SHADOW_FILTERING
//#define SOFT_SHADOWS
#ifdef SOFT_SHADOWS
#ifndef HARDWARE_SHADOW_FILTERING
#define HARDWARE_SHADOW_FILTERING
#endif
#endif

const int shadowMapResolution = 1024;
const float shadowDistance = 180.0f;
const float ShadowDistanceFadePercentage = 0.9f;
const float ShadowDistanceFade = shadowDistance * ShadowDistanceFadePercentage;
const float ShadowDistanceFadeLength = shadowDistance - ShadowDistanceFade;
const float sunPathRotation = -40.0f;
#ifdef HARDWARE_SHADOW_FILTERING
const bool 	shadowHardwareFiltering = true;
#else
const bool 	shadowHardwareFiltering = false;
#endif

const int colortex1Format = RGBA16;

#define SHADOW_MAP_BIAS 0.9	

const float ShadowQuality = 4.0f;
const float ShadowStep = 1.0f / ShadowQuality;

const float SoftShadowScale = 1.0f / shadowMapResolution;
#define SHADOW_SAMPLES 1.0f
const float ShadowSamplesTotal = (2*(ShadowQuality*SHADOW_SAMPLES)+1) *  (2*(ShadowQuality*SHADOW_SAMPLES)+1);

const int noiseTextureResolution = 64;

//#define SOFT_SHADOW_ROTATION

const bool generateShadowMipmap = false;
const float shadowIntervalSize 	= 8.0f;

const vec3 TorchEmitColor = vec3(0.9, 0.8, 0.6);

const float ShadowDepthCompressionFactor = 0.5f;

#endif