#ifndef INTERNAL_SHADER_SETTINGS_GLSL
#define INTERNAL_SHADER_SETTINGS_GLSL 1

#define HARDWARE_SHADOW_FILTERING

const int shadowMapResolution = 2048; // The shadow resolution [256 512 1024 1572 2048 3072 4096 8192 16384]
const float shadowDistance = 128; // How large the shadow map is [16 32 64 72 96 128 180 256]

#define ShaderPrecision highp

precision ShaderPrecision int;
precision ShaderPrecision float;

#endif