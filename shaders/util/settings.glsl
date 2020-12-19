#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL 1

#include "formats.glsl"

const int shadowMapResolution = 2048;
const float shadowDistance = 120.0f;
const float ShadowDistanceFadePercentage = 0.9f;
const float ShadowDistanceFade = shadowDistance * ShadowDistanceFadePercentage;
const float ShadowDistanceFadeLength = shadowDistance - ShadowDistanceFade;
const float sunPathRotation = -40.0f;
const bool shadowHardwareFiltering = true;

const int colortex1Format = RGBA16;

#define SHADOW_MAP_BIAS 0.9	

const float SoftShadowScale = 0.5f / shadowMapResolution;
#define SHADOW_SAMPLES 2.0f
const float ShadowSamplesPerSide = (2*(SHADOW_SAMPLES)+1);
const float ShadowSamplesTotal = ShadowSamplesPerSide *  ShadowSamplesPerSide;
const float ShadowQuality = 2.0f;
const float ShadowStep = 1.0f / ShadowQuality;
const float ShadowQualitySamplesPerSide =  (2*(SHADOW_SAMPLES * ShadowQuality)+1);
const float ShadowQualityArea = ShadowQualitySamplesPerSide * ShadowQualitySamplesPerSide;
const float ShadowArea = ShadowSamplesPerSide * ShadowSamplesPerSide;

const int noiseTextureResolution = 64;

//#define SOFT_SHADOW_ROTATION

const bool generateShadowMipmap = true;
const float shadowIntervalSize 	= 4.0f;

const vec3 TorchEmitColor = vec3(0.9, 0.8, 0.6);

const float ShadowDepthCompressionFactor = 1.0f;

const vec4 colortex5ClearColor = vec4(0.0f, 0.0f, 0.0f, 1.0f);

#endif