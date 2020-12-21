#version 120

varying vec2 texcoords;
varying vec3 ViewSpaceViewDir;
flat varying vec3 LightDirection;

#include "util/commonfuncs.glsl"

const float KM_SIZE = 1000.0f;
const float EarthRadius = 6360.0f * KM_SIZE;
const float AtmosphereHeight = 80.0f * KM_SIZE;
const float AtmosphereRadius = AtmosphereHeight + EarthRadius;

// Taken from https://www.scratchapixel.com/code.php?id=52&origin=/lessons/procedural-generation-virtual-worlds/simulating-sky 
bool SolveQuadratic(float a, float b, float c, out float x1, out float x2) 
{ 
    if (b == 0) { 
        // Handle special case where the the two vector ray.dir and V are perpendicular
        // with V = ray.orig - sphere.centre
        if (a == 0) return false; 
        x1 = 0; x2 = sqrt(-c / a); 
        return true; 
    } 
    float discr = b * b - 4 * a * c; 
 
    if (discr < 0) return false; 
 
    float q = (b < 0.f) ? -0.5f * (b - sqrt(discr)) : -0.5f * (b + sqrt(discr)); 
    x1 = q / a; 
    x2 = c / q; 
 
    return true; 
} 

void swap(inout float lhs, inout float rhs){
    float temp = rhs;
    rhs = lhs;
    lhs = temp;
}

bool RaySphereIntersect(vec3 orig, vec3 dir, float radius, out float t0, out float t1) 
{ 
    // They ray dir is normalized so A = 1 
    float A = dir.x * dir.x + dir.y * dir.y + dir.z * dir.z; 
    float B = 2 * (dir.x * orig.x + dir.y * orig.y + dir.z * orig.z); 
    float C = orig.x * orig.x + orig.y * orig.y + orig.z * orig.z - radius * radius; 
 
    if (!SolveQuadratic(A, B, C, t0, t1)) return false; 
 
    if (t0 > t1) swap(t0, t1); 
 
    return true; 
} 

const float ScaleHeightRayleigh = 7.994f * KM_SIZE;
const float ScaleHeightMie = 1.200f * KM_SIZE;

float CalculateDensityRayleigh(float h){
    return exp(-h/ScaleHeightRayleigh);
}

float CalculateDensityMie(float h){
    return exp(-h/ScaleHeightMie);
}

float PhaseRayleigh(in float cosTheta){
    return 3.0f / (16.0f * MATH_PI) * (1.0f + cosTheta * cosTheta);
}

float PhaseHenyeyGreenstein(in float cosTheta, in float g){
    float g_2 = g*g;
    float phase = (1.0f - g_2) / pow(1 + g_2 + 2.0f * g * cosTheta, 1.5f);
    return phase / (4.0f * MATH_PI);
}

float PhaseMie(in float cosTheta) {
    return PhaseHenyeyGreenstein(cosTheta, -0.75f);
}

#define INSCATTERING_STEPS 32
#define OPTICAL_DEPTH_STEPS 32

const vec3 ScatteringCoefficientRayleigh = vec3(5.5e-6, 13.0e-6, 22.4e-6);
const vec3 AbsorbtionCoefficientRayleigh = vec3(0.0f); // Negligible 
const vec3 ExtinctionCoefficientRayleigh = ScatteringCoefficientRayleigh + AbsorbtionCoefficientRayleigh;
const float ScatteringCoefficientMie = 21e-6;
const float AbsorbtionCoefficientMie = 1.1f * ScatteringCoefficientMie;
const float ExtinctionCoefficientMie = ScatteringCoefficientMie + AbsorbtionCoefficientMie;
const float SunBrightness = 10.0f;
const vec3 SunColor = vec3(1.0f, 1.0f, 1.0f) * SunBrightness;

struct OpticalDepth{
    vec3 Rayleigh;
    float Mie;
};

struct Ray {
    vec3 Origin;
    vec3 Direction;
};

OpticalDepth ComputeOpticalDepth(Ray AirMassRay, float pointdistance) {
    OpticalDepth AirMass;
    AirMass.Rayleigh = vec3(0.0f);
    AirMass.Mie = 0.0f;
    float RayMarchStepLength = pointdistance / float(OPTICAL_DEPTH_STEPS);
    float RayMarchPosition = 0.0f;
    for(int Step = 0; Step < OPTICAL_DEPTH_STEPS; Step++){
        vec3 SampleLocation = AirMassRay.Origin + AirMassRay.Direction * (RayMarchPosition + 0.5f * RayMarchStepLength);
        float Height = distance(SampleLocation, vec3(0.0f)) - EarthRadius;
        AirMass.Rayleigh += CalculateDensityRayleigh(Height);
        AirMass.Mie      += CalculateDensityMie(Height);

        RayMarchPosition += RayMarchStepLength;
    }
    AirMass.Rayleigh *= ExtinctionCoefficientRayleigh * RayMarchStepLength;
    AirMass.Mie      *= ExtinctionCoefficientMie      * RayMarchStepLength;
    return AirMass;
}

vec3 Transmittance(in OpticalDepth AirMass){
    vec3 TotalOpticalDepth = AirMass.Rayleigh + AirMass.Mie;
    //gl_FragData[1].rgb = exp(-TotalOpticalDepth);
    return exp(-TotalOpticalDepth * 2);
}

vec3 ComputeTransmittance(Ray ray, float pointdistance) {
    return Transmittance(ComputeOpticalDepth(ray, pointdistance));
}

vec3 ComputeAtmosphericScattering(in vec3 light, in vec3 dir){
    //dir.y = saturate(dir.y);
    //dir = normalize(dir);
    float t0;
    vec3 ViewPos = vec3(0.0f, EarthRadius, 0.0f);
    float DistanceToAtmosphereTop;
    RaySphereIntersect(ViewPos, dir, AtmosphereRadius, t0, DistanceToAtmosphereTop);
    vec3 AtmosphereIntersectionLocation = ViewPos + dir * DistanceToAtmosphereTop;
    vec3 AccumRayleigh = vec3(0.0f), AccumMie = vec3(0.0f);
    // TODO: precompute cos theta^2 for both functions
    float CosTheta = dot(light, dir);
    vec3 ScatteringStrengthRayleigh = PhaseRayleigh(CosTheta) * ScatteringCoefficientRayleigh;
    float ScatteringStrengthMie = PhaseMie(CosTheta) * ScatteringCoefficientMie;
    float RayMarchStepLength = DistanceToAtmosphereTop / float(INSCATTERING_STEPS);
    float RayMarchPosition = 0.0f;
    for(int InscatteringStep = 0; InscatteringStep < INSCATTERING_STEPS; InscatteringStep++){
        vec3 SampleLocation = ViewPos + dir * (RayMarchPosition + 0.5f * RayMarchStepLength);
        float InscatteringLength;
        RaySphereIntersect(SampleLocation, light, AtmosphereRadius, t0, InscatteringLength);
        Ray AirMassRay;
        AirMassRay.Origin = SampleLocation;
        AirMassRay.Direction = light;
        vec3 TransmittedSunLight = ComputeTransmittance(AirMassRay, InscatteringLength);
        vec3 TransmittedAccumSunLight = vec3(1.0f);
        float CurrentAltitude = distance(SampleLocation, vec3(0.0f)) - EarthRadius;
        vec3 CurrentAltitudeScatteringStrengthRayleigh = CalculateDensityRayleigh(CurrentAltitude) * ScatteringStrengthRayleigh;
        float CurrentAltitudeScatteringStrengthMie = CalculateDensityMie(CurrentAltitude) * ScatteringStrengthMie;
        AccumRayleigh += TransmittedSunLight * TransmittedAccumSunLight * CurrentAltitudeScatteringStrengthRayleigh * RayMarchStepLength;
        AccumMie      += TransmittedSunLight * TransmittedAccumSunLight * CurrentAltitudeScatteringStrengthMie      * RayMarchStepLength;
        RayMarchPosition += RayMarchStepLength;
    }
    // Multiplying the rayleigh light by 0.5f breaks the physical basis of this, but it sure does give some nice sunsets
    // I'll find a better fix to the problem later
    return SunColor * (0.5f * AccumRayleigh + AccumMie);
}

// TODO: Fill this function out
vec3 ComputeSkyGradient(in vec3 light, in vec3 dir){
    vec3 Top = GetSkyTopColor();
    vec3 Fog = ApplyFog(Top, GetWorldSpace());
    return Fog;
}

#define ATMOSPHERIC_SCATTERING

vec3 ComputeSkyColor(in vec3 light, in vec3 dir){
    #ifdef ATMOSPHERIC_SCATTERING
    return ComputeAtmosphericScattering(light, dir);
    #else
    return ComputeSkyGradient(light, dir);
    #endif
}

vec3 ComputeSunColor(in vec3 light, in vec3 dir){
    vec3 ViewPos = vec3(0.0f, EarthRadius, 0.0f);
    float t0, t1;
    RaySphereIntersect(ViewPos, dir, AtmosphereRadius, t0, t1);
    Ray SunRay;
    SunRay.Origin = ViewPos;
    SunRay.Direction = dir;
    vec3 Transmittance = ComputeTransmittance(SunRay, t1);
    return Transmittance * SunColor;
}

const float SunSpotSize = 0.999;

void main(){
    float DeferredFlag = texture2D(colortex5, texcoords).r;
    vec4 Color;
    if(DeferredFlag == 0.0f){ // If DeferredFlag is 0.0f it is part of the sky
        vec3 Direction = normalize(mat3(gbufferModelViewInverse) * ViewSpaceViewDir);
        if(dot(Direction, LightDirection) > SunSpotSize){
            Color.rgb = ComputeSunColor(LightDirection, Direction);
        } else {
            Color.rgb = ComputeSkyColor(LightDirection, Direction);
        }
        Color.a = 1.0f;
    } else {
        Color = texture2D(colortex7, texcoords);
    }
    //Color.rgb = vec3(DeferredFlag);
    /* DRAWBUFFERS:74 */
    gl_FragData[0] = Color;
}