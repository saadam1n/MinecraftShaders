#ifndef EFFECT_TONEMAPPING_GLSL
#define EFFECT_TONEMAPPING_GLSL 1

// http://filmicworlds.com/blog/filmic-tonemapping-operators/
// https://www.shadertoy.com/view/lslGzl 

// Only use 
vec3 ComputeHighDynamicRangeExposure(in vec3 color, in float exposure){
	return 1.0f - exp(-exposure * color);
}

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

#define TONEMAPPING_OPERATOR 5 // [0 1 2 3 4 5 6 7 8]

vec3 ComputeTonemap(in vec3 color){
    #if TONEMAPPING_OPERATOR == 0
    return color; // No tonemapping
    #elif TONEMAPPING_OPERATOR == 1
    return ComputeTonemapReinhard(color);
    #elif TONEMAPPING_OPERATOR == 2
    return ComputeTonemapFilmic(color);
    #elif TONEMAPPING_OPERATOR == 3
    return ComputeTonemapFilmicACES(color);
    #elif TONEMAPPING_OPERATOR == 4
    return ComputeTonemapUncharted2(color);
    #elif TONEMAPPING_OPERATOR == 5
    return ComputeTonemapRomBinDaHouse(color);
    #elif TONEMAPPING_OPERATOR == 6
    return ComputeTonemapLumaReinhard(color);
    #elif TONEMAPPING_OPERATOR == 7
    return ComputeTonemapWhiteLumaReinhard(color);
    #elif TONEMAPPING_OPERATOR == 8
    return ComputeTonemapSmooth(color);
    #endif 
}

#endif