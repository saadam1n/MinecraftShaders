#ifndef EFFECT_DEPTH_OF_FIELD_GLSL 
#define EFFECT_DEPTH_OF_FIELD_GLSL

#include "../Utility/Uniforms.glsl"
#include "../Utility/Functions.glsl"

/*
A  - Aperture diameter
f  - Focal length
S1 - Focal distance
S2 - Fragment distance
All units should be the same, preferably in meters
*/
float ComputeCircleOfConfusion(in float A, in float f, in float S1, in float S2){
    return A * (abs(S2-S1) / S2) * (f / (S1 - f));
}

float ComputeCircleOfConfusion(in float center, in float dist){
    // Use very large aperture size
    // This is to counter the framebuffer size correct in the two pass blur
    return saturate(ComputeCircleOfConfusion(1000.024f, 1.0f, center, dist));
}

#endif