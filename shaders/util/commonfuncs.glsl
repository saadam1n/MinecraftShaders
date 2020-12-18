#ifndef COMMON_FUNCS_GLSL
#define COMMON_FUNCS_GLSL 1

#define MATH_PI 3.1415

#include "uniforms.glsl"
#include "structures.glsl"

#ifndef HARDWARE_SHADOW_FILTERING
vec4 shadow2D(in sampler2D ShadowDepth, in vec3 coords){ 
    return vec4(step(coords.z, texture2D(ShadowDepth, coords.xy).r));
}
#endif

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

vec3 GetWorldSpace(vec2 texcoord = gl_TexCoord[0].st, sampler2D depthsampler = depthtex0){
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
    float len = sqrt(position.x * position.x + position.y * position.y);
    return (1.0f - SHADOW_MAP_BIAS) + len * SHADOW_MAP_BIAS;
}

#define SHADOW_DISTORTION // Increase shadow quality near the player while lowering shadow quality farther from the player. Negligible performance loss.

#ifdef SHADOW_DISTORTION

vec2 DistortShadowCoords(in vec2 shadowcoords){
    return shadowcoords * 1.0f / DistortionFactor(shadowcoords);
}

vec3 DistortShadowPos(in vec3 ShadowPos){
    return vec3(DistortShadowCoords(ShadowPos.xy), ShadowPos.z * ShadowDepthCompressionFactor);
}

#else

vec2 DistortShadowCoords(in vec2 shadowcoords){
    return shadowcoords;
}

vec3 DistortShadowPos(in vec3 ShadowPos){
    return ShadowPos;
}

vec2 DistortShadowCoordsInverse(in vec2 dshadowcoords){
    return dshadowcoords;
}

#endif

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

const float ScaleHeightRayleigh = 7994.0f;
const float ScaleHeightMie = 1200.0f;

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
    color = mix(color, vec3(0.0f), rainStrength);
    return FadeShadowColor(color, Surface);
}

vec3 ComputeShadow(in SurfaceStruct Surface){
    // TODO: precompute length(ShadowPos.xy) when doing shadow distortion calculations
    float DiffThresh = length(Surface.ShadowScreen.xy) + 0.10f;
    DiffThresh *= 3.0f / (shadowMapResolution / 2048.0f);
    // The max() is to get rid of a shadowing bug near the player
    // DistortionFactor * DistortionFactor causes it, I'm not sure why though
    float AdjustedShadowDepth = Surface.ShadowScreen.z - max(0.0028f * DiffThresh * (1.0f - Surface.NdotL) * Surface.Distortion * Surface.Distortion, 0.00015f);
    #ifdef SOFT_SHADOWS
    #ifdef SOFT_SHADOW_ROTATION
    mat2 Transformation = CreateRandomRotationScreen(Surface.Screen.xy + frameTimeCounter) * SoftShadowScale;
    #else
    vec2 Transformation = vec2(SoftShadowScale);
    #endif
    vec3 ShadowAccum = vec3(0.0f);
    for(float x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x+= ShadowStep){
        for(float y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y+= ShadowStep){
            vec3 ShadowHardwareFilterCoord = vec3(Surface.ShadowScreen.xy + vec2(x, y) * Transformation, AdjustedShadowDepth);
            float ShadowVisibility0 = shadow2D(shadowtex0, ShadowHardwareFilterCoord).r;
            float ShadowVisibility1 = shadow2D(shadowtex1, ShadowHardwareFilterCoord).r;
            vec4 ShadowColor0 = texture2D(shadowcolor0, ShadowHardwareFilterCoord.xy);
            vec3 TransmittedColor = ShadowColor0.rgb * ShadowColor0.a;
            vec3 ShadedColor = mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
            ShadowAccum += ShadedColor;
        }
    }
    ShadowAccum /= ShadowSamplesTotal;
    return PostProcessShadow(ShadowAccum, Surface);
    #else
    vec3 ShadowHardwareFilterCoord = vec3(Surface.ShadowScreen.xy, AdjustedShadowDepth);
    float ShadowVisibility0 = shadow2D(shadowtex0, ShadowHardwareFilterCoord).r;
    float ShadowVisibility1 = shadow2D(shadowtex1, ShadowHardwareFilterCoord).r;
    vec4 ShadowColor0 = texture2D(shadowcolor0, ShadowHardwareFilterCoord.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * ShadowColor0.a;
    vec3 ShadedColor = mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);
    return PostProcessShadow(ShadedColor, Surface);
    #endif
}

float CalculateDensityRayleigh(float h){
    return exp(-h/ScaleHeightRayleigh);
}

float CalculateDensityMie(float h){
    return exp(-h/ScaleHeightMie);
}

vec3 GetSkyTopColor(void){
    float Input = abs((float(worldTime) / 24000.0f) * 2.0f - 1.0f);
    // RED
    float Red = 0.5 * pow(Input, 7.0f);
    // GREEN
    float Green = 0.7 * pow(Input, 2.0f);
    // BLUE
    float Blue = 0.9 * pow(Input, 0.7f);
    return vec3 (Red, Green, Blue);
}

//#define ATMOSPHERIC_SCATTERING

vec3 ApplyFog(in vec3 color, in vec3 worldpos){
    float dist = distance(worldpos, gbufferModelView[3].xyz);
    vec3 toPos = normalize(worldpos - gbufferModelView[3].xyz);
    float strength = 1.0f - max(dot(toPos, vec3(0.0f, 1.0f, 0.0f)), 0.0f);
    float extinction = exp(dist * 0.1f);
    float inscattering = exp(dist * 0.1f) * strength;
    vec3 FoggyColor = color * extinction + inscattering * vec3(1.0f);
    return FoggyColor;
}

vec3 ComputeSkyGradient(in vec3 light, in vec3 dir){
    vec3 Top = GetSkyTopColor();
    vec3 Fog = ApplyFog(Top, GetWorldSpace());
    return Fog;
}

vec3 ComputeSkyColor(vec3 light, in vec3 dir){
    #ifdef ATMOSPHERIC_SCATTERING
    return dir * 0.5f + 0.5f;
    #else
    return ComputeSkyGradient(light, dir);
    #endif
}

// Put this in the fragment shader if the transformation curve is not straight, if not then it goes in vertex shader
void AdjustLightMap(in SurfaceStruct surface){
    // Do nothing for now
}

void ComputeLightmap(in SurfaceStruct Surface, inout ShadingStruct Shading){
    Shading.Torch = Surface.Torch * TorchEmitColor;
    Shading.Sky = Surface.Sky * mix(GetSkyTopColor(), vec3(0.5f), 0.5f);
}

// Better name would be construct, but constructors don't exist in a functional programming language
void CreateSurfaceStructDeferred(in vec2 texcoords, in vec3 l, out SurfaceStruct Surface){
    Surface.Diffuse = texture2D(colortex0, texcoords).rgb;
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

    Surface.NdotL = max(dot(Surface.Normal, l), 0.0f);
}

vec3 CalculateSunShading(in SurfaceStruct Surface){
    return Surface.NdotL * ComputeShadow(Surface);
}

void ShadeSurfaceStruct(in SurfaceStruct Surface, inout ShadingStruct Shading){
    Shading.Sun = CalculateSunShading(Surface);
    ComputeLightmap(Surface, Shading);
}

void ComputeColor(in SurfaceStruct Surface, inout ShadingStruct Shading){
    vec3 Lighting = Shading.Sun + Shading.Torch + Shading.Sky;
    Shading.Color = Surface.Diffuse * Lighting;
    //Shading.Color = texture2D(shadowcolor0, Surface.ShadowScreen.st).rgb;
}

#endif