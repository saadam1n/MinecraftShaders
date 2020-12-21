#ifndef COMMON_FUNCS_GLSL
#define COMMON_FUNCS_GLSL 1

#define MATH_PI 3.1415

#include "uniforms.glsl"
#include "structures.glsl"

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

float CalculateDensityRayleigh(float h){
    return exp(-h / ScaleHeightRayleigh);
}

float CalculateDensityMie(float h){
    return exp(-h / ScaleHeightMie);
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
#define OPTICAL_DEPTH_STEPS 8

const vec3 ScatteringCoefficientRayleigh = vec3(5.5e-6, 13.0e-6, 22.4e-6);
const vec3 AbsorbtionCoefficientRayleigh = vec3(0.0f); // Negligible 
const vec3 ExtinctionCoefficientRayleigh = ScatteringCoefficientRayleigh + AbsorbtionCoefficientRayleigh;
const float ScatteringCoefficientMie = 21e-6;
const float AbsorbtionCoefficientMie = 1.1f * ScatteringCoefficientMie;
const float ExtinctionCoefficientMie = ScatteringCoefficientMie + AbsorbtionCoefficientMie;
const float SunBrightness = 20.0f;
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
    return exp(-TotalOpticalDepth);
}

vec3 ComputeTransmittance(Ray ray, float pointdistance) {
    return Transmittance(ComputeOpticalDepth(ray, pointdistance));
}

// TODO: Optimize this 
// Also switch to trapezoidal integration

vec3 ComputeAtmosphericScattering(in vec3 light, in vec3 dir){
    //dir.y = saturate(dir.y);
    //dir = normalize(dir);
    float t0;
    vec3 ViewPos = vec3(0.0f, EarthRadius, 0.0f);
    float AtmosphereDistance = RaySphereIntersect(ViewPos, dir, AtmosphereRadius);
    vec3 AtmosphereIntersectionLocation = ViewPos + dir * AtmosphereDistance;
    vec3 AccumRayleigh = vec3(0.0f), AccumMie = vec3(0.0f);
    // TODO: precompute cos theta^2 for both functions
    float CosTheta = dot(light, dir);
    vec3 ScatteringStrengthRayleigh = PhaseRayleigh(CosTheta) * ScatteringCoefficientRayleigh;
    float ScatteringStrengthMie = PhaseMie(CosTheta) * ScatteringCoefficientMie;
    float RayMarchStepLength = AtmosphereDistance / float(INSCATTERING_STEPS);
    float RayMarchPosition = 0.0f;
    OpticalDepth InscatteringOpticalDepth; 
    InscatteringOpticalDepth.Rayleigh = vec3(0.0f);
    InscatteringOpticalDepth.Mie = 0.0f;
    for(int InscatteringStep = 0; InscatteringStep < INSCATTERING_STEPS; InscatteringStep++){
        vec3 SampleLocation = ViewPos + dir * (RayMarchPosition + 0.5f * RayMarchStepLength);
        float CurrentAltitude = distance(SampleLocation, vec3(0.0f)) - EarthRadius;
        float CurrenyDensityRayleigh = CalculateDensityRayleigh(CurrentAltitude);
        float CurrentDensityMie = CalculateDensityMie(CurrentAltitude);
        InscatteringOpticalDepth.Rayleigh += CurrenyDensityRayleigh * ExtinctionCoefficientRayleigh * RayMarchStepLength;
        InscatteringOpticalDepth.Mie += CurrenyDensityRayleigh * ExtinctionCoefficientMie * RayMarchStepLength;
        float LightLength = RaySphereIntersect(SampleLocation, light, AtmosphereRadius);
        Ray AirMassRay;
        AirMassRay.Origin = SampleLocation;
        AirMassRay.Direction = light;
        vec3 TransmittedSunLight = ComputeTransmittance(AirMassRay, LightLength) * Transmittance(InscatteringOpticalDepth);
        vec3 TransmittedAccumSunLight = vec3(1.0f);
        vec3 CurrentAltitudeScatteringStrengthRayleigh = CurrenyDensityRayleigh * ScatteringStrengthRayleigh;
        float CurrentAltitudeScatteringStrengthMie = CurrentDensityMie * ScatteringStrengthMie;
        AccumRayleigh += TransmittedSunLight * TransmittedAccumSunLight * CurrentAltitudeScatteringStrengthRayleigh * RayMarchStepLength;
        AccumMie      += TransmittedSunLight * TransmittedAccumSunLight * CurrentAltitudeScatteringStrengthMie      * RayMarchStepLength;
        RayMarchPosition += RayMarchStepLength;
    }
    vec3 Opacity = Transmittance(InscatteringOpticalDepth);
    // Multiplying the rayleigh light by 0.5f breaks the physical basis of this, but it sure does give some nice sunsets
    // I'll find a better fix to the problem later
    return SunColor * (AccumRayleigh + AccumMie);
}

const vec3 FogScattering = vec3(2.0e-2);
const vec3 FogAbsorbtion = vec3(1.5e-3);
const vec3 FogExtinction = FogScattering + FogAbsorbtion;

// Basic idea behind this is that there is some sort of fog cover over the player's head
// We blend with skyColor based of how high the viewing direction is and how far it is
// Then inscattering is computed using a mie phase approximationg using dot and pow
// It is going to be quite similair to Slidures v1.06
vec3 ComputeFog(in vec3 light, in vec3 dir, in vec3 color, in float dist){
    float vertical = max(dir.y, 0.0f);
    //vertical = pow(vertical, 0.1f);
    vertical = max(vertical, 0.01f);
    vec3 extinction = exp(-FogExtinction * dist);
    vec3 inscattering = exp(FogScattering * dist);
    inscattering = mix(inscattering, FogScattering * max(dot(light, dir), 0.0f) * vec3(12.0f, 5.0f, 1.0f) * dist, 1.0f);
    vec3 foggyclr = mix(mix(color * extinction + inscattering, inscattering, pow(max(dot(light, dir), 0.0f), 2.0f)), color, vertical);
    return foggyclr;
}

vec3 ComputeSkyColor(in vec3 light, in vec3 dir){
    return ComputeAtmosphericScattering(light, dir);
}

vec3 saturate(vec3 val);

vec3 ComputeSunColor(in vec3 light, in vec3 dir){
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

const float SunSpotSize = 0.999;

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

void ShadeSurfaceStruct(in SurfaceStruct Surface, inout ShadingStruct Shading, in vec3 sun){
    Shading.Sun = CalculateSunShading(Surface, sun);
    ComputeLightmap(Surface, Shading);
}

void ComputeColor(in SurfaceStruct Surface, inout ShadingStruct Shading){
    vec3 Lighting = Shading.Sun + Shading.Torch + Shading.Sky;
    Shading.Color = Surface.Diffuse * vec4(Lighting, 1.0f);
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st);
    //Shading.Color = vec4(vec3(Surface.NdotL), 1.0f);
}

#endif