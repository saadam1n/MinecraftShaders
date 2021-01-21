#ifndef TRANFORM_DISTORT_GLSL
#define TRANFORM_DISTORT_GLSL 1

#include "../Utility/Constants.glsl"

#define SHADOW_MAP_BIAS 0.9f
#define SHADOW_DISTORTION // Nobody in their right minds should turn this off
#define BUILDERBOY_CUBE_LENGTH_DISTORTION // Based off the distortion method presented in Builderboy's shadow tutorial shaderpacks

float Gaussian2D(in vec2 coords, in float sigma){
    float sigma_squared_times_2 = sigma * sigma * 2.0f;
    coords *= coords;
    return exp((coords.x + coords.y) / sigma_squared_times_2) / (sigma_squared_times_2 * MATH_PI);
}

const float DistortPower = 7.0f;

float DistortLength(in vec2 p){
    p = abs(p);
    p = pow(p, vec2(DistortPower));
    return pow(p.x + p.y, 1.0f / DistortPower);
    #ifdef BUILDERBOY_CUBE_LENGTH_DISTORTION
    p = abs(p);
    p = p * p * p;
    return pow(p.x + p.y, 1.0f / 3.0f);
    #else
    //vec2 BorderDist = abs(1.0f / p);
    //float BorderDistMin = min(BorderDist.x, BorderDist.y);
    //vec2 BorderVec = p *  BorderDistMin;
    return length(p);// / length(BorderVec);
    #endif 
}

float DistortionFactor(in vec2 position) {
    float len = 1e-6 + DistortLength(position);
    return (1.0f - SHADOW_MAP_BIAS) + len * SHADOW_MAP_BIAS;
}

vec2 DistortShadowCoords(in vec2 shadowcoords){
    //return shadowcoords * (1.0f + Gaussian2D(shadowcoords, 0.25f));
    //return mix(shadowcoords, shadowcoords + 1.0f / (pow(length(shadowcoords), 8.0f) + 1.0f), 0.3f);
    #ifndef SHADOW_DISTORTION
    return shadowcoords;
    #endif
    vec2 distortedcoords =  shadowcoords / min(DistortionFactor(shadowcoords), 1.0f);
    return distortedcoords;
}

vec3 DistortShadowPos(in vec3 ShadowPos){
    return vec3(DistortShadowCoords(ShadowPos.xy), ShadowPos.z * 0.5f);
}

vec3 DistortShadow(vec3 pos) {
    return DistortShadowPos(pos);
}

vec3 DistortShadowSample(in vec3 sample){
    vec3 Distorted = DistortShadowPos(sample);
    Distorted.xyz = Distorted.xyz * 0.5f + 0.5f; // Do the z also since depth textures are 0 - 1 not -1 to 1
    return Distorted;
}

#endif