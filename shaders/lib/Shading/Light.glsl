#ifndef SHADING_LIGHT_GLSL 
#define SHADING_LIGHT_GLSL 1

#include "Structures.glsl"
#include "Shadow.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../VolumeRendering/Sky.glsl"
#include "../Misc/Masks.glsl"

// Credit to xirreal#0281 for finding these values
const int DayEnd = 12785;
const int NightEnd = 23251;

vec3 GetSunMoonDirection(in vec3 viewPos){
    return normalize(mat3(gbufferModelViewInverse) * viewPos);
}

float GetDayNightInterpolation(void){
    if(worldTime > DayEnd && worldTime < NightEnd){
        return 1.0f;
    } else {
        return 0.0f;
    }
}

// Do mix(Day, Night, DayNightInterpolation)
float DayNightInterpolation = GetDayNightInterpolation();

vec3 GetLightColor(void){
    vec3 SunDirection = GetSunMoonDirection(sunPosition);
    // My guess for why materials don't look white during the day is because
    // their BRDF is very low
    // But I only use a simple cosTheta diffuse BRDF
    // So I must multiply by 0.1f here
    vec3 SunColor = ComputeSunColor(SunDirection, SunDirection) + ComputeAtmosphereColor(SunDirection, SunDirection);
    SunColor *= 0.17f;
    vec3 MoonColor = vec3(0.1f, 0.15f, 0.9f);

    return SunColor;
}

vec3 GetLightDirection(void) {
    return normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
}

vec3 CalculateSunShading(in SurfaceStruct Surface, in vec3 sun, in MaskStruct masks){
    return (masks.Plant ? 1.0f : Surface.NdotL) * sun * ComputeShadow(Surface) * vec3(0.84f, 0.87f, 0.795f);
}

#endif