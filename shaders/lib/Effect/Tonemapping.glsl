#ifndef EFFECT_TONEMAPPING_GLSL
#define EFFECT_TONEMAPPING_GLSL 1

// http://filmicworlds.com/blog/filmic-tonemapping-operators/
// https://www.shadertoy.com/view/lslGzl 

#include "../Utility/ColorAdjust.glsl"

// Only use in HDR
vec3 ComputeHighDynamicRangeExposure(in vec3 color, in float exposure){
	return 1.0f - exp(-exposure * color);
}

// I'm not a big fan of reinhard tonemapping, especially x / (1+x)
// It takes away your deep blacks and saturation
// And each color seems to get increasingly white but never seems to have that property of being white
// Which makes it look like Minecraft xbox edition
vec3 ComputeTonemapReinhard(in vec3 color){
    return color / (color + 1.0f);
}

vec3 ComputeTonemapFilmic(vec3 color) {
	color = max(vec3(0.), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec3 ComputeTonemapFilmicACES(vec3 color) {
    return clamp((color*(2.51f*color+0.03f))/(color*(2.43f*color+0.59f)+0.14f), vec3(0.0f), vec3(1.0f));
}

vec3 ComputeTonemapUncharted2(vec3 color) {
	float A = 0.15f;
	float B = 0.50f;
	float C = 0.10f;
	float D = 0.20f;
	float E = 0.02f;
	float F = 0.30f;
	float W = 11.2f;
	float exposure = 2.0f;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	return color;
}

vec3 ComputeTonemapRomBinDaHouse(vec3 color) {
    color = exp( -1.0 / ( 2.72*color + 0.15 ) );
	return color;
}

vec3 ComputeTonemapLumaReinhard(vec3 color) {
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma / (1. + luma);
	color *= toneMappedLuma / luma;
	return color;
}

vec3 ComputeTonemapWhiteLumaReinhard(vec3 color) {
	float white = 2.;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
	color *= toneMappedLuma / luma;
	return color;
}

vec3 ComputeTonemapSmooth(in vec3 color){
    return pow(smoothstep(vec3(0.0f), vec3(1.0f), color), vec3(0.55f));
}

vec3 ComputeTonemapConvergence(in vec3 color){
	return mix(pow(color, vec3(0.707f)), color * color, color);
}

// // #define TONEMAPPING_OPERATOR 5 // [0 1 2 3 4 5 6 7 8 9]
#define TONEMAPPING_OPERATOR 0 // [0 1]

// TODO:
// - Add tonemaps from this shadertoy https://www.shadertoy.com/view/4dBcD1 
// - Add other tonemaps
// - Write my own tonemaps
// The goal of these TODOs is to give the user an ability to choose the looks of the shader they like
// After all, shaders are very subjective and the tonemap is a big decieder in who likes the shader
// Some people like super saturated looks, others don't
// I, myself, perfer saturated looks

vec3 ComputeTonemap(in vec3 color){
	//return color;
	/*
    #if TONEMAPPING_OPERATOR == 0
    return color;
    #elif TONEMAPPING_OPERATOR == 1
	// This helps regain some saturation
    return ComputeTonemapReinhard(Saturation(color * 1.9f, 1.1f));
    #elif TONEMAPPING_OPERATOR == 2
    return ComputeTonemapLumaReinhard(color * 3.0f);
    #elif TONEMAPPING_OPERATOR == 3
    return ComputeTonemapWhiteLumaReinhard(color);
    #elif TONEMAPPING_OPERATOR == 4
    return ComputeTonemapFilmic(color);
    #elif TONEMAPPING_OPERATOR == 5
    return ComputeTonemapFilmicACES(color);
    #elif TONEMAPPING_OPERATOR == 6
    return ComputeTonemapUncharted2(color);
    #elif TONEMAPPING_OPERATOR == 7
    return ComputeTonemapRomBinDaHouse(color);
    #elif TONEMAPPING_OPERATOR == 8
    return ComputeTonemapSmooth(color);
    #elif TONEMAPPING_OPERATOR == 9
	return ComputeTonemapConvergence(color);
    #endif 
	*/
	/*
	vec3 FilmicACES = ComputeTonemapFilmicACES(color);
	return FilmicACES;
	color = ComputeHighDynamicRangeExposure(color, 2.0f);
	vec3 Reinhard = ComputeTonemapWhiteLumaReinhard(color);
	return mix(FilmicACES, Reinhard, 0.2f);
	*/
	#if TONEMAPPING_OPERATOR == 0
	return ComputeTonemapFilmicACES(color);
	#elif TONEMAPPING_OPERATOR == 1
	return  ComputeTonemapWhiteLumaReinhard(color);
	#endif
}

float Grayscale(in vec3 c){
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
}

#endif