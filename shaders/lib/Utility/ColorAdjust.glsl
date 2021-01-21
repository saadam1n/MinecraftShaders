#ifndef UTILITY_COLOR_ADJUST_GLSL
#define UTILITY_COLOR_ADJUST_GLSL

#include "Uniforms.glsl"
#include "TextureSampling.glsl"
#include "../Internal/ShaderSettings.glsl"

// Based on KUDA 6.5.56
float Luma(vec3 color) {
	return dot(color, vec3(0.3333));
}

//Taken from https://github.com/CesiumGS/cesium/blob/master/Source/Shaders/Builtin/Functions/saturation.glsl
vec3 Saturation(vec3 rgb, float adjustment) {
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

//#define FILM_GRAIN

const float FilmGrainStrength = 0.00325f;

vec3 ComputeFilmGrain(in vec3 color){
	vec3 ColorOffset = (texture2D(noisetex,  gl_TexCoord[1].st).rag * 2.0f - 1.0f) * FilmGrainStrength;
	return max(color + ColorOffset, vec3(0.0f));
}

const float WaterDropletSpeed = 0.1f;
const float WaterSampleOffset = 0.0001f;

const float WaterDropletScale = 0.05f * 256.0f/float(noiseTextureResolution);
const vec3 WaterScreenChromaticAberation = vec3(0.5f, 1.0f, 1.5f);

vec2[3] ComputeWaterDropletCoords(void){
	vec2 NoiseCoords = gl_TexCoord[0].st;
	NoiseCoords.y += frameTimeCounter * WaterDropletSpeed;
	vec2 Noise = (BicubicTexture(noisetex, NoiseCoords * WaterDropletScale, noiseTextureResolution).rg * 2.0f - 1.0f) * 0.01f; // maybe add camera pos to create a moving effect while walking underwater
	Noise.g *= aspectRatio;
	vec2 Coords[3];
	Coords[0] = gl_TexCoord[0].st + Noise * WaterScreenChromaticAberation.r;
	Coords[1] = gl_TexCoord[0].st + Noise * WaterScreenChromaticAberation.g;
	Coords[2] = gl_TexCoord[0].st + Noise * WaterScreenChromaticAberation.b;
	return Coords;
}

float CalculateExposure(void){
	float EyeSkyLightMap = eyeBrightnessSmooth.y / 240.0f;
	float SkyExposure = mix(1.5f, 1.0f, EyeSkyLightMap) * 0.5f;
	return SkyExposure;
}

// Probably taken from contiuum tutorial
const float UnderExposure = 0.5f;
const float OverExposure = 1.5f;
vec3 HighDynamicRange(in vec3 color){
	color = min(color, vec3(1.0f));
	return mix(color * OverExposure, color * UnderExposure, color);
}

#endif