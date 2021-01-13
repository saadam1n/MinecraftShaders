#ifndef SHADING_SHADOW_GLSL
#define SHADING_SHADOW_GLSL

#include "Structures.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../Random/Noise2D.glsl"

const float SoftShadowScale = 1.0f / shadowMapResolution;
#define SHADOW_SAMPLES 2.0 // Defines how large the shadows are. [0.0 1.0 2.0 3.0 4.0]
const float ShadowSamplesPerSide = (2*(SHADOW_SAMPLES)+1);
const float ShadowSamplesTotal = ShadowSamplesPerSide *  ShadowSamplesPerSide;
#define SHADOW_QUALITY 1.0 // Defines how smooth the shadows are. [1.0 2.0 3.0 4.0]
const float ShadowStep = 1.0f / SHADOW_QUALITY;
const float ShadowQualitySamplesPerSide =  (2*(SHADOW_SAMPLES * SHADOW_QUALITY)+1);
const float ShadowQualityArea = ShadowQualitySamplesPerSide * ShadowQualitySamplesPerSide;
const float ShadowArea = ShadowSamplesPerSide * ShadowSamplesPerSide;

const float FadeBegin = 0.95f;
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

const float ShadowLOD = 0.0f;

#define SMOOTH_SHADOW_FILTERING
// Hardware shadow filtering is just a bilinear filter of the shadow map

float HardShadow(in sampler2D depth, in vec3 p, in float lod = 0.0f){
    return step(p.z, texture2DLod(depth, p.xy, lod).r);
}

vec3 CalculateShadow(in vec3 ShadowCoord){
    float ShadowVisibility0 = HardShadow(shadowtex0, ShadowCoord, ShadowLOD);
    float ShadowVisibility1 = HardShadow(shadowtex1, ShadowCoord, ShadowLOD);
    vec4 ShadowColor0 = texture2DLod(shadowcolor0, ShadowCoord.xy, ShadowLOD);
    vec3 TransmittedColor = ShadowColor0.rgb * (1.0f - ShadowColor0.a); // Perform a blend operation with the sun color
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}

vec3 CalculateShadow(in vec2 coord, in float depth){
    return CalculateShadow(vec3(coord, depth));
}

vec3 ComputeVisibility(in vec3 ShadowCoord){
    const float Offset = 0.5f / shadowMapResolution;
    vec2 ClosestTexel = Round(ShadowCoord.xy * shadowMapResolution) / shadowMapResolution;
    vec2 Offsets[4];
    Offsets[0] = vec2(ClosestTexel.x + Offset, ClosestTexel.y + Offset);
    Offsets[1] = vec2(ClosestTexel.x - Offset, ClosestTexel.y - Offset);
    Offsets[2] = vec2(ClosestTexel.x + Offset, ClosestTexel.y - Offset);
    Offsets[3] = vec2(ClosestTexel.x - Offset, ClosestTexel.y + Offset);
    vec3 ShadowResults[4]; 
    ShadowResults[0] = CalculateShadow(Offsets[0], ShadowCoord.z);
    ShadowResults[1] = CalculateShadow(Offsets[1], ShadowCoord.z);
    ShadowResults[2] = CalculateShadow(Offsets[2], ShadowCoord.z);
    ShadowResults[3] = CalculateShadow(Offsets[3], ShadowCoord.z);
    vec2 ShadowInterpolationFactors;
    ShadowInterpolationFactors.x = (Offsets[0].x - ShadowCoord.x) * shadowMapResolution;
    ShadowInterpolationFactors.y = (Offsets[0].y - ShadowCoord.y) * shadowMapResolution;
    // Make the texture filtering more "exponential
    #ifdef SMOOTH_SHADOW_FILTERING
    ShadowInterpolationFactors = smoothstep(vec2(0.0f), vec2(1.0f), ShadowInterpolationFactors);
    #endif
    vec3 ShadowInterpolateX[2];
    ShadowInterpolateX[0] = mix(ShadowResults[0], ShadowResults[3],ShadowInterpolationFactors.x);
    ShadowInterpolateX[1] = mix(ShadowResults[2], ShadowResults[1],ShadowInterpolationFactors.x);
    vec3 ShadowInterpolateY = mix(ShadowInterpolateX[0], ShadowInterpolateX[1], ShadowInterpolationFactors.y);
    return ShadowInterpolateY;
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
    float AdjustedShadowDepth = Surface.ShadowScreen.z - max(0.0028f * DiffThresh * ((1.0f - pow(Surface.NdotL, 0.01f)) * 3.0f) * Surface.Distortion * Surface.Distortion, 0.00015f) * 2.0f;
    mat2 Transformation = CreateRandomRotationScreen(Surface.Screen.xy + frameTimeCounter * 0.01f) * SoftShadowScale; // add frameTimeCounter if you want animated noise
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