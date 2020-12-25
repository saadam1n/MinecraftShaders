#ifndef TRANFORM_DISTORT_GLSL
#define TRANFORM_DISTORT_GLSL 1

#include "../Utility/Constants.glsl"

#define SHADOW_MAP_BIAS 0.9f

float DistortionFactor(in vec2 position) {
    float len = sqrt(position.x * position.x + position.y * position.y) * 0.9f;
    return (1.0f - SHADOW_MAP_BIAS) + len * SHADOW_MAP_BIAS;
}

vec2 DistortShadowCoords(in vec2 shadowcoords){
    return shadowcoords * 1.0f / DistortionFactor(shadowcoords);
}

vec3 DistortShadowPos(in vec3 ShadowPos){
    return vec3(DistortShadowCoords(ShadowPos.xy), ShadowPos.z);
}

vec3 DistortShadow(vec3 pos) {
    return DistortShadowPos(pos);
}

#endif