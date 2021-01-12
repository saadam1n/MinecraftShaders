#ifndef VOLUME_RENDERING_CLOUDS_GLSL
#define VOLUME_RENDERING_CLOUDS_GLSL 1

#include "../Geometry/Ray.glsl"
#include "../Geometry/Plane.glsl"
#include "../Random/Noise3D.glsl"
#include "../Transform/Eye.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "SunProperties.glsl"

// https://eo.ucar.edu/webweather/cumulus.html
// Or 1024.0f
#define CLOUD_START 200.0f
#define CLOUD_HEIGHT 256.0f
#define CLOUD_END (CLOUD_START + CLOUD_HEIGHT)
#define CLOUD_INSCATTERING_STEPS 16 // [8 12 16 24 32 48 64]
#define CLOUD_LIGHT_STEPS 16 // [4 6 8 12 16 24 32 48]
// http://ww2010.atmos.uiuc.edu/(Gh)/guides/mtr/cld/cldtyp/hgh/crs.rxml
#define CIRRUS_START 6000.0f

void InitCloudPlanes(out Plane upper, out Plane lower, in vec2 player){
    upper.Normal = lower.Normal = vec3(0.0f, -1.0f, 0.0f);
    upper.Position.xz = lower.Position.xz = player;
    lower.Position.y = CLOUD_START;
    upper.Position.y = CLOUD_START + CLOUD_HEIGHT;
}

const vec3 CloudScattering = vec3(0.06f);
const vec3 CloudAbsoption = vec3(0.00f);
const vec3 CloudExtinction = CloudScattering + CloudAbsoption;

float CloudDensityPower = mix(45.5f, 1.5f, rainStrength) * 1.5f;
float CloudDensityMult = mix(2.2f, 5.5f, rainStrength);

float GenerateCloudNoise(in vec3 p){
    p.xz *= 0.5f;
    float RawNoise = max(GenerateNoise3D_9(p), 0.0f);
    float Perlin = GenerateNoise3D_6(p) * GenerateNoise3D_2(p * 20.0f);
    float Noise = clamp(pow(RawNoise * 0.05f, 2.0f), 0.0f, 1.0f);
    Noise = pow(clamp(5000000000.0f * pow(Noise, 4.0f), 0.0f, 1.0f) * GenerateNoise3D_0(p) * Perlin, 0.807f);
    return Noise;
    p.xz *= 0.5f;
    p.y *= 10.0f;
    return saturate(200.0f * pow((GenerateNoise3D_11(p)), 40.05f));
}

float SampleCloudDensity(in vec3 pos){
    // or  0.004f
    vec3 NoiseCoord = pos * 0.03f;
    NoiseCoord.xz += frameTimeCounter * 0.0432f; 
    NoiseCoord.y -= CLOUD_START;
    NoiseCoord.y += 4.0f;
    float Density = CloudDensityMult * pow(GenerateCloudNoise(NoiseCoord), CloudDensityPower) *  GenerateCloudNoise(NoiseCoord * 12.0f);
    return max(GenerateCloudNoise(NoiseCoord * 0.1f), 0.0f);
}

// ViewPos + dir * (RayMarchPosition + 0.5f * RayMarchStepLength)

#define VOLUMETRIC_CLOUDS

vec3 ComputeCloudColor(in vec3 playerpos, in vec3 dir, in vec3 lightdir, in vec3 lightcolor, in vec3 background) {
    Ray ViewingRay;
    ViewingRay.Origin = playerpos;
    ViewingRay.Direction = dir;
    float Dither = texture2D(noisetex, gl_TexCoord[0].st * 10.0f + frameTimeCounter).r * 3.0f;
    // TODO: Add support for cases where the player is in the cloud
    const float CloudStart = 12288.0f;
    const float CloudEnd = CloudStart + 16.0f;
    #ifndef VOLUMETRIC_CLOUDS
    return background;
    #endif
    float ViewStartDist = Dither + (CLOUD_START - eyeAltitude) / dir.y;
    float ViewEndDist =            (CLOUD_END   - eyeAltitude) / dir.y;
    float EyeExtinction = 1.0f;
    if(ViewStartDist > CloudStart || ViewEndDist > CloudEnd){
        return background;
    } //else if(ViewStartDist > CloudStart-1000.0f){
      //  EyeExtinction
   //}
    vec3 ViewStart = ViewingRay.Origin + ViewingRay.Direction * ViewStartDist;
    vec3 ViewEnd   = ViewingRay.Origin + ViewingRay.Direction * ViewEndDist;
    vec3 ViewStep = (ViewStart - ViewEnd) / CLOUD_INSCATTERING_STEPS;
    float StepLength = (ViewEndDist - ViewStartDist) / CLOUD_INSCATTERING_STEPS;
    vec3 ScatteredLight = CloudScattering * PhaseHenyeyGreenstein(dot(dir, lightdir), -0.15f);// * (4.0f * MATH_PI); // Re-denormalize results of HG phase function for strong scattering
    vec3 AccumOpticalDepth = vec3(0.0f);
    vec3 AccumColor = vec3(0.0f);
    float RayMarchPosition = 0.0f; 
    for(float Step = 0; Step < CLOUD_INSCATTERING_STEPS; Step++){
        vec3 SamplePosition = ViewStart + ViewingRay.Direction * (RayMarchPosition + 0.5f * StepLength);
        float Density = SampleCloudDensity(SamplePosition);
        vec3 CurrentOpticalDepth = Density * CloudExtinction * StepLength;
        AccumOpticalDepth += CurrentOpticalDepth;
        vec3 ViewTransmittance = exp(-AccumOpticalDepth);
        Ray LightRay;
        LightRay.Origin = SamplePosition;
        LightRay.Direction = lightdir;
        float LightEndDist = ((CLOUD_END - LightRay.Origin.y) / LightRay.Direction.y);
        vec3 LightEndPos = LightRay.Origin + LightRay.Direction * LightEndDist;
        float LightStepLength = abs(LightEndDist) / CLOUD_LIGHT_STEPS;
        vec3 LightStep = LightRay.Direction * LightStepLength;
        vec3 LightOpticalDepth = vec3(0.0f);
        float LightRayMarchPosition = 0.0f;
        for(float LightStep = 0.0f; LightStep < CLOUD_LIGHT_STEPS; LightStep++){
            vec3 LightSamplePosition = SamplePosition + LightRay.Direction * (LightRayMarchPosition + 0.5f * LightStepLength);;
            float LightDensity = SampleCloudDensity(LightSamplePosition);
            LightOpticalDepth += vec3(LightDensity);
            LightRayMarchPosition += LightStepLength;
        }
        LightOpticalDepth = LightOpticalDepth * CloudExtinction * LightStepLength;
        vec3 LightTransmittance = exp(-LightOpticalDepth);
        vec3 TransmittedSunColor = lightcolor * LightTransmittance * ViewTransmittance;
        AccumColor += TransmittedSunColor * StepLength * ScatteredLight * Density;
        RayMarchPosition += StepLength;
    }
    vec3 TransmittedBackgroundColor = exp(-AccumOpticalDepth) * background;
    return mix(background, TransmittedBackgroundColor + AccumColor, EyeExtinction);
}

vec3 Draw2DClouds(in vec3 Direction, in vec3 lightcol, in vec3 background){
    #define CLOUD_2D_START 400
    float CloudHeightDist = CLOUD_2D_START - eyeAltitude;
    if(CloudHeightDist > 0.0f){
        if(Direction.y < 0.0f){
            return background;
        }
    } else {
        if(Direction.y > 0.0f){
            return background;
        }
    }
    float CloudDist = CloudHeightDist / Direction.y;
    const float Begin = 2000.0f;
    const float End = 3000.0f;
    float Fade = 1.0f - ((clamp(CloudDist, Begin, End) - Begin) / (End - Begin));
    vec2 CloudLocation = ((frameTimeCounter + cameraPosition.xz) / 100.0f) + Direction.xz * CloudDist * 0.01f;
    float CloudDensity = GenerateNoise2D_3(CloudLocation);
    vec3 CloudColor = Fade * 0.01f * lightcol * (CloudDensity);
    vec3 BackgroundColor = background * exp(-0.1f * CloudDensity);
    return CloudColor + BackgroundColor;
}

#endif