#ifndef VOLUME_RENDERING_ATMOSPHERE_GLSL
#define VOLUME_RENDERING_ATMOSPHERE_GLSL

#include "Phase.glsl"
#include "AtmosphereProperties.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Geometry/Ray.glsl"
#include "../Geometry/Sphere.glsl"

// Thes values were the best all rounder for both performance and quality
// I will add a slider for both of these (if I knew how) so users with better computers can get the sky the can acheive
#define INSCATTERING_STEPS 8 // Optical depth steps [ 8 12 16 24 32 48 64 128 ]
#define OPTICAL_DEPTH_STEPS 8 // Optical depth steps [ 8 12 16 24 32 48 64 128 ]

// Optical depth:
// x - rayleigh
// y - mie
// z - ozone

vec3 ComputeOpticalDepth(Ray AirMassRay, float pointdistance) {
    vec3 OpticalDepth = vec3(0.0f);
    float RayMarchStepLength = pointdistance / float(OPTICAL_DEPTH_STEPS);
    float RayMarchPosition = 0.0f;
    vec3 CurrentDensity = CalculateAtmosphericDensity(AirMassRay, RayMarchPosition, RayMarchStepLength);
    for(int Step = 1; Step < OPTICAL_DEPTH_STEPS; Step++){
        vec3 NextDensity = CalculateAtmosphericDensity(AirMassRay, RayMarchPosition, RayMarchStepLength);
        OpticalDepth += (CurrentDensity + NextDensity) / 2.0f;
        RayMarchPosition += RayMarchStepLength;
        CurrentDensity = NextDensity;
    }
    OpticalDepth *= RayMarchStepLength;
    return OpticalDepth;
}

vec3 Transmittance(in vec3 OpticalDepth){
    vec3 Tau = 
        OpticalDepth.x * ExtinctionRayleigh +
        OpticalDepth.y * ExtinctionMie      +
        OpticalDepth.z * ExtinctionOzone    ;
    return exp(-Tau);
}

vec3 ComputeTransmittance(Ray ray, float pointdistance) {
    return Transmittance(ComputeOpticalDepth(ray, pointdistance));
}

//#define ATMOSPHERE_CAMERA_HEIGHT

vec3 GetCameraPositionEarth(void){
    #ifdef ATMOSPHERE_CAMERA_HEIGHT
    return vec3(0.0f, EarthRadius + max(5.0f * (cameraPosition.y-64.0f), 0.0f), 0.0f);
    #else
    return vec3(0.0f, EarthRadius, 0.0f);
    #endif
}

void ComputeAtmosphericScattering(inout Ray ViewRay, in vec3 light, inout vec3 AccumRayleigh, inout vec3 AccumMie, inout vec3 ViewOpticalDepth, inout vec3 AccumViewOpticalDepth, inout float RayMarchPosition, inout float RayMarchStepLength) {
    vec3 SampleLocation = ViewRay.Origin + ViewRay.Direction * (RayMarchPosition + 0.5f * RayMarchStepLength);
    vec3 CurrentDensity = CalculateAtmosphericDensity(SampleLocation);
    ViewOpticalDepth += CurrentDensity * RayMarchStepLength;
    vec3 ViewTransmittance = Transmittance(ViewOpticalDepth + AccumViewOpticalDepth);
    float LightLength = RaySphereIntersect(SampleLocation, light, AtmosphereRadius);
    Ray LightRay;
    LightRay.Origin    = SampleLocation;
    LightRay.Direction = light         ;
    vec3 TransmittedSunLight = ComputeTransmittance(LightRay, LightLength) * ViewTransmittance;
    AccumRayleigh += TransmittedSunLight * CurrentDensity.x;
    AccumMie      += TransmittedSunLight * CurrentDensity.y;
    RayMarchPosition += RayMarchStepLength;
}

vec3 ComputeAtmosphericScattering(in vec3 light, in vec3 dir, out vec3 viewopticaldepth) {
    //return vec3(1.0f);
    //dir.y = max(dir.y, 0.1f);
    //dir = normalize(dir);
    vec3 ViewPos = GetCameraPositionEarth();
    float AtmosphereDistance = RaySphereIntersect(ViewPos, dir, AtmosphereRadius);
    vec3 AtmosphereIntersectionLocation = ViewPos + dir * AtmosphereDistance;
    vec3 AccumRayleigh = vec3(0.0f), AccumMie = vec3(0.0f);
    // TODO: precompute cos theta^2 for both functions
    float CosTheta = dot(light, dir);
    vec3  ScatteringStrengthRayleigh = PhaseRayleigh(CosTheta) * ScatteringRayleigh;
    float ScatteringStrengthMie      = PhaseMie(CosTheta)      * ScatteringMie     ;
    float RayMarchStepLength = AtmosphereDistance / float(INSCATTERING_STEPS);
    float RayMarchPosition = 0.0f;
    vec3 ViewOpticalDepth = vec3(0.0f); 
    Ray ViewRay;
    ViewRay.Origin = ViewPos;
    ViewRay.Direction = dir;
    vec3 ViewDensity = CalculateAtmosphericDensity(ViewRay.Origin) * RayMarchStepLength;
    vec3 CurrentAccumRayleigh = vec3(0.0f), CurrentAccumMie = vec3(0.0f);
    vec3 CurrentOpticalDepth = vec3(0.0f);
    ComputeAtmosphericScattering(ViewRay, light, CurrentAccumRayleigh, CurrentAccumMie, CurrentOpticalDepth, ViewOpticalDepth, RayMarchPosition, RayMarchStepLength);
    ViewOpticalDepth += (ViewDensity + CurrentOpticalDepth) / 2.0f;
    for(int InscatteringStep = 1; InscatteringStep < INSCATTERING_STEPS; InscatteringStep++){
        vec3 NextAccumRayleigh = vec3(0.0f);
        vec3 NextAccumMie      = vec3(0.0f);
        vec3 NextOpticalDepth  = vec3(0.0f);
        ComputeAtmosphericScattering(ViewRay, light, NextAccumRayleigh, NextAccumMie, NextOpticalDepth, ViewOpticalDepth, RayMarchPosition, RayMarchStepLength);
        AccumRayleigh    += (NextAccumRayleigh + CurrentAccumRayleigh) / 2.0f;
        AccumMie         += (NextAccumMie      + CurrentAccumMie     ) / 2.0f;
        ViewOpticalDepth += (NextOpticalDepth  + CurrentOpticalDepth ) / 2.0f;
        CurrentAccumRayleigh = NextAccumRayleigh;
        CurrentAccumMie      = NextAccumMie     ;
        CurrentOpticalDepth  = NextOpticalDepth ;
    }
    viewopticaldepth = ViewOpticalDepth;
    return SunColor * (AccumRayleigh * ScatteringStrengthRayleigh + AccumMie * ScatteringStrengthMie) * RayMarchStepLength;
}

#endif