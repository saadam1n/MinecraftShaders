#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL 1

#include "formats.glsl"

const int shadowMapResolution = 2048; // The shadow resolution [256 512 1024 2048 4096]
const float shadowDistance = 120.0f;
const float ShadowDistanceFadePercentage = 0.9f;
const float ShadowDistanceFade = shadowDistance * ShadowDistanceFadePercentage;
const float ShadowDistanceFadeLength = shadowDistance - ShadowDistanceFade;
const float sunPathRotation = -40.0f;
const bool shadowHardwareFiltering = true;

const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16;

#define SHADOW_MAP_BIAS 0.9	

const float SoftShadowScale = 0.5f / shadowMapResolution;
#define SHADOW_SAMPLES 2.0f // Defines how large the shadows are. [1.0f 2.0f 3.0f 4.0f]
const float ShadowSamplesPerSide = (2*(SHADOW_SAMPLES)+1);
const float ShadowSamplesTotal = ShadowSamplesPerSide *  ShadowSamplesPerSide;
#define SHADOW_QUALITY 1.0f // Defines how smooth the shadows are. [1.0f 2.0f 3.0f 4.0f]
const float ShadowStep = 1.0f / SHADOW_QUALITY;
const float ShadowQualitySamplesPerSide =  (2*(SHADOW_SAMPLES * SHADOW_QUALITY)+1);
const float ShadowQualityArea = ShadowQualitySamplesPerSide * ShadowQualitySamplesPerSide;
const float ShadowArea = ShadowSamplesPerSide * ShadowSamplesPerSide;

const int noiseTextureResolution = 64;

const bool generateShadowMipmap = false;
const float shadowIntervalSize 	= 4.0f;

// Taken from KUDA 6.5.56
const vec3 TorchEmitColor = vec3(1.0, 0.57, 0.3);;

const float ShadowDepthCompressionFactor = 1.0f;

const vec4 colortex5ClearColor = vec4(0.0f, 0.0f, 0.0f, 1.0f);

#define SHIFTING_RAIN_AMPLITUDE 1.5f
#define WEATHER_DENSITY 1.0f // How fast and small weather particles (rain and snow) are [0.25f 0.5f 0.75f 1.0f 1.25f 1.5f 1.75 2.0f]

const float wetnessHalfLife = 0.0001f;
const float drynessHalfLife = 0.0001f;

#define BLOOM_THRESHOLD 0.5f
#define BLOOM_SAMPLES 16.0f

const float BloomSamplesPerSide = (2.0f * BLOOM_SAMPLES + 1.0f);
const float BloomStandardDeviation = BloomSamplesPerSide - 10.0f;

#endif