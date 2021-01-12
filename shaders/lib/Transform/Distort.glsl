#ifndef TRANFORM_DISTORT_GLSL
#define TRANFORM_DISTORT_GLSL 1

#include "../Utility/Constants.glsl"

#define SHADOW_MAP_BIAS 0.9f
#define SHADOW_DISTORTION // Nobody in their right minds should turn this off

float DistortionFactor(in vec2 position) {
    float len = length(position);
    return (1.0f - SHADOW_MAP_BIAS) + len * SHADOW_MAP_BIAS;
}

vec2 DistortShadowCoords(in vec2 shadowcoords){
    //return mix(shadowcoords, shadowcoords + 1.0f / (pow(length(shadowcoords), 8.0f) + 1.0f), 0.3f);
    #ifndef SHADOW_DISTORTION
    return shadowcoords;
    #endif
    vec2 distortedcoords =  shadowcoords * 1.0f / DistortionFactor(shadowcoords);
    return distortedcoords;
}

vec3 DistortShadowPos(in vec3 ShadowPos){
    return vec3(DistortShadowCoords(ShadowPos.xy), ShadowPos.z);
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