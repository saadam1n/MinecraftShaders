#ifndef VOLUME_RENDERING_ATMOSPHERE_GLSL
#define VOLUME_RENDERING_ATMOSPHERE_GLSL

#include "Phase.glsl"
#include "AtmosphereProperties.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../Geometry/Ray.glsl"
#include "../Geometry/Sphere.glsl"

#define INSCATTERING_STEPS 32 // Inscattering steps [ 32 48 64 96 128 192 256]

// Optical depth:
// x - rayleigh
// y - mie
// z - ozone

vec3 ComputeOpticalDepth(Ray AirMassRay, float pointdistance) {
    vec3 Start = AirMassRay.Origin;
    vec3 End = Start + AirMassRay.Direction * pointdistance;
    vec2 LUT_Coords = vec2(Start.y, End.y);
    LUT_Coords = LUT_Coords - EarthRadius;
    LUT_Coords /= AtmosphereHeight;
    LUT_Coords = saturate(LUT_Coords);
    vec3 OpticalDepth = texture2D(colortex6, LUT_Coords).rgb * pointdistance;
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

// https://web.archive.org/web/20200313091416/http://codeflow.org/entries/2011/apr/13/advanced-webgl-part-2-sky-rendering/
float ComputeHorizonExtinction(vec3 position, vec3 dir, float radius){
    float u = dot(dir, -position);
    if(u<0.0){
        return 1.0;
    }
    vec3 near = position + u*dir;
    if(length(near) < radius){
        return 0.0;
    }
    else{
        vec3 v2 = normalize(near)*radius - position;
        float diff = acos(dot(normalize(v2), dir));
        return smoothstep(0.0, 1.0, pow(diff*2.0, 3.0));
    }
}

void ComputeAtmosphericScattering(inout Ray ViewRay, in vec3 light, inout vec3 AccumRayleigh, inout vec3 AccumMie, inout vec3 ViewOpticalDepth, inout vec3 AccumViewOpticalDepth, inout float RayMarchPosition, inout float RayMarchStepLength) {
    vec3 SampleLocation = ViewRay.Origin + ViewRay.Direction * (RayMarchPosition + 0.5f * RayMarchStepLength);
    vec3 CurrentDensity = CalculateAtmosphericDensity(SampleLocation);
    Ray SampleRay = ViewRay;
    SampleRay.Origin = SampleLocation;
    ViewOpticalDepth += ComputeOpticalDepth(SampleRay, RayMarchStepLength);
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
    float HorizonDot = dot(dir, vec3(0.0f, 1.0f, 0.0f));
    float EyeExtinction = 1.0f;
    if(HorizonDot < 0.0f){
        EyeExtinction = max(1.0f - exp(-50.0f * HorizonDot - 4.0f), 0.0f);
    }
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
    vec3 AtmosphereColor = SunColor * (AccumRayleigh * ScatteringStrengthRayleigh + AccumMie * ScatteringStrengthMie) * RayMarchStepLength * EyeExtinction;
    return max(AtmosphereColor, vec3(0.0f));
}

#endif