#ifndef COMMON_FUNCS_GLSL
#define COMMON_FUNCS_GLSL 1

#define MATH_PI 3.14159265359
#define MATH_E 2.71828182846

#include "uniforms.glsl"
#include "structures.glsl"

// TODO: loops through all rows
vec4 GetRandomNumber(void){
    vec2 noisecoords;
    noisecoords.x = float(frameCounter) / float(noiseTextureResolution);
    // Do a bunch of module stuff to loop through all rows
    // But im lazy
    return texture2D(noisetex, noisecoords);
}

// Taken from continuum shaders
float Get3DNoise(in vec3 pos);
float PhaseMie(in float cosTheta);
float PhaseHenyeyGreenstein(in float cosTheta, in float g);

// A lot of these were taken from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float Get3DNoise1(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
//
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float GetNoise1D(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

float GetNoise2D(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// This one has non-ideal tiling properties that I'm still tuning
float Get3DNoise2(vec3 x) {
	const vec3 step = vec3(110, 241, 171);

	vec3 i = floor(x);
	vec3 f = fract(x);
 
	// For performance, compute the base input to a 1D hash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

// https://www.shadertoy.com/view/4lGGWy
float Get3DNoise3( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture2D(noisetex, (uv+0.5)/256.0).yx;
	return mix( rg.x, rg.y, f.z );
} 

struct Plane {
    vec3 Position;
    vec3 Normal;
};


struct Ray {
    vec3 Origin;
    vec3 Direction;
};

float Intersect(in Ray ray, in Plane plane){
    float div = dot(ray.Direction, plane.Normal);
    float num = dot(plane.Position - ray.Origin, plane.Normal);
    return num / div;
}

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
    float Noise = Get3DNoise(pos * 0.001f + frameTimeCounter * 0.1f);
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

vec3 GetSkyTopColor(void){
    float Input = abs((float(worldTime) / 24000.0f) * 2.0f - 1.0f);
    // RED
    float Red = 0.5 * pow(Input, 7.0f);
    // GREEN
    float Green = 0.7 * pow(Input, 2.0f);
    // BLUE
    float Blue = 0.9 * pow(Input, 0.7f);
    return mix(vec3 (Red, Green, Blue), skyColor, 0.5f);
}


vec3 ApplyFog(in vec3 color, in vec3 worldpos){
    float dist = distance(worldpos, gbufferModelView[3].xyz);
    vec3 toPos = normalize(worldpos - gbufferModelView[3].xyz);
    float strength = 1.0f - max(dot(toPos, vec3(0.0f, 1.0f, 0.0f)), 0.0f);
    float extinction = exp(dist * 0.1f);
    float inscattering = exp(dist * 0.1f) * strength;
    vec3 FoggyColor = color * extinction + inscattering * vec3(1.0f);
    return FoggyColor;
}


vec3 GetWorldSpace(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0);

const float KM_SIZE = 1000.0f;
const float EarthRadius = 6360.0f * KM_SIZE;
const float AtmosphereHeight = 80.0f * KM_SIZE;
const float AtmosphereRadius = AtmosphereHeight + EarthRadius;

// Taken from https://www.shadertoy.com/view/wlBXWK 

float RaySphereIntersect(vec3 origin, vec3 dir, float radius, float max_distance = KM_SIZE * 10000.0f) { 
    float A = dot(dir, dir);
    float B = 2.8f * dot(dir, origin);
    float C = dot(origin, origin) - (radius * radius);
    float D = (B * B) - 4.0f * A * C;
    // compiler is probably smart enough to optimize away the recomputations
    vec2 len = vec2(
        max((-B - sqrt(D)) / (2.0f * A), 0.0f),
        min((-B + sqrt(D)) / (2.0f * A), max_distance)
    );
    return len.y - len.x;
} 

const float ScaleHeightRayleigh = 7.994f * KM_SIZE;
const float ScaleHeightMie = 1.200f * KM_SIZE;

// Constant density altitude
// Use d\left(a,h\right)=\frac{1}{a}\int_{0}^{a}\exp\left(-\frac{x}{h}\right)dx in desmos
// a = atmosphere height
// h = scale height

// Actual value for rayleigh is 0.099995460007
// But that was too small
const float ConstantDensityRayleigh = 0.25;
// Actual value 0.015
// But that was too big
const float ConstantDensityMie = 0.005;

// I should fix functions that use these instead of integration over a constant
float CalculateDensityRayleigh(float h){
    return exp(-h / ScaleHeightRayleigh);
}

float CalculateDensityMie(float h){
    return exp(-h / ScaleHeightMie);
}

float CalculateDensityOzone(float h){
    return exp(-h / ScaleHeightMie);
}

// Ozone function:
// 0.07\left(\frac{1}{1+\left(x-29.874\right)^{2}}\right)^{0.7}
// Based of an approximation of https://www.shadertoy.com/view/wlBXWK 
// Original function:
// c\left(x\right)=\max\left(\min\left(x,\ 1\right),0\right) this is clamp()
// c\left(\frac{1.0}{\frac{\cosh\left(30-x\right)}{3}}\cdot\exp\left(-\frac{x}{7.994}\right)\right)
// x in both functions is in kilometers
// I'd galdy appreciate if someone finds the correct function or a more accurate function
vec3 CalculateAtmosphericDensity(float height){
    vec3 Density;
    Density.xy = exp(-height / vec2(ScaleHeightRayleigh, ScaleHeightMie));
    float x = height / KM_SIZE; // The function squares x, and x is supposed to be in km
    x  = x - 29.874f;
    x *= x;
    x  = 1.0f / (1.0f + x);
    x  = pow(x, 0.7);
    x *= 0.07f;
    Density.z = x;
    return Density;
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

float PhaseRayleigh(in vec3 v, in vec3 l){
    return PhaseRayleigh(dot(v, l));
}

float PhaseMie(in vec3 v, in vec3 l){
    return PhaseMie(dot(v, l));
}

const vec3 ScatteringRayleigh = vec3(5.5e-6, 13.0e-6, 22.4e-6);
const vec3 AbsorptionRayleigh = vec3(0.0f); // Negligible 
const vec3 ExtinctionRayleigh = ScatteringRayleigh + AbsorptionRayleigh;
const float ScatteringMie = 21e-6;
const float AbsorptionMie = 1.1f * ScatteringMie;
const float ExtinctionMie = ScatteringMie + AbsorptionMie;
const vec3 ScatteringOzone = vec3(0.0f); // Ozone does not scatter light
const vec3 AbsorptionOzone = vec3(2.04e-5, 4.97e-5, 1.95e-6);
const vec3 ExtinctionOzone = ScatteringOzone + AbsorptionOzone;
const float SunBrightness = 20.0f;
const vec3 SunColor = vec3(1.0f, 1.0f, 1.0f) * SunBrightness;
const float SunColorBrightness = 0.3f;

// Thes values were the best all rounder for both performance and quality
// I will add a slider for both of these (if I knew how) so users with better computers can get the sky the can acheive
#define INSCATTERING_STEPS 8
#define OPTICAL_DEPTH_STEPS 2

// Optical depth:
// x - rayleigh
// y - mie
// z - ozone

vec3 ComputeOpticalDepth(Ray AirMassRay, float pointdistance) {
    vec3 OpticalDepth = vec3(0.0f);
    float RayMarchStepLength = pointdistance / float(OPTICAL_DEPTH_STEPS);
    float RayMarchPosition = 0.0f;
    for(int Step = 0; Step < OPTICAL_DEPTH_STEPS; Step++){
        vec3 SampleLocation = AirMassRay.Origin + AirMassRay.Direction * (RayMarchPosition + 0.5f * RayMarchStepLength);
        float Height = distance(SampleLocation, vec3(0.0f)) - EarthRadius;
        OpticalDepth += CalculateAtmosphericDensity(Height);
        RayMarchPosition += RayMarchStepLength;
    }
    OpticalDepth *= RayMarchStepLength;
    return OpticalDepth;
}

vec3 Transmittance(in vec3 OpticalDepth){
    vec3 Tau = 
        OpticalDepth.x * ExtinctionRayleigh +
        OpticalDepth.y * ExtinctionMie +
        OpticalDepth.z * ExtinctionOzone;
    //gl_FragData[1].rgb = exp(-TotalOpticalDepth);
    return exp(-Tau);
}

vec3 ComputeTransmittance(Ray ray, float pointdistance) {
    return Transmittance(ComputeOpticalDepth(ray, pointdistance));
}

// TODO: Optimize this 
// Also switch to trapezoidal integration

vec3 ComputeAtmosphericScattering(in vec3 light, in vec3 dir, inout vec3 viewtransmittance) {
    //return vec3(1.0f);
    //dir.y = max(dir.y, 0.1f);
    //dir = normalize(dir);
    vec3 ViewPos = vec3(0.0f, EarthRadius, 0.0f);
    float AtmosphereDistance = RaySphereIntersect(ViewPos, dir, AtmosphereRadius);
    vec3 AtmosphereIntersectionLocation = ViewPos + dir * AtmosphereDistance;
    vec3 AccumRayleigh = vec3(0.0f), AccumMie = vec3(0.0f);
    // TODO: precompute cos theta^2 for both functions
    float CosTheta = dot(light, dir);
    vec3 ScatteringStrengthRayleigh = PhaseRayleigh(CosTheta) * ScatteringRayleigh;
    float ScatteringStrengthMie = PhaseMie(CosTheta) * ScatteringMie;
    float RayMarchStepLength = AtmosphereDistance / float(INSCATTERING_STEPS);
    float RayMarchPosition = 0.0f;
    vec3 ViewOpticalDepth = vec3(0.0f); 
    vec3 ViewTransmittance = vec3(1.0f);
    for(int InscatteringStep = 0; InscatteringStep < INSCATTERING_STEPS; InscatteringStep++){
        vec3 SampleLocation = ViewPos + dir * (RayMarchPosition + 0.5f * RayMarchStepLength);
        float CurrentAltitude = distance(SampleLocation, vec3(0.0f)) - EarthRadius;
        vec3 CurrentDensity = CalculateAtmosphericDensity(CurrentAltitude);
        ViewOpticalDepth += CurrentDensity * RayMarchStepLength;
        ViewTransmittance *= Transmittance(ViewOpticalDepth);
        float LightLength = RaySphereIntersect(SampleLocation, light, AtmosphereRadius);
        Ray LightRay;
        LightRay.Origin = SampleLocation;
        LightRay.Direction = light;
        vec3 TransmittedSunLight = ComputeTransmittance(LightRay, LightLength) * ViewTransmittance;
        vec3 TransmittedAccumSunLight = vec3(1.0f);
        vec3 CurrentAltitudeScatteringStrengthRayleigh = CurrentDensity.x * ScatteringStrengthRayleigh;
        float CurrentAltitudeScatteringStrengthMie     = CurrentDensity.y * ScatteringStrengthMie;
        AccumRayleigh += TransmittedSunLight * TransmittedAccumSunLight * CurrentAltitudeScatteringStrengthRayleigh * RayMarchStepLength;
        AccumMie      += TransmittedSunLight * TransmittedAccumSunLight * CurrentAltitudeScatteringStrengthMie      * RayMarchStepLength;
        RayMarchPosition += RayMarchStepLength;
    }
    viewtransmittance = ViewTransmittance;
    return SunColor * (AccumRayleigh + AccumMie);
}

vec3 ComputeAtmosphericScattering(in vec3 light, in vec3 dir){
    vec3 temp;
    return ComputeAtmosphericScattering(light, dir, temp);
}

// https://www.shadertoy.com/view/llffzM 
const vec3 SkyColor = vec3(0.39, 0.57, 1.0);
const vec3 SkyGradientBottom = vec3(0.8, 0.9, 1.0f);

vec3 ComputeInaccurateAtmosphere(in vec3 light, in vec3 dir, out vec3 sun) {
    vec3 Rayleigh = mix(SkyGradientBottom, SkyColor, min(dir.y + 0.5f, 1.0f)); 
    float cosTheta = dot(light, dir);
    float Mie = pow(cosTheta * 0.5f + 0.5f, 42.0f) * 0.3f;
    return Rayleigh + Mie;
}


const float SunSpotSize = 0.999;

vec3 ComputeInaccurateSun(in vec3 light, in vec3 dir, in vec3 absorption) {
    if(dot(light, dir) < SunSpotSize){
        return vec3(0.0f);
    }
    return vec3(0.0f);
}

#define PHYSICALLY_BASED_ATMOSPHERE // Use a physically based model for rendering the atmosphere

vec3 ComputeAtmosphereColor(in vec3 light, in vec3 dir, out vec3 aux){
    #ifdef PHYSICALLY_BASED_ATMOSPHERE
    return ComputeAtmosphericScattering(light, dir, aux);
    #else
    return ComputeInaccurateAtmosphere(light, dir, aux);
    #endif
}

vec3 ComputeAtmosphereColor(in vec3 light, in vec3 dir){
    vec3 temp;
    return ComputeAtmosphereColor(light, dir, temp);
}


vec3 saturate(vec3 val);


vec3 ComputeSunColor(in vec3 light, in vec3 dir){
    if(dot(light, dir) < SunSpotSize){
        return vec3(0.0f);
    }
    vec3 ViewPos = vec3(0.0f, EarthRadius, 0.0f);
    float dist = RaySphereIntersect(ViewPos, dir, AtmosphereRadius);
    Ray SunRay;
    SunRay.Origin = ViewPos;
    SunRay.Direction = dir;
    vec3 Transmittance = ComputeTransmittance(SunRay, dist);
    // The saturate breaks the physical basis of this function
    // But gives us nice orange color without too white during the day
    return saturate(Transmittance * SunColor);
}

vec3 ComputeSunColor(in vec3 light, in vec3 dir, in vec3 transmittance){
    if(dot(light, dir) < SunSpotSize){
        return vec3(0.0f);
    }
    // The saturate breaks the physical basis of this function
    // But gives us nice orange color without too white during the day
    return saturate(transmittance * SunColor);
}

vec4 CalculateShadow(in sampler2D ShadowDepth, in vec3 coords){ 
    return vec4(step(coords.z, texture2D(ShadowDepth, coords.xy).r));
}

vec3 DistortShadow(vec3 pos);

vec3 saturate(vec3 val){
    return clamp(val, vec3(0.0f), vec3(1.0f));
}

float saturate(float val){
    return clamp(val, 0.0f, 1.0f);
}

float dotunorm(vec3 lhs, vec3 rhs){
    return saturate(dot(lhs, rhs));
}

vec3 GetViewSpace(vec2 texcoord, sampler2D depthsampler = depthtex0){
    vec4 ndc = vec4(texcoord * 2.0f - 1.0f, texture2D(depthsampler, texcoord).r * 2.0f - 1.0f, 1.0f);
    ndc = gbufferProjectionInverse * ndc;
    return ndc.xyz / ndc.w;
}

vec3 GetPlayerSpace(vec2 texcoord, sampler2D depthsampler = depthtex0){
    return (gbufferModelViewInverse * vec4(GetViewSpace(texcoord, depthsampler), 1.0f)).xyz;
}

vec3 GetWorldSpace(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0) {
    return GetPlayerSpace(texcoord, depthsampler) + cameraPosition;
}

vec3 GetShadowSpace(vec2 texcoord, sampler2D depthsampler = depthtex0){
    vec4 pos = vec4(GetPlayerSpace(texcoord, depthsampler), 1.0f);
    pos = shadowProjection * shadowModelView * pos;
    pos.xyz /= pos.w;
    return pos.xyz;
}

vec3 GetShadowSpaceDistorted(vec2 texcoord, sampler2D depthsampler = depthtex0){
    return DistortShadow(GetShadowSpace(texcoord, depthsampler));
}

vec3 GetShadowSpaceDistortedSample(vec2 texcoord, sampler2D depthsampler = depthtex0){
    return GetShadowSpaceDistorted(texcoord, depthsampler) * 0.5f + 0.5f;
}

vec3 GetShadowSpaceSample(vec2 texcoord, sampler2D depthsampler = depthtex0){
    return GetShadowSpace(texcoord, depthsampler) * 0.5f + 0.5f;
}

#define SHADOW_DISTORT_FACTOR 0.10f
#define SHADOW_DISTORT_FACTOR_INV (1.0f - SHADOW_DISTORT_FACTOR)
const float SHADOW_DISTORT_EXP = 3;
const float  SHADOW_DISTORT_ROOT = 1.0f / SHADOW_DISTORT_EXP;

float DistortionFactor(in vec2 position) {
    float len = sqrt(position.x * position.x + position.y * position.y) * 0.9f;
    return (1.0f - SHADOW_MAP_BIAS) + len * SHADOW_MAP_BIAS;
}

vec2 DistortShadowCoords(in vec2 shadowcoords){
    return shadowcoords * 1.0f / DistortionFactor(shadowcoords);
}

vec3 DistortShadowPos(in vec3 ShadowPos){
    return vec3(DistortShadowCoords(ShadowPos.xy), ShadowPos.z * ShadowDepthCompressionFactor);
}


vec3 DistortShadow(vec3 pos) {
    return DistortShadowPos(pos);
}

// moments.x - The mean depth
// moments.y - The mean squared depth
float ChebychevsInequality(float T, vec2 moments){
    float variance_2 = max(moments.y - (moments.x * moments.x), 0.0002);
    float TmU = T - moments.x;
    float  TmU2 = TmU * TmU;
    return variance_2 / (variance_2 + TmU2);
}

// Taken from "OpenGL Cookbook, Light and Shadows, Implementing variance shadow mapping"
float VarianceShadowMap(float depth, vec2 moments){
    float pmax = ChebychevsInequality(depth, moments);
    return max(pmax, (depth <= moments.x ? 1.0f : 0.2));
}

// Based on Continuum's implementation
float ContinuumChebyshev(vec2 moments, float depth){
    if(depth <= moments.x){
        // The depth is less than the mean, so it's not in shadow at all
        return 1.0f;
    }
    // There is some shadowing
    // Calculate the variance
    float variance = max(moments.y - (moments.x * moments.x), 0.000002f); // use the same minimum value that Continuum did
    float MeanOffset = depth - moments.x;
    return variance / (variance + MeanOffset * MeanOffset);
}

float Gaussian(float stddev, float x){
    float stddev2 = stddev * stddev;
    float stddev2_2 = stddev2 * 2.0f;
    return pow(MATH_PI * stddev2_2, -0.5f) * exp(-(x * x / stddev2_2));
}

// This is based off continuum's tutorial, I might switch to a guassian method instead later
mat2 CreateRandomRotation(in vec2 texcoord){
	float Rotation = texture2D(noisetex, texcoord).r;
	return mat2(cos(Rotation), -sin(Rotation), sin(Rotation), cos(Rotation));
}

mat2 CreateRandomRotationScreen(in vec2 texcoord){
	return CreateRandomRotation(texcoord * vec2(viewWidth / noiseTextureResolution, viewHeight / noiseTextureResolution));
}

float FadeShadow(in float centerdistance){
    return clamp(centerdistance - ShadowDistanceFade, 0.0f, ShadowDistanceFadeLength) / ShadowDistanceFadeLength;
}

const float FadeBegin = 0.9f;
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

// https://www.geeksforgeeks.org/total-area-two-overlapping-rectangles/ 

struct Square {
    vec2 Center;
    float Side;
};

struct SquareBounds {
    vec2 Left;
    vec2 Right;
};

SquareBounds CreateBounds(in Square s){
    SquareBounds bounds;
    vec2 BoundsOffset = vec2(s.Side * 0.5f);
    bounds.Right = s.Center + BoundsOffset;
    bounds.Left = s.Center - BoundsOffset;
    return bounds;
}

float GetCommonArea(in Square lhs, in Square rhs) {
    SquareBounds bounds_rhs = CreateBounds(rhs), bounds_lhs = CreateBounds(lhs);
    float X = min(bounds_rhs.Right.x, bounds_lhs.Right.x) - max(bounds_rhs.Left.x, bounds_lhs.Left.x);
    float Y = min(bounds_rhs.Right.y, bounds_lhs.Right.y) - max(bounds_rhs.Left.x, bounds_lhs.Left.y);
    //X = saturate(X);
    //Y = saturate(Y);
    // In this case we will know that the squares will intersect
    return X * Y;
}

// https://hub.jmonkeyengine.org/t/round-with-glsl/8186 
vec2 Round(in vec2 coords){
    vec2 signum=sign(coords);//1
    coords=abs(coords);//2
    vec2 coords2 =fract(coords);//3
    coords=floor(coords);//4
    coords2=ceil((sign(coords2-0.5)+1.0)*0.5);//5
    coords=(coords+coords2)*signum;
    return coords;
}

// Tool to analytically find the soft shadow
float CalculateShadowContribution(in vec2 offset, in vec2 origin){
    // Calculate the actual orgin 
    vec2 ResCoords = origin * shadowMapResolution;
    vec2 Rounded = Round(ResCoords);
    Square Sample;
    Sample.Center = offset;
    Sample.Side = 1.0f;
    Square ShadowSampleArea;
    ShadowSampleArea.Center = Rounded - ResCoords;
    ShadowSampleArea.Side = ShadowSamplesPerSide;
    // We find the shared area between the sample
    float SharedArea = GetCommonArea(Sample, ShadowSampleArea);
    return SharedArea / ShadowArea;
}

vec3 ComputeVisibility(in vec3 ShadowCoord){
    float ShadowVisibility0 = shadow2D(shadowtex0, ShadowCoord, 0).r;
    float ShadowVisibility1 = shadow2D(shadowtex1, ShadowCoord, 0).r;
    vec4 ShadowColor0 = texture2D(shadowcolor0, ShadowCoord.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * ShadowColor0.a;
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
}

vec3 ComputeShadow(in SurfaceStruct Surface){
    if(rainStrength > 0.99f){
        return vec3(0.0f);
    }
    float DiffThresh = length(Surface.ShadowScreen.xy) + 0.10f;
    DiffThresh *= 3.0f / (shadowMapResolution / 2048.0f);
    float AdjustedShadowDepth = Surface.ShadowScreen.z - max(0.0028f * DiffThresh * (1.0f - Surface.NdotL) * Surface.Distortion * Surface.Distortion, 0.00015f) * 2.0f;
    mat2 Transformation = CreateRandomRotationScreen(Surface.Screen.xy + frameTimeCounter) * SoftShadowScale;
    vec3 ShadowAccum = vec3(0.0f);
    for(float y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y += ShadowStep){
        for(float x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x+= ShadowStep){
            ShadowAccum += ComputeVisibility(vec3(Surface.ShadowScreen.xy + vec2(x, y) * Transformation, AdjustedShadowDepth));
        }
    }
    ShadowAccum *= 1.0f / ShadowQualityArea;
    return PostProcessShadow(ShadowAccum, Surface);
}

vec3 GetLightDirection(void){
    return normalize((shadowModelViewInverse * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
}


// Originally aken from Continuum shaders
// Desmos copy paste
// clamp: c\left(x,\ l,\ u\right)=\max\left(\min\left(x,\ u\right),l\right)
// function: c\left(\max\left(\frac{1.0}{\left(5.6\left(1.0\ -\ c\left(1.1x,\ 0.0,\ 1.0\right)\right)\right)^{2.0}}-0.02435,\ 0.0\right),\ 0.0,\ 1.0\right)^{0.9}
float GetLightMapTorchContinuum(in float lightmap) {
	lightmap 		= clamp(lightmap * 1.10f, 0.0f, 1.0f);
	lightmap 		= 1.0f - lightmap;
	lightmap 		*= 5.6f;
	lightmap 		= 1.0f / pow((lightmap + 0.8f), 2.0f);
	lightmap 		-= 0.02435f;
	lightmap 		= max(0.0f, lightmap);
	//lightmap 		*= 0.008f;
	lightmap 		= clamp(lightmap, 0.0f, 1.0f);
	lightmap 		= pow(lightmap, 0.9f);
	return lightmap;
}
// A more appoximate but faster version
// k\left(x^{p}\right)+o
// k=3.9
// p=5.06
// o=0.02435
float GetLightMapTorchApprox(in float lightmap) {
    const float K = 2.0f;
    const float P = 5.06f;
    const float Offset = 0.02435f;
    return K * pow(lightmap, P) + Offset;
}

/* Desmos
k\left(\frac{s^{p}-0.5s+o}{n}\right)^{f}
s=\ x+0.062
p=1.36
o\ =\ 0.0082
n=0.563
f=1.2
k=0.5
*/



float GetLightMapSky(in float sky){
    const float NonNegative = 0.062f + 0.01f; // last term is bias
    const float Power = 1.36f;
    const float Offset = 0.0082f;
    const float NormalizationFactor = 0.563f;
    const float FractionalPower = 1.2f;
    const float ScalingFactor = 0.5f;
    sky += NonNegative;
    sky = pow(sky, Power) - 0.5f * sky + Offset;
    sky /= NormalizationFactor;
    sky = pow(sky, FractionalPower);
    // why does vscode give a green blue highligh to "Fract" (case senstitive)?
    return sky * ScalingFactor;
}

// Put this in the fragment shader if the transformation curve is not straight, if not then it goes in vertex shader
void AdjustLightMap(inout SurfaceStruct surface){
    surface.Torch = GetLightMapTorchApprox(surface.Torch);
    surface.Sky = GetLightMapSky(surface.Sky);
}

void ComputeLightmap(in SurfaceStruct Surface, inout ShadingStruct Shading){
    Shading.Torch = Surface.Torch * TorchEmitColor;
    // TODO: make this a flat varying variable
    Shading.Sky = Surface.Sky * mix(GetSkyTopColor(), vec3(0.5f), 0.5f);
}

// Better name would be construct, but constructors don't exist in a functional programming language
void CreateSurfaceStructDeferred(in vec2 texcoords, in vec3 l, out SurfaceStruct Surface){
    Surface.Diffuse = texture2D(colortex0, texcoords);
    Surface.Normal = texture2D(colortex1, texcoords).rgb * 2.0f - 1.0f;

    vec2 LightMap = texture2D(colortex2, texcoords).st; 
    Surface.Torch = LightMap.x;
    Surface.Sky = LightMap.y;
    AdjustLightMap(Surface);

    // In a way the screen space coords contain the texcoords
    Surface.Screen = vec3(texcoords, texture2D(depthtex0, texcoords).r);
    Surface.Clip = Surface.Screen * 2.0f - 1.0f;
    vec4 UnDivW = gbufferProjectionInverse * vec4(Surface.Clip, 1.0f);
    Surface.View = UnDivW.xyz / UnDivW.w;
    Surface.Player = (gbufferModelViewInverse * vec4(Surface.View, 1.0f)).xyz;
    Surface.World = Surface.Player + cameraPosition;
    UnDivW = shadowProjection * shadowModelView * vec4(Surface.Player, 1.0f);
    Surface.ShadowClip = UnDivW.xyz;// / UnDivW.w;
    Surface.Distortion = DistortionFactor(Surface.ShadowClip.xy);
    Surface.ShadowScreen = vec3((Surface.ShadowClip.xy * 1.0f / Surface.Distortion), Surface.ShadowClip.z * ShadowDepthCompressionFactor) * 0.5f + 0.5f;

    Surface.NdotL = dotunorm(Surface.Normal, l);
}

vec3 GetScreenCoords(in vec4 fragcoord){
    //fragcoord.xyz *= fragcoord.w;
    // Move this to vert shader if possible
    vec2 Screen = fragcoord.xy / vec2(viewWidth, viewHeight);
    return vec3(Screen, fragcoord.z);
}

// Taken from SEUS v10.1
vec4 Cubic(float x)
{
    float x2 = x * x;
    float x3 = x2 * x;
    vec4 w;
    w.x =   -x3 + 3*x2 - 3*x + 1;
    w.y =  3*x3 - 6*x2       + 4;
    w.z = -3*x3 + 3*x2 + 3*x + 1;
    w.w =  x3;
    return w / 6.f;
}

vec4 BicubicTexture(in sampler2D tex, in vec2 coord)
{
	int resolution = 64;

	coord *= resolution;

	float fx = fract(coord.x);
    float fy = fract(coord.y);
    coord.x -= fx;
    coord.y -= fy;

    vec4 xcubic = Cubic(fx);
    vec4 ycubic = Cubic(fy);

    vec4 c = vec4(coord.x - 0.5, coord.x + 1.5, coord.y - 0.5, coord.y + 1.5);
    vec4 s = vec4(xcubic.x + xcubic.y, xcubic.z + xcubic.w, ycubic.x + ycubic.y, ycubic.z + ycubic.w);
    vec4 offset = c + vec4(xcubic.y, xcubic.w, ycubic.y, ycubic.w) / s;

    vec4 sample0 = texture2D(tex, vec2(offset.x, offset.z) / resolution);
    vec4 sample1 = texture2D(tex, vec2(offset.y, offset.z) / resolution);
    vec4 sample2 = texture2D(tex, vec2(offset.x, offset.w) / resolution);
    vec4 sample3 = texture2D(tex, vec2(offset.y, offset.w) / resolution);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix( mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

vec4 SampleTextureAtlas(in vec2 coords){
    return texture2D(texture, coords);
}

void CreateSurfaceStructForward(in vec3 fragcoord, in vec3 normal, in vec3 l, out SurfaceStruct Surface){
    Surface.Diffuse = SampleTextureAtlas(gl_TexCoord[0].st);
    Surface.Normal = normal;

    vec2 LightMap = gl_TexCoord[1].st; 
    Surface.Torch = LightMap.x;
    Surface.Sky = LightMap.y;
    AdjustLightMap(Surface);

    // In a way the screen space coords contain the texcoords
    Surface.Screen = vec3(fragcoord.xy, fragcoord.z);
    Surface.Clip = Surface.Screen * 2.0f - 1.0f;
    vec4 UnDivW = gbufferProjectionInverse * vec4(Surface.Clip, 1.0f);
    Surface.View = UnDivW.xyz / UnDivW.w;
    Surface.Player = (gbufferModelViewInverse * vec4(Surface.View, 1.0f)).xyz;
    Surface.World = Surface.Player + cameraPosition;
    UnDivW = shadowProjection * shadowModelView * vec4(Surface.Player, 1.0f);
    Surface.ShadowClip = UnDivW.xyz;// / UnDivW.w;
    Surface.Distortion = DistortionFactor(Surface.ShadowClip.xy);
    Surface.ShadowScreen = vec3((Surface.ShadowClip.xy * 1.0f / Surface.Distortion), Surface.ShadowClip.z * ShadowDepthCompressionFactor) * 0.5f + 0.5f;

    Surface.NdotL = dotunorm(Surface.Normal, l);
}

vec3 CalculateSunShading(in SurfaceStruct Surface, in vec3 sun){
    return Surface.NdotL * sun * ComputeShadow(Surface);
}

// Taken from continuum shaders
float Get3DNoise(in vec3 pos) {
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	vec2 coord =  (uv  + 0.5f) / noiseTextureResolution;
	vec2 coord2 = (uv2 + 0.5f) / noiseTextureResolution;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}

// Should be flat varying from vert shader
// But I'm lazy
vec3 GetEyePositionShadow(void){
    vec4 eye = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0f, 0.0f, 0.1f, 1.0f);
    return eye.xyz;
}

// Same for this
vec3 GetEyePositionWorld(void){
    vec4 eye = gbufferModelViewInverse * vec4(0.0f, 0.0f, 0.1f, 1.0f);
    return eye.xyz + cameraPosition;
}

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

void ShadeSurfaceStruct(in SurfaceStruct Surface, inout ShadingStruct Shading, in vec3 sundir, in vec3 suncol){
    Shading.Sun = CalculateSunShading(Surface, suncol);
    ComputeLightmap(Surface, Shading);
    #ifndef DEFERRED_SHADING
    ComputeVolumetricLighting(Surface, Shading, sundir, suncol);
    #endif
    Shading.Volumetric *= suncol;
}

const vec3 FogScattering = vec3(2.0e-9);
const vec3 FogAbsorbtion = vec3(1.5e-3);
const vec3 FogExtinction = FogAbsorbtion;

vec3 ComputeFog(in vec3 light, in vec3 dir, in vec3 color, in float dist){
    vec3 transmittedColor = color * exp(-FogExtinction * dist);
    vec3 inscatteredColor = fogColor * exp(-FogScattering * dist);
    return transmittedColor + inscatteredColor;
}

void ComputeColor(in SurfaceStruct Surface, inout ShadingStruct Shading){
    vec3 Lighting = Shading.Sun + Shading.Torch + Shading.Sky;
    Shading.Color = Surface.Diffuse * vec4(Lighting, 1.0f);// + vec4(Shading.Volumetric, 0.0f);
    //Shading.Color.rgb = ComputeFog(vec3(0.0f), vec3(0.0f), Shading.Color.rgb, 100);
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st);
    //Shading.Color = vec4(vec3(Surface.NdotL), 1.0f);
}

float Guassian(in float sigma, in float x){
    float sigma2_2 = 2.0f * sigma * sigma;
    return (1.0f / sqrt(MATH_PI * sigma2_2)) * exp(x * x / sigma2_2);
}

vec3 GetSunMoonDirection(in vec3 viewPos){
    /*
    vec4 v4pos = vec4(viewPos, 1.0f);
    v4pos = gbufferModelViewInverse * v4pos;
    return normalize(v4pos.xyz);*/
    return normalize(mat3(gbufferModelViewInverse) * viewPos);
}

vec3 GetLightColor(void){
    vec3 SunDirection = GetSunMoonDirection(sunPosition);
    vec3 SunColor = ComputeSunColor(SunDirection, SunDirection) + ComputeAtmosphereColor(SunDirection, SunDirection);
    vec3 MoonColor = vec3(0.1f, 0.15f, 0.9f);
    return SunColor * 0.7f;
}

//	Classic Perlin 3D Noise 
//	by Stefan Gustavson
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
float PerlinNoise(vec2 P){
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  float noise = 2.3 * n_xy;
  return pow(noise * 0.5f + 0.5f, 3.0f);
}

#endif