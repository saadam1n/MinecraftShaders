#ifndef INTERNAL_OPTIFINE_SETTINGS_GLSL
#define INTERNAL_OPTIFINE_SETTINGS_GLSL 1

const float sunPathRotation = -40.0f;
const bool shadowHardwareFiltering = true;
const bool generateShadowMipmap = false;
const float shadowIntervalSize 	= 4.0; // The shadow interval [0.1 0.25 0.5 0.75 1.0 2.0 3.0 4.0 5.0 7.0 8.0]
const vec4 colortex2ClearColor = vec4(0.0f, 0.0f, 1.0f, 0.0f);
const float wetnessHalfLife = 600.0f;
const float drynessHalfLife = 200.0f;
const float eyeBrightnessHalflife = 15.0f;

#endif