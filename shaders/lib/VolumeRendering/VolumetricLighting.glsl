#ifndef VOLUME_RENDERING_VOLUMETRIC_LIGHTING_GLSL
#define VOLUME_RENDERING_VOLUMETRIC_LIGHTING_GLSL 1

#include "../Transform/Eye.glsl"
#include "../Transform/Distort.glsl"
#include "../Random/Noise3D.glsl"
#include "../Shading/Shadow.glsl"

// TOOD:
// Updated VL using actual papers instead of doing it myself
// Posible sources:
// https://developer.nvidia.com/gpugems/gpugems3/part-ii-light-and-shadows/chapter-13-volumetric-light-scattering-post-process 
// https://software.intel.com/content/www/us/en/develop/articles/ivb-atmospheric-light-scattering.html 
// http://citeseerx.ist.psu.edu/viewdoc/download;jsessionid=6F0D486CFF38486898A53648D1DE71D6?doi=10.1.1.230.2900&rep=rep1&type=pdf
// http://liu.diva-portal.org/smash/get/diva2:449126/FULLTEXT01.pdf 
// https://research.ijcaonline.org/volume108/number11/pxc3900275.pdf 
// I'll work on this an VL clouds tmrw

const float VolumetricLightingScattering = 0.1f;
const float VolumetricLightingAbsorption = 0.0f;
const float VolumetricLightingExtinction = VolumetricLightingScattering + VolumetricLightingAbsorption;
const float VolumetricLightingScaleHeight = 10.0f;
const float VolumetricLightingHeightOffset = -56.0f;
const float VolumetricLightingMinHeight = 0.0f;

//#define VARYING_VOLUMETRIC_LIGHTING // Applies noise to the VL density function

#define VOLUMETRIC_LIGHTING
#define VOLUMETRIC_LIGHTING_STEPS 64.0f
#define VOLUMETRIC_OPTICAL_DEPTH_STEPS 64.0f

const float VolumetricLightingStandardDeviation = 5.0f;

// Computes in shadow clip space
void ComputeVolumetricLighting(inout SurfaceStruct Surface, inout ShadingStruct Shading, in vec3 sundir, in vec3 suncolor, in vec3 eyePosWorld = GetEyePositionWorld(), in vec3 eyePosShadow = GetEyePositionShadow()){
    #ifdef VOLUMETRIC_LIGHTING
    vec3 WorldStep = (Surface.World - eyePosWorld) / VOLUMETRIC_LIGHTING_STEPS;
    float WorldStepLength = length(WorldStep);
    vec3 WorldDirection = WorldStep / WorldStepLength;
    vec3 toEye = Surface.ShadowClip - eyePosShadow;
    vec3 StepSize = (toEye) / VOLUMETRIC_LIGHTING_STEPS;
    vec3 StepDirection = normalize(StepSize);
    float StepLength = length(StepSize);
    float ScatteredLight = VolumetricLightingScattering * PhaseHenyeyGreenstein(dot(sundir, WorldDirection), -0.6f);
    vec3 VolumetricLightingAccum = vec3(0.0f);
    // TODO: precompute this in vert shader
    // Media properties don't change, the density does
    // That's why I'm not changing the coefficents
    float DensityFactor = mix(1.0f, 7.0f, rainStrength);
    vec3 AccumOpticalDepth = vec3(0.0f);
    vec3 LightOpticalDepth = vec3(0.0f);
    for(float Step = 0.0f; Step < VOLUMETRIC_LIGHTING_STEPS; Step++){
        vec3 SamplePositionShadow = eyePosShadow + StepSize * Step;
        SamplePositionShadow = DistortShadow(SamplePositionShadow) * 0.5f + 0.5f;
        vec3 SamplePositionWorld = eyePosWorld + WorldStep * Step;
        #ifdef VARYING_VOLUMETRIC_LIGHTING
        float Density = exp(-max(SamplePositionWorld.y + VolumetricLightingHeightOffset, VolumetricLightingMinHeight) / VolumetricLightingScaleHeight) * DensityFactor
                      * pow(Get3DNoise(SamplePositionWorld + frameTimeCounter), 1.2f);
        #else
        float Density = exp(-max(SamplePositionWorld.y + VolumetricLightingHeightOffset, VolumetricLightingMinHeight) / VolumetricLightingScaleHeight) * DensityFactor;
        #endif
        AccumOpticalDepth += vec3(Density * VolumetricLightingExtinction * WorldStepLength);
        vec3 Transmittance = exp(-AccumOpticalDepth);
        vec3 VolumetricLighting = ComputeVisibility(SamplePositionShadow) * Density * Transmittance;
        VolumetricLightingAccum += VolumetricLighting;
    }
    VolumetricLightingAccum = VolumetricLightingAccum * ScatteredLight * WorldStepLength * suncolor;
    // TODO: multiply it by a good phase function for VL (not mie, that just made it look worse)
    Shading.Volumetric = VolumetricLightingAccum;
    Shading.OpticalDepth = AccumOpticalDepth * WorldStepLength;
    #else
    Shading.Volumetric = vec3(0.0f);
    Shading.OpticalDepth =  vec3(0.0f);
    #endif
}

// Approximation based on LVutner's implementation 
// Some stuff was also taken from VOID 2.0 Dev 
#define VL_APPROX_SAMPLES 32
#define VL_APPROX_STEP_LENGTH
vec2 JitterScale = ScreenSize / noiseTextureResolution;
#ifdef VL_APPROX_STEP_LENGTH
vec3 ComputeVolumetricLightingApprox(in vec3 playerpos, in vec3 viewpos, in vec3 col, out vec3 OpticalDepth)
#else
vec3 ComputeVolumetricLightingApprox(in vec3 playerpos, in vec3 viewpos, in vec3 col)
#endif
 {
    #ifndef VL_APPROX_STEP_LENGTH
    const vec3 Scatter = vec3(0.6f);
    #else
    const vec3 Scatter = vec3(0.05f);
    #endif
    float Jitter = 0.1f * (texture2D(noisetex, JitterScale * gl_TexCoord[0].st).r * 2.0f - 1.0f);
    mat4 ShadowTransform = shadowProjection * shadowModelView;
    vec3 EyePosition = gbufferModelViewInverse[3].xyz;
    vec3 Segment = playerpos - EyePosition;
    vec3 Direction = normalize(Segment);
    float Phase = PhaseHenyeyGreenstein(dot(Direction, LightDirection), -0.16f);
    float Position = Jitter;
    float StepLength = length(Segment) / VL_APPROX_SAMPLES;
    vec3 Accum = vec3(0.0f);
    for(int sample = 0; sample < VL_APPROX_SAMPLES; sample++){
        vec3 SamplePosition = EyePosition + Direction * (Position + 0.5f * StepLength);
        float Density = exp(-max(SamplePosition.y + cameraPosition.y - 64.0f, 0.0f) / 10.0f);
        SamplePosition = (ShadowTransform * vec4(SamplePosition, 1.0f)).xyz;
        SamplePosition = DistortShadowSample(SamplePosition);
        #ifdef VL_APPROX_STEP_LENGTH
        OpticalDepth += Density * Scatter * StepLength;
        vec3 Transmittance = exp(-OpticalDepth);
        #else
        vec3 Transmittance = vec3(1.0f);
        #endif
        Accum += ComputeVisibility(SamplePosition) * Transmittance * Density;
        Position += StepLength;
    }
    #ifndef VL_APPROX_STEP_LENGTH
    Accum /= VL_APPROX_SAMPLES;
    #else
    Accum *= StepLength;
    #endif
    vec3 VL = Scatter * Phase * col * Accum;
    return VL;
}

#endif