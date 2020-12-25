#ifndef MISC_UNUSED_CODE_GLSL
#define MISC_UNUSED_CODE_GLSL 1

#include "../settings.glsl"
#include "../Utility/Uniforms.glsl"

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

vec4 CalculateShadow(in sampler2D ShadowDepth, in vec3 coords){ 
    return vec4(step(coords.z, texture2D(ShadowDepth, coords.xy).r));
}

float FadeShadow(in float centerdistance){
    return clamp(centerdistance - ShadowDistanceFade, 0.0f, ShadowDistanceFadeLength) / ShadowDistanceFadeLength;
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

vec3 ApplyFog(in vec3 color, in vec3 worldpos){
    float dist = distance(worldpos, gbufferModelView[3].xyz);
    vec3 toPos = normalize(worldpos - gbufferModelView[3].xyz);
    float strength = 1.0f - max(dot(toPos, vec3(0.0f, 1.0f, 0.0f)), 0.0f);
    float extinction = exp(dist * 0.1f);
    float inscattering = exp(dist * 0.1f) * strength;
    vec3 FoggyColor = color * extinction + inscattering * vec3(1.0f);
    return FoggyColor;
}

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

const vec3 FogScattering = vec3(2.0e-9);
const vec3 FogAbsorbtion = vec3(1.5e-3);
const vec3 FogExtinction = FogAbsorbtion;

vec3 ComputeFog(in vec3 light, in vec3 dir, in vec3 color, in float dist){
    vec3 transmittedColor = color * exp(-FogExtinction * dist);
    vec3 inscatteredColor = fogColor * exp(-FogScattering * dist);
    return transmittedColor + inscatteredColor;
}

#endif