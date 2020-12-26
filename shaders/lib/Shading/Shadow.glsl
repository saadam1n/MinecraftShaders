#ifndef SHADING_SHADOW_GLSL
#define SHADING_SHADOW_GLSL

#include "Structures.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../Internal/ShaderSettings.glsl"
#include "../Random/Noise2D.glsl"

const float SoftShadowScale = 0.5f / shadowMapResolution;
#define SHADOW_SAMPLES 2.0f // Defines how large the shadows are. [1.0f 2.0f 3.0f 4.0f]
const float ShadowSamplesPerSide = (2*(SHADOW_SAMPLES)+1);
const float ShadowSamplesTotal = ShadowSamplesPerSide *  ShadowSamplesPerSide;
#define SHADOW_QUALITY 1.0f // Defines how smooth the shadows are. [1.0f 2.0f 3.0f 4.0f]
const float ShadowStep = 1.0f / SHADOW_QUALITY;
const float ShadowQualitySamplesPerSide =  (2*(SHADOW_SAMPLES * SHADOW_QUALITY)+1);
const float ShadowQualityArea = ShadowQualitySamplesPerSide * ShadowQualitySamplesPerSide;
const float ShadowArea = ShadowSamplesPerSide * ShadowSamplesPerSide;

const float FadeBegin = 0.9f;
const float FadeEnd = 1.0f - FadeBegin;

vec3 FadeShadowColor(in vec3 color, in SurfaceStruct Surface){
    float len = length(Surface.View);
    float Fade = clamp(len - shadowDistance * FadeBegin, 0.0f, FadeEnd * shadowDistance);
    Fade /= FadeEnd * shadowDistance;
    return mix(color, vec3(1.0f), Fade);
}

vec3 PostProcessShadow(in vec3 color, in SurfaceStruct Surface){
    color = FadeShadowColor(color, Surface);
    return mix(color, vec3(0.0f), rainStrength);
}

vec3 ComputeVisibility(in vec3 ShadowCoord){
    float ShadowVisibility0 = shadow2D(shadowtex0, ShadowCoord, 0).r;
    float ShadowVisibility1 = shadow2D(shadowtex1, ShadowCoord, 0).r;
    vec4 ShadowColor0 = texture2D(shadowcolor0, ShadowCoord.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * ShadowColor0.a;
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}

vec3 ComputeShadow(in SurfaceStruct Surface){
    if(rainStrength > 0.99f){
        return vec3(0.0f);
    }
    if(!IsInRange(Surface.ShadowScreen, vec3(0.0f), vec3(1.0f))){
        return vec3(1.0f);
    }
    float DiffThresh = length(Surface.ShadowScreen.xy) + 0.10f;
    DiffThresh *= 3.0f / (shadowMapResolution / 2048.0f);
    float AdjustedShadowDepth = Surface.ShadowScreen.z - max(0.0028f * DiffThresh * (1.0f - Surface.NdotL) * Surface.Distortion * Surface.Distortion, 0.00015f) * 2.0f;
    mat2 Transformation = CreateRandomRotationScreen(Surface.Screen.xy + frameTimeCounter) * SoftShadowScale;
    vec3 ShadowAccum = vec3(0.0f);
    for(float y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y += ShadowStep){
        for(float x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x+= ShadowStep){
            ShadowAccum += ComputeVisibility(vec3(Surface.ShadowScreen.xy + vec2(x, y) * Transformation, AdjustedShadowDepth));
        }
    }
    ShadowAccum *= 1.0f / ShadowQualityArea;
    return PostProcessShadow(ShadowAccum, Surface);
}

#endif