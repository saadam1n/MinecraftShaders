#ifndef SHADING_LIGHT_GLSL 
#define SHADING_LIGHT_GLSL 1

#include "Structures.glsl"
#include "Shadow.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../VolumeRendering/Sky.glsl"
#include "../Misc/Masks.glsl"

vec3 GetSunMoonDirection(in vec3 viewPos){
    return normalize(mat3(gbufferModelViewInverse) * viewPos);
}

vec3 GetLightColor(void){
    vec3 SunDirection = GetSunMoonDirection(sunPosition);
    vec3 SunColor = ComputeSunColor(SunDirection, SunDirection) + ComputeAtmosphereColor(SunDirection, SunDirection);
    vec3 MoonColor = vec3(0.1f, 0.15f, 0.9f);
    return saturate(SunColor * 0.7f);
}

vec3 GetLightDirection(void) {
    return normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
}

vec3 CalculateSunShading(in SurfaceStruct Surface, in vec3 sun, in MaskStruct masks){
    return (masks.Plant ? 1.0f : Surface.NdotL) * sun * ComputeShadow(Surface) * vec3(0.84f, 0.87f, 0.795f);
}

#endif