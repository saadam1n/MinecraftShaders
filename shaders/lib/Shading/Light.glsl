#ifndef SHADING_LIGHT_GLSL 
#define SHADING_LIGHT_GLSL 1

#include "Structures.glsl"
#include "Shadow.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../VolumeRendering/Sky.glsl"
#include "../Misc/Masks.glsl"

// Credit to xirreal for finding these values
const int DayEnd = 12785;
const int NightEnd = 23215;

bool isNight = worldTime < NightEnd && worldTime > DayEnd;
bool isDay = !isNight;

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

#define VIBRANT_SUN_LIGHTING

// TODO: optimize this and make it better
vec3 GetLightColor(void){
    vec3 SunDirection = GetSunMoonDirection(sunPosition);
    // My guess for why materials don't look white during the day is because
    // their BRDF is very low
    // But I only use a simple cosTheta diffuse BRDF
    // So I must multiply by 0.1f here
    vec3 SunColor = ComputeSunColor(SunDirection, SunDirection) + ComputeAtmosphereColor(SunDirection, SunDirection);
    #ifndef DEFERRED1
    #ifdef VIBRANT_SUN_LIGHTING
    SunColor *= 0.35f * vec3(0.8f, 0.9f, 1.1f);
    #else
    SunColor *= 0.025f * vec3(0.8f, 0.9f, 1.1f);
    #endif
    #endif
    //SunColor = saturate(SunColor); 
    if(isDay){
        return SunColor;
    } else{
        return MoonColor;
    }
}

vec3 GetLightDirection(void) {
    return normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
}

vec3 CalculateSunShading(in SurfaceStruct Surface, in vec3 sun, in MaskStruct masks){
    return (masks.Plant ? 1.0f : Surface.NdotL) * sun * ComputeShadow(Surface);
}

#endif