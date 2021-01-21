#ifndef VOLUME_RENDERING_ATMOSPHERE_GLSL
#define VOLUME_RENDERING_ATMOSPHERE_GLSL

#include "Phase.glsl"
#include "AtmosphereProperties.glsl"
#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"
#include "../Geometry/Ray.glsl"
#include "../Geometry/Sphere.glsl"
#include "../Utility/ColorAdjust.glsl"

#define INSCATTERING_STEPS 64 // Inscattering steps [ 10 12 16 32 48 64 96 128 192 256 384 512 1024 2048]

// Optical depth:
// x - rayleigh
// y - mie
// z - ozone

/*


// Taken from robobo shaders 
float ComputeEarthShadow(vec3 light) {
	return max(0.0, 1.0 - exp(-((1.61107315569f - acos(dot(light, vec3(0.0f, 1.0f, 0.0f)))/1.5f))));
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

vec3 ComputeOpticalDepth(Ray AirMassRay, float pointdistance) {
    vec3 Start = AirMassRay.Origin;
    vec3 End = Start + AirMassRay.Direction * pointdistance;
    vec2 LUT_Coords = vec2(Start.y, End.y);
    LUT_Coords = LUT_Coords - EarthRadius;
    LUT_Coords /= AtmosphereHeight;
    if(any(lessThan(LUT_Coords, vec2(0.0f)))){
        return vec3(100000.0f);
    }
    vec3 OpticalDepth = texture2D(depthtex2, LUT_Coords).rgb * pointdistance;
    return OpticalDepth;
}

vec3 ComputeTransmittance(Ray ray, float pointdistance) {
    return Transmittance(ComputeOpticalDepth(ray, pointdistance));
}
*/

//#define TEST_OZONE

#ifdef TEST_OZONE
vec3 Transmittance(in vec3 OpticalDepth){
    vec3 Tau = 
        OpticalDepth.x * ExtinctionRayleigh +
        OpticalDepth.y * ExtinctionMie      ;
    if(gl_TexCoord[0].x < 0.5f)
    Tau += 
        OpticalDepth.z * ExtinctionOzone    ;
    return exp(-Tau); 
}
#else
vec3 Transmittance(in vec3 OpticalDepth){
    vec3 Tau = 
        OpticalDepth.x * ExtinctionRayleigh +
        OpticalDepth.y * ExtinctionMie      +
        OpticalDepth.z * ExtinctionOzone    ;
    return exp(-Tau); 
}
#endif

vec3 GetCameraPositionEarth(void){
    float y = EarthRadius + (1070.74320039f-64.0f) + eyeAltitude;// * sin(frameTimeCounter);
    //y += eyeAltitude - 64.0f;
    return vec3(0.0f, y, 0.0f);
}

vec3 LookUpOpticalDepth(in float altitude, in float vertical_angle) {
    return texture2DLod(PrecomputedOpticalDepth, vec2(altitude / AtmosphereHeight, vertical_angle * 0.5f + 0.5f), 0).rgb;
}

vec3 LookUpOpticalDepth(in Ray ray) {
    float altitude = length(ray.Origin) - EarthRadius;
    float vertical_angle = dot(normalize(ray.Origin), ray.Direction);
    return LookUpOpticalDepth(altitude, vertical_angle);
}

vec3 ComputeViewOpticalDepth(in Ray SampleRay, in vec3 cameraopticaldepth){
    vec3 CurrentOpticalDepth = LookUpOpticalDepth(SampleRay);
    return cameraopticaldepth - CurrentOpticalDepth;
}

//#define MULTISCATTERING

vec3 EarthColor = vec3(0.0f, 1.0f, 0.0f) * 0.0f;

vec3 ComputeAtmosphericScattering(in vec3 light, in vec3 dir, out vec3 ViewOpticalDepth) {
    if(isInNether){
        return vec3(0.0f);
    }
    dir = normalize(dir);
    vec3 ViewPos = GetCameraPositionEarth();
    float AtmosphereDistance = RaySphereIntersect(ViewPos, dir, AtmosphereRadius);
    // Aerial perspective
    float t0, t1;
    bool IntersectEarth = RaySphereIntersect(ViewPos, dir, EarthRadius, t0, t1)  && t1 > 0.0f;
    if(IntersectEarth){
        AtmosphereDistance = max(t0, 0.0f);
    }
    vec3 AtmosphereIntersectionLocation = ViewPos + dir * AtmosphereDistance;
    vec3 AccumRayleigh = vec3(0.0f), AccumMie = vec3(0.0f);
    float CosTheta = dot(light, dir);     // TODO: precompute cos theta^2 for both functions
    vec3  ScatteringStrengthRayleigh = PhaseRayleigh(CosTheta) * ScatteringRayleigh;
    float ScatteringStrengthMie      = PhaseMie(CosTheta)      * ScatteringMie     ;
    float RayMarchStepLength = AtmosphereDistance / float(INSCATTERING_STEPS);
    float RayMarchPosition = 0.0f;
    ViewOpticalDepth = vec3(0.0f); 
    Ray ViewRay;
    ViewRay.Origin = ViewPos;
    ViewRay.Direction = dir;
    vec3 CameraOpticalDepth = LookUpOpticalDepth(ViewRay);
    #ifdef MULTISCATTERING
    vec3 Normal = dir;
    vec3 Tangent = cross(Normal, vec3(0.0f, 1.0f, 0.0f)); 
    vec3 Bitangent = cross(Normal, Tangent); 
    mat3 Rotation = mat3(Tangent, Bitangent, Normal);
    vec3 MultiscatterDirections[6];
    MultiscatterDirections[0] = Rotation * vec3( 0.0f,  1.0f,  0.0f);
    MultiscatterDirections[1] = Rotation * vec3( 0.0f, -1.0f,  0.0f);
    MultiscatterDirections[2] = Rotation * vec3( 1.0f,  0.0f,  0.0f);
    MultiscatterDirections[3] = Rotation * vec3(-1.0f,  0.0f,  0.0f);
    MultiscatterDirections[4] = Rotation * vec3( 0.0f,  0.0f,  1.0f);
    MultiscatterDirections[5] = Rotation * vec3( 0.0f,  0.0f, -1.0f);
    float MSDoD;
    const float MieStrength = 0.01f; // avoid white sky
    vec4 MultiscatterPhase[6];
    MSDoD = dot(MultiscatterDirections[0], dir);
    MultiscatterPhase[0] = vec4(PhaseRayleigh(MSDoD) * ScatteringRayleigh, PhaseMie(MSDoD) * ScatteringMie * MieStrength);
    MSDoD = dot(MultiscatterDirections[1], dir);
    MultiscatterPhase[1] = vec4(PhaseRayleigh(MSDoD) * ScatteringRayleigh, PhaseMie(MSDoD) * ScatteringMie * MieStrength);
    MSDoD = dot(MultiscatterDirections[2], dir);
    MultiscatterPhase[2] = vec4(PhaseRayleigh(MSDoD) * ScatteringRayleigh, PhaseMie(MSDoD) * ScatteringMie * MieStrength);
    MSDoD = dot(MultiscatterDirections[3], dir);
    MultiscatterPhase[3] = vec4(PhaseRayleigh(MSDoD) * ScatteringRayleigh, PhaseMie(MSDoD) * ScatteringMie * MieStrength);
    MSDoD = dot(MultiscatterDirections[4], dir);
    MultiscatterPhase[4] = vec4(PhaseRayleigh(MSDoD) * ScatteringRayleigh, PhaseMie(MSDoD) * ScatteringMie * MieStrength);
    MSDoD = dot(MultiscatterDirections[5], dir);
    MultiscatterPhase[5] = vec4(PhaseRayleigh(MSDoD) * ScatteringRayleigh, PhaseMie(MSDoD) * ScatteringMie * MieStrength);
    #endif
    vec3 MultiscatterAccum = vec3(0.0f);
    for(int InscatteringStep = 0; InscatteringStep < INSCATTERING_STEPS; InscatteringStep++){
        vec3 SampleLocation = ViewRay.Origin + ViewRay.Direction * (RayMarchPosition + 0.5f * RayMarchStepLength);
        vec3 CurrentDensity = CalculateAtmosphericDensity(SampleLocation);
        Ray SampleRay = ViewRay;
        SampleRay.Origin = SampleLocation;
        ViewOpticalDepth = ComputeViewOpticalDepth(SampleRay, CameraOpticalDepth);
        vec3 ViewTransmittance = Transmittance(ViewOpticalDepth);
        Ray LightRay;
        LightRay.Origin    = SampleLocation;
        LightRay.Direction = light         ;
        vec3 LightTransmittance = Transmittance(LookUpOpticalDepth(LightRay));
        #ifdef MULTISCATTERING
        // TODO: precomputation of Directions and phases 
        vec3 MultiScatterTransmittance = vec3(0.0f); {
            Ray MultiscatterRay;
            MultiscatterRay.Origin = LightRay.Origin;

            MultiscatterRay.Direction = MultiscatterDirections[0];
            MultiScatterTransmittance += Transmittance(LookUpOpticalDepth(MultiscatterRay)) * (MultiscatterPhase[0].rgb * CurrentDensity.x + MultiscatterPhase[0].a * CurrentDensity.y);

            MultiscatterRay.Direction = MultiscatterDirections[1];
            MultiScatterTransmittance += Transmittance(LookUpOpticalDepth(MultiscatterRay)) * (MultiscatterPhase[1].rgb * CurrentDensity.x + MultiscatterPhase[1].a * CurrentDensity.y);

            MultiscatterRay.Direction = MultiscatterDirections[2];
            MultiScatterTransmittance += Transmittance(LookUpOpticalDepth(MultiscatterRay)) * (MultiscatterPhase[2].rgb * CurrentDensity.x + MultiscatterPhase[2].a * CurrentDensity.y);

            MultiscatterRay.Direction = MultiscatterDirections[3];
            MultiScatterTransmittance += Transmittance(LookUpOpticalDepth(MultiscatterRay)) * (MultiscatterPhase[3].rgb * CurrentDensity.x + MultiscatterPhase[3].a * CurrentDensity.y);

            MultiscatterRay.Direction = MultiscatterDirections[4];
            MultiScatterTransmittance += Transmittance(LookUpOpticalDepth(MultiscatterRay)) * (MultiscatterPhase[4].rgb * CurrentDensity.x + MultiscatterPhase[4].a * CurrentDensity.y);

            MultiscatterRay.Direction = MultiscatterDirections[5];
            MultiScatterTransmittance += Transmittance(LookUpOpticalDepth(MultiscatterRay)) * (MultiscatterPhase[5].rgb * CurrentDensity.x + MultiscatterPhase[5].a * CurrentDensity.y);

            MultiScatterTransmittance /= 6.0f;
            MultiscatterAccum += MultiScatterTransmittance * ViewTransmittance;
        }
        #endif
        vec3 TransmittedSunLight = LightTransmittance * ViewTransmittance;
        AccumRayleigh += TransmittedSunLight * CurrentDensity.x;
        AccumMie      += TransmittedSunLight * CurrentDensity.y;
        RayMarchPosition += RayMarchStepLength;
    }
    vec3 AtmosphereColor = SunColor * ((AccumRayleigh * ScatteringStrengthRayleigh + AccumMie * ScatteringStrengthMie)  + MultiscatterAccum) * RayMarchStepLength;
    AtmosphereColor = max(AtmosphereColor, vec3(0.0f));
    if(IntersectEarth){
        vec3 ViewTransmittance = Transmittance(ViewOpticalDepth);
        AtmosphereColor += EarthColor * ViewTransmittance; // TODO: diffuse shading of the ground
        ViewOpticalDepth = vec3(1e10);
    }
    return AtmosphereColor;
}

// The reason why I'm adding "ATI" to the end of these functions is because they are from the paper "Rendering outdoor light scattering in real time" and that was published by ATI

const vec3  BetaR_ATI = vec3(4.395e-6, 1.083e-5, 3.364e-5);
const float BetaM_ATI = 1.78e-5     ;

vec3 ComputeAtmosphericScatteringATI(in vec3 light, in vec3 view, out vec3 viewopticaldepth){
    float costheta = dot(view, light);
    vec3 ViewPos = GetCameraPositionEarth();
    ViewPos.y += 20.0f * KM_SIZE;
    float AtmosphereDistance = RaySphereIntersect(ViewPos, view, AtmosphereRadius);
    // L(s, theta) = L_0 * F_ex(s) + L_in(s, theta)
    const vec3 TotalScatter = (BetaR_ATI + BetaM_ATI);
    viewopticaldepth = TotalScatter * AtmosphereDistance;
    vec3 Extinction = exp(-viewopticaldepth);
    vec3 InScattering = Extinction * (1.0f - Extinction) * (PhaseRayleigh(costheta) + PhaseMie(costheta)) / TotalScatter;
    return  1e-2 * (Extinction  + InScattering);
}

// Approximated sky, based on VOID 2.0 Dev shader
// l - light dir
// v - view dir
// o - optical depth
// This from my understanding is basically a single ray march step shader
vec3 ComputeAtmosphereicScatteringVOID2(in vec3 l, in vec3 v, out vec3 o){
    // Just to be safe
    l = normalize(l);
    v = normalize(v);
    // First we start by computing the optical depth
    // VOID 2.0 Dev uses a special function for this
    vec3 OpticalDepth = exp2(-0.1f * v) * (1.5f - dot(v, vec3(0.0f, 1.0f, 0.0f)));// Fill in later


    // Then we compute scattered light
    float cosTheta = dot(l, v);
    vec4 ScatteredLight;
    ScatteredLight.xyz = OpticalDepth.x * PhaseRayleigh(cosTheta) * vec3(1.0f);
    ScatteredLight.w = OpticalDepth.y * PhaseMie(cosTheta);

    return ScatteredLight.xyz;
}

#endif