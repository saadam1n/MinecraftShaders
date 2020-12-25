#ifndef VOLUME_RENDERING_CLOUD_GLSL
#define VOLUME_RENDERING_CLOUD_GLSL 1

#include "../Geometry/Ray.glsl"
#include "../Geometry/Plane.glsl"

#define CLOUD_START 256.0f
#define CLOUD_HEIGHT 16.0f
#define CLOUD_INSCATTERING_STEPS 64.0f
#define CLOUD_LIGHT_STEPS 16.0f

void InitCloudPlanes(out Plane upper, out Plane lower){
    upper.Normal = lower.Normal = vec3(0.0f, 1.0f, 0.0f);
    upper.Position.xz = lower.Position.xz = vec2(0.0f);
    lower.Position.y = CLOUD_START;
    upper.Position.y = CLOUD_START + CLOUD_HEIGHT;
}

const vec3 CloudScattering = vec3(0.0005f);
const vec3 CloudAbsoption = vec3(0.000001f);
const vec3 CloudExtinction = CloudScattering + CloudAbsoption;

float SampleCloudDensity(in vec3 pos){
    float Noise = GenerateNoise3D_0(pos * 0.001f + frameTimeCounter * 0.1f);
    return Noise;
}

// ViewPos + dir * (RayMarchPosition + 0.5f * RayMarchStepLength)

vec3 ComputeCloudColor(in vec3 playerpos, in vec3 dir, in vec3 lightdir, in vec3 lightcolor, in vec3 background) {
    Plane UpperCloudPlane, LowerCloudPlane;
    InitCloudPlanes(UpperCloudPlane, LowerCloudPlane);
    Ray ViewingRay;
    ViewingRay.Origin = playerpos;
    ViewingRay.Direction = dir;
    // TODO: Add support for cases where the player is in the cloud
    float ViewStartDist =  Intersect(ViewingRay, LowerCloudPlane);
    float ViewEndDist =  Intersect(ViewingRay, UpperCloudPlane);
    vec3 ViewStart = ViewingRay.Origin + ViewingRay.Direction * ViewStartDist;
    vec3 ViewEnd   = ViewingRay.Origin + ViewingRay.Direction * ViewEndDist;
    vec3 StepSize = (ViewEnd - ViewStart) / CLOUD_INSCATTERING_STEPS;
    float StepLength = ViewEndDist - ViewStartDist;
    vec3 StepDirection = StepSize / StepLength;
    vec3 AccumOpticalDepth = vec3(0.0f);
    vec3 ViewTransmittance = vec3(1.0f);
    vec3 AccumColor = vec3(0.0f);
    vec3 ScatteredLight = CloudScattering * PhaseHenyeyGreenstein(dot(dir, lightdir), -0.9);
    float RayMarchPosition = 0.0f;
    for(float Step = 0; Step < CLOUD_INSCATTERING_STEPS; Step++){
        vec3 SamplePosition = ViewStart + ViewingRay.Direction * (RayMarchPosition * 0.5f * StepLength);
        float Density = SampleCloudDensity(SamplePosition);
        vec3 CurrentOpticalDepth = vec3(Density) * CloudExtinction * StepLength;
        AccumOpticalDepth += CurrentOpticalDepth;
        ViewTransmittance = ViewTransmittance * exp(-CurrentOpticalDepth);
        Ray LightRay;
        LightRay.Origin = SamplePosition;
        LightRay.Direction = lightdir;
        float LightEndDist = Intersect(ViewingRay, LowerCloudPlane);
        vec3 LightEndPos = LightRay.Origin + LightRay.Direction * LightEndDist;
        vec3 LightStep = (LightEndPos - LightRay.Origin) / CLOUD_LIGHT_STEPS;
        float LightStepLength = LightEndDist / CLOUD_LIGHT_STEPS;
        vec3 LightOpticalDepth = vec3(0.0f);
        float LightRayMarchPosition = 0.0f;
        for(float LightStep = 0.0f; LightStep < CLOUD_LIGHT_STEPS; LightStep++){
            vec3 LightSamplePosition = LightRay.Origin + LightRay.Direction * (LightRayMarchPosition + 0.5f * LightStepLength);
            float LightDensity = SampleCloudDensity(LightSamplePosition);
            LightOpticalDepth += vec3(LightDensity);
            LightRayMarchPosition += LightStepLength;
        }
        vec3 LightTransmittance = exp(-LightOpticalDepth * CloudExtinction * LightStepLength);
        vec3 TransmittedSunColor = LightTransmittance * ViewTransmittance * lightcolor * ScatteredLight;
        AccumColor += TransmittedSunColor * StepLength;
        RayMarchPosition += StepLength;
    }
    vec3 TransmittedBackgroundColor = ViewTransmittance * background;
    return TransmittedBackgroundColor + AccumColor;
}


#endif