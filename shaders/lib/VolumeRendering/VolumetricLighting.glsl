#ifndef VOLUME_RENDERING_VOLUMETRIC_LIGHTING_GLSL
#define VOLUME_RENDERING_VOLUMETRIC_LIGHTING_GLSL 1

const float VolumetricLightingScattering = 0.1f;
const float VolumetricLightingAbsorption = 0.0f;
const float VolumetricLightingExtinction = VolumetricLightingScattering + VolumetricLightingAbsorption;
const float VolumetricLightingScaleHeight = 10.0f;
const float VolumetricLightingHeightOffset = -56.0f;
const float VolumetricLightingMinHeight = 0.0f;

//#define VARYING_VOLUMETRIC_LIGHTING // Applies noise to the VL density function

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
    float ScatteredLight = VolumetricLightingScattering * PhaseHenyeyGreenstein(dot(sundir, WorldDirection), -0.3f);
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

#endif