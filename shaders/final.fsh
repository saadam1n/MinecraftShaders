#version 120

#include "util/commonfuncs.glsl"

//Taken from https://github.com/CesiumGS/cesium/blob/master/Source/Shaders/Builtin/Functions/saturation.glsl
vec3 Saturation(vec3 rgb, float adjustment) {
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}


vec3 FilmicToneMapping(vec3 color)
{
	color = max(vec3(0.), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec3 Uncharted2ToneMapping(vec3 color)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	float exposure = 2.;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	return color;
}

vec3 ACESFilmicTonemapping(vec3 color) {
    return clamp((color*(2.51f*color+0.03f))/(color*(2.43f*color+0.59f)+0.14f), vec3(0.0f), vec3(1.0f));
}

//#define DEBUG

#define FILM_GRAIN

const float FilmGrainStrength = 0.00325f;

vec3 ComputeFilmGrain(in vec3 color){
	vec3 ColorOffset = (texture2D(noisetex,  gl_TexCoord[1].st).rgb * 2.0f - 1.0f) * FilmGrainStrength;
	return max(color + ColorOffset, vec3(0.0f));
}

const float WaterDropletSpeed = 0.9f;
const float WaterSampleOffset = 0.0001f;

vec2 ComputeWaterDropletCoords(void){
	vec2 WaterSampleCoords = vec2(gl_TexCoord[0].s, gl_TexCoord[0].t + WaterDropletSpeed * frameTimeCounter) * 4.0f;
	// Now compute an offset
	float WaterCenter = PerlinNoise(WaterSampleCoords);
	float WaterLeft =  PerlinNoise(vec2(WaterSampleCoords.x - WaterSampleOffset, WaterSampleCoords.y));
	float WaterUp = PerlinNoise(vec2(WaterSampleCoords.x, WaterSampleCoords.y + WaterSampleOffset));
	vec2 WaterCoords = gl_TexCoord[0].st;
	if((WaterCenter + WaterLeft + WaterUp) / 3.0f > 0.2f){
		vec3 WaterNormal;
		WaterNormal.r = WaterCenter - WaterLeft;
		WaterNormal.g = WaterCenter - WaterUp;
		WaterNormal.b = sqrt(1.0f - length(WaterNormal.rg));
		WaterNormal = normalize(WaterNormal);
		WaterCoords += WaterNormal.xz / 50.0f;
	}
	return mix(gl_TexCoord[0].st, WaterCoords, rainStrength);
}

void main(){
	vec2 TexCoords = ComputeWaterDropletCoords();
    vec4 color = texture2D(colortex7, TexCoords);
	color.rgb = Saturation(color.rgb, 1.1f);
	//color.rgb *= 3.0f;
    //Apply tonemap 
	color.rgb = ACESFilmicTonemapping(color.rgb);
	#ifdef FILM_GRAIN
	color.rgb = ComputeFilmGrain(color.rgb);
	#endif
	#ifdef DEBUG
	color = texture2D(debugTex,  gl_TexCoord[0].st);
	#endif
	//color.rgb = vec3(PerlinNoise(TexCoords));
	color.rgb = pow(color.rgb, vec3(1.0f / 2.2f));
    gl_FragColor = color;
}