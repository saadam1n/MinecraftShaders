#ifndef VOLUME_RENDERING_PHASE_FUNCTION_GLSL
#define VOLUME_RENDERING_PHASE_FUNCTION_GLSL 1

#include "../Utility/Constants.glsl"

float PhaseRayleigh(in float cosTheta){
    return 3.0f / (16.0f * MATH_PI) * (1.0f + cosTheta * cosTheta);
}

float PhaseHenyeyGreenstein(in float cosTheta, in float g){
    float g_2 = g*g;
    float phase = (1.0f - g_2) / pow(1 + g_2 + 2.0f * g * cosTheta, 1.5f);
    return phase / (4.0f * MATH_PI);
}

float PhaseMie(in float cosTheta) {
    return PhaseHenyeyGreenstein(cosTheta, -0.974f);
}

float PhaseRayleigh(in vec3 v, in vec3 l){
    return PhaseRayleigh(dot(v, l));
}

float PhaseMie(in vec3 v, in vec3 l){
    return PhaseMie(dot(v, l));
}

#endif