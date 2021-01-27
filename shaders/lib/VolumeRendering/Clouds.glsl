#ifndef VOLUME_RENDERING_CLOUDS_GLSL
#define VOLUME_RENDERING_CLOUDS_GLSL 1

#include "../Geometry/Ray.glsl"
#include "../Geometry/Plane.glsl"
#include "../Random/Noise3D.glsl"
#include "../Transform/Eye.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../Utility/TextureSampling.glsl"
#include "SunProperties.glsl"

// https://eo.ucar.edu/webweather/cumulus.html
// Or 1024.0f
#define CLOUD_START 2048.0f
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

float RemapValue(in float val, in float old_min, in float old_max, in float new_min, in float new_max){
    val -= old_min;
    val /= old_max;
    val *= new_max;
    val += new_min;
    return val;
}

float SmoothNoise(in vec3 pos){
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
	vec2 coord2 = (uv2 + 0.5f) / noiseTextureResolution;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}

// TODO: update this with my own noise function instead of relying on other people's noise function
float GenerateCloudNoise(in vec3 p){
    p *= 0.1f;
    float Noise = 0.0f;

    Noise += SmoothNoise(p * 0.01f) * 0.500f;
    Noise += SmoothNoise(p * -0.02f) * 0.250f;
    Noise += SmoothNoise(p * 0.04f) * 0.125f;
    Noise += SmoothNoise(p * -0.08f) * 0.0625f;
	
    /*const*/ float Coverage = mix(0.42f, 0.25f, rainStrength);
    const     float Sharpness = 0.0005f;
    Noise = 1.0f - pow(Sharpness, max(Noise - Coverage, 0.0f));

    //Noise *= (1.0f - exp(-1.0f * Noise));
    Noise = RemapValue(Noise * Noise, 0.0f, 0.9375f, 0.0f, 0.25f);
    //Noise = pow(Noise, 0.8f);
    //Noise = sqrt(Noise);
    //Noise = GenerateNoise3D_0(p * 0.001f);
    //Noise *= mix(GenerateNoise3D_0(p * 0.005f), 1.0f, 0.5f);

    return Noise;
}

float SampleCloudDensity(in vec3 pos){
    // or  0.004f
    vec3 NoiseCoord = pos;// * 0.003f;
    NoiseCoord.xz += frameTimeCounter * 15.432f; 
    NoiseCoord.y -= CLOUD_START;
    NoiseCoord.y += 4.0f;
    float Density = GenerateCloudNoise(NoiseCoord);
    Density = clamp(Density, 0.0f, 1.0f);
    return Density;
}

#define VOLUMETRIC_CLOUDS

const float CloudStart = 42288.0f;
const float CloudEnd = CloudStart + 16.0f;

vec3 ComputeCloudColor(in vec3 playerpos, in vec3 dir, in vec3 lightdir, in vec3 lightcolor, in vec3 background) {
    #ifndef VOLUMETRIC_CLOUDS
    return background;
    #else
    Ray ViewingRay;
    ViewingRay.Origin = playerpos;
    ViewingRay.Direction = dir;
    float Dither = (texture2D(noisetex, gl_TexCoord[0].st * 10.0f + frameTimeCounter).r * 2.0f - 1.0f) * 8.0f;
    // TODO: Add support for cases where the player is in the cloud
    float ViewStartDist = (CLOUD_START - eyeAltitude) / dir.y;
    float ViewEndDist   = (CLOUD_END   - eyeAltitude) / dir.y;
    float EyeExtinction = 1.0f;
    if(ViewStartDist > CloudStart || ViewEndDist > CloudEnd){
        return background;
    } 
    vec3 ViewStart = ViewingRay.Origin + ViewingRay.Direction * ViewStartDist;
    vec3 ViewEnd   = ViewingRay.Origin + ViewingRay.Direction * ViewEndDist  ;
    float StepLength = (ViewEndDist - ViewStartDist) / CLOUD_INSCATTERING_STEPS;
    vec3 ScatteredLight = CloudScattering * PhaseHenyeyGreenstein(dot(dir, lightdir), -0.15f);
    vec3 AccumOpticalDepth = vec3(0.0f);
    vec3 AccumColor = vec3(0.0f);
    float RayMarchPosition = Dither; 
    for(float Step = 0; Step < CLOUD_INSCATTERING_STEPS; Step++){
        vec3 SamplePosition = ViewStart + ViewingRay.Direction * (RayMarchPosition + 0.5f * StepLength);
        float Density = SampleCloudDensity(SamplePosition);
        vec3 CurrentOpticalDepth = Density * CloudExtinction * StepLength;
        AccumOpticalDepth += CurrentOpticalDepth;
        vec3 ViewTransmittance = exp(-AccumOpticalDepth);
        Ray LightRay;
        LightRay.Origin = SamplePosition;
        LightRay.Direction = lightdir;
        float LightEndDist = (CLOUD_END - LightRay.Origin.y) / LightRay.Direction.y;
        float LightStepLength = LightEndDist / CLOUD_LIGHT_STEPS;
        vec3 LightOpticalDepth = vec3(0.0f);
        float LightRayMarchPosition = 0.0f;
        for(float LightStep = 0.0f; LightStep < CLOUD_LIGHT_STEPS; LightStep++){
            vec3 LightSamplePosition = SamplePosition + LightRay.Direction * (LightRayMarchPosition + 0.5f * LightStepLength);;
            float LightDensity = SampleCloudDensity(LightSamplePosition);
            LightOpticalDepth += LightDensity;
            LightRayMarchPosition += LightStepLength;
        }
        LightOpticalDepth = LightOpticalDepth * CloudExtinction * LightStepLength;
        vec3 LightTransmittance = exp(-LightOpticalDepth);
        vec3 TransmittedSunColor = lightcolor * LightTransmittance * ViewTransmittance;
        AccumColor += TransmittedSunColor * Density;
        RayMarchPosition += StepLength;
    }
    AccumColor = AccumColor * StepLength * ScatteredLight;
    vec3 TransmittedBackgroundColor = exp(-AccumOpticalDepth) * background;
    return mix(background, TransmittedBackgroundColor + AccumColor, EyeExtinction);
    #endif
}

vec3 Draw2DClouds(in vec3 Direction, in vec3 lightcol, in vec3 background){
    #define CLOUD_2D_START 4096
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
    const float Begin = 24000.0f;
    const float End = Begin + 1000.0f;
    float Fade = max(1.0f - ((clamp(CloudDist, Begin, End) - Begin) / (End - Begin)), 0.0f);
    vec2 CloudLocation = ((frameTimeCounter + cameraPosition.xz) / 1000.0f) + Direction.xz * CloudDist * 0.0000995f;
    // Cloud noise generation
    // Use same method as "Generating and Rendering Procedural Clouds in Real Time on Programmable 3D Graphics Hardware"
    // Assume noisetex res is 256
    float CloudDensity;
    CloudDensity  = BicubicTexture(noisetex, CloudLocation         ).x * 0.0625f;
    CloudDensity += BicubicTexture(noisetex, CloudLocation * 0.500f).x * 0.1250f;
    CloudDensity += BicubicTexture(noisetex, CloudLocation * 0.250f).x * 0.2500f;
    CloudDensity += BicubicTexture(noisetex, CloudLocation * 0.125f).x * 0.5000f;
    // Use the same method to adjust the clouds
    // I also use the same values
    const float Coverage = 0.42f;
    const float Sharpness = 0.0015f;
    CloudDensity = 1.0f - pow(Sharpness, max(CloudDensity - Coverage, 0.0f));
    // Here is where I deviate from their method
    // I carve out finer details using noise from a 5th octave
    // CloudDensity *= mix(texture2D(noisetex, CloudLocation * 2.0f).x, 1.0f, 0.9f);
    vec3 CloudColor = Fade * 0.05f * lightcol * (CloudDensity);
    vec3 BackgroundColor = background * exp(-0.1f * CloudDensity);
    return CloudColor + BackgroundColor;
}

#endif