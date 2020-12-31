#ifndef UTILITY_COLOR_ADJUST_GLSL
#define UTILITY_COLOR_ADJUST_GLSL

#include "Uniforms.glsl"
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

vec2 ComputeWaterDropletCoords(void){
	vec2 WaterSampleCoords = vec2(gl_TexCoord[0].s, gl_TexCoord[0].t + WaterDropletSpeed * frameTimeCounter);
	// Now compute an offset
	float WaterCenter = texture2D(noisetex, WaterSampleCoords).a;
	float WaterLeft =  texture2D(noisetex, vec2(WaterSampleCoords.x - WaterSampleOffset, WaterSampleCoords.y)).a;
	float WaterUp = texture2D(noisetex, vec2(WaterSampleCoords.x, WaterSampleCoords.y + WaterSampleOffset * 4.0f)).a;
	vec2 WaterCoords = gl_TexCoord[0].st;
	if((WaterCenter + WaterLeft + WaterUp) / 3.0f > 0.2f){
		vec3 WaterNormal;
		WaterNormal.r = WaterCenter - WaterLeft;
		WaterNormal.g = WaterCenter - WaterUp;
		WaterNormal.b = sqrt(1.0f - dot(WaterNormal.rg, WaterNormal.rg));
		WaterNormal = normalize(WaterNormal);
		WaterCoords += WaterNormal.xz / 50.0f;
	}
	return mix(gl_TexCoord[0].st, WaterCoords, rainStrength);
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